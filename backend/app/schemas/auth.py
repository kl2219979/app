"""
app/schemas/auth.py — Contratos HTTP de autenticación
"""

from datetime import date

from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    nombres: str = Field(min_length=1, max_length=150)
    apellidos: str = Field(min_length=1, max_length=150)
    fecha_nacimiento: date
    genero: str = Field(min_length=1, max_length=30)
    correo: EmailStr
    usuario: str = Field(min_length=3, max_length=50)
    contrasena: str = Field(min_length=8, max_length=128)


class UserPublic(BaseModel):
    id: int
    nombres: str
    apellidos: str
    fecha_nacimiento: date
    genero: str
    correo: EmailStr
    usuario: str
    rol: str = "user"
    activo: bool = True
    mfa_enabled: bool = False

    model_config = {"from_attributes": True}


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    mfa_required: bool = False
    mfa_token: str | None = None


class LoginResponse(BaseModel):
    """Login puede devolver tokens o un challenge MFA."""

    access_token: str | None = None
    refresh_token: str | None = None
    token_type: str = "bearer"
    mfa_required: bool = False
    mfa_token: str | None = None


class MfaVerifyRequest(BaseModel):
    mfa_token: str = Field(min_length=20)
    code: str = Field(min_length=6, max_length=8, pattern=r"^\d{6,8}$")


class MfaSetupResponse(BaseModel):
    secret: str
    otpauth_uri: str
    mfa_enabled: bool


class MfaConfirmRequest(BaseModel):
    code: str = Field(min_length=6, max_length=8, pattern=r"^\d{6,8}$")


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class LogoutRequest(BaseModel):
    refresh_token: str | None = None


class TokenPayload(BaseModel):
    """Payload tipado del JWT (reservado para validación explícita en auth)."""

    sub: str
