from datetime import timedelta

from fastapi import HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.security import (
    create_password_reset_token,
    create_token_pair,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import RegisterRequest

settings = get_settings()

PASSWORD_RESET_TOKEN_TYPE = "password_reset"


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.users = UserRepository(db)

    async def register(self, payload: RegisterRequest) -> tuple[User, str, str]:
        existing = await self.users.get_by_email(payload.email)
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists",
            )

        user = await self.users.create(
            email=payload.email,
            name=payload.name,
            hashed_password=hash_password(payload.password),
        )
        access, refresh = create_token_pair(str(user.id))
        return user, access, refresh

    async def login(self, email: str, password: str) -> tuple[User, str, str]:
        user = await self.users.get_by_email(email)
        invalid_creds = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
        if user is None or user.hashed_password is None:
            raise invalid_creds
        if not verify_password(password, user.hashed_password):
            raise invalid_creds
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled"
            )

        access, refresh = create_token_pair(str(user.id))
        return user, access, refresh

    async def login_with_google(self, id_token_str: str) -> tuple[User, str, str]:
        try:
            info = google_id_token.verify_oauth2_token(
                id_token_str, google_requests.Request(), settings.GOOGLE_CLIENT_ID
            )
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Google token",
            ) from exc

        google_sub = info["sub"]
        email = info["email"]

        user = await self.users.get_by_google_id(google_sub)
        if user is None:
            user = await self.users.get_by_email(email)
            if user is not None:
                # Existing email/password account signing in with Google for
                # the first time: link the account rather than duplicating it.
                user = await self.users.update(user, google_id=google_sub)
            else:
                user = await self.users.create(
                    email=email,
                    name=info.get("name", email.split("@")[0]),
                    google_id=google_sub,
                    photo_url=info.get("picture"),
                    email_verified=info.get("email_verified", False),
                )

        access, refresh = create_token_pair(str(user.id))
        return user, access, refresh

    async def refresh_tokens(self, refresh_token: str) -> tuple[str, str]:
        payload = decode_token(refresh_token)
        invalid = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token"
        )
        if payload is None or payload.get("type") != "refresh":
            raise invalid

        user_id = payload.get("sub")
        user = await self.users.get_by_id(user_id) if user_id else None
        if user is None or not user.is_active:
            raise invalid

        return create_token_pair(str(user.id))

    async def request_password_reset(self, email: str) -> str | None:
        """Returns a short-lived reset token, or None if no account exists
        (caller should still respond 200 either way to avoid leaking which
        emails are registered).
        """
        user = await self.users.get_by_email(email)
        if user is None:
            return None
        return create_password_reset_token(str(user.id), timedelta(minutes=30), PASSWORD_RESET_TOKEN_TYPE)

    async def reset_password(self, token: str, new_password: str) -> None:
        payload = decode_token(token)
        invalid = HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset token"
        )
        if payload is None or payload.get("type") != PASSWORD_RESET_TOKEN_TYPE:
            raise invalid

        user_id = payload.get("sub")
        user = await self.users.get_by_id(user_id) if user_id else None
        if user is None:
            raise invalid

        await self.users.update(user, hashed_password=hash_password(new_password))
