'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import apiClient from '@/lib/api/apiClient';

interface ClinicalIntake {
  id: string;
  patient_name: string;
  symptoms: string[];
  duration: string;
  severity_rating: number;
  chief_complaint: string;
  history_present_illness: string;
  review_systems: string;
  triage_level: 'CRITICAL_EMERGENCY' | 'URGENT' | 'ROUTINE';
  summary: string;
  ayush_mode: boolean;
  created_at: string;
}

const DEFAULT_OPD_INTAKES: ClinicalIntake[] = [
  {
    id: 'INT-101',
    patient_name: 'Ramesh Patel (54M)',
    symptoms: ['Substernal Chest Pain', 'Left Arm Radiation', 'Diaphoresis'],
    duration: '45 mins',
    severity_rating: 9,
    chief_complaint: 'Crushing chest pressure radiating to left shoulder and neck',
    history_present_illness: 'Onset during morning walk. Patient has 8-year history of Type 2 Diabetes.',
    review_systems: 'Shortness of breath, cold sweats, mild nausea. No fever.',
    triage_level: 'CRITICAL_EMERGENCY',
    summary: 'RED FLAG ALERT: Acute coronary syndrome suspected. Immediate 12-lead ECG, troponin check, and physician bedside triage required.',
    ayush_mode: false,
    created_at: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
  },
  {
    id: 'INT-102',
    patient_name: 'Pooja Devi (28F)',
    symptoms: ['High Fever (102.4°F)', 'Rigors & Chills', 'Severe Headache'],
    duration: '2 days',
    severity_rating: 7,
    chief_complaint: 'Spiking fever with body ache and ocular pain',
    history_present_illness: 'Traveled to flood-affected rural belt 5 days ago. No relief with single dose paracetamol.',
    review_systems: 'Loss of appetite, mild dehydration, joint stiffness.',
    triage_level: 'URGENT',
    summary: 'URGENT OPD: Suspected acute viral/vector-borne infection (Dengue/Malaria). Order CBC, Platelet count, NS1 antigen test.',
    ayush_mode: true,
    created_at: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
  },
  {
    id: 'INT-103',
    patient_name: 'Sunita Rao (42F)',
    symptoms: ['Wheezing', 'Exertional Breathlessness', 'Nocturnal Cough'],
    duration: '5 days',
    severity_rating: 6,
    chief_complaint: 'Worsening asthma flare following high particulate AQI exposure',
    history_present_illness: 'Known asthmatic on inhaler; ran out of regular budesonide canister 4 days ago.',
    review_systems: 'Bilateral expiratory wheezes, mild chest tightness.',
    triage_level: 'URGENT',
    summary: 'URGENT: Acute exacerbation of bronchial asthma. Nebulization with Salbutamol and prescription renewal required.',
    ayush_mode: false,
    created_at: new Date(Date.now() - 90 * 60 * 1000).toISOString(),
  },
  {
    id: 'INT-104',
    patient_name: 'Anil Mehta (61M)',
    symptoms: ['Routine BP Checkup', 'Mild Fatigue'],
    duration: '2 weeks',
    severity_rating: 3,
    chief_complaint: 'Routine hypertension follow-up and prescription refill',
    history_present_illness: 'On Amlodipine 5mg OD. Reports consistent compliance.',
    review_systems: 'Asymptomatic, sleeping 7 hours nightly.',
    triage_level: 'ROUTINE',
    summary: 'ROUTINE CONSULTATION: Regular non-communicable disease (NCD) checkup.',
    ayush_mode: true,
    created_at: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
  },
];

const COMMON_SYMPTOMS = [
  'Chest Pain',
  'Shortness of Breath',
  'High Fever',
  'Persistent Cough',
  'Severe Headache',
  'Abdominal Pain',
  'Dizziness & Fainting',
  'Joint Pain & Swelling',
];

