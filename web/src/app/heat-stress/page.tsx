"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Sun, Droplets, Thermometer, ShieldAlert, Activity, RefreshCw } from "lucide-react";

export default function HeatStressPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchHeatStress = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/apps/heat-stress?lat=28.6139&lon=77.2090");
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
    fetchHeatStress();
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
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20">
                Feature 11 • Open-Meteo & WBGT Index
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Real-time Heat Stress & Environmental Advisory
              </h1>
            </div>
          </div>
          <button
            onClick={fetchHeatStress}
            className="p-2 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 text-slate-400 transition"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
          </button>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24 text-slate-400 gap-3">
            <RefreshCw className="w-6 h-6 animate-spin text-amber-400" /> Fetching live weather & computing heat stress index...
          </div>
        ) : data ? (
          <div className="space-y-6">
            {/* Top Cards Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <div className="flex items-center justify-between text-amber-400">
                  <span className="text-xs font-medium text-slate-400">Ambient Temp</span>
                  <Thermometer className="w-5 h-5" />
                </div>
                <p className="text-3xl font-bold text-white">{data.temperature_c}°C</p>
                <p className="text-xs text-slate-500">Live CPCB / IMD Feed</p>
              </div>

              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <div className="flex items-center justify-between text-blue-400">
                  <span className="text-xs font-medium text-slate-400">Relative Humidity</span>
                  <Droplets className="w-5 h-5" />
                </div>
                <p className="text-3xl font-bold text-white">{data.humidity_percent}%</p>
                <p className="text-xs text-slate-500">Moisture Content</p>
              </div>

              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <div className="flex items-center justify-between text-rose-400">
                  <span className="text-xs font-medium text-slate-400">WBGT Index</span>
                  <Sun className="w-5 h-5" />
                </div>
                <p className="text-3xl font-bold text-white">{data.wbgt_index}</p>
                <span className="inline-block px-2 py-0.5 rounded text-[10px] font-bold bg-rose-500/20 text-rose-300 border border-rose-500/30">
                  {data.heat_stress_tier}
                </span>
              </div>

              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <div className="flex items-center justify-between text-cyan-400">
                  <span className="text-xs font-medium text-slate-400">Dehydration Risk</span>
                  <Activity className="w-5 h-5" />
                </div>
                <p className="text-3xl font-bold text-white">{data.dehydration_risk_percent}%</p>
                <p className="text-xs text-cyan-400 font-medium">Rec: {data.recommended_water_intake_liters}L Water/day</p>
              </div>
            </div>

            {/* NDMA Emergency Advisory Banner */}
            <div className="p-6 rounded-2xl bg-amber-500/10 border border-amber-500/30 space-y-3">
              <div className="flex items-center gap-3">
                <ShieldAlert className="w-6 h-6 text-amber-400 shrink-0" />
                <h3 className="text-lg font-bold text-amber-300">NDMA & Health Ministry Advisory</h3>
              </div>
              <p className="text-sm text-amber-200/90 leading-relaxed">{data.ndma_advisory}</p>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
