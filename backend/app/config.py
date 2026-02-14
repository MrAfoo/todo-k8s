"""Application configuration using Pydantic settings."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Database
    database_url: str = "postgresql://postgres:password@localhost:5432/todo_db"

    # JWT - Must match BETTER_AUTH_SECRET from frontend for token verification
    secret_key: str = "your-secret-key-change-in-production"
    better_auth_secret: str | None = None  # If set, this takes precedence
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # Groq (free AI API)
    groq_api_key: str | None = None
    
    # MCP Server
    mcp_server_url: str = "http://localhost:8001"
    
    # Application
    debug: bool = True
    allowed_origins: str = "http://localhost:3000,http://127.0.0.1:3000"
    
    # Note: In production, set ALLOWED_ORIGINS to your Vercel domain(s)
    # Example: ALLOWED_ORIGINS=https://your-app.vercel.app,https://your-app-git-main.vercel.app

    model_config = SettingsConfigDict(
        env_file=".env", 
        case_sensitive=False,
        extra="ignore"  # Ignore extra fields from .env parsing
    )
    
    @property
    def allowed_origins_list(self) -> list[str]:
        """Parse allowed origins from comma-separated string."""
        if isinstance(self.allowed_origins, str):
            return [origin.strip() for origin in self.allowed_origins.split(",")]
        return self.allowed_origins

    @property
    def jwt_secret(self) -> str:
        """Get the JWT secret key, preferring BETTER_AUTH_SECRET if set."""
        return self.better_auth_secret or self.secret_key


settings = Settings()
