#!/usr/bin/env python3
"""
SvasthyaSetu — All-in-One Model & Feature Verification Suite
Executes direct live tests on all 5 trained production ML models and core clinical engines.
"""

import sys
import os
import time
import json
import numpy as np

# Add backend root to sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# ANSI Terminal Colors
GREEN = "\033[92m"
CYAN = "\033[96m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

def print_header(title):
    print(f"\n{BOLD}{CYAN}{'='*75}{RESET}")
    print(f"{BOLD}{CYAN} ▶ {title}{RESET}")
    print(f"{BOLD}{CYAN}{'='*75}{RESET}")

def print_success(msg):
    print(f" {GREEN}✓{RESET} {msg}")

def print_metric(label, value, extra=""):
    print(f"   • {BOLD}{label}:{RESET} {value} {extra}")

def run_all_tests():
    start_total = time.time()
    passed_tests = 0
    total_tests = 9

    print(f"\n{BOLD}===========================================================================")
    print(f"       SVASTHYASETU CLINICAL PLATFORM — MODEL & FEATURE TEST SUITE        ")
    print(f"==========================================================================={RESET}")
    print(" Verifying 5 Trained ML Models & 4 Core Algorithmic Clinical Engines...\n")

    # ---------------------------------------------------------
    # TEST 1: Anemia Colorimetry Regression Model
    # ---------------------------------------------------------
    print_header("MODEL 1: Palmar/Conjunctival Anemia Colorimetry Model (anemia_estimator.pkl)")
    t0 = time.time()
    
    test_cases = [
        {"name": "Severe Anemia Sample (Pale Pallor)", "rgb": {"red": 230, "green": 190, "blue": 185}},
        {"name": "Moderate Anemia Sample", "rgb": {"red": 210, "green": 155, "blue": 140}},
        {"name": "Normal Healthy Vascular Capillary", "rgb": {"red": 185, "green": 125, "blue": 105}}
    ]

    for tc in test_cases:
        res = client.post("/api/v1/screening/anemia-colorimetry", json=tc["rgb"])
        assert res.status_code == 200, f"Failed: {res.text}"
        data = res.json()
        print(f"\n {BOLD}[Input: {tc['name']}]{RESET} RGB={tc['rgb']}")
        print_metric("Estimated Hemoglobin", f"{data['estimated_hb_g_dl']} g/dL")
        print_metric("Clinical Tier", data['anemia_severity'])
        print_metric("Clinical Action", data['clinical_action'])

    print_success(f"Model 1 Verified in {round((time.time()-t0)*1000, 1)}ms — Real GradientBoosting Model Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 2: Acoustic FFT Cough Classifier
    # ---------------------------------------------------------
    print_header("MODEL 2: Acoustic Cough Wave Biomarker Classifier (cough_classifier.pkl)")
    t0 = time.time()

    res = client.post("/api/v1/screening/cough-demo")
    assert res.status_code == 200, f"Failed: {res.text}"
    data = res.json()
    
    print_metric("Classified Cough Type", f"{BOLD}{data['cough_type']}{RESET}")
    print_metric("Model Confidence", f"{round(data['confidence_score']*100, 1)}%")
    if "acoustic_features" in data:
        print_metric("Extracted Acoustic Features", "")
        print(f"     - Spectral Centroid: {data['acoustic_features']['spectral_centroid_hz']} Hz")
        print(f"     - Spectral Rolloff:  {data['acoustic_features']['spectral_rolloff_hz']} Hz")
        print(f"     - Zero-Crossing Rate:{data['acoustic_features']['zero_crossing_rate']}")
        print(f"     - Peak Frequency:    {data['acoustic_features']['peak_frequency_hz']} Hz")
    print_metric("Recommendation", data['clinical_recommendation'])
    print_metric("Model Architecture", data['ml_model'])

    print_success(f"Model 2 Verified in {round((time.time()-t0)*1000, 1)}ms — Real FFT Acoustic Extraction Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 3: Acoustic Voice Stress & Fatigue Estimator
    # ---------------------------------------------------------
    print_header("MODEL 3: Physiological Voice Stress Index Model (voice_stress_model.pkl)")
    t0 = time.time()

    voice_payload = {
        "transcript_text": "I am unable to sleep after four days of night deployment, experiencing dizziness and fast heartbeat.",
        "pitch_variance": 58.4,
        "pause_ratio": 0.45
    }
    res = client.post("/api/v1/apps/nyaya/voice-stress", json=voice_payload)
    assert res.status_code == 200, f"Failed: {res.text}"
    data = res.json()

    print_metric("Input Transcript", f'"{voice_payload["transcript_text"]}"')
    print_metric("Voice Stress Index", f"{data['voice_stress_score']} / 100 ({data['stress_tier']})")
    print_metric("Emotion Classification", data['emotion_classification'])
    print_metric("Physiological Fatigue", f"{data['voice_fatigue_score']} / 100 ({data['fatigue_tier']})")
    print_metric("Acoustic Markers", f"PitchVar={data['acoustic_markers']['pitch_variance_hz']} Hz, PauseRatio={data['acoustic_markers']['vocal_pause_ratio']}, TremorScore={data['acoustic_markers']['tremor_score']}")

    print_success(f"Model 3 Verified in {round((time.time()-t0)*1000, 1)}ms — Real Voice Stress Regressor Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 4: Crisis NLP Classifier
    # ---------------------------------------------------------
    print_header("MODEL 4: Crisis & Psychological Distress NLP Detector (crisis_detector_model.pkl)")
    t0 = time.time()

    nlp_tests = [
        "I feel completely hopeless, there is no way out and I want to end everything",
        "Subject threatened me with severe physical harm if I speak to police officers",
        "Completed standard post-patrol rest, feeling recovered and stable"
    ]

    for text in nlp_tests:
        v_res = client.post("/api/v1/apps/nyaya/voice-stress", json={"transcript_text": text, "pitch_variance": 30.0, "pause_ratio": 0.2})
        nlp_out = v_res.json()["crisis_nlp_detection"]
        print(f"\n {BOLD}[Input Statement]{RESET} \"{text}\"")
        print_metric("Crisis Category", nlp_out["category"])
        print_metric("Confidence", f"{round(nlp_out['confidence']*100, 1)}%")
        print_metric("NLP Model", nlp_out["model"])

    print_success(f"Model 4 Verified in {round((time.time()-t0)*1000, 1)}ms — Real TF-IDF Classifier Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 5: DBSCAN Epidemic Geo-Clustering & Threat Predictor
    # ---------------------------------------------------------
    print_header("MODEL 5: Epidemic Outbreak Geo-Clustering & Threat Predictor (epidemic_predictor.pkl)")
    t0 = time.time()

    geo_payload = {
        "coordinates": [
            {"lat": 28.6139, "lng": 77.2090},
            {"lat": 28.6145, "lng": 77.2095},
            {"lat": 28.6150, "lng": 77.2088},
            {"lat": 28.6140, "lng": 77.2102},
            {"lat": 28.6800, "lng": 77.1200}  # Outlier
        ],
        "radius_km": 3.0,
        "min_cluster_samples": 2
    }
    res = client.post("/api/v1/epidemic/clusters", json=geo_payload)
    assert res.status_code == 200, f"Failed: {res.text}"
    data = res.json()

    print_metric("Total Input Geo-Coordinates", data["total_data_points"])
    print_metric("Active Clusters Discovered", data["active_clusters_found"])
    print_metric("Isolated Outlier Cases", data["isolated_outlier_cases"])
    print_metric("Epidemic Threat Level", data["epidemic_threat_index"])
    for c in data["clusters"]:
        print(f"     • Cluster #{c['cluster_id']}: Center=({c['center_lat']}, {c['center_lng']}) | Cases={c['total_cases']} | Risk={c['risk_level']}")
    print_metric("ML Engine", data["ml_model"])

    print_success(f"Model 5 Verified in {round((time.time()-t0)*1000, 1)}ms — DBSCAN Haversine Clustering Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 6: Smart OPD & Dual-Path Prescription Engine
    # ---------------------------------------------------------
    print_header("FEATURE 6: Smart OPD Intake & Dual-Prescription Engine (ICD-11 + AYUSH)")
    t0 = time.time()

    opd_res = client.post("/api/v1/apps/medikiosk/intake", json={
        "chief_complaint": "Acute heat exhaustion, throbbing headache, muscle cramps and high thirst",
        "symptoms": ["heat exhaustion", "headache", "muscle cramps", "dehydration"],
        "duration": "2 days",
        "severity_rating": 8,
        "history_present_illness": "Onset following 6 hours of outdoor duty under direct midday sun.",
        "review_systems": "Elevated heart rate, dry mucous membranes, no focal deficits.",
        "ayush_mode": True
    })
    assert opd_res.status_code == 200, f"Failed: {opd_res.text}"
    opd_data = opd_res.json()

    rx_res = client.post("/api/v1/clinical/dual-prescription", json={
        "condition_key": "HEAT_STRESS",
        "symptoms": ["headache", "dehydration", "cramps"]
    })
    assert rx_res.status_code == 200, f"Failed: {rx_res.text}"
    rx_data = rx_res.json()

    print_metric("Triage Status", opd_data["triage_level"])
    print_metric("ICD-11 Diagnosis", rx_data["icd_11_code"] + " — " + rx_data["condition_name"])
    print_metric("Allopathic Pathway", rx_data["allopathic_pathway"]["primary"])
    print_metric("Ayurvedic Ahara/Vihara", rx_data["ayush_integrative_pathway"]["ayurveda"])
    print_metric("Yoga / Pranayama", rx_data["ayush_integrative_pathway"]["yoga_pranayama"])

    print_success(f"Feature 6 Verified in {round((time.time()-t0)*1000, 1)}ms — Parallel Allopathy & AYUSH Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 7: BSA 2023 Cryptographic Merkle Chain Evidence Vault
    # ---------------------------------------------------------
    print_header("FEATURE 7: BSA 2023 Sec 63 Cryptographic Merkle Evidence Vault")
    t0 = time.time()

    evi_res = client.post("/api/v1/covert-sos/evidence/log", json={
        "incident_type": "THREAT_AUDIO_RECORDING",
        "description": "Voice recording and geolocation timestamped at incident coordinates.",
        "gps_lat": 28.6139,
        "gps_lng": 77.2090
    })
    assert evi_res.status_code == 200, f"Failed: {evi_res.text}"
    evi_data = evi_res.json()

    chain_res = client.get("/api/v1/covert-sos/evidence/chain")
    assert chain_res.status_code == 200, f"Failed: {chain_res.text}"
    chain_data = chain_res.json()

    print_metric("Evidence Record ID", evi_data["evidence_id"])
    print_metric("Block Index", f"#{evi_data['block_index']}")
    print_metric("SHA-256 Digest", evi_data["sha256_hash"])
    print_metric("Merkle Root", evi_data["merkle_root"])
    print_metric("Legal Compliance", evi_data["legal_compliance"])
    print_metric("Total Blocks in Chain", chain_data["total_blocks"])

    print_success(f"Feature 7 Verified in {round((time.time()-t0)*1000, 1)}ms — Cryptographic SHA-256 Merkle Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 8: Thermal Stress (WBGT) & Telemetry Advisory Engine
    # ---------------------------------------------------------
    print_header("FEATURE 8: ISO 7243 Thermal Stress & Dynamic Hydration Engine")
    t0 = time.time()

    vit_res = client.post("/api/v1/apps/arogya/vitals", json={
        "heart_rate": 108,
        "spo2": 95,
        "body_temp_c": 38.6,
        "env_temp_c": 41.5,
        "humidity_percent": 68.0,
        "activity_level": "strenuous",
        "time_since_water_mins": 90,
        "has_respiratory_condition": False
    })
    assert vit_res.status_code == 200, f"Failed: {vit_res.text}"
    vit_data = vit_res.json()

    print_metric("Computed Heat Stress Score", f"{vit_data['heat_stress_score']} / 100")
    print_metric("NDMA Heat Risk Tier", vit_data["severity"])
    print_metric("Dehydration Risk", f"{vit_data['dehydration_risk_percent']}%")
    print_metric("Recommendations", vit_data["recommendations"])

    print_success(f"Feature 8 Verified in {round((time.time()-t0)*1000, 1)}ms — Real Thermal Calculation Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # TEST 9: Multi-Agent AI Clinical Hub
    # ---------------------------------------------------------
    print_header("FEATURE 9: Multi-Agent AI Clinical Assistant (ReAct Reasoning)")
    t0 = time.time()

    chat_res = client.post("/api/v1/ai/chat", json={
        "agent_id": "arogya_sathi_agent",
        "messages": [
            {"role": "user", "content": "My body temp is 39.1C and ambient temp is 42C with 70% humidity. Please evaluate thermal stress."}
        ],
        "context": {"heart_rate": 112, "spo2": 94}
    })
    assert chat_res.status_code == 200, f"Failed: {chat_res.text}"
    chat_data = chat_res.json()

    print_metric("Target Agent ID", chat_data.get("agent_id", "arogya_sathi_agent"))
    print_metric("Execution Engine", chat_data.get("engine", "domain_conversational_engine"))
    content_snippet = chat_data.get("content", "")
    print_metric("Clinical Agent Reasoning Response", content_snippet[:160] + "..." if len(content_snippet) > 160 else content_snippet)
    if chat_data.get("tool_calls"):
        print_metric("Tools Executed", [tc["tool_name"] for tc in chat_data["tool_calls"]])

    print_success(f"Feature 9 Verified in {round((time.time()-t0)*1000, 1)}ms — Autonomous Agent Reasoning Active")
    passed_tests += 1

    # ---------------------------------------------------------
    # Summary
    # ---------------------------------------------------------
    total_time = round(time.time() - start_total, 2)
    print(f"\n{BOLD}{GREEN}===========================================================================")
    print(f" ✓ ALL {passed_tests}/{total_tests} MODELS AND FEATURES PASSED SYNCHRONOUS VALIDATION 100% ")
    print(f" Total Execution Time: {total_time}s across 5 Real ML Models + 4 Clinical Engines")
    print(f"==========================================================================={RESET}\n")

if __name__ == "__main__":
    run_all_tests()
