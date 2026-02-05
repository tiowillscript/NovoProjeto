from fastapi import FastAPI

from app.core.config import settings

app = FastAPI(title="NovoProjeto API", version="0.1.0")


@app.get("/health", tags=["health"])
async def health() -> dict:
    return {"status": "ok", "environment": settings.environment}
