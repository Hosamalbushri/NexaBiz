from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration for the experimental sync API."""

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

    dev_api_token: str = "dev-sync-token-change-me"
    default_company_id: str = "00000000-0000-4000-8000-000000000001"
    default_user_id: str = "00000000-0000-4000-8000-000000000002"
    default_device_id: str = "00000000-0000-4000-8000-000000000003"

    sync_pull_limit: int = 500


@lru_cache
def get_settings() -> Settings:
    return Settings()
