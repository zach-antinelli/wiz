import io
import logging
import re
from os import getenv, urandom
from pathlib import Path
from typing import Optional

import mysql.connector
from anthropic import Anthropic
from fastapi import FastAPI, Form, HTTPException, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from jose import JWTError, jwt
from rich import box
from rich.console import Console
from rich.table import Table
import uvicorn
from datetime import datetime, timedelta
from pydantic import BaseModel

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

ANTHROPIC_API_KEY = getenv("ANTHROPIC_API_KEY")
if not ANTHROPIC_API_KEY:
    raise ValueError("ANTHROPIC_API_KEY environment variable is not set")
GENSEN_USER = getenv("GENSEN_USER")
if not GENSEN_USER:
    raise ValueError("GENSEN_USER environment variable is not set")
GENSEN_PW = getenv("GENSEN_PW")
if not GENSEN_PW:
    raise ValueError("GENSEN_PW environment variable is not set")
MYSQL_HOST = getenv("MYSQL_HOST")
if not MYSQL_HOST:
    raise ValueError("MYSQL_HOST environment variable is not set")
MYSQL_DB = getenv("MYSQL_DB")
if not MYSQL_DB:
    raise ValueError("MYSQL_DB environment variable is not set")
MYSQL_USER = getenv("MYSQL_USER")
if not MYSQL_USER:
    raise ValueError("MYSQL_USER environment variable is not set")
MYSQL_PW = getenv("MYSQL_PW")
if not MYSQL_PW:
    raise ValueError("MYSQL_PW environment variable is not set")

SECRET_KEY = urandom(64).hex()
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

app = FastAPI(title="GenAI Sentry")
templates = Jinja2Templates(directory="templates")


class CommandRequest(BaseModel):
    command: str


class CommandResponse(BaseModel):
    output: Optional[str] = None
    error: Optional[str] = None


class ValidationError(Exception):
    """Custom validation error class."""

    def __init__(
        self, field: str, message: str = "A validation error occurred"
    ) -> None:
        """Handle message."""
        self.field = field
        self.message = message
        super().__init__(f"{message}: {field}")


class Claude:
    """Claude Language model handler."""

    client: Anthropic = None

    def __init__(self) -> None:
        """Validate requirements and set constants."""
        self.client = Anthropic()

    def query(self, user_prompt: str, model: str = "claude-3-7-sonnet-20250219") -> str:
        """Query Claude with a prompt."""
        system_prompt = " ".join(
            [
                "Return a SQL query based on natural langage instruction.",
                "Ensure the query is syntactically correct.",
                "Use proper SQL conventions and best practices.",
                "Avoid using backticks unless necessary.",
                "Do not include any explanations, markdown, or comments.",
                "Only return the raw SQL query as plain text.",
                "Be very careful to not make any errors.",
                "Attempt to validate if this natural language instruction is valid."
                "Validation requirements: the input query request should follow a format like"
                "get X from Y where Z. X could mean 'rows', 'columns', 'count', etc.,"
                "Y could mean a table name, and Z could mean a condition.",
                "If the language instruction requests to make changes to the database,"
                "such as inserting, updating, or deleting data, then it is considered invalid.",
                "If the query is invalid, ALWAYS return a response in the format 'invalid:'.",
                "For invalid queries, ensure that 'invalid:' is at the beginning and is lowercase.",
                "If the query is valid, return the SQL query.",
            ]
        )

        message = self.client.messages.create(
            model=model,
            max_tokens=1000,
            temperature=1,
            system=system_prompt,
            messages=[{"role": "user", "content": user_prompt}],
        )

        return message.content[0].text


class MySQLDB:
    """MySQL database connection and query handler."""

    def __init__(self) -> None:
        """Initialize environment variables for DB connection."""
        self.host = MYSQL_HOST
        self.user = MYSQL_USER
        self.password = MYSQL_PW
        self.database = MYSQL_DB
        ssl_disabled = True

        self.connection = None

    def connect(self) -> None:
        """Establish database connection."""
        self.connection = mysql.connector.connect(
            host=self.host,
            user=self.user,
            password=self.password,
            database=self.database,
        )

    def disconnect(self) -> None:
        """Close database connection."""
        if self.connection and self.connection.is_connected():
            self.connection.close()

    def execute_query(self, query: str, params: tuple | None = None) -> list[dict]:
        """Execute a SQL query and return results."""
        cursor = None
        try:
            if not self.connection or not self.connection.is_connected():
                self.connect()

            if not self.connection.is_connected():
                raise Exception("Could not connect to database")

            cursor = self.connection.cursor(dictionary=True)
            cursor.execute(query, params)

            if cursor.description:
                results = cursor.fetchall()
                return results

            self.connection.commit()
            return [{"affected_rows": [cursor.rowcount]}]
        except Exception as e:
            logger.error(e)
            return [{"error": str(e)}]
        finally:
            if cursor:
                cursor.close()


