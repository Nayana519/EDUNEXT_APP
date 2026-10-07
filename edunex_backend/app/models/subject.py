import uuid
from sqlalchemy import Column, String, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.models.base import Base

class Subject(Base):
    __tablename__ = "subjects"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = Column(String)
    name = Column(String)
    color = Column(String)
    teacher_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)