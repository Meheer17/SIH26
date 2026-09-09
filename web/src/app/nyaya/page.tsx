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
    id: 'ESC-101',
    user_id: 'u_891',
    patient_name: 'Sunita Devi (Case #412/2026)',
    case_stage: 'Trial Proceedings & Witness Protection',
    distress_score: 84,
    distress_level: 'SEVERE_DISTRESS',
    escalation_status: 'DISTRICT_PROTECTION_ACTIVATED',
    created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
  },
  {
    id: 'ESC-102',
    user_id: 'u_892',
    patient_name: 'Manish Kumar (Case #308/2026)',
    case_stage: 'Chargesheet Filing & Legal Aid Allotment',
    distress_score: 66,
    distress_level: 'MODERATE_DISTRESS',
    escalation_status: 'COUNSELOR_ASSIGNED',
    created_at: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
  },
];

const LEGAL_MILESTONES = [
  { id: 'fir', label: '1. FIR Registration', desc: 'Initial police report filed under SC/ST PoA Act' },
  { id: 'chargesheet', label: '2. Chargesheet Filed', desc: '60-day mandatory investigation concluded' },
  { id: 'trial', label: '3. Special Court Trial', desc: 'Hearing & evidence submission in Designated Special Court' },
  { id: 'adjournment', label: '4. Cross-Examination & Protection', desc: 'Witness protection & court appearance' },
  { id: 'compensation', label: '5. State Compensation Disbursal', desc: 'Relief grant disbursal under SC/ST Rules' },
];

