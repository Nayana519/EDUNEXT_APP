from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.access import (can_manage_class, drop_common_enrollments,
                             enroll_class_in_common_subjects, get_teacher)
from app.core.college_rules import normalize_reg, reg_problem
from app.core.database import get_db
from app.dependencies import require_teacher
from app.models.college import ClassAdvisor, ClassGroup, ClassStudent, Student

router = APIRouter(prefix="/classes", tags=["classes"])


def _managed(db: Session, user, class_id: UUID) -> ClassGroup:
    cg = db.get(ClassGroup, class_id)
    if cg is None:
        raise HTTPException(404, "Class not found.")
    if not can_manage_class(db, user, class_id):
        raise HTTPException(403, "You are not the advisor of this class.")
    return cg


@router.get("/mine")
def my_classes(user=Depends(require_teacher), db: Session = Depends(get_db)):
    t = get_teacher(db, user)
    q = select(ClassGroup).order_by(ClassGroup.name)
    if not (t and t.is_admin):
        q = q.where(ClassGroup.id.in_(
            select(ClassAdvisor.class_id).where(ClassAdvisor.user_id == user.id)))
    out = []
    for c in db.scalars(q).all():
        n = db.scalar(select(func.count()).select_from(ClassStudent)
                      .where(ClassStudent.class_id == c.id))
        out.append({"id": str(c.id), "name": c.name, "students": n or 0})
    return out


@router.get("/{class_id}/students")
def class_students(class_id: UUID, user=Depends(require_teacher),
                   db: Session = Depends(get_db)):
    _managed(db, user, class_id)
    rows = db.scalars(select(Student)
                      .join(ClassStudent, ClassStudent.student_id == Student.id)
                      .where(ClassStudent.class_id == class_id)
                      .order_by(Student.register_number)).all()
    return [{"register_number": s.register_number, "name": s.name,
             "account_linked": s.user_id is not None} for s in rows]


class AddToClass(BaseModel):
    register_number: str
    name: str | None = None            # needed only when the student is new
    college_email: str | None = None


@router.post("/{class_id}/students", status_code=201)
def add_to_class(class_id: UUID, body: AddToClass, user=Depends(require_teacher),
                 db: Session = Depends(get_db)):
    cg = _managed(db, user, class_id)
    reg = normalize_reg(body.register_number)
    problem = reg_problem(reg)
    if problem:
        raise HTTPException(400, problem)

    student = db.scalars(select(Student).where(Student.register_number == reg)).first()
    if student is None:
        name = (body.name or "").strip()
        if not name:
            raise HTTPException(404, "This register number is new. Enter the student's name to add them.")
        email = (body.college_email or "").strip().lower() or None
        student = Student(register_number=reg, name=name, college_email=email)
        db.add(student)
        db.flush()

    # a student belongs to one class per semester
    other = db.execute(
        select(ClassGroup.name)
        .join(ClassStudent, ClassStudent.class_id == ClassGroup.id)
        .where(ClassStudent.student_id == student.id,
               ClassGroup.semester_id == cg.semester_id)).first()
    if other is not None:
        raise HTTPException(409, f"{reg} is already in {other[0]} this semester.")

    db.add(ClassStudent(class_id=class_id, student_id=student.id))
    db.flush()
    added = enroll_class_in_common_subjects(db, class_id, by_user_id=user.id)
    db.commit()
    return {"status": "added", "common_subject_enrollments": added}


@router.delete("/{class_id}/students/{register_number}")
def remove_from_class(class_id: UUID, register_number: str,
                      reason: str = Query(..., min_length=3),
                      user=Depends(require_teacher), db: Session = Depends(get_db)):
    _managed(db, user, class_id)
    student = db.scalars(select(Student).where(
        Student.register_number == normalize_reg(register_number))).first()
    link = db.get(ClassStudent, (class_id, student.id)) if student else None
    if link is None:
        raise HTTPException(404, "This student is not in the class.")

    dropped = drop_common_enrollments(db, class_id, student.id, user.id, reason)
    db.delete(link)
    db.commit()
    return {"status": "removed", "common_subject_enrollments_removed": dropped}