from typing import Optional
from pydantic import BaseModel


class CommandRequest(BaseModel):
    command: str


class CommandResponse(BaseModel):
    output: Optional[str] = None
    error: Optional[str] = None
