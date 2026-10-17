from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.access import enroll_class_in_common_subjects, require_admin
from app.core.database import get_db
from app.models.academic import Subject
from app.core.college_rules import normalize_reg, reg_problem
from app.models.college import (ClassAdvisor, ClassGroup, ClassStudent, Semester, Student, Teacher)
router = APIRouter(prefix="/admin", tags=["admin"])


def _save(db: Session):
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "That record already exists.")
def _current_semester(db: Session) -> Semester:
    sem = db.scalars(select(Semester).where(Semester.is_current.is_(True))).first()
    if sem is None:
        raise HTTPException(400, "Create a semester first.")
    return sem

def _link_advisor(db: Session, class_id, email: str):
    teacher = db.scalars(select(Teacher).where(
        func.lower(Teacher.email) == email.strip().lower())).first()
    if teacher is None:
        raise HTTPException(404, "That teacher is not on the approved list.")
    if teacher.user_id is None:
        raise HTTPException(400, "That teacher must sign in to the app once first.")
    if db.get(ClassAdvisor, (class_id, teacher.user_id)) is None:
        db.add(ClassAdvisor(class_id=class_id, user_id=teacher.user_id))


# ---------- semesters ----------
class SemesterIn(BaseModel):
    academic_year: str
    name: str
    is_current: bool = False


