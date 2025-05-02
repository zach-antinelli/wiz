from anthropic import Anthropic
from prompt import PROMPT

class Claude:
    """Claude Language model handler."""

    client: Anthropic = None

    def __init__(self) -> None:
        """Validate requirements and set constants."""
        self.client = Anthropic()

    def query(self, user_prompt: str, model: str = "claude-3-7-sonnet-20250219") -> str:
        """Query Claude with a prompt."""
        system_prompt = PROMPT

        message = self.client.messages.create(
            model=model,
            max_tokens=1000,
            temperature=1,
            system=system_prompt,
            messages=[{"role": "user", "content": user_prompt}],
        )

        return message.content[0].text
