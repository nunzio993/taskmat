from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    REDIS_URL: str = "redis://redis:6379/0" # Default for docker
    SECRET_KEY: str = "emergency_key_rotation_2026" # Change in prod
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080 # 7 days

    class Config:
        env_file = ".env"

settings = Settings()
