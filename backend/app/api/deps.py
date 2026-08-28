from typing import List, Callable, Optional, Dict, Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.security import decode_access_token
from app.models.schemas import RoleEnum
from app.db.database import get_database, db_manager

security_bearer = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_bearer)
) -> Dict[str, Any]:
    """Dependency to extract, decode JWT bearer token and return user profile."""
    token = credentials.credentials
    payload = decode_access_token(token)
    
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = payload["sub"]
    db = get_database()
    
    user_doc = None
    if db is not None:
        user_doc = await db.users.find_one({"_id": user_id})
    
    if not user_doc:
        # Check in-memory store fallback
        for u in db_manager._in_memory_collections["users"]:
            if u["id"] == user_id:
                user_doc = u
                break

    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User associated with token not found"
        )
        
    return user_doc

def require_roles(allowed_roles: List[RoleEnum]) -> Callable:
    """Dependency factory enforcing that current user holds at least one of the allowed roles or is Admin."""
    async def role_checker(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
        user_roles = current_user.get("mapped_roles", [])
        is_admin = current_user.get("is_admin", False)
        
        if is_admin or RoleEnum.SYSTEM_ADMIN.value in user_roles:
            return current_user
            
        allowed_str_values = [r.value if isinstance(r, RoleEnum) else r for r in allowed_roles]
        
        has_role = any(r in allowed_str_values for r in user_roles)
        if not has_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Requires one of roles: {[r.value for r in allowed_roles]}"
            )
        return current_user

    return role_checker

async def require_admin(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
    """Dependency enforcing system administrator role."""
    is_admin = current_user.get("is_admin", False)
    user_roles = current_user.get("mapped_roles", [])
    
    if not is_admin and RoleEnum.SYSTEM_ADMIN.value not in user_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to System Administrators"
        )
    return current_user
