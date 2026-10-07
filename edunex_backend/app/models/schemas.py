from pydantic import BaseModel
from uuid import UUID

class SubjectOut(BaseModel):
    id: UUID
    code: str
    name: str
    color: str | None

    class Config:
        from_attributes = True

class UserOut(BaseModel):
    id: UUID
    email: str
    role: str

    class Config:
        from_attributes = True