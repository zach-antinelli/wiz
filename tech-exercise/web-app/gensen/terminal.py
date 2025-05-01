import re
from pathlib import Path

from db import MySQLDB
from llm import Claude


class Terminal:
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
        """Format SQL results into a clean, readable output."""
        if not result:
            return "No results found."

        output = []

        if len(result) > 10:
            return self._format_table_results(result)

        for i, row in enumerate(result):
            output.append(f"Record {i + 1} of {len(result)}")
            output.append("─" * 80)

            max_key_length = max(len(str(key)) for key in row.keys())

            for key, value in row.items():
                key_str = str(key).ljust(max_key_length + 2)
                value_str = "" if value is None else str(value)

                if len(value_str) > 80:
                    wrapped_value = self._wrap_text(value_str, 80, max_key_length + 4)
                    output.append(f"{key_str}: {wrapped_value}")
                else:
                    output.append(f"{key_str}: {value_str}")

            if i < len(result) - 1:
                output.append("\n")

        return "\n".join(output)

    def _wrap_text(self, text: str, width: int, indent: int) -> str:
        """Wrap text to the specified width with proper indentation."""
        if not text:
            return ""

        lines = []
        first_line = True

        while text:
            if first_line:
                current_width = width
                prefix = ""
                first_line = False
            else:
                current_width = width - indent
                prefix = " " * indent

            if len(text) <= current_width:
                lines.append(f"{prefix}{text}")
                break

            split_point = text.rfind(" ", 0, current_width)
            if split_point == -1:
                split_point = current_width

            lines.append(f"{prefix}{text[:split_point]}")
            text = text[split_point:].lstrip()

        return "\n".join(lines)

    def _format_table_results(self, result: list[dict]) -> str:
        """Format results as a simplified table with horizontal scrolling support."""
        columns = list(result[0].keys())

        max_column_width = 80
        min_column_width = 20

        max_widths = {col: max(len(str(col)), min_column_width) for col in columns}

        for row in result:
            for col in columns:
                value = "" if row[col] is None else str(row[col])
                display_value = value[:max_column_width] + "..." if len(value) > max_column_width else value
                max_widths[col] = max(max_widths[col], min(len(display_value), max_column_width + 3))

        header = " | ".join(str(col).ljust(max_widths[col]) for col in columns)
        separator = "-" * len(header)

        rows = []
        for row in result:
            formatted_row = []
            for col in columns:
                value = "" if row[col] is None else str(row[col])
                display_value = value[:max_column_width] + "..." if len(value) > max_column_width else value
                formatted_row.append(display_value.ljust(max_widths[col]))
            rows.append(" | ".join(formatted_row))

        table = [header, separator] + rows
        return "\n".join(table)

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

            if isinstance(result, list) and result:
                if "error" in result[0]:
                    msg = f"Query execution failed: {result[0]['error']}"
                    self.logger.error(msg)
                    return msg
                else:
                    row_count = len(result)
                    self.logger.info(
                        "Query was successful, returning %d rows", row_count
                    )
                    formatted_result = self.format_results(result)
                    return query_message + formatted_result
            elif isinstance(result, list) and not result:
                self.logger.info("Query was successful, but returned no results")
                return query_message + "Query returned no results."
            else:
                msg = f"Query execution failed: {result}"
                self.logger.error(msg)
                return msg
        except Exception as e:
            return f"Error: {e}"
