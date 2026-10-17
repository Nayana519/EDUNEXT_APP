from types import SimpleNamespace

import pytest
from fastapi import FastAPI, HTTPException, Request
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import app.models.academic  # noqa: F401  (registers the tables)
import app.models.college   # noqa: F401
from app.core import college_rules
from app.core.access import enroll_class_in_common_subjects
from app.core.database import Base, get_db
from app.dependencies import get_current_user
from app.models.academic import Enrollment, Notification, Subject
from app.models.college import (ClassAdvisor, ClassGroup, ClassStudent, Semester,
                                Student, Teacher)
from app.models.user import User
from app.routers import admin, auth, classes, feed, materials, subjects
from app.routers.imports import _plan_enrollments, _plan_students


@compiles(JSONB, "sqlite")
def _jsonb_for_sqlite(type_, compiler, **kw):
    return "JSON"


def H(email):
    return {"x-test-user": email}


@pytest.fixture()
def world():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False},
                           poolclass=StaticPool)
    Base.metadata.create_all(engine)
    db = sessionmaker(bind=engine, expire_on_commit=False)()

    def mkuser(email, role):
        u = User(firebase_uid=email, email=email, role=role)
        db.add(u)
        db.flush()
        return u

    sem = Semester(academic_year="2026-27", name="S7", is_current=True)
    db.add(sem)
    db.flush()
    class_a = ClassGroup(name="S7 CSE-A", semester_id=sem.id)
    class_b = ClassGroup(name="S7 CSE-B", semester_id=sem.id)
    db.add_all([class_a, class_b])
    db.flush()

    t1 = mkuser("t1@c.com", "teacher")        # advisor of class A
    t2 = mkuser("t2@c.com", "teacher")        # advisor of nothing
    db.add_all([Teacher(email="t1@c.com", user_id=t1.id),
                Teacher(email="t2@c.com", user_id=t2.id),
                ClassAdvisor(class_id=class_a.id, user_id=t1.id)])

    s1u, s2u, s3u = (mkuser(f"s{i}@c.com", "student") for i in (1, 2, 3))
    s1 = Student(register_number="CHN23CS001", name="One", user_id=s1u.id)
    s2 = Student(register_number="CHN23CS002", name="Two", user_id=s2u.id)
    s3 = Student(register_number="CHN23CS101", name="Three", user_id=s3u.id)
    spare = Student(register_number="CHN23CS005", name="Spare")   # in no class yet
    db.add_all([s1, s2, s3, spare])
    db.flush()
    db.add_all([ClassStudent(class_id=class_a.id, student_id=s1.id),
                ClassStudent(class_id=class_a.id, student_id=s2.id),
                ClassStudent(class_id=class_b.id, student_id=s3.id)])

    def subject(code, teacher, cls, kind):
        s = Subject(code=code, name=code, teacher_id=teacher.id, semester_id=sem.id,
                    class_id=cls.id, kind=kind)
        db.add(s)
        db.flush()
        return s

    common_a = subject("CST401", t1, class_a, "common")
    elective_a = subject("CST412", t1, class_a, "elective")
    subject_b = subject("CST501", t2, class_b, "common")
    enroll_class_in_common_subjects(db, class_a.id)
    enroll_class_in_common_subjects(db, class_b.id)
    db.add(Enrollment(student_id=s1.id, subject_id=elective_a.id, source="manual"))

    # accounts that have not registered yet
    for email in ("new1@c.com", "new2@c.com", "faketeacher@c.com",
                  "chn23csd006@ceconline.edu", "chn24csd006@ceconline.edu"):
        mkuser(email, None)
    db.add_all([Student(register_number="CHN23CS003", name="Free", college_email="new1@c.com"),
                Student(register_number="CHN23CS004", name="Other",
                        college_email="someone@else.com"),
                Student(register_number="CHN23CS006", name="Rules")])
    db.commit()
    return SimpleNamespace(db=db, sem=sem, class_a=class_a, common_a=common_a,
                           elective_a=elective_a, subject_b=subject_b,
                           s1=s1, s1u=s1u, s2u=s2u, spare=spare)


@pytest.fixture()
def client(world):
    app = FastAPI()
    for r in (auth.router, subjects.router, feed.router, materials.router,
              admin.router, classes.router):
        app.include_router(r)

    def _db():
        yield world.db

    def _user(request: Request):
        u = world.db.scalars(select(User).where(
            User.email == request.headers.get("x-test-user"))).first()
        if u is None:
            raise HTTPException(401, "unknown test user")
        u.token_email_verified = True
        return u

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[get_current_user] = _user
    return TestClient(app)


