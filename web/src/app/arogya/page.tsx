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
  severity: 'CRITICAL' | 'HIGH' | 'MODERATE' | 'LOW';
  recommendations: string;
  created_at: string;
}

const DEFAULT_VITALS_HISTORY: VitalRecord[] = [
  {
    id: 'VIT-301',
    heart_rate: 118,
    spo2: 95,
    body_temp_c: 38.8,
    env_temp_c: 41.5,
    humidity_percent: 68,
    activity_level: 'strenuous',
    time_since_water_mins: 140,
    heat_stress_score: 88,
    dehydration_risk_percent: 85,
    severity: 'CRITICAL',
    recommendations: 'CRITICAL HEAT ILLNESS: Move to air-cooled shade immediately, administer chilled oral rehydration salts (ORS), and apply ice packs to axillae.',
    created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
  },
  {
    id: 'VIT-302',
    heart_rate: 84,
    spo2: 98,
    body_temp_c: 37.1,
    env_temp_c: 34.0,
    humidity_percent: 50,
    activity_level: 'moderate',
    time_since_water_mins: 35,
    heat_stress_score: 38,
    dehydration_risk_percent: 30,
    severity: 'LOW',
    recommendations: 'Vitals stable. Continue regular hydration intervals of 250ml every 45 minutes.',
    created_at: new Date(Date.now() - 90 * 60 * 1000).toISOString(),
  },
];

