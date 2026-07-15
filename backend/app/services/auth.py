"""
app/services/auth.py — Registro, login, refresh, logout y MFA
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from jwt.exceptions import InvalidTokenError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.logging_config import get_logger
from app.core.mfa import (
    create_mfa_challenge_token,
    decode_mfa_challenge_token,
    decrypt_totp_secret,
    encrypt_totp_secret,
    generate_totp_secret,
    provisioning_uri,
    verify_totp,
)
from app.core.security import (
    create_access_token,
    generate_refresh_token,
    hash_password,
    hash_refresh_token,
    verify_password,
)
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.repositories.refresh_token import RefreshTokenRepository
from app.repositories.user import UserRepository
from app.schemas.auth import (
    LoginResponse,
    MfaSetupResponse,
    Token,
    UserRegister,
)

logger = get_logger("app.auth")


class AuthService:
    @staticmethod
    def _issue_tokens(db: Session, user: User) -> Token:
        access = create_access_token(
            subject=user.id,
            extra_claims={"rol": user.rol, "mfa": user.mfa_enabled},
        )
        raw_refresh = generate_refresh_token()
        expires_at = datetime.now(UTC) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        RefreshTokenRepository.create(
            db,
            RefreshToken(
                user_id=user.id,
                token_hash=hash_refresh_token(raw_refresh),
                expires_at=expires_at,
            ),
        )
        db.commit()
        return Token(access_token=access, refresh_token=raw_refresh)

    @staticmethod
    def register(db: Session, body: UserRegister) -> User:
        if UserRepository.exists_correo_or_usuario(
            db, correo=body.correo, usuario=body.usuario
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ya existe un usuario con ese correo o nombre de usuario",
            )
        user = User(
            nombres=body.nombres,
            apellidos=body.apellidos,
            fecha_nacimiento=body.fecha_nacimiento,
            genero=body.genero,
            correo=body.correo,
            usuario=body.usuario,
            contrasena_hash=hash_password(body.contrasena),
            rol="user",
            activo=True,
            mfa_enabled=False,
        )
        UserRepository.create(db, user)
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def login(
        db: Session,
        username: str,
        password: str,
        *,
        client_ip: str = "unknown",
    ) -> LoginResponse:
        user = UserRepository.get_by_correo_or_usuario(db, username)
        if user is None or not verify_password(password, user.contrasena_hash):
            logger.warning(
                "auth_login_failed reason=invalid_credentials username=%s ip=%s",
                username[:80],
                client_ip,
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario o contraseña incorrectos",
                headers={"WWW-Authenticate": "Bearer"},
            )
        if not user.activo:
            logger.warning(
                "auth_login_failed reason=inactive_user user_id=%s ip=%s",
                user.id,
                client_ip,
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cuenta desactivada. Contacta soporte para reactivarla.",
            )

        # Admin con MFA: password OK → challenge, aún sin tokens de sesión.
        if user.is_admin and user.mfa_enabled:
            challenge = create_mfa_challenge_token(user.id)
            logger.info(
                "auth_login_mfa_challenge user_id=%s ip=%s",
                user.id,
                client_ip,
            )
            return LoginResponse(mfa_required=True, mfa_token=challenge)

        tokens = AuthService._issue_tokens(db, user)
        logger.info("auth_login_ok user_id=%s ip=%s", user.id, client_ip)
        return LoginResponse(
            access_token=tokens.access_token,
            refresh_token=tokens.refresh_token,
            token_type=tokens.token_type,
            mfa_required=False,
        )

    @staticmethod
    def verify_mfa_login(
        db: Session,
        *,
        mfa_token: str,
        code: str,
        client_ip: str = "unknown",
    ) -> Token:
        try:
            user_id = decode_mfa_challenge_token(mfa_token)
        except (InvalidTokenError, ValueError):
            logger.warning("auth_mfa_failed reason=bad_challenge ip=%s", client_ip)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Challenge MFA inválido o expirado",
            ) from None

        user = UserRepository.get_by_id(db, user_id)
        if user is None or not user.activo or not user.mfa_enabled or not user.mfa_secret_encrypted:
            logger.warning(
                "auth_mfa_failed reason=user_state user_id=%s ip=%s",
                user_id,
                client_ip,
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="MFA no disponible para este usuario",
            )

        secret = decrypt_totp_secret(user.mfa_secret_encrypted)
        if not verify_totp(secret, code):
            logger.warning(
                "auth_mfa_failed reason=bad_code user_id=%s ip=%s",
                user.id,
                client_ip,
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Código MFA incorrecto",
            )

        tokens = AuthService._issue_tokens(db, user)
        logger.info("auth_mfa_ok user_id=%s ip=%s", user.id, client_ip)
        return tokens

    @staticmethod
    def setup_mfa(db: Session, user: User) -> MfaSetupResponse:
        secret = generate_totp_secret()
        user.mfa_secret_encrypted = encrypt_totp_secret(secret)
        user.mfa_enabled = False
        UserRepository.update(db, user)
        db.commit()
        db.refresh(user)
        return MfaSetupResponse(
            secret=secret,
            otpauth_uri=provisioning_uri(secret=secret, account_name=user.correo),
            mfa_enabled=False,
        )

    @staticmethod
    def confirm_mfa(db: Session, user: User, code: str) -> User:
        if not user.mfa_secret_encrypted:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Primero llama a /auth/mfa/setup",
            )
        secret = decrypt_totp_secret(user.mfa_secret_encrypted)
        if not verify_totp(secret, code):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Código MFA incorrecto",
            )
        user.mfa_enabled = True
        UserRepository.update(db, user)
        db.commit()
        db.refresh(user)
        logger.info("auth_mfa_enabled user_id=%s", user.id)
        return user

    @staticmethod
    def refresh(db: Session, raw_refresh: str) -> Token:
        stored = RefreshTokenRepository.get_active_by_hash(
            db, hash_refresh_token(raw_refresh)
        )
        if stored is None:
            logger.warning("auth_refresh_failed reason=invalid_or_expired")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token inválido o expirado",
            )
        user = UserRepository.get_by_id(db, stored.user_id)
        if user is None or not user.activo:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario no encontrado o desactivado",
            )
        if user.is_admin and not user.mfa_enabled:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Los administradores deben activar MFA",
            )
        RefreshTokenRepository.revoke(db, stored)
        return AuthService._issue_tokens(db, user)

    @staticmethod
    def logout(
        db: Session,
        raw_refresh: str | None = None,
        *,
        user: User | None = None,
    ) -> None:
        if raw_refresh:
            if user is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Se requiere autenticación para revocar un refresh token",
                )
            stored = RefreshTokenRepository.get_active_by_hash(
                db, hash_refresh_token(raw_refresh)
            )
            if stored is not None:
                if stored.user_id != user.id:
                    logger.warning(
                        "auth_logout_denied reason=foreign_refresh "
                        "user_id=%s token_owner=%s",
                        user.id,
                        stored.user_id,
                    )
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="No puedes revocar el refresh token de otro usuario",
                    )
                RefreshTokenRepository.revoke(db, stored)
                db.commit()
            return
        if user is not None:
            RefreshTokenRepository.revoke_all_for_user(db, user.id)
            db.commit()
