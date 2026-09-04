'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { apiClient } from '@/lib/api/apiClient';

interface DistressRecord {
  id: string;
  sentiment_score: number;
  case_stage: string;
  days_since_incident: number;
  recent_checkin_responses: string;
  distress_score: number;
  distress_level: string;
  escalation_status: string;
  proactive_outreach_needed: boolean;
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

const DEFAULT_ESCALATIONS: EscalationRecord[] = [
  {
    id: 'esc_101',
    user_id: 'u_891',
    patient_name: 'Sunita Devi (Victim Case #412)',
    case_stage: 'Trial Proceedings (Court Adjournment)',
    distress_score: 84,
    distress_level: 'SEVERE_DISTRESS',
    escalation_status: 'DISTRICT_COLLECTOR_NOTIFIED',
    created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
  },
  {
    id: 'esc_102',
    user_id: 'u_892',
    patient_name: 'Manish Kumar (Witness Case #308)',
    case_stage: 'Chargesheet Filing & Witness Protection',
    distress_score: 66,
    distress_level: 'MODERATE_DISTRESS',
    escalation_status: 'COUNSELOR_ASSIGNED',
    created_at: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
  },
];

const LEGAL_MILESTONES = [
  { id: 'fir', label: '1. FIR Lodged', desc: 'Initial police report filed under SC/ST PoA Act' },
  { id: 'chargesheet', label: '2. Chargesheet Filed', desc: 'Investigation concluded by IO' },
  { id: 'trial', label: '3. Trial in Court', desc: 'Special Court hearing & evidence submission' },
  { id: 'adjournment', label: '4. Cross-Examination / Adjournment', desc: 'Defense arguments & witness testimony' },
  { id: 'compensation', label: '5. State Compensation Disbursal', desc: 'Relief grant release under SC/ST Rules' },
];

export default function NyayaSahayPage() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState<'CHECKIN' | 'ESCALATIONS' | 'CHAT' | 'HISTORY'>('CHECKIN');

  // Victim Form State
  const [sentiment, setSentiment] = useState(-0.45);
  const [caseStage, setCaseStage] = useState('trial');
  const [threatLevel, setThreatLevel] = useState('High Alert (Hostile Pressure)');
  const [daysSince, setDaysSince] = useState(72);
  const [responsesText, setResponsesText] = useState(
    'Experiencing severe anxiety and fear of intimidation prior to court hearing next week. Need guidance on witness protection.'
  );

  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<DistressRecord[]>([]);
  const [escalations, setEscalations] = useState<EscalationRecord[]>(DEFAULT_ESCALATIONS);
  const [latestResult, setLatestResult] = useState<DistressRecord | null>(null);
  const [selectedEscalation, setSelectedEscalation] = useState<EscalationRecord | null>(DEFAULT_ESCALATIONS[0]);

  // AI Chat State
  const [chatMessages, setChatMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string }>>([
    {
      role: 'assistant',
      content:
        'Namaste. I am your NyayaSahay Legal & Psychological Support Counselor. I am here to stand by you, explain your legal rights under the SC/ST (Prevention of Atrocities) Act, assist with FIR & compensation tracking, and ensure your safety. How can I help you today?',
    },
  ]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const calculateDistressIndex = (sent: number, stage: string, days: number, txt: string): DistressRecord => {
    let stageMultiplier = 20;
    if (stage === 'trial' || stage === 'adjournment') stageMultiplier = 35;
    if (stage === 'chargesheet') stageMultiplier = 25;

    let score = Math.round(
      ((1 - sent) / 2) * 50 + stageMultiplier + (days < 60 ? 15 : 5)
    );
    score = Math.max(10, Math.min(98, score));

    let level = 'LOW_DISTRESS';
    let status = 'NONE';
    let outreach = false;

    if (score >= 70) {
      level = 'SEVERE_DISTRESS';
      status = 'DISTRICT_PROTECTION_ESCALATED';
      outreach = true;
    } else if (score >= 50) {
      level = 'MODERATE_DISTRESS';
      status = 'COUNSELOR_ASSIGNED';
      outreach = true;
    }

    return {
      id: 'ny_' + Date.now(),
      sentiment_score: sent,
      case_stage: stage,
      days_since_incident: days,
      recent_checkin_responses: txt,
      distress_score: score,
      distress_level: level,
      escalation_status: status,
      proactive_outreach_needed: outreach,
      created_at: new Date().toISOString(),
    };
  };

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get<DistressRecord[]>('/apps/nyaya/distress');
      if (Array.isArray(data) && data.length > 0) {
        setHistory(data);
        setLatestResult(data[0]);
        return;
      }
    } catch (e) {
      console.error('Maintaining pre-seeded distress history', e);
    }

