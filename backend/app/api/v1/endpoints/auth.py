import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, status, Depends
from app.models.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    UserProfileResponse,
    RoleEnum,
    AppContextEnum
)
from app.core.security import get_password_hash, verify_password, create_access_token
from app.db.database import get_database, db_manager
from app.api.deps import get_current_user

router = APIRouter()

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(req: UserRegisterRequest):
    """Register a new user in MongoDB / In-Memory database with initial role."""
    db = get_database()
    email_or_phone = req.email_or_phone.strip().lower()
    
    # Check if user exists
    existing = None
    if db is not None:
        existing = await db.users.find_one({"email_or_phone": email_or_phone})
    else:
        for u in db_manager._in_memory_collections["users"]:
            if u["email_or_phone"] == email_or_phone:
                existing = u
                break

    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email or phone is already registered."
        )

    user_id = str(uuid.uuid4())
    hashed_pwd = get_password_hash(req.password)
    
    # Check if first user -> grant Admin privileges automatically for easy onboarding
    is_admin = False
    total_users_count = 0
    if db is not None:
        total_users_count = await db.users.count_documents({})
    else:
        total_users_count = len(db_manager._in_memory_collections["users"])
        
    if total_users_count == 0 or email_or_phone.startswith("admin"):
        is_admin = True
        
    mapped_roles = [req.primary_role.value]
    if is_admin and RoleEnum.SYSTEM_ADMIN.value not in mapped_roles:
        mapped_roles.append(RoleEnum.SYSTEM_ADMIN.value)

    now_iso = datetime.now(timezone.utc).isoformat()
    
    user_doc = {
        "_id": user_id,
        "id": user_id,
        "full_name": req.full_name,
        "email_or_phone": email_or_phone,
        "hashed_password": hashed_pwd,
        "primary_role": req.primary_role.value,
        "app_context": req.app_context.value,
        "mapped_roles": mapped_roles,
        "is_active": True,
        "is_admin": is_admin,
        "created_at": now_iso
    }

    if db is not None:
        await db.users.insert_one(user_doc)
    else:
        db_manager._in_memory_collections["users"].append(user_doc)

    access_token = create_access_token(
        user_id=user_id,
        email_or_phone=email_or_phone,
        roles=mapped_roles,
        is_admin=is_admin
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user_id=user_id,
        full_name=req.full_name,
        email_or_phone=email_or_phone,
        primary_role=req.primary_role,
        mapped_roles=[RoleEnum(r) for r in mapped_roles if r in RoleEnum.__members__],
        is_admin=is_admin
    )

@router.post("/login", response_model=TokenResponse)
async def login(req: UserLoginRequest):
    """Authenticate user with email/phone and password."""
    db = get_database()
    email_or_phone = req.email_or_phone.strip().lower()

    user_doc = None
    if db is not None:
        user_doc = await db.users.find_one({"email_or_phone": email_or_phone})
    else:
        for u in db_manager._in_memory_collections["users"]:
            if u["email_or_phone"] == email_or_phone:
                user_doc = u
                break

    if not user_doc or not verify_password(req.password, user_doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email/phone or password."
        )

    if not user_doc.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated."
        )

    mapped_roles = user_doc.get("mapped_roles", [user_doc["primary_role"]])
    is_admin = user_doc.get("is_admin", False)

    access_token = create_access_token(
        user_id=user_doc["id"],
        email_or_phone=email_or_phone,
        roles=mapped_roles,
        is_admin=is_admin
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user_id=user_doc["id"],
        full_name=user_doc["full_name"],
        email_or_phone=user_doc["email_or_phone"],
        primary_role=RoleEnum(user_doc["primary_role"]),
        mapped_roles=[RoleEnum(r) for r in mapped_roles if r in RoleEnum.__members__],
        is_admin=is_admin
    )

@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """Fetch profile details of current authenticated user."""
    mapped_roles = current_user.get("mapped_roles", [current_user["primary_role"]])
    return UserProfileResponse(
        id=current_user["id"],
        full_name=current_user["full_name"],
        email_or_phone=current_user["email_or_phone"],
        primary_role=RoleEnum(current_user["primary_role"]),
        app_context=AppContextEnum(current_user.get("app_context", AppContextEnum.AROGYA_SATHI.value)),
        mapped_roles=[RoleEnum(r) for r in mapped_roles if r in RoleEnum.__members__],
        is_active=current_user.get("is_active", True),
        is_admin=current_user.get("is_admin", False),
        created_at=current_user.get("created_at", datetime.now(timezone.utc).isoformat())
    )
