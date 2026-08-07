from fastapi import APIRouter

from app.api.v1.endpoints import auth, receipts

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(receipts.router)

# Phase 3+ endpoint routers will be included here as they're built:
# api_router.include_router(products.router)
# api_router.include_router(dashboard.router)
# api_router.include_router(budgets.router)
# api_router.include_router(search.router)
# api_router.include_router(insights.router)
