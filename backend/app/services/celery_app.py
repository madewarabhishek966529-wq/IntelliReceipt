from celery import Celery

from app.core.config import get_settings

settings = get_settings()

celery_app = Celery(
    "receipt_intelligence",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
)

# Import task modules so they register with this Celery app. Direct import
# (rather than autodiscover_tasks, which expects a Django-style app
# registry) keeps this explicit and avoids import-order surprises.
from app.services import receipt_tasks  # noqa: E402,F401
