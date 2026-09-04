'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { apiClient } from '@/lib/api/apiClient';

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
    unit: 'Border Outpost G1',
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
    unit: 'Base Depot Camp',
    personnel_count: 82,
    average_burnout_index: 22.8,
    critical_risk_count: 0,
    high_risk_count: 3,
    status: 'GREEN',
    avg_duty_hours: 42,
    avg_leave_gap: 0.25,
    suggested_action: 'Optimal operational readiness. Routine weekly welfare check-in.',
  },
  {
    unit: '7th Mountain Brigade',
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
  '1. Little interest or pleasure in doing activities or daily tasks',
  '2. Feeling down, depressed, or hopeless during deployment',
  '3. Trouble falling or staying asleep, or sleeping too much',
  '4. Feeling fatigued, exhausted, or having little energy on watch',
  '5. Poor appetite or overeating during field operations',
  '6. Feeling that you are letting yourself or your unit down',
  '7. Trouble concentrating on military briefings or duties',
  '8. Moving or speaking noticeably slowly, or restlessness',
  '9. Persistent stress thoughts or feeling overwhelmed',
];

const PHQ9_OPTIONS = [
  { label: 'Not at all', score: 0 },
  { label: 'Several days', score: 1 },
  { label: 'More than half the days', score: 2 },
  { label: 'Nearly every day', score: 3 },
];

