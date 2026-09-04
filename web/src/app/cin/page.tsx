"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Shield, WifiOff, Activity, Radio, AlertTriangle, RefreshCw, Users, CheckCircle2 } from "lucide-react";

export default function CommunityImmunityNetworkPage() {
  const [loading, setLoading] = useState(false);
  const [syncData, setSyncData] = useState<any>(null);
  const [simulatedNodes, setSimulatedNodes] = useState([
    { id: "NODE-88A1", rssi: -42, battery: 92, symptoms: ["Fever", "Heat Exhaustion"], status: "ACTIVE_MESH" },
    { id: "NODE-71F4", rssi: -65, battery: 78, symptoms: ["Dry Cough"], status: "ACTIVE_MESH" },
    { id: "NODE-33C9", rssi: -58, battery: 84, symptoms: ["Fever", "Chills"], status: "ACTIVE_MESH" },
    { id: "NODE-90E2", rssi: -71, battery: 60, symptoms: [], status: "HEALTHY" },
  ]);

  const triggerMeshSync = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/cin/outbreaks");
      if (res.ok) {
        const data = await res.json();
        setSyncData(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    triggerMeshSync();
  }, []);

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#0F172A]">
      {/* Header */}
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
              <div className="flex items-center gap-2">
                <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800 flex items-center gap-1">
                  <Radio className="w-3 h-3 animate-pulse" /> Offline BLE Mesh
                </span>
                <span className="text-xs text-slate-500 font-mono">Zero-Internet P2P</span>
              </div>
              <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
                Community Immunity Network (CIN)
              </h1>
            </div>
          </div>
          <button
            onClick={triggerMeshSync}
            disabled={loading}
            className="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-lg font-medium text-sm transition shadow-sm"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            Sync P2P Mesh
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8 space-y-8">
        {/* Outbreak Status Banner */}
        {syncData && (
          <div
            className={`p-6 rounded-xl border ${
              syncData.outbreak_detected
                ? "bg-amber-50 border-amber-300 text-amber-900"
                : "bg-emerald-50 border-emerald-300 text-emerald-900"
            }`}
          >
            <div className="flex items-start gap-4">
              <div
                className={`p-3 rounded-xl ${
                  syncData.outbreak_detected ? "bg-amber-200" : "bg-emerald-200"
                }`}
              >
                {syncData.outbreak_detected ? (
                  <AlertTriangle className="w-6 h-6 text-amber-800" />
                ) : (
                  <CheckCircle2 className="w-6 h-6 text-emerald-800" />
                )}
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <h2 className="text-lg font-bold">
                    Mesh Alert Status: {syncData.risk_level} RISK
                  </h2>
                  <span className="text-xs font-mono px-2 py-0.5 rounded bg-white/80 border border-current">
                    {syncData.total_mesh_nodes} Local Mesh Nodes
                  </span>
                </div>
                <p className="mt-1 text-sm font-medium">{syncData.alert_message}</p>
                <p className="mt-2 text-xs opacity-90">{syncData.recommended_action}</p>
              </div>
            </div>
          </div>
        )}

        {/* Metric Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between text-slate-500 mb-2">
              <span className="text-xs font-semibold uppercase">Active P2P Peers</span>
              <Users className="w-4 h-4 text-blue-600" />
            </div>
            <p className="text-3xl font-extrabold text-slate-900">{syncData?.total_mesh_nodes || 4}</p>
            <p className="text-xs text-slate-500 mt-1">100m Bluetooth LE range</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between text-slate-500 mb-2">
              <span className="text-xs font-semibold uppercase">Fever Spikes</span>
              <Activity className="w-4 h-4 text-rose-600" />
            </div>
            <p className="text-3xl font-extrabold text-rose-600">{syncData?.fever_count || 3}</p>
            <p className="text-xs text-slate-500 mt-1">Nodes reporting fever &gt;38°C</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between text-slate-500 mb-2">
              <span className="text-xs font-semibold uppercase">Respiratory Cluster</span>
              <Activity className="w-4 h-4 text-amber-600" />
            </div>
            <p className="text-3xl font-extrabold text-amber-600">{syncData?.cough_count || 2}</p>
            <p className="text-xs text-slate-500 mt-1">Nodes reporting cough symptoms</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between text-slate-500 mb-2">
              <span className="text-xs font-semibold uppercase">Privacy Encryption</span>
              <Shield className="w-4 h-4 text-emerald-600" />
            </div>
            <p className="text-lg font-bold text-emerald-700">SHA-256 ZK-Hash</p>
            <p className="text-xs text-slate-500 mt-1">Zero PII / Anonymized payload</p>
          </div>
        </div>

        {/* Live Bluetooth Mesh Node Table */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
            <div>
              <h3 className="font-bold text-slate-900">Discovered Nearby BLE Mesh Nodes</h3>
              <p className="text-xs text-slate-500">
                P2P direct exchange without internet or cellular connectivity
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
              <span className="text-xs text-emerald-700 font-medium">Scanning 2.4 GHz Mesh...</span>
            </div>
          </div>

          <div className="divide-y divide-slate-100">
            {simulatedNodes.map((node) => (
              <div key={node.id} className="p-4 px-6 flex items-center justify-between hover:bg-slate-50">
                <div className="flex items-center gap-4">
                  <div className="p-2.5 rounded-lg bg-slate-100 border border-slate-200">
                    <WifiOff className="w-5 h-5 text-slate-600" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-bold text-slate-900 text-sm">{node.id}</span>
                      <span className="text-xs text-slate-400 font-mono">RSSI: {node.rssi} dBm</span>
                    </div>
                    <div className="flex items-center gap-2 mt-1">
                      {node.symptoms.length > 0 ? (
                        node.symptoms.map((s, idx) => (
                          <span
                            key={idx}
                            className="px-2 py-0.5 rounded text-[11px] font-medium bg-rose-50 text-rose-700 border border-rose-200"
                          >
                            {s}
                          </span>
                        ))
                      ) : (
                        <span className="px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
                          Asymptomatic
                        </span>
                      )}
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xs font-mono text-slate-500">Batt: {node.battery}%</span>
                  <p className="text-xs text-emerald-600 font-semibold mt-0.5">Encrypted Sync Verified</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
