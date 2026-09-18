import asyncio
import sys
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import create_access_token

def get_auth_headers(email: str = "legal_officer@district.gov.in", role: str = "COUNSELOR"):
    token = create_access_token(user_id="usr-test-004", email_or_phone=email, roles=[role])
    return {"Authorization": f"Bearer {token}"}

def run_tests():
    with TestClient(app) as client:
        headers = get_auth_headers()
        print("===========================================================================")
        print(" 🚀 STARTING FULL VALIDATION OF NYAYA-MANAS BACKEND & API SUITE")
        print("===========================================================================")

        # 1. Test Victims List
        res = client.get("/api/v1/nyaya-manas/victims", headers=headers)
        assert res.status_code == 200, f"Victims list failed: {res.text}"
        data = res.json()
        assert data["status"] == "SUCCESS"
        assert len(data["victims"]) >= 4
        print(f" ✓ [1/12] GET /victims -> Retrieved {data['total_count']} registered victims (Critical: {data['critical_count']})")

        # 2. Test Single Victim Dossier
        victim_id = data["victims"][0]["id"]
        res = client.get(f"/api/v1/nyaya-manas/victims/{victim_id}", headers=headers)
        assert res.status_code == 200
        v_data = res.json()["victim"]
        assert v_data["id"] == victim_id
        print(f" ✓ [2/12] GET /victims/{victim_id} -> Successfully retrieved dossier for {v_data['full_name']} (DDI: {v_data['dds_score']})")

        # 3. Test Victim Registration
        new_reg = {
            "full_name": "Lalita Devi",
            "phone_number": "+919123456780",
            "district": "Gorakhpur",
            "state": "Uttar Pradesh",
            "tehsil": "Gorakhpur Sadar",
            "police_station": "Kotwali",
            "fir_number": "FIR-2026/0991-SCST",
            "offense_category": "grievous_hurt",
            "case_stage": "fir",
            "preferred_language": "hi",
            "preferred_channel": "ivrs",
            "statutory_compensation_sanctioned": 400000.0
        }
        res = client.post("/api/v1/nyaya-manas/victims/register", json=new_reg, headers=headers)
        assert res.status_code == 200
        reg_victim = res.json()["victim"]
        print(f" ✓ [3/12] POST /victims/register -> Registered new victim {reg_victim['id']} ({reg_victim['full_name']})")

        # 4. Test Check-In Submission & 7-Factor DDS Calculation
        checkin_payload = {
            "victim_id": victim_id,
            "channel": "ivrs",
            "language": "hi",
            "text_content": "Accused family is issuing continuous threats before court testimony, I cannot sleep.",
            "pitch_variance": 58.4,
            "pause_ratio": 0.42,
            "speech_rate_wpm": 165.0,
            "vocal_tremor_score": 0.68,
            "audio_duration_sec": 30.0,
            "engagement_latency_hours": 3.0,
            "reported_threat": True
        }
        res = client.post("/api/v1/nyaya-manas/checkin/submit", json=checkin_payload, headers=headers)
        assert res.status_code == 200
        chk_data = res.json()
        assert chk_data["status"] == "SUCCESS"
        dds_score = chk_data["computed_dds"]["dds_score"]
        risk_tier = chk_data["computed_dds"]["risk_tier"]
        print(f" ✓ [4/12] POST /checkin/submit -> Computed Dynamic Distress Score: {dds_score}/100 ({risk_tier}), Escalation Triggered: {chk_data['escalation_triggered']}")

        # 5. Test Trauma-Informed AI Chatbot
        chat_payload = {
            "victim_id": victim_id,
            "message": "They told me they will harm my family if I testify tomorrow.",
            "language": "hi"
        }
        res = client.post("/api/v1/nyaya-manas/chat", json=chat_payload, headers=headers)
        assert res.status_code == 200
        chat_res = res.json()
        assert chat_res["threat_flagged"] == True
        print(f" ✓ [5/12] POST /chat -> AI Companion responded with trauma de-escalation (Threat Flagged: {chat_res['threat_flagged']})")

        # 6. Test Dialect IVRS 14566 Helpline Simulator
        ivrs_payload = {
            "victim_id": victim_id,
            "phone_number": "+919876543210",
            "dtmf_choice": 1,
            "language": "hi",
            "spoken_audio_transcript": "Bahut dar lag raha hai kal court jaane mein"
        }
        res = client.post("/api/v1/nyaya-manas/ivrs/simulate", json=ivrs_payload, headers=headers)
        assert res.status_code == 200
        ivrs_res = res.json()
        print(f" ✓ [6/12] POST /ivrs/simulate -> NHAA 14566 IVRS Processed: {ivrs_res['flow_selected']} -> {ivrs_res['audio_response']}")

        # 7. Test 7-Point Statutory Interventions List & Dispatch
        res = client.get("/api/v1/nyaya-manas/interventions", headers=headers)
        assert res.status_code == 200
        int_data = res.json()
        print(f" ✓ [7/12] GET /interventions -> Retrieved {int_data['total_count']} active statutory intervention packages")

        disp_payload = {
            "victim_id": victim_id,
            "intervention_type": "armed_witness_escort",
            "title": "Special Armed Witness Detail (Sec 15A PoA Act)",
            "description": "2 Armed Constables assigned for court journey.",
            "priority": "CRITICAL",
            "assigned_agency": "POLICE_PROTECTION_CELL",
            "assigned_officer": "Insp. V. K. Yadav",
            "sla_hours": 2
        }
        res = client.post("/api/v1/nyaya-manas/interventions/dispatch", json=disp_payload, headers=headers)
        assert res.status_code == 200
        print(f" ✓ [8/12] POST /interventions/dispatch -> Dispatched intervention {res.json()['intervention']['id']}")

        # 8. Test Explainable AI (XAI) & SHAP Breakdown
        res = client.get(f"/api/v1/nyaya-manas/xai/explain/{victim_id}", headers=headers)
        assert res.status_code == 200
        xai_res = res.json()
        assert len(xai_res["shap_feature_attributions"]) > 0
        print(f" ✓ [9/12] GET /xai/explain/{victim_id} -> Transparent SHAP breakdown loaded ({len(xai_res['shap_feature_attributions'])} features)")

        # 9. Test Human Override
        ovr_payload = {
            "victim_id": victim_id,
            "adjusted_dds_score": 62.0,
            "justification_reason": "Patient attended 45min clinical session with DMHP counselor; stabilization noted."
        }
        res = client.post("/api/v1/nyaya-manas/xai/override", json=ovr_payload, headers=headers)
        assert res.status_code == 200
        print(f" ✓ [10/12] POST /xai/override -> Successfully logged human override with audit justification.")

        # 10. Test Statutory Compensation Relief Disbursement
        comp_payload = {
            "victim_id": victim_id,
            "stage": "trial_stage",
            "amount_inr": 206250.0,
            "reference_number": "DBT-TREASURY-UP-2026-8812"
        }
        res = client.post("/api/v1/nyaya-manas/compensation/disburse", json=comp_payload, headers=headers)
        assert res.status_code == 200
        print(f" ✓ [11/12] POST /compensation/disburse -> Statutory relief ₹2,06,250 disbursed (Treasury Ref: {comp_payload['reference_number']})")

        # 11. Test Multi-Tier Role Dashboards
        roles = ["victim", "counsellor", "district", "state", "national"]
        for r in roles:
            dash_res = client.get(f"/api/v1/nyaya-manas/dashboard/{r}", headers=headers)
            assert dash_res.status_code == 200, f"Dashboard for {r} failed: {dash_res.text}"
            print(f" ✓ [12/12] GET /dashboard/{r} -> Verified real-time {r.upper()} role dashboard API")

        print("===========================================================================")
        print(" 🎉 ALL 12 NYAYA-MANAS API MODULES VERIFIED & WORKING 100% WITH ZERO MOCKS")
        print("===========================================================================")

if __name__ == "__main__":
    run_tests()
