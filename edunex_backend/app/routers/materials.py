import os
import shutil
import uuid
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies import get_current_user, require_teacher
from app.models.academic import Material, Subject

router = APIRouter(prefix="/materials", tags=["materials"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
TESSERACT = os.getenv("TESSERACT_CMD", r"C:\Program Files\Tesseract-OCR\tesseract.exe")


def ocr_image(img) -> str:
    """Read text from a picture. Returns '' if Tesseract is not installed."""
    try:
        import pytesseract
        pytesseract.pytesseract.tesseract_cmd = TESSERACT
        return pytesseract.image_to_string(img)
    except Exception as e:
        print("OCR skipped:", e)
        return ""


def read_pdf(path: str) -> list[str]:
    import pdfplumber
    pages = []
    with pdfplumber.open(path) as pdf:
        for page in pdf.pages:
            text = (page.extract_text() or "").strip()
            if len(text) < 20:  # almost empty = scanned page, so use OCR
                text = ocr_image(page.to_image(resolution=200).original).strip()
            pages.append(text)
    return pages


def read_image(path: str) -> list[str]:
    from PIL import Image
    return [ocr_image(Image.open(path)).strip()]


@router.get("")
def list_materials(subject_id: UUID, user=Depends(get_current_user),
                   db: Session = Depends(get_db)):
    rows = db.scalars(select(Material).where(Material.subject_id == subject_id)
                      .order_by(Material.created_at.desc())).all()
    return [{"id": str(m.id), "name": m.name, "page_count": m.page_count,
             "has_text": bool(m.extracted_text),
             "created_at": m.created_at.isoformat()} for m in rows]


@router.post("/upload", status_code=201)
def upload(subject_id: UUID = Form(...), file: UploadFile = File(...),
           user=Depends(require_teacher), db: Session = Depends(get_db)):
    subject = db.get(Subject, subject_id)
    if subject is None or subject.teacher_id != user.id:
        raise HTTPException(403, "Not your subject")

    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in (".pdf", ".png", ".jpg", ".jpeg"):
        raise HTTPException(400, "Only PDF or image files are allowed")

    path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}{ext}")
    with open(path, "wb") as out:
        shutil.copyfileobj(file.file, out)

    pages = read_pdf(path) if ext == ".pdf" else read_image(path)
    m = Material(subject_id=subject_id, name=file.filename, file_url=path,
                 page_count=len(pages), extracted_text="\n".join(pages))
    db.add(m)
    db.commit()
    db.refresh(m)
    return {"id": str(m.id), "name": m.name, "page_count": m.page_count,
            "has_text": bool(m.extracted_text)}