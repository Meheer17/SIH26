import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "backend")))

from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token

client = TestClient(app)

def test_nyaya_api_endpoints():
    print("=== TESTING NYAYA-MANAS API ENDPOINTS WITH FASTAPI TESTCLIENT ===")
    
    # Use default demo user (no token required)
    headers = {}



    # 1. Test POST /api/v1/apps/nyaya/compensation
    print("\n1. Testing POST /api/v1/apps/nyaya/compensation:")
    r1 = client.post("/api/v1/apps/nyaya/compensation", json={"offense_category": "rape", "case_stage": "fir"}, headers=headers)
    print("Status:", r1.status_code, "Body:", r1.json())
    assert r1.status_code == 200, f"Expected 200 OK, got {r1.status_code}"

    # 2. Test GET /api/v1/apps/nyaya/dashboard-stats
    print("\n2. Testing GET /api/v1/apps/nyaya/dashboard-stats:")
    r2 = client.get("/api/v1/apps/nyaya/dashboard-stats?tier=district", headers=headers)
    print("Status:", r2.status_code, "Body keys:", list(r2.json().keys()))
    assert r2.status_code == 200, f"Expected 200 OK, got {r2.status_code}"

    # 3. Test POST /api/v1/apps/nyaya/xai-breakdown
    print("\n3. Testing POST /api/v1/apps/nyaya/xai-breakdown:")
    r3 = client.post("/api/v1/apps/nyaya/xai-breakdown", json={"victim_id": "V-102", "distress_score": 75}, headers=headers)
    print("Status:", r3.status_code, "Body keys:", list(r3.json().keys()))
    assert r3.status_code == 200, f"Expected 200 OK, got {r3.status_code}"

    # 4. Test POST /api/v1/apps/nyaya/ivrs-simulate
    print("\n4. Testing POST /api/v1/apps/nyaya/ivrs-simulate:")
    r4 = client.post("/api/v1/apps/nyaya/ivrs-simulate", json={"phone_number": "+919876543210", "dtmf_choice": 1}, headers=headers)
    print("Status:", r4.status_code, "Body:", r4.json())
    assert r4.status_code == 200, f"Expected 200 OK, got {r4.status_code}"

    # 5. Test POST /api/v1/apps/rakshak/hrms-stress
    print("\n5. Testing POST /api/v1/apps/rakshak/hrms-stress:")
    r5 = client.post("/api/v1/apps/rakshak/hrms-stress", json={"weekly_duty_hours": 65, "deployment_days": 120}, headers=headers)
    print("Status:", r5.status_code, "Body:", r5.json())
    assert r5.status_code == 200, f"Expected 200 OK, got {r5.status_code}"

    # 6. Test GET /api/v1/apps/rakshak/commander-dashboard
    print("\n6. Testing GET /api/v1/apps/rakshak/commander-dashboard:")
    r6 = client.get("/api/v1/apps/rakshak/commander-dashboard?unit_id=UNIT-CAPF-44", headers=headers)
    print("Status:", r6.status_code, "Body keys:", list(r6.json().keys()))
    assert r6.status_code == 200, f"Expected 200 OK, got {r6.status_code}"

    print("\n✅ ALL API ENDPOINTS RETURNED 200 OK!")


if __name__ == "__main__":
    test_nyaya_api_endpoints()
