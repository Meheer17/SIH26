import requests
import json

BASE_URL = "http://127.0.0.1:8000/api/v1/phc"

def test_phc():
    print("Testing PHC API Endpoints...")
    
    # 1. Profile
    res = requests.get(f"{BASE_URL}/users/profile")
    assert res.status_code == 200, f"Profile failed: {res.text}"
    print("✅ GET /users/profile:", res.json()["full_name"])

    # 2. Health Profile
    res = requests.get(f"{BASE_URL}/users/health-profile")
    assert res.status_code == 200, f"Health profile failed: {res.text}"
    print("✅ GET /users/health-profile:", res.json()["occupation_risk"])

    # 3. Latest Vitals
    res = requests.get(f"{BASE_URL}/health/vitals/latest")
    assert res.status_code == 200, f"Latest vitals failed: {res.text}"
    print("✅ GET /health/vitals/latest: HR =", res.json()["heart_rate"])

    # 4. Sync Vitals
    payload = {
        "heart_rate": 78.0,
        "spo2": 98.5,
        "body_temp_c": 37.1,
        "systolic_bp": 120.0,
        "diastolic_bp": 80.0,
        "ambient_temp_c": 41.5,
        "humidity_pct": 64.0,
        "activity_level": "moderate"
    }
    res = requests.post(f"{BASE_URL}/health/vitals/sync", json=payload)
    assert res.status_code == 200, f"Sync vitals failed: {res.text}"
    print("✅ POST /health/vitals/sync: synced successfully, heat index =", res.json()["record"]["heat_index_c"])

    # 5. Risk Score
    res = requests.get(f"{BASE_URL}/health/risk-score")
    assert res.status_code == 200, f"Risk score failed: {res.text}"
    print("✅ GET /health/risk-score: Composite =", res.json()["composite_risk_score"])

    # 6. Hydration
    res = requests.post(f"{BASE_URL}/health/hydration/log", json={"amount_ml": 500, "beverage_type": "water"})
    assert res.status_code == 200, f"Hydration log failed: {res.text}"
    print("✅ POST /health/hydration/log: Today total ml =", res.json()["today_total_ml"])

    # 7. Anomalies
    res = requests.get(f"{BASE_URL}/anomalies")
    assert res.status_code == 200, f"Anomalies failed: {res.text}"
    print("✅ GET /anomalies: Total count =", len(res.json()))

    # 8. Edge AI Detect
    res = requests.post(f"{BASE_URL}/anomalies/detect", json={
        "heart_rate": 96.0,
        "spo2": 97.0,
        "body_temp_c": 37.4,
        "ambient_temp_c": 42.0,
        "humidity_pct": 65.0,
        "hydration_ml_today": 1200
    })
    assert res.status_code == 200, f"Edge AI detect failed: {res.text}"
    print("✅ POST /anomalies/detect: Latency =", res.json()["latency_ms"], "ms, Anomalies =", len(res.json()["anomalies_detected"]))

    # 9. Disaster Alerts
    res = requests.get(f"{BASE_URL}/alerts/disaster")
    assert res.status_code == 200, f"Disaster alerts failed: {res.text}"
    print("✅ GET /alerts/disaster: Count =", len(res.json()))

    # 10. SOS Trigger & Cancel
    res = requests.post(f"{BASE_URL}/emergency/sos/trigger", json={
        "latitude": 25.3176,
        "longitude": 82.9739,
        "address": "Assi Ghat, Varanasi",
        "trigger_type": "manual_button"
    })
    assert res.status_code == 200, f"SOS trigger failed: {res.text}"
    print("✅ POST /emergency/sos/trigger: Status =", res.json()["sos_state"]["status"])

    res = requests.post(f"{BASE_URL}/emergency/sos/cancel")
    assert res.status_code == 200, f"SOS cancel failed: {res.text}"
    print("✅ POST /emergency/sos/cancel: Status =", res.json()["sos_state"]["status"])

    # 11. Nearby Hospitals
    res = requests.get(f"{BASE_URL}/emergency/nearby-hospitals")
    assert res.status_code == 200, f"Hospitals failed: {res.text}"
    print("✅ GET /emergency/nearby-hospitals: Count =", len(res.json()))

    # 12. Medications & Mark Taken
    res = requests.get(f"{BASE_URL}/medications")
    assert res.status_code == 200, f"Medications failed: {res.text}"
    meds = res.json()
    print("✅ GET /medications: Count =", len(meds))
    if meds:
        m_id = meds[0]["id"]
        res = requests.post(f"{BASE_URL}/medications/{m_id}/log", json={"medication_id": m_id, "status": "taken"})
        assert res.status_code == 200
        print("✅ POST /medications/{id}/log: Marked as taken")

    # 13. Caregiver Dependents
    res = requests.get(f"{BASE_URL}/caregiver/dependents")
    assert res.status_code == 200, f"Caregiver dependents failed: {res.text}"
    print("✅ GET /caregiver/dependents: Count =", len(res.json()))

    # 14. Provider Patients
    res = requests.get(f"{BASE_URL}/provider/patients")
    assert res.status_code == 200, f"Provider patients failed: {res.text}"
    print("✅ GET /provider/patients: Count =", len(res.json()))

    # 15. Telemedicine Doctors
    res = requests.get(f"{BASE_URL}/telemedicine/doctors")
    assert res.status_code == 200, f"Doctors failed: {res.text}"
    print("✅ GET /telemedicine/doctors: Count =", len(res.json()))

    # 16. Health Records Vault
    res = requests.get(f"{BASE_URL}/records")
    assert res.status_code == 200, f"Records failed: {res.text}"
    print("✅ GET /records: Count =", len(res.json()))

    # 17. Schemes
    res = requests.get(f"{BASE_URL}/schemes/eligibility")
    assert res.status_code == 200, f"Schemes failed: {res.text}"
    print("✅ GET /schemes/eligibility: Eligible =", res.json()["user_eligible_pmjay"])

    # 18. Edge AI Status
    res = requests.get(f"{BASE_URL}/edge-ai/status")
    assert res.status_code == 200, f"Edge AI status failed: {res.text}"
    print("✅ GET /edge-ai/status: Framework =", res.json()["framework"])

    print("\n🎉 ALL 18 PHC BACKEND ENDPOINTS PASSED FLAWLESSLY!")

if __name__ == "__main__":
    test_phc()
