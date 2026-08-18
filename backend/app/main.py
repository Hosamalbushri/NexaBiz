from contextlib import asynccontextmanager
import logging
import os
import uuid

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
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
from app.core.rate_limit import SlidingWindowLimiter
from app.sync.router import router, sync_router

configure_logging()
settings = get_settings()

_AUTH_LIMIT_PATHS = {"/api/v1/auth/login", "/api/v1/auth/refresh"}
auth_limiter = SlidingWindowLimiter(
    max_requests=settings.auth_rate_limit_per_minute,
    window_seconds=60.0,
)


def _seed_on_startup() -> None:
    settings.assert_safe_for_environment()
    if settings.allow_dev_token:
        logging.getLogger("uvicorn.error").warning(
            "ALLOW_DEV_TOKEN is enabled — disable for any non-local deployment"
        )
    db = SessionLocal()
    try:
        seed_identity(db, settings)
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


@asynccontextmanager
async def lifespan(_app: FastAPI):
    _seed_on_startup()
    yield


# a2wsgi + Passenger can hang forever waiting on ASGI lifespan. Seed in
# passenger_wsgi.py instead, then skip lifespan under WSGI.
_skip_asgi_lifespan = os.environ.get("SKIP_ASGI_LIFESPAN", "").strip().lower() in {
    "1",
    "true",
    "yes",
}

app = FastAPI(
    title="NexaBiz Experimental Sync API",
    description=(
        "EXPERIMENTAL synchronization + identity backend for the Flutter "
        "offline-first architecture. Not production-ready."
    ),
    version="0.2.0-experimental",
    docs_url="/docs",
    openapi_url="/openapi.json",
    lifespan=None if _skip_asgi_lifespan else lifespan,
)

_raw_origins = settings.cors_origins.strip()
if _raw_origins in {"", "*"}:
    cors_origins = ["*"]
    cors_credentials = False
else:
    cors_origins = [o.strip() for o in _raw_origins.split(",") if o.strip()]
    cors_credentials = True

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=cors_credentials,
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


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Propagate / assign X-Correlation-Id for client↔server log joins."""

    async def dispatch(self, request: Request, call_next) -> Response:
        correlation = (
            request.headers.get("x-correlation-id")
            or request.headers.get("x-request-id")
            or ""
        ).strip()
        if not correlation:
            correlation = str(uuid.uuid4())
        request.state.correlation_id = correlation
        response = await call_next(request)
        response.headers.setdefault("X-Correlation-Id", correlation)
        if request.url.path.startswith("/api/"):
            logging.getLogger("sync").info(
                "request method=%s path=%s correlation_id=%s status=%s",
                request.method,
                request.url.path,
                correlation,
                response.status_code,
            )
        return response


class AuthRateLimitMiddleware(BaseHTTPMiddleware):
    """Sliding-window limit on login and refresh (brute-force mitigation)."""

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.method == "POST" and request.url.path in _AUTH_LIMIT_PATHS:
            host = request.client.host if request.client else "unknown"
            limit = get_settings().auth_rate_limit_per_minute
            allowed, retry_after = auth_limiter.allow(
                f"{host}:{request.url.path}",
                max_requests=limit,
            )
            if not allowed:
                return JSONResponse(
                    status_code=429,
                    content={
                        "error": {
                            "code": "rate_limited",
                            "message": "Too many authentication attempts. Try again later.",
                            "details": {"retry_after": retry_after},
                        }
                    },
                    headers={"Retry-After": str(retry_after)},
                )
        return await call_next(request)


app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(CorrelationIdMiddleware)
app.add_middleware(AuthRateLimitMiddleware)

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


@app.get("/", tags=["meta"])
def root() -> dict[str, str]:
    return {
        "app": settings.app_name,
        "status": "experimental",
        "docs": "/docs",
        "health": "/health",
        "auth": "/api/v1/auth/login",
    }
