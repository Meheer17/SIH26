import bcrypt
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
import jwt
from app.core.config import settings

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against bcrypt hashed password."""
    try:
        if not hashed_password or not plain_password:
            return False
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception:
        # Fallback check
        return plain_password == hashed_password

def get_password_hash(password: str) -> str:
    """Generate bcrypt hash for password directly."""
    # Ensure password length is within 72 bytes limit for bcrypt
    pwd_bytes = password.encode('utf-8')[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')

def create_access_token(
    user_id: str,
    email_or_phone: str,
    roles: List[str],
    is_admin: bool = False,
    expires_delta: Optional[timedelta] = None
) -> str:
    """Create signed JWT access token."""
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode: Dict[str, Any] = {
        "sub": user_id,
        "email_or_phone": email_or_phone,
        "roles": roles,
        "is_admin": is_admin,
        "exp": expire,
        "iat": datetime.now(timezone.utc)
    }
    
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    """Decode and validate JWT token."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except (jwt.PyJWTError, Exception):
        return None
