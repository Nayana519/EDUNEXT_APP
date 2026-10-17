from fastapi import Depends, HTTPException
from sqlalchemy import false, or_,select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies import get_current_user
from app.models.academic import Enrollment, Subject
from app.models.college import (ClassAdvisor, ClassGroup, ClassStudent, EnrollmentAudit,
                                Student, Teacher)

def get_student(db: Session, user):
    return db.scalars(select(Student).where(Student.user_id == user.id)).first()


def get_teacher(db: Session, user):
    return db.scalars(select(Teacher).where(Teacher.user_id == user.id)).first()


def require_admin(user=Depends(get_current_user), db: Session = Depends(get_db)):
    t = get_teacher(db, user) if user.role == "teacher" else None
    if t is None or not t.is_admin:
        raise HTTPException(403, "Admins only.")
    return user


def can_manage_subject(db: Session, user, subject) -> bool:
    if user.role != "teacher":
        return False
    t = get_teacher(db, user)
    if t is not None and t.is_admin:
        return True
    return subject.teacher_id == user.id

def can_manage_class(db: Session, user, class_id) -> bool:
    """Admin, or a class advisor of that class."""
    if user.role != "teacher":
        return False
    t = get_teacher(db, user)
    if t is not None and t.is_admin:
        return True
    return db.get(ClassAdvisor, (class_id, user.id)) is not None


def can_post_to_class(db: Session, user, class_id) -> bool:
    return can_manage_class(db, user, class_id)



def visible_subjects(db: Session, user, *cols):
    """A SELECT of the subjects this user is allowed to see."""
    stmt = select(*(cols or (Subject,)))
    if user.role == "teacher":
        t = get_teacher(db, user)
        if t is not None and t.is_admin:
            return stmt
        return stmt.where(Subject.teacher_id == user.id)
    student = get_student(db, user)
    if student is None:
        return stmt.where(false())
    return (stmt.join(Enrollment, Enrollment.subject_id == Subject.id)
                .where(Enrollment.student_id == student.id))


def visible_class_ids(db: Session, user):
    if user.role == "teacher":
        taught = select(Subject.class_id).where(
            Subject.teacher_id == user.id, Subject.class_id.is_not(None))
        advised = select(ClassAdvisor.class_id).where(ClassAdvisor.user_id == user.id)
        return select(ClassGroup.id).where(
            or_(ClassGroup.id.in_(taught), ClassGroup.id.in_(advised)))
    student = get_student(db, user)
    return select(ClassStudent.class_id).where(
        ClassStudent.student_id == (student.id if student else None))


def ensure_can_view_subject(db: Session, user, subject_id):
    ok = db.scalars(visible_subjects(db, user, Subject.id)
                    .where(Subject.id == subject_id)).first()
    if ok is None:
        raise HTTPException(403, "You are not part of this subject.")


def user_ids_for_subject(db: Session, subject_id) -> list:
    q = (select(Student.user_id)
         .join(Enrollment, Enrollment.student_id == Student.id)
         .where(Enrollment.subject_id == subject_id, Student.user_id.is_not(None)))
    return list(db.scalars(q))


def user_ids_for_class(db: Session, class_id) -> list:
    q = (select(Student.user_id)
         .join(ClassStudent, ClassStudent.student_id == Student.id)
         .where(ClassStudent.class_id == class_id, Student.user_id.is_not(None)))
    return list(db.scalars(q))


def enroll_class_in_common_subjects(db: Session, class_id, by_user_id=None) -> int:
    """Puts every student of the class into every COMMON subject of that class."""
    subjects = db.scalars(select(Subject).where(
        Subject.class_id == class_id, Subject.kind == "common")).all()
    student_ids = list(db.scalars(
        select(ClassStudent.student_id).where(ClassStudent.class_id == class_id)))
    added = 0
    for s in subjects:
        have = set(db.scalars(select(Enrollment.student_id).where(Enrollment.subject_id == s.id)))
        for sid in student_ids:
            if sid not in have:
                db.add(Enrollment(student_id=sid, subject_id=s.id,
                                  source="common_auto", added_by=by_user_id))
                added += 1
    return added

def drop_common_enrollments(db: Session, class_id, student_id, by_user_id, reason) -> int:
    """When a student leaves a class, remove only the AUTOMATIC enrollments of its common
    subjects. Electives and manual additions stay."""
    subject_ids = list(db.scalars(select(Subject.id).where(
        Subject.class_id == class_id, Subject.kind == "common")))
    removed = 0
    for sid in subject_ids:
        e = db.get(Enrollment, (student_id, sid))
        if e is not None and e.source == "common_auto":
            db.delete(e)
            db.add(EnrollmentAudit(subject_id=sid, student_id=student_id, action="remove",
                                   reason=reason, by_user_id=by_user_id))
            removed += 1
    return removed