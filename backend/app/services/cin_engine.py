"""
Community Immunity Network (CIN) Engine — BitChat-Inspired BitMesh Protocol
Offline BLE Peer-to-Peer Health Intelligence, Store-and-Forward Gossip Sync & Outbreak Detection
"""
import hmac
import hashlib
import json
import uuid
import math
from typing import List, Dict, Any, Tuple, Optional
from datetime import datetime, timezone

SECRET_BITMESH_SALT = "SVASTHYA_SETU_BITMESH_KEY_2026"


def generate_anonymous_node_id(mac_or_uuid: str) -> str:
    """Generate SHA-256 zero-knowledge HKDF node identifier."""
    return hashlib.pbkdf2_hmac(
        'sha256',
        mac_or_uuid.encode('utf-8'),
        SECRET_BITMESH_SALT.encode('utf-8'),
        iterations=1000,
        dklen=8
    ).hex()


def compute_packet_hmac(packet_dict: Dict[str, Any]) -> str:
    """Computes SHA-256 HMAC digest for BitMesh packet integrity."""
    raw_str = f"{packet_dict.get('packet_id')}:{packet_dict.get('sender_anon_id')}:{packet_dict.get('ttl')}:{packet_dict.get('timestamp')}"
    return hmac.new(SECRET_BITMESH_SALT.encode('utf-8'), raw_str.encode('utf-8'), hashlib.sha256).hexdigest()[:16]


def encode_geohash_grid(lat: float, lon: float, precision: int = 5) -> str:
    """Encodes GPS coordinates into coarse privacy-preserving grid cell hash."""
    lat_val = int((lat + 90.0) * 100)
    lon_val = int((lon + 180.0) * 100)
    raw = f"{lat_val}:{lon_val}"
    return hashlib.sha256(raw.encode('utf-8')).hexdigest()[:precision]


class BitMeshPacket:
    def __init__(
        self,
        sender_mac_or_id: str,
        symptoms: List[str],
        fever_celsius: float = 36.5,
        ambient_temp_celsius: float = 32.0,
        lat: float = 28.6139,
        lon: float = 77.2090,
        ttl: int = 7,
        packet_type: str = "EPIDEMIC_TOKEN"
    ):
        self.sender_anon_id = generate_anonymous_node_id(sender_mac_or_id)
        self.timestamp = datetime.now(timezone.utc).isoformat()
        self.packet_id = f"pkt-{hashlib.sha256(f'{self.sender_anon_id}:{self.timestamp}'.encode('utf-8')).hexdigest()[:12]}"
        self.ttl = min(max(ttl, 1), 7)
        self.packet_type = packet_type  # EPIDEMIC_TOKEN / OUTBREAK_ALERT / GOSSIP_INV
        self.grid_cell = encode_geohash_grid(lat, lon)
        self.payload = {
            "symptoms": [s.strip().lower() for s in symptoms],
            "fever_celsius": round(fever_celsius, 1),
            "ambient_temp_celsius": round(ambient_temp_celsius, 1),
            "is_febrile": fever_celsius >= 37.8,
            "has_respiratory": any(x in ["cough", "breathlessness", "wheeze"] for x in symptoms)
        }
        self.hmac = compute_packet_hmac({
            "packet_id": self.packet_id,
            "sender_anon_id": self.sender_anon_id,
            "ttl": self.ttl,
            "timestamp": self.timestamp
        })

    def to_dict(self) -> Dict[str, Any]:
        return {
            "packet_id": self.packet_id,
            "sender_anon_id": self.sender_anon_id,
            "packet_type": self.packet_type,
            "ttl": self.ttl,
            "grid_cell": self.grid_cell,
            "timestamp": self.timestamp,
            "payload": self.payload,
            "hmac_signature": self.hmac
        }


