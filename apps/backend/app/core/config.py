from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    REDIS_URL: str = "redis://redis:6379/0" # Default for docker
    SECRET_KEY: str  # REQUIRED - must be set in .env, no default for security
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080 # 7 days

    
    # Stripe Configuration
    STRIPE_SECRET_KEY: str = "sk_test_PLACEHOLDER"  # Set in .env
    STRIPE_PUBLISHABLE_KEY: str = "pk_test_PLACEHOLDER"  # Set in .env
    STRIPE_WEBHOOK_SECRET: str = "whsec_PLACEHOLDER"  # Set in .env
    STRIPE_PLATFORM_FEE_PERCENT: float = 15.0  # Default platform fee

    class Config:
        env_file = ".env"

settings = Settings()
