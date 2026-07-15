"""
app/core/config.py — Configuración central de la aplicación
"""

from __future__ import annotations

from functools import lru_cache
from typing import Self
from urllib.parse import quote_plus

from pydantic import Field, computed_field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_INSECURE_SECRET_PREFIXES = ("change-me", "secret", "changeme")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    APP_NAME: str = "App Backend"
    APP_ENV: str = "development"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"

    HOST: str = "0.0.0.0"
    PORT: int = 8000

    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "app_db"
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432

    database_url_override: str | None = Field(
        default=None,
        validation_alias="DATABASE_URL",
    )

    SECRET_KEY: str = "change-me-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 14
    MFA_CHALLENGE_EXPIRE_MINUTES: int = 5

    # HMAC para webhooks entrantes (obligatorio en production).
    WEBHOOK_SECRET: str | None = None

    # Detrás de proxy TLS: exige X-Forwarded-Proto=https en production.
    FORCE_HTTPS: bool = False

    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_AUTH_MAX: int = 10
    RATE_LIMIT_AUTH_WINDOW_SECONDS: int = 60

    CORS_ORIGINS: str = "http://localhost:5173"
    CORS_ALLOW_METHODS: str = "GET,POST,PUT,PATCH,DELETE,OPTIONS"
    CORS_ALLOW_HEADERS: str = "Authorization,Content-Type,X-Webhook-Signature"

    @computed_field  # type: ignore[prop-decorator]
    @property
    def DATABASE_URL(self) -> str:
        if self.database_url_override:
            return self.database_url_override
        user = quote_plus(self.POSTGRES_USER)
        password = quote_plus(self.POSTGRES_PASSWORD)
        return (
            f"postgresql://{user}:{password}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def is_production(self) -> bool:
        return self.APP_ENV.lower() == "production"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    @property
    def cors_methods_list(self) -> list[str]:
        return [m.strip() for m in self.CORS_ALLOW_METHODS.split(",") if m.strip()]

    @property
    def cors_headers_list(self) -> list[str]:
        return [h.strip() for h in self.CORS_ALLOW_HEADERS.split(",") if h.strip()]

    @field_validator("POSTGRES_PORT")
    @classmethod
    def port_must_be_valid(cls, value: int) -> int:
        if not 1 <= value <= 65535:
            raise ValueError("POSTGRES_PORT must be between 1 and 65535")
        return value

    @model_validator(mode="after")
    def harden_production(self) -> Self:
        if not self.is_production:
            return self

        # DEBUG siempre off en producción (aunque .env diga true).
        object.__setattr__(self, "DEBUG", False)

        key = self.SECRET_KEY.strip().lower()
        if len(self.SECRET_KEY) < 32 or any(
            key.startswith(prefix) for prefix in _INSECURE_SECRET_PREFIXES
        ):
            raise ValueError(
                "SECRET_KEY must be a strong random value when APP_ENV=production "
                "(min 32 chars, not a placeholder like 'change-me-...')."
            )

        if not self.WEBHOOK_SECRET or len(self.WEBHOOK_SECRET) < 32:
            raise ValueError(
                "WEBHOOK_SECRET (min 32 chars) is required when APP_ENV=production"
            )

        if not self.FORCE_HTTPS:
            raise ValueError(
                "FORCE_HTTPS=true is required when APP_ENV=production "
                "(terminate TLS at the reverse proxy and forward X-Forwarded-Proto)"
            )

        if "*" in self.cors_origins_list:
            raise ValueError("CORS_ORIGINS must not include '*' in production")

        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
