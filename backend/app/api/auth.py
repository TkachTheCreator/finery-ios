import asyncio
from datetime import datetime, timedelta, timezone

import bcrypt as _bcrypt
from fastapi import APIRouter, Depends, HTTPException, Request, status
import jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.limiter import limiter
from app.models.user import User
from app.schemas.user import ForgotPasswordIn, ForgotPasswordOut, TokenOut, UserLogin, UserOut, UserRegister, UserUpdate

router = APIRouter(prefix="/auth", tags=["auth"])


def _hash(password: str) -> str:
    return _bcrypt.hashpw(password.encode(), _bcrypt.gensalt(rounds=12)).decode()


def _verify(plain: str, hashed: str) -> bool:
    return _bcrypt.checkpw(plain.encode(), hashed.encode())


async def _hash_async(password: str) -> str:
    return await asyncio.to_thread(_hash, password)


async def _verify_async(plain: str, hashed: str) -> bool:
    return await asyncio.to_thread(_verify, plain, hashed)


def _create_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode({"sub": user_id, "exp": expire}, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


async def get_current_user(token: str, db: AsyncSession) -> User:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return user


from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

bearer = HTTPBearer()


async def current_user(
    creds: HTTPAuthorizationCredentials = Depends(bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    return await get_current_user(creds.credentials, db)


@router.post("/register", response_model=TokenOut, status_code=201)
@limiter.limit("5/minute")
async def register(request: Request, body: UserRegister, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        email=body.email,
        hashed_password=await _hash_async(body.password),
        name=body.name,
        tax_mode=body.tax_mode,
        user_type=body.user_type,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)

    return TokenOut(
        access_token=_create_token(str(user.id)),
        user=UserOut.model_validate(user),
    )


@router.post("/login", response_model=TokenOut)
@limiter.limit("5/minute")
async def login(request: Request, body: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()
    # Unified message prevents user enumeration via different error codes
    if not user or not await _verify_async(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Неверный email или пароль")

    return TokenOut(
        access_token=_create_token(str(user.id)),
        user=UserOut.model_validate(user),
    )


@router.get("/me", response_model=UserOut)
async def me(user: User = Depends(current_user)):
    return user


@router.put("/me", response_model=UserOut)
async def update_me(
    body: UserUpdate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    if body.name is not None:
        user.name = body.name
    if body.tax_mode is not None:
        user.tax_mode = body.tax_mode
    if body.user_type is not None:
        user.user_type = body.user_type
    await db.flush()
    await db.refresh(user)
    return user


@router.post("/forgot-password", response_model=ForgotPasswordOut)
@limiter.limit("5/minute")
async def forgot_password(request: Request, body: ForgotPasswordIn, db: AsyncSession = Depends(get_db)):
    # Always return 200 regardless of whether email exists (prevent user enumeration)
    await db.execute(select(User).where(User.email == body.email))
    return ForgotPasswordOut(message="Если email существует, письмо отправлено")
