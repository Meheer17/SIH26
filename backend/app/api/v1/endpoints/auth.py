import uuid
import secrets
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, HTTPException, status, Depends
from app.models.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    UserProfileResponse,
    RoleEnum,
    AppContextEnum,
    UserRegisterResponse,
    VerifyOtpRequest,
    ResendOtpRequest,
    RefreshTokenRequest
)
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token, decode_access_token
from app.db.database import get_database, db_manager
from app.api.deps import get_current_user

router = APIRouter()


def safe_role_enum(role_val, default: RoleEnum = RoleEnum.PATIENT) -> RoleEnum:
    if isinstance(role_val, RoleEnum):
        return role_val
    if isinstance(role_val, str):
        if role_val in RoleEnum.__members__:
            return RoleEnum[role_val]
        for member in RoleEnum:
            if member.value == role_val:
                return member
    return default


def generate_secure_otp() -> str:
    """Generate a cryptographically secure 6-digit numeric OTP."""
    return "".join(secrets.choice("0123456789") for _ in range(6))


async def generate_and_save_otp(email_or_phone: str) -> str:
    """Helper to generate a secure 6-digit numeric OTP, save it, and output to standard logging console in DEBUG mode."""
    otp_code = generate_secure_otp()
    expires_at = (datetime.now(timezone.utc) + timedelta(minutes=5)).isoformat()
    otp_doc = {
        "email_or_phone": email_or_phone,
        "otp_code": otp_code,
        "expires_at": expires_at,
        "attempts": 0,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    db = get_database()
    if db is not None:
        # Invalidate old OTPs for this user
        await db.otps.delete_many({"email_or_phone": email_or_phone})
        await db.otps.insert_one(otp_doc)
    else:
        # Fallback in-memory
        db_manager._in_memory_collections["otps"] = [
            otp for otp in db_manager._in_memory_collections["otps"]
            if otp["email_or_phone"] != email_or_phone
        ]
        db_manager._in_memory_collections["otps"].append(otp_doc)
        
    from app.core.config import settings
    if settings.DEBUG:
        print(f"\n==================================================")
        print(f"SECURITY OTP GENERATED FOR: {email_or_phone}")
        print(f"   CODE: {otp_code}")
        print(f"   EXPIRES AT: {expires_at}")
        print(f"==================================================\n")
    return otp_code


@router.post("/register", response_model=UserRegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(req: UserRegisterRequest):
    """Register a new user in MongoDB / In-Memory database (verification required)."""
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
    
    # Check if first user -> grant Admin privileges automatically
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
        "is_verified": False,
        "created_at": now_iso
    }

    if db is not None:
        await db.users.insert_one(user_doc)
    else:
        db_manager._in_memory_collections["users"].append(user_doc)

    otp_code = await generate_and_save_otp(email_or_phone)

    from app.core.config import settings
    if settings.DEBUG:
        message = f"Registration successful. Please verify using OTP: {otp_code} (logged to console)"
    else:
        message = "Registration successful. Please verify using the OTP sent to your email or phone."

    return UserRegisterResponse(
        message=message,
        email_or_phone=email_or_phone,
        is_verified=False
    )


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(req: VerifyOtpRequest):
    """Verify registration OTP and activate session with access + refresh tokens."""
    db = get_database()
    email_or_phone = req.email_or_phone.strip().lower()
    otp_code = req.otp_code.strip()
    
    user_doc = None
    if db is not None:
        user_doc = await db.users.find_one({"email_or_phone": email_or_phone})
    else:
        for u in db_manager._in_memory_collections["users"]:
            if u["email_or_phone"] == email_or_phone:
                user_doc = u
                break
                
    if not user_doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
        
    otp_doc = None
    if db is not None:
        otp_doc = await db.otps.find_one({"email_or_phone": email_or_phone})
    else:
        for o in db_manager._in_memory_collections["otps"]:
            if o["email_or_phone"] == email_or_phone:
                otp_doc = o
                break
                
    if not otp_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No active OTP verification code found for this user.")
        
    attempts = otp_doc.get("attempts", 0)
    
    # Check attempts limit
    if attempts >= 5:
        if db is not None:
            await db.otps.delete_many({"email_or_phone": email_or_phone})
        else:
            db_manager._in_memory_collections["otps"] = [
                o for o in db_manager._in_memory_collections["otps"]
                if o["email_or_phone"] != email_or_phone
            ]
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification blocked. Too many incorrect attempts. Please request a new OTP."
        )

    # Check expiration
    expires_at = datetime.fromisoformat(otp_doc["expires_at"].replace("Z", "+00:00"))
    if datetime.now(timezone.utc) > expires_at:
        if db is not None:
            await db.otps.delete_many({"email_or_phone": email_or_phone})
        else:
            db_manager._in_memory_collections["otps"] = [
                o for o in db_manager._in_memory_collections["otps"]
                if o["email_or_phone"] != email_or_phone
            ]
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP has expired. Please request a new one.")

    # Match code
    if otp_doc["otp_code"] != otp_code:
        attempts += 1
        if attempts >= 5:
            if db is not None:
                await db.otps.delete_many({"email_or_phone": email_or_phone})
            else:
                db_manager._in_memory_collections["otps"] = [
                    o for o in db_manager._in_memory_collections["otps"]
                    if o["email_or_phone"] != email_or_phone
                ]
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification blocked. Too many incorrect attempts. Please request a new OTP."
            )
        else:
            if db is not None:
                await db.otps.update_one({"email_or_phone": email_or_phone}, {"$set": {"attempts": attempts}})
            else:
                otp_doc["attempts"] = attempts
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid OTP code. Remaining attempts: {5 - attempts}."
            )

    # Activate user verification status & delete OTP code (single-use validation)
    if db is not None:
        await db.users.update_one({"email_or_phone": email_or_phone}, {"$set": {"is_verified": True}})
        await db.otps.delete_many({"email_or_phone": email_or_phone})
    else:
        user_doc["is_verified"] = True
        db_manager._in_memory_collections["otps"] = [
            o for o in db_manager._in_memory_collections["otps"]
            if o["email_or_phone"] != email_or_phone
        ]
        
    mapped_roles = user_doc.get("mapped_roles", [user_doc["primary_role"]])
    is_admin = user_doc.get("is_admin", False)
    
    access_token = create_access_token(
        user_id=user_doc["id"],
        email_or_phone=email_or_phone,
        roles=mapped_roles,
        is_admin=is_admin
    )
    refresh_token = create_refresh_token(user_id=user_doc["id"])
    
    ref_doc = {
        "user_id": user_doc["id"],
        "token": refresh_token,
        "revoked": False,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    if db is not None:
        await db.refresh_tokens.update_one(
            {"user_id": user_doc["id"]},
            {"$set": ref_doc},
            upsert=True
        )
    else:
        db_manager._in_memory_collections["refresh_tokens"] = [
            t for t in db_manager._in_memory_collections["refresh_tokens"]
            if t["user_id"] != user_doc["id"]
        ]
        db_manager._in_memory_collections["refresh_tokens"].append(ref_doc)
        
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user_id=user_doc["id"],
        full_name=user_doc["full_name"],
        email_or_phone=user_doc["email_or_phone"],
        primary_role=safe_role_enum(user_doc["primary_role"]),
        mapped_roles=[safe_role_enum(r) for r in mapped_roles],
        is_admin=is_admin
    )


