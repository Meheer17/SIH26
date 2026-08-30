import sys
import os
import asyncio
from datetime import datetime, timezone, timedelta
from fastapi import HTTPException

# Add backend directory to Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "..", "..", "OneDrive", "Desktop", "SIH26", "backend")))

from app.db.database import db_manager
from app.models.schemas import VerifyOtpRequest
from app.api.v1.endpoints.auth import generate_secure_otp, generate_and_save_otp, verify_otp

async def run_tests():
    print("[START] STARTING OTP VERIFICATION TEST SUITE...")
    
    # 1. Test secure randomness
    otp1 = generate_secure_otp()
    otp2 = generate_secure_otp()
    print(f"   [1] Secure Random Generated: {otp1}, {otp2}")
    assert len(otp1) == 6 and len(otp2) == 6, "OTP length must be 6"
    assert otp1 != otp2, "OTPs should be random and not equal"
    print("   [OK] Secure Randomness Check: PASSED")

    # Setup mock user context
    test_user_id = "test-user-uuid"
    test_email = "tester@sih.gov.in"
    user_doc = {
        "id": test_user_id,
        "full_name": "Test User",
        "email_or_phone": test_email,
        "hashed_password": "hashed_password",
        "primary_role": "PATIENT",
        "app_context": "arogya_sathi",
        "mapped_roles": ["PATIENT"],
        "is_active": True,
        "is_admin": False,
        "is_verified": False,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    # Inject user into in-memory collections
    db_manager._in_memory_collections["users"] = [user_doc]
    db_manager.db = None # Force fallback to in-memory mode for tests
    
    # 2. Test OTP Generation and Storage
    otp_code = await generate_and_save_otp(test_email)
    print(f"   [2] Generated code: {otp_code} for user: {test_email}")
    stored_otps = db_manager._in_memory_collections["otps"]
    assert len(stored_otps) == 1, "OTP should be stored in collections"
    assert stored_otps[0]["otp_code"] == otp_code, "Stored OTP must match generated"
    print("   [OK] Generation and Storage Check: PASSED")

    # 3. Test Invalid OTP fails
    try:
        req = VerifyOtpRequest(email_or_phone=test_email, otp_code="000000")
        await verify_otp(req)
        assert False, "Verification should fail for incorrect OTP"
    except HTTPException as e:
        print(f"   [3] Failed as expected with message: {e.detail}")
        assert "Invalid OTP code" in e.detail, "Should return invalid OTP detail"
    print("   [OK] Incorrect OTP Failure Check: PASSED")

    # 4. Test Remaining Attempts decrement
    stored_otps = db_manager._in_memory_collections["otps"]
    attempts = stored_otps[0]["attempts"]
    print(f"   [4] Stored attempts after 1 fail: {attempts}")
    assert attempts == 1, "Failed attempts count should increment to 1"
    print("   [OK] Attempts Counter Check: PASSED")

    # 5. Test Maximum incorrect attempts invalidates OTP
    print("   [5] Triggering 4 more incorrect attempts...")
    for i in range(4):
        try:
            req = VerifyOtpRequest(email_or_phone=test_email, otp_code="000000")
            await verify_otp(req)
        except HTTPException as e:
            last_message = e.detail
            
    print(f"       Final fail message: {last_message}")
    assert "Verification blocked" in last_message, "Should block verification after 5 failures"
    stored_otps = db_manager._in_memory_collections["otps"]
    assert len(stored_otps) == 0, "OTP must be deleted from database after 5 failures"
    print("   [OK] Maximum Incorrect Attempts Lockout Check: PASSED")

    # 6. Test Expiration Check
    print("   [6] Testing expired OTP rejection...")
    otp_code = await generate_and_save_otp(test_email)
    stored_otps = db_manager._in_memory_collections["otps"]
    # Force expired state
    stored_otps[0]["expires_at"] = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
    try:
        req = VerifyOtpRequest(email_or_phone=test_email, otp_code=otp_code)
        await verify_otp(req)
        assert False, "Should fail verification when OTP is expired"
    except HTTPException as e:
        print(f"       Failed as expected: {e.detail}")
        assert "expired" in e.detail
    stored_otps = db_manager._in_memory_collections["otps"]
    assert len(stored_otps) == 0, "Expired OTP must be deleted"
    print("   [OK] Expiration Check: PASSED")

    # 7. Test Successful verification, single-use invalidation, and is_verified status update
    print("   [7] Testing correct verification flow...")
    otp_code = await generate_and_save_otp(test_email)
    req = VerifyOtpRequest(email_or_phone=test_email, otp_code=otp_code)
    response = await verify_otp(req)
    
    # Check verified status in users collection
    assert db_manager._in_memory_collections["users"][0]["is_verified"] is True, "User is_verified must be set to True"
    # Check single-use invalidation
    stored_otps = db_manager._in_memory_collections["otps"]
    assert len(stored_otps) == 0, "OTP must be deleted upon successful verification"
    print(f"       Verification Response access token: {response.access_token[:20]}...")
    print("   [OK] Success & Invalidation Check: PASSED")

    print("\n[SUCCESS] ALL OTP BUSINESS LOGIC TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    asyncio.run(run_tests())
