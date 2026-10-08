import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase # 👈 Added DeclarativeBase import here

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Standard SQLAlchemy 2.0 blueprint mapping class
class Base(DeclarativeBase):
    pass

# FastAPI will call this for every request that needs the database
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
