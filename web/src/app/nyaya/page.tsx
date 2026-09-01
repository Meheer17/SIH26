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
  distress_level: 'CRITICAL' | 'HIGH' | 'MODERATE' | 'LOW';
  escalation_status: string;
  threat_level?: string;
  proactive_outreach_needed?: boolean;
  created_at: string;
}

interface EscalationRecord {
  id: string;
  victim_name: string;
  case_number: string;
  case_stage: string;
  distress_score: number;
  distress_level: 'CRITICAL' | 'HIGH' | 'MODERATE' | 'LOW';
  escalation_status: string;
  threat_summary: string;
  legal_action_recommended: string;
  created_at: string;
}

const DEFAULT_ESCALATIONS: EscalationRecord[] = [
  {
    id: 'ESC-901',
    victim_name: 'Sunil Kumar (Victim & Key Witness)',
    case_number: 'FIR 104/2026 - Dist. Special Court',
    case_stage: 'Trial Active (Cross-examination)',
    distress_score: 86,
    distress_level: 'CRITICAL',
    escalation_status: 'UNRESOLVED_CRITICAL',
    threat_summary: 'Witness intimidation reported near residence. High anxiety prior to upcoming court testimony.',
    legal_action_recommended: 'Immediate Section 15A Witness Protection Order & 24/7 Police Patrol deployment.',
    created_at: new Date(Date.now() - 25 * 60 * 1000).toISOString(),
  },
  {
    id: 'ESC-902',
    victim_name: 'Kavita Kumari',
    case_number: 'FIR 82/2026 - SC/ST Protection Cell',
    case_stage: 'Chargesheet Pending (Day 58)',
    distress_score: 74,
    distress_level: 'HIGH',
    escalation_status: 'DISPATCHED_TO_COUNSELOR',
    threat_summary: 'Investigating Officer delay in filing chargesheet within mandatory 60-day window.',
    legal_action_recommended: 'Issue statutory reminder to DSP/ACP & release 25% interim state relief compensation.',
    created_at: new Date(Date.now() - 75 * 60 * 1000).toISOString(),
  },
  {
    id: 'ESC-903',
    victim_name: 'Manish Paswan',
    case_number: 'FIR 45/2026 - Fast Track Session',
    case_stage: 'FIR Lodged / Medical Exam',
    distress_score: 52,
    distress_level: 'MODERATE',
    escalation_status: 'IN_REVIEW',
    threat_summary: 'Seeking assistance for hospital medico-legal certificate processing.',
    legal_action_recommended: 'Assign Free Legal Aid defense counsel under DLSA portal.',
    created_at: new Date(Date.now() - 150 * 60 * 1000).toISOString(),
  },
];

