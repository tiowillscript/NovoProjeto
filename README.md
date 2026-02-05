# NovoProjeto - TV Institucional

Sistema completo para TV institucional com backend, painel web e player Android TV.

## Visão geral
- **Backend/API**: FastAPI + PostgreSQL
- **Painel web**: Next.js (em construção)
- **Player Android TV**: Kotlin (em construção)

## Pré-requisitos
- Docker Desktop instalado (Windows/macOS/Linux)

## Como rodar (Windows - passo a passo)
1. Abra o **PowerShell**.
2. Entre na pasta do projeto:
   ```powershell
   cd C:\caminho\para\NovoProjeto
   ```
3. Copie o arquivo de ambiente de exemplo:
   ```powershell
   Copy-Item .env.example .env
   ```
4. Suba os containers:
   ```powershell
   docker compose up --build
   ```
5. Abra a documentação da API:
   - http://localhost:8000/docs

> Para parar os containers, use `Ctrl+C` e depois `docker compose down`.

## Estrutura de pastas
```
backend/   # FastAPI + SQLAlchemy
frontend/  # Next.js (em construção)
mobile/    # Android TV (em construção)
docs/      # Documentação
```

## Healthcheck
- `GET /health`

## Próximas etapas
As próximas etapas adicionam autenticação, gerenciamento de dispositivos, mídias e painel web.
