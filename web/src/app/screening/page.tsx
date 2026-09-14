"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Mic, Camera, Activity, AlertCircle, CheckCircle, Sparkles, HeartPulse, Droplet } from "lucide-react";
import { apiClient } from "@/lib/api/apiClient";

export default function NonInvasiveScreeningPage() {
  const [activeTab, setActiveTab] = useState<"anemia" | "cough">("anemia");
  const [coughLoading, setCoughLoading] = useState(false);
  const [coughResult, setCoughResult] = useState<any>(null);

  const [redVal, setRedVal] = useState(230);
  const [greenVal, setGreenVal] = useState(190);
  const [blueVal, setBlueVal] = useState(185);
  const [anemiaLoading, setAnemiaLoading] = useState(false);
  const [anemiaResult, setAnemiaResult] = useState<any>(null);

  const runCoughAnalysis = async () => {
    setCoughLoading(true);
    try {
      const data = await apiClient.post<any>("/screening/cough-demo");
      setCoughResult(data);
    } catch (err) {
      console.error(err);
    } finally {
      setCoughLoading(false);
    }
  };

  const runAnemiaScreening = async (r = redVal, g = greenVal, b = blueVal) => {
    setAnemiaLoading(true);
    try {
      const data = await apiClient.post<any>("/screening/anemia-colorimetry", {
        red: Number(r),
        green: Number(g),
        blue: Number(b),
      });
      setAnemiaResult(data);
    } catch (err) {
      console.error(err);
    } finally {
      setAnemiaLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0B0F17] text-slate-100 font-sans pb-20">
      
      {/* Sticky Header */}
      <header className="bg-slate-950/80 backdrop-blur-xl border-b border-slate-800/80 sticky top-16 z-40">
        <div className="max-w-6xl mx-auto px-6 py-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="p-2 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 transition text-slate-300"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20">
                <Sparkles className="w-3.5 h-3.5" /> Point-of-Care Diagnostic Biomarkers
              </span>
              <h1 className="text-2xl font-black text-white tracking-tight mt-1">
                Non-Invasive Diagnostic Suite
              </h1>
            </div>
          </div>

          <div className="flex bg-slate-900/90 p-1 rounded-xl border border-slate-800">
            <button
              onClick={() => setActiveTab("anemia")}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-extrabold transition ${
                activeTab === "anemia"
                  ? "bg-gradient-to-r from-rose-500 to-pink-600 text-white shadow-md shadow-rose-600/20"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              <Camera className="w-4 h-4" /> Palmar Anemia RGB
            </button>
            <button
              onClick={() => setActiveTab("cough")}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-extrabold transition ${
                activeTab === "cough"
                  ? "bg-gradient-to-r from-cyan-500 to-indigo-600 text-white shadow-md shadow-cyan-500/20"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              <Mic className="w-4 h-4" /> Cough Audio ML
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-8 space-y-8">
        
        {/* PALMAR ANEMIA RGB TAB */}
        {activeTab === "anemia" && (
          <div className="space-y-6">
            <div className="glass-card rounded-2xl p-6 sm:p-8 border border-slate-800 space-y-6">
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                  <h2 className="text-xl font-extrabold text-white flex items-center gap-2">
                    <Droplet className="w-6 h-6 text-rose-400" />
                    Non-Invasive Palmar &amp; Nail-Bed Hemoglobin Estimator
                  </h2>
                  <p className="text-xs text-slate-400 mt-1">
                    Continuous Hemoglobin (Hb g/dL) regression and anemia severity tiering using CIELAB colorimetry &amp; GradientBoosting ML weights (`anemia_estimator.pkl`).
                  </p>
                </div>

                <span className="px-3 py-1 rounded-full text-xs font-bold bg-teal-500/10 text-teal-400 border border-teal-500/20 shrink-0">
                  Zero Blood Draw Required
                </span>
              </div>

              {/* RGB Palette & Preset Selectors */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="glass-panel p-6 rounded-xl border border-slate-800 space-y-5">
                  <div className="font-bold text-sm text-slate-200">1-Tap Preset Capillary Pallor Samples</div>
                  
                  <div className="grid grid-cols-3 gap-3">
                    <button
                      onClick={() => { setRedVal(230); setGreenVal(190); setBlueVal(185); runAnemiaScreening(230, 190, 185); }}
                      className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 font-extrabold text-xs hover:bg-rose-500/20 transition flex flex-col items-center gap-1"
                    >
                      <div className="w-8 h-8 rounded-full border border-rose-400/40" style={{ backgroundColor: 'rgb(230,190,185)' }} />
                      <span>Pale Pallor</span>
                    </button>

                    <button
                      onClick={() => { setRedVal(210); setGreenVal(155); setBlueVal(140); runAnemiaScreening(210, 155, 140); }}
                      className="p-3 rounded-xl bg-amber-500/10 border border-amber-500/30 text-amber-300 font-extrabold text-xs hover:bg-amber-500/20 transition flex flex-col items-center gap-1"
                    >
                      <div className="w-8 h-8 rounded-full border border-amber-400/40" style={{ backgroundColor: 'rgb(210,155,140)' }} />
                      <span>Mild Anemia</span>
                    </button>

                    <button
                      onClick={() => { setRedVal(185); setGreenVal(125); setBlueVal(105); runAnemiaScreening(185, 125, 105); }}
                      className="p-3 rounded-xl bg-teal-500/10 border border-teal-500/30 text-teal-300 font-extrabold text-xs hover:bg-teal-500/20 transition flex flex-col items-center gap-1"
                    >
                      <div className="w-8 h-8 rounded-full border border-teal-400/40" style={{ backgroundColor: 'rgb(185,125,105)' }} />
                      <span>Healthy Palm</span>
                    </button>
                  </div>

                  {/* Manual RGB Sliders */}
                  <div className="space-y-3 pt-2 text-xs">
                    <div>
                      <div className="flex justify-between font-bold text-slate-300 mb-1">
                        <span>Red Channel (Capillary Erythema):</span>
                        <span className="text-rose-400">{redVal}</span>
                      </div>
                      <input
                        type="range"
                        min={100}
                        max={255}
                        value={redVal}
                        onChange={(e) => setRedVal(Number(e.target.value))}
                        className="w-full accent-rose-500"
                      />
                    </div>

                    <div>
                      <div className="flex justify-between font-bold text-slate-300 mb-1">
                        <span>Green Channel:</span>
                        <span className="text-emerald-400">{greenVal}</span>
                      </div>
                      <input
                        type="range"
                        min={80}
                        max={220}
                        value={greenVal}
                        onChange={(e) => setGreenVal(Number(e.target.value))}
                        className="w-full accent-emerald-500"
                      />
                    </div>

                    <div>
                      <div className="flex justify-between font-bold text-slate-300 mb-1">
                        <span>Blue Channel:</span>
                        <span className="text-cyan-400">{blueVal}</span>
                      </div>
                      <input
                        type="range"
                        min={80}
                        max={220}
                        value={blueVal}
                        onChange={(e) => setBlueVal(Number(e.target.value))}
                        className="w-full accent-cyan-500"
                      />
                    </div>
                  </div>

                  <button
                    onClick={() => runAnemiaScreening()}
                    disabled={anemiaLoading}
                    className="w-full py-3 rounded-xl bg-gradient-to-r from-rose-500 to-pink-600 hover:from-rose-400 hover:to-pink-500 text-white font-extrabold text-xs shadow-lg shadow-rose-600/25 transition disabled:opacity-50"
                  >
                    {anemiaLoading ? "Computing Hemoglobin Regression..." : "Run Palmar Anemia Colorimetry"}
                  </button>
                </div>

                {/* Output Card */}
                <div className="glass-panel p-6 rounded-xl border border-slate-800 flex flex-col justify-between space-y-4">
                  <div className="space-y-4">
                    <div className="text-xs font-extrabold tracking-wider uppercase text-rose-400">Diagnostic Output</div>
                    
                    {anemiaResult ? (
                      <div className="space-y-4">
                        <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-center">
                          <div className="text-xs font-bold text-slate-400 uppercase tracking-wider">Estimated Hemoglobin (Hb)</div>
                          <div className="text-4xl font-black text-rose-400 mt-1">
                            {anemiaResult.estimated_hb_g_dl} <span className="text-lg font-semibold text-slate-300">g/dL</span>
                          </div>
                        </div>

                        <div className="space-y-2 text-xs">
                          <div className="flex justify-between border-b border-slate-800 pb-2">
                            <span className="text-slate-400">Clinical Tier:</span>
                            <span className="font-extrabold text-white">{anemiaResult.anemia_severity}</span>
                          </div>
                          <div>
                            <span className="font-bold text-slate-200">Recommended Clinical Action:</span>
                            <p className="text-slate-300 mt-1 leading-relaxed bg-slate-900/60 p-3 rounded-lg border border-slate-800">
                              {anemiaResult.clinical_action}
                            </p>
                          </div>
                        </div>
                      </div>
                    ) : (
                      <div className="text-center py-16 space-y-2 text-slate-500">
                        <Camera className="w-10 h-10 mx-auto text-slate-600" />
                        <p className="text-xs italic">Select a preset or adjust RGB sliders and click run.</p>
                      </div>
                    )}
                  </div>

                  <div className="text-[10px] text-slate-500 border-t border-slate-800 pt-3">
                    Model: <span className="text-slate-400 font-mono">GradientBoosting-CIELAB (anemia_estimator.pkl)</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* COUGH AUDIO TAB */}
        {activeTab === "cough" && (
          <div className="space-y-6">
            <div className="glass-card rounded-2xl p-6 sm:p-8 border border-slate-800 space-y-6">
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                  <h2 className="text-xl font-extrabold text-white flex items-center gap-2">
                    <Mic className="w-6 h-6 text-cyan-400" />
                    Acoustic Cough Biomarker Classifier
                  </h2>
                  <p className="text-xs text-slate-400 mt-1">
                    Spectral Centroid, Rolloff, and Zero Crossing Rate (ZCR) acoustic spectrogram classifier (`cough_classifier.pkl`).
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="glass-panel p-6 rounded-xl border border-slate-800 space-y-5">
                  <div className="space-y-2">
                    <div className="text-xs font-bold text-slate-200">Acoustic Audio Input</div>
                    <p className="text-xs text-slate-400 leading-relaxed">
                      Click below to capture 3-second cough audio wave and run spectral feature extraction.
                    </p>
                  </div>

                  <button
                    onClick={runCoughAnalysis}
                    disabled={coughLoading}
                    className="w-full py-3.5 rounded-xl bg-gradient-to-r from-cyan-500 to-indigo-600 hover:from-cyan-400 hover:to-indigo-500 text-white font-extrabold text-xs shadow-lg shadow-cyan-500/25 transition disabled:opacity-50 flex items-center justify-center gap-2"
                  >
                    <Mic className="w-4 h-4" />
                    {coughLoading ? "Extracting Acoustic Waveform..." : "Record & Analyze Cough Biomarkers"}
                  </button>

                  <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 text-xs space-y-2">
                    <div className="font-bold text-slate-300">Feature Extraction Pipeline:</div>
                    <ul className="list-disc list-inside text-slate-400 text-[11px] space-y-1">
                      <li>Spectral Centroid (Frequency Brightness)</li>
                      <li>Spectral Rolloff (Energy Envelope)</li>
                      <li>Zero Crossing Rate (ZCR Turbulency)</li>
                      <li>Peak Resonant Frequencies</li>
                    </ul>
                  </div>
                </div>

                <div className="glass-panel p-6 rounded-xl border border-slate-800 flex flex-col justify-between space-y-4">
                  <div className="space-y-4">
                    <div className="text-xs font-extrabold tracking-wider uppercase text-cyan-400">Analysis Result</div>

                    {coughResult ? (
                      <div className="space-y-4 text-xs">
                        <div className="p-4 rounded-xl bg-cyan-500/10 border border-cyan-500/20">
                          <div className="text-xs text-slate-400 font-bold uppercase tracking-wider">Cough Classification</div>
                          <div className="text-2xl font-black text-cyan-300 mt-1">{coughResult.cough_type}</div>
                          <div className="text-[11px] text-teal-400 font-bold mt-1">
                            Confidence: {(coughResult.confidence_score * 100).toFixed(1)}%
                          </div>
                        </div>

                        {coughResult.acoustic_features && (
                          <div className="grid grid-cols-2 gap-2 text-[11px]">
                            <div className="p-2 rounded-lg bg-slate-900 border border-slate-800">
                              <span className="text-slate-400">Centroid:</span>
                              <div className="font-bold text-white">{coughResult.acoustic_features.spectral_centroid_hz} Hz</div>
                            </div>
                            <div className="p-2 rounded-lg bg-slate-900 border border-slate-800">
                              <span className="text-slate-400">Rolloff:</span>
                              <div className="font-bold text-white">{coughResult.acoustic_features.spectral_rolloff_hz} Hz</div>
                            </div>
                          </div>
                        )}

                        <div className="p-3 rounded-lg bg-slate-900/60 border border-slate-800">
                          <span className="font-bold text-slate-200">Clinical Recommendation:</span>
                          <p className="text-slate-300 mt-1 leading-relaxed text-[11px]">
                            {coughResult.clinical_recommendation}
                          </p>
                        </div>
                      </div>
                    ) : (
                      <div className="text-center py-16 space-y-2 text-slate-500">
                        <Mic className="w-10 h-10 mx-auto text-slate-600" />
                        <p className="text-xs italic">Click analyze to run FFT audio classifier.</p>
                      </div>
                    )}
                  </div>

                  <div className="text-[10px] text-slate-500 border-t border-slate-800 pt-3">
                    Model: <span className="text-slate-400 font-mono">RandomForest-Acoustic (cough_classifier.pkl)</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

      </main>
    </div>
  );
}
