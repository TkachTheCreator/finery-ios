from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str  # required — must be set in .env, never has a random default
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours

    ENV: str = "development"

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