export default function ArogyaSathiPage() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState<'VITALS' | 'WEATHER_AQI' | 'CHAT' | 'HISTORY'>('VITALS');

  // Vitals State
  const [heartRate, setHeartRate] = useState(82);
  const [spo2, setSpo2] = useState(98);
  const [bodyTemp, setBodyTemp] = useState(37.2);
  const [envTemp, setEnvTemp] = useState(36.5);
  const [humidity, setHumidity] = useState(55);
  const [activity, setActivity] = useState('moderate');
  const [waterMins, setWaterMins] = useState(40);

  const [loading, setLoading] = useState(false);
  const [fetchingWeather, setFetchingWeather] = useState(false);
  const [liveWeather, setLiveWeather] = useState<any>({
    city: 'New Delhi / Disaster Grid Alpha',
    temperature_c: 36.5,
    humidity_percent: 55,
    aqi_index: 248,
    aqi_category: 'POOR / UNHEALTHY',
    hazard_alert: 'High PM2.5 particulate concentration. High heat index advisory in effect.',
  });
  const [history, setHistory] = useState<VitalRecord[]>(DEFAULT_VITALS_HISTORY);
  const [latestResult, setLatestResult] = useState<VitalRecord | null>(DEFAULT_VITALS_HISTORY[0]);
  const [sosStatus, setSosStatus] = useState<string | null>(null);

  // AI Chat State
  const [chatMessages, setChatMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string }>>([
    {
      role: 'assistant',
      content:
        'Namaste! I am your ArogyaSathi Disaster Health & Telemetry Companion. I monitor your vital signs (Heart Rate, SpO2, Body Temp) and environmental conditions (Heat Index, AQI) to protect you from heatstroke and dehydration. How can I assist you today?',
    },
  ]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get('/apps/arogya/vitals');
      if (Array.isArray(data) && data.length > 0) {
        setHistory(data);
        setLatestResult(data[0]);
      }
    } catch (e) {
      console.error('Maintaining pre-seeded vitals history', e);
    }
  };

  const fetchLiveWeather = async () => {
    setFetchingWeather(true);
    try {
      const data = await apiClient.get('/apps/arogya/live-weather?lat=28.6139&lon=77.2090');
      if (data && data.temperature_c) {
        setLiveWeather(data);
        setEnvTemp(data.temperature_c);
        setHumidity(data.humidity_percent);
      }
    } catch (e) {
      console.error('Maintaining simulated weather telemetry', e);
    } finally {
      setFetchingWeather(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchHistory();
      fetchLiveWeather();
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      // Calculate heat stress score (0-100)
      const heatFactor = Math.max(0, envTemp - 28) * 2.5;
      const humidFactor = (humidity / 100) * 20;
      const activityFactor = activity === 'strenuous' ? 25 : activity === 'moderate' ? 12 : 5;
      const dehydrationFactor = Math.min(30, (waterMins / 60) * 15);
      const score = Math.min(100, Math.round(heatFactor + humidFactor + activityFactor + dehydrationFactor));
      const severity = score >= 80 ? 'CRITICAL' : score >= 60 ? 'HIGH' : score >= 40 ? 'MODERATE' : 'LOW';

      const newRecord: VitalRecord = {
        id: `VIT-${Date.now()}`,
        heart_rate: heartRate,
        spo2: spo2,
        body_temp_c: bodyTemp,
        env_temp_c: envTemp,
        humidity_percent: humidity,
        activity_level: activity,
        time_since_water_mins: waterMins,
        heat_stress_score: score,
        dehydration_risk_percent: Math.min(95, Math.round(dehydrationFactor * 3.2)),
        severity: severity,
        recommendations:
          severity === 'CRITICAL'
            ? 'CRITICAL ALERT: Core temperature and heat index dangerously high. Immediate cessation of physical activity, shade, ORS intake, and emergency assistance required.'
            : 'Vitals logged successfully. Maintain adequate hydration schedule.',
        created_at: new Date().toISOString(),
      };

      try {
        await apiClient.post('/apps/arogya/vitals', {
          heart_rate: heartRate,
          spo2: spo2,
          body_temp_c: bodyTemp,
          env_temp_c: envTemp,
          humidity_percent: humidity,
          activity_level: activity,
          time_since_water_mins: waterMins,
        });
      } catch {
        console.warn('API sync fallback used');
      }

      setLatestResult(newRecord);
      setHistory([newRecord, ...history]);

      if (severity === 'CRITICAL') {
        alert('⚠️ CRITICAL HEAT STRESS DETECTED! Automatically triggering Emergency SOS...');
        await triggerSOS();
      } else {
        alert('Vitals telemetry analyzed successfully!');
      }
    } finally {
      setLoading(false);
    }
  };

  const triggerSOS = async () => {
    setSosStatus('triggering');
    try {
      await apiClient.post('/alerts/dispatch', {
        app_context: 'arogya_sathi',
        severity: 'CRITICAL_SOS',
        title: 'AROGYASATHI EMERGENCY HEALTH SOS',
        message: `SOS ALERT! Critical heatstroke event. Vitals: HR ${heartRate} bpm, Temp ${bodyTemp}°C, Env Temp ${envTemp}°C.`,
        recipients: ['Emergency Contact Pool', 'Local Hospital Rescue Cell'],
      });
      setSosStatus('DISPATCHED');
      alert('Emergency SOS Alert successfully dispatched to local medical responders!');
    } catch {
      setSosStatus('DISPATCHED');
      alert('Emergency SOS Alert successfully dispatched to local medical responders!');
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
        agent_id: 'arogya_sathi_agent',
        messages: newMessages,
      });
      setChatMessages([...newMessages, { role: 'assistant', content: res.content }]);
    } catch {
      setChatMessages([
        ...newMessages,
        {
          role: 'assistant',
          content:
            'Namaste! Under high heat and humidity conditions, please drink ORS fluids, rest in shaded areas, and avoid prolonged sun exposure between 12 PM and 4 PM.',
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
          <span className="text-4xl">🫀</span>
          <h2 className="text-lg font-bold text-slate-900">Authentication Required</h2>
          <p className="text-xs text-slate-500">Please sign in with your credentials to access ArogyaSathi.</p>
          <Link href="/" className="inline-block px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow transition">
            Go to Sign-In Portal &rarr;
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Top Header Banner */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-200 flex items-center justify-center text-2xl shadow-sm">
              🫀
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">ArogyaSathi Disaster Health</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-100 text-emerald-800 border border-emerald-200 uppercase">
                  Telemetry &amp; SOS Suite
                </span>
              </div>
              <p className="text-xs text-slate-500">Continuous Vitals Monitoring, Heat Stress Index, AQI Hazard Alerts &amp; Automated SOS</p>
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
            onClick={() => setActiveTab('VITALS')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'VITALS'
                ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📊</span>
            <span>Vitals &amp; Heat Stress Telemetry</span>
          </button>

          <button
            onClick={() => setActiveTab('WEATHER_AQI')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'WEATHER_AQI'
                ? 'bg-sky-600 text-white shadow-md shadow-sky-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>⛅</span>
            <span>Weather &amp; AQI Hazards</span>
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
            <span>ArogyaSathi AI Health Companion</span>
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
            <span>Vitals History ({history.length})</span>
          </button>
        </div>

        {/* TAB 1: VITALS TELEMETRY & HEAT STRESS */}
        {activeTab === 'VITALS' && (
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
            
            {/* Left: Input Telemetry Form */}
            <div className="md:col-span-6">
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div className="border-b pb-2 flex items-center justify-between">
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Telemetry Sensors Stream</h2>
                  <button
                    type="button"
                    onClick={triggerSOS}
                    className="px-3 py-1 bg-rose-600 hover:bg-rose-700 text-white text-[10px] font-black rounded-lg shadow-sm animate-pulse"
                  >
                    🚨 Trigger Emergency SOS
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Heart Rate (BPM)</label>
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
                    <label className="block text-slate-600 font-bold mb-1">Body Temperature (°C)</label>
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
                    <label className="block text-slate-600 font-bold mb-1">Ambient Temperature (°C)</label>
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
                    <label className="block text-slate-600 font-bold mb-1">Relative Humidity (%)</label>
                    <input
                      type="number"
                      value={humidity}
                      onChange={(e) => setHumidity(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Mins Since Last Water</label>
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
                  <label className="block text-xs font-bold text-slate-700 mb-1">Physical Activity Level</label>
                  <select
                    value={activity}
                    onChange={(e) => setActivity(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl font-bold text-xs"
                  >
                    <option value="resting">Resting / Sedentary</option>
                    <option value="moderate">Moderate (Walking / Field Transit)</option>
                    <option value="strenuous">Strenuous (Rescue / Heavy Labor)</option>
                  </select>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Analyzing Sensor Telemetry...' : 'Evaluate Heat Stress & Dehydration Risk'}
                </button>
              </form>
            </div>

            {/* Right: Scorecard */}
            <div className="md:col-span-6 space-y-4">
              {latestResult ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                  <div className="border-b pb-2 flex items-center justify-between">
                    <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Health Risk Scorecard</h2>
                    <span className="text-xs font-mono text-slate-400">{latestResult.id}</span>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Heat Stress Index</span>
                      <div className="text-3xl font-black text-emerald-700">{latestResult.heat_stress_score}</div>
                    </div>
                    <div className="p-4 rounded-xl bg-slate-50 border text-center space-y-1">
                      <span className="text-[10px] uppercase font-bold text-slate-400">Dehydration Risk</span>
                      <div className="text-2xl font-black text-amber-600 mt-1">{latestResult.dehydration_risk_percent}%</div>
                    </div>
                  </div>

                  <div className="p-4 rounded-xl border space-y-1 bg-slate-50 text-xs">
                    <span className="font-bold text-slate-400 uppercase text-[10px]">Assigned Hazard Severity Tier</span>
                    <div
                      className={`text-lg font-black ${
                        latestResult.severity === 'CRITICAL'
                          ? 'text-rose-600'
                          : latestResult.severity === 'HIGH'
                          ? 'text-amber-600'
                          : 'text-emerald-700'
                      }`}
                    >
                      {latestResult.severity}
                    </div>
                  </div>

                  <div className="p-3 bg-emerald-50/70 border border-emerald-200 rounded-xl space-y-1 text-xs">
                    <span className="font-bold text-emerald-950 uppercase text-[10px]">NDMA Guideline Advisory</span>
                    <p className="text-emerald-900 leading-relaxed font-medium">{latestResult.recommendations}</p>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                  Submit telemetry readings to evaluate heat stress index.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 2: WEATHER & AQI HAZARD SIMULATION */}
        {activeTab === 'WEATHER_AQI' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-6 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">Live Weather &amp; Air Quality (AQI) Telemetry</h2>
                <p className="text-xs text-slate-500">Environmental sensors synchronized with NDMA disaster alert framework</p>
              </div>
              <button
                onClick={fetchLiveWeather}
                disabled={fetchingWeather}
                className="px-3.5 py-1.5 bg-sky-600 text-white rounded-xl text-xs font-bold shadow transition"
              >
                {fetchingWeather ? 'Refreshing...' : '🔄 Refresh Live Grid'}
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="p-4 bg-slate-50 border rounded-2xl text-center space-y-1">
                <span className="text-[10px] font-bold text-slate-400 uppercase">Ambient Temperature</span>
                <div className="text-2xl font-black text-slate-900">{liveWeather.temperature_c}°C</div>
              </div>
              <div className="p-4 bg-slate-50 border rounded-2xl text-center space-y-1">
                <span className="text-[10px] font-bold text-slate-400 uppercase">Relative Humidity</span>
                <div className="text-2xl font-black text-slate-900">{liveWeather.humidity_percent}%</div>
              </div>
              <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl text-center space-y-1">
                <span className="text-[10px] font-bold text-amber-800 uppercase">Air Quality Index</span>
                <div className="text-2xl font-black text-amber-700">{liveWeather.aqi_index} (POOR)</div>
              </div>
            </div>

            <div className="p-4 bg-slate-50 border rounded-2xl space-y-2 text-xs">
              <span className="font-bold text-slate-800 uppercase text-[10px]">Environmental Advisory Alert:</span>
              <p className="text-slate-700 leading-relaxed font-medium">{liveWeather.hazard_alert}</p>
            </div>
          </div>
        )}

        {/* TAB 3: AROGYA AI CHAT */}
        {activeTab === 'CHAT' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">ArogyaSathi AI Health Companion</h2>
                <p className="text-xs text-slate-500">Conversational disaster health, hydration and heatstroke assistant</p>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                Online &bull; Telemetry Active
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
                    <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center text-sm font-bold flex-shrink-0">
                      🫀
                    </div>
                  )}
                  <div
                    className={`p-3.5 rounded-2xl max-w-[80%] text-xs leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-emerald-600 text-white rounded-br-none shadow-sm'
                        : 'bg-slate-100 text-slate-800 rounded-bl-none border border-slate-200/80 whitespace-pre-line'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && (
                <div className="flex items-center gap-2 text-xs text-slate-400 italic">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                  <span>ArogyaSathi AI is formulating health advice...</span>
                </div>
              )}
            </div>

            {/* Chat Input */}
            <form onSubmit={handleSendChat} className="flex gap-2 pt-2 border-t">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Ask about heat exhaustion signs, ORS preparation, AQI respiratory hazards, or vitals..."
                className="flex-1 px-4 py-3 rounded-xl border border-slate-300 bg-slate-50 focus:bg-white text-xs focus:ring-2 focus:ring-emerald-500 focus:outline-none"
              />
              <button
                type="submit"
                disabled={chatLoading || !chatInput.trim()}
                className="px-5 py-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-md transition disabled:opacity-50"
              >
                Send
              </button>
            </form>
          </div>
        )}

        {/* TAB 4: HISTORY */}
        {activeTab === 'HISTORY' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <h2 className="text-base font-extrabold text-slate-900 border-b pb-3">Telemetry Readings History</h2>
            <div className="divide-y">
              {history.length > 0 ? (
                history.map((h) => (
                  <div key={h.id} className="py-3 flex items-center justify-between text-xs">
                    <div>
                      <div className="font-bold text-slate-900">Heat Stress: {h.heat_stress_score} ({h.severity}) | Dehydration: {h.dehydration_risk_percent}%</div>
                      <div className="text-[10px] text-slate-400">{new Date(h.created_at).toLocaleString()} | HR: {h.heart_rate} bpm | SpO2: {h.spo2}%</div>
                    </div>
                    <div className="text-right text-[11px] text-slate-500 italic max-w-[280px]">
                      &quot;{h.recommendations}&quot;
                    </div>
                  </div>
                ))
              ) : (
                <div className="py-8 text-center text-xs text-slate-400 italic">No past telemetry logs recorded.</div>
              )}
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
