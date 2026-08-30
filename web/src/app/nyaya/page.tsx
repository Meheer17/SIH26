'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import apiClient from '@/lib/api/apiClient';

interface DistressRecord {
  id: string;
  sentiment_score: number;
  case_stage: string;
  days_since_incident: number;
  recent_checkin_responses: string;
  distress_score: number;
  distress_level: string;
  escalation_status: string;
  proactive_outreach_needed?: boolean;
  created_at: string;
}

interface EscalationRecord {
  id: string;
  user_id: string;
  patient_name: string;
  case_stage: string;
  distress_score: number;
  distress_level: string;
  escalation_status: string;
  created_at: string;
}

export default function NyayaSahayPage() {
  const { user } = useAuth();
  
  // Victim wellbeing checkin form
  const [sentiment, setSentiment] = useState(-0.3); // sliding scale -1.0 to 1.0
  const [caseStage, setCaseStage] = useState('trial');
  const [daysSince, setDaysSince] = useState(90);
  const [responsesText, setResponsesText] = useState('Feeling very stressed and threatened before the upcoming trial adjournment date.');

  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<DistressRecord[]>([]);
  const [escalations, setEscalations] = useState<EscalationRecord[]>([]);
  const [latestResult, setLatestResult] = useState<DistressRecord | null>(null);

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get('/apps/nyaya/distress');
      setHistory(data);
      if (data.length > 0) {
        setLatestResult(data[0]);
      }
    } catch (e) {
      console.error('Failed to load distress check-ins history', e);
    }
  };

  const fetchEscalations = async () => {
    try {
      const data = await apiClient.get('/apps/nyaya/escalations');
      setEscalations(data);
    } catch (e) {
      console.error('Failed to load counselor escalations', e);
    }
  };

  useEffect(() => {
    if (user) {
      fetchHistory();
      const userRoles = user.mapped_roles || [user.primary_role];
      const isCounselor = userRoles.some(role => role === 'COUNSELOR' || role === 'SYSTEM_ADMIN');
      if (isCounselor) {
        fetchEscalations();
      }
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await apiClient.post('/apps/nyaya/distress', {
        sentiment_score: sentiment,
        case_stage: caseStage,
        days_since_incident: daysSince,
        recent_checkin_responses: responsesText,
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

  const acknowledgeCase = async (id: string) => {
    try {
      await apiClient.post(`/alerts/${id}/acknowledge`);
      alert('Escalated distress case successfully acknowledged and logged.');
      fetchEscalations();
    } catch (err: any) {
      alert(err.message || 'Failed to acknowledge alert');
    }
  };

  if (!user) {
    return <div className="p-8 text-center text-xs text-slate-500 font-bold">Please log in to view NyayaSahay</div>;
  }

  const userRoles = user.mapped_roles || [user.primary_role];
  const isCounselor = userRoles.some(
    (role) => role === 'COUNSELOR' || role === 'SYSTEM_ADMIN'
  );

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        
        <header className="flex items-center justify-between bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3">
            <span className="text-2xl">⚖️</span>
            <div>
              <h1 className="text-xl font-extrabold text-slate-900">NyayaSahay Outreach</h1>
              <p className="text-xs text-slate-500">SC/ST Atrocity Victim Support &amp; Distress Tracking</p>
            </div>
          </div>
          <div className="flex gap-2">
            <div className="px-3.5 py-2 bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-bold rounded-xl flex items-center">
              Active Mode: {isCounselor ? '⚖️ Counselor Desk' : '👤 Victim Wellbeing Checkin'}
            </div>
            <Link href="/dashboard" className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition">
              &larr; Dashboard
            </Link>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
          
          {/* Left Column: Form (Victims) or Counselor escalations list */}
          <div className="md:col-span-6 space-y-6">
            
            {isCounselor ? (
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div>
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Escalation Case alerts</h2>
                  <p className="text-[10px] text-slate-400">Distress spike alerts requiring counselor support outreach.</p>
                </div>
                <div className="space-y-3">
                  {escalations.map((item) => (
                    <div key={item.id} className="p-4 rounded-xl border bg-slate-50 flex items-center justify-between">
                      <div className="space-y-1">
                        <div className="font-bold text-xs text-slate-900">Patient: {item.patient_name}</div>
                        <div className="text-[10px] text-rose-600 font-bold uppercase">Distress Score: {item.distress_score} ({item.distress_level})</div>
                        <div className="text-[9px] text-slate-400">Legal stage: {item.case_stage}</div>
                      </div>
                      <button
                        onClick={() => acknowledgeCase(item.id)}
                        className="px-3.5 py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-bold text-[10px] rounded-xl transition"
                      >
                        Acknowledge
                      </button>
                    </div>
                  ))}
                  {escalations.length === 0 && (
                    <div className="py-8 text-center text-xs text-slate-400 italic">No escalated distress cases found.</div>
                  )}
                </div>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Wellbeing Assessment</h2>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Sentiment slider (Self-reported mood: -1.0 is highly distressed, 1.0 is stable)
                  </label>
                  <div className="flex items-center gap-3">
                    <span className="text-xs">😢</span>
                    <input
                      type="range"
                      min="-1"
                      max="1"
                      step="0.1"
                      value={sentiment}
                      onChange={(e) => setSentiment(Number(e.target.value))}
                      className="w-full"
                    />
                    <span className="text-xs">🙂</span>
                    <span className="font-mono text-xs text-slate-500 font-bold">{sentiment}</span>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Legal Case Milestone</label>
                    <select
                      value={caseStage}
                      onChange={(e) => setCaseStage(e.target.value)}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                    >
                      <option value="fir">FIR Registration</option>
                      <option value="chargesheet">Chargesheet Filed</option>
                      <option value="trial">Trial Proceedings</option>
                      <option value="adjournment">Court Adjournment</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Days since Incident</label>
                    <input
                      type="number"
                      value={daysSince}
                      onChange={(e) => setDaysSince(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Wellness Diary (Speech/text checkin log)</label>
                  <textarea
                    required
                    value={responsesText}
                    onChange={(e) => setResponsesText(e.target.value)}
                    rows={3}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                    placeholder="Tell us how you are coping with the case adjournments or threat levels..."
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Evaluating distress score...' : 'Log Wellbeing Checkin'}
                </button>
              </form>
            )}

          </div>

          {/* Right Column: Distress results / wellbeing trends */}
          <div className="md:col-span-6 space-y-6">
            
            {latestResult ? (
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Wellbeing Trends</h2>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Distress Score</span>
                    <div className="text-3xl font-black text-purple-700">{latestResult.distress_score}</div>
                  </div>
                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Outreach Status</span>
                    <div className="text-xs font-bold text-slate-700 mt-2">
                      {latestResult.proactive_outreach_needed ? (
                        <span className="text-rose-600 font-extrabold uppercase">Outreach Active</span>
                      ) : (
                        <span className="text-emerald-600 font-extrabold uppercase">Standard Monitoring</span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="space-y-1 text-xs">
                  <span className="block text-slate-400 font-bold uppercase text-[9px]">Case Timeline Milestone Correlation</span>
                  <div className="p-3 bg-slate-50 rounded-xl border italic text-slate-600">
                    Distress score evaluated at stage: <span className="font-bold text-indigo-700 uppercase">{latestResult.case_stage}</span>
                  </div>
                </div>

                {latestResult.escalation_status !== 'NONE' && (
                  <div className="p-3.5 bg-rose-50 border border-rose-200 text-rose-800 text-xs font-medium rounded-xl">
                    ⚠️ Alert: Distress score exceeded threshold. Multi-tier Case Escalation dispatched to District protection node.
                  </div>
                )}
              </div>
            ) : (
              <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                {isCounselor ? 'Outreach list loaded. Scroll to inspect.' : 'Submit a wellbeing checkin to display your dynamic distress level.'}
              </div>
            )}

            {!isCounselor && (
              <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-3">
                <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Outreach Diary log</h2>
                <div className="divide-y max-h-60 overflow-y-auto pr-1">
                  {history.length > 0 ? (
                    history.map((h) => (
                      <div key={h.id} className="py-2.5 flex items-center justify-between text-xs">
                        <div>
                          <div className="font-bold text-slate-800">Distress Score: {h.distress_score} ({h.distress_level})</div>
                          <div className="text-[10px] text-slate-400">{new Date(h.created_at).toLocaleString()}</div>
                        </div>
                        <div className="text-right text-[10px] text-slate-500 italic max-w-[200px] truncate">
                          {h.recent_checkin_responses}
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="py-4 text-center text-xs text-slate-400 italic">No past check-ins logged.</div>
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
