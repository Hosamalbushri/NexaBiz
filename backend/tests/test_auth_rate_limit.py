"""Auth rate limiter (no database required)."""

from __future__ import annotations

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.exceptions import TooManyRequestsError, app_error_handler
from app.core.rate_limit import SlidingWindowLimiter


def test_sliding_window_allows_then_blocks() -> None:
    limiter = SlidingWindowLimiter(max_requests=2, window_seconds=60)
    assert limiter.allow("ip")[0] is True
    assert limiter.allow("ip")[0] is True
    allowed, retry = limiter.allow("ip")
    assert allowed is False
    assert retry >= 1
    assert limiter.allow("other")[0] is True


def test_sliding_window_disabled_when_max_zero() -> None:
    limiter = SlidingWindowLimiter(max_requests=0)
    for _ in range(50):
        assert limiter.allow("ip")[0] is True


def test_middleware_returns_429() -> None:
    limiter = SlidingWindowLimiter(max_requests=1, window_seconds=60)
    app = FastAPI()
    app.add_exception_handler(TooManyRequestsError, app_error_handler)

    @app.post("/api/v1/auth/login")
    def login() -> dict[str, str]:
        allowed, retry = limiter.allow("test")
        if not allowed:
            raise TooManyRequestsError(retry_after=retry)
        return {"ok": "yes"}

    client = TestClient(app)
    first = client.post("/api/v1/auth/login")
    assert first.status_code == 200
    second = client.post("/api/v1/auth/login")
    assert second.status_code == 429
    assert second.headers.get("retry-after")
    body = second.json()
    assert body["error"]["code"] == "rate_limited"
