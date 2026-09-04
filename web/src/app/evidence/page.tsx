"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Shield, Lock, FileText, CheckCircle2, RefreshCw } from "lucide-react";

export default function EvidenceChainPage() {
  const [chain, setChain] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [incidentType, setIncidentType] = useState("THREAT_RECORDING");
  const [description, setDescription] = useState("Stealth audio capture during legal adjournment.");

  const fetchChain = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/covert-sos/evidence/chain");
      if (res.ok) {
        const json = await res.json();
        setChain(json);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleAddEvidence = async () => {
    try {
      const res = await fetch("http://localhost:8000/api/v1/covert-sos/evidence/log", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ incident_type: incidentType, description: description })
      });
      if (res.ok) {
        fetchChain();
      }
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchChain();
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div className="flex items-center gap-4">
            <Link href="/" className="p-2 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 transition">
              <ArrowLeft className="w-5 h-5 text-slate-400" />
            </Link>
            <div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
                Feature 16 • Bharatiya Sakshya Adhiniyam 2023 BSA Sec 63
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Cryptographic Evidence Chain (Merkle Audit Trail)
              </h1>
            </div>
          </div>
        </div>

        {/* Add Evidence Input */}
        <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 space-y-4">
          <h3 className="text-base font-bold text-white flex items-center gap-2">
            <Lock className="w-5 h-5 text-cyan-400" /> Log Tamper-Evident Legal Block
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-300">Incident Category</label>
              <select
                value={incidentType}
                onChange={(e) => setIncidentType(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-white outline-none"
              >
                <option value="THREAT_RECORDING">Threat / Coercion Recording</option>
                <option value="LEGAL_CHECKIN">Victim Wellbeing Log</option>
                <option value="COVERT_SOS_DISPATCH">Stealth SOS Dispatch Record</option>
              </select>
            </div>

            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-300">Statement / Evidence Details</label>
              <input
                type="text"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-white outline-none"
              />
            </div>
          </div>

          <button
            onClick={handleAddEvidence}
            className="px-6 py-2.5 rounded-xl bg-cyan-600 hover:bg-cyan-500 text-white font-medium text-sm transition flex items-center gap-2 shadow-lg shadow-cyan-600/25"
          >
            <Shield className="w-4 h-4" /> Compute Cryptographic Block
          </button>
        </div>

        {/* Merkle Chain Timeline */}
        {chain && (
          <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-sm font-bold text-white">Merkle Tree Root: <span className="text-cyan-400 font-mono">{chain.merkle_root}</span></h3>
              <span className="text-xs text-slate-400">{chain.total_blocks} Blocks Anchored</span>
            </div>

            <div className="space-y-3">
              {chain.blocks.map((b: any) => (
                <div key={b.block_index} className="p-4 rounded-xl bg-slate-950 border border-slate-800 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-cyan-400 font-mono">Block #{b.block_index} • {b.evidence_id}</span>
                    <span className="flex items-center gap-1 text-[10px] font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                      <CheckCircle2 className="w-3 h-3" /> BSA Sec 63 Verified
                    </span>
                  </div>
                  <p className="text-xs font-mono text-slate-400 break-all">SHA-256: {b.sha256_hash}</p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
