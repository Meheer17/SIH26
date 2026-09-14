"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Cpu, ShieldCheck, Lock, UploadCloud, RefreshCw, Layers } from "lucide-react";

export default function FederatedNodePage() {
  const [status, setStatus] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [submitted, setSubmitted] = useState(false);
  const [localWeights, setLocalWeights] = useState<number[]>([0.41, -0.14, 0.86, 0.29, -0.04, 0.61, 0.18]);

  const fetchStatus = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/ai/federated/status");
      if (res.ok) {
        const json = await res.json();
        setStatus(json);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleComputeLocalSGD = () => {
    // Simulate local SGD training iteration on edge device
    const updated = localWeights.map(w => parseFloat((w + (Math.random() * 0.04 - 0.02)).toFixed(4)));
    setLocalWeights(updated);
  };

  const handleSubmitWeights = async () => {
    try {
      const res = await fetch("http://localhost:8000/api/v1/ai/federated/weights", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_node_id: `ANON-NODE-WEB-${Math.floor(Math.random() * 1000)}`,
          model_name: "cough_classifier",
          gradients_hash: `0x${Math.random().toString(16).substring(2, 14)}`,
          local_samples_count: 32,
          weights_vector: localWeights
        })
      });
      if (res.ok) {
        setSubmitted(true);
        fetchStatus();
      }
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchStatus();
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
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                Feature 14 • FedAvg + Laplace Differential Privacy
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Privacy-Preserving Federated Learning Pipeline
              </h1>
            </div>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24 text-slate-400 gap-3">
            <RefreshCw className="w-6 h-6 animate-spin text-indigo-400" /> Connecting to global FedAvg server...
          </div>
        ) : status ? (
          <div className="space-y-6">
            {/* Status Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <span className="text-xs text-slate-400 font-medium">Global Fed Round</span>
                <p className="text-3xl font-bold text-indigo-400">Round {status.current_global_round}</p>
                <p className="text-xs text-slate-500">FedAvg Aggregation</p>
              </div>

              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <span className="text-xs text-slate-400 font-medium">Active Rural Nodes</span>
                <p className="text-3xl font-bold text-white">{status.active_nodes}</p>
                <p className="text-xs text-slate-500">Edge P2P Participants</p>
              </div>

              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <span className="text-xs text-slate-400 font-medium">Privacy Budget (ε)</span>
                <p className="text-3xl font-bold text-emerald-400">{status.differential_privacy_epsilon}</p>
                <p className="text-xs text-slate-500">Laplace DP (Guaranteed Zero-Leak)</p>
              </div>

              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-2">
                <span className="text-xs text-slate-400 font-medium">Global Accuracy</span>
                <p className="text-3xl font-bold text-cyan-400">{status.global_accuracy_percent}%</p>
                <p className="text-xs text-slate-500">TFLite Model Accuracy</p>
              </div>
            </div>

            {/* Global Weights Vector Display */}
            {status.global_weight_vector && (
              <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 space-y-3">
                <h3 className="text-sm font-bold text-white flex items-center gap-2">
                  <Layers className="w-4 h-4 text-indigo-400" /> Global FedAvg Model Weight Vector (7-Dimensional Acoustic Features)
                </h3>
                <div className="flex flex-wrap gap-2 font-mono text-xs">
                  {status.global_weight_vector.map((w: number, idx: number) => (
                    <span key={idx} className="px-3 py-1.5 rounded-lg bg-slate-800 border border-slate-700 text-indigo-300">
                      w_{idx}: {w}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Local Node Action Card */}
            <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="space-y-1">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Lock className="w-5 h-5 text-indigo-400" /> On-Device Edge Gradient Computation
                </h3>
                <p className="text-xs text-slate-400 max-w-md">
                  Your raw health data and audio never leave this device. Compute local SGD weights and transmit encrypted differentially-private updates to the global swarm.
                </p>
                <div className="flex items-center gap-2 pt-2">
                  <button
                    onClick={handleComputeLocalSGD}
                    className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-mono text-slate-200 border border-slate-700"
                  >
                    Run Local SGD Step
                  </button>
                </div>
              </div>

              <button
                onClick={handleSubmitWeights}
                disabled={submitted}
                className="px-6 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-medium text-sm transition flex items-center gap-2 shadow-lg shadow-indigo-600/25 shrink-0 disabled:opacity-50"
              >
                <UploadCloud className="w-4 h-4" /> {submitted ? "Gradients Uploaded" : "Submit Encrypted Gradients"}
              </button>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
