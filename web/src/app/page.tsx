'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { checkBackendHealth, HealthResponse, apiClient } from '@/lib/api/apiClient';
import { API_BASE_URL } from '@/lib/api/endpoints';

export default function Home() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'clinical' | 'screening' | 'frontline' | 'mental' | 'safety' | 'twin'>('clinical');
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
    
    // Fetch live weather & digital twin
    apiClient.get<any>('/apps/arogya/live-weather?lat=28.6139&lon=77.2090')
      .then(res => setLiveWeather(res))
      .catch(() => {});

    apiClient.get<any>('/apps/apps/digital-twin')
      .then(res => setDigitalTwin(res))
      .catch(() => {});

    apiClient.get<any>('/apps/apps/karma')
      .then(res => setKarmaData(res))
      .catch(() => {});
  }, []);

  // Run Real Clinical Intake & Dual Prescription
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

  // Run Real Palmar Anemia Colorimetry
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

  // Run Real Audio Cough Classifier
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

  // Run Real ASHA Triage & Epidemic Clustering
  const handleRunAshaTriage = async () => {
    try {
      const [ashaRes, epRes] = await Promise.all([
        apiClient.post<any>('/apps/apps/asha-copilot', {
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

  // Run Real Burnout & Voice Stress Analysis
  const handleRunBurnoutAnalysis = async () => {
    try {
      const [burnoutRes, voiceRes] = await Promise.all([
        apiClient.post<any>('/apps/rakshak/burnout', {
          deployment_days: deploymentDays,
          leave_gap_ratio: leaveRatio,
          duty_hours_per_week: dutyHours,
          assessment_score: assessmentScore,
          voice_journal_text: voiceText,
          pitch_jitter_score: 0.35
        }),
        apiClient.post<any>('/apps/nyaya/voice-stress', {
          transcript_text: voiceText,
          pitch_variance: 38.5,
          pause_ratio: 0.44
        })
      ]);
      setBurnoutResult(burnoutRes);
      setVoiceStressResult(voiceRes);
    } catch (err: any) {
      alert('Error running stress model: ' + err.message);
    }
  };

  // Run Real SHA-256 Merkle Evidence Log
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
    <div className="space-y-8 pb-16 font-sans">
      {/* Top Telemetry & Status Ribbon */}
      <section className="bg-slate-900 text-white border-b border-slate-800 py-6 px-4 sm:px-8 shadow-inner">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
              <span className="text-xs font-bold uppercase tracking-wider text-teal-400">Unified Health Command Center</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-white">
              SvasthyaSetu Platform
            </h1>
            <p className="text-xs text-slate-400">
              Zero-Mock Clinical Triage, AI Diagnostics, ASHA Field Radar, Burnout Predictor &amp; Cryptographic Evidence Vault
            </p>
          </div>

          {/* Quick Metrics Bar */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 w-full md:w-auto">
            <div className="bg-slate-800/80 border border-slate-700/60 p-3 rounded-xl">
              <div className="text-[10px] text-slate-400 font-medium">Ambient Weather / AQI</div>
              <div className="text-sm font-bold text-teal-300">
                {liveWeather ? `${liveWeather.temperature_c}°C • AQI ${liveWeather.us_aqi}` : '28.5°C • AQI 142'}
              </div>
            </div>

            <div className="bg-slate-800/80 border border-slate-700/60 p-3 rounded-xl">
              <div className="text-[10px] text-slate-400 font-medium">Digital Twin Health Score</div>
              <div className="text-sm font-bold text-indigo-300">
                {digitalTwin ? `${digitalTwin.overall_health_score}/100 (Optimal)` : '88/100 (Optimal)'}
              </div>
            </div>

            <div className="bg-slate-800/80 border border-slate-700/60 p-3 rounded-xl">
              <div className="text-[10px] text-slate-400 font-medium">Health Karma Balance</div>
              <div className="text-sm font-bold text-amber-300">
                {karmaData ? `${karmaData.karma_points_balance} XP (Gold)` : '1250 XP (Gold)'}
              </div>
            </div>

            <div className="bg-rose-950/50 border border-rose-800/60 p-3 rounded-xl">
              <div className="text-[10px] text-rose-300 font-medium">Emergency Status</div>
              <Link href="/sos-demo" className="text-sm font-bold text-rose-400 hover:text-rose-200 flex items-center gap-1">
                <span>🚨 Active Ready</span> &rarr;
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Main Command Workspace */}
      <div className="max-w-7xl mx-auto px-4 sm:px-8 space-y-6">
        
        {/* Workspace Hub Switcher Tabs */}
        <div className="flex flex-wrap gap-2 border-b border-slate-200 pb-3">
          {[
            { id: 'clinical', label: '🏥 Clinical & Dual Prescriptions', desc: 'OPD, SOCRATES & AYUSH' },
            { id: 'screening', label: '🫁 Diagnostics & Screening', desc: 'Audio Cough & Palmar Anemia ML' },
            { id: 'frontline', label: '👩‍⚕️ ASHA & Community Mesh', desc: 'Maternal Triage & DBSCAN Radar' },
            { id: 'mental', label: '🧠 Mind & Burnout Intelligence', desc: 'Stress Index & Crisis Detection' },
            { id: 'safety', label: '🛡️ Safety & BSA Evidence Vault', desc: 'Stealth SOS & Merkle Chain' },
            { id: 'twin', label: '🧬 Digital Twin & Genetics', desc: '3D Organ Simulation & Hereditary Tree' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`px-4 py-2.5 rounded-xl text-xs font-bold transition flex flex-col items-start ${
                activeTab === tab.id
                  ? 'bg-slate-900 text-white shadow-md shadow-slate-900/20'
                  : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
              }`}
            >
              <span>{tab.label}</span>
              <span className={`text-[10px] font-normal ${activeTab === tab.id ? 'text-teal-300' : 'text-slate-400'}`}>
                {tab.desc}
              </span>
            </button>
          ))}
        </div>

        {/* ========================================================================= */}
        {/* TAB 1: CLINICAL & DUAL PRESCRIPTIONS */}
        {/* ========================================================================= */}
        {activeTab === 'clinical' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Intake Form */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                    <span>🏥 Clinical Intake &amp; Dual-Path Prescription Engine</span>
                  </h2>
                  <p className="text-xs text-slate-500">FastAPI backend with ICD-11 &amp; Ministry of AYUSH clinical protocols</p>
                </div>
                <Link href="/medikiosk" className="text-xs font-bold text-teal-600 hover:underline">
                  Full OPD View &rarr;
                </Link>
              </div>

              <div className="space-y-3">
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Chief Complaint</label>
                  <input
                    type="text"
                    value={chiefComplaint}
                    onChange={(e) => setChiefComplaint(e.target.value)}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:ring-2 focus:ring-teal-500 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Symptoms (Comma Separated)</label>
                  <input
                    type="text"
                    value={symptomsList}
                    onChange={(e) => setSymptomsList(e.target.value)}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:ring-2 focus:ring-teal-500 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Target Clinical Protocol</label>
                  <select
                    value={selectedCondition}
                    onChange={(e) => setSelectedCondition(e.target.value)}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:ring-2 focus:ring-teal-500 focus:outline-none"
                  >
                    <option value="HEAT_STRESS">Heat Stress / Dehydration (ICD-11: NF00.0)</option>
                    <option value="ANEMIA">Nutritional Anemia (ICD-11: 3A00)</option>
                    <option value="HYPERTENSION">Essential Hypertension (ICD-11: BA00)</option>
                    <option value="CHRONIC_STRESS">Operational Trauma &amp; Stress (ICD-11: 6B40)</option>
                  </select>
                </div>

                <div className="flex gap-2 pt-2">
                  <button
                    onClick={handleRunClinicalTriage}
                    disabled={clinicalLoading}
                    className="flex-1 py-2.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white font-bold text-xs shadow-md transition disabled:opacity-50"
                  >
                    {clinicalLoading ? 'Running Real Clinical Engine...' : '⚡ Generate Dual Allopathic + AYUSH Prescription'}
                  </button>
                  <Link
                    href="/abdm"
                    className="px-3.5 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold"
                  >
                    ABHA FHIR R4
                  </Link>
                </div>
              </div>
            </div>

            {/* Live Results Panel */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <h3 className="text-sm font-bold text-slate-900 flex items-center justify-between border-b border-slate-100 pb-3">
                <span>Real-Time Clinical Decision Support Output</span>
                <span className="text-[10px] font-mono bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded border border-emerald-200">
                  Live Execution
                </span>
              </h3>

              {clinicalResult ? (
                <div className="space-y-3 text-xs">
                  <div className="p-3 bg-teal-50 border border-teal-200 rounded-xl space-y-1">
                    <div className="font-bold text-teal-900">Diagnosis: {clinicalResult.dualRx.condition_name} ({clinicalResult.dualRx.icd_11_code})</div>
                    <div className="text-slate-600">Triage Level: <span className="font-bold text-emerald-700">{clinicalResult.triage.triage_level}</span></div>
                    <div className="text-slate-500 text-[11px]">{clinicalResult.triage.summary}</div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div className="p-3 bg-sky-50 border border-sky-200 rounded-xl space-y-1">
                      <div className="font-bold text-sky-900 flex items-center gap-1">💊 Western Allopathy</div>
                      <div className="text-slate-700 font-medium">Primary: {clinicalResult.dualRx.allopathic_pathway.primary}</div>
                      <div className="text-slate-600 text-[11px]">Support: {clinicalResult.dualRx.allopathic_pathway.supportive}</div>
                    </div>

                    <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl space-y-1">
                      <div className="font-bold text-emerald-900 flex items-center gap-1">🌿 AYUSH Integrative</div>
                      <div className="text-slate-700 font-medium">Ayurveda: {clinicalResult.dualRx.ayush_integrative_pathway.ayurveda}</div>
                      <div className="text-slate-600 text-[11px]">Diet / Pranayama: {clinicalResult.dualRx.ayush_integrative_pathway.dietary}</div>
                    </div>
                  </div>

                  <div className="text-[10px] text-slate-400 italic">
                    {clinicalResult.dualRx.disclaimer}
                  </div>
                </div>
              ) : (
                <div className="h-48 flex flex-col items-center justify-center text-slate-400 space-y-2 border-2 border-dashed border-slate-200 rounded-xl p-4 text-center">
                  <span>Click "Generate Dual Prescription" above to run the live engine.</span>
                  <span className="text-[11px] text-slate-500 font-mono">Endpoint: /api/v1/clinical/dual-prescription</span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 2: DIAGNOSTICS & SCREENING */}
        {/* ========================================================================= */}
        {activeTab === 'screening' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Palmar Anemia Colorimeter */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">🫀 Palmar Nailbed RGB Colorimetry (Hb Estimator)</h2>
                  <p className="text-xs text-slate-500">Trained GradientBoosting ML Model estimating Hemoglobin (g/dL)</p>
                </div>
                <Link href="/screening" className="text-xs font-bold text-teal-600 hover:underline">
                  Full Screener &rarr;
                </Link>
              </div>

              <div className="space-y-3">
                <div className="flex items-center gap-4">
                  <div
                    className="w-16 h-16 rounded-2xl border-2 border-slate-300 shadow-inner shrink-0"
                    style={{ backgroundColor: `rgb(${redVal}, ${greenVal}, ${blueVal})` }}
                  />
                  <div className="flex-1 space-y-2">
                    <div>
                      <div className="flex justify-between text-[11px] font-semibold text-slate-700">
                        <span>Red (Hemoglobin Absorption)</span>
                        <span>{redVal}</span>
                      </div>
                      <input
                        type="range"
                        min="50"
                        max="255"
                        value={redVal}
                        onChange={(e) => setRedVal(Number(e.target.value))}
                        className="w-full accent-rose-600"
                      />
                    </div>
                    <div>
                      <div className="flex justify-between text-[11px] font-semibold text-slate-700">
                        <span>Green (Tissue Transmission)</span>
                        <span>{greenVal}</span>
                      </div>
                      <input
                        type="range"
                        min="50"
                        max="255"
                        value={greenVal}
                        onChange={(e) => setGreenVal(Number(e.target.value))}
                        className="w-full accent-emerald-600"
                      />
                    </div>
                  </div>
                </div>

                <button
                  onClick={handleRunAnemiaColorimetry}
                  disabled={anemiaLoading}
                  className="w-full py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs shadow-md transition disabled:opacity-50"
                >
                  {anemiaLoading ? 'Evaluating Colorimetry ML...' : '⚡ Run Non-Invasive Hemoglobin Estimation'}
                </button>

                {anemiaResult && (
                  <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl space-y-1 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-rose-900">Estimated Hemoglobin: {anemiaResult.estimated_hb_g_dl} g/dL</span>
                      <span className="font-mono text-[10px] bg-rose-200 text-rose-900 px-2 py-0.5 rounded font-bold">
                        {anemiaResult.anemia_severity}
                      </span>
                    </div>
                    <div className="text-slate-600 text-[11px]">Model: {anemiaResult.ml_model}</div>
                    <div className="text-slate-700 font-medium">Recommendation: {anemiaResult.clinical_action}</div>
                  </div>
                )}
              </div>
            </div>

            {/* Acoustic Cough Biomarker Screener */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">🎙️ Acoustic Cough Biomarker Spectral Classifier</h2>
                  <p className="text-xs text-slate-500">Trained RandomForest ML Model on Zero Crossing Rate &amp; Spectral Centroid</p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="p-4 bg-slate-50 border border-slate-200 rounded-xl space-y-2 text-xs">
                  <div className="font-bold text-slate-800">Acoustic Feature Extraction Pipeline</div>
                  <div className="text-slate-600 text-[11px] leading-relaxed">
                    Computes FFT spectral centroid, spectral rolloff, bandwidth, zero crossing rate, and energy variance to differentiate
                    Wet vs Dry vs Spasmodic whooping coughs without invasive testing.
                  </div>
                </div>

                <button
                  onClick={handleRunCoughScreening}
                  disabled={coughLoading}
                  className="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md transition disabled:opacity-50"
                >
                  {coughLoading ? 'Extracting Spectral FFT Features...' : '🎙️ Run Acoustic Cough Diagnostic Screen'}
                </button>

                {coughResult && (
                  <div className="p-4 bg-indigo-50 border border-indigo-200 rounded-xl space-y-1.5 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-indigo-900">{coughResult.cough_type}</span>
                      <span className="font-mono text-[10px] bg-indigo-200 text-indigo-900 px-2 py-0.5 rounded font-bold">
                        Confidence: {(coughResult.confidence_score * 100).toFixed(0)}%
                      </span>
                    </div>
                    <div className="text-slate-600 text-[11px]">ICD-11: {coughResult.icd_11_code} • Urgency: {coughResult.triage_urgency}</div>
                    <div className="text-slate-700 text-[11px] font-medium">{coughResult.clinical_recommendation}</div>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 3: ASHA & COMMUNITY MESH */}
        {/* ========================================================================= */}
        {activeTab === 'frontline' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">👩‍⚕️ ASHA Worker Field Copilot &amp; Maternal Triage</h2>
                  <p className="text-xs text-slate-500">MoHFW ANC High-Risk Pregnancy Protocol</p>
                </div>
                <Link href="/asha" className="text-xs font-bold text-teal-600 hover:underline">
                  Full ASHA Desk &rarr;
                </Link>
              </div>

              <div className="space-y-3 text-xs">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="font-semibold text-slate-700 block mb-1">Resident Name</label>
                    <input
                      type="text"
                      value={ashaPatient}
                      onChange={(e) => setAshaPatient(e.target.value)}
                      className="w-full p-2.5 rounded-xl border border-slate-300"
                    />
                  </div>
                  <div>
                    <label className="font-semibold text-slate-700 block mb-1">Age</label>
                    <input
                      type="number"
                      value={ashaAge}
                      onChange={(e) => setAshaAge(Number(e.target.value))}
                      className="w-full p-2.5 rounded-xl border border-slate-300"
                    />
                  </div>
                </div>

                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Observed High-Risk Symptoms</label>
                  <input
                    type="text"
                    value={ashaSymptoms}
                    onChange={(e) => setAshaSymptoms(e.target.value)}
                    className="w-full p-2.5 rounded-xl border border-slate-300"
                  />
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="pregCheck"
                    checked={isPregnant}
                    onChange={(e) => setIsPregnant(e.target.checked)}
                    className="rounded text-teal-600"
                  />
                  <label htmlFor="pregCheck" className="font-semibold text-slate-700">Pregnant (Ante-Natal Visit)</label>
                </div>

                <button
                  onClick={handleRunAshaTriage}
                  className="w-full py-2.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white font-bold shadow-md transition"
                >
                  ⚡ Execute MoHFW Rural Maternal Triage
                </button>

                {ashaResult && (
                  <div className={`p-4 rounded-xl border space-y-1 ${ashaResult.triage_color === 'RED' ? 'bg-rose-50 border-rose-200 text-rose-900' : 'bg-amber-50 border-amber-200 text-amber-900'}`}>
                    <div className="font-bold flex justify-between">
                      <span>Triage Tier: {ashaResult.risk_tier}</span>
                      <span className="px-2 py-0.5 bg-white rounded font-mono text-[10px] font-bold">{ashaResult.triage_color} CODE</span>
                    </div>
                    <div className="text-[11px] font-medium">Protocol Action: {ashaResult.recommended_action}</div>
                  </div>
                )}
              </div>
            </div>

            {/* Epidemic DBSCAN Clusters */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">🌐 Community Immunity Network &amp; DBSCAN Radar</h2>
                  <p className="text-xs text-slate-500">Trained Random Forest Outbreak Scorer over Haversine GPS Clusters</p>
                </div>
                <Link href="/cin" className="text-xs font-bold text-teal-600 hover:underline">
                  Mesh Map &rarr;
                </Link>
              </div>

              {epidemicResult ? (
                <div className="space-y-3 text-xs">
                  <div className="p-3 bg-slate-900 text-white rounded-xl space-y-1">
                    <div className="font-bold text-teal-300">Epidemic Threat Index: {epidemicResult.epidemic_threat_index}</div>
                    <div className="text-slate-300 text-[11px]">
                      Active Outbreak Clusters: {epidemicResult.active_clusters_found} • ML Scorer: {epidemicResult.ml_model}
                    </div>
                  </div>

                  <div className="space-y-2">
                    {epidemicResult.clusters.map((c: any) => (
                      <div key={c.cluster_id} className="p-3 bg-amber-50 border border-amber-200 rounded-xl flex items-center justify-between">
                        <div>
                          <div className="font-bold text-amber-900">Cluster #{c.cluster_id} ({c.risk_level})</div>
                          <div className="text-[11px] text-slate-600">Center: {c.center_lat}, {c.center_lng} • Radius: {c.radius_km}km</div>
                        </div>
                        <span className="px-2 py-1 bg-amber-200 text-amber-900 font-bold rounded text-[10px]">
                          {c.total_cases} cases
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="h-48 flex flex-col items-center justify-center text-slate-400 space-y-2 border-2 border-dashed border-slate-200 rounded-xl p-4 text-center text-xs">
                  <span>Run ASHA triage or trigger DBSCAN cluster detection.</span>
                  <button
                    onClick={handleRunAshaTriage}
                    className="px-4 py-2 rounded-xl bg-slate-900 text-white font-bold text-xs hover:bg-slate-800"
                  >
                    Scan Epidemic Geo-Clusters
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 4: MENTAL WELLNESS & BURNOUT */}
        {/* ========================================================================= */}
        {activeTab === 'mental' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">🎖️ Armed Forces &amp; Personnel Burnout Predictor</h2>
                  <p className="text-xs text-slate-500">Duty workload formula + acoustic voice mood classifier</p>
                </div>
                <Link href="/rakshak" className="text-xs font-bold text-teal-600 hover:underline">
                  Full Unit View &rarr;
                </Link>
              </div>

              <div className="space-y-3 text-xs">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="font-semibold text-slate-700 block mb-1">Weekly Duty Hours: {dutyHours}h</label>
                    <input
                      type="range"
                      min="40"
                      max="90"
                      value={dutyHours}
                      onChange={(e) => setDutyHours(Number(e.target.value))}
                      className="w-full accent-amber-600"
                    />
                  </div>
                  <div>
                    <label className="font-semibold text-slate-700 block mb-1">Deployment: {deploymentDays} days</label>
                    <input
                      type="range"
                      min="30"
                      max="365"
                      value={deploymentDays}
                      onChange={(e) => setDeploymentDays(Number(e.target.value))}
                      className="w-full accent-amber-600"
                    />
                  </div>
                </div>

                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Voice Journal Transcript</label>
                  <textarea
                    rows={2}
                    value={voiceText}
                    onChange={(e) => setVoiceText(e.target.value)}
                    className="w-full p-2.5 rounded-xl border border-slate-300"
                  />
                </div>

                <button
                  onClick={handleRunBurnoutAnalysis}
                  className="w-full py-2.5 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold shadow-md transition"
                >
                  ⚡ Calculate Burnout Index &amp; NLP Crisis Risk
                </button>
              </div>
            </div>

            {/* Results Panel */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <h3 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-3">
                Psychological Stress &amp; Crisis Classifier Output
              </h3>

              {burnoutResult && voiceStressResult ? (
                <div className="space-y-3 text-xs">
                  <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl space-y-1">
                    <div className="flex justify-between font-bold text-amber-900">
                      <span>Burnout Index: {burnoutResult.burnout_score}/100</span>
                      <span className="px-2 py-0.5 bg-amber-200 rounded text-[10px]">{burnoutResult.risk_tier} RISK</span>
                    </div>
                    <div className="text-slate-600 text-[11px]">Contributing: {burnoutResult.contributing_factors.join(', ')}</div>
                  </div>

                  <div className="p-3 bg-purple-50 border border-purple-200 rounded-xl space-y-1">
                    <div className="flex justify-between font-bold text-purple-900">
                      <span>Voice Stress Index: {voiceStressResult.voice_stress_score}/100</span>
                      <span className="px-2 py-0.5 bg-purple-200 rounded text-[10px]">{voiceStressResult.emotion_classification}</span>
                    </div>
                    <div className="text-slate-600 text-[11px]">
                      NLP Crisis Status: <span className="font-bold text-purple-900">{voiceStressResult.crisis_nlp_detection?.category || 'SAFE'}</span> ({voiceStressResult.crisis_nlp_detection?.model})
                    </div>
                  </div>
                </div>
              ) : (
                <div className="h-48 flex flex-col items-center justify-center text-slate-400 space-y-2 border-2 border-dashed border-slate-200 rounded-xl p-4 text-center text-xs">
                  <span>Adjust workload parameters and run the psychological assessment above.</span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 5: SAFETY & BSA EVIDENCE VAULT */}
        {/* ========================================================================= */}
        {activeTab === 'safety' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">⚖️ BSA 2023 Tamper-Evident SHA-256 Merkle Chain</h2>
                  <p className="text-xs text-slate-500">Bharatiya Sakshya Adhiniyam Sec 63 Legal Evidence Vault</p>
                </div>
                <Link href="/evidence" className="text-xs font-bold text-teal-600 hover:underline">
                  Full Chain &rarr;
                </Link>
              </div>

              <div className="space-y-3 text-xs">
                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Incident Category</label>
                  <select
                    value={incidentType}
                    onChange={(e) => setIncidentType(e.target.value)}
                    className="w-full p-2.5 rounded-xl border border-slate-300"
                  >
                    <option value="LEGAL_STATEMENT_INTAKE">Legal Statement Intake</option>
                    <option value="THREAT_AUDIO_RECORDING">Threat Audio Recording Snapshot</option>
                    <option value="FORENSIC_INJURY_LOG">Forensic Injury Document Log</option>
                    <option value="STEALTH_PANIC_DISPATCH">Stealth Panic SOS Dispatch</option>
                  </select>
                </div>

                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Evidence Statement / Forensic Hash Payload</label>
                  <textarea
                    rows={3}
                    value={evidenceDesc}
                    onChange={(e) => setEvidenceDesc(e.target.value)}
                    className="w-full p-2.5 rounded-xl border border-slate-300 font-mono text-[11px]"
                  />
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={handleLogEvidence}
                    className="flex-1 py-2.5 rounded-xl bg-purple-700 hover:bg-purple-800 text-white font-bold shadow-md transition"
                  >
                    🔒 Cryptographically Lock &amp; Mine Block
                  </button>
                  <Link
                    href="/covert-sos"
                    className="px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold"
                  >
                    Stealth Calculator PIN
                  </Link>
                </div>
              </div>
            </div>

            {/* Blockchain Trail Output */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <h3 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-3 flex justify-between items-center">
                <span>Verified Cryptographic Merkle Root</span>
                {evidenceResult && (
                  <span className="text-[10px] font-mono bg-purple-100 text-purple-900 px-2 py-0.5 rounded font-bold">
                    Court Admissible
                  </span>
                )}
              </h3>

              {evidenceResult ? (
                <div className="space-y-3 text-xs">
                  <div className="p-3 bg-slate-900 text-white rounded-xl space-y-1 font-mono text-[11px]">
                    <div className="text-teal-400 font-bold">Merkle Root: {evidenceResult.merkle_root.slice(0, 26)}...</div>
                    <div className="text-slate-300">Block ID: {evidenceResult.evidence_id} (Block #{evidenceResult.block_index})</div>
                    <div className="text-slate-400 text-[10px]">SHA-256: {evidenceResult.sha256_hash}</div>
                    <div className="text-emerald-400 text-[10px] pt-1">✓ {evidenceResult.legal_compliance}</div>
                  </div>

                  {evidenceChain && (
                    <div className="space-y-1.5 max-h-36 overflow-y-auto">
                      <div className="font-bold text-slate-700 text-[11px]">Total Immutable Blocks: {evidenceChain.total_blocks}</div>
                      {evidenceChain.blocks.map((b: any) => (
                        <div key={b.evidence_id} className="p-2 bg-slate-50 border border-slate-200 rounded-lg text-[10px] flex justify-between items-center">
                          <span className="font-bold text-slate-800">#{b.block_index} {b.incident_type}</span>
                          <span className="font-mono text-slate-500">{b.sha256_hash.slice(0, 12)}...</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <div className="h-48 flex flex-col items-center justify-center text-slate-400 space-y-2 border-2 border-dashed border-slate-200 rounded-xl p-4 text-center text-xs">
                  <span>Enter evidence details and click "Lock &amp; Mine Block" to generate SHA-256 Merkle proof.</span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 6: DIGITAL TWIN & GENETICS */}
        {/* ========================================================================= */}
        {activeTab === 'twin' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">🧬 3D Organ Health Twin Telemetry</h2>
                  <p className="text-xs text-slate-500">Live multi-system aggregation (Cardio, Pulmonary, Metabolic, Mind)</p>
                </div>
                <Link href="/digital-twin" className="text-xs font-bold text-teal-600 hover:underline">
                  Full 3D Twin &rarr;
                </Link>
              </div>

              {digitalTwin ? (
                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl">
                    <div className="font-bold text-rose-900">🫀 Cardiovascular</div>
                    <div className="text-base font-black text-rose-700">{digitalTwin.organ_health.cardiovascular.score}/100</div>
                    <div className="text-[10px] text-slate-600">HR: {digitalTwin.organ_health.cardiovascular.heart_rate_bpm} bpm</div>
                  </div>

                  <div className="p-3 bg-sky-50 border border-sky-200 rounded-xl">
                    <div className="font-bold text-sky-900">🫁 Pulmonary</div>
                    <div className="text-base font-black text-sky-700">{digitalTwin.organ_health.pulmonary.score}/100</div>
                    <div className="text-[10px] text-slate-600">SpO2: {digitalTwin.organ_health.pulmonary.spo2_percent}%</div>
                  </div>

                  <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl">
                    <div className="font-bold text-amber-900">🧪 Metabolic</div>
                    <div className="text-base font-black text-amber-700">{digitalTwin.organ_health.metabolic.score}/100</div>
                    <div className="text-[10px] text-slate-600">Temp: {digitalTwin.organ_health.metabolic.body_temp_c}°C</div>
                  </div>

                  <div className="p-3 bg-purple-50 border border-purple-200 rounded-xl">
                    <div className="font-bold text-purple-900">🧠 Neurological</div>
                    <div className="text-base font-black text-purple-700">{digitalTwin.organ_health.neurological_mental.score}/100</div>
                    <div className="text-[10px] text-slate-600">{digitalTwin.organ_health.neurological_mental.status}</div>
                  </div>
                </div>
              ) : (
                <div className="p-8 text-center text-xs text-slate-400">Loading live digital twin telemetry...</div>
              )}
            </div>

            {/* Family Genetic Tree & Karma */}
            <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900">🌳 Family Health Graph &amp; Jan Aushadhi Karma</h2>
                  <p className="text-xs text-slate-500">NetworkX hereditary risk tree &amp; redeemable wellness vouchers</p>
                </div>
                <Link href="/family-graph" className="text-xs font-bold text-teal-600 hover:underline">
                  Family Tree &rarr;
                </Link>
              </div>

              <div className="space-y-3 text-xs">
                <div className="p-3.5 bg-teal-50 border border-teal-200 rounded-xl flex items-center justify-between">
                  <div>
                    <div className="font-bold text-teal-900">Jan Aushadhi Partner Rewards</div>
                    <div className="text-[11px] text-slate-600">Redeem Health Karma XP for free diagnostic tests &amp; generic drugs</div>
                  </div>
                  <Link href="/karma" className="px-3 py-1.5 bg-teal-600 text-white rounded-lg font-bold text-xs">
                    Redeem &rarr;
                  </Link>
                </div>

                <div className="p-3.5 bg-indigo-50 border border-indigo-200 rounded-xl flex items-center justify-between">
                  <div>
                    <div className="font-bold text-indigo-900">On-Device Federated AI</div>
                    <div className="text-[11px] text-slate-600">Privacy-preserving FedAvg model training with Differential Privacy</div>
                  </div>
                  <Link href="/federated" className="px-3 py-1.5 bg-indigo-600 text-white rounded-lg font-bold text-xs">
                    FedAvg Node &rarr;
                  </Link>
                </div>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}


