import re

COLLEGE_CODE = "CHN"
COLLEGE_EMAIL_DOMAIN = "ceconline.edu"

# While developing, Gmail test accounts must still work, so this is False.
# Set it to True before real students use the app.
ENFORCE_COLLEGE_EMAIL = False

_REG = re.compile(r"^([A-Z]{3})(\d{2})([A-Z]{2,3})(\d{3})$")
_EMAIL_LOCAL = re.compile(r"^([a-z]{3})(\d{2})([a-z]{2,4})(\d{3})$")


def normalize_reg(value: str | None) -> str:
    return "".join((value or "").split()).upper()


def parse_reg(value: str | None):
    """CHN23CS141 -> {'college': 'CHN', 'year': 2023, 'branch': 'CS', 'slot': 141}"""
    m = _REG.match(normalize_reg(value))
    if not m or m.group(1) != COLLEGE_CODE:
        return None
    return {"college": m.group(1), "year": 2000 + int(m.group(2)),
            "branch": m.group(3), "slot": int(m.group(4))}


def reg_problem(value: str | None) -> str | None:
    if parse_reg(value) is None:
        shown = normalize_reg(value) or "(empty)"
        return (f"'{shown}' is not a valid register number. It looks like "
                f"{COLLEGE_CODE}23CS141: college code, joining year, branch, 3-digit number.")
    return None


def email_problem_for_student(email: str | None, reg: str) -> str | None:
    if not ENFORCE_COLLEGE_EMAIL:
        return None
    local, _, domain = (email or "").strip().lower().partition("@")
    if domain != COLLEGE_EMAIL_DOMAIN:
        return f"Use your college email ending in @{COLLEGE_EMAIL_DOMAIN}."
    m = _EMAIL_LOCAL.match(local)
    info = parse_reg(reg)
    if not m or info is None:
        return "This does not look like a student college email."
    if m.group(1).upper() != info["college"] or 2000 + int(m.group(2)) != info["year"]:
        return "The joining year in your email does not match your register number."
    if m.group(3)[:2].upper() != info["branch"][:2]:
        return "The branch in your email does not match your register number."
    return None


def email_problem_for_teacher(email: str | None) -> str | None:
    if not ENFORCE_COLLEGE_EMAIL:
        return None
    if not (email or "").strip().lower().endswith("@" + COLLEGE_EMAIL_DOMAIN):
        return f"Teachers must use their institution email ending in @{COLLEGE_EMAIL_DOMAIN}."
    return None