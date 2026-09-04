"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Stethoscope, Leaf, ShieldAlert, Pill, Sparkles, CheckCircle2 } from "lucide-react";

export default function DualPrescriptionPage() {
  const [condition, setCondition] = useState("HEAT_STRESS");
  const [symptoms, setSymptoms] = useState("Dizziness, High Fever, Fatigue");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);

  const handleGenerate = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/clinical/dual-prescription", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          condition_key: condition,
          symptoms: symptoms.split(",").map((s) => s.trim())
        })
      });
      if (res.ok) {
        const data = await res.json();
        setResult(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div className="flex items-center gap-4">
            <Link href="/" className="p-2 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 transition">
              <ArrowLeft className="w-5 h-5 text-slate-400" />
            </Link>
            <div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                Feature 6 • ICD-11 + AYUSH Parallel Pathway
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Dual Prescription Engine
              </h1>
            </div>
          </div>
        </div>

        {/* Form Selector */}
        <div className="bg-slate-900/70 backdrop-blur border border-slate-800 rounded-2xl p-6 grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-300">Select Clinical Condition</label>
            <select
              value={condition}
              onChange={(e) => setCondition(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-200 outline-none focus:border-emerald-500 transition"
            >
              <option value="HEAT_STRESS">Heat Stress / Heat Exhaustion</option>
              <option value="ANEMIA">Iron Deficiency Anemia</option>
              <option value="HYPERTENSION">Essential Hypertension</option>
              <option value="CHRONIC_STRESS">Operational / Psychological Stress</option>
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-300">Reported Symptoms (comma separated)</label>
            <input
              type="text"
              value={symptoms}
              onChange={(e) => setSymptoms(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-slate-200 outline-none focus:border-emerald-500 transition"
              placeholder="e.g. Fever, Dizziness, Nausea"
            />
          </div>

          <button
            onClick={handleGenerate}
            disabled={loading}
            className="px-6 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-medium text-sm transition flex items-center justify-center gap-2 shadow-lg shadow-emerald-600/25 disabled:opacity-50"
          >
            <Sparkles className="w-4 h-4" /> {loading ? "Generating..." : "Generate Parallel Pathway"}
          </button>
        </div>

        {/* Dual Prescription Card */}
        {result && (
          <div className="space-y-6">
            {/* Condition Banner */}
            <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-between">
              <div>
                <span className="text-xs text-slate-400 font-mono">ICD-11 Code: {result.icd_11_code}</span>
                <h2 className="text-lg font-bold text-white mt-0.5">{result.condition}</h2>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                Conflict Checked & Verified
              </span>
            </div>

            {/* Parallel Columns */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Allopathic Column */}
              <div className="bg-slate-900/70 backdrop-blur border border-blue-500/20 rounded-2xl p-6 space-y-4">
                <div className="flex items-center gap-2 border-b border-slate-800 pb-3">
                  <Stethoscope className="w-5 h-5 text-blue-400" />
                  <h3 className="font-bold text-white">Allopathic Pathway (Western Medicine)</h3>
                </div>

                <div className="space-y-3">
                  <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Prescribed Medications</h4>
                  <div className="space-y-2">
                    {result.allopathic_pathway?.medications?.map((med: any, idx: number) => (
                      <div key={idx} className="p-3 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between">
                        <div>
                          <p className="text-sm font-semibold text-white">{med.name}</p>
                          <p className="text-xs text-slate-400">{med.dosage} • {med.frequency}</p>
                        </div>
                        <span className="text-xs px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20">{med.duration}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* AYUSH Column */}
              <div className="bg-slate-900/70 backdrop-blur border border-emerald-500/20 rounded-2xl p-6 space-y-4">
                <div className="flex items-center gap-2 border-b border-slate-800 pb-3">
                  <Leaf className="w-5 h-5 text-emerald-400" />
                  <h3 className="font-bold text-white">AYUSH Parallel Pathway (Traditional)</h3>
                </div>

                <div className="space-y-3">
                  <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Ayurvedic Formulations</h4>
                  <div className="space-y-2">
                    {result.ayush_pathway?.herbal_formulations?.map((herb: any, idx: number) => (
                      <div key={idx} className="p-3 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between">
                        <div>
                          <p className="text-sm font-semibold text-emerald-400">{herb.name}</p>
                          <p className="text-xs text-slate-400">{herb.dosage} • {herb.instructions}</p>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 space-y-1">
                    <span className="text-[10px] text-emerald-400 font-semibold uppercase tracking-wider">Ahara & Vihara (Diet & Lifestyle)</span>
                    <p className="text-xs text-slate-300">{result.ayush_pathway?.ahara_vihara_diet}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Contraindications & Interactions Warning Banner */}
            {result.interaction_warnings && result.interaction_warnings.length > 0 && (
              <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-start gap-3">
                <ShieldAlert className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
                <div className="space-y-1">
                  <h4 className="text-sm font-semibold text-amber-300">Herb-Drug Safety & Interaction Check</h4>
                  <ul className="text-xs text-amber-200/80 list-disc list-inside space-y-0.5">
                    {result.interaction_warnings.map((w: string, idx: number) => (
                      <li key={idx}>{w}</li>
                    ))}
                  </ul>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
