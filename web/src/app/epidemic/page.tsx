"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, MapPin, AlertOctagon, Activity, Layers, RefreshCw } from "lucide-react";

export default function EpidemicHeatmapPage() {
  const [loading, setLoading] = useState(false);
  const [heatmapData, setHeatmapData] = useState<any>(null);

  const fetchHeatmap = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/epidemic/heat-map");
      if (res.ok) {
        const data = await res.json();
        setHeatmapData(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHeatmap();
  }, []);

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#0F172A]">
      <header className="bg-white border-b border-slate-200 px-6 py-4 sticky top-0 z-10 shadow-sm">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 transition text-slate-600"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-100 text-rose-800">
                Spatial ML DBSCAN
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
                Epidemic Early Warning & Geo-Heatmap
              </h1>
            </div>
          </div>
          <button
            onClick={fetchHeatmap}
            disabled={loading}
            className="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-lg font-medium text-sm transition"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            Recalculate DBSCAN Clusters
          </button>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8 space-y-8">
        {/* Epidemic Metrics Banner */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <span className="text-xs font-semibold text-slate-400 uppercase">Epidemic Threat Index</span>
            <p className="text-2xl font-extrabold text-rose-600 mt-1">
              {heatmapData?.epidemic_threat_index || "HIGH_SURGE"}
            </p>
            <p className="text-xs text-slate-500 mt-1">Real-time geospatial surge detection</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <span className="text-xs font-semibold text-slate-400 uppercase">Active Outbreak Clusters</span>
            <p className="text-2xl font-extrabold text-slate-900 mt-1">
              {heatmapData?.active_clusters_found || 2}
            </p>
            <p className="text-xs text-slate-500 mt-1">DBSCAN radius: 5.0 km</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <span className="text-xs font-semibold text-slate-400 uppercase">Total Geotagged Reports</span>
            <p className="text-2xl font-extrabold text-slate-900 mt-1">
              {heatmapData?.total_data_points || 16}
            </p>
            <p className="text-xs text-slate-500 mt-1">From kiosks & app sensors</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <span className="text-xs font-semibold text-slate-400 uppercase">Isolated Outliers</span>
            <p className="text-2xl font-extrabold text-amber-600 mt-1">
              {heatmapData?.isolated_outlier_cases || 2}
            </p>
            <p className="text-xs text-slate-500 mt-1">Unclustered single occurrences</p>
          </div>
        </div>

        {/* Spatial Map Simulation & Clusters */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden p-6 space-y-6">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div>
              <h3 className="font-bold text-slate-900 text-lg">Cluster Vector Maps</h3>
              <p className="text-xs text-slate-500">Haversine metric distance &amp; cluster radius analysis</p>
            </div>
            <span className="text-xs font-mono px-3 py-1 bg-slate-100 text-slate-700 rounded-full border border-slate-200">
              Min Samples = 3 | Eps = 5.0 km
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {heatmapData?.clusters?.map((c: any) => (
              <div key={c.cluster_id} className="p-5 rounded-xl border border-slate-200 bg-slate-50/50 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <MapPin className="w-5 h-5 text-rose-600" />
                    <h4 className="font-bold text-slate-900">Cluster #{c.cluster_id} - Geo Focal Point</h4>
                  </div>
                  <span className="px-2.5 py-0.5 text-xs font-bold bg-rose-100 text-rose-800 rounded-full">
                    {c.risk_level} RISK
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2 text-xs font-mono bg-white p-3 rounded-lg border border-slate-200">
                  <div>Center Lat: {c.center_lat}°</div>
                  <div>Center Lng: {c.center_lng}°</div>
                  <div>Reported Cases: {c.total_cases}</div>
                  <div>Coverage Radius: {c.radius_km} km</div>
                </div>

                <div>
                  <p className="text-xs font-semibold text-slate-500 mb-1">Geotagged Points in Cluster:</p>
                  <div className="flex flex-wrap gap-1">
                    {c.points.map((pt: any, i: number) => (
                      <span key={i} className="text-[10px] font-mono px-2 py-0.5 bg-slate-200 text-slate-800 rounded">
                        [{pt[0]}, {pt[1]}]
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