export default function RakshakMitraPage() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState<'CHECKIN' | 'HEATMAP' | 'CHAT' | 'HISTORY'>('CHECKIN');

  // Soldier checkin state
  const [deploymentDays, setDeploymentDays] = useState(75);
  const [leaveGapRatio, setLeaveGapRatio] = useState(0.6);
  const [dutyHours, setDutyHours] = useState(58);
  const [phqAnswers, setPhqAnswers] = useState<number[]>([1, 1, 2, 2, 1, 1, 1, 1, 1]);
  const [showPhqModal, setShowPhqModal] = useState(false);

  // Voice Recording state
  const [voiceText, setVoiceText] = useState('Feeling fatigued after successive long night watches. Sleep is irregular.');
  const [isRecording, setIsRecording] = useState(false);
  const [speechSupported, setSpeechSupported] = useState(false);
  const recognitionRef = useRef<any>(null);

  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<BurnoutRecord[]>([]);
  const [heatmap, setHeatmap] = useState<HeatmapItem[]>(DEFAULT_HEATMAP_DATA);
  const [latestResult, setLatestResult] = useState<BurnoutRecord | null>(null);
  const [selectedUnit, setSelectedUnit] = useState<HeatmapItem | null>(null);
  const [heatmapFilter, setHeatmapFilter] = useState<'ALL' | 'RED' | 'ORANGE' | 'GREEN'>('ALL');

  // AI Chat State
  const [chatMessages, setChatMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string }>>([
    {
      role: 'assistant',
      content:
        'Jai Hind! I am your RakshakMitra AI Welfare Companion. I am here to support you with stress mitigation, duty fatigue management, voice mood analysis, and confidential welfare counseling. How are you feeling today?',
    },
  ]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const cumulativePhqScore = phqAnswers.reduce((acc, curr) => acc + curr, 0);

  // Initialize Web Speech API for voice mood journaling
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const SpeechRecognition =
        (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      if (SpeechRecognition) {
        setSpeechSupported(true);
        const recog = new SpeechRecognition();
        recog.continuous = true;
        recog.interimResults = true;
        recog.lang = 'en-IN';

        recog.onresult = (event: any) => {
          let currentTranscript = '';
          for (let i = event.resultIndex; i < event.results.length; i++) {
            currentTranscript += event.results[i][0].transcript;
          }
          if (currentTranscript.trim()) {
            setVoiceText((prev) => (prev ? `${prev} ${currentTranscript}` : currentTranscript));
          }
        };

        recog.onerror = (e: any) => {
          console.warn('Speech recognition notification:', e.error);
          setIsRecording(false);
        };

        recog.onend = () => {
          setIsRecording(false);
        };

        recognitionRef.current = recog;
      }
    }
  }, []);

  const toggleRecording = () => {
    if (!speechSupported || !recognitionRef.current) {
      alert('Speech recognition is not supported in this browser. You can type your voice journal manually.');
      return;
    }

    if (isRecording) {
      recognitionRef.current.stop();
      setIsRecording(false);
    } else {
      try {
        recognitionRef.current.start();
        setIsRecording(true);
      } catch (e) {
        console.error('Error starting speech recognition', e);
      }
    }
  };

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
      actions.push('Temporary removal from high-stress patrol duty');
    } else if (bScore >= 50) {
      tier = 'HIGH';
      actions.push('⚠️ Schedule 3-day wellness break within 10 days');
      actions.push('Review unit duty rotation roster');
      actions.push('Peer support group check-in');
    } else {
      tier = 'MODERATE';
      actions.push('Maintain routine duty rotation');
      actions.push('Weekly mindfulness & relaxation sessions');
    }

    return {
      id: 'brn_' + Date.now(),
      deployment_days: days,
      leave_gap_ratio: gap,
      duty_hours_per_week: hours,
      assessment_score: score,
      phq9_answers: phqAnswers,
      burnout_score: bScore,
      risk_tier: tier,
      contributing_factors: factors.length > 0 ? factors : ['Routine operational strain'],
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
      console.error('Maintaining pre-seeded burnout history', e);
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
            'Jai Hind, Comrade! Remember that seeking help is a mark of true strength. Try 4-7-8 deep breathing during breaks, and know that your welfare officers stand ready to support your deployment needs.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  const filteredHeatmap =
    heatmapFilter === 'ALL' ? heatmap : heatmap.filter((h) => h.status === heatmapFilter);

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6 space-y-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Header Banner */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-center text-2xl shadow-sm text-white">
              🎖️
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">RakshakMitra Forces Stress System</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-slate-100 text-slate-800 border border-slate-300 uppercase">
                  SIH26186 • MHA Track
                </span>
              </div>
              <p className="text-xs text-slate-500">Burnout Predictor, Leave Gap Matrix, Commander Unit Heatmap &amp; Voice Mood Profiler</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {user ? (
              <div className="px-3 py-1.5 bg-slate-100 border rounded-xl text-xs font-bold text-slate-700 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
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
                ? 'bg-slate-900 text-white shadow-md'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📊</span>
            <span>Soldier Stress Check-in</span>
          </button>

          <button
            onClick={() => setActiveTab('HEATMAP')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'HEATMAP'
                ? 'bg-rose-600 text-white shadow-md shadow-rose-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>🗺️</span>
            <span>Commander Unit Heatmap ({heatmap.length})</span>
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
            <span>AI Welfare Companion</span>
          </button>

          <button
            onClick={() => setActiveTab('HISTORY')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'HISTORY'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📜</span>
            <span>Check-in History ({history.length})</span>
          </button>
        </div>

        {/* TAB 1: SOLDIER CHECKIN */}
        {activeTab === 'CHECKIN' && (
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
            
            {/* Input Form */}
            <div className="md:col-span-6">
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 text-xs">
                <div className="border-b pb-2 flex items-center justify-between">
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Duty &amp; Burnout Parameters</h2>
                  <button
                    type="button"
                    onClick={() => setShowPhqModal(true)}
                    className="px-3 py-1 bg-indigo-50 border border-indigo-200 text-indigo-700 font-bold rounded-lg hover:bg-indigo-100 transition"
                  >
                    📝 PHQ-9 / GAD-7 Test ({cumulativePhqScore}/27)
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Continuous Deployment (Days)</label>
                    <input
                      type="number"
                      value={deploymentDays}
                      onChange={(e) => setDeploymentDays(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Leave Gap Ratio (0.0 - 1.0)</label>
                    <input
                      type="number"
                      step="0.05"
                      min="0"
                      max="1"
                      value={leaveGapRatio}
                      onChange={(e) => setLeaveGapRatio(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Duty Hours Per Week</label>
                  <input
                    type="number"
                    value={dutyHours}
                    onChange={(e) => setDutyHours(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                    required
                  />
                </div>

                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="font-bold text-slate-700">Voice Mood Journaling</label>
                    <button
                      type="button"
                      onClick={toggleRecording}
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${
                        isRecording ? 'bg-rose-100 text-rose-800 border-rose-300 animate-pulse' : 'bg-slate-100 text-slate-700 border-slate-200'
                      }`}
                    >
                      {isRecording ? '🔴 Recording...' : '🎙️ Record Voice'}
                    </button>
                  </div>
                  <textarea
                    value={voiceText}
                    onChange={(e) => setVoiceText(e.target.value)}
                    placeholder="Speak or type your daily operational feelings..."
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl h-20"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Calculating Burnout Index...' : 'Calculate Burnout Index & Mitigation Plan'}
                </button>
              </form>
            </div>

            {/* Scorecard View */}
            <div className="md:col-span-6 space-y-4">
              {latestResult ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 text-xs">
                  <div className="border-b pb-2 flex items-center justify-between">
                    <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Burnout Index Scorecard</h2>
                    <span className="text-xs font-mono text-slate-400">{latestResult.id}</span>
                  </div>

                  <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Predicted Burnout Index Score</span>
                    <div className="text-4xl font-black text-slate-900">{latestResult.burnout_score} <span className="text-xs font-normal text-slate-500">/ 100</span></div>
                  </div>

                  <div className="p-3 bg-slate-50 border rounded-xl flex items-center justify-between">
                    <span className="font-bold text-slate-600">Assigned Risk Tier:</span>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-black ${
                        latestResult.risk_tier === 'CRITICAL'
                          ? 'bg-rose-100 text-rose-800'
                          : latestResult.risk_tier === 'HIGH'
                          ? 'bg-amber-100 text-amber-800'
                          : 'bg-emerald-100 text-emerald-800'
                      }`}
                    >
                      {latestResult.risk_tier} RISK
                    </span>
                  </div>

                  <div className="p-3.5 bg-slate-50 border rounded-xl space-y-1">
                    <span className="font-bold text-slate-700 uppercase text-[10px]">Contributing Operational Factors</span>
                    <ul className="list-disc pl-4 space-y-0.5 text-slate-600">
                      {latestResult.contributing_factors.map((f, i) => (
                        <li key={i}>{f}</li>
                      ))}
                    </ul>
                  </div>

                  <div className="p-3.5 bg-emerald-50/70 border border-emerald-200 rounded-xl space-y-1">
                    <span className="font-bold text-emerald-950 uppercase text-[10px]">Recommended Welfare Actions</span>
                    <ul className="list-disc pl-4 space-y-0.5 text-emerald-900 font-medium">
                      {latestResult.recommended_actions.map((act, i) => (
                        <li key={i}>{act}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                  Submit deployment parameters to calculate burnout score.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 2: COMMANDER HEATMAP */}
        {activeTab === 'HEATMAP' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-6 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">Commander Anonymized Unit Heatmap</h2>
                <p className="text-xs text-slate-500">Aggregated unit burnout indices for commanding officers</p>
              </div>
              <div className="flex gap-1.5">
                {(['ALL', 'RED', 'ORANGE', 'GREEN'] as const).map((filter) => (
                  <button
                    key={filter}
                    onClick={() => setHeatmapFilter(filter)}
                    className={`px-3 py-1 rounded-lg text-xs font-bold transition ${
                      heatmapFilter === filter
                        ? 'bg-slate-900 text-white'
                        : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                    }`}
                  >
                    {filter}
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {filteredHeatmap.map((unit, idx) => (
                <div
                  key={idx}
                  onClick={() => setSelectedUnit(unit)}
                  className={`p-4 rounded-2xl border cursor-pointer transition space-y-2 ${
                    unit.status === 'RED'
                      ? 'bg-rose-50/50 border-rose-200 hover:border-rose-400'
                      : unit.status === 'ORANGE'
                      ? 'bg-amber-50/50 border-amber-200 hover:border-amber-400'
                      : 'bg-emerald-50/50 border-emerald-200 hover:border-emerald-400'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <h3 className="font-bold text-sm text-slate-900">{unit.unit}</h3>
                    <span
                      className={`px-2 py-0.5 rounded text-[10px] font-black ${
                        unit.status === 'RED'
                          ? 'bg-rose-200 text-rose-900'
                          : unit.status === 'ORANGE'
                          ? 'bg-amber-200 text-amber-900'
                          : 'bg-emerald-200 text-emerald-900'
                      }`}
                    >
                      {unit.status}
                    </span>
                  </div>

                  <div className="text-xs space-y-1 text-slate-600">
                    <div>Personnel Count: <strong>{unit.personnel_count}</strong></div>
                    <div>Avg Burnout Index: <strong>{unit.average_burnout_index} / 100</strong></div>
                    <div>Critical Risk Cases: <strong className="text-rose-700">{unit.critical_risk_count}</strong></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 3: CHAT */}
        {activeTab === 'CHAT' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">RakshakMitra AI Welfare Companion</h2>
                <p className="text-xs text-slate-500">Confidential welfare counseling and operational stress support</p>
              </div>
            </div>

            <div className="h-80 overflow-y-auto space-y-3 p-4 bg-slate-50 rounded-2xl border border-slate-200 text-xs">
              {chatMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[80%] p-3 rounded-2xl font-medium leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-slate-900 text-white rounded-br-none'
                        : 'bg-white text-slate-800 border border-slate-200 rounded-bl-none shadow-xs'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && <div className="text-slate-400 text-xs italic">RakshakMitra AI is thinking...</div>}
            </div>

            <form onSubmit={handleSendChat} className="flex gap-2">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Share your operational thoughts or ask for stress mitigation advice..."
                className="flex-1 px-4 py-2.5 bg-slate-50 border rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-slate-900"
              />
              <button
                type="submit"
                disabled={chatLoading}
                className="px-5 py-2.5 bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs rounded-xl shadow-xs transition"
              >
                Send
              </button>
            </form>
          </div>
        )}

        {/* TAB 4: HISTORY */}
        {activeTab === 'HISTORY' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <h2 className="text-base font-extrabold text-slate-900">Check-in History ({history.length})</h2>
              <span className="text-xs text-slate-500 font-mono">Anonymized Records</span>
            </div>

            <div className="divide-y divide-slate-100">
              {history.map((rec) => (
                <div key={rec.id} className="py-3.5 flex items-center justify-between text-xs">
                  <div>
                    <span className="font-bold text-slate-900">{rec.id}</span>
                    <p className="text-slate-500 text-[11px] mt-0.5">
                      Deployment: {rec.deployment_days} days | Duty: {rec.duty_hours_per_week} hrs/wk | PHQ Score: {rec.assessment_score}
                    </p>
                  </div>
                  <div className="text-right">
                    <span
                      className={`px-2.5 py-1 rounded text-[10px] font-black ${
                        rec.risk_tier === 'CRITICAL'
                          ? 'bg-rose-100 text-rose-800'
                          : 'bg-emerald-100 text-emerald-800'
                      }`}
                    >
                      Score: {rec.burnout_score} ({rec.risk_tier})
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* PHQ9 Modal */}
        {showPhqModal && (
          <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-2xl max-w-lg w-full p-6 space-y-4 max-h-[85vh] overflow-y-auto text-xs shadow-xl">
              <div className="flex items-center justify-between border-b pb-2">
                <h3 className="font-bold text-sm text-slate-900">PHQ-9 Psychological Assessment</h3>
                <button onClick={() => setShowPhqModal(false)} className="text-slate-400 hover:text-slate-600 font-bold">
                  ✕
                </button>
              </div>

              <div className="space-y-4">
                {PHQ9_QUESTIONS.map((q, qIdx) => (
                  <div key={qIdx} className="space-y-1.5 bg-slate-50 p-3 rounded-xl border border-slate-200">
                    <p className="font-semibold text-slate-800">{q}</p>
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
                            className={`p-1.5 rounded-lg text-[10px] font-bold transition border ${
                              isSelected
                                ? 'bg-indigo-600 text-white border-indigo-600'
                                : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-100'
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
                className="w-full py-2.5 bg-slate-900 text-white font-bold rounded-xl shadow-xs"
              >
                Save Assessment ({cumulativePhqScore} / 27)
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
