from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies import get_current_user
from app.models.college import Student, Teacher
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterRequest(BaseModel):
    role: str
    register_number: str | None = None


def _profile(db: Session, user: User) -> dict:
    student = db.scalars(select(Student).where(Student.user_id == user.id)).first()
    teacher = db.scalars(select(Teacher).where(Teacher.user_id == user.id)).first()
    name = (student.name if student else None) or (teacher.name if teacher else None) or user.name
    return {
        "id": str(user.id),
        "email": user.email,
        "name": name,
        "role": user.role,
        "register_number": student.register_number if student else None,
        "is_admin": bool(teacher and teacher.is_admin),
    }


@router.post("/register")
def register(body: RegisterRequest, db: Session = Depends(get_db),
             user: User = Depends(get_current_user)):
    role = body.role.strip().lower()
    if role not in ("student", "teacher"):
        raise HTTPException(400, "Role must be 'student' or 'teacher'.")
    if user.role is not None:                       # role is set once
        return _profile(db, user)
    if not getattr(user, "token_email_verified", False):
        raise HTTPException(403, "Verify your email first, or sign in with Google.")

    email = (user.email or "").strip().lower()

    if role == "teacher":
        teacher = db.scalars(select(Teacher).where(func.lower(Teacher.email) == email)).first()
        if teacher is None:
            raise HTTPException(403, "This email is not on the approved teacher list.")
        if teacher.user_id not in (None, user.id):
            raise HTTPException(409, "This teacher record is already linked to another account.")
        teacher.user_id = user.id
    else:
        reg = (body.register_number or "").strip().upper()
        if not reg:
            raise HTTPException(400, "Enter your register number.")
        student = db.scalars(select(Student).where(Student.register_number == reg)).first()
        if student is None:
            raise HTTPException(403, "Register number not found. Ask your class teacher to add you.")
        if student.user_id not in (None, user.id):
            raise HTTPException(409, "This register number is already linked to another account.")
        if student.college_email and student.college_email.strip().lower() != email:
            raise HTTPException(403, "This email does not match the college record.")
        student.user_id = user.id

    user.role = role
    db.commit()
    db.refresh(user)
    return _profile(db, user)


@router.get("/me")
def me(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return _profile(db, user)