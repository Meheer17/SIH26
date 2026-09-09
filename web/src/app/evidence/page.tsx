"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Shield, Lock, FileText, CheckCircle2, RefreshCw } from "lucide-react";
import { apiClient } from "@/lib/api/apiClient";

export default function EvidenceChainPage() {
  const [chain, setChain] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [incidentType, setIncidentType] = useState("THREAT_RECORDING");
  const [description, setDescription] = useState("Stealth audio capture during legal adjournment.");

  const fetchChain = async () => {
    setLoading(true);
    try {
      const json = await apiClient.get<any>("/covert-sos/evidence/chain");
      setChain(json);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleAddEvidence = async () => {
    try {
      await apiClient.post<any>("/covert-sos/evidence/log", {
        incident_type: incidentType,
        description: description,
      });
      fetchChain();
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchChain();
  }, []);

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#0F172A] p-6 font-sans">
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-4">
          <div className="flex items-center gap-4">
            <Link href="/" className="p-2 rounded-xl bg-white border border-slate-200 hover:bg-slate-50 transition shadow-xs text-slate-700">
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-teal-50 text-teal-700 border border-teal-200">
                Bharatiya Sakshya Adhiniyam 2023 Sec 63
              </span>
              <h1 className="text-2xl font-black tracking-tight text-slate-900 mt-1">
                Cryptographic Legal Evidence Chain
              </h1>
            </div>
          </div>
        </div>

        {/* Add Evidence Input */}
        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-xs">
          <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
            <Lock className="w-5 h-5 text-teal-600" /> Log Tamper-Evident Legal Block
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-700">Incident Category</label>
              <select
                value={incidentType}
                onChange={(e) => setIncidentType(e.target.value)}
                className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-800 outline-none focus:ring-2 focus:ring-teal-500"
              >
                <option value="THREAT_RECORDING">Threat / Coercion Recording</option>
                <option value="LEGAL_CHECKIN">Victim Wellbeing Log</option>
                <option value="COVERT_SOS_DISPATCH">Stealth SOS Dispatch Record</option>
              </select>
            </div>

            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-700">Statement / Evidence Details</label>
              <input
                type="text"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-800 outline-none focus:ring-2 focus:ring-teal-500"
              />
            </div>
          </div>

          <button
            onClick={handleAddEvidence}
            className="px-6 py-2.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white font-bold text-sm transition flex items-center gap-2 shadow-xs"
          >
            <Shield className="w-4 h-4" /> Compute &amp; Anchor Cryptographic Block
          </button>
        </div>

        {/* Merkle Chain Timeline */}
        {chain && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-xs">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-sm font-bold text-slate-900">
                Merkle Tree Root: <span className="text-teal-700 font-mono text-xs">{chain.merkle_root}</span>
              </h3>
              <span className="text-xs font-bold text-slate-500">{chain.total_blocks} Blocks Anchored</span>
            </div>

            <div className="space-y-3">
              {chain.blocks?.map((b: any) => (
                <div key={b.block_index} className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-teal-800 font-mono">Block #{b.block_index} • {b.evidence_id}</span>
                    <span className="flex items-center gap-1 text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                      <CheckCircle2 className="w-3 h-3" /> BSA Sec 63 Verified
                    </span>
                  </div>
                  <p className="text-xs font-mono text-slate-600 break-all">SHA-256: {b.sha256_hash}</p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
