"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Shield, WifiOff, Activity, Radio, AlertTriangle, RefreshCw, Users, CheckCircle2, Send, Cpu, Database } from "lucide-react";

export default function CommunityImmunityNetworkPage() {
  const [loading, setLoading] = useState(false);
  const [syncData, setSyncData] = useState<any>(null);
  const [symptomInput, setSymptomInput] = useState("fever, dry cough");
  const [tempInput, setTempInput] = useState(38.2);

  const [simulatedNodes, setSimulatedNodes] = useState([
    { id: "8088e6406e2a1132", ttl: 7, rssi: -42, battery: 92, symptoms: ["Fever", "Heat Exhaustion"], packet_type: "EPIDEMIC_TOKEN", hmac: "3f8b9a2c1d0e" },
    { id: "71f49b1a09c488e1", ttl: 6, rssi: -65, battery: 78, symptoms: ["Dry Cough"], packet_type: "EPIDEMIC_TOKEN", hmac: "7a1e4c9f0b2d" },
    { id: "33c910e5b721aa45", ttl: 5, rssi: -58, battery: 84, symptoms: ["Fever", "Chills"], packet_type: "OUTBREAK_ALERT", hmac: "9c2d1b4a8e0f" },
    { id: "90e28f73120b66c9", ttl: 7, rssi: -71, battery: 60, symptoms: ["Asymptomatic"], packet_type: "GOSSIP_INV", hmac: "5e0f9b3a1c4d" },
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

  const broadcastBitMeshPacket = async () => {
    setLoading(true);
    try {
      const symptomsList = symptomInput.split(",").map((s) => s.trim());
      const payload = [
        {
          device_mac_or_uuid: `device-web-${Math.floor(Math.random() * 1000)}`,
          symptoms: symptomsList,
          fever_celsius: parseFloat(tempInput.toString()),
          ambient_temp_celsius: 34.5,
          ttl: 7
        }
      ];
      const res = await fetch("http://localhost:8000/api/v1/cin/sync", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });
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
                  <Radio className="w-3 h-3 animate-pulse" /> BitChat-BitMesh P2P Protocol
                </span>
                <span className="text-xs text-slate-500 font-mono">Store-and-Forward Gossip v2.6</span>
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
                    BitMesh Alert Status: {syncData.risk_level} RISK
                  </h2>
                  <span className="text-xs font-mono px-2 py-0.5 rounded bg-white/80 border border-current">
                    Swarm R0 = {syncData.estimated_r0 || "1.20"}
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
              <span className="text-xs font-semibold uppercase">Active BitMesh Peers</span>
              <Users className="w-4 h-4 text-blue-600" />
            </div>
            <p className="text-3xl font-extrabold text-slate-900">{syncData?.total_mesh_nodes || 4}</p>
            <p className="text-xs text-slate-500 mt-1">Multi-Hop Store-and-Forward</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between text-slate-500 mb-2">
              <span className="text-xs font-semibold uppercase">Estimated Swarm R0</span>
              <Activity className="w-4 h-4 text-rose-600" />
            </div>
            <p className="text-3xl font-extrabold text-rose-600">{syncData?.estimated_r0 || "1.25"}</p>
            <p className="text-xs text-slate-500 mt-1">Reproduction Rate Estimate</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between text-slate-500 mb-2">
              <span className="text-xs font-semibold uppercase">Fever & Respiratory</span>
              <Activity className="w-4 h-4 text-amber-600" />
            </div>
            <p className="text-3xl font-extrabold text-amber-600">
              {syncData ? `${syncData.fever_count} Fever / ${syncData.cough_count} Cough` : "1 Fever / 1 Cough"}
            </p>
            <p className="text-xs text-slate-500 mt-1">Encrypted Payload Aggregates</p>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between text-slate-500 mb-2">
              <span className="text-xs font-semibold uppercase">Security & Privacy</span>
              <Shield className="w-4 h-4 text-emerald-600" />
            </div>
            <p className="text-lg font-bold text-emerald-700">HKDF + SHA-256 HMAC</p>
            <p className="text-xs text-slate-500 mt-1">Zero-Knowledge Ephemeral ID</p>
          </div>
        </div>

        {/* Broadcast BitMesh Packet Box */}
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <h3 className="font-bold text-slate-900 flex items-center gap-2 mb-2">
            <Send className="w-4 h-4 text-blue-600" /> Broadcast Offline BitMesh Epidemic Token
          </h3>
          <p className="text-xs text-slate-500 mb-4">
            Simulate broadcasting an encrypted store-and-forward epidemic packet over Bluetooth Low Energy mesh protocol.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Symptoms (comma separated)</label>
              <input
                type="text"
                value={symptomInput}
                onChange={(e) => setSymptomInput(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Body Temperature (°C)</label>
              <input
                type="number"
                step="0.1"
                value={tempInput}
                onChange={(e) => setTempInput(parseFloat(e.target.value))}
                className="w-full px-3 py-2 text-sm border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="flex items-end">
              <button
                onClick={broadcastBitMeshPacket}
                disabled={loading}
                className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition flex items-center justify-center gap-2"
              >
                <Radio className="w-4 h-4" /> Broadcast BitMesh Packet
              </button>
            </div>
          </div>
        </div>

        {/* Live Bluetooth Mesh Node Table */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
            <div>
              <h3 className="font-bold text-slate-900">BitChat Store-and-Forward Gossip Peers</h3>
              <p className="text-xs text-slate-500">
                P2P direct exchange with TTL hop-limit decay and zero-knowledge HKDF anonymization
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
              <span className="text-xs text-emerald-700 font-medium">Scanning BLE 2.4 GHz Mesh...</span>
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
                      <span className="text-xs text-slate-400 font-mono">TTL: {node.ttl}/7</span>
                      <span className="text-xs text-slate-400 font-mono">HMAC: {node.hmac}</span>
                    </div>
                    <div className="flex items-center gap-2 mt-1">
                      {node.symptoms.map((s, idx) => (
                        <span
                          key={idx}
                          className="px-2 py-0.5 rounded text-[11px] font-medium bg-rose-50 text-rose-700 border border-rose-200"
                        >
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xs font-mono text-slate-500">Batt: {node.battery}%</span>
                  <p className="text-xs text-emerald-600 font-semibold mt-0.5">BitMesh Gossip Verified</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Store-and-Forward Relay Log */}
        {syncData?.bitmesh_relays && (
          <div className="bg-slate-900 text-slate-100 p-6 rounded-xl border border-slate-800 font-mono text-xs shadow-lg">
            <h4 className="text-emerald-400 font-bold mb-2 flex items-center gap-2">
              <Cpu className="w-4 h-4" /> BitMesh Store-and-Forward Multi-Hop Relay Log
            </h4>
            <div className="space-y-1 opacity-90">
              {syncData.bitmesh_relays.map((relay: any, idx: number) => (
                <p key={idx}>
                  [{new Date().toLocaleTimeString()}] Pkt: <span className="text-yellow-400">{relay.packet_id}</span> | Peer: {relay.sender_anon_id} | InTTL: {relay.incoming_ttl} &#8594; OutTTL: {relay.forward_ttl} | Action: <span className="text-emerald-400">{relay.relay_action}</span>
                </p>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

