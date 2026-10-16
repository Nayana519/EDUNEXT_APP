from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.dependencies import get_current_user
from app.models.academic import Notification

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("")
def list_notifications(user=Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.scalars(select(Notification)
                      .where(Notification.user_id == user.id)
                      .order_by(Notification.created_at.desc()).limit(50)).all()
    return [{"id": str(n.id), "message": n.message, "read": n.read,
             "created_at": n.created_at.isoformat()} for n in rows]

@router.patch("/{notification_id}/read")
def mark_read(notification_id: UUID, user=Depends(get_current_user),
              db: Session = Depends(get_db)):
    n = db.get(Notification, notification_id)
    if n is None or n.user_id != user.id:
        raise HTTPException(404, "Not found")
    n.read = True
    db.commit()
    return {"ok": True}