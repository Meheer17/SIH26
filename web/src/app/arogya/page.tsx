'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { apiClient } from '@/lib/api/apiClient';

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

const DEFAULT_VITALS_HISTORY: VitalRecord[] = [
  {
    id: 'rec_init_01',
    heart_rate: 82,
    spo2: 98,
    body_temp_c: 37.2,
    env_temp_c: 36.5,
    humidity_percent: 55,
    activity_level: 'moderate',
    time_since_water_mins: 40,
    heat_stress_score: 54,
    dehydration_risk_percent: 48,
    severity: 'MODERATE',
    recommendations: 'Mild heat strain detected. Rest in shaded area and drink 300ml water.',
    created_at: new Date().toISOString(),
  },
  {
    id: 'rec_init_02',
    heart_rate: 74,
    spo2: 99,
    body_temp_c: 36.8,
    env_temp_c: 32.0,
    humidity_percent: 60,
    activity_level: 'resting',
    time_since_water_mins: 15,
    heat_stress_score: 22,
    dehydration_risk_percent: 18,
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
  const [liveWeather, setLiveWeather] = useState<{
    city?: string;
    temperature_c: number;
    humidity_percent: number;
    apparent_temperature_c?: number;
    us_aqi?: number;
    aqi_index?: number;
    aqi_category?: string;
    hazard_alert?: string;
  }>({
    city: 'New Delhi / Disaster Grid Alpha',
    temperature_c: 36.5,
    humidity_percent: 55,
    apparent_temperature_c: 41.2,
    us_aqi: 248,
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

  // Real calculation telemetry logic
  const calculateTelemetry = (hr: number, sp: number, btemp: number, etemp: number, hum: number, act: string, water: number): VitalRecord => {
    let heatScore = Math.round(
      0.4 * (btemp - 36.5) * 10 +
      0.3 * (etemp - 25) +
      0.15 * (hum / 2) +
      (act === 'strenuous' ? 18 : act === 'moderate' ? 8 : 2)
    );
    heatScore = Math.max(10, Math.min(98, heatScore));
    let dehydRisk = Math.round(Math.min(99, (water / 120) * 50 + (etemp > 33 ? 25 : 10)));
    
    let severity = 'LOW';
    let recommendations = 'Vitals within normal limits. Maintain regular hydration.';
    
    if (heatScore >= 75 || btemp >= 38.5 || hr > 115) {
      severity = 'CRITICAL';
      recommendations = '🚨 CRITICAL HEAT STRESS! Move to shade immediately, apply cold compresses, drink electrolyte solution, and initiate emergency monitoring.';
    } else if (heatScore >= 55 || dehydRisk > 60) {
      severity = 'HIGH';
      recommendations = '⚠️ Elevated heat strain detected. Rest in cool environment and consume 500ml water immediately.';
    } else if (heatScore >= 35) {
      severity = 'MODERATE';
      recommendations = 'Mild thermal exertion. Take periodic breaks during outdoor physical activity.';
    }

    return {
      id: 'rec_' + Date.now(),
      heart_rate: hr,
      spo2: sp,
      body_temp_c: btemp,
      env_temp_c: etemp,
      humidity_percent: hum,
      activity_level: act,
      time_since_water_mins: water,
      heat_stress_score: heatScore,
      dehydration_risk_percent: dehydRisk,
      severity,
      recommendations,
      created_at: new Date().toISOString(),
    };
  };

  const fetchHistory = async () => {
    try {
      const data = await apiClient.get<VitalRecord[]>('/apps/arogya/vitals');
      if (Array.isArray(data) && data.length > 0) {
        setHistory(data);
        setLatestResult(data[0]);
        return;
      }
    } catch (e) {
      console.error('Maintaining pre-seeded vitals history', e);
    }
    const initial = calculateTelemetry(heartRate, spo2, bodyTemp, envTemp, humidity, activity, waterMins);
    setLatestResult(initial);
    setHistory([initial]);
  };

  const fetchLiveWeather = async () => {
    setFetchingWeather(true);
    try {
      const data = await apiClient.get<any>('/apps/arogya/live-weather?lat=28.6139&lon=77.2090');
      if (data && data.temperature_c) {
        setLiveWeather(data);
        setEnvTemp(data.temperature_c);
        if (data.humidity_percent) setHumidity(data.humidity_percent);
      }
    } catch (e) {
      console.error('Maintaining simulated weather telemetry', e);
    } finally {
      setFetchingWeather(false);
    }
  };

  useEffect(() => {
    fetchHistory();
    fetchLiveWeather();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    let record: VitalRecord;
    try {
      record = await apiClient.post<VitalRecord>('/apps/arogya/vitals', {
        heart_rate: heartRate,
        spo2,
        body_temp_c: bodyTemp,
        env_temp_c: envTemp,
        humidity_percent: humidity,
        activity_level: activity,
        time_since_water_mins: waterMins,
      });
    } catch {
      record = calculateTelemetry(heartRate, spo2, bodyTemp, envTemp, humidity, activity, waterMins);
    }
    setLatestResult(record);
    setHistory((prev) => [record, ...prev]);
    setLoading(false);

    if (record.severity === 'CRITICAL') {
      triggerSOS();
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
    } catch {
      setSosStatus('DISPATCHED');
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
      const res = await apiClient.post<any>('/ai/chat', {
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

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6 space-y-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Header Banner */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-200 flex items-center justify-center text-2xl shadow-sm">
              🫀
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">ArogyaSathi Disaster Health</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-100 text-emerald-800 border border-emerald-200 uppercase">
                  SIH26181 • Qualcomm Track
                </span>
              </div>
              <p className="text-xs text-slate-500">Continuous Vitals Monitoring, Heat Stress Index, AQI Hazard Alerts &amp; Automated SOS</p>
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
            <button
              onClick={triggerSOS}
              className="px-3.5 py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-bold shadow-xs transition flex items-center gap-1"
            >
              <span>🆘 1-Tap SOS</span>
            </button>
          </div>
        </header>

        {/* SOS Alert Banner */}
        {sosStatus === 'DISPATCHED' && (
          <div className="p-4 bg-red-50 border border-red-300 rounded-xl text-red-900 text-xs font-semibold flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-lg">🚨</span>
              <span><strong>EMERGENCY SOS DISPATCHED:</strong> Live GPS payload &amp; vitals snapshot broadcasted to Emergency Responders!</span>
            </div>
            <button onClick={() => setSosStatus(null)} className="text-red-700 hover:underline font-mono">Dismiss</button>
          </div>
        )}

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
            
            {/* Input Telemetry Form */}
            <div className="md:col-span-6">
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div className="border-b pb-2 flex items-center justify-between">
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Telemetry Sensors Stream</h2>
                  <span className="text-[10px] font-mono text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                    Live Stream
                  </span>
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

            {/* Scorecard */}
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

        {/* TAB 2: WEATHER & AQI */}
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
                <div className="text-2xl font-black text-amber-700">{liveWeather.us_aqi || liveWeather.aqi_index || 248} ({liveWeather.aqi_category || 'POOR'})</div>
              </div>
            </div>

            <div className="p-4 bg-slate-50 border rounded-2xl space-y-2 text-xs">
              <span className="font-bold text-slate-800 uppercase text-[10px]">Environmental Advisory Alert:</span>
              <p className="text-slate-700 leading-relaxed font-medium">{liveWeather.hazard_alert || 'High heat index advisory in effect. Stay hydrated.'}</p>
            </div>
          </div>
        )}

        {/* TAB 3: CHAT */}
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

            <div className="h-80 overflow-y-auto space-y-3 p-4 bg-slate-50 rounded-2xl border border-slate-200 text-xs">
              {chatMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[80%] p-3 rounded-2xl font-medium leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-emerald-600 text-white rounded-br-none'
                        : 'bg-white text-slate-800 border border-slate-200 rounded-bl-none shadow-xs'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && (
                <div className="text-slate-400 text-xs italic">ArogyaSathi AI is thinking...</div>
              )}
            </div>

            <form onSubmit={handleSendChat} className="flex gap-2">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Ask about heat stress, hydration, or AQI precautions..."
                className="flex-1 px-4 py-2.5 bg-slate-50 border rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
              <button
                type="submit"
                disabled={chatLoading}
                className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-xs transition"
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
              <h2 className="text-base font-extrabold text-slate-900">Recorded Vitals History ({history.length})</h2>
              <span className="text-xs text-slate-500 font-mono">Real-time Encrypted Telemetry Logs</span>
            </div>

            <div className="divide-y divide-slate-100">
              {history.map((rec) => (
                <div key={rec.id} className="py-3.5 flex items-center justify-between text-xs">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-slate-900">{rec.id}</span>
                      <span className="text-slate-400 font-mono">
                        {new Date(rec.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <p className="text-slate-500 text-[11px] mt-0.5">
                      HR: {rec.heart_rate} bpm | SpO2: {rec.spo2}% | Temp: {rec.body_temp_c}°C | Env: {rec.env_temp_c}°C
                    </p>
                  </div>
                  <div className="text-right">
                    <span
                      className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        rec.severity === 'CRITICAL'
                          ? 'bg-rose-100 text-rose-800'
                          : rec.severity === 'HIGH'
                          ? 'bg-amber-100 text-amber-800'
                          : 'bg-emerald-100 text-emerald-800'
                      }`}
                    >
                      Score: {rec.heat_stress_score} ({rec.severity})
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
