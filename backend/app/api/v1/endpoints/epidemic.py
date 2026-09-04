"""
Epidemic Intelligence & Heatmap Router
DBSCAN Spatial Clustering & Heat Stress Hotspot Mapping
"""
from fastapi import APIRouter, Body
from typing import List, Optional
from pydantic import BaseModel
from app.services.epidemic_clustering import run_dbscan_epidemic_clustering

router = APIRouter()

class GeoPoint(BaseModel):
    lat: float
    lng: float

class ClusteringRequest(BaseModel):
    coordinates: Optional[List[GeoPoint]] = []
    radius_km: float = 5.0
    min_cluster_samples: int = 3

@router.post("/clusters")
def compute_epidemic_clusters(req: ClusteringRequest = Body(...)):
    """
    Executes spatial DBSCAN clustering on symptom GPS reports.
    Identifies high-density outbreak clusters and localized epidemic spikes.
    """
    raw_coords = [[p.lat, p.lng] for p in req.coordinates] if req.coordinates else []
    return run_dbscan_epidemic_clustering(raw_coords, req.radius_km, req.min_cluster_samples)

@router.get("/heat-map")
def get_epidemic_heat_map_data():
    """Returns sample epidemic heat map cluster data for interactive mapping."""
    return run_dbscan_epidemic_clustering([], 5.0, 3)