class CommandProcessor:
    """Terminal configuration and behavior."""

    def __init__(self) -> None:
        """Initialize the command processor."""
        self.claude = Claude()
        self.mysql = MySQLDB()
        self.script_dir = Path(__file__).parent
        self.commands = {
            "help": lambda _: Path("templates/help.menu").read_text(),
            "clear": lambda _: "CLEAR_SCREEN",
        }

    def format_results(self, result: list[dict]) -> str:
        """Format SQL results into table output."""
        if not result:
            return "Query returned no results"

        if "error" in result[0]:
            return f"Query error: {result[0]['error']}"

        console = Console(
            file=io.StringIO(), force_terminal=True, width=120, color_system="standard"
        )

        table = Table(
            box=box.DOUBLE_EDGE,
            show_header=True,
            header_style="bold white",
            show_lines=True,
            show_edge=True,
            padding=(0, 1),
            border_style="white",
        )

        columns = list(result[0].keys())
        num_columns = len(columns)
        available_width = console.width - (num_columns * 3) - 2
        min_width = max(10, available_width // (num_columns * 2))
        max_width = max(20, available_width // num_columns)

        for col in columns:
            table.add_column(
                str(col),
                justify="left",
                style="white",
                min_width=min_width,
                max_width=max_width,
                overflow="fold",
            )

        for row in result:
            formatted_values = [
                str(val) if val is not None else "" for val in row.values()
            ]
            table.add_row(*formatted_values)

        console.print(table)
        output = console.file.getvalue()

        return re.sub(r"\x1b\[[0-9;]*[mGKH]", "", output)

    def process_command(self, command: str) -> str:
        """Process commandline."""
        command = command.strip()
        if not command:
            return None

        parts = command.split()
        cmd = parts[0].lower()

        if cmd in self.commands:
            result = self.commands[cmd](parts[1:] if len(parts) > 1 else [])
            return result

        invalid_msg = (
            "Invalid query request.\n\n"
            "Plain language queries should follow a format like 'get X from Y where Z'.\n"
            "- X could mean 'rows', 'columns', 'count', etc.\n"
            "- Y could mean a table name\n"
            "- Z could mean a condition\n\n"
            "Queries that modify the database (insert, update, delete) are not allowed.\n\n"
        )

        try:
            command = (
                command.replace("= '", "='").replace("='", "= '").replace("'", "'")
            )

            sql_query = self.claude.query(command)
            invalid_query = re.match(
                r"^\s*(insert|update|delete|drop|alter|create|truncate)\b",
                sql_query,
                re.IGNORECASE,
            )

            if sql_query.split()[0].lower() == "invalid:" or invalid_query:
                logger.error("Invalid query request: %s", sql_query)
                return invalid_msg

            logger.info("Executing query: %s", sql_query)
            query_message = f"Executing query: {sql_query}\n\n"
            result = self.mysql.execute_query(sql_query)

            if result and isinstance(result, list):
                row_count = len(result)
                logger.info("Query was successful, returning %d rows", row_count)
                formatted_result = self.format_results(result)
                return query_message + formatted_result
            else:
                msg = f"Query execution failed: {result}"
                logger.error(msg)
                return msg
        except Exception as e:
            return f"Error: {e}"


processor = CommandProcessor()


def create_access_token(data: dict, expires_delta: timedelta = None):
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_user_from_cookie(request: Request):
    """Get user from cookie."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    token = request.cookies.get("access_token")
    if not token:
        raise credentials_exception

    if token.startswith("Bearer "):
        token = token[7:]

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None or username != GENSEN_USER:
            raise credentials_exception
        return username
    except JWTError:
        raise credentials_exception


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """Serve the terminal page."""
    return templates.TemplateResponse("terminal.html", {"request": request})


@app.post("/")
async def login(username: str = Form(...), password: str = Form(...)):
    if username == GENSEN_USER and password == GENSEN_PW:
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": username}, expires_delta=access_token_expires
        )

        response = RedirectResponse(url="/terminal", status_code=status.HTTP_302_FOUND)
        response.set_cookie(
            key="access_token",
            value=access_token,
            httponly=True,
            path="/",
            max_age=(ACCESS_TOKEN_EXPIRE_MINUTES * 60),
            samesite="lax",
        )
        return response


@app.post("/execute", response_model=CommandResponse)
async def execute_command(request: Request, command: CommandRequest):
    await get_user_from_cookie(request)

    if not command.command:
        raise HTTPException(status_code=400, detail="No command provided")

    try:
        output = processor.process_command(command.command)
        return CommandResponse(output=output)
    except Exception as e:
        return CommandResponse(error=str(e))


@app.post("/auth")
async def terminal_auth(username: str = Form(...), password: str = Form(...)):
    """Handle authentication from the terminal interface"""
    if username == GENSEN_USER and password == GENSEN_PW:
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": username}, expires_delta=access_token_expires
        )

        response = HTMLResponse(content="Authentication successful")
        response.set_cookie(
            key="access_token",
            value=access_token,
            httponly=True,
            path="/",
            max_age=(ACCESS_TOKEN_EXPIRE_MINUTES * 60),
            samesite="lax",
        )
        return response

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect username or password",
    )


if __name__ == "__main__":
    options = {
        "host": getenv("GENSEN_HOST", "127.0.0.1"),
        "port": int(getenv("GENSEN_PORT", "8080")),
    }

    try:
        logger.info(
            "Starting server on %s:%d",
            options["host"],
            options["port"],
        )
        uvicorn.run("app:app", host=options["host"], port=options["port"], reload=False)
    except Exception as e:
        logger.exception("Server failed to start: %s", e)
