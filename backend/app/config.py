"""Application configuration via pydantic-settings."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "HomeReminder API"
    app_version: str = "0.1.0"
    database_url: str = "sqlite+aiosqlite:///./homereminder.db"
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash"
    default_reminder_days_before: int = 5
    allowed_origins: list[str] = ["*"]


settings = Settings()
