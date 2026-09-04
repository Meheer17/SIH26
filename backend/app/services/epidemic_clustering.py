"""
Epidemic Early Warning & Geo-Spatial DBSCAN Clustering Engine
Performs DBSCAN spatial-temporal clustering on health symptom GPS data.
Identifies disease hotspots, heat-stress zones, and potential disease outbreaks.
"""
import numpy as np
from sklearn.cluster import DBSCAN
from typing import List, Dict, Any

def run_dbscan_epidemic_clustering(
    coordinates: List[List[float]], # [[lat, lng], ...]
    eps_km: float = 5.0,            # 5 km radius neighborhood
    min_samples: int = 3            # min 3 cases to form an outbreak cluster
) -> Dict[str, Any]:
    """
    Runs DBSCAN clustering on geographical coordinate pairs (latitude, longitude).
    Converts Lat/Lng to radians for spherical Haversine metric distance computation.
    """
    if not coordinates or len(coordinates) == 0:
        # Generate simulated cluster dataset for demonstration
        np.random.seed(42)
        base_lat, base_lng = 28.6139, 77.2090 # New Delhi center
        
        # Cluster 1: Heat stress cluster
        c1 = np.random.randn(8, 2) * 0.015 + [base_lat, base_lng]
        # Cluster 2: Fever cluster
        c2 = np.random.randn(6, 2) * 0.012 + [base_lat + 0.08, base_lng - 0.05]
        # Outliers
        outliers = np.array([[base_lat + 0.2, base_lng + 0.2], [base_lat - 0.15, base_lng - 0.1]])
        
        coordinates = np.vstack([c1, c2, outliers]).tolist()

    coords_arr = np.array(coordinates)
    
    # Earth radius in KM
    kms_per_radian = 6371.0088
    epsilon = eps_km / kms_per_radian
    
    # Convert lat/lng to radians for haversine metric
    coords_rad = np.radians(coords_arr)
    
    db = DBSCAN(eps=epsilon, min_samples=min_samples, metric='haversine')
    db.fit(coords_rad)
    
    labels = db.labels_
    n_clusters = len(set(labels)) - (1 if -1 in labels else 0)
    n_outliers = list(labels).count(-1)

    clusters_output = []
    for cluster_id in range(n_clusters):
        cluster_mask = (labels == cluster_id)
        cluster_points = coords_arr[cluster_mask]
        
        center_lat = float(np.mean(cluster_points[:, 0]))
        center_lng = float(np.mean(cluster_points[:, 1]))
        case_count = int(len(cluster_points))
        
        risk = "HIGH" if case_count >= 6 else "MODERATE"
        
        clusters_output.append({
            "cluster_id": cluster_id + 1,
            "center_lat": round(center_lat, 5),
            "center_lng": round(center_lng, 5),
            "total_cases": case_count,
            "radius_km": eps_km,
            "risk_level": risk,
            "points": [[round(pt[0], 5), round(pt[1], 5)] for pt in cluster_points]
        })

    return {
        "status": "SUCCESS",
        "total_data_points": len(coordinates),
        "active_clusters_found": n_clusters,
        "isolated_outlier_cases": n_outliers,
        "clusters": clusters_output,
        "epidemic_threat_index": "HIGH_SURGE" if n_clusters >= 2 else ("MODERATE_SURGE" if n_clusters == 1 else "LOW")
    }