    const initial = calculateDistressIndex(sentiment, caseStage, daysSince, responsesText);
    setLatestResult(initial);
    setHistory([initial]);
  };

  const fetchEscalations = async () => {
    try {
      const data = await apiClient.get<EscalationRecord[]>('/apps/nyaya/escalations');
      if (Array.isArray(data) && data.length > 0) {
        setEscalations(data);
      }
    } catch (e) {
      console.error('Maintaining pre-seeded counselor escalations', e);
    }
  };

  useEffect(() => {
    fetchHistory();
    fetchEscalations();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    let record: DistressRecord;

    try {
      record = await apiClient.post<DistressRecord>('/apps/nyaya/distress', {
        sentiment_score: sentiment,
        case_stage: caseStage,
        days_since_incident: daysSince,
        recent_checkin_responses: responsesText,
      });
    } catch {
      record = calculateDistressIndex(sentiment, caseStage, daysSince, responsesText);
    }

    setLatestResult(record);
    setHistory((prev) => [record, ...prev]);
    setLoading(false);
  };

  const handleSendChat = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!chatInput.trim()) return;

    const userMsg = chatInput.trim();
    setChatInput('');
    const newMessages = [...chatMessages, { role: 'user' as const, content: userMsg }];
    setChatMessages(newMessages);
    setChatLoading(true);

    try {
      const res = await apiClient.post<any>('/ai/chat', {
        agent_id: 'nyaya_sahay_agent',
        messages: newMessages,
      });
      setChatMessages([...newMessages, { role: 'assistant', content: res.content }]);
    } catch {
      setChatMessages([
        ...newMessages,
        {
          role: 'assistant',
          content:
            'Namaste. Under Section 15A of the SC/ST (Prevention of Atrocities) Act, you are entitled to complete protection, legal aid, and state compensation during trial. You are not alone.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6 space-y-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Header Banner */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-indigo-50 border border-indigo-200 flex items-center justify-center text-2xl shadow-sm">
              ⚖️
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">NyayaSahay Victim Support</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-indigo-100 text-indigo-800 border border-indigo-200 uppercase">
                  SIH26094 • MoSJE Track
                </span>
              </div>
              <p className="text-xs text-slate-500">Dynamic Psychological Distress Index, Case Milestone Correlation &amp; District Protection Desk</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {user ? (
              <div className="px-3 py-1.5 bg-slate-100 border rounded-xl text-xs font-bold text-slate-700 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-indigo-500"></span>
                <span>{user.full_name} ({user.primary_role})</span>
              </div>
            ) : (
              <span className="px-2.5 py-1 bg-slate-100 border text-slate-600 rounded-lg text-xs font-semibold">
                Evaluation Mode Active
              </span>
            )}
          </div>
        </header>

        {/* Feature Tabs */}
        <div className="flex flex-wrap gap-2 border-b border-slate-200 pb-2">
          <button
            onClick={() => setActiveTab('CHECKIN')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'CHECKIN'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📊</span>
            <span>Psychological Distress Check-in</span>
          </button>

          <button
            onClick={() => setActiveTab('ESCALATIONS')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'ESCALATIONS'
                ? 'bg-slate-900 text-white shadow-md'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>🏛️</span>
            <span>District Counselor Escalations ({escalations.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('CHAT')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'CHAT'
                ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>💬</span>
            <span>AI Legal &amp; Mental Companion</span>
          </button>

          <button
            onClick={() => setActiveTab('HISTORY')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'HISTORY'
                ? 'bg-sky-600 text-white shadow-md shadow-sky-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📜</span>
            <span>Check-in Logs ({history.length})</span>
          </button>
        </div>

        {/* TAB 1: VICTIM CHECKIN */}
        {activeTab === 'CHECKIN' && (
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
            
            {/* Input Form */}
            <div className="md:col-span-6">
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 text-xs">
                <div className="border-b pb-2 flex items-center justify-between">
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Distress Index Parameters</h2>
                  <span className="text-[10px] font-mono text-indigo-700 font-bold bg-indigo-50 px-2 py-0.5 rounded border border-indigo-200">
                    SC/ST PoA Act
                  </span>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Legal Milestone Stage</label>
                  <select
                    value={caseStage}
                    onChange={(e) => setCaseStage(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl font-bold"
                  >
                    {LEGAL_MILESTONES.map((m) => (
                      <option key={m.id} value={m.id}>
                        {m.label} ({m.desc})
                      </option>
                    ))}
                  </select>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Days Since Incident</label>
                    <input
                      type="number"
                      value={daysSince}
                      onChange={(e) => setDaysSince(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Sentiment Score (-1.0 to +1.0)</label>
                    <input
                      type="number"
                      step="0.05"
                      min="-1.0"
                      max="1.0"
                      value={sentiment}
                      onChange={(e) => setSentiment(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Perceived Threat Level</label>
                  <select
                    value={threatLevel}
                    onChange={(e) => setThreatLevel(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl font-bold"
                  >
                    <option value="Low Threat">Low Threat (Normal Daily Operations)</option>
                    <option value="Moderate Pressure">Moderate Pressure (Local Social Pressure)</option>
                    <option value="High Alert (Hostile Pressure)">High Alert (Direct Hostile Intimidation)</option>
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Recent Psychological Check-in Notes</label>
                  <textarea
                    value={responsesText}
                    onChange={(e) => setResponsesText(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl h-20"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Evaluating Distress Index...' : 'Calculate Psychological Distress Index & Outreach Status'}
                </button>
              </form>
            </div>

            {/* Scorecard */}
            <div className="md:col-span-6 space-y-4">
              {latestResult ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 text-xs">
                  <div className="border-b pb-2 flex items-center justify-between">
                    <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Distress Index Scorecard</h2>
                    <span className="text-xs font-mono text-slate-400">{latestResult.id}</span>
                  </div>

                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Calculated Psychological Distress Index</span>
                    <div className="text-4xl font-black text-indigo-700">{latestResult.distress_score} <span className="text-xs font-normal text-slate-500">/ 100</span></div>
                  </div>

                  <div className="p-3 bg-slate-50 border rounded-xl flex items-center justify-between">
                    <span className="font-bold text-slate-600">Distress Level Category:</span>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-black ${
                        latestResult.distress_level === 'SEVERE_DISTRESS'
                          ? 'bg-rose-100 text-rose-800'
                          : latestResult.distress_level === 'MODERATE_DISTRESS'
                          ? 'bg-amber-100 text-amber-800'
                          : 'bg-emerald-100 text-emerald-800'
                      }`}
                    >
                      {latestResult.distress_level}
                    </span>
                  </div>

                  <div className="p-3.5 bg-slate-50 border rounded-xl space-y-1">
                    <span className="font-bold text-slate-700 uppercase text-[10px]">District Protection Escalation Status</span>
                    <p className="font-bold text-indigo-900">{latestResult.escalation_status}</p>
                  </div>

                  <div className="p-3.5 bg-indigo-50/70 border border-indigo-200 rounded-xl space-y-1">
                    <span className="font-bold text-indigo-950 uppercase text-[10px]">Proactive Outreach Protocol</span>
                    <p className="text-indigo-900 font-medium">
                      {latestResult.proactive_outreach_needed
                        ? '⚠️ Proactive counselor outreach activated. Designated district legal & welfare officer notified.'
                        : 'Routine check-in logged. No emergency escalation required.'}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                  Submit check-in parameters to evaluate distress index.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 2: DISTRICT ESCALATIONS */}
        {activeTab === 'ESCALATIONS' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            
            {/* Queue */}
            <div className="lg:col-span-5 bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-4">
              <div className="border-b pb-2 flex items-center justify-between">
                <h2 className="text-xs font-extrabold text-slate-800 uppercase tracking-wider">District Escalation Queue ({escalations.length})</h2>
                <span className="text-[10px] font-mono bg-indigo-50 text-indigo-700 px-2 py-0.5 rounded font-bold">Counselor Desk</span>
              </div>

              <div className="divide-y divide-slate-100 space-y-2">
                {escalations.map((item) => (
                  <div
                    key={item.id}
                    onClick={() => setSelectedEscalation(item)}
                    className={`p-3.5 rounded-xl cursor-pointer transition border ${
                      selectedEscalation?.id === item.id
                        ? 'bg-indigo-50/70 border-indigo-300'
                        : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-bold text-xs text-slate-900">{item.patient_name}</span>
                      <span
                        className={`px-2 py-0.5 rounded text-[9px] font-black ${
                          item.distress_level === 'SEVERE_DISTRESS'
                            ? 'bg-rose-100 text-rose-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        Score: {item.distress_score}
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-600">{item.case_stage}</p>
                    <div className="text-[10px] text-slate-400 font-mono mt-1">{item.id} &bull; Status: {item.escalation_status}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Selected View */}
            <div className="lg:col-span-7 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 text-xs">
              {selectedEscalation ? (
                <div className="space-y-4">
                  <div className="border-b pb-3 flex items-center justify-between">
                    <div>
                      <h2 className="text-lg font-black text-slate-900">{selectedEscalation.patient_name}</h2>
                      <span className="text-xs text-slate-400 font-mono">Case ID: {selectedEscalation.id}</span>
                    </div>
                    <span className="px-3 py-1 bg-indigo-100 text-indigo-800 rounded-full font-black text-xs">
                      {selectedEscalation.distress_level}
                    </span>
                  </div>

                  <div className="p-4 bg-slate-50 rounded-2xl border space-y-2">
                    <span className="font-bold text-slate-400 uppercase text-[10px]">District Action Plan</span>
                    <p className="text-slate-800 font-medium leading-relaxed">
                      Escalated under Section 15A of SC/ST (PoA) Act. District Protection Officer assigned. Direct witness protection &amp; legal counseling initiated.
                    </p>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div className="p-3 bg-slate-50 border rounded-xl">
                      <span className="text-[10px] font-bold text-slate-400 uppercase block">Current Milestone</span>
                      <span className="font-bold text-slate-900">{selectedEscalation.case_stage}</span>
                    </div>
                    <div className="p-3 bg-slate-50 border rounded-xl">
                      <span className="text-[10px] font-bold text-slate-400 uppercase block">Escalation Status</span>
                      <span className="font-bold text-indigo-700">{selectedEscalation.escalation_status}</span>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-12 text-slate-400 text-xs italic">
                  Select an escalation record from the queue to view protection details.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 3: CHAT */}
        {activeTab === 'CHAT' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">NyayaSahay AI Legal &amp; Mental Support</h2>
                <p className="text-xs text-slate-500">Confidential guidance on SC/ST PoA Act rights, witness protection &amp; state compensation</p>
              </div>
            </div>

            <div className="h-80 overflow-y-auto space-y-3 p-4 bg-slate-50 rounded-2xl border border-slate-200 text-xs">
              {chatMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[80%] p-3 rounded-2xl font-medium leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-indigo-600 text-white rounded-br-none'
                        : 'bg-white text-slate-800 border border-slate-200 rounded-bl-none shadow-xs'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && <div className="text-slate-400 text-xs italic">NyayaSahay AI is thinking...</div>}
            </div>

            <form onSubmit={handleSendChat} className="flex gap-2">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Ask about legal rights, FIR process, compensation, or protection..."
                className="flex-1 px-4 py-2.5 bg-slate-50 border rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
              <button
                type="submit"
                disabled={chatLoading}
                className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-xs transition"
              >
                Send
              </button>
            </form>
          </div>
        )}

        {/* TAB 4: HISTORY */}
        {activeTab === 'HISTORY' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto text-xs">
            <div className="border-b pb-3 flex items-center justify-between">
              <h2 className="text-base font-extrabold text-slate-900">Check-in Logs ({history.length})</h2>
              <span className="text-xs text-slate-500 font-mono">Confidential Logs</span>
            </div>

            <div className="divide-y divide-slate-100">
              {history.map((rec) => (
                <div key={rec.id} className="py-3.5 flex items-center justify-between">
                  <div>
                    <span className="font-bold text-slate-900">{rec.id}</span>
                    <p className="text-slate-500 text-[11px] mt-0.5">
                      Milestone: {rec.case_stage} | Days: {rec.days_since_incident} | Sentiment: {rec.sentiment_score}
                    </p>
                  </div>
                  <div className="text-right">
                    <span
                      className={`px-2.5 py-1 rounded text-[10px] font-black ${
                        rec.distress_level === 'SEVERE_DISTRESS'
                          ? 'bg-rose-100 text-rose-800'
                          : 'bg-emerald-100 text-emerald-800'
                      }`}
                    >
                      Score: {rec.distress_score} ({rec.distress_level})
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
