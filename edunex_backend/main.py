from fastapi import FastAPI
# Pull the specific routers
from app.routers import subjects, feed 

app = FastAPI(title="EduNex Backend")

# Include the routing logic trees
app.include_router(subjects.router)
app.include_router(feed.router)

@app.get("/")
def read_root():
    return {"status": "EduNex Core System API Operational"}
