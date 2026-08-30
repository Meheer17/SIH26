'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import apiClient from '@/lib/api/apiClient';

interface VitalRecord {
  id: string;
  heart_rate: number;
  spo2: number;
  body_temp_c: number;
  env_temp_c: number;
  humidity_percent: number;
  activity_level: string;
  time_since_water_mins: number;
  heat_stress_score: number;
  dehydration_risk_percent: number;
  severity: string;
  recommendations: string;
  created_at: string;
}

export default function ArogyaSathiPage() {
  const { user } = useAuth();
  const [heartRate, setHeartRate] = useState(72);
  const [spo2, setSpo2] = useState(98);
  const [bodyTemp, setBodyTemp] = useState(37.0);
  const [envTemp, setEnvTemp] = useState(38.0);
  const [humidity, setHumidity] = useState(55);
  const [activity, setActivity] = useState('moderate');
  const [waterMins, setWaterMins] = useState(30);

  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<VitalRecord[]>([]);
  const [latestResult, setLatestResult] = useState<VitalRecord | null>(null);
  const [sosStatus, setSosStatus] = useState<string | null>(null);

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get('/apps/arogya/vitals');
      setHistory(data);
      if (data.length > 0) {
        setLatestResult(data[0]);
      }
    } catch (e) {
      console.error('Failed to load vitals history', e);
    }
  };

  useEffect(() => {
    if (user) {
      fetchHistory();
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await apiClient.post('/apps/arogya/vitals', {
        heart_rate: heartRate,
        spo2: spo2,
        body_temp_c: bodyTemp,
        env_temp_c: envTemp,
        humidity_percent: humidity,
        activity_level: activity,
        time_since_water_mins: waterMins,
      });
      setLatestResult(res);
      fetchHistory();
      if (res.severity === 'CRITICAL') {
        alert('⚠️ CRITICAL STRESS LEVEL DETECTED! Automatically triggering Emergency SOS...');
        await triggerSOS();
      }
    } catch (err: any) {
      alert(err.message || 'Failed to submit vitals');
    } finally {
      setLoading(false);
    }
  };

  const triggerSOS = async () => {
    setSosStatus('triggering');
    try {
      const res = await apiClient.post('/alerts/dispatch', {
        app_context: 'arogya_sathi',
        severity: 'CRITICAL_SOS',
        title: 'AROGYASATHI EMERGENCY SOS',
        message: `SOS ALERT! Critical health stress event triggered by user. Vitals snapshot: HR ${heartRate} bpm, Body Temp ${bodyTemp}°C, Env Temp ${envTemp}°C.`,
        recipients: ['Emergency Contact Pool', 'Local Hospital Rescue Cell'],
        metadata: {
          heart_rate: heartRate,
          body_temp_c: bodyTemp,
          env_temp_c: envTemp,
        },
      });
      setSosStatus('DISPATCHED');
      alert(`SOS Alert successfully dispatched! ID: ${res.alert.alert_id}`);
    } catch (err: any) {
      setSosStatus('error');
      alert(err.message || 'Failed to trigger SOS');
    }
  };

  if (!user) {
    return <div className="p-8 text-center text-xs text-slate-500 font-bold">Please log in to view ArogyaSathi</div>;
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        <header className="flex items-center justify-between bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3">
            <span className="text-2xl">🫀</span>
            <div>
              <h1 className="text-xl font-extrabold text-slate-900">ArogyaSathi Risk Companion</h1>
              <p className="text-xs text-slate-500">Heat Stress and Dehydration Index Monitor</p>
            </div>
          </div>
          <Link href="/dashboard" className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition">
            &larr; Dashboard
          </Link>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
          {/* Form Column */}
          <form onSubmit={handleSubmit} className="md:col-span-5 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Manual Vitals Input</h2>
            
            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <label className="block text-slate-600 font-bold mb-1">Heart Rate (bpm)</label>
                <input
                  type="number"
                  value={heartRate}
                  onChange={(e) => setHeartRate(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                  required
                />
              </div>
              <div>
                <label className="block text-slate-600 font-bold mb-1">Blood Oxygen SpO2 (%)</label>
                <input
                  type="number"
                  value={spo2}
                  onChange={(e) => setSpo2(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <label className="block text-slate-600 font-bold mb-1">Body Temp (°C)</label>
                <input
                  type="number"
                  step="0.1"
                  value={bodyTemp}
                  onChange={(e) => setBodyTemp(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                  required
                />
              </div>
              <div>
                <label className="block text-slate-600 font-bold mb-1">Ambient Temp (°C)</label>
                <input
                  type="number"
                  step="0.1"
                  value={envTemp}
                  onChange={(e) => setEnvTemp(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <label className="block text-slate-600 font-bold mb-1">Humidity (%)</label>
                <input
                  type="number"
                  value={humidity}
                  onChange={(e) => setHumidity(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                  required
                />
              </div>
              <div>
                <label className="block text-slate-600 font-bold mb-1">Water Intake (mins ago)</label>
                <input
                  type="number"
                  value={waterMins}
                  onChange={(e) => setWaterMins(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs text-slate-600 font-bold mb-1">Physical Activity Level</label>
              <select
                value={activity}
                onChange={(e) => setActivity(e.target.value)}
                className="w-full px-3 py-2.5 bg-slate-50 border rounded-xl text-xs"
              >
                <option value="resting">Resting / Inactive</option>
                <option value="moderate">Moderate Workload</option>
                <option value="strenuous">Strenuous Effort</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
            >
              {loading ? 'Evaluating...' : 'Record & Calculate Stress'}
            </button>

            <button
              type="button"
              onClick={triggerSOS}
              disabled={sosStatus === 'triggering'}
              className="w-full py-3 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs rounded-xl shadow-md transition flex items-center justify-center gap-1.5"
            >
              <span>🆘 Trigger Emergency SOS</span>
            </button>
          </form>

          {/* Results Column */}
          <div className="md:col-span-7 space-y-6">
            {latestResult ? (
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Vitals Scorecard</h2>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Heat Stress Score</span>
                    <div className="text-3xl font-black text-indigo-700">{latestResult.heat_stress_score}</div>
                  </div>
                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Dehydration Risk</span>
                    <div className="text-3xl font-black text-sky-700">{latestResult.dehydration_risk_percent}%</div>
                  </div>
                </div>

                <div className={`p-4 rounded-xl border flex items-center gap-3 font-bold ${
                  latestResult.severity === 'CRITICAL' ? 'bg-red-50 border-red-200 text-red-800 animate-pulse' :
                  latestResult.severity === 'HIGH' ? 'bg-amber-50 border-amber-200 text-amber-800' :
                  latestResult.severity === 'MODERATE' ? 'bg-sky-50 border-sky-200 text-sky-850' :
                  'bg-emerald-50 border-emerald-200 text-emerald-800'
                }`}>
                  <div className="text-xl">Risk Tier: {latestResult.severity}</div>
                </div>

                <div className="space-y-1 text-xs">
                  <div className="font-bold text-slate-700">Health Advisory Note:</div>
                  <p className="text-slate-600 italic bg-slate-50 p-3 rounded-xl border">{latestResult.recommendations}</p>
                </div>
              </div>
            ) : (
              <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                Input your vital signs to generate stress scorecard.
              </div>
            )}

            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-3">
              <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Log History</h2>
              <div className="divide-y max-h-60 overflow-y-auto pr-1">
                {history.length > 0 ? (
                  history.map((h) => (
                    <div key={h.id} className="py-2.5 flex items-center justify-between text-xs">
                      <div>
                        <div className="font-bold text-slate-800">Stress score: {h.heat_stress_score} ({h.severity})</div>
                        <div className="text-[10px] text-slate-400">{new Date(h.created_at).toLocaleString()}</div>
                      </div>
                      <div className="text-right font-mono text-slate-500 text-[10px]">
                        HR {h.heart_rate} | SpO2 {h.spo2}%
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="py-4 text-center text-xs text-slate-400 italic">No past vital records logged.</div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
