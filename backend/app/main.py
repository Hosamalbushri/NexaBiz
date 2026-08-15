from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.admin.router import (
    companies_router,
    devices_router,
    permissions_router,
    roles_router,
    users_router,
)
from app.auth.router import router as auth_router
from app.auth.seed import seed_identity
from app.core.config import get_settings
from app.core.database import SessionLocal
from app.core.exceptions import (
    AppError,
    app_error_handler,
    http_exception_handler,
    unhandled_error_handler,
)
from app.core.logging import configure_logging
from app.sync.router import router, sync_router

configure_logging()
settings = get_settings()

app = FastAPI(
    title="NexaBiz Experimental Sync API",
    description=(
        "EXPERIMENTAL synchronization + identity backend for the Flutter "
        "offline-first architecture. Not production-ready."
    ),
    version="0.2.0-experimental",
    docs_url="/docs",
    openapi_url="/openapi.json",
)

origins = (
    ["*"]
    if settings.cors_origins.strip() in {"", "*"}
    else [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """API-appropriate security headers (no browser-only CSP that breaks docs)."""

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "no-referrer")
        response.headers.setdefault(
            "Permissions-Policy", "geolocation=(), microphone=(), camera=()"
        )
        # HSTS only meaningful behind HTTPS terminators; harmless on local HTTP.
        if request.url.scheme == "https":
            response.headers.setdefault(
                "Strict-Transport-Security", "max-age=31536000; includeSubDomains"
            )
        return response


app.add_middleware(SecurityHeadersMiddleware)

app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(Exception, unhandled_error_handler)

app.include_router(router)
app.include_router(sync_router)
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(roles_router)
app.include_router(permissions_router)
app.include_router(companies_router)
app.include_router(devices_router)


@app.on_event("startup")
def on_startup() -> None:
    db = SessionLocal()
    try:
        seed_identity(db, settings)
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


@app.get("/", tags=["meta"])
def root() -> dict[str, str]:
    return {
        "app": settings.app_name,
        "status": "experimental",
        "docs": "/docs",
        "health": "/health",
        "auth": "/api/v1/auth/login",
    }
