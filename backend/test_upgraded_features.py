#!/usr/bin/env python3
"""
SvasthyaSetu — Verification Suite for Upgraded & Fixed Features
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_upgraded_features():
    print("========================================================")
    print(" VERIFYING UPGRADED FEATURES & BUG FIXES")
    print("========================================================")

    # 1. Test Health Graph Bug Fix
    print("\n1. Testing Family Health Risk Graph Fix...")
    res = client.get("/api/v1/mind/family-health-graph/demo")
    assert res.status_code == 200, f"Failed demo: {res.text}"
    print("   ✓ GET /mind/family-health-graph/demo passed!")

    custom_tree = [
        {"id": "patient_1", "name": "Rohan", "relation": "self", "conditions": ["hypertension"], "parents": ["father_1"]},
        {"id": "father_1", "name": "Suresh", "relation": "father", "conditions": ["type2_diabetes"], "parents": []}
    ]
    res = client.post("/api/v1/mind/family-health-graph", json=custom_tree)
    assert res.status_code == 200, f"Failed custom payload: {res.text}"
    data = res.json()
    assert data["status"] == "SUCCESS"
    assert data["total_family_nodes"] == 2
    print("   ✓ POST /mind/family-health-graph passed with custom pedigree payload!")

    # 2. Test BitChat BitMesh Engine
    print("\n2. Testing BitChat-Inspired BitMesh P2P Engine...")
    bitmesh_payload = [
        {
            "device_mac_or_uuid": "device-test-99",
            "symptoms": ["fever", "cough"],
            "fever_celsius": 38.5,
            "ambient_temp_celsius": 33.0,
            "ttl": 7
        }
    ]
    res = client.post("/api/v1/cin/sync", json=bitmesh_payload)
    assert res.status_code == 200, f"Failed BitMesh sync: {res.text}"
    cin_data = res.json()
    assert cin_data["protocol"] == "BitChat-BitMesh P2P Gossip v2.6"
    assert "estimated_r0" in cin_data
    assert len(cin_data["bitmesh_relays"]) > 0
    print(f"   ✓ BitMesh P2P Gossip verified! Protocol: {cin_data['protocol']} | Swarm R0: {cin_data['estimated_r0']}")

    # 3. Test FedAvg Differential Privacy Aggregation
    print("\n3. Testing FedAvg Differential Privacy Engine...")
    fed_payload = {
        "client_node_id": "NODE-TEST-001",
        "model_name": "cough_classifier",
        "gradients_hash": "0xabc123def456",
        "local_samples_count": 40,
        "weights_vector": [0.44, -0.16, 0.90, 0.32, -0.06, 0.63, 0.20]
    }
    res = client.post("/api/v1/ai/federated/weights", json=fed_payload)
    assert res.status_code == 200, f"Failed FedAvg weights upload: {res.text}"
    fed_data = res.json()
    assert fed_data["status"] == "ACCEPTED"
    assert "aggregated_global_weights" in fed_data
    print(f"   ✓ FedAvg Weight Aggregation verified! Global Weights: {fed_data['aggregated_global_weights']}")

    # 4. Test RAKSHAK-MANAS HRMS Stress Engine
    print("\n4. Testing RAKSHAK-MANAS HRMS Stress Engine...")
    rakshak_payload = {
        'weekly_duty_hours': 72.0,
        'deployment_days': 120,
        'leave_gap_ratio': 0.90,
        'station_transfers_count': 4,
        'training_commitments_count': 5,
        'phq9_assessment_score': 18,
        'voice_journal_text': 'Extreme physical exhaustion and continuous night sentinel patrols in Siachen.'
    }
    res = client.post("/api/v1/apps/rakshak/hrms-stress", json=rakshak_payload)
    assert res.status_code == 200, f"Failed RAKSHAK HRMS stress test: {res.text}"
    rak_data = res.json()
    assert rak_data["status"] == "SUCCESS"
    assert "result" in rak_data
    result = rak_data["result"]
    assert "hrms_stress_index" in result or "burnout_score" in result or "stress_index" in result
    print(f"   ✓ RAKSHAK HRMS Stress Index verified! Status: {rak_data['status']} | Result: {result}")

    # 5. Test RAKSHAK-MANAS Commander Dashboard
    print("\n5. Testing RAKSHAK-MANAS Commander Dashboard...")
    res = client.get("/api/v1/apps/rakshak/commander-dashboard")
    assert res.status_code == 200, f"Failed Commander Dashboard test: {res.text}"
    cmd_data = res.json()
    assert "unit_id" in cmd_data
    assert "privacy_guarantee" in cmd_data
    print(f"   ✓ RAKSHAK Commander Dashboard verified! Unit: {cmd_data['unit_name']} | Guarantee: {cmd_data['privacy_guarantee']}")

    print("\n========================================================")
    print(" ALL UPGRADED FEATURES AND BUG FIXES VERIFIED 100%!")
    print("========================================================")

if __name__ == "__main__":
    test_upgraded_features()

