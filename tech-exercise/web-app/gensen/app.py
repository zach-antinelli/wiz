from datetime import timedelta

from auth import create_access_token, get_user_from_cookie
from config import Config
from models import CommandRequest, CommandResponse
import uvicorn
from commands import CommandProcessor
from fastapi import FastAPI, Form, HTTPException, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates


config = Config()
logger = config.logger

app = FastAPI(title="GenAI Sentry")
templates = Jinja2Templates(directory="templates")
processor = CommandProcessor(config)


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """Serve the terminal page."""
    return templates.TemplateResponse("terminal.html", {"request": request})


@app.post("/")
async def login(username: str = Form(...), password: str = Form(...)):
    if username == config.gensen_user and password == config.gensen_pw:
        access_token_expires = timedelta(minutes=config.access_token_expire_minutes)
        access_token = create_access_token(
            data={"sub": username},
            secret_key=config.secret_key,
            algorithm=config.algorithm,
            expires_delta=access_token_expires,
        )

        response = RedirectResponse(url="/terminal", status_code=status.HTTP_302_FOUND)
        response.set_cookie(
            key="access_token",
            value=access_token,
            httponly=True,
            path="/",
            max_age=(config.access_token_expire_minutes * 60),
            samesite="lax",
        )
        return response


@app.post("/execute", response_model=CommandResponse)
async def execute_command(request: Request, command: CommandRequest):
    await get_user_from_cookie(
        request=request,
        secret_key=config.secret_key,
        algorithm=config.algorithm,
        gensen_user=config.gensen_user,
    )

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
    if username == config.gensen_user and password == config.gensen_pw:
        access_token_expires = timedelta(minutes=config.access_token_expire_minutes)
        access_token = create_access_token(
            data={"sub": username},
            secret_key=config.secret_key,
            algorithm=config.algorithm,
            expires_delta=access_token_expires,
        )

        response = HTMLResponse(content="Authentication successful")
        response.set_cookie(
            key="access_token",
            value=access_token,
            httponly=True,
            path="/",
            max_age=(config.access_token_expire_minutes * 60),
            samesite="lax",
        )
        return response

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect username or password",
    )


if __name__ == "__main__":
    try:
        logger.info(
            "Starting server on %s:%d",
            config.gensen_host,
            config.gensen_port,
        )

        uvicorn.run(
            "app:app",
            host=config.gensen_host,
            port=config.gensen_port,
            reload=False,
        )
    except Exception as e:
        logger.exception(
            "Server failed to start: %s",
            e,
        )