@router.post("/semesters", status_code=201)
def create_semester(body: SemesterIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    if body.is_current:
        db.query(Semester).update({Semester.is_current: False})
    s = Semester(academic_year=body.academic_year.strip(), name=body.name.strip().upper(),
                 is_current=body.is_current)
    db.add(s)
    _save(db)
    return {"id": str(s.id), "academic_year": s.academic_year, "name": s.name}


@router.get("/semesters")
def list_semesters(db: Session = Depends(get_db), admin=Depends(require_admin)):
    rows = db.scalars(select(Semester).order_by(Semester.academic_year.desc(), Semester.name)).all()
    return [{"id": str(s.id), "academic_year": s.academic_year, "name": s.name,
             "is_current": s.is_current} for s in rows]


# ---------- classes ----------

class ClassIn(BaseModel):
    name: str
    semester_id: UUID | None = None
    department: str = "CSE"
    advisor_email: str | None = None


@router.post("/classes", status_code=201)
def create_class(body: ClassIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    sem_id = body.semester_id or _current_semester(db).id
    c = ClassGroup(name=body.name.strip().upper(), department=body.department.strip(),
                   semester_id=sem_id)
    db.add(c)
    try:
        db.flush()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "That class already exists.")
    if body.advisor_email and body.advisor_email.strip():
        _link_advisor(db, c.id, body.advisor_email)
    _save(db)
    return {"id": str(c.id), "name": c.name}


class AdvisorIn(BaseModel):
    teacher_email: str


@router.post("/classes/{class_id}/advisors", status_code=201)
def add_advisor(class_id: UUID, body: AdvisorIn, db: Session = Depends(get_db),
                admin=Depends(require_admin)):
    if db.get(ClassGroup, class_id) is None:
        raise HTTPException(404, "Class not found.")
    _link_advisor(db, class_id, body.teacher_email)
    _save(db)
    return {"status": "added"}


@router.get("/classes")
def list_classes(semester_id: UUID | None = None, db: Session = Depends(get_db),
                 admin=Depends(require_admin)):
    q = select(ClassGroup).order_by(ClassGroup.name)
    if semester_id:
        q = q.where(ClassGroup.semester_id == semester_id)
    return [{"id": str(c.id), "name": c.name, "department": c.department,
             "semester_id": str(c.semester_id)} for c in db.scalars(q).all()]


# ---------- teachers (approved list) ----------
class TeacherIn(BaseModel):
    email: str
    name: str | None = None
    is_admin: bool = False


@router.post("/teachers", status_code=201)
def approve_teacher(body: TeacherIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    t = Teacher(email=body.email.strip().lower(), name=body.name, is_admin=body.is_admin)
    db.add(t)
    _save(db)
    return {"id": str(t.id), "email": t.email}


@router.get("/teachers")
def list_teachers(db: Session = Depends(get_db), admin=Depends(require_admin)):
    return [{"id": str(t.id), "email": t.email, "name": t.name, "is_admin": t.is_admin,
             "signed_in_once": t.user_id is not None}
            for t in db.scalars(select(Teacher).order_by(Teacher.email)).all()]


# ---------- students (approved list) ----------
class StudentIn(BaseModel):
    register_number: str
    name: str
    college_email: str | None = None
    class_id: UUID | None = None


@router.post("/students", status_code=201)
def add_student(body: StudentIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    email = body.college_email.strip().lower() if body.college_email else None
    reg = normalize_reg(body.register_number)
    problem = reg_problem(reg)
    if problem:
        raise HTTPException(400, problem)
    st = Student(register_number=reg, name=body.name.strip(), college_email=email)
    try:
        db.add(st)
        db.flush()
        if body.class_id:
            if db.get(ClassGroup, body.class_id) is None:
                raise HTTPException(404, "Class not found.")
            db.add(ClassStudent(class_id=body.class_id, student_id=st.id))
            db.flush()
            enroll_class_in_common_subjects(db, body.class_id, by_user_id=admin.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "A student with this register number already exists.")
    return {"id": str(st.id), "register_number": st.register_number}


# ---------- subjects (sections) ----------
class SubjectIn(BaseModel):
    code: str
    name: str
    teacher_email: str
    semester_id: UUID | None = None
    kind: str = "common"              # common | elective
    class_id: UUID | None = None
    class_name: str | None = None     # easier than class_id
    color: str = "#2F6F4E"


@router.post("/subjects", status_code=201)
def create_subject(body: SubjectIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    kind = body.kind.strip().lower()
    if kind not in ("common", "elective"):
        raise HTTPException(400, "Kind must be 'common' or 'elective'.")

    sem_id = body.semester_id or _current_semester(db).id
    if kind == "elective":
        body.class_id = None
        body.class_name = None
    class_id = body.class_id
    if class_id is None and body.class_name and body.class_name.strip():
        cg = db.scalars(select(ClassGroup).where(
            ClassGroup.semester_id == sem_id,
            func.upper(ClassGroup.name) == body.class_name.strip().upper())).first()
        if cg is None:
            raise HTTPException(404, f"Class '{body.class_name}' not found in this semester.")
        class_id = cg.id
    if kind == "common" and class_id is None:
        raise HTTPException(400, "A common subject needs a class.")

    teacher = db.scalars(select(Teacher).where(
        func.lower(Teacher.email) == body.teacher_email.strip().lower())).first()
    if teacher is None:
        raise HTTPException(404, "That teacher is not on the approved list.")
    if teacher.user_id is None:
        raise HTTPException(400, "That teacher must sign in to the app once first.")

    subject = Subject(code=body.code.strip().upper(), name=body.name.strip(), color=body.color,
                      teacher_id=teacher.user_id, semester_id=sem_id,
                      class_id=class_id, kind=kind)
    db.add(subject)
    db.flush()
    added = 0
    if kind == "common":
        added = enroll_class_in_common_subjects(db, class_id, by_user_id=admin.id)
    db.commit()
    return {"id": str(subject.id), "students_enrolled": added}

class RolloverIn(BaseModel):
    academic_year: str
    name: str                              # e.g. S8
    from_semester_id: UUID | None = None   # default: the current semester
    carry_students: bool = True
    confirm: bool = False                  # false = preview only


def _next_class_name(old_class: str, old_sem: str, new_sem: str) -> str:
    oc, os_ = old_class.upper(), old_sem.upper()
    return oc.replace(os_, new_sem, 1) if os_ in oc else f"{new_sem} {oc}"


@router.post("/rollover")
def rollover(body: RolloverIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    old = db.get(Semester, body.from_semester_id) if body.from_semester_id else _current_semester(db)
    if old is None:
        raise HTTPException(404, "Semester not found.")
    new_name = body.name.strip().upper()
    year = body.academic_year.strip()
    if not new_name or not year:
        raise HTTPException(400, "Enter the academic year and the new semester name.")
    if db.scalars(select(Semester).where(
            Semester.academic_year == year, Semester.name == new_name)).first():
        raise HTTPException(409, "That semester already exists.")

    old_classes = db.scalars(select(ClassGroup).where(
        ClassGroup.semester_id == old.id).order_by(ClassGroup.name)).all()
    plan = []
    for c in old_classes:
        count = db.scalar(select(func.count()).select_from(ClassStudent)
                          .where(ClassStudent.class_id == c.id))
        plan.append({"from": c.name, "to": _next_class_name(c.name, old.name, new_name),
                     "students": count or 0})

    if not body.confirm:
        return {"preview": True,
                "old_semester": f"{old.name} {old.academic_year}",
                "new_semester": f"{new_name} {year}",
                "classes": plan,
                "note": "Old classes, enrollments and content stay untouched. Subjects are "
                        "not copied: create the new subjects, and common ones enroll the "
                        "students automatically."}

    db.query(Semester).update({Semester.is_current: False})
    sem = Semester(academic_year=year, name=new_name, is_current=True)
    db.add(sem)
    db.flush()
    carried = 0
    for c in old_classes:
        nc = ClassGroup(name=_next_class_name(c.name, old.name, new_name),
                        department=c.department, semester_id=sem.id)
        db.add(nc)
        db.flush()
        if body.carry_students:
            ids = list(db.scalars(select(ClassStudent.student_id)
                                  .where(ClassStudent.class_id == c.id)))
            for sid in ids:
                db.add(ClassStudent(class_id=nc.id, student_id=sid))
                carried += 1
    _save(db)
    return {"preview": False, "semester": f"{new_name} {year}",
            "classes_created": len(old_classes), "students_carried": carried}