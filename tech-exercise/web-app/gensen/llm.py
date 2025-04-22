from anthropic import Anthropic


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
                "Return a MySQL query based on natural langage instruction.",
                "Ensure the query is syntactically correct.",
                "Use proper MySQL conventions and best practices.",
                "Ensure to use proper MySQL syntax.",
                "Avoid using backticks unless necessary.",
                "Do not include any explanations, markdown, or comments.",
                "Only return the raw MySQL query as plain text.",
                "Be very careful to not make any errors.",
                "If a query such as 'get 5 from X' is given, return 5 rows from X",
                "with X being a table name. For example: 'get 5 from prowler'.",
                "If a query such as 'get results from X' is given, return all results from X.",
                "Attempt to validate if this natural language instruction is valid.",
                "Validation requirements: the input query request should follow a format like",
                "'get X from Y where Z'. X could mean 'rows', 'columns', 'count', etc.",
                "Y could mean a table name, and Z could mean a condition.",
                "Be flexible with the language and try to understand the intent.",
                "If the language instruction requests to make changes to the database,",
                "such as inserting, updating, or deleting data, then it is considered invalid.",
                "If the query is invalid, ALWAYS return a response in the format 'invalid:'.",
                "For invalid queries, ensure that 'invalid:' is at the beginning and is lowercase.",
                "If the query is valid, return the MySQL query only.",
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
