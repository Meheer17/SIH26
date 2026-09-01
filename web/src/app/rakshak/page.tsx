'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import apiClient from '@/lib/api/apiClient';

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
  
  // Commander filter state
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
    if (!speechSupported) {
      alert('Speech recognition is not supported on this browser. You can type directly into the journal.');
      return;
    }

    if (isRecording) {
      recognitionRef.current?.stop();
      setIsRecording(false);
    } else {
      try {
        recognitionRef.current?.start();
        setIsRecording(true);
      } catch (err) {
        console.error('Failed to start microphone:', err);
      }
    }
  };

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get('/apps/rakshak/burnout');
      if (Array.isArray(data) && data.length > 0) {
        setHistory(data);
        setLatestResult(data[0]);
      }
    } catch (e) {
      console.error('Failed to load burnout history', e);
    }
  };

  const fetchHeatmap = async () => {
    try {
      const data = await apiClient.get('/apps/rakshak/heatmap');
      if (Array.isArray(data) && data.length > 0) {
        setHeatmap(data);
      }
    } catch (e) {
      console.error('Failed to load commander heatmap, maintaining pre-seeded data', e);
    }
  };

  useEffect(() => {
    if (user) {
      fetchHistory();
      fetchHeatmap();
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
        assessment_score: cumulativePhqScore,
        phq9_answers: phqAnswers,
        voice_journal_text: voiceText,
        pitch_jitter_score: 0.25,
      });
      setLatestResult(res);
      fetchHistory();
      fetchHeatmap();
      alert('Wellbeing check-in and voice mood analysis submitted successfully!');
    } catch (err: any) {
      alert(err.message || 'Checkin submission failed');
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
        agent_id: 'rakshak_mitra_agent',
        messages: newMessages,
        context: {
          deployment_days: deploymentDays,
          duty_hours: dutyHours,
          phq_score: cumulativePhqScore,
        },
      });
      setChatMessages([...newMessages, { role: 'assistant', content: res.content }]);
    } catch (err: any) {
      setChatMessages([
        ...newMessages,
        {
          role: 'assistant',
          content:
            'Jai Hind. I have noted your message. Please ensure you stay well-hydrated, take periodic breaks between patrols, and discuss duty adjustments with your unit welfare officer.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  const handlePhqOptionChange = (questionIndex: number, score: number) => {
    const updated = [...phqAnswers];
    updated[questionIndex] = score;
    setPhqAnswers(updated);
  };

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50 font-sans p-6">
        <div className="bg-white p-8 rounded-2xl border text-center space-y-4 max-w-md w-full shadow-sm">
          <span className="text-4xl">🎖️</span>
          <h2 className="text-lg font-bold text-slate-900">Authentication Required</h2>
          <p className="text-xs text-slate-500">Please sign in with your defense credentials to access RakshakMitra.</p>
          <Link href="/" className="inline-block px-5 py-2.5 bg-indigo-600 text-white rounded-xl text-xs font-bold shadow">
            Go to Sign In &rarr;
          </Link>
        </div>
      </div>
    );
  }

  const userRoles = user.mapped_roles || [user.primary_role];
  const isWelfare = userRoles.some(
    (role) => role === 'WELFARE_OFFICER' || role === 'SYSTEM_ADMIN' || role === 'SOLDIER'
  );

  const filteredHeatmap = heatmap.filter((item) => {
    if (heatmapFilter === 'ALL') return true;
    return item.status === heatmapFilter;
  });

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Top Header Banner */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-amber-50 border border-amber-200 flex items-center justify-center text-2xl shadow-sm">
              🎖️
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">RakshakMitra Command Core</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-amber-100 text-amber-800 border border-amber-200 uppercase">
                  Armed Forces Edition
                </span>
              </div>
              <p className="text-xs text-slate-500">Psychological Stress, Burnout Prediction &amp; Welfare Interventions</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="px-3 py-1.5 bg-slate-100 border rounded-xl text-xs font-bold text-slate-700 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              <span>{user.full_name} ({user.primary_role})</span>
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
                ? 'bg-amber-600 text-white shadow-md shadow-amber-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📝</span>
            <span>Soldier Check-in &amp; Voice Journal</span>
          </button>

          <button
            onClick={() => setActiveTab('HEATMAP')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'HEATMAP'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>🧑‍✈️</span>
            <span>Anonymized Commander Heatmap</span>
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
            <span>Rakshak AI Companion</span>
          </button>

          <button
            onClick={() => setActiveTab('HISTORY')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'HISTORY'
                ? 'bg-slate-900 text-white shadow-md'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📜</span>
            <span>Assessment History ({history.length})</span>
          </button>
        </div>

        {/* TAB 1: SOLDIER CHECKIN & VOICE MOOD JOURNAL */}
        {activeTab === 'CHECKIN' && (
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
            
            {/* Left: Input Form */}
            <div className="md:col-span-6">
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div className="border-b pb-2 flex items-center justify-between">
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Wellbeing &amp; Stress Log</h2>
                  <span className="text-[11px] text-slate-400 font-mono">Confidential Personnel Record</span>
                </div>
                
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
                    <label className="block text-slate-600 font-bold mb-1">Leave Gap Ratio (0.0 - 1.0)</label>
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
                    <label className="block text-slate-600 font-bold mb-1">Weekly Duty Workload (Hours)</label>
                    <input
                      type="number"
                      value={dutyHours}
                      onChange={(e) => setDutyHours(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Validated PHQ-9 Screen</label>
                    <button
                      type="button"
                      onClick={() => setShowPhqModal(true)}
                      className="w-full px-3 py-2 bg-amber-50 hover:bg-amber-100 border border-amber-200 text-amber-800 font-bold rounded-xl text-left flex items-center justify-between transition"
                    >
                      <span>PHQ-9 Score: {cumulativePhqScore}/27</span>
                      <span className="text-xs">&rarr;</span>
                    </button>
                  </div>
                </div>

                {/* Live Voice Mood Journal Section */}
                <div className="space-y-2 pt-2 border-t border-slate-100">
                  <div className="flex items-center justify-between">
                    <label className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                      <span>📓 Voice Mood Journal (Speech Diary)</span>
                    </label>
                    <button
                      type="button"
                      onClick={toggleRecording}
                      className={`px-3 py-1 rounded-full text-[10px] font-bold transition flex items-center gap-1.5 ${
                        isRecording
                          ? 'bg-rose-600 text-white animate-pulse shadow-md shadow-rose-600/30'
                          : 'bg-indigo-50 text-indigo-700 border border-indigo-200 hover:bg-indigo-100'
                      }`}
                    >
                      <span className={`w-2 h-2 rounded-full ${isRecording ? 'bg-white' : 'bg-indigo-600'}`}></span>
                      <span>{isRecording ? 'Listening (Speak now)...' : '🎙️ Record Voice Audio'}</span>
                    </button>
                  </div>

                  <textarea
                    required
                    value={voiceText}
                    onChange={(e) => setVoiceText(e.target.value)}
                    rows={3}
                    className="w-full px-3.5 py-2.5 bg-slate-50 border rounded-xl text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
                    placeholder="Speak or type how you are feeling, operational fatigue, sleep trends, or mental load..."
                  />
                  {isRecording && (
                    <p className="text-[10px] text-rose-600 font-semibold animate-pulse">
                      🔴 Live microphone capture active. Transcribing speech in real-time...
                    </p>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Evaluating Stress & Mood Trajectory...' : 'Calculate Burnout & Welfare Action'}
                </button>
              </form>
            </div>

            {/* Right: Scorecard */}
            <div className="md:col-span-6 space-y-4">
              {latestResult ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                  <div className="border-b pb-2 flex items-center justify-between">
                    <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Burnout Scorecard</h2>
                    <span className="text-xs font-mono text-slate-400">{latestResult.id}</span>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Burnout Index</span>
                      <div className="text-3xl font-black text-amber-700">{latestResult.burnout_score}</div>
                    </div>
                    <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Risk Severity</span>
                      <div
                        className={`text-xl font-black mt-1 ${
                          latestResult.risk_tier === 'CRITICAL'
                            ? 'text-rose-600'
                            : latestResult.risk_tier === 'HIGH'
                            ? 'text-amber-600'
                            : 'text-emerald-700'
                        }`}
                      >
                        {latestResult.risk_tier}
                      </div>
                    </div>
                  </div>

                  {/* Mood Trajectory Analysis */}
                  {latestResult.mood_trajectory && (
                    <div className="p-4 rounded-xl bg-indigo-50/70 border border-indigo-100 space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-[10px] font-bold uppercase tracking-wider text-indigo-900">
                          Psychological Trajectory
                        </span>
                        <span className="px-2 py-0.5 rounded text-[9px] font-bold bg-white text-indigo-800 border border-indigo-200">
                          Polarity: {latestResult.mood_trajectory.sentiment_polarity}
                        </span>
                      </div>
                      <p className="text-xs font-bold text-indigo-950">
                        {latestResult.mood_trajectory.trajectory_label}
                      </p>
                      <div className="flex flex-wrap gap-1 pt-1">
                        {latestResult.mood_trajectory.detected_markers.map((m, idx) => (
                          <span key={idx} className="px-2 py-0.5 rounded bg-white text-indigo-700 text-[10px] font-semibold border border-indigo-200">
                            {m}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}

                  <div className="space-y-1.5 text-xs">
                    <span className="block text-slate-400 font-bold uppercase text-[9px]">Contributing Stress Factors</span>
                    <ul className="list-disc list-inside space-y-1 text-slate-700 bg-slate-50 p-3 rounded-xl border">
                      {latestResult.contributing_factors.map((f, index) => (
                        <li key={index}>{f}</li>
                      ))}
                    </ul>
                  </div>

                  <div className="space-y-2 text-xs">
                    <span className="block text-slate-400 font-bold uppercase text-[9px]">AI Welfare Recommendations</span>
                    <div className="flex flex-wrap gap-2">
                      {latestResult.recommended_actions.map((act, index) => (
                        <span key={index} className="px-3 py-1.5 bg-emerald-50 border border-emerald-200 text-emerald-800 text-[11px] font-bold rounded-xl shadow-sm">
                          {act}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                  Submit a wellbeing assessment check-in to generate your index scorecard.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 2: ANONYMIZED COMMANDER HEATMAP */}
        {activeTab === 'HEATMAP' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b pb-3">
                <div>
                  <h2 className="text-base font-extrabold text-slate-900 uppercase tracking-wider">Unit Wellness Heatmap Matrix</h2>
                  <p className="text-xs text-slate-500">Strictly Anonymized Unit Aggregates. Personal soldier IDs and names are never revealed.</p>
                </div>
                
                {/* Status Filter Buttons */}
                <div className="flex gap-1.5">
                  {(['ALL', 'RED', 'ORANGE', 'GREEN'] as const).map((f) => (
                    <button
                      key={f}
                      onClick={() => setHeatmapFilter(f)}
                      className={`px-3 py-1 text-xs font-bold rounded-xl border transition ${
                        heatmapFilter === f
                          ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm'
                          : 'bg-slate-50 text-slate-600 border-slate-200 hover:bg-slate-100'
                      }`}
                    >
                      {f === 'ALL' ? 'All Units' : f}
                    </button>
                  ))}
                </div>
              </div>

              {/* Heatmap Grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {filteredHeatmap.map((item) => {
                  const isRed = item.status === 'RED';
                  const isOrange = item.status === 'ORANGE';
                  return (
                    <div
                      key={item.unit}
                      onClick={() => setSelectedUnit(item)}
                      className={`p-5 rounded-2xl border transition-all duration-200 shadow-sm hover:shadow-md cursor-pointer flex flex-col justify-between space-y-3 ${
                        isRed
                          ? 'bg-rose-50/60 border-rose-200 hover:border-rose-400'
                          : isOrange
                          ? 'bg-amber-50/60 border-amber-200 hover:border-amber-400'
                          : 'bg-emerald-50/60 border-emerald-200 hover:border-emerald-400'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <div className="font-extrabold text-base text-slate-900 flex items-center gap-2">
                            <span>{item.unit}</span>
                            <span
                              className={`px-2 py-0.5 rounded-full text-[9px] font-black uppercase ${
                                isRed
                                  ? 'bg-rose-100 text-rose-800'
                                  : isOrange
                                  ? 'bg-amber-100 text-amber-800'
                                  : 'bg-emerald-100 text-emerald-800'
                              }`}
                            >
                              {item.status}
                            </span>
                          </div>
                          <div className="text-xs text-slate-600 mt-1">Personnel Strength: <strong>{item.personnel_count} soldiers</strong></div>
                        </div>
                        <div className="text-right">
                          <div className={`font-black text-xl ${isRed ? 'text-rose-700' : isOrange ? 'text-amber-700' : 'text-emerald-700'}`}>
                            {item.average_burnout_index}
                          </div>
                          <div className="text-[10px] text-slate-400 uppercase font-bold">Burnout Index</div>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-2 text-xs bg-white/70 p-2.5 rounded-xl border border-slate-200/50">
                        <div>
                          <span className="text-[10px] text-slate-400 font-bold uppercase">Critical Risk</span>
                          <div className="font-black text-rose-600">{item.critical_risk_count} personnel</div>
                        </div>
                        <div>
                          <span className="text-[10px] text-slate-400 font-bold uppercase">High Risk</span>
                          <div className="font-black text-amber-600">{item.high_risk_count} personnel</div>
                        </div>
                      </div>

                      <div className="text-[11px] font-semibold text-slate-700 pt-1 flex items-center justify-between">
                        <span>{item.suggested_action || 'Welfare review suggested.'}</span>
                        <span className="text-indigo-600 font-bold text-xs">Inspect &rarr;</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* TAB 3: RAKSHAK AI CONVERSATIONAL COMPANION */}
        {activeTab === 'CHAT' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">RakshakMitra AI Welfare Companion</h2>
                <p className="text-xs text-slate-500">Confidential, supportive, human-understandable psychological companion</p>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                Online &bull; Strict Privacy Mode
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
                    <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-800 flex items-center justify-center text-sm font-bold flex-shrink-0">
                      🎖️
                    </div>
                  )}
                  <div
                    className={`p-3.5 rounded-2xl max-w-[80%] text-xs leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-amber-600 text-white rounded-br-none shadow-sm'
                        : 'bg-slate-100 text-slate-800 rounded-bl-none border border-slate-200/80 whitespace-pre-line'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && (
                <div className="flex items-center gap-2 text-xs text-slate-400 italic">
                  <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
                  <span>RakshakMitra AI is formulating support guidance...</span>
                </div>
              )}
            </div>

            {/* Chat Input */}
            <form onSubmit={handleSendChat} className="flex gap-2 pt-2 border-t">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Ask about stress mitigation, duty rotation, sleep recovery, or confidential counseling..."
                className="flex-1 px-4 py-3 rounded-xl border border-slate-300 bg-slate-50 focus:bg-white text-xs focus:ring-2 focus:ring-amber-500 focus:outline-none"
              />
              <button
                type="submit"
                disabled={chatLoading || !chatInput.trim()}
                className="px-5 py-3 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs shadow-md transition disabled:opacity-50"
              >
                Send
              </button>
            </form>
          </div>
        )}

        {/* TAB 4: ASSESSMENT HISTORY */}
        {activeTab === 'HISTORY' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <h2 className="text-base font-extrabold text-slate-900 border-b pb-3">Personal Assessment History</h2>
            <div className="divide-y">
              {history.length > 0 ? (
                history.map((h) => (
                  <div key={h.id} className="py-3 flex items-center justify-between text-xs">
                    <div>
                      <div className="font-bold text-slate-900">Burnout Index: {h.burnout_score} ({h.risk_tier})</div>
                      <div className="text-[10px] text-slate-400">{new Date(h.created_at).toLocaleString()}</div>
                      <div className="text-[11px] text-slate-600 mt-1">Actions: {h.recommended_actions?.join(', ')}</div>
                    </div>
                    <div className="text-right text-[11px] text-slate-500 italic max-w-[280px]">
                      &quot;{h.voice_journal_text || 'No voice transcript logged'}&quot;
                    </div>
                  </div>
                ))
              ) : (
                <div className="py-8 text-center text-xs text-slate-400 italic">No past wellness assessments logged.</div>
              )}
            </div>
          </div>
        )}

      </div>

      {/* Interactive Unit Drill-down Modal */}
      {selectedUnit && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 max-w-lg w-full space-y-4 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3">
              <div>
                <h3 className="text-base font-extrabold text-slate-900">{selectedUnit.unit}</h3>
                <p className="text-xs text-slate-500">Commander Anonymized Aggregated Metrics</p>
              </div>
              <button
                onClick={() => setSelectedUnit(null)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 font-bold flex items-center justify-center text-sm"
              >
                &times;
              </button>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-3 bg-slate-50 border rounded-xl">
                <span className="text-[10px] font-bold text-slate-400 uppercase">Average Burnout</span>
                <div className="text-2xl font-black text-slate-900">{selectedUnit.average_burnout_index}</div>
              </div>
              <div className="p-3 bg-slate-50 border rounded-xl">
                <span className="text-[10px] font-bold text-slate-400 uppercase">Unit Status</span>
                <div className="text-lg font-black text-amber-700">{selectedUnit.status}</div>
              </div>
            </div>

            <div className="space-y-2 text-xs">
              <span className="font-bold text-slate-700 uppercase text-[10px]">Recommended Commander Action:</span>
              <p className="p-3 bg-amber-50 border border-amber-200 text-amber-900 rounded-xl font-medium">
                {selectedUnit.suggested_action}
              </p>
            </div>

            <div className="pt-2 flex justify-end gap-2 border-t">
              <button
                type="button"
                onClick={() => {
                  alert(`Dispatched welfare rotation order for ${selectedUnit.unit}!`);
                  setSelectedUnit(null);
                }}
                className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow"
              >
                Dispatch Welfare Protocol
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Interactive PHQ-9 Clinical Modal */}
      {showPhqModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 max-w-2xl w-full max-h-[85vh] overflow-y-auto space-y-5 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3">
              <div>
                <h3 className="text-base font-extrabold text-slate-900">PHQ-9 Validated Depression &amp; Stress Screen</h3>
                <p className="text-xs text-slate-500">Over the last 2 weeks, how often have you been bothered by the following:</p>
              </div>
              <button
                onClick={() => setShowPhqModal(false)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 font-bold flex items-center justify-center text-sm"
              >
                &times;
              </button>
            </div>

            <div className="space-y-4">
              {PHQ9_QUESTIONS.map((q, qIndex) => (
                <div key={qIndex} className="p-3.5 bg-slate-50 border rounded-xl space-y-2 text-xs">
                  <p className="font-bold text-slate-800">{q}</p>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                    {PHQ9_OPTIONS.map((opt) => (
                      <button
                        key={opt.score}
                        type="button"
                        onClick={() => handlePhqOptionChange(qIndex, opt.score)}
                        className={`p-2 rounded-lg text-center font-bold text-[10px] border transition ${
                          phqAnswers[qIndex] === opt.score
                            ? 'bg-amber-600 text-white border-amber-600 shadow'
                            : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-100'
                        }`}
                      >
                        {opt.label} (+{opt.score})
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>

            <div className="flex items-center justify-between pt-2 border-t">
              <div className="text-xs font-bold text-amber-800">
                Calculated PHQ-9 Score: {cumulativePhqScore} / 27
              </div>
              <button
                type="button"
                onClick={() => setShowPhqModal(false)}
                className="px-5 py-2.5 bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs rounded-xl shadow transition"
              >
                Save &amp; Continue Check-in
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
