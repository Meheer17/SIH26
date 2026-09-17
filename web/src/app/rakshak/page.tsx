'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { apiClient } from '@/lib/api/apiClient';
import VoiceStressRecorder, { VoiceStressResult } from '@/components/VoiceStressRecorder';

interface MoodTrajectory {
  sentiment_polarity: number;
  trajectory_state: string;
  trajectory_label: string;
  detected_markers: string[];
}

interface BurnoutRecord {
  id: string;
  deployment_days: number;
  leave_gap_ratio: number;
  duty_hours_per_week: number;
  assessment_score: number;
  phq9_answers?: number[];
  gad7_answers?: number[];
  burnout_score: number;
  risk_tier: string;
  contributing_factors: string[];
  recommended_actions: string[];
  voice_journal_text?: string;
  mood_trajectory?: MoodTrajectory;
  created_at: string;
}

interface HeatmapItem {
  unit: string;
  personnel_count: number;
  average_burnout_index: number;
  critical_risk_count: number;
  high_risk_count: number;
  status: 'RED' | 'ORANGE' | 'GREEN';
  avg_duty_hours?: number;
  avg_leave_gap?: number;
  suggested_action?: string;
}

const DEFAULT_HEATMAP_DATA: HeatmapItem[] = [
  {
    unit: '15th Rajput Regiment',
    personnel_count: 24,
    average_burnout_index: 45.2,
    critical_risk_count: 2,
    high_risk_count: 5,
    status: 'ORANGE',
    avg_duty_hours: 56,
    avg_leave_gap: 0.5,
    suggested_action: 'Rebalance night patrol roster and schedule 3-day wellness break.',
  },
  {
    unit: 'Border Outpost G1 (Forward Line)',
    personnel_count: 14,
    average_burnout_index: 78.4,
    critical_risk_count: 5,
    high_risk_count: 6,
    status: 'RED',
    avg_duty_hours: 68,
    avg_leave_gap: 0.85,
    suggested_action: 'Mandatory 7-day R&R rotation and immediate unit counselor visit.',
  },
  {
    unit: 'Base Depot Camp & Logistical Hub',
    personnel_count: 82,
    average_burnout_index: 22.8,
    critical_risk_count: 0,
    high_risk_count: 3,
    status: 'GREEN',
    avg_duty_hours: 42,
    avg_leave_gap: 0.25,
    suggested_action: 'Optimal operational readiness. Maintain routine weekly welfare check-in.',
  },
  {
    unit: '7th Mountain Brigade (High Altitude)',
    personnel_count: 32,
    average_burnout_index: 72.1,
    critical_risk_count: 6,
    high_risk_count: 8,
    status: 'RED',
    avg_duty_hours: 64,
    avg_leave_gap: 0.78,
    suggested_action: 'High altitude strain detected. Dispatch medical check-up team.',
  },
];

const PHQ9_QUESTIONS = [
  '1. Little interest or pleasure in doing daily tasks or briefings',
  '2. Feeling down, depressed, or hopeless during deployment',
  '3. Trouble falling or staying asleep, or irregular sleep cycles',
  '4. Feeling fatigued, exhausted, or having little energy on watch',
  '5. Poor appetite or skipping meals during field operations',
  '6. Feeling that you are letting yourself or your unit down',
  '7. Trouble concentrating on military briefings or duties',
  '8. Noticeably slow speech/movements or severe restlessness',
  '9. Persistent stress thoughts or feeling overwhelmed',
];

const PHQ9_OPTIONS = [
  { label: 'Not at all', score: 0 },
  { label: 'Several days', score: 1 },
  { label: 'More than half the days', score: 2 },
  { label: 'Nearly every day', score: 3 },
];

