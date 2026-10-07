from fastapi import Depends, HTTPException, Header
from sqlalchemy.orm import Session
from firebase_admin import auth as fb_auth

from app.core.database import get_db
from app.models.user import User

async def get_current_user(
    authorization: str = Header(...),
    db: Session = Depends(get_db),
) -> User:
    # 1. Pull the token out of "Bearer <token>"
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "Missing or malformed Authorization header")
    token = authorization.replace("Bearer ", "")

    # 2. Ask Firebase: is this a real, unexpired token?
    try:
        decoded = fb_auth.verify_id_token(token)
    except Exception:
        raise HTTPException(401, "Invalid or expired token")

    uid = decoded["uid"]
    email = decoded.get("email")

    # 3. Look up (or create) the matching row in our own users table
    user = db.query(User).filter(User.firebase_uid == uid).first()
    if user is None:
        user = User(firebase_uid=uid, email=email)
        db.add(user)
        db.commit()
        db.refresh(user)

    return user

# A second dependency that only lets teachers through
async def require_teacher(user: User = Depends(get_current_user)) -> User:
    if user.role != "teacher":
        raise HTTPException(403, "Teachers only")
    return user