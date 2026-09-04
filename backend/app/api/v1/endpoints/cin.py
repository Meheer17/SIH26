"""
Community Immunity Network (CIN) Router
BLE Mesh P2P Sync & Community Outbreak Intelligence
"""
from fastapi import APIRouter, HTTPException, Body
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from app.services.cin_engine import process_cin_mesh_payloads, generate_anonymous_node_id

router = APIRouter()

class MeshSyncPayload(BaseModel):
    device_mac_or_uuid: str
    symptoms: List[str]
    fever_celsius: Optional[float] = 36.5
    ambient_temp_celsius: Optional[float] = 32.0
    contacts_count: Optional[int] = 1

@router.post("/sync")
def sync_cin_mesh_data(payloads: List[MeshSyncPayload] = Body(...)):
    """
    Ingest peer-to-peer sync payloads from offline BLE devices.
    Returns processed cluster risk and community alert status.
    """
    records = [p.model_dump() for p in payloads]
    result = process_cin_mesh_payloads(records)
    return result

@router.get("/node-id/{raw_id}")
def get_anonymous_node_id(raw_id: str):
    """Generates zero-knowledge anonymized node ID for P2P mesh broadcasting."""
    anon_id = generate_anonymous_node_id(raw_id)
    return {"raw_id": raw_id, "anonymized_node_id": anon_id}

@router.get("/outbreaks")
def get_simulated_mesh_outbreaks():
    """Returns real-time mesh outbreak intelligence summary."""
    sample_records = [
        {"symptoms": ["fever", "heat exhaustion"], "fever_celsius": 38.5},
        {"symptoms": ["fever", "dry cough"], "fever_celsius": 38.8},
        {"symptoms": ["cough"], "fever_celsius": 37.0},
        {"symptoms": ["fever", "chills"], "fever_celsius": 39.1},
    ]
    return process_cin_mesh_payloads(sample_records)
