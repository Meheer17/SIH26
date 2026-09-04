"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Activity, Heart, Brain, RefreshCw, Zap, ShieldCheck } from "lucide-react";

export default function DigitalTwinPage() {
  const [twin, setTwin] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchDigitalTwin = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/apps/digital-twin");
      if (res.ok) {
        const data = await res.json();
        setTwin(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDigitalTwin();
  }, []);

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
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
                Feature 12 • Groundbreaking Organ Avatar Twin
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Longitudinal 3D Digital Twin & Organ Health Score
              </h1>
            </div>
          </div>
          <button onClick={fetchDigitalTwin} className="p-2 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 text-slate-400 transition">
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
          </button>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24 text-slate-400 gap-3">
            <RefreshCw className="w-6 h-6 animate-spin text-cyan-400" /> Constructing personalized 3D Digital Twin...
          </div>
        ) : twin ? (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Overall Health Score Card */}
            <div className="bg-slate-900/70 backdrop-blur border border-slate-800 rounded-2xl p-6 flex flex-col items-center justify-center text-center space-y-4">
              <div className="relative w-40 h-40 flex items-center justify-center">
                <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
                  <path className="text-slate-800" strokeWidth="3" stroke="currentColor" fill="none" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" />
                  <path className="text-cyan-400" strokeDasharray={`${twin.overall_health_score}, 100`} strokeWidth="3" strokeLinecap="round" stroke="currentColor" fill="none" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" />
                </svg>
                <div className="absolute text-center">
                  <span className="text-4xl font-extrabold text-white">{twin.overall_health_score}</span>
                  <span className="block text-[10px] text-slate-400 uppercase tracking-widest mt-0.5">Health Score</span>
                </div>
              </div>

              <div className="space-y-1">
                <span className="text-xs font-semibold text-emerald-400 flex items-center justify-center gap-1">
                  <Zap className="w-3.5 h-3.5" /> {twin.health_score_trajectory}
                </span>
                <p className="text-xs text-slate-400">Aggregated across ArogyaSathi, MediKiosk & NyayaSahay telemetry</p>
              </div>
            </div>

            {/* Organ System Cards */}
            <div className="lg:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="p-5 rounded-2xl bg-slate-900/70 border border-slate-800 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-bold text-white flex items-center gap-2">
                    <Heart className="w-4 h-4 text-rose-400" /> Cardiovascular System
                  </span>
                  <span className="text-xs font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                    {twin.organ_health.cardiovascular.score} / 100
                  </span>
                </div>
                <div className="text-xs text-slate-400 space-y-1">
                  <p>Status: <span className="text-white font-medium">{twin.organ_health.cardiovascular.status}</span></p>
                  <p>HRV Baseline: <span className="text-white font-medium">{twin.organ_health.cardiovascular.hrv_ms} ms</span></p>
                </div>
              </div>

              <div className="p-5 rounded-2xl bg-slate-900/70 border border-slate-800 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-bold text-white flex items-center gap-2">
                    <Activity className="w-4 h-4 text-indigo-400" /> Pulmonary & Respiratory
                  </span>
                  <span className="text-xs font-bold text-indigo-400 bg-indigo-500/10 px-2 py-0.5 rounded border border-indigo-500/20">
                    {twin.organ_health.pulmonary.score} / 100
                  </span>
                </div>
                <div className="text-xs text-slate-400 space-y-1">
                  <p>Status: <span className="text-white font-medium">{twin.organ_health.pulmonary.status}</span></p>
                  <p>Acoustic Cough Biomarker: <span className="text-emerald-400 font-medium">{twin.organ_health.pulmonary.cough_risk}</span></p>
                </div>
              </div>

              <div className="p-5 rounded-2xl bg-slate-900/70 border border-slate-800 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-bold text-white flex items-center gap-2">
                    <ShieldCheck className="w-4 h-4 text-amber-400" /> Metabolic & Blood
                  </span>
                  <span className="text-xs font-bold text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded border border-amber-500/20">
                    {twin.organ_health.metabolic.score} / 100
                  </span>
                </div>
                <div className="text-xs text-slate-400 space-y-1">
                  <p>Status: <span className="text-white font-medium">{twin.organ_health.metabolic.status}</span></p>
                  <p>Estimated Hemoglobin: <span className="text-white font-medium">{twin.organ_health.metabolic.estimated_hb} g/dL</span></p>
                </div>
              </div>

              <div className="p-5 rounded-2xl bg-slate-900/70 border border-slate-800 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-bold text-white flex items-center gap-2">
                    <Brain className="w-4 h-4 text-purple-400" /> Neurological & Mental State
                  </span>
                  <span className="text-xs font-bold text-purple-400 bg-purple-500/10 px-2 py-0.5 rounded border border-purple-500/20">
                    {twin.organ_health.neurological_mental.score} / 100
                  </span>
                </div>
                <div className="text-xs text-slate-400 space-y-1">
                  <p>State: <span className="text-white font-medium">{twin.organ_health.neurological_mental.status}</span></p>
                  <p>Burnout / Stress Index: <span className="text-emerald-400 font-medium">{twin.organ_health.neurological_mental.burnout_index}</span></p>
                </div>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