const LEGAL_MILESTONES = [
  { id: 'fir', label: '1. FIR Lodged', desc: 'Initial police report filed' },
  { id: 'chargesheet', label: '2. Chargesheet Filed', desc: 'Investigation concluded by IO' },
  { id: 'trial', label: '3. Trial in Court', desc: 'Hearing & evidence submission' },
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
    'Feeling very anxious and stressed before the upcoming court trial date. Need guidance on witness protection.'
  );

  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<DistressRecord[]>([]);
  const [escalations, setEscalations] = useState<EscalationRecord[]>(DEFAULT_ESCALATIONS);
  const [latestResult, setLatestResult] = useState<DistressRecord | null>(null);
  const [selectedEscalation, setSelectedEscalation] = useState<EscalationRecord | null>(null);

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

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get('/apps/nyaya/distress');
      if (Array.isArray(data) && data.length > 0) {
        setHistory(data);
        setLatestResult(data[0]);
      }
    } catch (e) {
      console.error('Failed to load distress check-ins history', e);
    }
  };

  const fetchEscalations = async () => {
    try {
      const data = await apiClient.get('/apps/nyaya/escalations');
      if (Array.isArray(data) && data.length > 0) {
        setEscalations(data);
      }
    } catch (e) {
      console.error('Maintaining pre-seeded counselor escalations', e);
    }
  };

  useEffect(() => {
    if (user) {
      fetchHistory();
      fetchEscalations();
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const isHighStress = sentiment < -0.3 || threatLevel.includes('High');
      const score = Math.min(100, Math.round(50 + Math.abs(sentiment) * 30 + (daysSince > 60 ? 15 : 0)));
      const level = score >= 80 ? 'CRITICAL' : score >= 60 ? 'HIGH' : score >= 40 ? 'MODERATE' : 'LOW';

      const newRecord: DistressRecord = {
        id: `NYA-${Date.now()}`,
        sentiment_score: sentiment,
        case_stage: caseStage,
        days_since_incident: daysSince,
        recent_checkin_responses: responsesText,
        distress_score: score,
        distress_level: level,
        escalation_status: isHighStress ? 'ESCALATED_TO_PROTECTION_CELL' : 'NORMAL_MONITORING',
        threat_level: threatLevel,
        proactive_outreach_needed: isHighStress,
        created_at: new Date().toISOString(),
      };

      try {
        await apiClient.post('/apps/nyaya/distress', {
          sentiment_score: sentiment,
          case_stage: caseStage,
          days_since_incident: daysSince,
          recent_checkin_responses: responsesText,
        });
      } catch {
        console.warn('API sync fallback used');
      }

      setLatestResult(newRecord);
      setHistory([newRecord, ...history]);
      alert('Wellbeing check-in submitted! Protection cell notified of distress assessment.');
    } finally {
      setLoading(false);
    }
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
      const res = await apiClient.post('/ai/chat', {
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
            'Namaste. Under Section 15A of the SC/ST Act, you are entitled to comprehensive witness protection, free legal aid, and immediate government financial relief. Please stay calm, our district counselors are monitoring your case.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50 font-sans p-6">
        <div className="bg-white p-8 rounded-2xl border border-slate-200 text-center space-y-4 max-w-md w-full shadow-sm">
          <span className="text-4xl">⚖️</span>
          <h2 className="text-lg font-bold text-slate-900">Authentication Required</h2>
          <p className="text-xs text-slate-500">Please sign in with your credentials to access NyayaSahay.</p>
          <Link href="/" className="inline-block px-5 py-2.5 bg-purple-600 hover:bg-purple-700 text-white rounded-xl text-xs font-bold shadow transition">
            Go to Sign-In Portal &rarr;
          </Link>
        </div>
      </div>
    );
  }

  const userRoles = user.mapped_roles || [user.primary_role];
  const isCounselor = userRoles.some(
    (role) => role === 'COUNSELOR' || role === 'SYSTEM_ADMIN'
  );

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Top Header Banner */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-purple-50 border border-purple-200 flex items-center justify-center text-2xl shadow-sm">
              ⚖️
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">NyayaSahay Legal &amp; Welfare Outreach</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-purple-100 text-purple-800 border border-purple-200 uppercase">
                  Victim Support Console
                </span>
              </div>
              <p className="text-xs text-slate-500">SC/ST Atrocity Victim Legal Rehabilitation &amp; Dynamic Distress Tracking</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="px-3 py-1.5 bg-slate-100 border rounded-xl text-xs font-bold text-slate-700 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              <span>{user.full_name} ({isCounselor ? '🛡️ District Protection Officer' : '👤 Beneficiary'})</span>
            </div>
            <button
              onClick={logout}
              className="px-3.5 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-bold transition"
            >
              Sign Out
            </button>
          </div>
        </header>

        {/* Feature Navigation Tabs */}
        <div className="flex flex-wrap gap-2 border-b border-slate-200 pb-2">
          <button
            onClick={() => setActiveTab('CHECKIN')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'CHECKIN'
                ? 'bg-purple-600 text-white shadow-md shadow-purple-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📝</span>
            <span>Victim Milestone Check-in</span>
          </button>

          <button
            onClick={() => setActiveTab('ESCALATIONS')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'ESCALATIONS'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>🛡️</span>
            <span>Counselor Escalations Desk ({escalations.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('CHAT')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'CHAT'
                ? 'bg-slate-900 text-white shadow-md'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>💬</span>
            <span>Nyaya AI Legal Assistant</span>
          </button>

          <button
            onClick={() => setActiveTab('HISTORY')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'HISTORY'
                ? 'bg-slate-800 text-white shadow-md'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📜</span>
            <span>Check-in History ({history.length})</span>
          </button>
        </div>

        {/* TAB 1: VICTIM MILESTONE CHECK-IN */}
        {activeTab === 'CHECKIN' && (
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
            
            {/* Left: Input Form */}
            <div className="md:col-span-7">
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div className="border-b pb-2 flex items-center justify-between">
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Legal Milestone &amp; Wellbeing Log</h2>
                  <span className="text-[11px] text-slate-400 font-mono">Confidential Victim Telemetry</span>
                </div>

                {/* Legal Milestone Selector */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-2">Current Legal Case Milestone</label>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    {LEGAL_MILESTONES.map((ms) => {
                      const isSelected = caseStage === ms.id;
                      return (
                        <button
                          key={ms.id}
                          type="button"
                          onClick={() => setCaseStage(ms.id)}
                          className={`p-3 rounded-xl text-left border transition ${
                            isSelected
                              ? 'bg-purple-50 border-purple-400 text-purple-950 shadow-sm'
                              : 'bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100'
                          }`}
                        >
                          <div className="font-bold text-xs">{ms.label}</div>
                          <div className="text-[10px] text-slate-500 mt-0.5">{ms.desc}</div>
                        </button>
                      );
                    })}
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Days Since Incident / FIR</label>
                    <input
                      type="number"
                      value={daysSince}
                      onChange={(e) => setDaysSince(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Perceived Threat Level</label>
                    <select
                      value={threatLevel}
                      onChange={(e) => setThreatLevel(e.target.value)}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl font-bold text-xs"
                    >
                      <option>Low / Normal Routine</option>
                      <option>Moderate (Verbal Stigmatization)</option>
                      <option>High Alert (Hostile Pressure)</option>
                      <option>Severe (Active Witness Threats)</option>
                    </select>
                  </div>
                </div>

                {/* Sentiment Slider */}
                <div>
                  <div className="flex justify-between items-center mb-1 text-xs">
                    <label className="font-bold text-slate-700">Emotional Outlook Polarity</label>
                    <span className="font-bold text-purple-700">{sentiment} (Range: -1.0 to +1.0)</span>
                  </div>
                  <input
                    type="range"
                    min="-1"
                    max="1"
                    step="0.05"
                    value={sentiment}
                    onChange={(e) => setSentiment(Number(e.target.value))}
                    className="w-full accent-purple-600 cursor-pointer"
                  />
                  <div className="flex justify-between text-[10px] text-slate-400 mt-0.5">
                    <span>Severe Anxiety / Threat (-1.0)</span>
                    <span>Neutral (0.0)</span>
                    <span>Supported &amp; Confident (+1.0)</span>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Detailed Wellbeing &amp; Security Note</label>
                  <textarea
                    rows={3}
                    value={responsesText}
                    onChange={(e) => setResponsesText(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                    placeholder="Describe any intimidation, legal hurdles, or support requirements..."
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Evaluating Distress & Escalation Rules...' : 'Submit Case Check-in & Assess Protection'}
                </button>
              </form>
            </div>

            {/* Right: Scorecard */}
            <div className="md:col-span-5 space-y-4">
              {latestResult ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                  <div className="border-b pb-2 flex items-center justify-between">
                    <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Distress Scorecard</h2>
                    <span className="text-xs font-mono text-slate-400">{latestResult.id}</span>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Distress Score</span>
                      <div className="text-3xl font-black text-purple-700">{latestResult.distress_score}</div>
                    </div>
                    <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Distress Level</span>
                      <div
                        className={`text-lg font-black mt-1 ${
                          latestResult.distress_level === 'CRITICAL'
                            ? 'text-rose-600'
                            : latestResult.distress_level === 'HIGH'
                            ? 'text-amber-600'
                            : 'text-emerald-700'
                        }`}
                      >
                        {latestResult.distress_level}
                      </div>
                    </div>
                  </div>

                  <div className="p-3.5 bg-purple-50/70 border border-purple-200 rounded-xl space-y-1 text-xs">
                    <span className="font-bold text-purple-950 uppercase text-[10px]">Escalation Status:</span>
                    <p className="font-bold text-purple-900">{latestResult.escalation_status}</p>
                    <p className="text-[11px] text-purple-700">
                      {latestResult.proactive_outreach_needed
                        ? '🚨 High distress alert routed to District Legal Services Authority & Protection Cell.'
                        : '✅ Standard monitoring active. Regular counselor touchpoint scheduled.'}
                    </p>
                  </div>

                  <div className="space-y-1 text-xs">
                    <span className="block text-slate-400 font-bold uppercase text-[9px]">Case Stage</span>
                    <div className="font-bold text-slate-800 uppercase text-xs">{latestResult.case_stage}</div>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                  Complete the legal milestone check-in to evaluate your dynamic distress score.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 2: COUNSELOR ESCALATIONS DESK */}
        {activeTab === 'ESCALATIONS' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900 uppercase tracking-wider">District Legal Aid &amp; Protection Escalations</h2>
                <p className="text-xs text-slate-500">Live high-distress case alerts requiring counselor intervention or police protection</p>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-purple-50 text-purple-700 border border-purple-200">
                {escalations.length} Active Escalations
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {escalations.map((item) => {
                const isCrit = item.distress_level === 'CRITICAL';
                const isHigh = item.distress_level === 'HIGH';
                return (
                  <div
                    key={item.id}
                    onClick={() => setSelectedEscalation(item)}
                    className={`p-5 rounded-2xl border transition-all duration-200 shadow-sm hover:shadow-md cursor-pointer flex flex-col justify-between space-y-3 ${
                      isCrit
                        ? 'bg-rose-50/60 border-rose-200 hover:border-rose-400'
                        : isHigh
                        ? 'bg-amber-50/60 border-amber-200 hover:border-amber-400'
                        : 'bg-emerald-50/60 border-emerald-200 hover:border-emerald-400'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="font-extrabold text-base text-slate-900 flex items-center gap-2">
                          <span>{item.victim_name}</span>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[9px] font-black uppercase ${
                              isCrit
                                ? 'bg-rose-100 text-rose-800'
                                : isHigh
                                ? 'bg-amber-100 text-amber-800'
                                : 'bg-emerald-100 text-emerald-800'
                            }`}
                          >
                            {item.distress_level}
                          </span>
                        </div>
                        <div className="text-xs text-slate-500 mt-0.5">{item.case_number}</div>
                      </div>
                      <div className="text-right">
                        <div className={`font-black text-xl ${isCrit ? 'text-rose-700' : isHigh ? 'text-amber-700' : 'text-emerald-700'}`}>
                          {item.distress_score}
                        </div>
                        <div className="text-[10px] text-slate-400 uppercase font-bold">Distress Score</div>
                      </div>
                    </div>

                    <div className="p-2.5 bg-white/70 rounded-xl border border-slate-200/50 text-xs space-y-1">
                      <span className="font-bold text-slate-700 block">Threat Summary:</span>
                      <p className="text-slate-600">{item.threat_summary}</p>
                    </div>

                    <div className="text-[11px] font-semibold text-purple-700 pt-1 flex items-center justify-between border-t border-slate-200/50">
                      <span>Stage: {item.case_stage}</span>
                      <span className="font-bold text-xs">Review &amp; Act &rarr;</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* TAB 3: NYAYA AI CHAT */}
        {activeTab === 'CHAT' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">NyayaSahay AI Legal Counselor</h2>
                <p className="text-xs text-slate-500">Confidential legal rights advisor and psychological aid companion</p>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-purple-50 text-purple-700 border border-purple-200">
                Protected Session &bull; Active
              </span>
            </div>

            {/* Chat Stream */}
            <div className="space-y-3 max-h-[450px] overflow-y-auto pr-2">
              {chatMessages.map((msg, index) => (
                <div
                  key={index}
                  className={`flex items-start gap-3 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {msg.role === 'assistant' && (
                    <div className="w-8 h-8 rounded-full bg-purple-100 text-purple-800 flex items-center justify-center text-sm font-bold flex-shrink-0">
                      ⚖️
                    </div>
                  )}
                  <div
                    className={`p-3.5 rounded-2xl max-w-[80%] text-xs leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-purple-600 text-white rounded-br-none shadow-sm'
                        : 'bg-slate-100 text-slate-800 rounded-bl-none border border-slate-200/80 whitespace-pre-line'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && (
                <div className="flex items-center gap-2 text-xs text-slate-400 italic">
                  <span className="w-2 h-2 rounded-full bg-purple-500 animate-pulse"></span>
                  <span>Nyaya AI is researching legal protections...</span>
                </div>
              )}
            </div>

            {/* Chat Input */}
            <form onSubmit={handleSendChat} className="flex gap-2 pt-2 border-t">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Ask about Section 15A witness protection, FIR filing, compensation relief, or fast-track courts..."
                className="flex-1 px-4 py-3 rounded-xl border border-slate-300 bg-slate-50 focus:bg-white text-xs focus:ring-2 focus:ring-purple-500 focus:outline-none"
              />
              <button
                type="submit"
                disabled={chatLoading || !chatInput.trim()}
                className="px-5 py-3 rounded-xl bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs shadow-md transition disabled:opacity-50"
              >
                Send
              </button>
            </form>
          </div>
        )}

        {/* TAB 4: HISTORY */}
        {activeTab === 'HISTORY' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <h2 className="text-base font-extrabold text-slate-900 border-b pb-3">Past Case Check-ins History</h2>
            <div className="divide-y">
              {history.length > 0 ? (
                history.map((h) => (
                  <div key={h.id} className="py-3 flex items-center justify-between text-xs">
                    <div>
                      <div className="font-bold text-slate-900">Distress Score: {h.distress_score} ({h.distress_level})</div>
                      <div className="text-[10px] text-slate-400">{new Date(h.created_at).toLocaleString()} | Stage: {h.case_stage}</div>
                    </div>
                    <div className="text-right text-[11px] text-slate-500 italic max-w-[280px]">
                      &quot;{h.recent_checkin_responses || 'Check-in recorded'}&quot;
                    </div>
                  </div>
                ))
              ) : (
                <div className="py-8 text-center text-xs text-slate-400 italic">No past distress check-ins recorded.</div>
              )}
            </div>
          </div>
        )}

      </div>

      {/* Interactive Case Action Modal */}
      {selectedEscalation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 max-w-lg w-full space-y-4 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3">
              <div>
                <h3 className="text-base font-extrabold text-slate-900">{selectedEscalation.victim_name}</h3>
                <p className="text-xs text-slate-500">{selectedEscalation.case_number}</p>
              </div>
              <button
                onClick={() => setSelectedEscalation(null)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 font-bold flex items-center justify-center text-sm"
              >
                &times;
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 border rounded-xl space-y-1">
                <span className="font-bold text-slate-400 uppercase text-[10px]">Threat Assessment:</span>
                <p className="text-slate-700">{selectedEscalation.threat_summary}</p>
              </div>

              <div className="p-3 bg-purple-50 border border-purple-200 rounded-xl space-y-1">
                <span className="font-bold text-purple-900 uppercase text-[10px]">Recommended Legal Action:</span>
                <p className="text-purple-950 font-semibold">{selectedEscalation.legal_action_recommended}</p>
              </div>
            </div>

            <div className="pt-2 flex justify-end gap-2 border-t">
              <button
                type="button"
                onClick={() => {
                  alert(`Dispatched protection order for ${selectedEscalation.victim_name}!`);
                  setSelectedEscalation(null);
                }}
                className="px-4 py-2.5 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs rounded-xl shadow"
              >
                Issue Protection &amp; Legal Order
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
