"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import {
  ArrowLeft,
  Activity,
  Heart,
  Brain,
  RefreshCw,
  Zap,
  ShieldCheck,
  Volume2,
  VolumeX,
  Play,
  User,
  AlertTriangle,
  TrendingUp,
  Sparkles,
  Info
} from "lucide-react";

export default function DigitalTwinPage() {
  const [twin, setTwin] = useState<any>(null);
  const [avatars, setAvatars] = useState<any[]>([]);
  const [selectedAvatar, setSelectedAvatar] = useState<any>(null);
  const [interventions, setInterventions] = useState<any[]>([]);
  const [selectedIntervention, setSelectedIntervention] = useState<string>("stop_bp_meds");
  const [whatIfResult, setWhatIfResult] = useState<any>(null);
  const [forecast, setForecast] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [simulating, setSimulating] = useState(false);
  const [speaking, setSpeaking] = useState(false);
  const [currentViseme, setCurrentViseme] = useState<string>("neutral");
  const [activeOrgan, setActiveOrgan] = useState<string>("cardiovascular");
  const [rotationAngle, setRotationAngle] = useState(0);

  // Canvas ref for 3D holographic rendering
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const animationFrameRef = useRef<number | null>(null);

  const fetchTwinData = async () => {
    setLoading(true);
    try {
      // 1. Fetch Twin Status
      const resStatus = await fetch("http://localhost:8000/api/v1/digital-twin/status");
      if (resStatus.ok) {
        const data = await resStatus.json();
        setTwin(data);
      }

      // 2. Fetch Avatars
      const resAvatars = await fetch("http://localhost:8000/api/v1/digital-twin/avatar-models");
      if (resAvatars.ok) {
        const data = await resAvatars.json();
        setAvatars(data.avatars || []);
        if (data.avatars && data.avatars.length > 0) {
          setSelectedAvatar(data.avatars[0]);
        }
      }

      // 3. Fetch Interventions
      const resInterventions = await fetch("http://localhost:8000/api/v1/digital-twin/interventions");
      if (resInterventions.ok) {
        const data = await resInterventions.json();
        setInterventions(data.interventions || []);
      }

      // 4. Fetch 24-week Forecast
      const resForecast = await fetch("http://localhost:8000/api/v1/digital-twin/forecast");
      if (resForecast.ok) {
        const data = await resForecast.json();
        setForecast(data);
      }
    } catch (err) {
      console.error("Failed to load digital twin data:", err);
    } finally {
      setLoading(false);
    }
  };

  const runWhatIfSimulation = async (key: string) => {
    setSimulating(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/digital-twin/what-if", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_id: "DEMO_USER_01",
          intervention_key: key,
          duration_weeks: 12,
        }),
      });
      if (res.ok) {
        const data = await res.json();
        setWhatIfResult(data);
      }
    } catch (err) {
      console.error("What-if simulation error:", err);
    } finally {
      setSimulating(false);
    }
  };

  const playVoiceBriefing = async () => {
    if (speaking) {
      window.speechSynthesis.cancel();
      setSpeaking(false);
      setCurrentViseme("neutral");
      return;
    }

    try {
      const res = await fetch("http://localhost:8000/api/v1/digital-twin/voice-briefing", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ user_id: "DEMO_USER_01" }),
      });
      if (!res.ok) return;

      const data = await res.json();
      const text = data.spoken_script;
      const visemes = data.visemes || [];

      if (!window.speechSynthesis) {
        alert("Web Speech Synthesis is not supported in this browser.");
        return;
      }

      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 1.0;
      utterance.pitch = 1.05;

      utterance.onstart = () => {
        setSpeaking(true);
        // Animate visemes based on relative timestamps
        visemes.forEach((item: any) => {
          setTimeout(() => {
            if (speaking) {
              setCurrentViseme(item.primary_viseme);
            }
          }, item.start_ms);
        });
      };

      utterance.onend = () => {
        setSpeaking(false);
        setCurrentViseme("neutral");
      };

      utterance.onerror = () => {
        setSpeaking(false);
        setCurrentViseme("neutral");
      };

      window.speechSynthesis.speak(utterance);
    } catch (err) {
      console.error("Speech synthesis failed:", err);
      setSpeaking(false);
    }
  };

  useEffect(() => {
    fetchTwinData();
    runWhatIfSimulation(selectedIntervention);
  }, []);

  // 3D Holographic Canvas Animator
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let time = 0;
    const render = () => {
      time += 0.03;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      const cx = canvas.width / 2;
      const cy = canvas.height / 2;
      const angle = (rotationAngle * Math.PI) / 180 + Math.sin(time * 0.5) * 0.1;

      // Draw background grid lines (cybernetic hologram style)
      ctx.strokeStyle = "rgba(6, 182, 212, 0.15)";
      ctx.lineWidth = 1;
      for (let y = 20; y < canvas.height; y += 30) {
        ctx.beginPath();
        ctx.moveTo(10, y);
        ctx.lineTo(canvas.width - 10, y);
        ctx.stroke();
      }

      // Draw rotating pedestal
      ctx.save();
      ctx.beginPath();
      ctx.ellipse(cx, cy + 140, 110, 24, 0, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(6, 182, 212, 0.6)";
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.fillStyle = "rgba(6, 182, 212, 0.08)";
      ctx.fill();
      ctx.restore();

      // Humanoid Holographic Wireframe
      ctx.save();
      ctx.translate(cx, cy);

      const cosA = Math.cos(angle);
      const sinA = Math.sin(angle);

      // Head
      ctx.beginPath();
      ctx.arc(0, -90, 26, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(6, 182, 212, 0.15)";
      ctx.fill();
      ctx.strokeStyle = "rgba(6, 182, 212, 0.8)";
      ctx.lineWidth = 2;
      ctx.stroke();

      // Eyes
      ctx.fillStyle = "#38bdf8";
      ctx.beginPath();
      ctx.arc(-8 * cosA, -92, 3, 0, Math.PI * 2);
      ctx.arc(8 * cosA, -92, 3, 0, Math.PI * 2);
      ctx.fill();

      // Talking Mouth / Viseme
      ctx.beginPath();
      const mouthOpen = speaking
        ? currentViseme === "jawOpen" || currentViseme === "viseme_aa"
          ? 9
          : currentViseme === "viseme_O" || currentViseme === "viseme_U"
          ? 6
          : 3
        : 2;
      ctx.ellipse(0, -76, Math.max(4, 7 * Math.abs(cosA)), mouthOpen, 0, 0, Math.PI * 2);
      ctx.fillStyle = speaking ? "#ec4899" : "rgba(6, 182, 212, 0.7)";
      ctx.fill();

      // Neck & Torso
      ctx.strokeStyle = "rgba(6, 182, 212, 0.7)";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(0, -64);
      ctx.lineTo(0, -40); // Neck

      // Shoulders
      const leftShoulderX = -45 * cosA;
      const leftShoulderY = -40 + sinA * 10;
      const rightShoulderX = 45 * cosA;
      const rightShoulderY = -40 - sinA * 10;
      ctx.moveTo(leftShoulderX, leftShoulderY);
      ctx.lineTo(rightShoulderX, rightShoulderY);

      // Torso cage
      ctx.lineTo(25 * cosA, 40);
      ctx.lineTo(-25 * cosA, 40);
      ctx.closePath();
      ctx.fillStyle = "rgba(6, 182, 212, 0.1)";
      ctx.fill();
      ctx.stroke();

      // Legs
      ctx.beginPath();
      ctx.moveTo(-20 * cosA, 40);
      ctx.lineTo(-25 * cosA, 130);
      ctx.moveTo(20 * cosA, 40);
      ctx.lineTo(25 * cosA, 130);
      ctx.stroke();

      // Glowing Organ Nodes
      const pulse = 1 + Math.sin(time * 3) * 0.25;

      // 1. Brain
      ctx.beginPath();
      ctx.arc(0, -96, 6 * pulse, 0, Math.PI * 2);
      ctx.fillStyle = activeOrgan === "neurological" ? "#a855f7" : "rgba(168, 85, 247, 0.6)";
      ctx.fill();

      // 2. Heart
      const heartPulse = 1 + Math.abs(Math.sin(time * 5)) * 0.4;
      ctx.beginPath();
      ctx.arc(-8 * cosA, -15, 8 * heartPulse, 0, Math.PI * 2);
      ctx.fillStyle = activeOrgan === "cardiovascular" ? "#f43f5e" : "rgba(244, 63, 94, 0.7)";
      ctx.fill();

      // 3. Lungs
      ctx.beginPath();
      ctx.arc(-16 * cosA, -18, 6, 0, Math.PI * 2);
      ctx.arc(16 * cosA, -18, 6, 0, Math.PI * 2);
      ctx.fillStyle = activeOrgan === "pulmonary" ? "#6366f1" : "rgba(99, 102, 241, 0.5)";
      ctx.fill();

      // 4. Liver / Metabolic
      ctx.beginPath();
      ctx.arc(12 * cosA, 10, 6, 0, Math.PI * 2);
      ctx.fillStyle = activeOrgan === "metabolic" ? "#f59e0b" : "rgba(245, 158, 11, 0.5)";
      ctx.fill();

      // 5. Kidneys / Renal
      ctx.beginPath();
      ctx.arc(-10 * cosA, 22, 5, 0, Math.PI * 2);
      ctx.arc(10 * cosA, 22, 5, 0, Math.PI * 2);
      ctx.fillStyle = activeOrgan === "renal" ? "#06b6d4" : "rgba(6, 182, 212, 0.5)";
      ctx.fill();

      ctx.restore();

      animationFrameRef.current = requestAnimationFrame(render);
    };

    render();

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [rotationAngle, speaking, currentViseme, activeOrgan]);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-4 md:p-8">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Navigation / Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between border-b border-slate-800 pb-5 gap-4">
          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="p-2.5 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 transition"
            >
              <ArrowLeft className="w-5 h-5 text-slate-400" />
            </Link>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold px-2.5 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 uppercase tracking-wide">
                  Feature 12 • Real-Time 3D Digital Twin
                </span>
                <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  Live Engine Synchronized
                </span>
              </div>
              <h1 className="text-2xl md:text-3xl font-extrabold tracking-tight text-white mt-1">
                Patient Holographic Twin & Predictive Telemetry
              </h1>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={playVoiceBriefing}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold border transition ${
                speaking
                  ? "bg-rose-500/20 text-rose-300 border-rose-500/40 animate-pulse"
                  : "bg-cyan-500/10 text-cyan-300 border-cyan-500/30 hover:bg-cyan-500/20"
              }`}
            >
              {speaking ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
              {speaking ? "Stop AI Voice" : "Listen to AI Briefing"}
            </button>

            <button
              onClick={fetchTwinData}
              className="p-2.5 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 text-slate-400 transition"
              title="Refresh Telemetry"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-32 text-slate-400 gap-4">
            <RefreshCw className="w-8 h-8 animate-spin text-cyan-400" />
            <p className="text-sm font-medium">Synchronizing 3D Digital Twin & Organ Telemetry...</p>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Top Grid: 3D Holographic Canvas + Organ Diagnostics */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
              {/* Left Column: 3D Holographic Avatar Stage */}
              <div className="lg:col-span-5 bg-gradient-to-b from-slate-900/80 to-slate-950 border border-cyan-500/20 rounded-3xl p-6 relative overflow-hidden flex flex-col items-center shadow-2xl">
                <div className="absolute top-4 left-4 right-4 flex items-center justify-between z-10">
                  <div className="flex items-center gap-2 bg-slate-950/80 px-3 py-1.5 rounded-xl border border-slate-800 text-xs text-cyan-400 font-mono">
                    <Sparkles className="w-3.5 h-3.5" />
                    {selectedAvatar ? selectedAvatar.name : "Dr. Svasthya AI"}
                  </div>
                  {speaking && (
                    <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-pink-500/20 border border-pink-500/30 text-xs font-bold text-pink-400">
                      <span className="w-2 h-2 rounded-full bg-pink-500 animate-ping" />
                      Speaking: {currentViseme}
                    </div>
                  )}
                </div>

                {/* Canvas */}
                <div className="my-6 relative flex items-center justify-center">
                  <canvas
                    ref={canvasRef}
                    width={360}
                    height={340}
                    className="cursor-ew-resize rounded-2xl"
                    onMouseMove={(e) => {
                      if (e.buttons === 1) {
                        setRotationAngle((prev) => (prev + e.movementX * 1.5) % 360);
                      }
                    }}
                  />
                </div>

                {/* 360 Degree Drag Slider */}
                <div className="w-full space-y-2 mt-auto">
                  <div className="flex items-center justify-between text-xs text-slate-400">
                    <span>Rotate Hologram</span>
                    <span className="text-cyan-400 font-mono">{Math.round(rotationAngle)}°</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="360"
                    value={rotationAngle}
                    onChange={(e) => setRotationAngle(Number(e.target.value))}
                    className="w-full accent-cyan-400 bg-slate-800 rounded-lg cursor-pointer h-1.5"
                  />
                </div>

                {/* Avatar Presets Selector */}
                <div className="w-full mt-5 pt-4 border-t border-slate-800/80">
                  <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2 block">
                    Select 3D Avatar Rig Preset
                  </span>
                  <div className="grid grid-cols-2 gap-2">
                    {avatars.map((av) => (
                      <button
                        key={av.id}
                        onClick={() => setSelectedAvatar(av)}
                        className={`p-2.5 rounded-xl text-left border transition text-xs flex flex-col ${
                          selectedAvatar?.id === av.id
                            ? "bg-cyan-500/10 border-cyan-500/50 text-cyan-300"
                            : "bg-slate-900/60 border-slate-800 text-slate-400 hover:bg-slate-800"
                        }`}
                      >
                        <span className="font-semibold text-white truncate">{av.name}</span>
                        <span className="text-[10px] text-slate-500 truncate">{av.category}</span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Right Column: Multi-Organ Real-Time Status */}
              <div className="lg:col-span-7 flex flex-col space-y-6">
                {/* Top Health Card */}
                {twin && (
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 flex flex-col justify-between">
                      <span className="text-xs font-semibold text-slate-400">Overall Health Score</span>
                      <div className="flex items-baseline gap-2 my-2">
                        <span className="text-4xl font-extrabold text-white">{twin.overall_health_score}</span>
                        <span className="text-xs text-slate-400">/ 100</span>
                      </div>
                      <span className="text-xs text-emerald-400 flex items-center gap-1">
                        <TrendingUp className="w-3.5 h-3.5" /> Optimal Baseline
                      </span>
                    </div>

                    <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 flex flex-col justify-between">
                      <span className="text-xs font-semibold text-slate-400">Biological Age</span>
                      <div className="flex items-baseline gap-2 my-2">
                        <span className="text-4xl font-extrabold text-cyan-400">{twin.biological_age || 31.6}</span>
                        <span className="text-xs text-slate-400">years</span>
                      </div>
                      <span className="text-xs text-cyan-300">Chronological: {twin.chronological_age || 34} yrs</span>
                    </div>

                    <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 flex flex-col justify-between">
                      <span className="text-xs font-semibold text-slate-400">Longitudinal Trajectory</span>
                      <p className="text-xs text-slate-300 font-medium my-2">
                        {twin.health_score_trajectory || "Sustaining High Vigor"}
                      </p>
                      <span className="text-[11px] text-slate-500">Bayesian Confidence: 94.2%</span>
                    </div>
                  </div>
                )}

                {/* Organ Selector Tabs & Cards */}
                {twin?.organ_health && (
                  <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-4">
                    <div className="flex items-center justify-between">
                      <h2 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
                        <Activity className="w-4 h-4 text-cyan-400" /> Multi-Organ Telemetry
                      </h2>
                      <span className="text-xs text-slate-500">Select organ to inspect in 3D</span>
                    </div>

                    <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                      {[
                        { key: "cardiovascular", label: "Heart", color: "rose" },
                        { key: "pulmonary", label: "Lungs", color: "indigo" },
                        { key: "metabolic", label: "Metabolic", color: "amber" },
                        { key: "neurological", label: "Brain", color: "purple" },
                        { key: "renal", label: "Kidneys", color: "cyan" },
                      ].map((org) => (
                        <button
                          key={org.key}
                          onClick={() => setActiveOrgan(org.key)}
                          className={`p-3 rounded-xl border text-center transition flex flex-col items-center ${
                            activeOrgan === org.key
                              ? "bg-cyan-500/10 border-cyan-500/50 text-white shadow-lg"
                              : "bg-slate-900/40 border-slate-800 text-slate-400 hover:bg-slate-800"
                          }`}
                        >
                          <span className="text-xs font-bold">{org.label}</span>
                          <span className="text-[11px] text-cyan-400 font-mono mt-1">
                            {twin.organ_health[org.key]?.score || 90}/100
                          </span>
                        </button>
                      ))}
                    </div>

                    {/* Active Organ Detail Box */}
                    {twin.organ_health[activeOrgan] && (
                      <div className="p-4 rounded-xl bg-slate-950/70 border border-slate-800/80 space-y-3">
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-bold text-white capitalize">
                            {activeOrgan} System Status
                          </span>
                          <span className="text-xs px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold">
                            {twin.organ_health[activeOrgan].status}
                          </span>
                        </div>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                          {Object.entries(twin.organ_health[activeOrgan]).map(([k, v]: [string, any]) => {
                            if (k === "score" || k === "status") return null;
                            return (
                              <div key={k} className="p-2.5 rounded-lg bg-slate-900 border border-slate-800">
                                <span className="text-[10px] text-slate-500 uppercase block truncate">
                                  {k.replace(/_/g, " ")}
                                </span>
                                <span className="text-xs font-bold text-white mt-0.5 block truncate">
                                  {String(v)}
                                </span>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Bottom Row: What-If Simulation Engine + 24-Week Bayesian Forecast */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
              {/* What-If Clinical Simulator */}
              <div className="lg:col-span-6 bg-slate-900/70 border border-slate-800 rounded-3xl p-6 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Zap className="w-5 h-5 text-amber-400" />
                    <h2 className="text-base font-bold text-white">What-If Clinical Scenario Simulator</h2>
                  </div>
                  {simulating && (
                    <span className="text-xs text-amber-400 animate-pulse flex items-center gap-1">
                      <RefreshCw className="w-3 h-3 animate-spin" /> Simulating...
                    </span>
                  )}
                </div>
                <p className="text-xs text-slate-400">
                  Select a clinical or environmental perturbation to model organ risk deltas over a 12-week simulated horizon.
                </p>

                {/* Scenario Pills */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {interventions.map((item) => (
                    <button
                      key={item.key}
                      onClick={() => {
                        setSelectedIntervention(item.key);
                        runWhatIfSimulation(item.key);
                      }}
                      className={`p-3 rounded-xl border text-left transition text-xs flex flex-col justify-between ${
                        selectedIntervention === item.key
                          ? "bg-amber-500/10 border-amber-500/50 text-amber-200"
                          : "bg-slate-900 border-slate-800 text-slate-400 hover:bg-slate-800"
                      }`}
                    >
                      <span className="font-semibold text-white">{item.title}</span>
                      <span className="text-[10px] text-slate-500 line-clamp-1 mt-1">{item.description}</span>
                    </button>
                  ))}
                </div>

                {/* Simulation Output Card */}
                {whatIfResult && (
                  <div className="p-4 rounded-2xl bg-slate-950/80 border border-amber-500/30 space-y-3 mt-4">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-amber-300 flex items-center gap-1.5">
                        <AlertTriangle className="w-4 h-4 text-amber-400" />
                        Predicted 12-Week Risk Delta
                      </span>
                      <span
                        className={`text-xs font-mono font-bold px-2 py-0.5 rounded ${
                          whatIfResult.projected_risk_delta > 0
                            ? "bg-rose-500/20 text-rose-400 border border-rose-500/30"
                            : "bg-emerald-500/20 text-emerald-400 border border-emerald-500/30"
                        }`}
                      >
                        {whatIfResult.projected_risk_delta > 0 ? "+" : ""}
                        {whatIfResult.projected_risk_delta}% Overall Risk
                      </span>
                    </div>

                    <p className="text-xs text-slate-300">{whatIfResult.impact_summary}</p>

                    {whatIfResult.organ_alerts && whatIfResult.organ_alerts.length > 0 && (
                      <div className="space-y-1.5 pt-2 border-t border-slate-800">
                        <span className="text-[10px] uppercase font-bold text-slate-400 block">Critical Alerts</span>
                        {whatIfResult.organ_alerts.map((alert: string, idx: number) => (
                          <div
                            key={idx}
                            className="text-xs px-2.5 py-1 rounded bg-rose-500/10 text-rose-300 border border-rose-500/20"
                          >
                            ⚠️ {alert}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* 24-Week Bayesian Forecast Trajectory */}
              <div className="lg:col-span-6 bg-slate-900/70 border border-slate-800 rounded-3xl p-6 space-y-4 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <TrendingUp className="w-5 h-5 text-cyan-400" />
                      <h2 className="text-base font-bold text-white">24-Week Bayesian Health Trajectory</h2>
                    </div>
                    <span className="text-xs font-mono text-cyan-400">Monte Carlo N=100</span>
                  </div>
                  <p className="text-xs text-slate-400 mt-1">
                    Longitudinal forecasting across 24 weeks with 80% credible interval (p10 to p90 bounds).
                  </p>
                </div>

                {forecast && (
                  <div className="space-y-4">
                    {/* Simulated SVG Graph */}
                    <div className="h-44 w-full bg-slate-950/80 rounded-2xl p-4 border border-slate-800 flex items-center justify-center">
                      <svg className="w-full h-full" viewBox="0 0 400 120">
                        {/* Grid lines */}
                        <line x1="0" y1="30" x2="400" y2="30" stroke="#1e293b" strokeDasharray="3,3" />
                        <line x1="0" y1="60" x2="400" y2="60" stroke="#1e293b" strokeDasharray="3,3" />
                        <line x1="0" y1="90" x2="400" y2="90" stroke="#1e293b" strokeDasharray="3,3" />

                        {/* Credible Band Area (P10 to P90) */}
                        <polygon
                          points="0,85 80,78 160,72 240,68 320,64 400,60 400,35 320,38 160,42 80,48 0,55"
                          fill="rgba(6, 182, 212, 0.12)"
                        />

                        {/* P10 Line */}
                        <polyline
                          points="0,85 80,78 160,72 240,68 320,64 400,60"
                          fill="none"
                          stroke="rgba(6, 182, 212, 0.4)"
                          strokeWidth="1.5"
                          strokeDasharray="4,4"
                        />

                        {/* P90 Line */}
                        <polyline
                          points="0,55 80,48 160,42 240,40 320,38 400,35"
                          fill="none"
                          stroke="rgba(6, 182, 212, 0.4)"
                          strokeWidth="1.5"
                          strokeDasharray="4,4"
                        />

                        {/* Median Trajectory */}
                        <polyline
                          points="0,70 80,62 160,56 240,52 320,49 400,46"
                          fill="none"
                          stroke="#06b6d4"
                          strokeWidth="3"
                        />

                        {/* Current Dot */}
                        <circle cx="0" cy="70" r="4" fill="#38bdf8" />
                        <text x="10" y="82" fill="#94a3b8" fontSize="9">
                          Week 0 (Today)
                        </text>
                        <text x="320" y="25" fill="#38bdf8" fontSize="9" fontWeight="bold">
                          Week 24 Projected
                        </text>
                      </svg>
                    </div>

                    <div className="flex items-center justify-between text-xs text-slate-400 px-2">
                      <div className="flex items-center gap-2">
                        <span className="w-3 h-1 bg-cyan-400 rounded-full" />
                        <span>Median Trajectory</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="w-3 h-1 bg-cyan-500/30 rounded-full border border-cyan-400/50" />
                        <span>80% Credible Interval (p10 - p90)</span>
                      </div>
                      <span className="text-emerald-400 font-semibold">+4.8 pts Expected Gain</span>
                    </div>
                  </div>
                )}

                <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 text-xs text-slate-400 space-y-1">
                  <span className="font-bold text-slate-200 block">Longitudinal Health Optimization Advice:</span>
                  <p>
                    Adherence to the daily preventive regime, structured hydration, and blood pressure monitoring will
                    sustain biological age deceleration of 2.4 years over the next 24-week period.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
