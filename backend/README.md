# Receipt Intelligence — Backend

FastAPI + PostgreSQL + Redis backend for the Receipt Intelligence platform.

## Stack

- FastAPI (async), SQLAlchemy 2.0 (async), Alembic
- PostgreSQL 16, Redis 7
- JWT auth (access + refresh), Google Sign-In
- Celery (background OCR/AI jobs — wired in Phase 2)

## Local setup (Docker, recommended)

```bash
cp .env.example .env   # fill in JWT_SECRET_KEY at minimum
docker compose up --build
```

This starts Postgres, Redis, the API (with auto-reload) on `http://localhost:8000`,
and a Celery worker. Migrations run automatically on container start.

API docs: `http://localhost:8000/docs`

## Local setup (without Docker)

```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # point DATABASE_URL / REDIS_URL at local services

alembic revision --autogenerate -m "init"
alembic upgrade head

uvicorn app.main:app --reload
```

## Project layout

```
app/
  api/v1/endpoints/   # route handlers, one file per resource
  core/                # config, security (JWT/hashing)
  db/                  # SQLAlchemy engine/session
  models/              # ORM models (source of truth for schema)
  repositories/        # DB access, one per aggregate
  schemas/             # Pydantic request/response models
  services/            # business logic, orchestrates repositories
alembic/               # migrations
tests/
```

## Auth flow (Phase 1)

- `POST /api/v1/auth/register`, `/login` — returns access + refresh JWT and user
- `POST /api/v1/auth/google` — verifies a Google ID token, links or creates the account
- `POST /api/v1/auth/refresh` — exchanges a refresh token for a new pair
- `POST /api/v1/auth/forgot-password` / `/reset-password` — 30-min reset token
  (currently printed to server logs; wire a real email provider before production)
- `GET /api/v1/auth/me` — current user from bearer token
- `POST /api/v1/auth/logout` — best-effort; tokens are stateless JWTs until
  refresh-token revocation storage is added

## Roadmap

See the root `README.md` for the full 7-phase build plan. This backend currently
implements Phase 1 (auth + schema). Phase 2 adds receipt upload, OCR, and AI
extraction endpoints.
