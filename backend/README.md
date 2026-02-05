# Backend API

## Como rodar localmente

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

A API ficará disponível em `http://localhost:8000`.

## Rodar com Docker Compose (na raiz do projeto)

```bash
docker compose up -d --build
```

## Endpoint inicial

- `GET /health`: retorna `{ "status": "ok" }`.
