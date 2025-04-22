import io
import re
from pathlib import Path

from db import MySQLDB
from llm import Claude
from rich import box
from rich.console import Console
from rich.table import Table


class CommandProcessor:
    def __init__(self, config):
        self.logger = config.logger
        self.claude = Claude()
        self.mysql = MySQLDB(
            config,
            ssl_disabled=True,
        )
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
            return result[0]["error"]

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
                self.logger.error("Invalid query request: %s", sql_query)
                return invalid_msg

            query_message = f"Executing query: {sql_query}\n\n"
            result = self.mysql.execute_query(sql_query)

            if result and isinstance(result, list):
                row_count = len(result)
                self.logger.info("Query was successful, returning %d rows", row_count)
                formatted_result = self.format_results(result)
                return query_message + formatted_result
            else:
                msg = f"Query execution failed: {result}"
                self.logger.error(msg)
                return msg
        except Exception as e:
            return f"Error: {e}"
