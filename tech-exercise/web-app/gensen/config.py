import logging
from os import getenv, urandom


class Config:
    """Application config."""

    def __init__(self):
        self.anthropic_api_key = getenv("ANTHROPIC_API_KEY")
        self.gensen_user = getenv("GENSEN_USER")
        self.gensen_pw = getenv("GENSEN_PW")
        self.gensen_host = getenv("GENSEN_HOST", "127.0.0.1")
        self.gensen_port = int(getenv("GENSEN_PORT", "8080"))
        self.mysql_host = getenv("MYSQL_HOST")
        self.mysql_db = getenv("MYSQL_DB")
        self.mysql_user = getenv("MYSQL_USER")
        self.mysql_pw = getenv("MYSQL_PW")
        self.secret_key = urandom(64).hex()
        self.algorithm = "HS256"
        self.access_token_expire_minutes = 30

        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
        )
        self.logger = logging.getLogger(__name__)

        required_env_vars = [
            "ANTHROPIC_API_KEY",
            "GENSEN_USER",
            "GENSEN_PW",
            "MYSQL_HOST",
            "MYSQL_DB",
            "MYSQL_USER",
            "MYSQL_PW",
        ]
        for var in required_env_vars:
            if not getenv(var):
                raise ValueError(f"{var} environment variable is not set")