# ---------------- who sees what ----------------
def test_electives_are_not_automatic(client):
    codes = lambda e: {s["code"] for s in client.get("/subjects", headers=H(e)).json()}
    assert codes("s1@c.com") == {"CST401", "CST412"}
    assert codes("s2@c.com") == {"CST401"}
    assert codes("s3@c.com") == {"CST501"}


def test_wrong_class_cannot_read_feed(client, world):
    r = client.get("/feed", params={"subject_id": str(world.common_a.id)},
                   headers=H("s3@c.com"))
    assert r.status_code == 403


def test_unenrolled_student_cannot_list_materials(client, world):
    r = client.get("/materials", params={"subject_id": str(world.elective_a.id)},
                   headers=H("s2@c.com"))
    assert r.status_code == 403


def test_student_cannot_post(client, world):
    r = client.post("/feed", json={"subject_id": str(world.common_a.id), "title": "x"},
                    headers=H("s1@c.com"))
    assert r.status_code == 403


def test_teacher_cannot_post_to_another_teachers_subject(client, world):
    r = client.post("/feed", json={"subject_id": str(world.common_a.id), "title": "x"},
                    headers=H("t2@c.com"))
    assert r.status_code == 403


def test_teacher_cannot_see_another_teachers_roster(client, world):
    r = client.get(f"/subjects/{world.subject_b.id}/students", headers=H("t1@c.com"))
    assert r.status_code == 403


# ---------------- notifications ----------------
def test_subject_post_notifies_only_enrolled_students(client, world):
    r = client.post("/feed", json={"subject_id": str(world.elective_a.id), "title": "News"},
                    headers=H("t1@c.com"))
    assert r.status_code == 201
    assert {n.user_id for n in world.db.scalars(select(Notification))} == {world.s1u.id}


def test_class_post_by_advisor_notifies_the_whole_class(client, world):
    r = client.post("/feed", json={"class_id": str(world.class_a.id), "title": "News"},
                    headers=H("t1@c.com"))
    assert r.status_code == 201
    assert {n.user_id for n in world.db.scalars(select(Notification))} == {
        world.s1u.id, world.s2u.id}


def test_only_the_advisor_can_post_to_the_class(client, world):
    r = client.post("/feed", json={"class_id": str(world.class_a.id), "title": "News"},
                    headers=H("t2@c.com"))
    assert r.status_code == 403


# ---------------- subject rosters, duplicates, audit ----------------
def test_duplicate_enrollment_is_refused(client, world):
    r = client.post(f"/subjects/{world.elective_a.id}/students",
                    json={"register_number": "CHN23CS001"}, headers=H("t1@c.com"))
    assert r.status_code == 400


def test_removal_needs_a_reason_and_is_audited(client, world):
    url = f"/subjects/{world.elective_a.id}/students/CHN23CS001"
    assert client.delete(url, headers=H("t1@c.com")).status_code == 422
    assert client.delete(url, params={"reason": "dropped course"},
                         headers=H("t1@c.com")).status_code == 200
    log = client.get(f"/subjects/{world.elective_a.id}/audit", headers=H("t1@c.com")).json()
    assert log[0]["action"] == "remove" and log[0]["reason"] == "dropped course"


def test_elective_can_include_a_student_from_another_class(client, world):
    r = client.post(f"/subjects/{world.elective_a.id}/students",
                    json={"register_number": "CHN23CS101"}, headers=H("t1@c.com"))
    assert r.status_code == 201
    roster = client.get(f"/subjects/{world.elective_a.id}/students", headers=H("t1@c.com")).json()
    assert "CHN23CS101" in {s["register_number"] for s in roster}


# ---------------- imports ----------------
def test_import_flags_bad_rows(world):
    rows = [{"register_number": "CHN23CS200", "name": "New", "class": "S7 CSE-A"},
            {"register_number": "chn23cs200", "name": "New", "class": "S7 CSE-A"},
            {"register_number": "CHN23CS201", "name": "Other", "class": "S9 NOPE"},
            {"register_number": "BADNUMBER", "name": "Bad", "class": "S7 CSE-A"}]
    _, summary, errors, _ = _plan_students(world.db, world.sem.id, rows)
    assert summary["to_apply"] == 1 and len(errors) == 3


def test_import_does_not_move_a_student_between_classes(world):
    rows = [{"register_number": "CHN23CS101", "class": "S7 CSE-A"}]
    _, summary, _, conflicts = _plan_students(world.db, world.sem.id, rows)
    assert summary["to_apply"] == 0 and len(conflicts) == 1


