from typing import List
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, status, Depends
from app.models.schemas import (
    RoleMappingRequest,
    RoleMappingResponse,
    UserProfileResponse,
    RoleEnum,
    AppContextEnum
)
from app.db.database import get_database, db_manager
from app.api.deps import require_admin

router = APIRouter()

@router.get("/users", response_model=List[UserProfileResponse])
async def list_all_users(admin_user: dict = Depends(require_admin)):
    """List all registered users in the platform for admin role management."""
    db = get_database()
    users_list = []
    
    if db is not None:
        cursor = db.users.find({})
        async for doc in cursor:
            mapped_roles = doc.get("mapped_roles", [doc["primary_role"]])
            users_list.append(UserProfileResponse(
                id=doc["id"],
                full_name=doc["full_name"],
                email_or_phone=doc["email_or_phone"],
                primary_role=RoleEnum(doc["primary_role"]),
                app_context=AppContextEnum(doc.get("app_context", AppContextEnum.AROGYA_SATHI.value)),
                mapped_roles=[RoleEnum(r) for r in mapped_roles if r in RoleEnum.__members__],
                is_active=doc.get("is_active", True),
                is_admin=doc.get("is_admin", False),
                created_at=doc.get("created_at", datetime.now(timezone.utc).isoformat())
            ))
    else:
        for doc in db_manager._in_memory_collections["users"]:
            mapped_roles = doc.get("mapped_roles", [doc["primary_role"]])
            users_list.append(UserProfileResponse(
                id=doc["id"],
                full_name=doc["full_name"],
                email_or_phone=doc["email_or_phone"],
                primary_role=RoleEnum(doc["primary_role"]),
                app_context=AppContextEnum(doc.get("app_context", AppContextEnum.AROGYA_SATHI.value)),
                mapped_roles=[RoleEnum(r) for r in mapped_roles if r in RoleEnum.__members__],
                is_active=doc.get("is_active", True),
                is_admin=doc.get("is_admin", False),
                created_at=doc.get("created_at", datetime.now(timezone.utc).isoformat())
            ))

    return users_list

@router.post("/users/{user_id}/roles", response_model=RoleMappingResponse)
async def map_user_roles(
    user_id: str,
    req: RoleMappingRequest,
    admin_user: dict = Depends(require_admin)
):
    """Admin maps specific RBAC roles to a registered user."""
    db = get_database()
    target_user = None

    if db is not None:
        target_user = await db.users.find_one({"_id": user_id})
    else:
        for u in db_manager._in_memory_collections["users"]:
            if u["id"] == user_id:
                target_user = u
                break

    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID '{user_id}' not found."
        )

    new_str_roles = list(set([r.value for r in req.roles]))
    
    # Preserve admin role if target user is admin
    if target_user.get("is_admin", False) and RoleEnum.SYSTEM_ADMIN.value not in new_str_roles:
        new_str_roles.append(RoleEnum.SYSTEM_ADMIN.value)

    updated_at_iso = datetime.now(timezone.utc).isoformat()

    if db is not None:
        update_fields = {"mapped_roles": new_str_roles, "updated_at": updated_at_iso}
        if req.app_context:
            update_fields["app_context"] = req.app_context.value
            
        await db.users.update_one(
            {"_id": user_id},
            {"$set": update_fields}
        )
    else:
        target_user["mapped_roles"] = new_str_roles
        if req.app_context:
            target_user["app_context"] = req.app_context.value
        target_user["updated_at"] = updated_at_iso

    return RoleMappingResponse(
        user_id=user_id,
        full_name=target_user["full_name"],
        email_or_phone=target_user["email_or_phone"],
        primary_role=RoleEnum(target_user["primary_role"]),
        mapped_roles=[RoleEnum(r) for r in new_str_roles if r in RoleEnum.__members__],
        updated_at=updated_at_iso
    )
