"""
app/repositories/refresh_token.py — Persistencia de refresh tokens
"""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.refresh_token import RefreshToken


class RefreshTokenRepository:
    @staticmethod
    def create(db: Session, token: RefreshToken) -> RefreshToken:
        db.add(token)
        db.flush()
        db.refresh(token)
        return token

    @staticmethod
    def get_active_by_hash(db: Session, token_hash: str) -> RefreshToken | None:
        now = datetime.now(UTC)
        return db.scalar(
            select(RefreshToken).where(
                RefreshToken.token_hash == token_hash,
                RefreshToken.revoked_at.is_(None),
                RefreshToken.expires_at > now,
            )
        )

    @staticmethod
    def revoke(db: Session, token: RefreshToken) -> None:
        token.revoked_at = datetime.now(UTC)
        db.add(token)
        db.flush()

    @staticmethod
    def revoke_all_for_user(db: Session, user_id: int) -> int:
        now = datetime.now(UTC)
        tokens = list(
            db.scalars(
                select(RefreshToken).where(
                    RefreshToken.user_id == user_id,
                    RefreshToken.revoked_at.is_(None),
                )
            ).all()
        )
        for token in tokens:
            token.revoked_at = now
            db.add(token)
        db.flush()
        return len(tokens)
