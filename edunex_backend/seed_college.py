import sys

from sqlalchemy import func, select

from app.core.access import enroll_class_in_common_subjects
from app.core.database import get_db
from app.models.academic import Enrollment, Subject
from app.models.college import ClassGroup, ClassStudent, Semester, Student, Teacher
from app.models.user import User

if len(sys.argv) != 4:
    sys.exit("Usage: python seed_college.py ADMIN_EMAIL STUDENT_EMAIL STUDENT_REGISTER_NUMBER")

admin_email, student_email, student_reg = sys.argv[1].lower(), sys.argv[2].lower(), sys.argv[3].upper()
db = next(get_db())


def find_user(email):
    return db.scalars(select(User).where(func.lower(User.email) == email)).first()


admin_user, student_user = find_user(admin_email), find_user(student_email)
if admin_user is None or student_user is None:
    sys.exit("Log in to the app once with BOTH emails first, then run this again.")
if db.scalars(select(Semester)).first():
    sys.exit("Already seeded.")

admin_user.role = "teacher"
student_user.role = "student"
db.add(Teacher(email=admin_email, name="Admin Teacher", is_admin=True, user_id=admin_user.id))

sem = Semester(academic_year="2026-27", name="S7", is_current=True)
db.add(sem)
db.flush()
cls = ClassGroup(name="S7 CSE-D", department="CSE", semester_id=sem.id)
db.add(cls)
db.flush()

students = [
    Student(register_number=student_reg, name=student_email.split("@")[0],
            college_email=student_email, user_id=student_user.id),
    Student(register_number="CEC001", name="Sample Student 1"),
    Student(register_number="CEC002", name="Sample Student 2"),
]
db.add_all(students)
db.flush()
for s in students:
    db.add(ClassStudent(class_id=cls.id, student_id=s.id))

common = Subject(code="CST401", name="Sample Common Subject", color="#2F6F4E",
                 teacher_id=admin_user.id, semester_id=sem.id, class_id=cls.id, kind="common")
elective = Subject(code="CST412", name="Sample Elective", color="#3E6E9E",
                   teacher_id=admin_user.id, semester_id=sem.id, class_id=cls.id, kind="elective")
db.add_all([common, elective])
db.flush()

enroll_class_in_common_subjects(db, cls.id)           # everyone gets CST401
for s in (students[0], students[1]):                  # only 2 students take the elective
    db.add(Enrollment(student_id=s.id, subject_id=elective.id,
                      source="manual", added_by=admin_user.id))
db.commit()
print("Done.")