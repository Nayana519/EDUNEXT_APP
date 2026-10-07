from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies import get_current_user
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["auth"])

class RegisterRequest(BaseModel):
    role: str  # "student" or "teacher"

class UserResponse(BaseModel):
    id: str
    email: str | None
    name: str | None
    role: str | None

    class Config:
        from_attributes = True

@router.post("/register", response_model=UserResponse)
def register(
    body: RegisterRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),  # this line already created the row if new
):
    # This is the ONLY place role ever gets set
    if user.role is None:
        user.role = body.role
        db.commit()
        db.refresh(user)
    return user

@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    return user