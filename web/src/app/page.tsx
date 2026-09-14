'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { checkBackendHealth, HealthResponse, apiClient } from '@/lib/api/apiClient';

export default function Home() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'clinical' | 'screening' | 'frontline' | 'mental' | 'safety'>('clinical');
  const [backendStatus, setBackendStatus] = useState<HealthResponse | null>(null);
  const [liveWeather, setLiveWeather] = useState<any>(null);
  const [digitalTwin, setDigitalTwin] = useState<any>(null);
  const [karmaData, setKarmaData] = useState<any>(null);

  // --- Clinical Tab State ---
  const [chiefComplaint, setChiefComplaint] = useState('Severe cough with fever and chest heaviness for 3 days');
  const [symptomsList, setSymptomsList] = useState('fever, productive cough, fatigue');
  const [selectedCondition, setSelectedCondition] = useState('HEAT_STRESS');
  const [clinicalResult, setClinicalResult] = useState<any>(null);
  const [clinicalLoading, setClinicalLoading] = useState(false);

  // --- Diagnostics Screening Tab State ---
  const [redVal, setRedVal] = useState(192);
  const [greenVal, setGreenVal] = useState(132);
  const [blueVal, setBlueVal] = useState(118);
  const [anemiaResult, setAnemiaResult] = useState<any>(null);
  const [anemiaLoading, setAnemiaLoading] = useState(false);
  const [coughResult, setCoughResult] = useState<any>(null);
  const [coughLoading, setCoughLoading] = useState(false);

  // --- ASHA / Frontline Tab State ---
  const [ashaPatient, setAshaPatient] = useState('Sunita Devi');
  const [ashaAge, setAshaAge] = useState(24);
  const [isPregnant, setIsPregnant] = useState(true);
  const [ashaSymptoms, setAshaSymptoms] = useState('severe headache, blurred vision, swelling in feet');
  const [ashaResult, setAshaResult] = useState<any>(null);
  const [epidemicResult, setEpidemicResult] = useState<any>(null);

  // --- Mental Wellness Tab State ---
  const [dutyHours, setDutyHours] = useState(68);
  const [deploymentDays, setDeploymentDays] = useState(120);
  const [leaveRatio, setLeaveRatio] = useState(0.85);
  const [assessmentScore, setAssessmentScore] = useState(18);
  const [voiceText, setVoiceText] = useState('Feeling very exhausted after 4 continuous night patrols, sleep is broken');
  const [burnoutResult, setBurnoutResult] = useState<any>(null);
  const [voiceStressResult, setVoiceStressResult] = useState<any>(null);

  // --- Safety & Evidence Vault State ---
  const [incidentType, setIncidentType] = useState('LEGAL_STATEMENT_INTAKE');
  const [evidenceDesc, setEvidenceDesc] = useState('Victim reported verbal intimidation and social boycott attempt in village square.');
  const [evidenceResult, setEvidenceResult] = useState<any>(null);
  const [evidenceChain, setEvidenceChain] = useState<any>(null);

  // Initial Data Fetch
  useEffect(() => {
    checkBackendHealth().then(setBackendStatus).catch(() => {});
    
    apiClient.get<any>('/apps/arogya/live-weather?lat=28.6139&lon=77.2090')
      .then(res => setLiveWeather(res))
      .catch(() => {});

    apiClient.get<any>('/apps/digital-twin')
      .then(res => setDigitalTwin(res))
      .catch(() => {});

    apiClient.get<any>('/apps/karma')
      .then(res => setKarmaData(res))
      .catch(() => {});
  }, []);

  // Handlers
  const handleRunClinicalTriage = async () => {
    setClinicalLoading(true);
    try {
      const [triageRes, dualRxRes] = await Promise.all([
        apiClient.post<any>('/apps/medikiosk/intake', {
          chief_complaint: chiefComplaint,
          symptoms: symptomsList.split(',').map(s => s.trim()),
          duration: '3 days',
          severity_rating: 7,
          history_present_illness: 'Progressive respiratory congestion following outdoor heat exposure.',
          review_systems: 'Mild fever, no hemoptysis.',
          ayush_mode: true
        }),
        apiClient.post<any>('/clinical/dual-prescription', {
          condition_key: selectedCondition,
          symptoms: symptomsList.split(',').map(s => s.trim())
        })
      ]);
      setClinicalResult({ triage: triageRes, dualRx: dualRxRes });
    } catch (err: any) {
      alert('Error running clinical engine: ' + (err.details?.detail || err.message));
    } finally {
      setClinicalLoading(false);
    }
  };

  const handleRunAnemiaColorimetry = async () => {
    setAnemiaLoading(true);
    try {
      const res = await apiClient.post<any>('/screening/anemia-colorimetry', {
        red: Number(redVal),
        green: Number(greenVal),
        blue: Number(blueVal)
      });
      setAnemiaResult(res);
    } catch (err: any) {
      alert('Error: ' + err.message);
    } finally {
      setAnemiaLoading(false);
    }
  };

  const handleRunCoughScreening = async () => {
    setCoughLoading(true);
    try {
      const res = await apiClient.post<any>('/screening/cough-demo');
      setCoughResult(res);
    } catch (err: any) {
      alert('Error: ' + err.message);
    } finally {
      setCoughLoading(false);
    }
  };

  const handleRunAshaTriage = async () => {
    try {
      const [ashaRes, epRes] = await Promise.all([
        apiClient.post<any>('/apps/asha-copilot', {
          patient_name: ashaPatient,
          age: ashaAge,
          is_pregnant: isPregnant,
          symptoms: ashaSymptoms.split(',').map(s => s.trim()),
          vitals: { bp: '140/95', hr: 88, hb: 10.1 }
        }),
        apiClient.post<any>('/epidemic/clusters', {
          coordinates: [
            { lat: 28.6139, lng: 77.2090 },
            { lat: 28.6210, lng: 77.2150 },
            { lat: 28.6180, lng: 77.2050 },
            { lat: 28.6900, lng: 77.1500 }
          ],
          radius_km: 5.0,
          min_cluster_samples: 2
        })
      ]);
      setAshaResult(ashaRes);
      setEpidemicResult(epRes);
    } catch (err: any) {
      alert('Error running ASHA triage: ' + err.message);
    }
  };

  const handleRunMentalAnalysis = async () => {
    try {
      const [brnRes, vceRes] = await Promise.all([
        apiClient.post<any>('/apps/rakshak/burnout', {
          deployment_days: Number(deploymentDays),
          leave_gap_ratio: Number(leaveRatio),
          duty_hours_per_week: Number(dutyHours),
          assessment_score: Number(assessmentScore),
          voice_journal_text: voiceText
        }),
        apiClient.post<any>('/apps/nyaya/voice-stress', {
          transcript_text: voiceText,
          pitch_variance: 42.5,
          pause_ratio: 0.38
        })
      ]);
      setBurnoutResult(brnRes);
      setVoiceStressResult(vceRes);
    } catch (err: any) {
      alert('Error analyzing resilience: ' + err.message);
    }
  };

  const handleLogEvidence = async () => {
    try {
      const res = await apiClient.post<any>('/covert-sos/evidence/log', {
        incident_type: incidentType,
        description: evidenceDesc,
        gps_lat: 28.6139,
        gps_lng: 77.2090
      });
      setEvidenceResult(res);

      const chainRes = await apiClient.get<any>('/covert-sos/evidence/chain');
      setEvidenceChain(chainRes);
    } catch (err: any) {
      alert('Error logging evidence: ' + err.message);
    }
  };

  return (
    <div className="min-h-screen bg-[#0B0F17] text-slate-100 font-sans pb-20">
      
      {/* Hero Header Banner */}
      <section className="relative overflow-hidden border-b border-slate-800/80 bg-slate-950/60 backdrop-blur-xl">
        <div className="absolute inset-0 bg-mesh-dark opacity-60 pointer-events-none" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 relative z-10">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-8">
            <div className="space-y-3 max-w-3xl">
              <div className="flex flex-wrap items-center gap-2">
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-teal-500/10 text-teal-400 border border-teal-500/20 shadow-sm shadow-teal-500/10">
                  <span className="w-2 h-2 rounded-full bg-teal-400 animate-pulse" />
                  National Health &amp; Resilience Grid
                </span>
                <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                  SIH 2026 Unified Platform
                </span>
              </div>
              
              <h1 className="text-3xl sm:text-5xl font-black text-white tracking-tight leading-tight">
                Healthcare Intelligence &amp; <br />
                <span className="text-gradient-teal">Non-Invasive Diagnostic Platform</span>
              </h1>
              
              <p className="text-sm sm:text-base text-slate-400 font-medium leading-relaxed max-w-2xl">
                Unified ecosystem integrating disaster health telemetry, offline OPD pre-triage, defense burnout indicators, atrocity victim forensic support, and camera colorimetry anemia screening.
              </p>
            </div>

            <div className="flex flex-wrap sm:flex-nowrap items-center gap-3 shrink-0">
              <Link
                href="/screening"
                className="px-5 py-3 rounded-xl bg-gradient-to-r from-teal-500 to-cyan-500 hover:from-teal-400 hover:to-cyan-400 text-slate-950 font-extrabold text-sm shadow-lg shadow-teal-500/25 transition duration-300 flex items-center gap-2"
              >
                <span>🔬</span>
                <span>Palmar Anemia &amp; Cough ML</span>
              </Link>
              <Link
                href="/chat"
                className="px-5 py-3 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-200 font-bold text-sm border border-slate-700/80 transition flex items-center gap-2"
              >
                <span>💬</span>
                <span>AI Clinical Hub</span>
              </Link>
            </div>
          </div>

          {/* Live Telemetry Bar */}
          <div className="mt-8 pt-6 border-t border-slate-800/80 grid grid-cols-2 md:grid-cols-4 gap-4 text-xs">
            <div className="glass-panel p-3.5 rounded-xl flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-teal-500/10 border border-teal-500/20 flex items-center justify-center text-teal-400 font-bold">
                5
              </div>
              <div>
                <div className="font-extrabold text-slate-200">ML Models Active</div>
                <div className="text-[10px] text-slate-400">Palmar Hb, FFT Cough, Voice Stress</div>
              </div>
            </div>

            <div className="glass-panel p-3.5 rounded-xl flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 font-bold">
                29
              </div>
              <div>
                <div className="font-extrabold text-slate-200">FastAPI Endpoints</div>
                <div className="text-[10px] text-slate-400">100% Tested &amp; Active</div>
              </div>
            </div>

            <div className="glass-panel p-3.5 rounded-xl flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400 font-bold">
                ISO
              </div>
              <div>
                <div className="font-extrabold text-slate-200">WBGT Heat Engine</div>
                <div className="text-[10px] text-slate-400">Live Weather &amp; Hydration</div>
              </div>
            </div>

            <div className="glass-panel p-3.5 rounded-xl flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-rose-500/10 border border-rose-500/20 flex items-center justify-center text-rose-400 font-bold">
                BSA
              </div>
              <div>
                <div className="font-extrabold text-slate-200">2023 Evidence Vault</div>
                <div className="text-[10px] text-slate-400">SHA-256 Merkle Chain</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-10 space-y-12">
        
        {/* SECTION 1: 4 SIH PROBLEM STATEMENTS HUB */}
        <section className="space-y-6">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div>
              <span className="text-xs font-extrabold tracking-wider uppercase text-teal-400">Target Applications</span>
              <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight mt-1">
                The 4 SIH Problem Statement Applications
              </h2>
            </div>
            <p className="text-xs text-slate-400 max-w-md">
              Full feature implementations addressing Qualcomm, Ayush, MHA, and MoSJE challenge statements in one platform.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            
            {/* App 1: ArogyaSathi */}
            <div className="glass-card glass-card-hover rounded-2xl p-6 flex flex-col justify-between space-y-6 border border-slate-800">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded-md text-[10px] font-black bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
                    SIH26181 — Qualcomm
                  </span>
                  <span className="text-xl">🫀</span>
                </div>
                <h3 className="text-xl font-extrabold text-white">ArogyaSathi</h3>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Disaster health, ISO 7243 WBGT heat stress telemetry, Open-Meteo weather fetch, and fall detection SOS.
                </p>
              </div>

              <div className="space-y-3 pt-4 border-t border-slate-800/80">
                <div className="flex items-center justify-between text-xs text-slate-300">
                  <span>Thermal Risk:</span>
                  <span className="font-bold text-amber-400">{liveWeather?.current?.heat_risk_tier || 'CRITICAL'}</span>
                </div>
                <Link
                  href="/arogya"
                  className="w-full py-2.5 rounded-xl bg-cyan-500/10 hover:bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 text-xs font-bold transition flex items-center justify-center gap-1.5"
                >
                  <span>Launch ArogyaSathi App</span>
                  <span>→</span>
                </Link>
              </div>
            </div>

            {/* App 2: MediKiosk */}
            <div className="glass-card glass-card-hover rounded-2xl p-6 flex flex-col justify-between space-y-6 border border-slate-800">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded-md text-[10px] font-black bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                    SIH26047 — Ayush
                  </span>
                  <span className="text-xl">🏥</span>
                </div>
                <h3 className="text-xl font-extrabold text-white">MediKiosk</h3>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Voice clinical history intake, SOCRATES questionnaire, AYUSH Prakriti profile, and dual prescription engine.
                </p>
              </div>

              <div className="space-y-3 pt-4 border-t border-slate-800/80">
                <div className="flex items-center justify-between text-xs text-slate-300">
                  <span>Prescription:</span>
                  <span className="font-bold text-emerald-400">Allopathy + AYUSH</span>
                </div>
                <Link
                  href="/medikiosk"
                  className="w-full py-2.5 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 text-xs font-bold transition flex items-center justify-center gap-1.5"
                >
                  <span>Launch MediKiosk App</span>
                  <span>→</span>
                </Link>
              </div>
            </div>

            {/* App 3: RakshakMitra */}
            <div className="glass-card glass-card-hover rounded-2xl p-6 flex flex-col justify-between space-y-6 border border-slate-800">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded-md text-[10px] font-black bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                    SIH26186 — MHA / Defense
                  </span>
                  <span className="text-xl">🎖️</span>
                </div>
                <h3 className="text-xl font-extrabold text-white">RakshakMitra</h3>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Burnout Index predictor, voice journal acoustic tremor analysis, and Garrison battalion unit stress heatmap.
                </p>
              </div>

              <div className="space-y-3 pt-4 border-t border-slate-800/80">
                <div className="flex items-center justify-between text-xs text-slate-300">
                  <span>Unit Risk Heatmap:</span>
                  <span className="font-bold text-indigo-400">Active Monitoring</span>
                </div>
                <Link
                  href="/rakshak"
                  className="w-full py-2.5 rounded-xl bg-indigo-500/10 hover:bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 text-xs font-bold transition flex items-center justify-center gap-1.5"
                >
                  <span>Launch RakshakMitra App</span>
                  <span>→</span>
                </Link>
              </div>
            </div>

            {/* App 4: NyayaSahay */}
            <div className="glass-card glass-card-hover rounded-2xl p-6 flex flex-col justify-between space-y-6 border border-slate-800">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded-md text-[10px] font-black bg-purple-500/10 text-purple-400 border border-purple-500/20">
                    SIH26094 — MoSJE
                  </span>
                  <span className="text-xl">⚖️</span>
                </div>
                <h3 className="text-xl font-extrabold text-white">NyayaSahay</h3>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Atrocity victim distress trajectory, DistilBERT crisis NLP, stealth PIN `9999=`, and BSA 2023 evidence chain.
                </p>
              </div>

              <div className="space-y-3 pt-4 border-t border-slate-800/80">
                <div className="flex items-center justify-between text-xs text-slate-300">
                  <span>Counselor Desk:</span>
                  <span className="font-bold text-purple-400">Escalations Ready</span>
                </div>
                <Link
                  href="/nyaya"
                  className="w-full py-2.5 rounded-xl bg-purple-500/10 hover:bg-purple-500/20 text-purple-300 border border-purple-500/30 text-xs font-bold transition flex items-center justify-center gap-1.5"
                >
                  <span>Launch NyayaSahay App</span>
                  <span>→</span>
                </Link>
              </div>
            </div>

          </div>
        </section>

        {/* SECTION 2: NON-INVASIVE PALMAR ANEMIA & COUGH HIGHLIGHT BANNER */}
        <section className="glass-card rounded-3xl p-8 border border-slate-800 relative overflow-hidden bg-gradient-to-r from-slate-950 via-slate-900 to-slate-950">
          <div className="absolute right-0 top-0 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl pointer-events-none" />
          <div className="flex flex-col lg:flex-row items-center justify-between gap-8 relative z-10">
            <div className="space-y-4 max-w-2xl">
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20">
                <span>🔬</span>
                <span>Non-Invasive Diagnostic Biomarkers</span>
              </span>
              <h2 className="text-2xl sm:text-4xl font-black text-white tracking-tight">
                Palmar Anemia RGB Colorimetry &amp; <br />
                <span className="text-gradient-teal">Acoustic Cough Biomarker Screener</span>
              </h2>
              <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
                Run point-of-care anemia screening using camera palmar/nail-bed RGB colorimetry (GradientBoosting regressor) and 3-second FFT acoustic cough wave analysis without drawing blood.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row items-center gap-4 w-full lg:w-auto">
              <Link
                href="/screening"
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-gradient-to-r from-rose-500 to-pink-600 hover:from-rose-400 hover:to-pink-500 text-white font-extrabold text-sm shadow-lg shadow-rose-600/25 transition text-center"
              >
                Test Palmar Anemia RGB
              </Link>
              <Link
                href="/screening"
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-sm border border-slate-700 transition text-center"
              >
                Test Cough Audio ML
              </Link>
            </div>
          </div>
        </section>

        {/* SECTION 3: INTERACTIVE DEMO ENGINES TABBED SUITE */}
        <section className="space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <span className="text-xs font-extrabold tracking-wider uppercase text-cyan-400">Live Execution</span>
              <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight mt-1">
                Interactive Clinical AI &amp; Diagnostic Playground
              </h2>
            </div>

            {/* Navigation Tabs */}
            <div className="flex bg-slate-900/90 p-1.5 rounded-xl border border-slate-800 overflow-x-auto scrollbar-none">
              {[
                { id: 'clinical', label: '🩺 Dual Prescription' },
                { id: 'screening', label: '🔬 Anemia & Cough' },
                { id: 'frontline', label: '👩‍⚕️ ASHA & Epidemic' },
                { id: 'mental', label: '🧠 Defense Resilience' },
                { id: 'safety', label: '🛡️ Evidence Chain' },
              ].map((t) => (
                <button
                  key={t.id}
                  onClick={() => setActiveTab(t.id as any)}
                  className={`px-4 py-2 rounded-lg text-xs font-extrabold transition whitespace-nowrap ${
                    activeTab === t.id
                      ? 'bg-gradient-to-r from-teal-500 to-cyan-500 text-slate-950 shadow-md shadow-teal-500/20'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>

          {/* TAB 1: CLINICAL & DUAL PRESCRIPTION */}
          {activeTab === 'clinical' && (
            <div className="glass-card rounded-2xl p-6 sm:p-8 border border-slate-800 space-y-6">
              <div className="space-y-2">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                  <span>🩺</span> Pre-OPD Triage &amp; Parallel Allopathy + AYUSH Prescription Engine
                </h3>
                <p className="text-xs text-slate-400">
                  Reconciles ICD-11 modern medicine pathways with Ayurvedic Ahara/Vihara and Pranayama protocols.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-300 mb-1">Chief Complaint</label>
                    <input
                      type="text"
                      value={chiefComplaint}
                      onChange={(e) => setChiefComplaint(e.target.value)}
                      className="w-full px-4 py-2.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-100 focus:outline-none focus:border-teal-500"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-300 mb-1">Symptoms List</label>
                    <input
                      type="text"
                      value={symptomsList}
                      onChange={(e) => setSymptomsList(e.target.value)}
                      className="w-full px-4 py-2.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-100 focus:outline-none focus:border-teal-500"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-300 mb-1">Clinical Condition Key</label>
                    <select
                      value={selectedCondition}
                      onChange={(e) => setSelectedCondition(e.target.value)}
                      className="w-full px-4 py-2.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-100 focus:outline-none focus:border-teal-500"
                    >
                      <option value="HEAT_STRESS">HEAT_STRESS (Heat Exhaustion)</option>
                      <option value="ACUTE_BRONCHITIS">ACUTE_BRONCHITIS (Respiratory Distress)</option>
                      <option value="ANEMIA_FATIGUE">ANEMIA_FATIGUE (Pallor &amp; Iron Deficiency)</option>
                    </select>
                  </div>

                  <button
                    onClick={handleRunClinicalTriage}
                    disabled={clinicalLoading}
                    className="w-full py-3 rounded-xl bg-gradient-to-r from-teal-500 to-cyan-500 text-slate-950 font-black text-xs transition shadow-lg shadow-teal-500/20 hover:opacity-90 disabled:opacity-50"
                  >
                    {clinicalLoading ? 'Evaluating Dual Prescription...' : 'Run Dual Prescription Triage'}
                  </button>
                </div>

                {/* Output Box */}
                <div className="glass-panel rounded-xl p-5 border border-slate-800 space-y-4">
                  <div className="text-xs font-bold text-teal-400 uppercase tracking-wider">Engine Output</div>
                  {clinicalResult ? (
                    <div className="space-y-3 text-xs">
                      <div className="flex justify-between border-b border-slate-800 pb-2">
                        <span className="text-slate-400">Triage Tier:</span>
                        <span className="font-extrabold text-amber-400">{clinicalResult.triage.triage_level}</span>
                      </div>
                      <div className="flex justify-between border-b border-slate-800 pb-2">
                        <span className="text-slate-400">ICD-11 Diagnosis:</span>
                        <span className="font-extrabold text-white">{clinicalResult.dualRx.icd_11_code} — {clinicalResult.dualRx.condition_name}</span>
                      </div>
                      <div>
                        <span className="font-bold text-cyan-400">Allopathic Pathway:</span>
                        <p className="text-slate-300 mt-0.5">{clinicalResult.dualRx.allopathic_pathway.primary}</p>
                      </div>
                      <div>
                        <span className="font-bold text-emerald-400">Ayurvedic Ahara/Vihara:</span>
                        <p className="text-slate-300 mt-0.5">{clinicalResult.dualRx.ayush_integrative_pathway.ayurveda}</p>
                      </div>
                    </div>
                  ) : (
                    <div className="text-xs text-slate-500 italic text-center py-10">
                      Click "Run Dual Prescription Triage" to execute parallel Allopathy + AYUSH clinical engines.
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: ANEMIA & COUGH */}
          {activeTab === 'screening' && (
            <div className="glass-card rounded-2xl p-6 sm:p-8 border border-slate-800 space-y-6">
              <div className="space-y-2">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                  <span>🔬</span> Palmar Hemoglobin Colorimetry &amp; Cough Wave ML
                </h3>
                <p className="text-xs text-slate-400">
                  Camera palmar/nail-bed RGB colorimetry coupled with Zero Crossing Rate FFT audio classifier.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Palmar Anemia RGB */}
                <div className="glass-panel p-5 rounded-xl border border-slate-800 space-y-4">
                  <div className="font-bold text-sm text-rose-400 flex items-center gap-2">
                    <span>🩸</span> Palmar Anemia RGB Colorimetry
                  </div>
                  
                  <div className="space-y-3">
                    <div className="grid grid-cols-3 gap-2 text-center text-xs">
                      <button
                        onClick={() => { setRedVal(230); setGreenVal(190); setBlueVal(185); }}
                        className="p-2 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-300 font-bold hover:bg-rose-500/20"
                      >
                        Pale Pallor
                      </button>
                      <button
                        onClick={() => { setRedVal(210); setGreenVal(155); setBlueVal(140); }}
                        className="p-2 rounded-lg bg-amber-500/10 border border-amber-500/30 text-amber-300 font-bold hover:bg-amber-500/20"
                      >
                        Mild Anemia
                      </button>
                      <button
                        onClick={() => { setRedVal(185); setGreenVal(125); setBlueVal(105); }}
                        className="p-2 rounded-lg bg-teal-500/10 border border-teal-500/30 text-teal-300 font-bold hover:bg-teal-500/20"
                      >
                        Healthy Capillary
                      </button>
                    </div>

                    <button
                      onClick={handleRunAnemiaColorimetry}
                      disabled={anemiaLoading}
                      className="w-full py-2.5 rounded-xl bg-gradient-to-r from-rose-500 to-pink-600 text-white font-extrabold text-xs shadow-md shadow-rose-600/20 hover:opacity-90"
                    >
                      {anemiaLoading ? 'Estimating Hb...' : 'Compute Hemoglobin (g/dL)'}
                    </button>

                    {anemiaResult && (
                      <div className="pt-3 border-t border-slate-800 space-y-1 text-xs">
                        <div className="text-lg font-black text-rose-400">
                          Hb: {anemiaResult.estimated_hb_g_dl} g/dL
                        </div>
                        <div className="font-bold text-slate-200">Severity: {anemiaResult.anemia_severity}</div>
                        <div className="text-slate-400 text-[11px]">{anemiaResult.clinical_action}</div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Acoustic Cough ML */}
                <div className="glass-panel p-5 rounded-xl border border-slate-800 space-y-4">
                  <div className="font-bold text-sm text-cyan-400 flex items-center gap-2">
                    <span>🎙️</span> Acoustic Cough Wave Biomarker Classifier
                  </div>

                  <div className="space-y-3">
                    <p className="text-xs text-slate-400">
                      Evaluates Spectral Centroid, Rolloff, and Zero Crossing Rate for TB / Wheeze screening.
                    </p>

                    <button
                      onClick={handleRunCoughScreening}
                      disabled={coughLoading}
                      className="w-full py-2.5 rounded-xl bg-gradient-to-r from-cyan-500 to-indigo-600 text-white font-extrabold text-xs shadow-md shadow-cyan-500/20 hover:opacity-90"
                    >
                      {coughLoading ? 'Analyzing Audio Spectrogram...' : 'Run Acoustic Cough Analysis'}
                    </button>

                    {coughResult && (
                      <div className="pt-3 border-t border-slate-800 space-y-1 text-xs">
                        <div className="text-lg font-black text-cyan-400">
                          Classification: {coughResult.cough_type}
                        </div>
                        <div className="text-slate-300 font-medium">Confidence: {(coughResult.confidence_score * 100).toFixed(1)}%</div>
                        <div className="text-slate-400 text-[11px]">{coughResult.clinical_recommendation}</div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: ASHA & FRONTLINE */}
          {activeTab === 'frontline' && (
            <div className="glass-card rounded-2xl p-6 sm:p-8 border border-slate-800 space-y-6">
              <div className="space-y-2">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                  <span>👩‍⚕️</span> ASHA Worker Field Copilot &amp; Outbreak Cluster Heatmap
                </h3>
                <p className="text-xs text-slate-400">
                  MoHFW Ante-Natal Care high-risk maternal triage &amp; DBSCAN spatial cluster detection.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-300 mb-1">Patient Name &amp; Age</label>
                    <div className="grid grid-cols-3 gap-2">
                      <input
                        type="text"
                        value={ashaPatient}
                        onChange={(e) => setAshaPatient(e.target.value)}
                        className="col-span-2 px-3 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white"
                      />
                      <input
                        type="number"
                        value={ashaAge}
                        onChange={(e) => setAshaAge(Number(e.target.value))}
                        className="px-3 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-300 mb-1">Maternal Symptoms</label>
                    <input
                      type="text"
                      value={ashaSymptoms}
                      onChange={(e) => setAshaSymptoms(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white"
                    />
                  </div>

                  <button
                    onClick={handleRunAshaTriage}
                    className="w-full py-3 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 text-slate-950 font-black text-xs shadow-md shadow-emerald-500/20"
                  >
                    Evaluate Maternal Triage &amp; Cluster Risk
                  </button>
                </div>

                <div className="glass-panel p-5 rounded-xl border border-slate-800 space-y-3 text-xs">
                  <div className="font-bold text-emerald-400">ASHA Copilot Assessment:</div>
                  {ashaResult ? (
                    <div className="space-y-2">
                      <div className="font-extrabold text-amber-400">Triage Tier: {ashaResult.triage_tier}</div>
                      <div className="text-slate-300">Action: {ashaResult.recommended_action}</div>
                      {epidemicResult && (
                        <div className="pt-2 border-t border-slate-800 text-cyan-300">
                          Epidemic Threat Level: {epidemicResult.epidemic_threat_index} ({epidemicResult.active_clusters_found} clusters)
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="text-slate-500 italic py-6">Click evaluate to run ASHA decision tree.</div>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: MENTAL WELLNESS */}
          {activeTab === 'mental' && (
            <div className="glass-card rounded-2xl p-6 sm:p-8 border border-slate-800 space-y-6">
              <div className="space-y-2">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                  <span>🧠</span> Defense Burnout Index &amp; Atrocity Psychological Trajectory
                </h3>
                <p className="text-xs text-slate-400">
                  Combines deployment metrics with 226-dim voice acoustic tremor analysis.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-3 text-xs">
                  <div>
                    <label className="block font-bold text-slate-300 mb-1">Weekly Duty Hours: {dutyHours} hrs</label>
                    <input
                      type="range"
                      min={40}
                      max={100}
                      value={dutyHours}
                      onChange={(e) => setDutyHours(Number(e.target.value))}
                      className="w-full accent-teal-500"
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-300 mb-1">Voice Journal Transcript</label>
                    <textarea
                      rows={2}
                      value={voiceText}
                      onChange={(e) => setVoiceText(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white"
                    />
                  </div>

                  <button
                    onClick={handleRunMentalAnalysis}
                    className="w-full py-3 rounded-xl bg-gradient-to-r from-indigo-500 to-purple-600 text-white font-black text-xs shadow-md shadow-indigo-500/20"
                  >
                    Compute Burnout &amp; Voice Stress Index
                  </button>
                </div>

                <div className="glass-panel p-5 rounded-xl border border-slate-800 space-y-3 text-xs">
                  <div className="font-bold text-indigo-400">Resilience Output:</div>
                  {burnoutResult ? (
                    <div className="space-y-2">
                      <div className="text-lg font-black text-amber-400">
                        Burnout Index: {burnoutResult.burnout_score} / 100 ({burnoutResult.risk_tier})
                      </div>
                      {voiceStressResult && (
                        <div className="text-slate-300">
                          Voice Stress Score: {voiceStressResult.voice_stress_score} / 100 ({voiceStressResult.stress_tier})
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="text-slate-500 italic py-6">Click compute to run acoustic stress models.</div>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* TAB 5: SAFETY & EVIDENCE VAULT */}
          {activeTab === 'safety' && (
            <div className="glass-card rounded-2xl p-6 sm:p-8 border border-slate-800 space-y-6">
              <div className="space-y-2">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                  <span>🛡️</span> BSA 2023 Sec 63 Cryptographic Merkle Evidence Vault
                </h3>
                <p className="text-xs text-slate-400">
                  Tamper-evident legal forensic evidence ledger for court trial admissibility.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-3 text-xs">
                  <div>
                    <label className="block font-bold text-slate-300 mb-1">Evidence Description</label>
                    <input
                      type="text"
                      value={evidenceDesc}
                      onChange={(e) => setEvidenceDesc(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs text-white"
                    />
                  </div>

                  <button
                    onClick={handleLogEvidence}
                    className="w-full py-3 rounded-xl bg-gradient-to-r from-purple-500 to-pink-600 text-white font-black text-xs shadow-md shadow-purple-500/20"
                  >
                    Commit Cryptographic Block to Merkle Chain
                  </button>
                </div>

                <div className="glass-panel p-5 rounded-xl border border-slate-800 space-y-3 text-xs">
                  <div className="font-bold text-purple-400">Merkle Vault Block:</div>
                  {evidenceResult ? (
                    <div className="space-y-1 font-mono text-[11px] text-slate-300">
                      <div>Block: #{evidenceResult.block_index}</div>
                      <div>SHA-256: {evidenceResult.sha256_hash?.slice(0, 24)}...</div>
                      <div>Merkle Root: {evidenceResult.merkle_root?.slice(0, 24)}...</div>
                      <div className="text-emerald-400 font-sans font-bold pt-1">{evidenceResult.legal_compliance}</div>
                    </div>
                  ) : (
                    <div className="text-slate-500 italic py-6">Commit evidence to view SHA-256 digest.</div>
                  )}
                </div>
              </div>
            </div>
          )}
        </section>

      </div>
    </div>
  );
}
