from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration for the experimental sync + identity API."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "nexabiz-sync-experimental"
    app_env: str = "development"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    log_level: str = "INFO"

    database_url: str = (
        "postgresql+psycopg2://sync:sync@localhost:5432/sync_experimental"
    )

    # Legacy shared token kept for migration window / optional fallback.
    # Prefer JWT sessions. Set allow_dev_token=false in non-dev environments.
    dev_api_token: str = "dev-sync-token-change-me"
    allow_dev_token: bool = True
    default_company_id: str = "00000000-0000-4000-8000-000000000001"
    default_user_id: str = "00000000-0000-4000-8000-000000000002"
    default_device_id: str = "00000000-0000-4000-8000-000000000003"

    jwt_secret: str = "dev-jwt-secret-change-me-please-use-long-random"
    jwt_algorithm: str = "HS256"
    jwt_issuer: str = "nexabiz-experimental"
    access_token_ttl_seconds: int = 900
    refresh_token_ttl_seconds: int = 60 * 60 * 24 * 30

    sync_pull_limit: int = 500

    # Comma-separated origins; empty / * means allow all in development.
    cors_origins: str = "*"

    # Seed bootstrap admin (created once by seed script / startup).
    seed_admin_email: str = "admin@example.com"
    seed_admin_password: str = "ChangeMeAdmin!123"
    seed_admin_name: str = "Platform Admin"
    seed_company_name: str = "Demo Company A"
    seed_company_code: str = "COMPANY-A"
    seed_company_id: str = "00000000-0000-4000-8000-000000000001"


@lru_cache
def get_settings() -> Settings:
    return Settings()