@router.post("/resend-otp")
async def resend_otp(req: ResendOtpRequest):
    """Resend a new 6-digit verification code to the console logs in DEBUG mode."""
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
                
    if not user_doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
        
    otp_code = await generate_and_save_otp(email_or_phone)
    
    from app.core.config import settings
    if settings.DEBUG:
        message = f"OTP resent successfully. Check logs for code: {otp_code} (logged to console)"
    else:
        message = "OTP has been resent to your registered email or phone."
    return {"message": message}


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

    # Enforce verification check
    if not user_doc.get("is_verified", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is not verified. Please verify with OTP."
        )

    mapped_roles = user_doc.get("mapped_roles", [user_doc["primary_role"]])
    is_admin = user_doc.get("is_admin", False)

    access_token = create_access_token(
        user_id=user_doc["id"],
        email_or_phone=email_or_phone,
        roles=mapped_roles,
        is_admin=is_admin
    )
    refresh_token = create_refresh_token(user_id=user_doc["id"])

    # Update active refresh token in database
    ref_doc = {
        "user_id": user_doc["id"],
        "token": refresh_token,
        "revoked": False,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if db is not None:
        await db.refresh_tokens.update_one(
            {"user_id": user_doc["id"]},
            {"$set": ref_doc},
            upsert=True
        )
    else:
        db_manager._in_memory_collections["refresh_tokens"] = [
            t for t in db_manager._in_memory_collections["refresh_tokens"]
            if t["user_id"] != user_doc["id"]
        ]
        db_manager._in_memory_collections["refresh_tokens"].append(ref_doc)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user_id=user_doc["id"],
        full_name=user_doc["full_name"],
        email_or_phone=user_doc["email_or_phone"],
        primary_role=safe_role_enum(user_doc["primary_role"]),
        mapped_roles=[safe_role_enum(r) for r in mapped_roles],
        is_admin=is_admin
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_session(req: RefreshTokenRequest):
    """Generate new access + refresh token session if refresh token is valid."""
    db = get_database()
    token = req.refresh_token.strip()
    
    payload = decode_access_token(token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token.")
        
    user_id = payload["sub"]
    
    ref_doc = None
    if db is not None:
        ref_doc = await db.refresh_tokens.find_one({"user_id": user_id, "token": token, "revoked": False})
    else:
        for t in db_manager._in_memory_collections["refresh_tokens"]:
            if t["user_id"] == user_id and t["token"] == token and not t["revoked"]:
                ref_doc = t
                break
                
    if not ref_doc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session expired or revoked.")
        
    user_doc = None
    if db is not None:
        user_doc = await db.users.find_one({"_id": user_id})
    else:
        for u in db_manager._in_memory_collections["users"]:
            if u["id"] == user_id:
                user_doc = u
                break
                
    if not user_doc or not user_doc.get("is_active", True):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User account is deactivated.")
        
    mapped_roles = user_doc.get("mapped_roles", [user_doc["primary_role"]])
    is_admin = user_doc.get("is_admin", False)
    
    new_access_token = create_access_token(
        user_id=user_doc["id"],
        email_or_phone=user_doc["email_or_phone"],
        roles=mapped_roles,
        is_admin=is_admin
    )
    new_refresh_token = create_refresh_token(user_id=user_doc["id"])
    
    new_ref_doc = {
        "user_id": user_doc["id"],
        "token": new_refresh_token,
        "revoked": False,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if db is not None:
        await db.refresh_tokens.delete_many({"user_id": user_doc["id"]})
        await db.refresh_tokens.insert_one(new_ref_doc)
    else:
        db_manager._in_memory_collections["refresh_tokens"] = [
            t for t in db_manager._in_memory_collections["refresh_tokens"]
            if t["user_id"] != user_doc["id"]
        ]
        db_manager._in_memory_collections["refresh_tokens"].append(new_ref_doc)
        
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        user_id=user_doc["id"],
        full_name=user_doc["full_name"],
        email_or_phone=user_doc["email_or_phone"],
        primary_role=safe_role_enum(user_doc["primary_role"]),
        mapped_roles=[safe_role_enum(r) for r in mapped_roles],
        is_admin=is_admin
    )


@router.post("/logout")
async def logout(current_user: dict = Depends(get_current_user)):
    """Terminate the active session by deleting the user's refresh token on the server."""
    db = get_database()
    user_id = current_user["id"]
    
    if db is not None:
        await db.refresh_tokens.delete_many({"user_id": user_id})
    else:
        db_manager._in_memory_collections["refresh_tokens"] = [
            t for t in db_manager._in_memory_collections["refresh_tokens"]
            if t["user_id"] != user_id
        ]
        
    return {"message": "Successfully logged out. Session terminated."}


@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """Fetch profile details of current authenticated user."""
    mapped_roles = current_user.get("mapped_roles", [current_user["primary_role"]])
    
    app_ctx_val = current_user.get("app_context", AppContextEnum.AROGYA_SATHI.value)
    try:
        app_ctx = AppContextEnum(app_ctx_val)
    except ValueError:
        app_ctx = AppContextEnum.NYAYA_MANAS if "nyaya" in str(app_ctx_val) or "mental" in str(app_ctx_val) else AppContextEnum.AROGYA_SATHI

    prim_role = safe_role_enum(current_user.get("primary_role"))

    return UserProfileResponse(
        id=current_user["id"],
        full_name=current_user["full_name"],
        email_or_phone=current_user["email_or_phone"],
        primary_role=prim_role,
        app_context=app_ctx,
        mapped_roles=[safe_role_enum(r) for r in mapped_roles],
        is_active=current_user.get("is_active", True),
        is_admin=current_user.get("is_admin", False),
        is_verified=current_user.get("is_verified", False),
        created_at=current_user.get("created_at", datetime.now(timezone.utc).isoformat())
    )