export default function RakshakMitraPage() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'CHECKIN' | 'VOICE_STRESS' | 'HEATMAP' | 'CHAT' | 'HISTORY'>('CHECKIN');

  // Soldier checkin state
  const [deploymentDays, setDeploymentDays] = useState(75);
  const [leaveGapRatio, setLeaveGapRatio] = useState(0.6);
  const [dutyHours, setDutyHours] = useState(58);
  const [phqAnswers, setPhqAnswers] = useState<number[]>([1, 1, 2, 2, 1, 1, 1, 1, 1]);
  const [showPhqModal, setShowPhqModal] = useState(false);

  // Voice Recording & Stress/Fatigue state
  const [voiceText, setVoiceText] = useState('Feeling fatigued after successive long night watches. Sleep is irregular.');
  const [voiceStressResult, setVoiceStressResult] = useState<VoiceStressResult | null>(null);
  const [showVoiceRecorderModal, setShowVoiceRecorderModal] = useState(false);

  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<BurnoutRecord[]>([]);
  const [heatmap, setHeatmap] = useState<HeatmapItem[]>(DEFAULT_HEATMAP_DATA);
  const [latestResult, setLatestResult] = useState<BurnoutRecord | null>(null);
  const [heatmapFilter, setHeatmapFilter] = useState<'ALL' | 'RED' | 'ORANGE' | 'GREEN'>('ALL');

  const fetchHeatmap = async () => {
    try {
      const res = await fetch("http://localhost:8000/api/v1/apps/rakshak/heatmap");
      if (res.ok) {
        const data = await res.json();
        if (data.garrison_units) {
          const items: HeatmapItem[] = data.garrison_units.map((g: any) => ({
            unit: g.name,
            personnel_count: g.total_strength,
            average_burnout_index: g.stress_score,
            critical_risk_count: g.high_stress_soldiers,
            high_risk_count: Math.ceil(g.high_stress_soldiers * 1.5),
            status: g.risk_tier === "CRITICAL" ? "RED" : (g.risk_tier === "HIGH" ? "ORANGE" : "GREEN"),
            avg_duty_hours: 58,
            avg_leave_gap: 0.6,
            suggested_action: g.primary_stressor
          }));
          setHeatmap(items);
        }
      }
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchHeatmap();
  }, []);

  // AI Chat State
  const [chatMessages, setChatMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string }>>([
    {
      role: 'assistant',
      content:
        'Jai Hind! I am your RakshakMitra AI Welfare Companion. I am here to support you with operational fatigue management, stress mitigation, acoustic voice mood profiling, and confidential welfare counseling. How are you feeling today?',
    },
  ]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const cumulativePhqScore = phqAnswers.reduce((acc, curr) => acc + curr, 0);

  const calculateBurnout = (days: number, gap: number, hours: number, score: number): BurnoutRecord => {
    let bScore = Math.round(
      0.35 * Math.min(100, (days / 120) * 100) +
      0.30 * Math.min(100, (gap / 1.0) * 100) +
      0.20 * Math.min(100, (hours / 80) * 100) +
      0.15 * Math.min(100, (score / 27) * 100)
    );
    bScore = Math.max(10, Math.min(99, bScore));

    let tier = 'LOW';
    const factors: string[] = [];
    const actions: string[] = [];

    if (days > 60) factors.push('Extended continuous deployment (>60 days)');
    if (gap > 0.5) factors.push('Overdue leave gap ratio (>0.5)');
    if (hours > 56) factors.push('Excessive duty hours (>56 hrs/week)');
    if (score > 10) factors.push('Elevated PHQ-9 distress score (>10)');

    if (bScore >= 75) {
      tier = 'CRITICAL';
      actions.push('🚨 Immediate 7-day R&R Leave Authorization recommended');
      actions.push('Mandatory 1-on-1 confidential counseling session');
      actions.push('Temporary rotation from high-stress watch & night patrol');
    } else if (bScore >= 50) {
      tier = 'HIGH';
      actions.push('⚠️ Schedule 3-day wellness break within 10 days');
      actions.push('Review unit duty rotation roster');
      actions.push('Peer support group check-in');
    } else {
      tier = 'MODERATE';
      actions.push('Maintain routine duty rotation');
      actions.push('Weekly mindfulness & recovery sessions');
    }

    return {
      id: 'BRN-' + Date.now().toString().slice(-6),
      deployment_days: days,
      leave_gap_ratio: gap,
      duty_hours_per_week: hours,
      assessment_score: score,
      phq9_answers: phqAnswers,
      burnout_score: bScore,
      risk_tier: tier,
      contributing_factors: factors.length > 0 ? factors : ['Routine operational deployment strain'],
      recommended_actions: actions,
      voice_journal_text: voiceText,
      mood_trajectory: {
        sentiment_polarity: -0.32,
        trajectory_state: 'HIGH_STRESS',
        trajectory_label: 'Elevated Operational Exhaustion',
        detected_markers: ['fatigue', 'duty_strain', 'sleep_disturbance'],
      },
      created_at: new Date().toISOString(),
    };
  };

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get<BurnoutRecord[]>('/apps/rakshak/checkin');
      if (Array.isArray(data) && data.length > 0) {
        setHistory(data);
        setLatestResult(data[0]);
        return;
      }
    } catch (e) {
      console.warn('Maintaining pre-seeded burnout history', e);
    }

    const initRec = calculateBurnout(deploymentDays, leaveGapRatio, dutyHours, cumulativePhqScore);
    setLatestResult(initRec);
    setHistory([initRec]);
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    let record: BurnoutRecord;

    try {
      record = await apiClient.post<BurnoutRecord>('/apps/rakshak/checkin', {
        deployment_days: deploymentDays,
        leave_gap_ratio: leaveGapRatio,
        duty_hours_per_week: dutyHours,
        assessment_score: cumulativePhqScore,
        phq9_answers: phqAnswers,
        voice_journal_text: voiceText,
      });
    } catch {
      record = calculateBurnout(deploymentDays, leaveGapRatio, dutyHours, cumulativePhqScore);
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
        agent_id: 'rakshak_mitra_agent',
        messages: newMessages,
      });
      setChatMessages([...newMessages, { role: 'assistant', content: res.content }]);
    } catch {
      setChatMessages([
        ...newMessages,
        {
          role: 'assistant',
          content:
            'Jai Hind, Comrade! Remember that seeking help is a mark of true strength. Try 4-7-8 deep breathing during rest breaks, and know that your welfare officers stand ready to support your deployment needs.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  const filteredHeatmap =
    heatmapFilter === 'ALL' ? heatmap : heatmap.filter((h) => h.status === heatmapFilter);

  return (
    <div className="min-h-screen bg-[#fafaf9] text-stone-900 font-sans pb-16">
      {/* Top Breadcrumb & Status */}
      <div className="border-b border-stone-200 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between text-xs text-stone-500">
          <div className="flex items-center gap-2">
            <Link href="/" className="hover:text-stone-900 transition font-medium">SvasthyaSetu</Link>
            <span>/</span>
            <span className="font-semibold text-stone-900">RakshakMitra Forces Wellness</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="hidden sm:inline-flex items-center gap-1.5 text-stone-600 font-medium">
              <span className="w-2 h-2 rounded-full bg-amber-500"></span>
              Encrypted Operational Channel
            </span>
            <span className="px-2 py-0.5 rounded text-[11px] font-mono font-bold bg-amber-50 text-amber-900 border border-amber-200">
              SIH26186 • MHA Track
            </span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 pt-8 space-y-8">
        
        {/* Module Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-stone-200 pb-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-md bg-stone-100 border border-stone-200 text-stone-700 text-xs font-medium">
              <span>🎖️</span>
              <span>Armed Forces Psychological Wellness &amp; Burnout Early-Warning</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-semibold tracking-tight text-stone-900">
              RakshakMitra Operational System
            </h1>
            <p className="text-stone-600 text-sm max-w-2xl leading-relaxed">
              Longitudinal duty fatigue tracking, leave gap matrix, unit-level burnout heatmaps, and acoustic voice stress profiling for commanders and personnel.
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
            <span>Soldier Stress Check-in</span>
          </button>

          <button
            onClick={() => setActiveTab('VOICE_STRESS')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'VOICE_STRESS'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>🎙️</span>
            <span>Voice Stress &amp; Fatigue Scanner</span>
          </button>

          <button
            onClick={() => setActiveTab('HEATMAP')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'HEATMAP'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>🗺️</span>
            <span>Commander Unit Heatmap</span>
            <span className="px-1.5 py-0.5 rounded text-[10px] font-mono bg-stone-100 text-stone-700">
              {heatmap.length}
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
            <span>AI Welfare Companion</span>
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
            <span>Check-in History</span>
            <span className="px-1.5 py-0.5 rounded text-[10px] font-mono bg-stone-100 text-stone-700">
              {history.length}
            </span>
          </button>
        </div>

        {/* ========================================================================= */}
        {/* TAB 1: SOLDIER STRESS CHECK-IN */}
        {/* ========================================================================= */}
        {activeTab === 'CHECKIN' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            
            {/* Input Form (Left) */}
            <div className="lg:col-span-6 space-y-6">
              <form onSubmit={handleSubmit} className="bg-white border border-stone-200 rounded-xl p-6 sm:p-7 shadow-xs space-y-6 text-xs">
                <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                  <div>
                    <h2 className="text-sm font-semibold text-stone-900">Duty &amp; Deployment Parameters</h2>
                    <p className="text-[11px] text-stone-500">Confidential self-assessment for duty rotation balance</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => setShowPhqModal(true)}
                    className="px-3 py-1.5 bg-stone-100 hover:bg-stone-200 border border-stone-300 text-stone-800 font-semibold rounded-lg transition"
                  >
                    📝 PHQ-9 Test ({cumulativePhqScore}/27)
                  </button>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="font-semibold text-stone-700">Continuous Deployment (Days)</label>
                    <input
                      type="number"
                      value={deploymentDays}
                      onChange={(e) => setDeploymentDays(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                      required
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="font-semibold text-stone-700">Leave Gap Ratio (0.0 to 1.0)</label>
                    <input
                      type="number"
                      step="0.05"
                      min="0"
                      max="1"
                      value={leaveGapRatio}
                      onChange={(e) => setLeaveGapRatio(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                      required
                    />
                  </div>
                </div>

                <div className="space-y-1.5">
                  <div className="flex items-center justify-between">
                    <label className="font-semibold text-stone-700">Weekly Duty Hours</label>
                    <span className="font-mono font-bold text-stone-900">{dutyHours} hrs/week</span>
                  </div>
                  <input
                    type="range"
                    min="30"
                    max="90"
                    value={dutyHours}
                    onChange={(e) => setDutyHours(Number(e.target.value))}
                    className="w-full h-2 bg-stone-200 rounded-lg appearance-none cursor-pointer accent-stone-900"
                  />
                </div>

                <div className="space-y-2 pt-2 border-t border-stone-100">
                  <div className="flex items-center justify-between">
                    <label className="font-semibold text-stone-700">Voice Mood &amp; Fatigue Journal</label>
                    <button
                      type="button"
                      onClick={() => setShowVoiceRecorderModal(true)}
                      className="px-2.5 py-1 rounded-md text-[11px] font-semibold bg-stone-900 text-white hover:bg-stone-800 transition flex items-center gap-1 shadow-xs"
                    >
                      <span>🎙️ Live Acoustic Scan</span>
                    </button>
                  </div>
                  <textarea
                    value={voiceText}
                    onChange={(e) => setVoiceText(e.target.value)}
                    placeholder="Speak using the acoustic recorder or type your daily operational feelings..."
                    rows={3}
                    className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium leading-relaxed"
                  />

                  {voiceStressResult && (
                    <div className="p-3 bg-stone-900 text-stone-100 rounded-lg text-xs space-y-1">
                      <div className="flex items-center justify-between">
                        <span className="text-stone-300 font-medium">Acoustic Biomarkers Recorded:</span>
                        <span className="text-[10px] font-mono text-amber-400 font-semibold">{voiceStressResult.fatigue_tier}</span>
                      </div>
                      <div className="flex gap-4 text-[11px] text-stone-300">
                        <span>Fatigue: <strong className="text-amber-400">{voiceStressResult.voice_fatigue_score}/100</strong></span>
                        <span>Stress: <strong className="text-rose-400">{voiceStressResult.voice_stress_score}/100</strong></span>
                        <span>Cadence: <strong>{voiceStressResult.acoustic_markers.speech_cadence}</strong></span>
                      </div>
                    </div>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-stone-900 hover:bg-stone-800 text-white font-semibold text-xs rounded-xl shadow-xs transition disabled:opacity-50"
                >
                  {loading ? 'Evaluating Burnout Risk...' : 'Calculate Burnout Index & Mitigation Protocol'}
                </button>
              </form>
            </div>

            {/* Scorecard View (Right) */}
            <div className="lg:col-span-6 space-y-6">
              {latestResult ? (
                <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-7 shadow-xs space-y-6 text-xs">
                  <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                    <div>
                      <h2 className="text-sm font-semibold text-stone-900">Burnout Index Scorecard</h2>
                      <span className="text-[11px] text-stone-400 font-mono">Reference: {latestResult.id}</span>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-md text-xs font-semibold ${
                        latestResult.risk_tier === 'CRITICAL'
                          ? 'bg-rose-50 text-rose-800 border border-rose-200'
                          : latestResult.risk_tier === 'HIGH'
                          ? 'bg-amber-50 text-amber-800 border border-amber-200'
                          : 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                      }`}
                    >
                      {latestResult.risk_tier} RISK TIER
                    </span>
                  </div>

                  {/* Primary Score Tile */}
                  <div className="p-6 rounded-xl bg-stone-50 border border-stone-200 text-center space-y-1">
                    <span className="text-[10px] uppercase font-semibold text-stone-500 tracking-wider">
                      Composite Predicted Burnout Index
                    </span>
                    <div className="text-4xl font-semibold tracking-tight text-stone-900">
                      {latestResult.burnout_score} <span className="text-base font-normal text-stone-500">/ 100</span>
                    </div>
                    <p className="text-[11px] text-stone-500 pt-1">
                      Computed from deployment timeline, leave deficit, watch duration, and PHQ assessment.
                    </p>
                  </div>

                  {/* Factors Breakdown */}
                  <div className="p-4 bg-white border border-stone-200 rounded-xl space-y-2">
                    <span className="text-[10px] uppercase font-semibold text-stone-400 block tracking-wider">
                      Contributing Operational Stressors
                    </span>
                    <ul className="space-y-1.5 text-stone-700 font-medium">
                      {latestResult.contributing_factors.map((f, i) => (
                        <li key={i} className="flex items-start gap-2">
                          <span className="text-amber-600 font-bold">&bull;</span>
                          <span>{f}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  {/* Recommended Welfare Protocol */}
                  <div className="p-4 bg-emerald-50/70 border border-emerald-200 rounded-xl space-y-2">
                    <span className="text-[10px] uppercase font-semibold text-emerald-900 block tracking-wider">
                      Recommended Duty &amp; Welfare Mitigations
                    </span>
                    <ul className="space-y-1.5 text-emerald-950 font-medium">
                      {latestResult.recommended_actions.map((act, i) => (
                        <li key={i} className="flex items-start gap-2">
                          <span className="text-emerald-700 font-bold">✓</span>
                          <span>{act}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-stone-200 rounded-xl p-12 text-center text-stone-400 text-xs italic shadow-xs">
                  Submit deployment parameters to compute unit burnout scorecard.
                </div>
              )}
            </div>

          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 2: VOICE STRESS SCANNER */}
        {/* ========================================================================= */}
        {activeTab === 'VOICE_STRESS' && (
          <div className="max-w-4xl mx-auto space-y-4">
            <VoiceStressRecorder
              onAnalysisComplete={(res) => {
                setVoiceStressResult(res);
                setVoiceText(res.text);
              }}
              onTranscriptChange={(t) => setVoiceText(t)}
              title="Soldier Voice Stress &amp; Fatigue Analyzer"
              description="Record spoken mission debriefs to evaluate vocal micro-tremors, pause ratios, operational fatigue, and emotional burnout."
            />
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 3: COMMANDER HEATMAP */}
        {/* ========================================================================= */}
        {activeTab === 'HEATMAP' && (
          <div className="max-w-5xl mx-auto space-y-6">
            <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-8 shadow-xs space-y-6">
              <div className="border-b border-stone-200 pb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">Commander Anonymized Unit Heatmap</h2>
                  <p className="text-xs text-stone-500">Aggregated brigade &amp; outpost burnout indices for commanding officers</p>
                </div>
                
                {/* Filter Pills */}
                <div className="flex items-center gap-1.5 bg-stone-100 p-1 rounded-lg">
                  {(['ALL', 'RED', 'ORANGE', 'GREEN'] as const).map((filter) => (
                    <button
                      key={filter}
                      onClick={() => setHeatmapFilter(filter)}
                      className={`px-3 py-1 rounded-md text-xs font-semibold transition ${
                        heatmapFilter === filter
                          ? 'bg-white text-stone-900 shadow-xs'
                          : 'text-stone-500 hover:text-stone-900'
                      }`}
                    >
                      {filter}
                    </button>
                  ))}
                </div>
              </div>

              {/* Heatmap Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {filteredHeatmap.map((unit, idx) => (
                  <div
                    key={idx}
                    className={`p-5 rounded-xl border space-y-3 transition ${
                      unit.status === 'RED'
                        ? 'bg-rose-50/40 border-rose-200'
                        : unit.status === 'ORANGE'
                        ? 'bg-amber-50/40 border-amber-200'
                        : 'bg-emerald-50/40 border-emerald-200'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <h3 className="font-semibold text-sm text-stone-900">{unit.unit}</h3>
                      <span
                        className={`px-2.5 py-0.5 rounded text-[10px] font-bold uppercase ${
                          unit.status === 'RED'
                            ? 'bg-rose-100 text-rose-800'
                            : unit.status === 'ORANGE'
                            ? 'bg-amber-100 text-amber-800'
                            : 'bg-emerald-100 text-emerald-800'
                        }`}
                      >
                        {unit.status} Status
                      </span>
                    </div>

                    <div className="grid grid-cols-3 gap-2 text-center text-xs pt-1">
                      <div className="bg-white/80 p-2 rounded-lg border border-stone-200">
                        <span className="text-[10px] text-stone-400 uppercase block">Personnel</span>
                        <span className="font-semibold text-stone-900">{unit.personnel_count}</span>
                      </div>
                      <div className="bg-white/80 p-2 rounded-lg border border-stone-200">
                        <span className="text-[10px] text-stone-400 uppercase block">Avg Burnout</span>
                        <span className="font-semibold text-stone-900">{unit.average_burnout_index}</span>
                      </div>
                      <div className="bg-white/80 p-2 rounded-lg border border-stone-200">
                        <span className="text-[10px] text-stone-400 uppercase block">Critical</span>
                        <span className="font-semibold text-rose-700">{unit.critical_risk_count}</span>
                      </div>
                    </div>

                    <div className="text-xs space-y-1 pt-1 text-stone-600">
                      <div className="flex items-center justify-between text-[11px]">
                        <span>Average Duty: <strong>{unit.avg_duty_hours} hrs/wk</strong></span>
                        <span>Leave Gap Ratio: <strong>{unit.avg_leave_gap}</strong></span>
                      </div>
                      <p className="text-[11px] text-stone-800 font-medium bg-white/60 p-2.5 rounded-lg border border-stone-200">
                        Recommendation: {unit.suggested_action}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 4: AI WELFARE COMPANION */}
        {/* ========================================================================= */}
        {activeTab === 'CHAT' && (
          <div className="max-w-4xl mx-auto space-y-4">
            <div className="bg-white border border-stone-200 rounded-xl p-6 shadow-xs space-y-4">
              <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">RakshakMitra AI Welfare Companion</h2>
                  <p className="text-xs text-stone-500">Confidential welfare counseling and operational stress decompression</p>
                </div>
                <span className="px-2.5 py-1 rounded text-[11px] font-semibold bg-emerald-50 text-emerald-800 border border-emerald-200">
                  Confidential Counseling
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
                    RakshakMitra AI is preparing counsel...
                  </div>
                )}
              </div>

              {/* Chat Input */}
              <form onSubmit={handleSendChat} className="flex gap-2">
                <input
                  type="text"
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  placeholder="Share your thoughts or ask for stress mitigation counsel..."
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
        {/* TAB 5: CHECK-IN HISTORY */}
        {/* ========================================================================= */}
        {activeTab === 'HISTORY' && (
          <div className="max-w-4xl mx-auto space-y-6">
            <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-8 shadow-xs space-y-4">
              <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">Longitudinal Check-in Records</h2>
                  <p className="text-xs text-stone-500">Anonymized deployment welfare logs</p>
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
                        Deployment: {rec.deployment_days} days &bull; Duty: {rec.duty_hours_per_week} hrs/wk &bull; PHQ Score: {rec.assessment_score}/27
                      </p>
                    </div>
                    <div className="text-right">
                      <span
                        className={`px-2.5 py-1 rounded text-[11px] font-semibold ${
                          rec.risk_tier === 'CRITICAL'
                            ? 'bg-rose-50 text-rose-800 border border-rose-200'
                            : 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                        }`}
                      >
                        Score: {rec.burnout_score} ({rec.risk_tier})
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* MODAL: PHQ-9 TEST */}
        {/* ========================================================================= */}
        {showPhqModal && (
          <div className="fixed inset-0 bg-stone-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-2xl max-w-xl w-full p-6 sm:p-7 space-y-5 max-h-[85vh] overflow-y-auto text-xs shadow-xl">
              <div className="flex items-center justify-between border-b border-stone-200 pb-3">
                <div>
                  <h3 className="font-semibold text-sm text-stone-900">PHQ-9 Psychological Assessment</h3>
                  <p className="text-[11px] text-stone-500">Confidential clinical screening for duty fatigue and emotional distress</p>
                </div>
                <button
                  onClick={() => setShowPhqModal(false)}
                  className="text-stone-400 hover:text-stone-700 font-semibold p-1"
                >
                  ✕
                </button>
              </div>

              <div className="space-y-4">
                {PHQ9_QUESTIONS.map((q, qIdx) => (
                  <div key={qIdx} className="space-y-2 bg-stone-50 p-3.5 rounded-xl border border-stone-200">
                    <p className="font-medium text-stone-800">{q}</p>
                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-1.5">
                      {PHQ9_OPTIONS.map((opt) => {
                        const isSelected = phqAnswers[qIdx] === opt.score;
                        return (
                          <button
                            key={opt.score}
                            type="button"
                            onClick={() => {
                              const newAns = [...phqAnswers];
                              newAns[qIdx] = opt.score;
                              setPhqAnswers(newAns);
                            }}
                            className={`p-2 rounded-lg text-[10px] font-semibold transition border ${
                              isSelected
                                ? 'bg-stone-900 text-white border-stone-900 shadow-xs'
                                : 'bg-white text-stone-700 border-stone-200 hover:bg-stone-100'
                            }`}
                          >
                            {opt.label}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>

              <button
                onClick={() => setShowPhqModal(false)}
                className="w-full py-3 bg-stone-900 hover:bg-stone-800 text-white font-semibold rounded-xl shadow-xs transition text-xs"
              >
                Save Assessment (Total Score: {cumulativePhqScore} / 27)
              </button>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* MODAL: VOICE RECORDER */}
        {/* ========================================================================= */}
        {showVoiceRecorderModal && (
          <div className="fixed inset-0 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <div className="max-w-2xl w-full">
              <div className="flex justify-end mb-2">
                <button
                  type="button"
                  onClick={() => setShowVoiceRecorderModal(false)}
                  className="px-3 py-1 bg-stone-800 text-stone-300 hover:text-white rounded-lg text-xs font-semibold"
                >
                  ✕ Close Recorder
                </button>
              </div>
              <VoiceStressRecorder
                onAnalysisComplete={(res) => {
                  setVoiceStressResult(res);
                  setVoiceText(res.text);
                  setShowVoiceRecorderModal(false);
                }}
                onTranscriptChange={(t) => setVoiceText(t)}
                title="Soldier Voice Stress &amp; Fatigue Analyzer"
                description="Speak freely into your microphone to capture duty fatigue, acoustic micro-tremors, and voice stress."
              />
            </div>
          </div>
        )}

      </div>
    </div>
  );
}

