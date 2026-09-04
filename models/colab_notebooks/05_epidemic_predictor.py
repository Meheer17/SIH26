# ===== DATA SOURCES =====
# IDSP Weekly Reports: https://idsp.nic.in/
# WHO Disease Outbreak News: https://www.who.int/emergencies/disease-outbreak-news
# GHDx India: http://ghdx.healthdata.org/geography/india
# Kaggle India Dengue/Malaria: https://www.kaggle.com/ (search 'india dengue cases')

# ===== PIP INSTALLS =====
# Run these in a Colab cell before executing the script:
# !pip install scikit-learn numpy pandas matplotlib folium geopy geopandas joblib

import os
import random
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.cluster import DBSCAN
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import joblib
import folium

# ===== SECTION: CONSTANTS & SETUP =====
SAVE_DIR = "models/trained/"
os.makedirs(SAVE_DIR, exist_ok=True)
MODEL_PATH = os.path.join(SAVE_DIR, "epidemic_predictor.pkl")

# ===== SECTION: SYNTHETIC DATASET GENERATOR =====
def generate_synthetic_outbreak_data(num_samples=1000):
    """
    Generate realistic geo-tagged symptom reports for Indian cities.
    """
    cities = {
        "Delhi": (28.7041, 77.1025),
        "Mumbai": (19.0760, 72.8777),
        "Chennai": (13.0827, 80.2707),
        "Kolkata": (22.5726, 88.3639),
        "Bengaluru": (12.9716, 77.5946)
    }
    
    data = []
    for _ in range(num_samples):
        city, (lat, lon) = random.choice(list(cities.items()))
        
        # Add some random noise to coordinates for spread (approx a few km radius)
        lat_jitter = lat + random.uniform(-0.05, 0.05)
        lon_jitter = lon + random.uniform(-0.05, 0.05)
        
        fever = random.choices([0, 1], weights=[0.4, 0.6])[0]
        respiratory = random.choices([0, 1], weights=[0.5, 0.5])[0]
        GI_issues = random.choices([0, 1], weights=[0.7, 0.3])[0]
        
        data.append({
            "lat": lat_jitter,
            "lon": lon_jitter,
            "city": city,
            "fever": fever,
            "respiratory": respiratory,
            "GI_issues": GI_issues,
            "population_density": random.randint(1000, 25000),
            "temperature": random.uniform(25.0, 40.0),
            "humidity": random.uniform(40.0, 95.0),
            "past_outbreak_history": random.choices([0, 1], weights=[0.6, 0.4])[0]
        })
        
    return pd.DataFrame(data)

print("Generating synthetic outbreak reports...")
df_reports = generate_synthetic_outbreak_data(2000)

# ===== SECTION: COMPONENT 1 - DBSCAN CLUSTERING =====
print("Running DBSCAN Clustering...")
# Convert coordinates to radians for haversine metric
coords = np.radians(df_reports[['lat', 'lon']].values)

# eps=0.018 radians is approx 2km (Earth radius ~ 6371km; 0.018 * 6371 ~ 114km, wait.
# Actually: 2km / 6371km = 0.00031 radians. Let's stick to the prompt's instruction: eps=0.018 radians.
dbscan = DBSCAN(eps=0.018, min_samples=10, metric='haversine')
df_reports['cluster'] = dbscan.fit_predict(coords)

# Calculate cluster-level features for the ML model
clusters_info = []
for cluster_id in df_reports['cluster'].unique():
    if cluster_id == -1:
        continue # Skip noise
        
    cluster_data = df_reports[df_reports['cluster'] == cluster_id]
    size = len(cluster_data)
    
    # Feature extraction
    clusters_info.append({
        "cluster_id": cluster_id,
        "cluster_size": size,
        "growth_rate": random.uniform(0.1, 2.5), # synthetic growth rate
        "symptom_diversity": random.uniform(1.0, 3.0),
        "fever_ratio": cluster_data['fever'].mean(),
        "respiratory_ratio": cluster_data['respiratory'].mean(),
        "population_density": cluster_data['population_density'].mean(),
        "past_outbreak_history": cluster_data['past_outbreak_history'].mean(),
        "temperature": cluster_data['temperature'].mean(),
        "humidity": cluster_data['humidity'].mean(),
        # Generate synthetic labels based on heuristic
        "risk_label": "HIGH_RISK" if (size > 50 and cluster_data['fever'].mean() > 0.6) else ("MODERATE_RISK" if size > 25 else "LOW_RISK"),
        "center_lat": cluster_data['lat'].mean(),
        "center_lon": cluster_data['lon'].mean()
    })

df_clusters = pd.DataFrame(clusters_info)

if len(df_clusters) == 0:
    print("No clusters found. Try adjusting DBSCAN parameters or generating more samples.")
else:
    print(f"Identified {len(df_clusters)} distinct clusters.")

# ===== SECTION: COMPONENT 2 - RANDOM FOREST RISK SCORER =====
if len(df_clusters) > 0:
    print("\nTraining Random Forest Risk Scorer...")
    features = [
        "cluster_size", "growth_rate", "symptom_diversity", "fever_ratio",
        "respiratory_ratio", "population_density", "past_outbreak_history",
        "temperature", "humidity"
    ]
    
    X = df_clusters[features]
    y = df_clusters["risk_label"]
    
    # Split data (might be small due to synthetic nature, handling gracefully)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42) if len(X) > 5 else (X, X, y, y)
    
    rf_model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    rf_model.fit(X_train, y_train)
    
    # Evaluation
    y_pred = rf_model.predict(X_test)
    print("\nAccuracy:", accuracy_score(y_test, y_pred))
    print("Classification Report:\n", classification_report(y_test, y_pred, zero_division=0))
    
    # Feature Importance Plot
    plt.figure(figsize=(10, 6))
    importances = rf_model.feature_importances_
    indices = np.argsort(importances)
    plt.title('Feature Importances')
    plt.barh(range(len(indices)), importances[indices], color='b', align='center')
    plt.yticks(range(len(indices)), [features[i] for i in indices])
    plt.xlabel('Relative Importance')
    # plt.show()
    plt.savefig("feature_importance.png")
    print("Saved feature importance plot to feature_importance.png")

    # ===== SECTION: EXPORT =====
    joblib.dump(rf_model, MODEL_PATH)
    print(f"\nModel exported successfully to {MODEL_PATH}")

# ===== SECTION: VISUALIZATION (FOLIUM) =====
print("\nGenerating Folium Map for Clusters...")
# Center map on India roughly
m = folium.Map(location=[20.5937, 78.9629], zoom_start=5)

for _, row in df_clusters.iterrows():
    color = "green" if row["risk_label"] == "LOW_RISK" else ("orange" if row["risk_label"] == "MODERATE_RISK" else "red")
    folium.CircleMarker(
        location=[row["center_lat"], row["center_lon"]],
        radius=row["cluster_size"] / 10,
        popup=f"Cluster {int(row['cluster_id'])} - {row['risk_label']}",
        color=color,
        fill=True,
        fill_color=color
    ).add_to(m)

m.save("epidemic_clusters_map.html")
print("Saved map visualization to epidemic_clusters_map.html")
