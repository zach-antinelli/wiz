from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, Request, status
from jose import JWTError, jwt


def create_access_token(
    data: dict,
    secret_key: str,
    algorithm: str,
    expires_delta: timedelta = None,
):
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode,
        secret_key,
        algorithm=algorithm,
    )
    return encoded_jwt


async def get_user_from_cookie(
    request: Request,
    secret_key: str,
    algorithm: str,
    gensen_user: str,
):
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
        payload = jwt.decode(
            token,
            secret_key,
            algorithms=[algorithm],
        )
        username: str = payload.get("sub")
        if username is None or username != gensen_user:
            raise credentials_exception
        return username
    except JWTError:
        raise credentials_exception
