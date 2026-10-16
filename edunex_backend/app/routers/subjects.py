from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.access import can_manage_subject, visible_subjects
from app.core.database import get_db
from app.dependencies import get_current_user
from app.models.academic import Enrollment, Notification, Subject
from app.models.college import EnrollmentAudit, Student

router = APIRouter(prefix="/subjects", tags=["subjects"])


def _managed(db: Session, user, subject_id: UUID) -> Subject:
    subject = db.get(Subject, subject_id)
    if subject is None:
        raise HTTPException(404, "Subject not found.")
    if not can_manage_subject(db, user, subject):
        raise HTTPException(403, "You do not manage this subject.")
    return subject


@router.get("")
def list_subjects(db: Session = Depends(get_db), user=Depends(get_current_user)):
    rows = db.scalars(visible_subjects(db, user).order_by(Subject.code)).all()
    return [{"id": str(s.id), "code": s.code, "name": s.name, "color": s.color,
             "kind": s.kind, "class_id": str(s.class_id) if s.class_id else None}
            for s in rows]


@router.get("/{subject_id}/students")
def list_enrolled(subject_id: UUID, db: Session = Depends(get_db), user=Depends(get_current_user)):
    _managed(db, user, subject_id)
    rows = db.execute(
        select(Student, Enrollment)
        .join(Enrollment, Enrollment.student_id == Student.id)
        .where(Enrollment.subject_id == subject_id)
        .order_by(Student.register_number)).all()
    return [{"register_number": st.register_number, "name": st.name,
             "source": en.source, "account_linked": st.user_id is not None}
            for st, en in rows]


class AddStudent(BaseModel):
    register_number: str
    reason: str | None = None


@router.post("/{subject_id}/students", status_code=201)
def add_student(subject_id: UUID, body: AddStudent, db: Session = Depends(get_db),
                user=Depends(get_current_user)):
    subject = _managed(db, user, subject_id)
    reg = body.register_number.strip().upper()
    student = db.scalars(select(Student).where(Student.register_number == reg)).first()
    if student is None:
        raise HTTPException(404, "No approved student has that register number.")
    if db.get(Enrollment, (student.id, subject.id)) is not None:
        raise HTTPException(400, "This student is already enrolled.")

    db.add(Enrollment(student_id=student.id, subject_id=subject.id,
                      source="manual", added_by=user.id))
    db.add(EnrollmentAudit(subject_id=subject.id, student_id=student.id, action="add",
                           reason=body.reason, by_user_id=user.id))
    if student.user_id:
        db.add(Notification(user_id=student.user_id, subject_id=subject.id,
                            message=f"You were added to {subject.code} {subject.name}"))
    db.commit()
    return {"status": "added"}


@router.delete("/{subject_id}/students/{register_number}")
def remove_student(subject_id: UUID, register_number: str,
                   reason: str = Query(..., min_length=3),
                   db: Session = Depends(get_db), user=Depends(get_current_user)):
    subject = _managed(db, user, subject_id)
    student = db.scalars(select(Student).where(
        Student.register_number == register_number.strip().upper())).first()
    enrollment = db.get(Enrollment, (student.id, subject.id)) if student else None
    if enrollment is None:
        raise HTTPException(404, "This student is not enrolled.")

    db.delete(enrollment)
    db.add(EnrollmentAudit(subject_id=subject.id, student_id=student.id, action="remove",
                           reason=reason, by_user_id=user.id))
    db.commit()
    return {"status": "removed"}