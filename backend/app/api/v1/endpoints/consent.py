import uuid
from typing import List
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException, status, Depends
from app.models.schemas import (
    ConsentGrantRequest,
    ConsentRecordResponse,
    ConsentRevokeRequest
)
from app.db.database import get_database, db_manager
from app.api.deps import get_current_user

router = APIRouter()

@router.post("/grant", response_model=ConsentRecordResponse, status_code=status.HTTP_201_CREATED)
async def grant_consent(
    req: ConsentGrantRequest,
    current_user: dict = Depends(get_current_user)
):
    """Grant explicit, time-bound consent to a specialist (doctor/counselor)."""
    db = get_database()
    consent_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(days=req.duration_days)

    consent_doc = {
        "_id": consent_id,
        "id": consent_id,
        "user_id": current_user["id"],
        "user_name": current_user["full_name"],
        "grantee_id": req.grantee_id,
        "grantee_name": req.grantee_name,
        "purpose": req.purpose,
        "scopes": req.scopes,
        "is_revoked": False,
        "created_at": now.isoformat(),
        "expires_at": expires_at.isoformat()
    }

    if db is not None:
        await db.consents.insert_one(consent_doc)
    else:
        db_manager._in_memory_collections["consents"].append(consent_doc)

    return ConsentRecordResponse(
        id=consent_id,
        user_id=current_user["id"],
        grantee_id=req.grantee_id,
        grantee_name=req.grantee_name,
        purpose=req.purpose,
        scopes=req.scopes,
        is_revoked=False,
        created_at=now.isoformat(),
        expires_at=expires_at.isoformat()
    )

@router.get("/my-consents", response_model=List[ConsentRecordResponse])
async def list_my_consents(current_user: dict = Depends(get_current_user)):
    """Retrieve all active & historical consent records for current user."""
    db = get_database()
    consents_list = []

    if db is not None:
        cursor = db.consents.find({"user_id": current_user["id"]})
        async for doc in cursor:
            consents_list.append(ConsentRecordResponse(
                id=doc["id"],
                user_id=doc["user_id"],
                grantee_id=doc["grantee_id"],
                grantee_name=doc.get("grantee_name", "Specialist"),
                purpose=doc["purpose"],
                scopes=doc["scopes"],
                is_revoked=doc.get("is_revoked", False),
                created_at=doc["created_at"],
                expires_at=doc["expires_at"]
            ))
    else:
        for doc in db_manager._in_memory_collections["consents"]:
            if doc["user_id"] == current_user["id"]:
                consents_list.append(ConsentRecordResponse(
                    id=doc["id"],
                    user_id=doc["user_id"],
                    grantee_id=doc["grantee_id"],
                    grantee_name=doc.get("grantee_name", "Specialist"),
                    purpose=doc["purpose"],
                    scopes=doc["scopes"],
                    is_revoked=doc.get("is_revoked", False),
                    created_at=doc["created_at"],
                    expires_at=doc["expires_at"]
                ))

    return consents_list

@router.post("/revoke/{consent_id}", response_model=ConsentRecordResponse)
async def revoke_consent(
    consent_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Instantly revoke an active consent grant (DPDP Act compliance)."""
    db = get_database()
    consent_doc = None

    if db is not None:
        consent_doc = await db.consents.find_one({"_id": consent_id, "user_id": current_user["id"]})
    else:
        for c in db_manager._in_memory_collections["consents"]:
            if c["id"] == consent_id and c["user_id"] == current_user["id"]:
                consent_doc = c
                break

    if not consent_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consent record not found or not owned by user."
        )

    if db is not None:
        await db.consents.update_one({"_id": consent_id}, {"$set": {"is_revoked": True}})
        consent_doc["is_revoked"] = True
    else:
        consent_doc["is_revoked"] = True

    return ConsentRecordResponse(
        id=consent_doc["id"],
        user_id=consent_doc["user_id"],
        grantee_id=consent_doc["grantee_id"],
        grantee_name=consent_doc.get("grantee_name", "Specialist"),
        purpose=consent_doc["purpose"],
        scopes=consent_doc["scopes"],
        is_revoked=True,
        created_at=consent_doc["created_at"],
        expires_at=consent_doc["expires_at"]
    )
