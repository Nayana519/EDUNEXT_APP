from uuid import UUID
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select, or_
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.dependencies import get_current_user, require_teacher
from app.models.academic import Post, Subject, Enrollment, Notification

router = APIRouter(prefix="/feed", tags=["feed"])

def post_out(p: Post):
    return {
        "id": str(p.id),
        "subject_code": p.subject.code if p.subject else None,
        "color": p.subject.color if p.subject else "#1E2A44",
        "type": p.type, "title": p.title, "body": p.body,
        "tag": p.tag, "created_at": p.created_at.isoformat(),
    }

@router.get("")
def get_feed(subject_id: UUID | None = None,
             user=Depends(get_current_user), db: Session = Depends(get_db)):
    q = select(Post).order_by(Post.created_at.desc()).limit(50)
    if subject_id:
        q = q.where(Post.subject_id == subject_id)
    else:
        if user.role == "teacher":
            mine = select(Subject.id).where(Subject.teacher_id == user.id)
        else:
            mine = select(Enrollment.subject_id).where(Enrollment.user_id == user.id)
        q = q.where(or_(Post.subject_id.in_(mine), Post.subject_id.is_(None)))
    return [post_out(p) for p in db.scalars(q).all()]

class PostIn(BaseModel):
    subject_id: UUID | None = None
    title: str
    body: str = ""
    tag: str | None = None

@router.post("", status_code=201)
def create_post(data: PostIn, user=Depends(require_teacher), db: Session = Depends(get_db)):
    post = Post(subject_id=data.subject_id, author_id=user.id,
                title=data.title, body=data.body, tag=data.tag)
    db.add(post)
    if data.subject_id:
        student_ids = db.scalars(
            select(Enrollment.user_id).where(Enrollment.subject_id == data.subject_id))
        db.add_all([Notification(user_id=i, subject_id=data.subject_id, message=data.title)
                    for i in student_ids])
    db.commit()
    db.refresh(post)
    return post_out(post)
