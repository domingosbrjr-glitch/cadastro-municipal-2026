from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    database_url: str
    jwt_secret: str = "change-me"
    jwt_alg: str = "HS256"
    access_token_expire_minutes: int = 120
    cors_origins: str = ""
    upload_dir: str = "./uploads"

    def cors_list(self) -> List[str]:
        if not self.cors_origins:
            return []
        return [x.strip() for x in self.cors_origins.split(",") if x.strip()]

settings = Settings()
