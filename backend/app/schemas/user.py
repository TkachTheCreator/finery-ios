import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, field_validator


class UserRegister(BaseModel):
    email: EmailStr
    password: str
    name: str
    tax_mode: Literal["npd", "usn6", "usn15", "patent", "none"] = "npd"
    user_type: Literal["freelancer", "ip", "blogger", "self_employed", "other"] = "freelancer"

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Пароль минимум 8 символов")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: uuid.UUID
    email: str
    name: str
    tax_mode: str
    user_type: str
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class UserUpdate(BaseModel):
    name: str | None = None
    tax_mode: Literal["npd", "usn6", "usn15", "patent", "none"] | None = None
    user_type: Literal["freelancer", "ip", "blogger", "self_employed", "other"] | None = None


class ForgotPasswordIn(BaseModel):
    email: EmailStr


class ForgotPasswordOut(BaseModel):
    message: str