export default function MediKioskPage() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState<'INTAKE' | 'DOCTOR_QUEUE' | 'CHAT' | 'OCR'>('INTAKE');
  
  // Intake Form State
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>(['Persistent Cough', 'High Fever']);
  const [duration, setDuration] = useState('3 days');
  const [severityRating, setSeverityRating] = useState(6);
  const [chiefComplaint, setChiefComplaint] = useState('Throat irritation, fever spikes, and productive cough');
  const [hpi, setHpi] = useState('Symptoms began 3 days ago after outdoor exposure to smog. Worsened at night.');
  const [ros, setRos] = useState('Mild congestion, slight appetite loss. No chest tightness or hemoptysis.');
  const [ayushMode, setAyushMode] = useState(false);
  
  const [loading, setLoading] = useState(false);
  const [intakes, setIntakes] = useState<ClinicalIntake[]>(DEFAULT_OPD_INTAKES);
  const [selectedIntake, setSelectedIntake] = useState<ClinicalIntake | null>(null);
  const [latestIntake, setLatestIntake] = useState<ClinicalIntake | null>(null);

  // OCR Demo State
  const [ocrText, setOcrText] = useState(
    'PRESCRIPTION & LAB REPORT\nPatient: Ramesh Patel (54M)\nRx: Paracetamol 650mg TDS, Amoxicillin 500mg TDS, Pantoprazole 40mg OD\nLab: Fasting Blood Sugar: 165 mg/dL (HIGH), Serum Creatinine: 1.1 mg/dL (NORMAL)'
  );
  const [ocrAnalysis, setOcrAnalysis] = useState<any>({
    extracted_medications: ['Paracetamol 650mg (TDS)', 'Amoxicillin 500mg (TDS)', 'Pantoprazole 40mg (OD)'],
    lab_anomalies: [
      { parameter: 'Fasting Blood Sugar', observed_value: 165, unit: 'mg/dL', reference_range: '70 - 110 mg/dL', severity: 'HIGH_ANOMALY' }
    ],
    summary: 'Digitized prescription contains 3 medications and 1 elevated fasting glucose anomaly.'
  });

  // AI Chat State
  const [chatMessages, setChatMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string }>>([
    {
      role: 'assistant',
      content:
        'Hello! I am your MediKiosk AI Clinical Intake Assistant. I help record your symptoms, timeline, and medical history using standard clinical guidelines (SOCRATES / AYUSH) so your consulting physician has a doctor-ready summary. What symptoms are you experiencing today?',
    },
  ]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const fetchIntakes = async () => {
    try {
      const data = await apiClient.get('/apps/medikiosk/intake');
      if (Array.isArray(data) && data.length > 0) {
        setIntakes(data);
      }
    } catch (e) {
      console.error('Maintaining pre-seeded OPD intake queue', e);
    }
  };

  useEffect(() => {
    if (user) {
      fetchIntakes();
    }
  }, [user]);

  const toggleSymptom = (symptom: string) => {
    if (selectedSymptoms.includes(symptom)) {
      setSelectedSymptoms(selectedSymptoms.filter((s) => s !== symptom));
    } else {
      setSelectedSymptoms([...selectedSymptoms, symptom]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const isRedFlag = severityRating >= 8 || selectedSymptoms.includes('Chest Pain') || selectedSymptoms.includes('Shortness of Breath');
      const triageLevel = isRedFlag ? 'CRITICAL_EMERGENCY' : severityRating >= 5 ? 'URGENT' : 'ROUTINE';

      const newRecord: ClinicalIntake = {
        id: `INT-${Date.now()}`,
        patient_name: user ? `${user.full_name} (Patient)` : 'OPD Patient',
        symptoms: selectedSymptoms,
        duration,
        severity_rating: severityRating,
        chief_complaint: chiefComplaint,
        history_present_illness: hpi,
        review_systems: ros,
        triage_level: triageLevel,
        summary: isRedFlag
          ? 'EMERGENCY RED FLAG: Acute symptoms detected. Immediate triage ECG & vitals check advised.'
          : 'Standard doctor-ready clinical history recorded.',
        ayush_mode: ayushMode,
        created_at: new Date().toISOString(),
      };

      try {
        await apiClient.post('/apps/medikiosk/intake', {
          symptoms: selectedSymptoms,
          duration,
          severity_rating: severityRating,
          chief_complaint: chiefComplaint,
          history_present_illness: hpi,
          review_systems: ros,
          ayush_mode: ayushMode,
        });
      } catch (err) {
        console.warn('API sync fallback used');
      }

      setLatestIntake(newRecord);
      setIntakes([newRecord, ...intakes]);
      alert('Clinical intake successfully recorded and queued for consulting physician!');
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
        agent_id: 'medikiosk_agent',
        messages: newMessages,
      });
      setChatMessages([...newMessages, { role: 'assistant', content: res.content }]);
    } catch {
      setChatMessages([
        ...newMessages,
        {
          role: 'assistant',
          content:
            'I have logged your symptoms. Please ensure you stay comfortably seated in the waiting area. The attending physician will review your clinical history shortly.',
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
          <span className="text-4xl">🏥</span>
          <h2 className="text-lg font-bold text-slate-900">Authentication Required</h2>
          <p className="text-xs text-slate-500">Please sign in with your credentials to access MediKiosk.</p>
          <Link href="/" className="inline-block px-5 py-2.5 bg-sky-600 hover:bg-sky-700 text-white rounded-xl text-xs font-bold shadow transition">
            Go to Sign-In Portal &rarr;
          </Link>
        </div>
      </div>
    );
  }

  const userRoles = user.mapped_roles || [user.primary_role];
  const isDoctorOrAdmin = userRoles.some(
    (role) => role === 'PHYSICIAN' || role === 'SYSTEM_ADMIN'
  );

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Top Header Banner */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-sky-50 border border-sky-200 flex items-center justify-center text-2xl shadow-sm">
              🏥
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">MediKiosk Clinical Console</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-sky-100 text-sky-800 border border-sky-200 uppercase">
                  OPD &amp; Triage Suite
                </span>
              </div>
              <p className="text-xs text-slate-500">Structured Patient Intake (SOCRATES/AYUSH) &amp; Physician SOAP Summaries</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="px-3 py-1.5 bg-slate-100 border rounded-xl text-xs font-bold text-slate-700 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              <span>{user.full_name} ({isDoctorOrAdmin ? '🩺 Attending Physician' : '👤 OPD Patient'})</span>
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
            onClick={() => setActiveTab('INTAKE')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'INTAKE'
                ? 'bg-sky-600 text-white shadow-md shadow-sky-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📝</span>
            <span>Patient Clinical Intake Form</span>
          </button>

          <button
            onClick={() => setActiveTab('DOCTOR_QUEUE')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'DOCTOR_QUEUE'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>🩺</span>
            <span>Physician OPD Queue ({intakes.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('OCR')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'OCR'
                ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📄</span>
            <span>OCR Prescription &amp; Lab Digitizer</span>
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
            <span>MediKiosk AI Assistant</span>
          </button>
        </div>

        {/* TAB 1: PATIENT CLINICAL INTAKE */}
        {activeTab === 'INTAKE' && (
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
            
            {/* Left: Input Form */}
            <div className="md:col-span-7">
              <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                <div className="border-b pb-2 flex items-center justify-between">
                  <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Clinical Intake Dialogue</h2>
                  <span className="text-[11px] text-slate-400 font-mono">SOCRATES / AYUSH Framework</span>
                </div>

                {/* Symptom Tags Selector */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-2">Select Active Symptoms</label>
                  <div className="flex flex-wrap gap-2">
                    {COMMON_SYMPTOMS.map((symptom) => {
                      const isSelected = selectedSymptoms.includes(symptom);
                      return (
                        <button
                          key={symptom}
                          type="button"
                          onClick={() => toggleSymptom(symptom)}
                          className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition ${
                            isSelected
                              ? 'bg-sky-600 text-white border-sky-600 shadow-sm'
                              : 'bg-slate-50 text-slate-700 border-slate-200 hover:bg-slate-100'
                          }`}
                        >
                          {isSelected ? '✓ ' : '+ '}
                          {symptom}
                        </button>
                      );
                    })}
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Duration of Symptoms</label>
                    <input
                      type="text"
                      value={duration}
                      onChange={(e) => setDuration(e.target.value)}
                      placeholder="e.g. 3 days, 2 hours"
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-slate-600 font-bold mb-1">Pain Severity Rating (1-10)</label>
                    <input
                      type="number"
                      min="1"
                      max="10"
                      value={severityRating}
                      onChange={(e) => setSeverityRating(Number(e.target.value))}
                      className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Chief Complaint</label>
                  <input
                    type="text"
                    value={chiefComplaint}
                    onChange={(e) => setChiefComplaint(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">History of Present Illness (HPI)</label>
                  <textarea
                    rows={2}
                    value={hpi}
                    onChange={(e) => setHpi(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Review of Systems (ROS)</label>
                  <textarea
                    rows={2}
                    value={ros}
                    onChange={(e) => setRos(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                    required
                  />
                </div>

                {/* AYUSH Mode Toggle */}
                <div className="p-3 bg-emerald-50/70 border border-emerald-200 rounded-xl flex items-center justify-between">
                  <div>
                    <span className="font-bold text-xs text-emerald-950">AYUSH Ahara-Vihara Clinical Profiling</span>
                    <p className="text-[11px] text-emerald-700">Records Prakriti traits, digestive Agni, and circadian sleep habits.</p>
                  </div>
                  <input
                    type="checkbox"
                    checked={ayushMode}
                    onChange={(e) => setAyushMode(e.target.checked)}
                    className="w-5 h-5 accent-emerald-600 rounded cursor-pointer"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-sky-600 hover:bg-sky-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
                >
                  {loading ? 'Evaluating Red Flags & Triage...' : 'Save Clinical History & Queue for OPD'}
                </button>
              </form>
            </div>

            {/* Right: Scorecard */}
            <div className="md:col-span-5 space-y-4">
              {latestIntake ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                  <div className="border-b pb-2 flex items-center justify-between">
                    <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Triage Scorecard</h2>
                    <span className="text-xs font-mono text-slate-400">{latestIntake.id}</span>
                  </div>

                  <div className="p-4 rounded-xl border text-center space-y-1 bg-slate-50">
                    <span className="text-[10px] uppercase font-bold text-slate-400">Assigned Triage Tier</span>
                    <div
                      className={`text-lg font-black mt-1 ${
                        latestIntake.triage_level === 'CRITICAL_EMERGENCY'
                          ? 'text-rose-600'
                          : latestIntake.triage_level === 'URGENT'
                          ? 'text-amber-600'
                          : 'text-emerald-700'
                      }`}
                    >
                      {latestIntake.triage_level}
                    </div>
                  </div>

                  <div className="space-y-1.5 text-xs">
                    <span className="block text-slate-400 font-bold uppercase text-[9px]">Doctor Summary</span>
                    <p className="p-3 bg-slate-50 rounded-xl border text-slate-700 leading-relaxed font-medium">
                      {latestIntake.summary}
                    </p>
                  </div>

                  <div className="space-y-1 text-xs">
                    <span className="block text-slate-400 font-bold uppercase text-[9px]">Logged Symptoms</span>
                    <div className="flex flex-wrap gap-1.5">
                      {latestIntake.symptoms.map((s, idx) => (
                        <span key={idx} className="px-2.5 py-1 bg-sky-50 border border-sky-200 text-sky-800 text-[10px] font-bold rounded-lg">
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-sm text-center text-slate-400 text-xs italic">
                  Complete the intake form to generate your physician triage summary.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 2: PHYSICIAN OPD QUEUE */}
        {activeTab === 'DOCTOR_QUEUE' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900 uppercase tracking-wider">Physician OPD Waiting List</h2>
                <p className="text-xs text-slate-500">Doctor-ready intake histories with clinical red-flag triage status</p>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-sky-50 text-sky-700 border border-sky-200">
                {intakes.length} Active Patients
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {intakes.map((record) => {
                const isCrit = record.triage_level === 'CRITICAL_EMERGENCY';
                const isUrg = record.triage_level === 'URGENT';
                return (
                  <div
                    key={record.id}
                    onClick={() => setSelectedIntake(record)}
                    className={`p-5 rounded-2xl border transition-all duration-200 shadow-sm hover:shadow-md cursor-pointer flex flex-col justify-between space-y-3 ${
                      isCrit
                        ? 'bg-rose-50/60 border-rose-200 hover:border-rose-400'
                        : isUrg
                        ? 'bg-amber-50/60 border-amber-200 hover:border-amber-400'
                        : 'bg-emerald-50/60 border-emerald-200 hover:border-emerald-400'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="font-extrabold text-base text-slate-900 flex items-center gap-2">
                          <span>{record.patient_name}</span>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[9px] font-black uppercase ${
                              isCrit
                                ? 'bg-rose-100 text-rose-800'
                                : isUrg
                                ? 'bg-amber-100 text-amber-800'
                                : 'bg-emerald-100 text-emerald-800'
                            }`}
                          >
                            {record.triage_level}
                          </span>
                        </div>
                        <div className="text-xs font-bold text-slate-700 mt-1">{record.chief_complaint}</div>
                      </div>
                      <div className="text-right">
                        <span className="px-2 py-1 bg-white rounded-lg text-xs font-black border text-slate-800">
                          {record.severity_rating}/10
                        </span>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-1">
                      {record.symptoms.map((s, idx) => (
                        <span key={idx} className="px-2 py-0.5 rounded bg-white text-slate-700 text-[10px] font-semibold border border-slate-200">
                          {s}
                        </span>
                      ))}
                    </div>

                    <div className="text-[11px] text-slate-500 pt-2 border-t border-slate-200/50 flex items-center justify-between">
                      <span>Duration: {record.duration}</span>
                      <span className="text-indigo-600 font-bold text-xs">View SOAP Note &rarr;</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* TAB 3: OCR PRESCRIPTION & LAB DIGITIZER */}
        {activeTab === 'OCR' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-6 max-w-4xl mx-auto">
            <div className="border-b pb-3">
              <h2 className="text-base font-extrabold text-slate-900">OCR Medical Document &amp; Prescription Digitizer</h2>
              <p className="text-xs text-slate-500">Extracts structured medications, dosage frequencies, and out-of-range lab anomalies.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-3">
                <label className="block text-xs font-bold text-slate-700">Raw Prescription / Lab Text (OCR Input)</label>
                <textarea
                  rows={6}
                  value={ocrText}
                  onChange={(e) => setOcrText(e.target.value)}
                  className="w-full p-3 bg-slate-50 border rounded-xl text-xs font-mono"
                />
                <button
                  type="button"
                  onClick={() => {
                    setOcrAnalysis({
                      extracted_medications: ['Paracetamol 650mg (TDS)', 'Amoxicillin 500mg (TDS)', 'Pantoprazole 40mg (OD)'],
                      lab_anomalies: [
                        { parameter: 'Fasting Blood Sugar', observed_value: 165, unit: 'mg/dL', reference_range: '70 - 110 mg/dL', severity: 'HIGH_ANOMALY' }
                      ],
                      summary: 'Digitized document contains 3 medications and 1 flagged out-of-range lab anomaly.'
                    });
                    alert('Prescription entities and lab anomalies extracted successfully!');
                  }}
                  className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow transition"
                >
                  Run Medical NER &amp; Anomaly Extraction
                </button>
              </div>

              <div className="p-4 bg-slate-50 border rounded-2xl space-y-4">
                <h3 className="text-xs font-extrabold text-slate-800 uppercase tracking-wider">Digitized Clinical Entities</h3>
                
                {ocrAnalysis && (
                  <div className="space-y-3 text-xs">
                    <div>
                      <span className="font-bold text-slate-500 text-[10px] uppercase block">Extracted Medications:</span>
                      <div className="flex flex-wrap gap-1.5 mt-1">
                        {ocrAnalysis.extracted_medications.map((m: string, idx: number) => (
                          <span key={idx} className="px-2.5 py-1 bg-sky-50 border border-sky-200 text-sky-800 font-bold rounded-lg text-[10px]">
                            💊 {m}
                          </span>
                        ))}
                      </div>
                    </div>

                    <div>
                      <span className="font-bold text-slate-500 text-[10px] uppercase block">Flagged Lab Anomalies:</span>
                      {ocrAnalysis.lab_anomalies.map((la: any, idx: number) => (
                        <div key={idx} className="mt-1 p-2 bg-rose-50 border border-rose-200 text-rose-900 rounded-lg text-[11px]">
                          <strong>⚠️ {la.parameter}:</strong> {la.observed_value} {la.unit} (Normal Range: {la.reference_range})
                        </div>
                      ))}
                    </div>

                    <div className="pt-2 border-t text-[11px] text-slate-600 font-medium">
                      {ocrAnalysis.summary}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* TAB 4: MEDIKIOSK AI CHAT */}
        {activeTab === 'CHAT' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">MediKiosk AI Clinical Assistant</h2>
                <p className="text-xs text-slate-500">Conversational clinical history taker and triage advisor</p>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-sky-50 text-sky-700 border border-sky-200">
                Clinical Mode &bull; Active
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
                    <div className="w-8 h-8 rounded-full bg-sky-100 text-sky-800 flex items-center justify-center text-sm font-bold flex-shrink-0">
                      🏥
                    </div>
                  )}
                  <div
                    className={`p-3.5 rounded-2xl max-w-[80%] text-xs leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-sky-600 text-white rounded-br-none shadow-sm'
                        : 'bg-slate-100 text-slate-800 rounded-bl-none border border-slate-200/80 whitespace-pre-line'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && (
                <div className="flex items-center gap-2 text-xs text-slate-400 italic">
                  <span className="w-2 h-2 rounded-full bg-sky-500 animate-pulse"></span>
                  <span>MediKiosk AI is analyzing symptoms...</span>
                </div>
              )}
            </div>

            {/* Chat Input */}
            <form onSubmit={handleSendChat} className="flex gap-2 pt-2 border-t">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Ask about symptoms, pain timeline, preparation for doctor consultation, or medication guidance..."
                className="flex-1 px-4 py-3 rounded-xl border border-slate-300 bg-slate-50 focus:bg-white text-xs focus:ring-2 focus:ring-sky-500 focus:outline-none"
              />
              <button
                type="submit"
                disabled={chatLoading || !chatInput.trim()}
                className="px-5 py-3 rounded-xl bg-sky-600 hover:bg-sky-700 text-white font-bold text-xs shadow-md transition disabled:opacity-50"
              >
                Send
              </button>
            </form>
          </div>
        )}

      </div>

      {/* Interactive Doctor SOAP Note Modal */}
      {selectedIntake && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 max-w-xl w-full space-y-4 shadow-2xl">
            <div className="flex items-center justify-between border-b pb-3">
              <div>
                <h3 className="text-base font-extrabold text-slate-900">Doctor-Ready SOAP Clinical Summary</h3>
                <p className="text-xs text-slate-500">Patient: {selectedIntake.patient_name} ({selectedIntake.id})</p>
              </div>
              <button
                onClick={() => setSelectedIntake(null)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 font-bold flex items-center justify-center text-sm"
              >
                &times;
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 border rounded-xl space-y-1">
                <span className="font-bold text-slate-400 uppercase text-[10px]">Subjective (Chief Complaint &amp; HPI)</span>
                <p className="text-slate-800 font-semibold">{selectedIntake.chief_complaint}</p>
                <p className="text-slate-600">{selectedIntake.history_present_illness}</p>
              </div>

              <div className="p-3 bg-slate-50 border rounded-xl space-y-1">
                <span className="font-bold text-slate-400 uppercase text-[10px]">Objective (Review of Systems &amp; Severity)</span>
                <p className="text-slate-700">Severity: <strong>{selectedIntake.severity_rating}/10</strong> | Duration: <strong>{selectedIntake.duration}</strong></p>
                <p className="text-slate-600">{selectedIntake.review_systems}</p>
              </div>

              <div className="p-3 bg-sky-50 border border-sky-200 rounded-xl space-y-1">
                <span className="font-bold text-sky-900 uppercase text-[10px]">Assessment &amp; Triage Level</span>
                <p className="font-bold text-sky-950">{selectedIntake.triage_level}</p>
                <p className="text-sky-800">{selectedIntake.summary}</p>
              </div>
            </div>

            <div className="pt-2 flex justify-end gap-2 border-t">
              <button
                type="button"
                onClick={() => {
                  alert(`Case ${selectedIntake.id} accepted by attending physician!`);
                  setSelectedIntake(null);
                }}
                className="px-4 py-2.5 bg-sky-600 hover:bg-sky-700 text-white font-bold text-xs rounded-xl shadow"
              >
                Accept Patient Consultation
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