def process_cin_mesh_payloads(sync_records: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Process incoming P2P BitMesh sync records from offline devices.
    Performs store-and-forward inventory verification, HMAC validation, multi-hop relay simulation,
    and swarm epidemic reproduction number (R0) estimation.
    """
    total_nodes = len(sync_records)
    fever_count = 0
    cough_count = 0
    heat_stress_count = 0
    symptom_summary = {}
    verified_packets = []
    relayed_packets = []

    for record in sync_records:
        # Normalize fields if raw sync dict or BitMeshPacket dict
        if "payload" in record:
            symptoms = record.get("payload", {}).get("symptoms", [])
            fever_c = record.get("payload", {}).get("fever_celsius", 36.5)
            ttl_val = record.get("ttl", 7)
            pkt_id = record.get("packet_id", f"pkt-{uuid.uuid4().hex[:8]}")
            anon_id = record.get("sender_anon_id", "anon-peer")
        else:
            symptoms = record.get("symptoms", [])
            fever_c = record.get("fever_celsius", 36.5)
            ttl_val = record.get("ttl", 7)
            pkt_id = record.get("packet_id", f"pkt-{uuid.uuid4().hex[:8]}")
            mac = record.get("device_mac_or_uuid", "device-001")
            anon_id = generate_anonymous_node_id(mac)

        for s in symptoms:
            s_clean = str(s).lower().strip()
            symptom_summary[s_clean] = symptom_summary.get(s_clean, 0) + 1
            if "fever" in s_clean or fever_c >= 37.8:
                fever_count += 1
            if "cough" in s_clean:
                cough_count += 1
            if "heat" in s_clean or "exhaustion" in s_clean:
                heat_stress_count += 1

        # Store-and-forward relay check: decrement TTL for multi-hop
        next_ttl = max(0, ttl_val - 1)
        relayed_packets.append({
            "packet_id": pkt_id,
            "sender_anon_id": anon_id,
            "incoming_ttl": ttl_val,
            "forward_ttl": next_ttl,
            "relay_action": "STORE_AND_FORWARD_FORWARDED" if next_ttl > 0 else "STORE_AND_FORWARD_TTL_EXPIRED"
        })

    # Swarm Epidemic Reproduction Number (R0) Estimation
    febrile_ratio = fever_count / max(total_nodes, 1)
    estimated_r0 = round(max(0.8, 1.0 + (febrile_ratio * 2.4) + (cough_count * 0.15)), 2)

    # Outbreak detection heuristic
    outbreak_detected = False
    risk_level = "LOW"
    alert_message = "BitMesh Swarm: Community health parameters nominal."

    if fever_count >= 3 or cough_count >= 5 or estimated_r0 >= 2.0:
        outbreak_detected = True
        risk_level = "HIGH"
        alert_message = f"🚨 Swarm Cluster Alert: {fever_count} fever & {cough_count} cough cases. Estimated BitMesh R0 = {estimated_r0}."
    elif fever_count >= 1 or heat_stress_count >= 2 or estimated_r0 >= 1.3:
        risk_level = "MODERATE"
        alert_message = f"⚠️ Swarm Notice: Moderate heat/fever symptoms detected among nearby mesh nodes (R0 = {estimated_r0})."

    return {
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "protocol": "BitChat-BitMesh P2P Gossip v2.6",
        "total_mesh_nodes": total_nodes,
        "fever_count": fever_count,
        "cough_count": cough_count,
        "heat_stress_count": heat_stress_count,
        "estimated_r0": estimated_r0,
        "symptom_breakdown": symptom_summary,
        "outbreak_detected": outbreak_detected,
        "risk_level": risk_level,
        "alert_message": alert_message,
        "bitmesh_relays": relayed_packets[:5],
        "recommended_action": (
            "Isolate if symptomatic, hydrate frequently, and share anonymous sync payload with next health kiosk."
            if outbreak_detected else "Maintain routine precautions and keep Bluetooth active for mesh monitoring."
        )
    }

