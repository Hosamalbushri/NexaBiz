"""Production / staging settings guards (no database required)."""

from __future__ import annotations

import pytest

from app.core.config import Settings


def test_development_allows_dev_defaults() -> None:
    settings = Settings(
        app_env="development",
        allow_dev_token=True,
        jwt_secret="dev-jwt-secret-change-me-please-use-long-random",
        cors_origins="*",
        seed_admin_password="ChangeMeAdmin!123",
    )
    settings.assert_safe_for_environment()


@pytest.mark.parametrize("env", ["production", "prod", "staging"])
def test_productionish_rejects_dev_token(env: str) -> None:
    settings = Settings(
        app_env=env,
        allow_dev_token=True,
        jwt_secret="a" * 32,
        cors_origins="https://app.example.com",
        seed_admin_password="StrongPass!not-default-99",
    )
    with pytest.raises(RuntimeError, match="ALLOW_DEV_TOKEN"):
        settings.assert_safe_for_environment()


@pytest.mark.parametrize("env", ["production", "staging"])
def test_productionish_rejects_wildcard_cors(env: str) -> None:
    settings = Settings(
        app_env=env,
        allow_dev_token=False,
        jwt_secret="a" * 32,
        cors_origins="*",
        seed_admin_password="StrongPass!not-default-99",
    )
    with pytest.raises(RuntimeError, match="CORS_ORIGINS"):
        settings.assert_safe_for_environment()


@pytest.mark.parametrize("env", ["production", "staging"])
def test_productionish_rejects_short_or_placeholder_jwt(env: str) -> None:
    settings = Settings(
        app_env=env,
        allow_dev_token=False,
        jwt_secret="dev-jwt-secret-change-me-please-use-long-random",
        cors_origins="https://app.example.com",
        seed_admin_password="StrongPass!not-default-99",
    )
    with pytest.raises(RuntimeError, match="JWT_SECRET"):
        settings.assert_safe_for_environment()


@pytest.mark.parametrize("env", ["production", "staging"])
def test_productionish_rejects_default_seed_password(env: str) -> None:
    settings = Settings(
        app_env=env,
        allow_dev_token=False,
        jwt_secret="a" * 32,
        cors_origins="https://app.example.com",
        seed_admin_password="ChangeMeAdmin!123",
    )
    with pytest.raises(RuntimeError, match="SEED_ADMIN_PASSWORD"):
        settings.assert_safe_for_environment()


def test_production_accepts_hardened_settings() -> None:
    settings = Settings(
        app_env="production",
        allow_dev_token=False,
        jwt_secret="a" * 32,
        cors_origins="https://app.example.com",
        seed_admin_password="StrongPass!not-default-99",
    )
    settings.assert_safe_for_environment()
