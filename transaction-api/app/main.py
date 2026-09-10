from fastapi import FastAPI
from .routes import router

app = FastAPI(
    title="Cloud Native Fraud Detection Platform",
    description="Real-time transaction processing and fraud detection API",
    version="1.0.0"
)

app.include_router(router)


@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }