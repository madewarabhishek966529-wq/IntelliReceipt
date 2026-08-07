from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings

settings = get_settings()

# Celery tasks run in a sync worker process, so they use a separate sync
# engine/session rather than the app's async engine. Same Postgres, same
# models — just a different driver (psycopg2 instead of asyncpg).
_sync_url = settings.DATABASE_URL.replace("postgresql+asyncpg", "postgresql+psycopg2")

sync_engine = create_engine(_sync_url, pool_pre_ping=True)
SyncSessionLocal = sessionmaker(bind=sync_engine, autoflush=False, expire_on_commit=False)


def get_sync_db() -> Session:
    return SyncSessionLocal()
