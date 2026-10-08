import sys
from datetime import date, timedelta
from app.core.database import get_db
from app.models.user import User
from app.models.academic import Subject, Enrollment, Post, Assignment

teacher_email, student_email = sys.argv[1], sys.argv[2]
db = next(get_db())

teacher = db.query(User).filter(User.email == teacher_email).first()
student = db.query(User).filter(User.email == student_email).first()
teacher.role = "teacher"
student.role = "student"

data = [
    ("CS301", "Database Systems", "#2F6F4E"),
    ("CS302", "Operating Systems", "#3E6E9E"),
    ("CS303", "Computer Networks", "#E2963A"),
    ("CS304", "Software Engineering", "#7A4B6B"),
]
for code, name, color in data:
    s = Subject(code=code, name=name, color=color, teacher_id=teacher.id)
    db.add(s)
    db.flush()
    db.add(Enrollment(user_id=student.id, subject_id=s.id))
    db.add(Post(subject_id=s.id, author_id=teacher.id, title=f"Welcome to {name}",
                body="First announcement for this subject.", tag="Info"))
    db.add(Assignment(subject_id=s.id, title=f"{code} Assignment 1",
                      due_date=date.today() + timedelta(days=7)))
db.commit()
print("Done")