def test_import_does_not_readd_a_removed_student(client, world):
    client.delete(f"/subjects/{world.elective_a.id}/students/CHN23CS001",
                  params={"reason": "dropped course"}, headers=H("t1@c.com"))
    plan, _, _, conflicts = _plan_enrollments(
        world.db, world.sem.id,
        [{"register_number": "CHN23CS001", "subject_code": "CST412"}])
    assert plan == [] and len(conflicts) == 1


def test_import_allows_a_cross_class_elective(world):
    plan, _, errors, _ = _plan_enrollments(
        world.db, world.sem.id,
        [{"register_number": "CHN23CS101", "class": "S7 CSE-B", "subject_code": "CST412"}])
    assert len(plan) == 1 and errors == []


# ---------------- registration identity ----------------
def register(client, email, **body):
    return client.post("/auth/register", json=body, headers=H(email))


def test_invalid_register_number_format_is_refused(client):
    assert register(client, "new1@c.com", role="student",
                    register_number="NOPE").status_code == 400


def test_unknown_register_number_is_refused(client):
    assert register(client, "new1@c.com", role="student",
                    register_number="CHN23CS999").status_code == 403


def test_register_number_cannot_be_claimed_twice(client):
    assert register(client, "new1@c.com", role="student",
                    register_number="chn23cs003").status_code == 200
    assert register(client, "new2@c.com", role="student",
                    register_number="CHN23CS003").status_code == 409


def test_email_must_match_the_college_record(client):
    assert register(client, "new2@c.com", role="student",
                    register_number="CHN23CS004").status_code == 403


def test_unapproved_teacher_is_refused(client):
    assert register(client, "faketeacher@c.com", role="teacher").status_code == 403


def test_college_email_rules_when_enforced(client, monkeypatch):
    monkeypatch.setattr(college_rules, "ENFORCE_COLLEGE_EMAIL", True)
    assert register(client, "new1@c.com", role="student",
                    register_number="CHN23CS003").status_code == 403       # wrong domain
    assert register(client, "chn24csd006@ceconline.edu", role="student",
                    register_number="CHN23CS006").status_code == 403       # wrong year
    assert register(client, "chn23csd006@ceconline.edu", role="student",
                    register_number="CHN23CS006").status_code == 200


# ---------------- class advisor ----------------
def test_advisor_adds_an_existing_student_and_common_subjects_follow(client, world):
    r = client.post(f"/classes/{world.class_a.id}/students",
                    json={"register_number": "chn23cs005"}, headers=H("t1@c.com"))
    assert r.status_code == 201
    assert world.db.get(Enrollment, (world.spare.id, world.common_a.id)) is not None
    assert world.db.get(Enrollment, (world.spare.id, world.elective_a.id)) is None


def test_a_new_student_needs_a_name(client, world):
    url = f"/classes/{world.class_a.id}/students"
    assert client.post(url, json={"register_number": "CHN23CS777"},
                       headers=H("t1@c.com")).status_code == 404
    assert client.post(url, json={"register_number": "CHN23CS777", "name": "Newbie"},
                       headers=H("t1@c.com")).status_code == 201


def test_bad_register_number_is_refused_for_a_class(client, world):
    r = client.post(f"/classes/{world.class_a.id}/students",
                    json={"register_number": "ABC"}, headers=H("t1@c.com"))
    assert r.status_code == 400


def test_a_student_cannot_be_in_two_classes_in_one_semester(client, world):
    r = client.post(f"/classes/{world.class_a.id}/students",
                    json={"register_number": "CHN23CS101"}, headers=H("t1@c.com"))
    assert r.status_code == 409


def test_a_teacher_who_is_not_the_advisor_cannot_manage_the_class(client, world):
    url = f"/classes/{world.class_a.id}/students"
    assert client.get(url, headers=H("t2@c.com")).status_code == 403
    assert client.post(url, json={"register_number": "CHN23CS005"},
                       headers=H("t2@c.com")).status_code == 403


def test_a_student_cannot_manage_a_class(client, world):
    r = client.get(f"/classes/{world.class_a.id}/students", headers=H("s1@c.com"))
    assert r.status_code == 403


def test_leaving_a_class_drops_common_subjects_but_keeps_electives(client, world):
    url = f"/classes/{world.class_a.id}/students/CHN23CS001"
    assert client.delete(url, headers=H("t1@c.com")).status_code == 422
    r = client.delete(url, params={"reason": "moved to another division"},
                      headers=H("t1@c.com"))
    assert r.status_code == 200
    assert world.db.get(Enrollment, (world.s1.id, world.common_a.id)) is None
    assert world.db.get(Enrollment, (world.s1.id, world.elective_a.id)) is not None