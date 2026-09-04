"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, UserCheck, ShieldAlert, HeartPulse, Sparkles, CheckCircle2 } from "lucide-react";

export default function AshaCopilotPage() {
  const [patientName, setPatientName] = useState("Sunita Devi");
  const [age, setAge] = useState(26);
  const [isPregnant, setIsPregnant] = useState(true);
  const [symptoms, setSymptoms] = useState("severe headache, swelling");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);

  const handleTriage = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/apps/asha-copilot", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          patient_name: patientName,
          age: Number(age),
          is_pregnant: isPregnant,
          symptoms: symptoms.split(",").map((s) => s.trim())
        })
      });
      if (res.ok) {
        const json = await res.json();
        setResult(json);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
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
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-rose-500/10 text-rose-400 border border-rose-500/20">
                Feature 15 • MoHFW RCH Protocol Assistant
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                ASHA Worker Copilot & Field Triage
              </h1>
            </div>
          </div>
        </div>

        {/* Form Card */}
        <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 space-y-4">
          <h3 className="text-base font-bold text-white flex items-center gap-2">
            <UserCheck className="w-5 h-5 text-rose-400" /> Rural Field Resident Intake
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-300">Resident Name</label>
              <input
                type="text"
                value={patientName}
                onChange={(e) => setPatientName(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-white outline-none focus:border-rose-500 transition"
              />
            </div>

            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-300">Age</label>
              <input
                type="number"
                value={age}
                onChange={(e) => setAge(Number(e.target.value))}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-white outline-none focus:border-rose-500 transition"
              />
            </div>

            <div className="space-y-1 flex flex-col justify-end">
              <label className="flex items-center gap-2 text-sm text-slate-200 cursor-pointer pb-2">
                <input
                  type="checkbox"
                  checked={isPregnant}
                  onChange={(e) => setIsPregnant(e.target.checked)}
                  className="rounded border-slate-800 bg-slate-950 text-rose-500 focus:ring-rose-500"
                />
                Maternal / Ante-Natal Status
              </label>
            </div>
          </div>

          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-300">Reported Symptoms (comma separated)</label>
            <input
              type="text"
              value={symptoms}
              onChange={(e) => setSymptoms(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-white outline-none focus:border-rose-500 transition"
            />
          </div>

          <button
            onClick={handleTriage}
            disabled={loading}
            className="px-6 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white font-medium text-sm transition flex items-center justify-center gap-2 shadow-lg shadow-rose-600/25 disabled:opacity-50"
          >
            <Sparkles className="w-4 h-4" /> Evaluate Field Triage
          </button>
        </div>

        {/* Result */}
        {result && (
          <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 space-y-4">
            <div className="flex items-center justify-between">
              <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                result.triage_color === "RED" ? "bg-rose-500/20 text-rose-300 border border-rose-500/30" : "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30"
              }`}>
                Triage Code: {result.triage_color}
              </span>
              <span className="text-xs text-slate-400 font-mono">{result.asha_guideline_reference}</span>
            </div>

            <div className="space-y-2">
              <h4 className="text-lg font-bold text-white">{result.patient_name} — {result.risk_tier}</h4>
              <p className="text-sm text-slate-300">{result.recommended_action}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