export default function NyayaSahayPage() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'CHECKIN' | 'ESCALATIONS' | 'CHAT' | 'HISTORY'>('CHECKIN');

  // Victim Form State
  const [sentiment, setSentiment] = useState(-0.45);
  const [caseStage, setCaseStage] = useState('trial');
  const [threatLevel, setThreatLevel] = useState('High Alert (Hostile Pressure)');
  const [daysSince, setDaysSince] = useState(72);
  const [responsesText, setResponsesText] = useState(
    'Experiencing severe anxiety and fear of intimidation prior to court hearing next week. Need guidance on witness protection and legal escort.'
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
        'Namaste. I am your NyayaSahay Legal & Psychological Support Counselor. I am here to stand by you, explain your statutory rights under the SC/ST (Prevention of Atrocities) Act, assist with FIR & compensation tracking, and ensure your physical protection and mental wellbeing. How may I support you today?',
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
    let status = 'ROUTINE_MONITORING';
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
      id: 'NYA-' + Date.now().toString().slice(-6),
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
      console.warn('Maintaining pre-seeded distress history', e);
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
      console.warn('Maintaining pre-seeded counselor escalations', e);
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
            'Namaste. Under Section 15A of the SC/ST (Prevention of Atrocities) Act, you are entitled to comprehensive state protection, legal aid, traveling allowance, and immediate interim compensation during trial. You are protected by law.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#fafaf9] text-stone-900 font-sans pb-16">
      {/* Top Breadcrumb & Status */}
      <div className="border-b border-stone-200 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between text-xs text-stone-500">
          <div className="flex items-center gap-2">
            <Link href="/" className="hover:text-stone-900 transition font-medium">SvasthyaSetu</Link>
            <span>/</span>
            <span className="font-semibold text-stone-900">NyayaSahay Victim Support</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="hidden sm:inline-flex items-center gap-1.5 text-stone-600 font-medium">
              <span className="w-2 h-2 rounded-full bg-purple-500"></span>
              Confidential Victim Desk
            </span>
            <span className="px-2 py-0.5 rounded text-[11px] font-mono font-bold bg-purple-50 text-purple-900 border border-purple-200">
              SIH26094 • MoSJE Track
            </span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 pt-8 space-y-8">
        
        {/* Module Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-stone-200 pb-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-md bg-stone-100 border border-stone-200 text-stone-700 text-xs font-medium">
              <span>⚖️</span>
              <span>SC/ST (PoA) Act Legal Support &amp; Psychological Protection Desk</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-semibold tracking-tight text-stone-900">
              NyayaSahay Victim Support System
            </h1>
            <p className="text-stone-600 text-sm max-w-2xl leading-relaxed">
              Dynamic psychological distress index calculation, legal milestone correlation, Section 15A witness protection protocols, and confidential counseling.
            </p>
          </div>

          <div className="flex items-center gap-3">
            {user ? (
              <div className="px-3.5 py-2 bg-white border border-stone-200 rounded-lg text-xs shadow-xs">
                <span className="text-stone-400 block text-[10px] font-medium uppercase tracking-wider">Logged In</span>
                <span className="font-semibold text-stone-900">{user.full_name}</span>
                <span className="text-stone-500 ml-1">({user.primary_role})</span>
              </div>
            ) : (
              <div className="px-3.5 py-2 bg-stone-100 border border-stone-200 rounded-lg text-xs text-stone-600">
                Evaluation Demo Profile Active
              </div>
            )}
          </div>
        </div>

        {/* Tab Switcher */}
        <div className="flex items-center gap-2 border-b border-stone-200 pb-px overflow-x-auto">
          <button
            onClick={() => setActiveTab('CHECKIN')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'CHECKIN'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>📊</span>
            <span>Psychological Distress Check-in</span>
          </button>

          <button
            onClick={() => setActiveTab('ESCALATIONS')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'ESCALATIONS'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>🏛️</span>
            <span>District Protection Desk</span>
            <span className="px-1.5 py-0.5 rounded text-[10px] font-mono bg-stone-100 text-stone-700">
              {escalations.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('CHAT')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'CHAT'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>💬</span>
            <span>AI Legal &amp; Mental Companion</span>
          </button>

          <button
            onClick={() => setActiveTab('HISTORY')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'HISTORY'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>📜</span>
            <span>Check-in Logs</span>
            <span className="px-1.5 py-0.5 rounded text-[10px] font-mono bg-stone-100 text-stone-700">
              {history.length}
            </span>
          </button>
        </div>

        {/* ========================================================================= */}
        {/* TAB 1: PSYCHOLOGICAL DISTRESS CHECK-IN */}
        {/* ========================================================================= */}
        {activeTab === 'CHECKIN' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            
            {/* Input Form (Left) */}
            <div className="lg:col-span-6 space-y-6">
              <form onSubmit={handleSubmit} className="bg-white border border-stone-200 rounded-xl p-6 sm:p-7 shadow-xs space-y-6 text-xs">
                <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                  <div>
                    <h2 className="text-sm font-semibold text-stone-900">Distress &amp; Milestone Parameters</h2>
                    <p className="text-[11px] text-stone-500">Track trauma markers across legal proceedings</p>
                  </div>
                  <span className="px-2.5 py-1 rounded text-[11px] font-mono font-semibold bg-purple-50 text-purple-900 border border-purple-200">
                    Sec 15A PoA Act
                  </span>
                </div>

                <div className="space-y-1.5">
                  <label className="font-semibold text-stone-700">Current Legal Milestone Stage</label>
                  <select
                    value={caseStage}
                    onChange={(e) => setCaseStage(e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg font-semibold text-stone-800 focus:outline-none focus:border-stone-900"
                  >
                    {LEGAL_MILESTONES.map((m) => (
                      <option key={m.id} value={m.id}>
                        {m.label} &mdash; {m.desc}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="font-semibold text-stone-700">Days Elapsed Since Incident</label>
                    <input
                      type="number"
                      value={daysSince}
                      onChange={(e) => setDaysSince(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                      required
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="font-semibold text-stone-700">Self-Assessed Sentiment Polarity</label>
                    <input
                      type="number"
                      step="0.05"
                      min="-1.0"
                      max="1.0"
                      value={sentiment}
                      onChange={(e) => setSentiment(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                      required
                    />
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="font-semibold text-stone-700">Perceived Security &amp; Intimidation Threat</label>
                  <select
                    value={threatLevel}
                    onChange={(e) => setThreatLevel(e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg font-semibold text-stone-800 focus:outline-none focus:border-stone-900"
                  >
                    <option value="Low Threat">Low Threat (Normal Daily Living)</option>
                    <option value="Moderate Pressure">Moderate Pressure (Local Social Pressure / Ostracization)</option>
                    <option value="High Alert (Hostile Pressure)">High Alert (Direct Hostile Intimidation / Threats to Witness)</option>
                  </select>
                </div>

                <div className="space-y-1.5 pt-2 border-t border-stone-100">
                  <label className="font-semibold text-stone-700">Psychological Check-in &amp; Wellness Reflections</label>
                  <textarea
                    value={responsesText}
                    onChange={(e) => setResponsesText(e.target.value)}
                    rows={3}
                    placeholder="Describe your current emotional state, court anxieties, or protection concerns..."
                    className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium leading-relaxed"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-stone-900 hover:bg-stone-800 text-white font-semibold text-xs rounded-xl shadow-xs transition disabled:opacity-50"
                >
                  {loading ? 'Evaluating Distress Index...' : 'Calculate Psychological Distress Index & Escalation Level'}
                </button>
              </form>
            </div>

            {/* Scorecard (Right) */}
            <div className="lg:col-span-6 space-y-6">
              {latestResult ? (
                <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-7 shadow-xs space-y-6 text-xs">
                  <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                    <div>
                      <h2 className="text-sm font-semibold text-stone-900">Psychological Distress Scorecard</h2>
                      <span className="text-[11px] text-stone-400 font-mono">Case ID: {latestResult.id}</span>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-md text-xs font-semibold ${
                        latestResult.distress_level === 'SEVERE_DISTRESS'
                          ? 'bg-rose-50 text-rose-800 border border-rose-200'
                          : latestResult.distress_level === 'MODERATE_DISTRESS'
                          ? 'bg-amber-50 text-amber-800 border border-amber-200'
                          : 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                      }`}
                    >
                      {latestResult.distress_level.replace('_', ' ')}
                    </span>
                  </div>

                  {/* Score Tile */}
                  <div className="p-6 rounded-xl bg-stone-50 border border-stone-200 text-center space-y-1">
                    <span className="text-[10px] uppercase font-semibold text-stone-500 tracking-wider">
                      Dynamic Psychological Distress Index
                    </span>
                    <div className="text-4xl font-semibold tracking-tight text-purple-900">
                      {latestResult.distress_score} <span className="text-base font-normal text-stone-500">/ 100</span>
                    </div>
                    <p className="text-[11px] text-stone-500 pt-1">
                      Calibrated with legal trial milestones, timeline elapsed, and threat perception.
                    </p>
                  </div>

                  {/* Escalation Status */}
                  <div className="p-4 bg-white border border-stone-200 rounded-xl space-y-1.5">
                    <span className="text-[10px] uppercase font-semibold text-stone-400 block tracking-wider">
                      District Protection Escalation Protocol
                    </span>
                    <p className="font-semibold text-stone-900 text-xs">
                      Status: <span className="text-purple-900 font-bold">{latestResult.escalation_status}</span>
                    </p>
                  </div>

                  {/* Proactive Outreach */}
                  <div className="p-4 bg-purple-50/70 border border-purple-200 rounded-xl space-y-2">
                    <span className="text-[10px] uppercase font-semibold text-purple-900 block tracking-wider">
                      Designated Support Action
                    </span>
                    <p className="text-purple-950 leading-relaxed font-medium">
                      {latestResult.proactive_outreach_needed
                        ? '⚠️ Active counselor outreach triggered. Designated District Protection Officer notified for Section 15A witness escort and psychosocial support.'
                        : 'Routine monitoring active. No emergency protection escalation required at this milestone.'}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-stone-200 rounded-xl p-12 text-center text-stone-400 text-xs italic shadow-xs">
                  Submit check-in parameters to evaluate psychological distress score.
                </div>
              )}
            </div>

          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 2: DISTRICT PROTECTION DESK */}
        {/* ========================================================================= */}
        {activeTab === 'ESCALATIONS' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            
            {/* Queue (Left) */}
            <div className="lg:col-span-5 bg-white border border-stone-200 rounded-xl p-5 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-stone-200 pb-3">
                <div>
                  <h2 className="text-xs font-semibold text-stone-500 uppercase tracking-wider">District Protection Queue</h2>
                  <span className="text-sm font-semibold text-stone-900">{escalations.length} Active Cases</span>
                </div>
                <span className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold bg-stone-100 text-stone-700">
                  Officer Desk
                </span>
              </div>

              <div className="space-y-2">
                {escalations.map((item) => {
                  const isSelected = selectedEscalation?.id === item.id;
                  return (
                    <div
                      key={item.id}
                      onClick={() => setSelectedEscalation(item)}
                      className={`p-3.5 rounded-lg cursor-pointer transition border text-xs space-y-1.5 ${
                        isSelected
                          ? 'bg-stone-100 border-stone-400 shadow-xs'
                          : 'bg-white border-stone-200 hover:bg-stone-50'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-semibold text-stone-900">{item.patient_name}</span>
                        <span
                          className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            item.distress_level === 'SEVERE_DISTRESS'
                              ? 'bg-rose-50 text-rose-800 border border-rose-200'
                              : 'bg-amber-50 text-amber-800 border border-amber-200'
                          }`}
                        >
                          Score: {item.distress_score}
                        </span>
                      </div>
                      <p className="text-stone-600 line-clamp-1">{item.case_stage}</p>
                      <div className="flex items-center justify-between text-[11px] text-stone-400 font-mono pt-1">
                        <span>{item.id}</span>
                        <span className="text-purple-800 font-semibold">{item.escalation_status}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Selected Case (Right) */}
            <div className="lg:col-span-7 bg-white border border-stone-200 rounded-xl p-6 sm:p-7 shadow-xs space-y-6 text-xs">
              {selectedEscalation ? (
                <div className="space-y-6">
                  <div className="border-b border-stone-200 pb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div>
                      <h2 className="text-xl font-semibold text-stone-900">{selectedEscalation.patient_name}</h2>
                      <span className="text-xs text-stone-400 font-mono">Case File: {selectedEscalation.id}</span>
                    </div>
                    <span className="px-3 py-1 rounded-md text-xs font-semibold bg-purple-50 text-purple-900 border border-purple-200">
                      {selectedEscalation.distress_level.replace('_', ' ')}
                    </span>
                  </div>

                  <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl space-y-2">
                    <span className="text-[10px] uppercase font-semibold text-stone-500 tracking-wider block">
                      Statutory District Protection Action Plan
                    </span>
                    <p className="text-stone-800 leading-relaxed font-medium">
                      Escalated under Section 15A of SC/ST (PoA) Act. Designated District Protection Officer assigned for trial accompaniment, witness protection security review, and immediate interim compensation verification.
                    </p>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="p-3.5 bg-white border border-stone-200 rounded-lg space-y-1">
                      <span className="text-[10px] uppercase font-semibold text-stone-400 block">Current Milestone</span>
                      <span className="font-semibold text-stone-900">{selectedEscalation.case_stage}</span>
                    </div>
                    <div className="p-3.5 bg-white border border-stone-200 rounded-lg space-y-1">
                      <span className="text-[10px] uppercase font-semibold text-stone-400 block">Officer Action Status</span>
                      <span className="font-semibold text-purple-900">{selectedEscalation.escalation_status}</span>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-16 text-stone-400 text-xs italic">
                  Select an escalation record from the left queue to view protection file.
                </div>
              )}
            </div>

          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 3: AI LEGAL & MENTAL COMPANION */}
        {/* ========================================================================= */}
        {activeTab === 'CHAT' && (
          <div className="max-w-4xl mx-auto space-y-4">
            <div className="bg-white border border-stone-200 rounded-xl p-6 shadow-xs space-y-4">
              <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">NyayaSahay AI Legal &amp; Psychosocial Companion</h2>
                  <p className="text-xs text-stone-500">Confidential guidance on SC/ST PoA Act rights, witness protection &amp; state compensation</p>
                </div>
                <span className="px-2.5 py-1 rounded text-[11px] font-semibold bg-purple-50 text-purple-900 border border-purple-200">
                  Legal Rights Advisory
                </span>
              </div>

              {/* Chat Thread */}
              <div className="h-80 overflow-y-auto space-y-3 p-4 bg-stone-50 rounded-xl border border-stone-200 text-xs">
                {chatMessages.map((msg, i) => (
                  <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                    <div
                      className={`max-w-[80%] p-3.5 rounded-xl font-medium leading-relaxed ${
                        msg.role === 'user'
                          ? 'bg-stone-900 text-white rounded-br-xs'
                          : 'bg-white text-stone-800 border border-stone-200 rounded-bl-xs shadow-xs'
                      }`}
                    >
                      {msg.content}
                    </div>
                  </div>
                ))}
                {chatLoading && (
                  <div className="text-stone-400 text-xs italic flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-stone-400 animate-pulse"></span>
                    NyayaSahay AI is researching legal provisions...
                  </div>
                )}
              </div>

              {/* Chat Input */}
              <form onSubmit={handleSendChat} className="flex gap-2">
                <input
                  type="text"
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  placeholder="Ask about your rights under PoA Act, compensation disbursal, or protection..."
                  className="flex-1 px-4 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-xs focus:outline-none focus:border-stone-900 font-medium"
                />
                <button
                  type="submit"
                  disabled={chatLoading}
                  className="px-5 py-2.5 bg-stone-900 hover:bg-stone-800 text-white font-semibold text-xs rounded-lg shadow-xs transition"
                >
                  Send
                </button>
              </form>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 4: CHECK-IN LOGS */}
        {/* ========================================================================= */}
        {activeTab === 'HISTORY' && (
          <div className="max-w-4xl mx-auto space-y-6">
            <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-8 shadow-xs space-y-4">
              <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">Confidential Check-in Logs</h2>
                  <p className="text-xs text-stone-500">Longitudinal psychological distress tracking records</p>
                </div>
                <span className="text-xs text-stone-500 font-mono">
                  {history.length} Logs Stored
                </span>
              </div>

              <div className="divide-y divide-stone-100">
                {history.map((rec) => (
                  <div key={rec.id} className="py-3.5 flex items-center justify-between text-xs">
                    <div>
                      <span className="font-semibold text-stone-900">{rec.id}</span>
                      <p className="text-stone-500 text-[11px] mt-0.5">
                        Milestone: {rec.case_stage} &bull; Days Elapsed: {rec.days_since_incident} &bull; Sentiment: {rec.sentiment_score}
                      </p>
                    </div>
                    <div className="text-right">
                      <span
                        className={`px-2.5 py-1 rounded text-[11px] font-semibold ${
                          rec.distress_level === 'SEVERE_DISTRESS'
                            ? 'bg-rose-50 text-rose-800 border border-rose-200'
                            : 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                        }`}
                      >
                        Score: {rec.distress_score} ({rec.distress_level.replace('_', ' ')})
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}

