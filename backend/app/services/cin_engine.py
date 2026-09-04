"""
Community Immunity Network (CIN) Engine
Offline BLE Peer-to-Peer Health Intelligence and Anonymized Outbreak Detection
"""
import hashlib
from typing import List, Dict, Any
from datetime import datetime, timezone

def generate_anonymous_node_id(mac_or_uuid: str) -> str:
    """Generate SHA-256 zero-knowledge node identifier."""
    salt = "SVASTHYA_SETU_CIN_SALT_2026"
    return hashlib.sha256(f"{mac_or_uuid}:{salt}".encode('utf-8')).hexdigest()[:16]

def process_cin_mesh_payloads(sync_records: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Process incoming P2P mesh sync records from offline devices.
    Aggregates anonymized symptom counts, fever spikes, and local contact counts.
    """
    total_nodes = len(sync_records)
    fever_count = 0
    cough_count = 0
    heat_stress_count = 0
    symptom_summary = {}

    for record in sync_records:
        symptoms = record.get("symptoms", [])
        for s in symptoms:
            s_clean = s.lower().strip()
            symptom_summary[s_clean] = symptom_summary.get(s_clean, 0) + 1
            if "fever" in s_clean:
                fever_count += 1
            if "cough" in s_clean:
                cough_count += 1
            if "heat" in s_clean or "exhaustion" in s_clean:
                heat_stress_count += 1

    # Outbreak detection heuristic
    outbreak_detected = False
    risk_level = "LOW"
    alert_message = "Community health parameters normal."

    if fever_count >= 3 or cough_count >= 5:
        outbreak_detected = True
        risk_level = "HIGH"
        alert_message = f"Cluster Alert: {fever_count} fever and {cough_count} cough cases reported in mesh range."
    elif fever_count >= 1 or heat_stress_count >= 2:
        risk_level = "MODERATE"
        alert_message = f"Notice: High ambient heat/fever symptoms detected among nearby mesh nodes."

    return {
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "total_mesh_nodes": total_nodes,
        "fever_count": fever_count,
        "cough_count": cough_count,
        "heat_stress_count": heat_stress_count,
        "symptom_breakdown": symptom_summary,
        "outbreak_detected": outbreak_detected,
        "risk_level": risk_level,
        "alert_message": alert_message,
        "recommended_action": (
            "Isolate if symptomatic, hydrate frequently, and share anonymous sync payload with next health kiosk."
            if outbreak_detected else "Maintain routine precautions and keep Bluetooth active for mesh monitoring."
        )
    }
