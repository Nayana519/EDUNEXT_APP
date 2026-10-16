from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.access import enroll_class_in_common_subjects, require_admin
from app.core.database import get_db
from app.models.academic import Subject
from app.models.college import ClassGroup, ClassStudent, Semester, Student, Teacher

router = APIRouter(prefix="/admin", tags=["admin"])


def _save(db: Session):
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "That record already exists.")


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
    semester_id: UUID
    department: str = "CSE"


@router.post("/classes", status_code=201)
def create_class(body: ClassIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    c = ClassGroup(name=body.name.strip().upper(), department=body.department.strip(),
                   semester_id=body.semester_id)
    db.add(c)
    _save(db)
    return {"id": str(c.id), "name": c.name}


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
    st = Student(register_number=body.register_number.strip().upper(),
                 name=body.name.strip(), college_email=email)
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
    semester_id: UUID
    teacher_email: str
    kind: str = "common"          # common | elective
    class_id: UUID | None = None
    color: str = "#2F6F4E"


@router.post("/subjects", status_code=201)
def create_subject(body: SubjectIn, db: Session = Depends(get_db), admin=Depends(require_admin)):
    kind = body.kind.strip().lower()
    if kind not in ("common", "elective"):
        raise HTTPException(400, "Kind must be 'common' or 'elective'.")
    if kind == "common" and body.class_id is None:
        raise HTTPException(400, "A common subject needs a class.")

    teacher = db.scalars(select(Teacher).where(
        func.lower(Teacher.email) == body.teacher_email.strip().lower())).first()
    if teacher is None:
        raise HTTPException(404, "That teacher is not on the approved list.")
    if teacher.user_id is None:
        raise HTTPException(400, "That teacher must sign in to the app once first.")

    subject = Subject(code=body.code.strip().upper(), name=body.name.strip(), color=body.color,
                      teacher_id=teacher.user_id, semester_id=body.semester_id,
                      class_id=body.class_id, kind=kind)
    db.add(subject)
    db.flush()
    added = 0
    if kind == "common":
        added = enroll_class_in_common_subjects(db, body.class_id, by_user_id=admin.id)
    db.commit()
    return {"id": str(subject.id), "students_enrolled": added}