import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


def _pk():
    return mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)


class Semester(Base):
    __tablename__ = "semesters"
    __table_args__ = (UniqueConstraint("academic_year", "name"),)
    id: Mapped[uuid.UUID] = _pk()
    academic_year: Mapped[str] = mapped_column(String(20))   # 2026-27
    name: Mapped[str] = mapped_column(String(20))            # S7
    is_current: Mapped[bool] = mapped_column(Boolean, default=False)


class ClassGroup(Base):
    __tablename__ = "classes"
    __table_args__ = (UniqueConstraint("name", "semester_id"),)
    id: Mapped[uuid.UUID] = _pk()
    name: Mapped[str] = mapped_column(String(60))            # S7 CSE-D
    department: Mapped[str] = mapped_column(String(60), default="CSE")
    semester_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("semesters.id"))


class Student(Base):
    __tablename__ = "students"
    id: Mapped[uuid.UUID] = _pk()
    register_number: Mapped[str] = mapped_column(String(30), unique=True)
    name: Mapped[str] = mapped_column(String(120))
    college_email: Mapped[str | None] = mapped_column(String(200), nullable=True)
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), unique=True, nullable=True)  # filled when they register
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Teacher(Base):
    __tablename__ = "teachers"
    id: Mapped[uuid.UUID] = _pk()
    email: Mapped[str] = mapped_column(String(200), unique=True)
    name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), unique=True, nullable=True)


class ClassStudent(Base):
    __tablename__ = "class_students"
    class_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("classes.id"), primary_key=True)
    student_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("students.id"), primary_key=True)


class EnrollmentAudit(Base):
    __tablename__ = "enrollment_audit"
    id: Mapped[uuid.UUID] = _pk()
    subject_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("subjects.id"))
    student_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("students.id"))
    action: Mapped[str] = mapped_column(String(10))          # add / remove
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    by_user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class ImportBatch(Base):
    __tablename__ = "import_batches"
    id: Mapped[uuid.UUID] = _pk()
    kind: Mapped[str] = mapped_column(String(20))              # students | enrollments
    semester_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("semesters.id"))
    filename: Mapped[str] = mapped_column(String(200))
    status: Mapped[str] = mapped_column(String(12), default="preview")  # preview | confirmed
    summary: Mapped[dict] = mapped_column(JSONB, default=dict)
    plan: Mapped[list] = mapped_column(JSONB, default=list)
    created_by: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())