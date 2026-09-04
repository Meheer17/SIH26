"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Gift, Award, CheckCircle2, Sparkles, RefreshCw } from "lucide-react";

export default function HealthKarmaPage() {
  const [karmaData, setKarmaData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchKarma = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/apps/karma");
      if (res.ok) {
        const json = await res.json();
        setKarmaData(json);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchKarma();
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
                Feature 18 • Gamified Healthcare Rewards
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Health Karma & Community Incentives
              </h1>
            </div>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-24 text-slate-400 gap-3">
            <RefreshCw className="w-6 h-6 animate-spin text-amber-400" /> Fetching your Health Karma balance...
          </div>
        ) : karmaData ? (
          <div className="space-y-6">
            {/* Balance Banner */}
            <div className="bg-gradient-to-r from-amber-500/20 via-slate-900 to-amber-600/10 border border-amber-500/30 rounded-3xl p-8 flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="space-y-2 text-center md:text-left">
                <span className="text-xs font-bold text-amber-400 uppercase tracking-widest bg-amber-500/10 px-3 py-1 rounded-full border border-amber-500/20">
                  {karmaData.tier}
                </span>
                <h2 className="text-4xl font-extrabold text-white">{karmaData.karma_points_balance} <span className="text-lg font-medium text-amber-400">Karma Points</span></h2>
                <p className="text-xs text-slate-300">Earned by adhering to medications, sharing epidemic symptom reports, and completing check-ins.</p>
              </div>

              <div className="flex flex-wrap gap-2">
                {karmaData.badges_earned.map((badge: string, idx: number) => (
                  <span key={idx} className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-900 border border-slate-800 text-xs font-medium text-amber-200">
                    <Award className="w-4 h-4 text-amber-400" /> {badge}
                  </span>
                ))}
              </div>
            </div>

            {/* Rewards Marketplace */}
            <div className="space-y-4">
              <h3 className="text-base font-bold text-white flex items-center gap-2">
                <Gift className="w-5 h-5 text-amber-400" /> Redeemable Healthcare Rewards
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {karmaData.redeemable_rewards.map((reward: any) => (
                  <div key={reward.id} className="bg-slate-900/70 border border-slate-800 rounded-2xl p-5 space-y-4 flex flex-col justify-between">
                    <div className="space-y-1.5">
                      <span className="text-[10px] font-semibold text-amber-400 uppercase tracking-wider">{reward.partner}</span>
                      <h4 className="text-sm font-bold text-white">{reward.title}</h4>
                    </div>

                    <div className="flex items-center justify-between border-t border-slate-800/80 pt-3">
                      <span className="text-sm font-bold text-amber-300">{reward.cost_points} Points</span>
                      <button className="px-3.5 py-1.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs transition shadow-lg shadow-amber-500/20">
                        Redeem Code
                      </button>
                    </div>
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
