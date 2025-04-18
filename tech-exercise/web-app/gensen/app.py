#! /usr/bin/env python

"""nlpdb."""

import io
import logging
import re
from functools import wraps
from os import getenv
from pathlib import Path

import mysql.connector
from anthropic import Anthropic
from flask import (
    Flask,
    Response,
    jsonify,
    redirect,
    render_template,
    request,
    session,
)
from rich import box
from rich.console import Console
from rich.table import Table

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config["SERVER_NAME"] = None
app.secret_key = getenv("FLASK_SECRET_KEY")

admin_username = getenv("ADMIN_USERNAME")
admin_password = getenv("ADMIN_PASSWORD")


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
        """Query Claude with a prompt.

        Args:
            prompt: The text prompt to send to the LLM
            model: The Anthropic model to use

        Returns:
            The model's response text

        """
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
                "- If the query is invalid, return only 'invalid'.",
                "- If the query is valid, return the SQL query.",
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
        self.host = getenv("MYSQL_HOST")
        self.user = getenv("MYSQL_USER")
        self.password = getenv("MYSQL_PASSWORD")
        self.database = getenv("MYSQL_DATABASE")
        self.connection = None

    def _validate_table_name(self, table_name: str) -> None:
        """Validate table name contains only allowed characters."""
        if not table_name.isalnum() and not all(
            c.isalnum() or c == "_" for c in table_name
        ):
            err = "Table name must be only alphanumeric characters or underscores"
            raise ValidationError(err)

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
        """Execute a SQL query and return results.

        Args:
            query: SQL query string
            params: Optional tuple of parameters for parameterized queries

        Returns:
            list of dicts containing query results or error message

        """
        cursor = None
        try:
            if not self.connection or not self.connection.is_connected():
                self.connect()

            if not self.connection.is_connected():
                raise

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
            "help": lambda _: render_template("help.menu"),
            "clear": lambda _: "CLEAR_SCREEN",
        }

    def _format_results(self, result: list[dict]) -> str:
        """Format SQL results into a rich table output."""
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

        try:
            command.replace("= '", "='").replace("='", "= '").replace("'", "'")
            sql_query = self.claude.query(command)
            logger.info("SQL query returned from LLM: %s", sql_query)

            if sql_query == "invalid":
                msg = (
                    "Invalid query request.\n\n"
                    "Plain language queries should follow a format like 'get X from Y where Z'.\n"
                    "- X could mean 'rows', 'columns', 'count', etc.\n"
                    "- Y could mean a table name\n"
                    "- Z could mean a condition\n\n"
                    "Queries that modify the database (insert, update, delete) are considered invalid.\n\n"
                    "Please try again with a valid query request."
                )
                logger.error(msg)
                return msg

            logger.info("Executing query: %s", sql_query)
            query_message = f"Executing query: {sql_query}\n\n"
            result = self.mysql.execute_query(sql_query)

            if result and isinstance(result, list):
                row_count = len(result)
                logger.info("Query was successful, returning %d rows", row_count)
                formatted_result = self._format_results(result)
                return query_message + formatted_result
            else:
                msg = f"Query execution failed: {result}"
                logger.error(msg)
                return msg
        except Exception as e:
            return f"Error: {e}"


processor = CommandProcessor()


def login_required(f: callable) -> callable:
    """Provide basic authentication."""

    @wraps(f)
    def decorated_function(*args: tuple, **kwargs: dict) -> str:
        if "authenticated" not in session:
            return render_template("login.html")
        return f(*args, **kwargs)

    return decorated_function


@app.route("/login", methods=["GET", "POST"])
def login() -> str:
    """Process login attempt."""
    if request.method == "GET":
        if "authenticated" in session:
            return redirect("/")
        return render_template("login.html")

    logger.info("Login attempt for user: %s", request.form.get("username"))

    if (
        request.form["username"] == admin_username
        and request.form["password"] == admin_password
    ):
        session["authenticated"] = True
        logger.info("Login successful")
        return redirect("/")

    logger.info("Login failed")
    return render_template("login.html", error="Invalid credentials")


@app.route("/", methods=["GET", "POST"])
@login_required
def home() -> str:
    """Render homescreen."""
    return render_template("terminal.html")


@app.route("/execute", methods=["POST"])
def execute() -> Response:
    """Command handler."""
    command = request.json.get("command", "")
    if not command:
        return jsonify({"error": "No command provided"}), 400

    try:
        output = processor.process_command(command)
        return jsonify({"output": output})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    options = {
        "host": getenv("FLASK_HOST", "127.0.0.1"),
        "port": int(getenv("FLASK_PORT", 8080)),
        "debug": getenv("FLASK_DEBUG", "False"),
    }

    try:
        logger.info(
            "Starting server on %s:%d (debug=%s)",
            options["host"],
            options["port"],
            options["debug"],
        )

        app.run(**options)
    except Exception as e:
        logger.exception("Flask failed to start: %s", e)
