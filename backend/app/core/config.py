from pydantic_settings import BaseSettings
from pydantic import Field
from typing import List
import os
from pathlib import Path

class Settings(BaseSettings):
    # Claude API Configuration
    anthropic_api_key: str = ""
    claude_model: str = "claude-3-5-sonnet-20241022"
    
    # Application Configuration
    app_name: str = "Math & Physics Education AI"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8000
    
    # CORS Configuration - Fix: Use Field alias and string processing
    allowed_origins_str: str = Field(
        default="http://localhost:3000,http://127.0.0.1:3000",
        alias="allowed_origins"
    )
    
    # Database Configuration
    redis_url: str = "redis://localhost:6379/0"
    
    # Knowledge Base Configuration
    knowledge_cache_dir: str = "./data/knowledge_cache"
    embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    
    # Jupyter Configuration
    jupyter_timeout: int = 30
    jupyter_kernel: str = "python3"
    
    # Tools Configuration
    code_execution_timeout: int = 30
    max_output_size: int = 10 * 1024 * 1024  # 10MB
    
    # Security Configuration
    max_message_length: int = 10000
    rate_limit_requests: int = 100
    rate_limit_window: int = 3600  # 1 hour
    
    # Frontend Configuration
    react_app_api_url: str = "http://localhost:8000"
    
    @property
    def allowed_origins(self) -> List[str]:
        """Convert comma-separated string to list"""
        return [origin.strip() for origin in self.allowed_origins_str.split(',') if origin.strip()]
    
    class Config:
        # Fix: Use Pydantic V2 configuration syntax
        env_file = Path(__file__).parent.parent.parent / ".env"
        case_sensitive = False
        env_file_encoding = 'utf-8'
        # Allow extra fields
        extra = 'ignore'

# Manually load .env file at import time to ensure environment variables are read correctly
from dotenv import load_dotenv
env_path = Path(__file__).parent.parent.parent / ".env"
if env_path.exists():
    load_dotenv(env_path)

settings = Settings() 