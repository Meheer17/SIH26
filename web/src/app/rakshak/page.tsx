'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import apiClient from '@/lib/api/apiClient';

interface BurnoutRecord {
  id: string;
  deployment_days: number;
  leave_gap_ratio: number;
  duty_hours_per_week: number;
  assessment_score: number;
  burnout_score: number;
  risk_tier: string;
  contributing_factors: string[];
  recommended_actions: string[];
  voice_journal_text?: string;
  created_at: string;
}

interface HeatmapItem {
  unit: string;
  personnel_count: number;
  average_burnout_index: number;
  critical_risk_count: number;
  high_risk_count: number;
  status: string;
}

export default function RakshakMitraPage() {
  const { user } = useAuth();
  
  // Soldier checkin state
  const [deploymentDays, setDeploymentDays] = useState(60);
  const [leaveGapRatio, setLeaveGapRatio] = useState(0.5);
  const [dutyHours, setDutyHours] = useState(56);
  const [assessmentScore, setAssessmentScore] = useState(12);
  const [voiceText, setVoiceText] = useState('Feeling fatigued after successive long night watches. Sleep is irregular.');

  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<BurnoutRecord[]>([]);
  const [heatmap, setHeatmap] = useState<HeatmapItem[]>([]);
  const [latestResult, setLatestResult] = useState<BurnoutRecord | null>(null);

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get('/apps/rakshak/burnout');
      setHistory(data);
      if (data.length > 0) {
        setLatestResult(data[0]);
      }
    } catch (e) {
      console.error('Failed to load burnout history', e);
    }
  };

  const fetchHeatmap = async () => {
    try {
      const data = await apiClient.get('/apps/rakshak/heatmap');
      setHeatmap(data);
    } catch (e) {
      console.error('Failed to load commander heatmap', e);
    }
  };

  useEffect(() => {
    if (user) {
      fetchHistory();
      // Only fetch heatmap if user role matches Welfare Officer/Admin
      const userRoles = user.mapped_roles || [user.primary_role];
      const isWelfare = userRoles.some(role => role === 'WELFARE_OFFICER' || role === 'SYSTEM_ADMIN');
      if (isWelfare) {
        fetchHeatmap();
      }
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await apiClient.post('/apps/rakshak/burnout', {
        deployment_days: deploymentDays,
        leave_gap_ratio: leaveGapRatio,
        duty_hours_per_week: dutyHours,
        assessment_score: assessmentScore,
        voice_journal_text: voiceText,
      });
      setLatestResult(res);
      fetchHistory();
      alert('Wellbeing check-in submitted successfully!');
    } catch (err: any) {
      alert(err.message || 'Checkin submission failed');
    } finally {
      setLoading(false);
    }
  };

  if (!user) {
    return <div className="p-8 text-center text-xs text-slate-500 font-bold">Please log in to view RakshakMitra</div>;
  }

  const userRoles = user.mapped_roles || [user.primary_role];
  const isWelfare = userRoles.some(
    (role) => role === 'WELFARE_OFFICER' || role === 'SYSTEM_ADMIN'
  );

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        
        <header className="flex items-center justify-between bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3">
            <span className="text-2xl">🎖️</span>
            <div>
              <h1 className="text-xl font-extrabold text-slate-900">RakshakMitra Command Core</h1>
              <p className="text-xs text-slate-500">Armed Forces Stress &amp; Burnout Prediction</p>
            </div>
          </div>
          <div className="flex gap-2">
            <div className="px-3.5 py-2 bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-bold rounded-xl flex items-center">
              Active Mode: {isWelfare ? '🧑‍✈️ Commander Portal' : '🎖️ Soldier Terminal'}
            </div>
            <Link href="/dashboard" className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition">
              &larr; Dashboard
            </Link>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
          
          {/* Left Column: Form (only for soldiers/all) or Heatmap (only for commanders) */}
          <div className="md:col-span-6 space-y-6">
            
            {isWelfare ? (
              // Heatmap list
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div>
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Unit Wellness Heatmap</h2>
                  <p className="text-[10px] text-slate-400">Anonymized aggregates. Personal records are strictly protected.</p>
                </div>
                <div className="space-y-3">
                  {heatmap.map((item) => {
                    const isRed = item.status === 'RED';
                    const isOrange = item.status === 'ORANGE';
                    return (
                      <div key={item.unit} className="p-4 rounded-xl border bg-slate-50 flex items-center justify-between">
                        <div className="space-y-1">
                          <div className="font-bold text-xs text-slate-900">{item.unit}</div>
                          <div className="text-[10px] text-slate-500">Personnel count: {item.personnel_count} soldiers</div>
                        </div>
                        <div className="text-right">
                          <div className={`font-black text-sm ${isRed ? 'text-rose-600' : isOrange ? 'text-amber-600' : 'text-emerald-600'}`}>
                            Burnout Index: {item.average_burnout_index}
                          </div>
                          <div className="text-[9px] text-slate-400">Critical: {item.critical_risk_count} | High: {item.high_risk_count}</div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            ) : (
              // Checkin form
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Wellbeing Check-in</h2>
                
                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Days Deployed</label>
                    <input
                      type="number"
                      value={deploymentDays}
                      onChange={(e) => setDeploymentDays(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Leave Gap Ratio (0.0 to 1.0)</label>
                    <input
                      type="number"
                      step="0.1"
                      min="0"
                      max="1"
                      value={leaveGapRatio}
                      onChange={(e) => setLeaveGapRatio(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Weekly Duty Workload (h)</label>
                    <input
                      type="number"
                      value={dutyHours}
                      onChange={(e) => setDutyHours(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Self-Assessment Score (PHQ/GAD)</label>
                    <input
                      type="number"
                      value={assessmentScore}
                      onChange={(e) => setAssessmentScore(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Voice Mood Journal Entry (Voice diary transcript)</label>
                  <textarea
                    required
                    value={voiceText}
                    onChange={(e) => setVoiceText(e.target.value)}
                    rows={3}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                    placeholder="Describe how you are feeling, sleep trends, or mental load..."
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Submitting stress indicators...' : 'Submit Wellness Log'}
                </button>
              </form>
            )}

          </div>

          {/* Right Column: Assessment results / past soldier records */}
          <div className="md:col-span-6 space-y-6">
            {latestResult ? (
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Wellness Scorecard</h2>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Burnout Index</span>
                    <div className="text-3xl font-black text-emerald-700">{latestResult.burnout_score}</div>
                  </div>
                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Risk Severity</span>
                    <div className="text-xl font-black text-slate-700 mt-1">{latestResult.risk_tier}</div>
                  </div>
                </div>

                <div className="space-y-1 text-xs">
                  <span className="block text-slate-400 font-bold uppercase text-[9px]">Contributing stress factors</span>
                  <ul className="list-disc list-inside space-y-1 text-slate-600 bg-slate-50 p-3 rounded-xl border">
                    {latestResult.contributing_factors.map((f, index) => (
                      <li key={index}>{f}</li>
                    ))}
                  </ul>
                </div>

                <div className="space-y-1 text-xs">
                  <span className="block text-slate-400 font-bold uppercase text-[9px]">Recommended Welfare Actions</span>
                  <div className="flex flex-wrap gap-2">
                    {latestResult.recommended_actions.map((act, index) => (
                      <span key={index} className="px-2.5 py-1 bg-emerald-50 border border-emerald-200 text-emerald-800 text-[10px] font-bold rounded-xl">
                        {act}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                {isWelfare ? 'Units summary maps loaded. Scroll to inspect.' : 'Submit a wellbeing assessment checkin to see index scores.'}
              </div>
            )}

            {!isWelfare && (
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-3">
                <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Assessment History</h2>
                <div className="divide-y max-h-60 overflow-y-auto pr-1">
                  {history.length > 0 ? (
                    history.map((h) => (
                      <div key={h.id} className="py-2.5 flex items-center justify-between text-xs">
                        <div>
                          <div className="font-bold text-slate-800">Burnout: {h.burnout_score} ({h.risk_tier})</div>
                          <div className="text-[10px] text-slate-400">{new Date(h.created_at).toLocaleString()}</div>
                        </div>
                        <div className="text-right text-[10px] text-slate-500 italic max-w-[200px] truncate">
                          {h.voice_journal_text || 'No voice notes'}
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="py-4 text-center text-xs text-slate-400 italic">No past wellness assessments logged.</div>
                  )}
                </div>
              </div>
            )}

          </div>

        </div>

      </div>
    </div>
  );
}
