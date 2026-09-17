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

# In-memory P2P BLE mesh node store
ACTIVE_BLE_NODES_STORE: List[Dict[str, Any]] = [
    {"device_mac_or_uuid": "BLE-Node-Alpha-8088", "symptoms": ["Fever", "Heat Exhaustion"], "fever_celsius": 38.5, "battery": 92, "ttl": 7},
    {"device_mac_or_uuid": "BLE-Node-Beta-71f4", "symptoms": ["Dry Cough"], "fever_celsius": 37.2, "battery": 78, "ttl": 6},
    {"device_mac_or_uuid": "BLE-Node-Gamma-33c9", "symptoms": ["Fever", "Chills"], "fever_celsius": 38.9, "battery": 84, "ttl": 5},
    {"device_mac_or_uuid": "BLE-Node-Delta-90e2", "symptoms": ["Asymptomatic"], "fever_celsius": 36.8, "battery": 95, "ttl": 7},
]

@router.post("/broadcast")
def broadcast_mesh_node(payload: MeshSyncPayload = Body(...)):
    """Broadcasts a new BLE node epidemic token into the local mesh swarm."""
    node_data = payload.model_dump()
    node_data["battery"] = 90
    node_data["ttl"] = 7
    node_data["anonymized_node_id"] = generate_anonymous_node_id(node_data["device_mac_or_uuid"])
    
    # Store in memory swarm
    ACTIVE_BLE_NODES_STORE.insert(0, node_data)
    if len(ACTIVE_BLE_NODES_STORE) > 20:
        ACTIVE_BLE_NODES_STORE.pop()

    processed = process_cin_mesh_payloads(ACTIVE_BLE_NODES_STORE)
    return {
        "status": "BROADCAST_ACCEPTED",
        "broadcast_node_id": node_data["anonymized_node_id"],
        "total_active_mesh_nodes": len(ACTIVE_BLE_NODES_STORE),
        "mesh_outbreak_status": processed
    }

@router.get("/nodes")
def get_active_mesh_nodes():
    """Returns list of active BLE peer nodes discovered in the swarm mesh."""
    return {
        "active_mesh_nodes_count": len(ACTIVE_BLE_NODES_STORE),
        "nodes": ACTIVE_BLE_NODES_STORE
    }

@router.post("/sync")
def sync_cin_mesh_data(payloads: List[MeshSyncPayload] = Body(...)):
    """
    Ingest peer-to-peer sync payloads from offline BLE devices.
    Returns processed cluster risk and community alert status.
    """
    records = [p.model_dump() for p in payloads]
    for r in records:
        ACTIVE_BLE_NODES_STORE.append(r)
    result = process_cin_mesh_payloads(ACTIVE_BLE_NODES_STORE)
    return result

@router.get("/node-id/{raw_id}")
def get_anonymous_node_id(raw_id: str):
    """Generates zero-knowledge anonymized node ID for P2P mesh broadcasting."""
    anon_id = generate_anonymous_node_id(raw_id)
    return {"raw_id": raw_id, "anonymized_node_id": anon_id}

@router.get("/outbreaks")
def get_simulated_mesh_outbreaks():
    """Returns real-time mesh outbreak intelligence summary."""
    return process_cin_mesh_payloads(ACTIVE_BLE_NODES_STORE)

