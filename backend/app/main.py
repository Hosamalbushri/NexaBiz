from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.exceptions import (
    AppError,
    app_error_handler,
    http_exception_handler,
    unhandled_error_handler,
)
from app.core.logging import configure_logging
from app.sync.router import router, sync_router
from fastapi import HTTPException

configure_logging()
settings = get_settings()

app = FastAPI(
    title="NexaBiz Experimental Sync API",
    description=(
        "EXPERIMENTAL synchronization backend for the Flutter offline-first "
        "architecture. Not production-ready. Implements push/pull/meta against "
        "PostgreSQL with change-log cursors, version conflicts, and idempotency."
    ),
    version="0.1.0-experimental",
    docs_url="/docs",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(Exception, unhandled_error_handler)

app.include_router(router)
app.include_router(sync_router)


@app.get("/", tags=["meta"])
def root() -> dict[str, str]:
    return {
        "app": settings.app_name,
        "status": "experimental",
        "docs": "/docs",
        "health": "/health",
    }
