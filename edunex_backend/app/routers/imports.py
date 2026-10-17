from collections import defaultdict
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.access import enroll_class_in_common_subjects, require_admin
from app.core.database import get_db
from app.core.importer import rows_from_file, rows_from_text
from app.models.academic import Enrollment, Subject
from app.models.college import (ClassGroup, ClassStudent, EnrollmentAudit,
                                ImportBatch, Semester, Student)

router = APIRouter(prefix="/admin/import", tags=["import"])


# ---------------------------------------------------------------- planning
def _plan_students(db: Session, sem_id, rows):
    classes = {c.name.upper(): c for c in db.scalars(
        select(ClassGroup).where(ClassGroup.semester_id == sem_id))}
    students = {s.register_number: s for s in db.scalars(select(Student))}
    members = set()
    if classes:
        members = {(r[0], r[1]) for r in db.execute(
            select(ClassStudent.class_id, ClassStudent.student_id)
            .where(ClassStudent.class_id.in_([c.id for c in classes.values()]))).all()}

    plan, errors, seen = [], [], set()
    new_students = new_members = unchanged = 0
    for i, r in enumerate(rows, start=2):          # row 1 is the header
        reg = r.get("register_number", "").upper()
        if not reg:
            errors.append({"row": i, "problem": "Missing register number"})
            continue
        if reg in seen:
            errors.append({"row": i, "register_number": reg, "problem": "Duplicate in this file"})
            continue
        seen.add(reg)
        cls = classes.get(r.get("class", "").upper())
        if cls is None:
            errors.append({"row": i, "register_number": reg,
                           "problem": f"Class '{r.get('class', '')}' does not exist in this semester"})
            continue
        st = students.get(reg)
        if st is None and not r.get("name"):
            errors.append({"row": i, "register_number": reg,
                           "problem": "Missing name for a new student"})
            continue
        is_new = st is None
        if not is_new and (cls.id, st.id) in members:
            unchanged += 1
            continue
        plan.append({"reg": reg, "name": r.get("name", ""),
                     "email": (r.get("email") or "").lower() or None,
                     "class_id": str(cls.id)})
        new_students += is_new
        new_members += 1

    summary = {"rows_in_file": len(rows), "new_students": new_students,
               "class_memberships_to_add": new_members, "unchanged": unchanged,
               "errors": len(errors), "to_apply": len(plan)}
    return plan, summary, errors, []


def _plan_enrollments(db: Session, sem_id, rows):
    students = {s.register_number: s for s in db.scalars(select(Student))}
    classes = {c.name.upper(): c for c in db.scalars(
        select(ClassGroup).where(ClassGroup.semester_id == sem_id))}
    by_code, subject_ids = defaultdict(list), []
    for s in db.scalars(select(Subject).where(Subject.semester_id == sem_id)):
        by_code[s.code.upper()].append(s)
        subject_ids.append(s.id)

    have, last = set(), {}
    if subject_ids:
        have = {(r[0], r[1]) for r in db.execute(
            select(Enrollment.student_id, Enrollment.subject_id)
            .where(Enrollment.subject_id.in_(subject_ids))).all()}
        for a in db.scalars(select(EnrollmentAudit)
                            .where(EnrollmentAudit.subject_id.in_(subject_ids))
                            .order_by(EnrollmentAudit.created_at)):
            last[(a.student_id, a.subject_id)] = a.action    # latest action wins

    plan, errors, conflicts, seen = [], [], [], set()
    already = 0
    for i, r in enumerate(rows, start=2):
        reg = r.get("register_number", "").upper()
        code = r.get("subject_code", "").upper()
        cname = r.get("class", "")

        def bad(problem):
            errors.append({"row": i, "register_number": reg or None, "problem": problem})

        if not reg or not code:
            bad("Needs a register number and a subject code")
            continue
        st = students.get(reg)
        if st is None:
            bad("Register number is not in the student list")
            continue
        cands = by_code.get(code, [])
        if not cands:
            bad(f"Subject {code} does not exist in this semester")
            continue
        cls = classes.get(cname.upper()) if cname else None
        if cname and cls is None:
            bad(f"Class '{cname}' does not exist in this semester")
            continue
        if len(cands) > 1:
            cands = [s for s in cands if cls is not None and s.class_id == cls.id]
        if len(cands) != 1:
            bad("More than one subject uses this code. Add the class column")
            continue
        subj = cands[0]
        if cls is not None and subj.class_id not in (None, cls.id):
            bad("This subject belongs to a different class")
            continue

        key = (st.id, subj.id)
        if key in seen:
            bad("Duplicate in this file")
            continue
        seen.add(key)
        if key in have:
            already += 1
            continue
        if last.get(key) == "remove":
            conflicts.append({"row": i, "register_number": reg,
                              "problem": f"A teacher removed this student from {code} earlier. Not re-added."})
            continue
        plan.append({"student_id": str(st.id), "subject_id": str(subj.id)})

    summary = {"rows_in_file": len(rows), "to_enroll": len(plan), "already_enrolled": already,
               "conflicts": len(conflicts), "errors": len(errors), "to_apply": len(plan)}
    return plan, summary, errors, conflicts


