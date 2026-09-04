"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, ShieldCheck, Database, FileCode, CheckCircle2, RefreshCw } from "lucide-react";

export default function AbdmBridgePage() {
  const [abhaNumber, setAbhaNumber] = useState("91-1234-5678-9012");
  const [linked, setLinked] = useState(false);
  const [fhirBundle, setFhirBundle] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const handleLinkAbha = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/clinical/abdm/link", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ abha_number: abhaNumber, abha_address: "user@abdm" })
      });
      if (res.ok) {
        setLinked(true);
        fetchFhirBundle();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchFhirBundle = async () => {
    try {
      const res = await fetch("http://localhost:8000/api/v1/clinical/abdm/fhir-bundle");
      if (res.ok) {
        const json = await res.json();
        setFhirBundle(json);
      }
    } catch (err) {
      console.error(err);
    }
  };

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
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                Feature 13 • ABDM M1/M2/M3 Sandbox Gateway
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Universal ABDM & HL7 FHIR R4 Bridge
              </h1>
            </div>
          </div>
        </div>

        {/* Link ABHA Card */}
        <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 space-y-4">
          <h3 className="text-base font-bold text-white flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-emerald-400" /> Connect Ayushman Bharat Health Account (ABHA)
          </h3>

          <div className="flex gap-3 max-w-lg">
            <input
              type="text"
              value={abhaNumber}
              onChange={(e) => setAbhaNumber(e.target.value)}
              placeholder="Enter 14-digit ABHA Number"
              className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white outline-none focus:border-emerald-500 transition font-mono"
            />
            <button
              onClick={handleLinkAbha}
              disabled={loading}
              className="px-6 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-medium text-sm transition flex items-center gap-2 shadow-lg shadow-emerald-600/25 disabled:opacity-50"
            >
              {linked ? <CheckCircle2 className="w-4 h-4" /> : <Database className="w-4 h-4" />}
              {linked ? "ABHA Linked" : "Link Account"}
            </button>
          </div>
        </div>

        {/* FHIR Bundle Viewer */}
        {fhirBundle && (
          <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-slate-300 flex items-center gap-2">
                <FileCode className="w-4 h-4 text-cyan-400" /> HL7 FHIR R4 JSON Bundle Preview
              </h3>
              <span className="text-xs text-slate-500 font-mono">Resource: {fhirBundle.resourceType}</span>
            </div>

            <pre className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-xs font-mono text-cyan-300 overflow-x-auto max-h-96">
              {JSON.stringify(fhirBundle, null, 2)}
            </pre>
          </div>
        )}
      </div>
    </div>
  );
}
