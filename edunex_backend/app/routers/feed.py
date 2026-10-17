from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.access import (can_manage_subject, can_post_to_class, ensure_can_view_subject,
                             get_teacher, user_ids_for_class, user_ids_for_subject,
                             visible_class_ids, visible_subjects)
from app.core.database import get_db
from app.dependencies import get_current_user, require_teacher
from app.models.academic import Notification, Post, Subject
from app.models.college import ClassGroup, ClassAdvisor

router = APIRouter(prefix="/feed", tags=["feed"])


def post_out(p: Post, db: Session) -> dict:
    if p.subject is not None:
        label, color = p.subject.code, p.subject.color
    elif p.class_id is not None:
        cg = db.get(ClassGroup, p.class_id)
        label, color = (cg.name if cg else "Class"), "#1E2A44"
    else:
        label, color = None, "#1E2A44"
    return {"id": str(p.id), "subject_code": label, "color": color, "type": p.type,
            "title": p.title, "body": p.body, "tag": p.tag,
            "created_at": p.created_at.isoformat()}


@router.get("")
def get_feed(subject_id: UUID | None = None, user=Depends(get_current_user),
             db: Session = Depends(get_db)):
    q = select(Post).order_by(Post.created_at.desc()).limit(50)
    if subject_id:
        ensure_can_view_subject(db, user, subject_id)
        q = q.where(Post.subject_id == subject_id)
    else:
        teacher = get_teacher(db, user) if user.role == "teacher" else None
        if not (teacher and teacher.is_admin):
            q = q.where(or_(
                Post.subject_id.in_(visible_subjects(db, user, Subject.id)),
                Post.class_id.in_(visible_class_ids(db, user))))
    return [post_out(p, db) for p in db.scalars(q).all()]


@router.get("/targets")
def post_targets(user=Depends(require_teacher), db: Session = Depends(get_db)):
    teacher = get_teacher(db, user)
    is_admin = bool(teacher and teacher.is_admin)

    sq = select(Subject).order_by(Subject.code)
    if not is_admin:
        sq = sq.where(Subject.teacher_id == user.id)
    subjects = db.scalars(sq).all()

    if is_admin:
        classes = db.scalars(select(ClassGroup).order_by(ClassGroup.name)).all()
    else:
        classes = db.scalars(
            select(ClassGroup)
            .where(ClassGroup.id.in_(
                select(ClassAdvisor.class_id).where(ClassAdvisor.user_id == user.id)))
            .order_by(ClassGroup.name)).all()

    return {
        "subjects": [{"id": str(s.id), "code": s.code, "name": s.name} for s in subjects],
        "classes": [{"id": str(c.id), "name": c.name} for c in classes],
    }


class PostIn(BaseModel):
    subject_id: UUID | None = None   # a subject announcement ...
    class_id: UUID | None = None     # ... or a whole-class announcement
    title: str
    body: str = ""
    tag: str | None = None


@router.post("", status_code=201)
def create_post(data: PostIn, user=Depends(require_teacher), db: Session = Depends(get_db)):
    if (data.subject_id is None) == (data.class_id is None):
        raise HTTPException(400, "Choose either a subject or a class.")

    if data.subject_id:
        subject = db.get(Subject, data.subject_id)
        if subject is None:
            raise HTTPException(404, "Subject not found.")
        if not can_manage_subject(db, user, subject):
            raise HTTPException(403, "You do not manage this subject.")
        recipients = user_ids_for_subject(db, subject.id)
    else:
        if not can_post_to_class(db, user, data.class_id):
            raise HTTPException(403, "You cannot post to this class.")
        recipients = user_ids_for_class(db, data.class_id)

    post = Post(subject_id=data.subject_id, class_id=data.class_id, author_id=user.id,
                title=data.title, body=data.body, tag=data.tag)
    db.add(post)
    db.add_all([Notification(user_id=uid, subject_id=data.subject_id, message=data.title)
                for uid in recipients])
    db.commit()
    db.refresh(post)
    return post_out(post, db)