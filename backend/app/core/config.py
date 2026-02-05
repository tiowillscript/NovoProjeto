from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    environment: str = "development"
    database_url: str = "postgresql+psycopg2://novoprojeto:novoprojeto@postgres:5432/novoprojeto"
    upload_dir: str = "/data/uploads"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
