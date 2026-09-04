"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Mic, Camera, Activity, AlertCircle, CheckCircle, FileText, Stethoscope } from "lucide-react";

export default function NonInvasiveScreeningPage() {
  const [activeTab, setActiveTab] = useState<"cough" | "anemia">("cough");
  const [coughLoading, setCoughLoading] = useState(false);
  const [coughResult, setCoughResult] = useState<any>(null);

  const [anemiaLoading, setAnemiaLoading] = useState(false);
  const [anemiaResult, setAnemiaResult] = useState<any>(null);

  const runCoughAnalysis = async () => {
    setCoughLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/screening/cough-demo", { method: "POST" });
      if (res.ok) {
        const data = await res.json();
        setCoughResult(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setCoughLoading(false);
    }
  };

  const runAnemiaScreening = async (red: number, green: number, blue: number) => {

    setAnemiaLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/screening/anemia-colorimetry", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ red, green, blue })
      });
      if (res.ok) {
        const data = await res.json();
        setAnemiaResult(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setAnemiaLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#0F172A]">
      {/* Top Bar */}
      <header className="bg-white border-b border-slate-200 px-6 py-4 sticky top-0 z-10">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 transition text-slate-600"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-blue-100 text-blue-800">
                AI Diagnostic Biomarkers
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
                Non-Invasive Diagnostic Suite
              </h1>
            </div>
          </div>

          <div className="flex bg-slate-100 p-1 rounded-lg border border-slate-200">
            <button
              onClick={() => setActiveTab("cough")}
              className={`flex items-center gap-2 px-4 py-1.5 rounded-md text-sm font-semibold transition ${
                activeTab === "cough"
                  ? "bg-white text-slate-900 shadow-sm"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              <Mic className="w-4 h-4" /> Cough Audio ML
            </button>
            <button
              onClick={() => setActiveTab("anemia")}
              className={`flex items-center gap-2 px-4 py-1.5 rounded-md text-sm font-semibold transition ${
                activeTab === "anemia"
                  ? "bg-white text-slate-900 shadow-sm"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              <Camera className="w-4 h-4" /> Palmar Anemia RGB
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-8">
        {/* COUGH TAB */}
        {activeTab === "cough" && (
          <div className="space-y-6">
            <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
              <h2 className="text-lg font-bold text-slate-900 mb-1 flex items-center gap-2">
                <Mic className="w-5 h-5 text-blue-600" /> Acoustic Biomarker Cough Classifier
              </h2>
              <p className="text-sm text-slate-500 mb-6">
                Record 3-second cough audio. Algorithms analyze Zero Crossing Rate (ZCR), spectral centroid, and frequency energy envelopes.
              </p>

              <div className="p-8 border-2 border-dashed border-slate-300 rounded-xl flex flex-col items-center justify-center bg-slate-50">
                <div className="p-4 rounded-full bg-blue-100 text-blue-600 mb-4 animate-bounce">
                  <Mic className="w-8 h-8" />
                </div>
                <p className="font-semibold text-slate-800 text-sm">Ready to record or test sample cough</p>
                <p className="text-xs text-slate-400 mt-1 mb-4">Sample Rate: 16 kHz WAV | PCM Mono</p>

                <button
                  onClick={runCoughAnalysis}
                  disabled={coughLoading}
                  className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition shadow-sm"
                >
                  {coughLoading ? "Analyzing Spectral Centroid..." : "Run Cough Acoustic Analysis"}
                </button>
              </div>
            </div>

            {/* Cough Results */}
            {coughResult && (
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
                <div className="flex items-center justify-between border-b border-slate-100 pb-4">
                  <div>
                    <span className="text-xs font-mono text-slate-400">ICD-11: {coughResult.icd_11_code}</span>
                    <h3 className="text-xl font-extrabold text-slate-900">{coughResult.cough_type}</h3>
                  </div>
                  <div className="text-right">
                    <span className="text-xs text-slate-500">ML Confidence</span>
                    <p className="text-lg font-bold text-emerald-600">{(coughResult.confidence_score * 100).toFixed(0)}%</p>
                  </div>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="p-3 bg-slate-50 rounded-lg border border-slate-200">
                    <span className="text-xs text-slate-500">Zero Crossing Rate</span>
                    <p className="font-mono font-bold text-slate-800">{coughResult.acoustic_features.zero_crossing_rate}</p>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg border border-slate-200">
                    <span className="text-xs text-slate-500">Spectral Centroid</span>
                    <p className="font-mono font-bold text-slate-800">{coughResult.acoustic_features.spectral_centroid_hz} Hz</p>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg border border-slate-200">
                    <span className="text-xs text-slate-500">Signal Energy</span>
                    <p className="font-mono font-bold text-slate-800">{coughResult.acoustic_features.signal_energy}</p>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg border border-slate-200">
                    <span className="text-xs text-slate-500">Triage Urgency</span>
                    <p className="font-bold text-amber-600">{coughResult.triage_urgency}</p>
                  </div>
                </div>

                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <p className="text-xs font-semibold text-blue-800 uppercase">Clinical Recommendation</p>
                  <p className="text-sm text-blue-900 mt-1">{coughResult.clinical_recommendation}</p>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ANEMIA TAB */}
        {activeTab === "anemia" && (
          <div className="space-y-6">
            <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
              <h2 className="text-lg font-bold text-slate-900 mb-1 flex items-center gap-2">
                <Camera className="w-5 h-5 text-rose-600" /> Non-Invasive Palmar Hemoglobin Estimator
              </h2>
              <p className="text-sm text-slate-500 mb-6">
                Captures palmar surface / conjunctival redness R/G colorimetric ratio to non-invasively screen for anemia.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <button
                  onClick={() => runAnemiaScreening(185, 125, 120)}
                  className="p-5 rounded-xl border border-slate-200 hover:border-emerald-500 bg-white hover:bg-emerald-50/30 text-left transition"
                >
                  <span className="text-xs font-mono px-2 py-0.5 rounded bg-emerald-100 text-emerald-800">Sample 1</span>
                  <h4 className="font-bold text-slate-900 mt-2">Healthy Palmar Redness</h4>
                  <p className="text-xs text-slate-500 mt-1">RGB (185, 125, 120) | High R/G Ratio</p>
                </button>

                <button
                  onClick={() => runAnemiaScreening(155, 142, 138)}
                  className="p-5 rounded-xl border border-slate-200 hover:border-amber-500 bg-white hover:bg-amber-50/30 text-left transition"
                >
                  <span className="text-xs font-mono px-2 py-0.5 rounded bg-amber-100 text-amber-800">Sample 2</span>
                  <h4 className="font-bold text-slate-900 mt-2">Moderate Pallor</h4>
                  <p className="text-xs text-slate-500 mt-1">RGB (155, 142, 138) | Reduced Redness</p>
                </button>

                <button
                  onClick={() => runAnemiaScreening(140, 145, 140)}
                  className="p-5 rounded-xl border border-slate-200 hover:border-rose-500 bg-white hover:bg-rose-50/30 text-left transition"
                >
                  <span className="text-xs font-mono px-2 py-0.5 rounded bg-rose-100 text-rose-800">Sample 3</span>
                  <h4 className="font-bold text-slate-900 mt-2">Severe Pallor / Anemia</h4>
                  <p className="text-xs text-slate-500 mt-1">RGB (140, 145, 140) | Low R/G Ratio</p>
                </button>
              </div>
            </div>

            {/* Anemia Results */}
            {anemiaResult && (
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
                <div className="flex items-center justify-between border-b border-slate-100 pb-4">
                  <div>
                    <span className="text-xs font-mono text-slate-400">ICD-10: {anemiaResult.icd_10_code}</span>
                    <h3 className="text-xl font-extrabold text-slate-900">{anemiaResult.anemia_severity.replace("_", " ")}</h3>
                  </div>
                  <div className="text-right">
                    <span className="text-xs text-slate-500">Estimated Hemoglobin</span>
                    <p className="text-2xl font-extrabold text-slate-900">{anemiaResult.estimated_hb_g_dl} <span className="text-sm font-normal text-slate-500">g/dL</span></p>
                  </div>
                </div>

                <div className="p-4 bg-slate-50 rounded-lg border border-slate-200">
                  <div className="flex items-center justify-between text-xs font-mono text-slate-600 mb-1">
                    <span>R/G Colorimetric Index: {anemiaResult.colorimetric_rgb.rg_ratio}</span>
                    <span>Urgency: {anemiaResult.triage_urgency}</span>
                  </div>
                  <p className="text-sm font-medium text-slate-800 mt-2">{anemiaResult.clinical_action}</p>
                </div>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
