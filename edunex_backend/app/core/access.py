from fastapi import Depends, HTTPException
from sqlalchemy import false, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies import get_current_user
from app.models.academic import Enrollment, Subject
from app.models.college import ClassStudent, Student, Teacher


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


def can_post_to_class(db: Session, user, class_id) -> bool:
    t = get_teacher(db, user) if user.role == "teacher" else None
    if t is None:
        return False
    if t.is_admin:
        return True
    return db.scalars(select(Subject.id).where(
        Subject.class_id == class_id, Subject.teacher_id == user.id).limit(1)).first() is not None


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
        return select(Subject.class_id).where(
            Subject.teacher_id == user.id, Subject.class_id.is_not(None))
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