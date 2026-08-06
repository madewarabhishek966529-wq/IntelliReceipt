from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    AccessTokenResponse,
    ForgotPasswordRequest,
    GoogleLoginRequest,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
    UserRead,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db)):
    user, access, refresh = await AuthService(db).register(payload)
    return TokenResponse(access_token=access, refresh_token=refresh, user=UserRead.model_validate(user))


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)):
    user, access, refresh = await AuthService(db).login(payload.email, payload.password)
    return TokenResponse(access_token=access, refresh_token=refresh, user=UserRead.model_validate(user))


@router.post("/google", response_model=TokenResponse)
async def google_login(payload: GoogleLoginRequest, db: AsyncSession = Depends(get_db)):
    user, access, refresh = await AuthService(db).login_with_google(payload.id_token)
    return TokenResponse(access_token=access, refresh_token=refresh, user=UserRead.model_validate(user))


@router.post("/refresh", response_model=AccessTokenResponse)
async def refresh(payload: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    access, refresh_token = await AuthService(db).refresh_tokens(payload.refresh_token)
    return AccessTokenResponse(access_token=access, refresh_token=refresh_token)


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    token = await AuthService(db).request_password_reset(payload.email)
    if token is not None:
        # TODO(Phase 6): wire a real transactional email provider. For now
        # this is where the reset-link email would be dispatched; logging
        # keeps local/dev flows testable without SMTP configured.
        print(f"[password-reset] token for {payload.email}: {token}")
    # Always return 200 regardless of whether the account exists, so the
    # endpoint can't be used to enumerate registered emails.
    return {"message": "If that email exists, a reset link has been sent."}


@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    await AuthService(db).reset_password(payload.token, payload.new_password)
    return {"message": "Password has been reset successfully."}


@router.get("/me", response_model=UserRead)
async def me(current_user: User = Depends(get_current_user)):
    return UserRead.model_validate(current_user)


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(current_user: User = Depends(get_current_user)):
    # Stateless JWTs: nothing to revoke server-side yet. Once refresh
    # tokens are stored (Phase 7 sync work), blacklist it here.
    return {"message": "Logged out"}
