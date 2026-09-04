"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Cpu, Download, CheckCircle2, WifiOff, RefreshCw } from "lucide-react";

export default function EdgeAiPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchEdge = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/ai/edge-fallback/status");
      if (res.ok) {
        const json = await res.json();
        setData(json);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEdge();
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
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                Feature 17 • Zero-Connectivity On-Device Inference
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Offline-First Edge AI Engine & TFLite Manager
              </h1>
            </div>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24 text-slate-400 gap-3">
            <RefreshCw className="w-6 h-6 animate-spin text-emerald-400" /> Checking local model cache...
          </div>
        ) : data ? (
          <div className="space-y-6">
            {/* Status Banner */}
            <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
                  <WifiOff className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-white">Offline Edge Mode Active</h3>
                  <p className="text-xs text-slate-400">TFLite models automatically execute locally when cell connectivity is dropped.</p>
                </div>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                Fully Autonomous
              </span>
            </div>

            {/* Model List */}
            <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 space-y-4">
              <h3 className="text-base font-bold text-white flex items-center gap-2">
                <Cpu className="w-5 h-5 text-emerald-400" /> On-Device TFLite Model Registry
              </h3>

              <div className="space-y-3">
                {data.offline_tflite_models.map((m: any, idx: number) => (
                  <div key={idx} className="p-4 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between">
                    <div className="space-y-1">
                      <p className="text-sm font-semibold text-white">{m.name} <span className="text-xs text-slate-500 font-mono">({m.size_mb} MB)</span></p>
                      <p className="text-xs text-slate-400 font-mono">{m.local_path} • v{m.version}</p>
                    </div>

                    <span className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                      <CheckCircle2 className="w-4 h-4" /> Cached Local
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
