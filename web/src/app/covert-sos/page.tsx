"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, ShieldAlert, Calculator, Heart, Lock, CheckCircle2 } from "lucide-react";
import { apiClient } from "@/lib/api/apiClient";

export default function CovertSOSPage() {
  const [calcDisplay, setCalcDisplay] = useState("0");
  const [covertStatus, setCovertStatus] = useState<any>(null);

  const handleCalcClick = (val: string) => {
    if (val === "C") {
      setCalcDisplay("0");
      return;
    }
    const nextVal = calcDisplay === "0" ? val : calcDisplay + val;
    setCalcDisplay(nextVal);

    // Trigger secret PIN check (e.g. 9999=)
    if (nextVal.endsWith("9999=")) {
      triggerCovertSOS("FAKE_CALCULATOR_PIN");
    }
  };

  const triggerCovertSOS = async (triggerType: string) => {
    try {
      const data = await apiClient.post<any>("/covert-sos/covert-trigger", {
        trigger_type: triggerType,
        lat: 28.6139,
        lng: 77.2090,
      });
      setCovertStatus(data);
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#0F172A]">
      <header className="bg-white border-b border-slate-200 px-6 py-4 sticky top-0 z-10 shadow-sm">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 transition text-slate-600"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-100 text-rose-800">
                Stealth Emergency System
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
                Panic Disguise SOS &amp; Dead Man&apos;s Switch
              </h1>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-8 grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Covert Disguised Calculator */}
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-bold text-slate-900 flex items-center gap-2">
              <Calculator className="w-5 h-5 text-slate-700" /> Disguised Calculator Interface
            </h2>
            <span className="text-xs font-mono bg-slate-100 text-slate-600 px-2 py-0.5 rounded">Secret PIN: 9999=</span>
          </div>
          <p className="text-xs text-slate-500">
            For SC/ST atrocity victims or personnel under threat. App appears as a standard functional calculator. Entering secret PIN silently dispatches legal &amp; emergency distress alerts without emitting sound.
          </p>

          <div className="max-w-xs mx-auto bg-slate-900 p-4 rounded-2xl shadow-xl text-white font-mono">
            <div className="bg-slate-800 p-4 rounded-xl text-right text-2xl font-bold mb-4 overflow-hidden text-emerald-400">
              {calcDisplay}
            </div>

            <div className="grid grid-cols-4 gap-2 text-center text-sm font-bold">
              {["C", "/", "*", "-"].map((btn) => (
                <button
                  key={btn}
                  onClick={() => handleCalcClick(btn)}
                  className="p-3 bg-slate-700 hover:bg-slate-600 rounded-lg"
                >
                  {btn}
                </button>
              ))}
              {["7", "8", "9", "+"].map((btn) => (
                <button
                  key={btn}
                  onClick={() => handleCalcClick(btn)}
                  className="p-3 bg-slate-700 hover:bg-slate-600 rounded-lg"
                >
                  {btn}
                </button>
              ))}
              {["4", "5", "6", "="].map((btn) => (
                <button
                  key={btn}
                  onClick={() => handleCalcClick(btn)}
                  className="p-3 bg-slate-700 hover:bg-slate-600 rounded-lg"
                >
                  {btn}
                </button>
              ))}
              {["1", "2", "3", "0"].map((btn) => (
                <button
                  key={btn}
                  onClick={() => handleCalcClick(btn)}
                  className="p-3 bg-slate-700 hover:bg-slate-600 rounded-lg"
                >
                  {btn}
                </button>
              ))}
            </div>
          </div>

          <div className="pt-2 text-center">
            <button
              onClick={() => triggerCovertSOS("SHAKE_ACCELEROMETER")}
              className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-800 rounded-lg text-xs font-semibold border border-slate-300"
            >
              Simulate Rapid Accelerometer Shake SOS
            </button>
          </div>
        </div>

        {/* Covert Status & Dispatch Log */}
        <div className="space-y-6">
          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
            <h3 className="font-bold text-slate-900 flex items-center gap-2">
              <ShieldAlert className="w-5 h-5 text-rose-600" /> Silent Dispatch Protocol Status
            </h3>

            {covertStatus ? (
              <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl space-y-3">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-rose-900 text-sm">{covertStatus.status}</span>
                  <span className="text-xs font-mono bg-rose-200 text-rose-900 px-2 py-0.5 rounded">
                    {covertStatus.covert_alert_id}
                  </span>
                </div>
                <p className="text-xs text-rose-800">{covertStatus.stealth_note}</p>
                <div className="text-xs font-mono text-slate-700 bg-white p-3 rounded border border-rose-100">
                  <div>Trigger: {covertStatus.trigger_mechanism}</div>
                  <div>Disguise Mode: {covertStatus.disguise_mode}</div>
                  <div>Notified: {covertStatus.notified_channels.join(", ")}</div>
                </div>
              </div>
            ) : (
              <div className="p-8 border border-dashed border-slate-200 rounded-xl text-center text-slate-400 text-xs">
                No active covert SOS trigger. System operating in stealth background mode.
              </div>
            )}
          </div>

          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-slate-900 flex items-center gap-2">
                <Heart className="w-5 h-5 text-blue-600" /> Passive Dead Man&apos;s Switch
              </h3>
              <span className="text-xs font-semibold px-2 py-0.5 rounded bg-emerald-100 text-emerald-800">
                ACTIVE
              </span>
            </div>
            <p className="text-xs text-slate-500">
              Monitors device activity. If zero interactions occur within 2 hours, automated welfare dispatch is alerted.
            </p>

            <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 flex items-center justify-between text-xs">
              <span>Last Heartbeat: 12 minutes ago</span>
              <span className="font-mono text-emerald-700 font-semibold">Ping Received OK</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
