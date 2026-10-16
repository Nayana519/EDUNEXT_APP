# Only these emails can become teachers. Put real faculty emails here.
APPROVED_TEACHER_EMAILS = {
    "teacher@email.com",
}


def is_approved_teacher(email: str | None) -> bool:
    return bool(email) and email.strip().lower() in APPROVED_TEACHER_EMAILS