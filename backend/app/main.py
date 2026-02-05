from fastapi import FastAPI

app = FastAPI(title="TV Institucional API", version="0.1.0")


@app.get("/health")
def healthcheck() -> dict:
    return {"status": "ok"}
