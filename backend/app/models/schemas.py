from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime

class RoleEnum(str, Enum):
    # Tier 1 - Base Users
    PATIENT = "PATIENT"
    SOLDIER = "SOLDIER"
    VICTIM = "VICTIM"
    CITIZEN = "CITIZEN"
    
    # Tier 2 - Specialists / Care Providers (Consent bound)
    PHYSICIAN = "PHYSICIAN"
    WELFARE_OFFICER = "WELFARE_OFFICER"
    COUNSELOR = "COUNSELOR"
    
    # Tier 3 - Supervisors / Authorities (Anonymized / Escalation view)
    COMMANDER = "COMMANDER"
    DISTRICT_OFFICER = "DISTRICT_OFFICER"
    STATE_ADMIN = "STATE_ADMIN"
    
    # Tier 4 - System Administrator
    SYSTEM_ADMIN = "SYSTEM_ADMIN"

class AppContextEnum(str, Enum):
    AROGYA_SATHI = "arogya_sathi"
    MEDIKIOSK = "medikiosk"
    RAKSHAK_MITRA = "rakshak_mitra"
    NYAYA_SAHAY = "nyaya_sahay"
    PLATFORM_ADMIN = "platform_admin"

# --- AUTH SCHEMAS ---

class UserRegisterRequest(BaseModel):
    full_name: str = Field(..., example="Rahul Sharma")
    email_or_phone: str = Field(..., example="rahul@example.com")
    password: str = Field(..., min_length=6, example="password123")
    primary_role: RoleEnum = Field(default=RoleEnum.PATIENT)
    app_context: AppContextEnum = Field(default=AppContextEnum.AROGYA_SATHI)

class UserLoginRequest(BaseModel):
    email_or_phone: str = Field(..., example="rahul@example.com")
    password: str = Field(..., example="password123")

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    full_name: str
    email_or_phone: str
    primary_role: RoleEnum
    mapped_roles: List[RoleEnum]
    is_admin: bool

class UserProfileResponse(BaseModel):
    id: str
    full_name: str
    email_or_phone: str
    primary_role: RoleEnum
    app_context: AppContextEnum
    mapped_roles: List[RoleEnum]
    is_active: bool
    is_admin: bool
    created_at: str

# --- RBAC & ROLE MAPPING SCHEMAS ---

class RoleMappingRequest(BaseModel):
    user_id: str
    roles: List[RoleEnum]
    app_context: Optional[AppContextEnum] = None

class RoleMappingResponse(BaseModel):
    user_id: str
    full_name: str
    email_or_phone: str
    primary_role: RoleEnum
    mapped_roles: List[RoleEnum]
    updated_at: str

# --- CONSENT ENGINE SCHEMAS ---

class ConsentGrantRequest(BaseModel):
    grantee_id: str = Field(..., description="ID of the doctor/counselor receiving consent")
    grantee_name: str = Field(..., description="Name of the specialist")
    purpose: str = Field(..., example="Clinical OPD Consultation & History Intake")
    scopes: List[str] = Field(default=["vitals:read", "medical_history:read", "notes:write"])
    duration_days: int = Field(default=30)

class ConsentRecordResponse(BaseModel):
    id: str
    user_id: str
    grantee_id: str
    grantee_name: str
    purpose: str
    scopes: List[str]
    is_revoked: bool
    created_at: str
    expires_at: str

class ConsentRevokeRequest(BaseModel):
    consent_id: str