# ---------------------------------------------------------------- routes
@router.post("/preview")
def preview(
    kind: str = Form(...),
    semester_id: UUID | None = Form(None),
    csv_text: str | None = Form(None),
    file: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    kind = kind.strip().lower()
    if kind not in ("students", "enrollments"):
        raise HTTPException(400, "Kind must be 'students' or 'enrollments'.")

    if semester_id:
        sem = db.get(Semester, semester_id)
    else:
        sem = db.scalars(select(Semester).where(Semester.is_current.is_(True))).first()
    if sem is None:
        raise HTTPException(400, "Create a semester first.")

    try:
        if file is not None and file.filename:
            rows, filename = rows_from_file(file.filename, file.file.read()), file.filename
        elif csv_text and csv_text.strip():
            rows, filename = rows_from_text(csv_text), "pasted text"
        else:
            raise HTTPException(400, "Upload a file or paste the data.")
    except ValueError as e:
        raise HTTPException(400, str(e))
    if not rows:
        raise HTTPException(400, "No data rows found. The first line must be the header.")

    planner = _plan_students if kind == "students" else _plan_enrollments
    plan, summary, errors, conflicts = planner(db, sem.id, rows)

    batch = ImportBatch(kind=kind, semester_id=sem.id, filename=filename,
                        summary=summary, plan=plan, created_by=admin.id)
    db.add(batch)
    db.commit()
    return {"batch_id": str(batch.id), "kind": kind,
            "semester": f"{sem.name} {sem.academic_year}", "summary": summary,
            "errors": errors[:100], "conflicts": conflicts[:100]}


@router.post("/{batch_id}/confirm")
def confirm(batch_id: UUID, db: Session = Depends(get_db), admin=Depends(require_admin)):
    b = db.get(ImportBatch, batch_id)
    if b is None:
        raise HTTPException(404, "Import not found.")
    if b.status == "confirmed":
        raise HTTPException(409, "This import was already applied.")

    if b.kind == "students":
        existing = {s.register_number: s for s in db.scalars(select(Student))}
        touched, created, memberships = set(), 0, 0
        for p in b.plan:
            st = existing.get(p["reg"])
            if st is None:
                st = Student(register_number=p["reg"], name=p["name"], college_email=p["email"])
                db.add(st)
                db.flush()
                existing[p["reg"]] = st
                created += 1
            cid = UUID(p["class_id"])
            if db.get(ClassStudent, (cid, st.id)) is None:
                db.add(ClassStudent(class_id=cid, student_id=st.id))
                memberships += 1
            touched.add(cid)
        db.flush()
        auto = sum(enroll_class_in_common_subjects(db, cid, by_user_id=admin.id) for cid in touched)
        result = {"students_created": created, "class_memberships_added": memberships,
                  "common_subject_enrollments_added": auto}
    else:
        added = 0
        for p in b.plan:
            sid, subj = UUID(p["student_id"]), UUID(p["subject_id"])
            if db.get(Enrollment, (sid, subj)) is None:
                db.add(Enrollment(student_id=sid, subject_id=subj,
                                  source="imported", added_by=admin.id))
                db.add(EnrollmentAudit(subject_id=subj, student_id=sid, action="add",
                                       reason=f"import: {b.filename}", by_user_id=admin.id))
                added += 1
        result = {"enrollments_added": added}

    b.status = "confirmed"
    db.commit()
    return result


@router.get("/batches")
def history(db: Session = Depends(get_db), admin=Depends(require_admin)):
    rows = db.scalars(select(ImportBatch).order_by(ImportBatch.created_at.desc()).limit(20)).all()
    return [{"id": str(b.id), "kind": b.kind, "filename": b.filename, "status": b.status,
             "summary": b.summary, "created_at": b.created_at.isoformat()} for b in rows]