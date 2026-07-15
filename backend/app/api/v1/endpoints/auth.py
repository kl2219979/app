"""
app/api/v1/endpoints/auth.py — Registro, login, MFA, refresh, logout, me
"""

from fastapi import APIRouter, Depends, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.rate_limit import client_ip, enforce_rate_limit
from app.models.user import User
from app.schemas.auth import (
    LoginResponse,
    LogoutRequest,
    MfaConfirmRequest,
    MfaSetupResponse,
    MfaVerifyRequest,
    RefreshRequest,
    Token,
    UserPublic,
    UserRegister,
)
from app.services.auth import AuthService

router = APIRouter(prefix="/auth")


@router.post(
    "/register",
    response_model=UserPublic,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar usuario",
)
def register(
    body: UserRegister,
    request: Request,
    db: Session = Depends(get_db),
) -> User:
    enforce_rate_limit(request, scope="auth")
    return AuthService.register(db, body)


@router.post(
    "/login",
    response_model=LoginResponse,
    summary="Login → tokens o challenge MFA",
)
def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
) -> LoginResponse:
    enforce_rate_limit(request, scope="auth")
    return AuthService.login(
        db,
        form_data.username,
        form_data.password,
        client_ip=client_ip(request),
    )


@router.post(
    "/mfa/verify",
    response_model=Token,
    summary="Completar login admin con código TOTP",
)
def mfa_verify(
    body: MfaVerifyRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Token:
    enforce_rate_limit(request, scope="auth")
    return AuthService.verify_mfa_login(
        db,
        mfa_token=body.mfa_token,
        code=body.code,
        client_ip=client_ip(request),
    )


@router.post(
    "/mfa/setup",
    response_model=MfaSetupResponse,
    summary="Generar secreto TOTP (escanea con Authenticator)",
)
def mfa_setup(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MfaSetupResponse:
    return AuthService.setup_mfa(db, current_user)


@router.post(
    "/mfa/confirm",
    response_model=UserPublic,
    summary="Confirmar MFA con un código válido",
)
def mfa_confirm(
    body: MfaConfirmRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> User:
    return AuthService.confirm_mfa(db, current_user, body.code)


@router.post(
    "/refresh",
    response_model=Token,
    summary="Renovar access token con refresh token",
)
def refresh(
    body: RefreshRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Token:
    enforce_rate_limit(request, scope="auth")
    return AuthService.refresh(db, body.refresh_token)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revocar refresh token propio (o todos)",
)
def logout(
    body: LogoutRequest = LogoutRequest(),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    AuthService.logout(db, body.refresh_token, user=current_user)


@router.get(
    "/me",
    response_model=UserPublic,
    summary="Usuario autenticado",
)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user
