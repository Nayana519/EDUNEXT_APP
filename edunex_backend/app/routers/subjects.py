from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID
from app.core.database import get_db
from app.models.academic import Subject
from pydantic import BaseModel

router = APIRouter(prefix="/subjects", tags=["subjects"])

# The validation rules for the incoming subject text data layout
class SubjectCreate(BaseModel):
    code: str
    name: str
    color: str = "#2F6F4E" # Default green if they skip choosing a custom color

@router.post("", status_code=status.HTTP_201_CREATED)
def teacher_create_subject(
    subject_data: SubjectCreate, 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user) # 👈 Phase 3 Guard: Extracts the logged-in user context
):
    # 1. Access Check: Security gate to stop students from faking requests
    if current_user.role != "teacher":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Access Denied: Only teachers can create new subjects."
        )
        
    # 2. Map data and automatically bind the logged-in teacher's ID
    new_subject = Subject(
        code=subject_data.code,
        name=subject_data.name,
        color=subject_data.color,
        teacher_id=current_user.id  # 👈 Manually allocates their ID securely on the server!
    )
    
    db.add(new_subject)
    db.commit()
    db.refresh(new_subject)
    
    return {"message": "Subject created successfully!", "subject_id": new_subject.id}

from app.models.academic import Enrollment

@router.post("/{subject_id}/enroll", status_code=status.HTTP_201_CREATED)
def student_enroll_in_subject(
    subject_id: UUID,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # 1. Access Check: Stop teachers from accidentally enrolling as students
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Only student accounts can enroll in courses."
        )
        
    # 2. Check if the subject actually exists in your Supabase table
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="The selected subject/teacher code was not found.")
        
    # 3. Check if the student is already enrolled to prevent duplication crashes
    already_enrolled = db.query(Enrollment).filter(
        Enrollment.user_id == current_user.id,
        Enrollment.subject_id == subject_id
    ).first()
    
    if already_enrolled:
        raise HTTPException(status_code=400, detail="You are already enrolled in this class.")

    # 4. Insert the linking row into your live 'enrollments' table!
    new_enrollment = Enrollment(
        user_id=current_user.id,
        subject_id=subject_id
    )
    
    db.add(new_enrollment)
    db.commit()
    
    return {"status": "success", "message": f"Successfully assigned to class managed by Teacher ID: {subject.teacher_id}"}
