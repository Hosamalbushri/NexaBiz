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

    # Legacy shared token — OFF by default. Enable only for local development.
    # Prefer JWT sessions. Never enable in production.
    dev_api_token: str = "dev-sync-token-change-me"
    allow_dev_token: bool = False
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

    @property
    def is_production(self) -> bool:
        return self.app_env.strip().lower() in {"production", "prod"}

    def assert_safe_for_environment(self) -> None:
        """Raise if clearly unsafe production/staging settings are active."""
        env = self.app_env.strip().lower()
        if env not in {"production", "prod", "staging"}:
            return
        if self.allow_dev_token:
            raise RuntimeError(
                "ALLOW_DEV_TOKEN must be false when APP_ENV is "
                f"{self.app_env!r}"
            )
        if (
            self.jwt_secret.startswith("dev-jwt-secret")
            or self.jwt_secret == "REPLACE_WITH_OPENSSL_RAND_HEX_32"
            or len(self.jwt_secret.strip()) < 32
        ):
            raise RuntimeError(
                "JWT_SECRET must be a unique secret (≥ 32 chars) for "
                f"{self.app_env!r}"
            )
        if self.cors_origins.strip() in {"", "*"}:
            raise RuntimeError(
                "CORS_ORIGINS=* (or empty) is not allowed in "
                f"{self.app_env!r}"
            )
        if self.seed_admin_password in {
            "ChangeMeAdmin!123",
            "REPLACE_STRONG_PASSWORD",
        }:
            raise RuntimeError(
                "SEED_ADMIN_PASSWORD must be changed before "
                f"{self.app_env!r} deploy"
            )



@lru_cache
def get_settings() -> Settings:
    return Settings()
