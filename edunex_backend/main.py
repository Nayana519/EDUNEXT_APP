import glob
import os
import firebase_admin
from fastapi import FastAPI
# Pull the specific routers
from app.routers import subjects, feed
from app.routers import admin, auth
from firebase_admin import credentials
import glob
import os
from app.routers import imports


if not firebase_admin._apps:
    _keys = glob.glob(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "secrets", "*.json")
    )
    if not _keys:
        raise RuntimeError(
            "No Firebase key found. Put the service account .json file in edunex_backend/secrets/"
        )
    firebase_admin.initialize_app(credentials.Certificate(_keys[0]))
app = FastAPI(title="EduNex Backend")
app.include_router(imports.router)
app.include_router(auth.router)
# Include the routing logic trees
app.include_router(subjects.router)
app.include_router(feed.router)
app.include_router(admin.router) 
@app.get("/")
def read_root():
    return {"status": "EduNex Core System API Operational"}
