from __future__ import annotations

import os

# Override host .env (e.g. cPanel APP_ENV=production) before Settings loads.
os.environ["APP_ENV"] = "development"
os.environ.setdefault("ALLOW_DEV_TOKEN", "true")
os.environ.setdefault("AUTH_RATE_LIMIT_PER_MINUTE", "0")
os.environ.setdefault("DEV_API_TOKEN", "test-token")

import pytest

pytest_plugins: list[str] = []


@pytest.fixture(scope="session", autouse=True)
def _reset_settings_cache() -> None:
    from app.core.config import get_settings

    get_settings.cache_clear()
    yield
    get_settings.cache_clear()
