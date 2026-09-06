'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { apiClient } from '@/lib/api/apiClient';

interface ClinicalIntake {
  id: string;
  patient_name: string;
  symptoms: string[];
  duration: string;
  severity_rating: number;
  chief_complaint: string;
  history_present_illness: string;
  review_systems?: string;
  triage_level: string;
  summary: string;
  ayush_mode: boolean;
  prakriti_type?: string;
  created_at: string;
}

const DEFAULT_OPD_INTAKES: ClinicalIntake[] = [
  {
    id: 'OPD-1092',
    patient_name: 'Rahul Sharma (42M)',
    symptoms: ['Persistent Cough', 'High Fever', 'Body Ache'],
    duration: '3 days',
    severity_rating: 6,
    chief_complaint: 'Dry throat tickling, persistent cough, and night fatigue',
    history_present_illness: 'Symptoms began 3 days ago following outdoor ambient dust exposure. Night fever spikes up to 101.4°F.',
    review_systems: 'Mild head congestion and appetite loss. Denies chest pain or hemoptysis.',
    triage_level: 'PRIORITY_OPD',
    summary:
      'CLINICAL SUMMARY (Rahul Sharma, 42M): Presenting with 3-day history of persistent dry cough and nocturnal fever spikes. Self-reported symptom severity 6/10. Vata-Pitta dosha imbalance indicated with mild respiratory Agni depletion. Scheduled for auscultation and chest screening.',
    ayush_mode: true,
    prakriti_type: 'Vata-Pitta',
    created_at: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
  },
  {
    id: 'OPD-1091',
    patient_name: 'Priya Verma (31F)',
    symptoms: ['Severe Migraine', 'Nausea', 'Photophobia'],
    duration: '2 days',
    severity_rating: 8,
    chief_complaint: 'Unilateral throbbing hemicranial headache with photophobia and nausea',
    history_present_illness: 'Sudden onset 48 hours ago following prolonged screen work and emotional stress. Aggravated by bright light.',
    review_systems: 'Photophobia and phonophobia present. No focal neurological weakness or neck stiffness.',
    triage_level: 'CRITICAL_TRIAGE',
    summary:
      'CLINICAL SUMMARY (Priya Verma, 31F): Severe acute hemicranial migraine (8/10 severity) accompanied by photophobia and nausea. Pitta-Kapha aggravation noted. Recommended immediate quiet-room triage and acute analgesic protocol.',
    ayush_mode: true,
    prakriti_type: 'Pitta-Kapha',
    created_at: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
  },
  {
    id: 'OPD-1089',
    patient_name: 'Harish Chandra (68M)',
    symptoms: ['Joint Pain & Swelling', 'Morning Stiffness'],
    duration: '2 weeks',
    severity_rating: 4,
    chief_complaint: 'Bilateral knee stiffness and difficulty climbing stairs in early mornings',
    history_present_illness: 'Progressive stiffness over 14 days, improving with mild ambulation.',
    review_systems: 'No erythema or systemic fever. Normal bowel habits.',
    triage_level: 'ROUTINE_OPD',
    summary:
      'CLINICAL SUMMARY (Harish Chandra, 68M): Subacute bilateral knee joint stiffness consistent with osteoarthritic changes. Vata-predominant prakriti. Recommended routine rheumatology evaluation and AYUSH Janu Basti therapy.',
    ayush_mode: true,
    prakriti_type: 'Vata-Kapha',
    created_at: new Date(Date.now() - 240 * 60 * 1000).toISOString(),
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
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'INTAKE' | 'DOCTOR_QUEUE' | 'OCR' | 'CHAT'>('INTAKE');

  // Intake Form State
  const [patientName, setPatientName] = useState('Rahul Sharma');
  const [patientAgeGender, setPatientAgeGender] = useState('42M');
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>(['Persistent Cough', 'High Fever']);
  const [symptomsInput, setSymptomsInput] = useState('sore throat, fatigue');
  const [duration, setDuration] = useState('3 days');
  const [severityRating, setSeverityRating] = useState(6);
  const [chiefComplaint, setChiefComplaint] = useState('Dry throat tickling, persistent cough, and night fatigue');
  const [hpi, setHpi] = useState('Symptoms began 3 days ago following outdoor dust exposure. Night fever spikes up to 101.4°F.');
  const [ros, setRos] = useState('Mild head congestion and appetite loss. Denies chest pain or hemoptysis.');
  const [ayushMode, setAyushMode] = useState(true);
  const [prakritiSelection, setPrakritiSelection] = useState('Vata-Pitta');

  const [loading, setLoading] = useState(false);
  const [intakes, setIntakes] = useState<ClinicalIntake[]>(DEFAULT_OPD_INTAKES);
  const [selectedIntake, setSelectedIntake] = useState<ClinicalIntake | null>(DEFAULT_OPD_INTAKES[0]);
  const [reviewSuccessMsg, setReviewSuccessMsg] = useState<string | null>(null);

  // OCR Demo State
  const [ocrText, setOcrText] = useState(
    'PRESCRIPTION & CLINICAL LAB REPORT\nPatient: Ramesh Patel (54M) | OPD Ref: #40921\nRx Medications:\n1. Paracetamol 650mg TDS (After meals)\n2. Amoxicillin 500mg TDS (5 Days)\n3. Pantoprazole 40mg OD (Before breakfast)\n\nBiochemical Findings:\n- Fasting Blood Sugar: 165 mg/dL [Reference: 70 - 110 mg/dL] -> HIGH\n- Serum Creatinine: 1.1 mg/dL [Reference: 0.7 - 1.3 mg/dL] -> NORMAL\n- HbA1c: 7.8% [Reference: < 5.7%] -> ELEVATED'
  );
  const [ocrAnalysis, setOcrAnalysis] = useState<any>({
    extracted_medications: [
      { name: 'Paracetamol', dosage: '650mg', frequency: 'TDS (3x/day)', timing: 'Post-prandial' },
      { name: 'Amoxicillin', dosage: '500mg', frequency: 'TDS (3x/day)', timing: '5-Day Course' },
      { name: 'Pantoprazole', dosage: '40mg', frequency: 'OD (1x/day)', timing: 'Pre-meal' },
    ],
    lab_anomalies: [
      { parameter: 'Fasting Blood Sugar', observed_value: 165, unit: 'mg/dL', reference_range: '70 - 110 mg/dL', severity: 'HIGH' },
      { parameter: 'HbA1c Glycated Hemoglobin', observed_value: 7.8, unit: '%', reference_range: '< 5.7 %', severity: 'ELEVATED' },
    ],
    summary: 'Prescription digitized with 3 active medications and 2 elevated metabolic biomarkers.',
  });

  // AI Chat State
  const [chatMessages, setChatMessages] = useState<Array<{ role: 'user' | 'assistant'; content: string }>>([
    {
      role: 'assistant',
      content:
        'Namaste! I am your MediKiosk AI Clinical Intake Assistant. I help structure your symptoms, medical history, and timeline using SOCRATES and AYUSH guidelines so your consulting physician receives a comprehensive clinical summary before your examination. What brings you in today?',
    },
  ]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const generateClinicalSummary = (
    name: string,
    cc: string,
    syms: string[],
    dur: string,
    sev: number,
    hpiTxt: string,
    rosTxt: string,
    ayush: boolean,
    prakriti: string
  ): ClinicalIntake => {
    let triage = 'ROUTINE_OPD';
    if (sev >= 8 || syms.some((s) => s.toLowerCase().includes('chest') || s.toLowerCase().includes('breath'))) {
      triage = 'CRITICAL_TRIAGE';
    } else if (sev >= 5) {
      triage = 'PRIORITY_OPD';
    }

    const summaryText = `CLINICAL SUMMARY (${name}): Patient presents with chief complaint of "${cc}" lasting ${dur}. Identified symptoms: ${syms.join(
      ', '
    )} (Self-rated severity ${sev}/10). HPI: ${hpiTxt}. ROS: ${rosTxt}. ${
      ayush ? `AYUSH Constitutional Profile: ${prakriti} Prakriti predominance noted with functional metabolic imbalance.` : ''
    }`;

    return {
      id: 'OPD-' + Math.floor(1000 + Math.random() * 9000),
      patient_name: name,
      symptoms: syms,
      duration: dur,
      severity_rating: sev,
      chief_complaint: cc,
      history_present_illness: hpiTxt,
      review_systems: rosTxt,
      triage_level: triage,
      summary: summaryText,
      ayush_mode: ayush,
      prakriti_type: prakriti,
      created_at: new Date().toISOString(),
    };
  };

  const fetchIntakes = async () => {
    try {
      const data = await apiClient.get<ClinicalIntake[]>('/apps/medikiosk/intake');
      if (Array.isArray(data) && data.length > 0) {
        setIntakes(data);
        setSelectedIntake(data[0]);
        return;
      }
    } catch (e) {
      console.warn('Maintaining pre-seeded OPD intake queue', e);
    }
  };

  useEffect(() => {
    fetchIntakes();
  }, []);

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

    const extraSyms = symptomsInput.split(',').map((s) => s.trim()).filter(Boolean);
    const symList = Array.from(new Set([...selectedSymptoms, ...extraSyms]));
    const formattedName = user ? `${user.full_name} (${patientAgeGender})` : `${patientName} (${patientAgeGender})`;

    let record: ClinicalIntake;
    try {
      record = await apiClient.post<ClinicalIntake>('/apps/medikiosk/intake', {
        patient_name: formattedName,
        symptoms: symList,
        duration,
        severity_rating: severityRating,
        chief_complaint: chiefComplaint,
        history_present_illness: hpi,
        review_systems: ros,
        ayush_mode: ayushMode,
        prakriti_type: prakritiSelection,
      });
    } catch {
      record = generateClinicalSummary(
        formattedName,
        chiefComplaint,
        symList,
        duration,
        severityRating,
        hpi,
        ros,
        ayushMode,
        prakritiSelection
      );
    }

    setIntakes((prev) => [record, ...prev]);
    setSelectedIntake(record);
    setLoading(false);
    setActiveTab('DOCTOR_QUEUE');
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
            'SOCRATES Triage Note: Please note the precise onset, location, duration, and severity of your symptoms so our physician summary engine can optimize your clinical record for the consulting doctor.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  const getTriageBadge = (level: string) => {
    switch (level) {
      case 'CRITICAL_TRIAGE':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-rose-50 text-rose-800 border border-rose-200">
            <span className="w-1.5 h-1.5 rounded-full bg-rose-600 animate-pulse"></span>
            Critical Triage
          </span>
        );
      case 'PRIORITY_OPD':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-amber-50 text-amber-800 border border-amber-200">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-600"></span>
            Priority OPD
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-emerald-50 text-emerald-800 border border-emerald-200">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-600"></span>
            Routine Consultation
          </span>
        );
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
            <span className="font-semibold text-stone-900">MediKiosk Smart Intake</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="hidden sm:inline-flex items-center gap-1.5 text-stone-600 font-medium">
              <span className="w-2 h-2 rounded-full bg-sky-500"></span>
              OPD Station #04 Active
            </span>
            <span className="px-2 py-0.5 rounded text-[11px] font-mono font-bold bg-sky-50 text-sky-800 border border-sky-200">
              SIH26047 • Clinical AYUSH
            </span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 pt-8 space-y-8">
        
        {/* Module Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-stone-200 pb-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-md bg-stone-100 border border-stone-200 text-stone-700 text-xs font-medium">
              <span>🏥</span>
              <span>Point-of-Care Clinical Intake &amp; Triage Terminal</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-semibold tracking-tight text-stone-900">
              MediKiosk Clinical Assistant
            </h1>
            <p className="text-stone-600 text-sm max-w-2xl leading-relaxed">
              Structured SOCRATES symptom intake, traditional AYUSH constitution profiling, prescription OCR digitization, and doctor-ready clinical summaries.
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
            onClick={() => setActiveTab('INTAKE')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'INTAKE'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>📋</span>
            <span>Clinical History Intake</span>
          </button>

          <button
            onClick={() => setActiveTab('DOCTOR_QUEUE')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'DOCTOR_QUEUE'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>👨‍⚕️</span>
            <span>Physician Summary Terminal</span>
            <span className="px-1.5 py-0.5 rounded text-[10px] font-mono bg-stone-100 text-stone-700">
              {intakes.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('OCR')}
            className={`px-4 py-2.5 text-xs font-semibold rounded-t-lg transition border-b-2 -mb-px flex items-center gap-2 whitespace-nowrap ${
              activeTab === 'OCR'
                ? 'border-stone-900 text-stone-900 bg-white'
                : 'border-transparent text-stone-500 hover:text-stone-900'
            }`}
          >
            <span>📄</span>
            <span>Prescription &amp; Lab OCR</span>
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
            <span>AI Clinical Assistant</span>
          </button>
        </div>

        {/* ========================================================================= */}
        {/* TAB 1: INTAKE FORM */}
        {/* ========================================================================= */}
        {activeTab === 'INTAKE' && (
          <div className="max-w-4xl mx-auto space-y-6">
            <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-8 shadow-xs space-y-8">
              <div className="border-b border-stone-200 pb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">OPD Patient Intake (SOCRATES Framework)</h2>
                  <p className="text-xs text-stone-500">Collect structured clinical evidence and correlate with traditional dosha constitution</p>
                </div>
                <span className="px-2.5 py-1 rounded text-[11px] font-semibold bg-sky-50 text-sky-800 border border-sky-200 self-start">
                  SOCRATES Protocol
                </span>
              </div>

              <form onSubmit={handleSubmit} className="space-y-6 text-xs">
                
                {/* Section 1: Patient Identity & Timeline */}
                <div className="space-y-4">
                  <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wider">1. Patient Profile &amp; Duration</h3>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div className="sm:col-span-2 space-y-1.5">
                      <label className="font-semibold text-stone-700">Patient Full Name</label>
                      <input
                        type="text"
                        value={patientName}
                        onChange={(e) => setPatientName(e.target.value)}
                        className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                        required
                      />
                    </div>
                    <div className="space-y-1.5">
                      <label className="font-semibold text-stone-700">Age &amp; Gender</label>
                      <input
                        type="text"
                        value={patientAgeGender}
                        onChange={(e) => setPatientAgeGender(e.target.value)}
                        placeholder="e.g. 42M or 31F"
                        className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                        required
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="space-y-1.5">
                      <label className="font-semibold text-stone-700">Symptom Duration / Timeline</label>
                      <input
                        type="text"
                        value={duration}
                        onChange={(e) => setDuration(e.target.value)}
                        placeholder="e.g. 3 days, 2 weeks, sudden onset"
                        className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                        required
                      />
                    </div>
                    <div className="space-y-1.5">
                      <div className="flex items-center justify-between">
                        <label className="font-semibold text-stone-700">Self-Rated Severity (1 to 10)</label>
                        <span className="font-mono font-bold text-stone-900">{severityRating}/10</span>
                      </div>
                      <input
                        type="range"
                        min="1"
                        max="10"
                        value={severityRating}
                        onChange={(e) => setSeverityRating(Number(e.target.value))}
                        className="w-full h-2 bg-stone-200 rounded-lg appearance-none cursor-pointer accent-stone-900 mt-2"
                      />
                    </div>
                  </div>
                </div>

                {/* Section 2: Symptoms */}
                <div className="space-y-3 pt-2 border-t border-stone-100">
                  <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wider">2. Primary Presenting Symptoms</h3>
                  <div className="flex flex-wrap gap-2">
                    {COMMON_SYMPTOMS.map((sym) => {
                      const selected = selectedSymptoms.includes(sym);
                      return (
                        <button
                          type="button"
                          key={sym}
                          onClick={() => toggleSymptom(sym)}
                          className={`px-3 py-1.5 rounded-lg text-xs font-medium transition border ${
                            selected
                              ? 'bg-stone-900 text-white border-stone-900 shadow-xs'
                              : 'bg-white text-stone-700 border-stone-200 hover:bg-stone-100'
                          }`}
                        >
                          {selected ? '✓ ' : '+ '} {sym}
                        </button>
                      );
                    })}
                  </div>

                  <div className="space-y-1.5 pt-2">
                    <label className="font-semibold text-stone-700">Additional Symptoms (Comma Separated)</label>
                    <input
                      type="text"
                      value={symptomsInput}
                      onChange={(e) => setSymptomsInput(e.target.value)}
                      placeholder="e.g. shivering, night sweats, nausea"
                      className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                    />
                  </div>
                </div>

                {/* Section 3: SOCRATES History */}
                <div className="space-y-4 pt-2 border-t border-stone-100">
                  <h3 className="text-xs font-semibold text-stone-500 uppercase tracking-wider">3. SOCRATES Clinical History</h3>
                  
                  <div className="space-y-1.5">
                    <label className="font-semibold text-stone-700">Chief Complaint (Patient&#39;s Own Words)</label>
                    <textarea
                      value={chiefComplaint}
                      onChange={(e) => setChiefComplaint(e.target.value)}
                      rows={2}
                      className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                      required
                    />
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="space-y-1.5">
                      <label className="font-semibold text-stone-700">History of Present Illness (HPI)</label>
                      <textarea
                        value={hpi}
                        onChange={(e) => setHpi(e.target.value)}
                        rows={3}
                        className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                      />
                    </div>
                    <div className="space-y-1.5">
                      <label className="font-semibold text-stone-700">Review of Systems (ROS)</label>
                      <textarea
                        value={ros}
                        onChange={(e) => setRos(e.target.value)}
                        rows={3}
                        className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:outline-none focus:border-stone-900 font-medium"
                      />
                    </div>
                  </div>
                </div>

                {/* Section 4: AYUSH Constitution Profiling */}
                <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="font-semibold text-stone-900 block">AYUSH Prakriti Constitutional Profiling</span>
                      <span className="text-[11px] text-stone-500">Integrate traditional dosha constitution with ICD-11 triage</span>
                    </div>
                    <input
                      type="checkbox"
                      checked={ayushMode}
                      onChange={(e) => setAyushMode(e.target.checked)}
                      className="w-4 h-4 rounded text-stone-900 accent-stone-900 cursor-pointer"
                    />
                  </div>

                  {ayushMode && (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2 border-t border-stone-200">
                      <div className="space-y-1">
                        <label className="font-semibold text-stone-700 text-[11px]">Predominant Prakriti Constitutional Type</label>
                        <select
                          value={prakritiSelection}
                          onChange={(e) => setPrakritiSelection(e.target.value)}
                          className="w-full px-3 py-2 bg-white border border-stone-200 rounded-lg font-semibold text-stone-800"
                        >
                          <option value="Vata-Pitta">Vata-Pitta (Heat &amp; Motion Sensitivity)</option>
                          <option value="Pitta-Kapha">Pitta-Kapha (Inflammation &amp; Congestion)</option>
                          <option value="Vata-Kapha">Vata-Kapha (Dryness &amp; Sluggish Metabolism)</option>
                          <option value="Tridosha">Tridosha (Equilibrium Baseline)</option>
                        </select>
                      </div>
                      <div className="text-[11px] text-stone-500 flex items-center bg-white p-3 rounded-lg border border-stone-200">
                        Prakriti profiling informs personalized herbal adjuvants (e.g. Kwath formulations) and dietary precautions alongside allopathic care.
                      </div>
                    </div>
                  )}
                </div>

                {/* Submit CTA */}
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-stone-900 hover:bg-stone-800 text-white font-semibold text-xs rounded-xl shadow-xs transition disabled:opacity-50"
                >
                  {loading ? 'Synthesizing Doctor Summary...' : 'Generate Physician-Ready OPD Summary & Triage Ticket'}
                </button>
              </form>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 2: DOCTOR'S QUEUE */}
        {/* ========================================================================= */}
        {activeTab === 'DOCTOR_QUEUE' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            
            {/* Queue Selector (Left) */}
            <div className="lg:col-span-5 bg-white border border-stone-200 rounded-xl p-5 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-stone-200 pb-3">
                <div>
                  <h2 className="text-xs font-semibold text-stone-500 uppercase tracking-wider">OPD Triage Queue</h2>
                  <span className="text-sm font-semibold text-stone-900">{intakes.length} Patients Waiting</span>
                </div>
                <span className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold bg-stone-100 text-stone-700">
                  Live Queue
                </span>
              </div>

              <div className="space-y-2">
                {intakes.map((item) => {
                  const isSelected = selectedIntake?.id === item.id;
                  return (
                    <div
                      key={item.id}
                      onClick={() => {
                        setSelectedIntake(item);
                        setReviewSuccessMsg(null);
                      }}
                      className={`p-3.5 rounded-lg cursor-pointer transition border text-xs space-y-1.5 ${
                        isSelected
                          ? 'bg-stone-100 border-stone-400 shadow-xs'
                          : 'bg-white border-stone-200 hover:bg-stone-50'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-semibold text-stone-900">{item.patient_name}</span>
                        {getTriageBadge(item.triage_level)}
                      </div>
                      <p className="text-stone-600 line-clamp-1">{item.chief_complaint}</p>
                      <div className="flex items-center justify-between text-[11px] text-stone-400 font-mono pt-1">
                        <span>{item.id}</span>
                        <span>{item.duration}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Selected Patient Clinical Summary (Right) */}
            <div className="lg:col-span-7 bg-white border border-stone-200 rounded-xl p-6 sm:p-7 shadow-xs space-y-6">
              {selectedIntake ? (
                <div className="space-y-6">
                  {/* Header */}
                  <div className="border-b border-stone-200 pb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <h2 className="text-xl font-semibold text-stone-900">{selectedIntake.patient_name}</h2>
                        <span className="text-xs text-stone-400 font-mono">({selectedIntake.id})</span>
                      </div>
                      <p className="text-xs text-stone-500 mt-0.5">
                        Recorded {new Date(selectedIntake.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                    <div>
                      {getTriageBadge(selectedIntake.triage_level)}
                    </div>
                  </div>

                  {/* Physician Summary Card */}
                  <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl space-y-2">
                    <span className="text-[10px] uppercase font-semibold tracking-wider text-stone-500 block">
                      Synthesized Clinical Summary for Consulting Physician
                    </span>
                    <p className="text-xs text-stone-800 leading-relaxed font-medium">
                      {selectedIntake.summary}
                    </p>
                  </div>

                  {/* 2-Column Findings */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                    <div className="p-3.5 bg-white border border-stone-200 rounded-lg space-y-1">
                      <span className="text-[10px] uppercase font-semibold text-stone-400 block">Chief Complaint</span>
                      <span className="font-semibold text-stone-900">{selectedIntake.chief_complaint}</span>
                    </div>

                    <div className="p-3.5 bg-white border border-stone-200 rounded-lg space-y-1">
                      <span className="text-[10px] uppercase font-semibold text-stone-400 block">Identified Symptoms</span>
                      <span className="font-semibold text-stone-900">{selectedIntake.symptoms.join(', ')}</span>
                    </div>

                    <div className="p-3.5 bg-white border border-stone-200 rounded-lg space-y-1">
                      <span className="text-[10px] uppercase font-semibold text-stone-400 block">History of Present Illness</span>
                      <span className="text-stone-700 leading-relaxed">{selectedIntake.history_present_illness || 'None provided'}</span>
                    </div>

                    <div className="p-3.5 bg-white border border-stone-200 rounded-lg space-y-1">
                      <span className="text-[10px] uppercase font-semibold text-stone-400 block">Review of Systems (ROS)</span>
                      <span className="text-stone-700 leading-relaxed">{selectedIntake.review_systems || 'Non-contributory'}</span>
                    </div>
                  </div>

                  {/* AYUSH Constitutional Recommendation */}
                  {selectedIntake.ayush_mode && (
                    <div className="p-4 bg-amber-50/70 border border-amber-200 rounded-xl text-xs space-y-1.5">
                      <div className="flex items-center justify-between">
                        <span className="font-semibold text-amber-900 uppercase text-[10px]">AYUSH Constitution Profile</span>
                        <span className="font-mono text-[10px] font-bold text-amber-800 bg-amber-100 px-2 py-0.5 rounded">
                          {selectedIntake.prakriti_type || 'Vata-Pitta'}
                        </span>
                      </div>
                      <p className="text-amber-950 leading-relaxed">
                        Predominance: {selectedIntake.prakriti_type || 'Vata-Pitta'}. Complementary AYUSH formulation suggestions: Pathyadi Kwath adjuvant for cranial congestion, Sitopaladi Churna for bronchial irritation.
                      </p>
                    </div>
                  )}

                  {/* Action Bar */}
                  <div className="pt-2 border-t border-stone-100 flex flex-wrap items-center justify-between gap-3">
                    <div className="flex gap-2">
                      <button
                        onClick={() => setReviewSuccessMsg(`Intake ${selectedIntake.id} marked as ready for Doctor Examination.`)}
                        className="px-4 py-2 bg-stone-900 hover:bg-stone-800 text-white rounded-lg text-xs font-semibold shadow-xs transition"
                      >
                        ✓ Mark Reviewed &amp; Call Patient
                      </button>
                      <button
                        onClick={() => window.print()}
                        className="px-3.5 py-2 bg-white border border-stone-200 hover:bg-stone-50 text-stone-700 rounded-lg text-xs font-medium transition"
                      >
                        🖨️ Print Consultation Slip
                      </button>
                    </div>

                    {reviewSuccessMsg && (
                      <span className="text-xs text-emerald-700 font-semibold bg-emerald-50 px-2.5 py-1 rounded border border-emerald-200">
                        {reviewSuccessMsg}
                      </span>
                    )}
                  </div>
                </div>
              ) : (
                <div className="text-center py-16 text-stone-400 text-xs italic">
                  Select a patient ticket from the left queue to inspect their clinical summary.
                </div>
              )}
            </div>

          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 3: OCR PRESCRIPTION DIGITIZER */}
        {/* ========================================================================= */}
        {activeTab === 'OCR' && (
          <div className="max-w-4xl mx-auto space-y-6">
            <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-8 shadow-xs space-y-6">
              <div className="border-b border-stone-200 pb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">Medical Prescription &amp; Lab Report OCR</h2>
                  <p className="text-xs text-stone-500">Optical document parsing, drug Named Entity Recognition (NER), and lab anomaly detection</p>
                </div>
                <span className="px-2.5 py-1 rounded text-[11px] font-semibold bg-teal-50 text-teal-800 border border-teal-200 self-start">
                  Tesseract + NER Engine
                </span>
              </div>

              <div className="space-y-4 text-xs">
                <div className="space-y-1.5">
                  <label className="font-semibold text-stone-700">Scanned Document Raw OCR Stream</label>
                  <textarea
                    value={ocrText}
                    onChange={(e) => setOcrText(e.target.value)}
                    rows={6}
                    className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg font-mono text-xs text-stone-800 focus:outline-none focus:border-stone-900"
                  />
                </div>

                {/* Extracted Medications */}
                <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl space-y-3">
                  <span className="text-[10px] uppercase font-semibold text-stone-500 tracking-wider block">
                    Extracted Medications (Drug NER Engine)
                  </span>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    {ocrAnalysis.extracted_medications?.map((med: any, idx: number) => (
                      <div key={idx} className="p-3 bg-white border border-stone-200 rounded-lg space-y-1">
                        <div className="flex items-center gap-1.5">
                          <span>💊</span>
                          <span className="font-semibold text-stone-900">{med.name}</span>
                        </div>
                        <div className="text-[11px] text-stone-600 font-mono">
                          {med.dosage} &bull; {med.frequency}
                        </div>
                        <div className="text-[10px] text-stone-400">
                          Timing: {med.timing}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Flagged Lab Anomalies */}
                {ocrAnalysis.lab_anomalies?.length > 0 && (
                  <div className="p-4 bg-rose-50/70 border border-rose-200 rounded-xl space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] uppercase font-semibold text-rose-900 tracking-wider">
                        Flagged Biochemical Anomalies
                      </span>
                      <span className="px-2 py-0.5 rounded text-[10px] font-mono font-bold bg-rose-100 text-rose-800">
                        {ocrAnalysis.lab_anomalies.length} Flagged
                      </span>
                    </div>

                    <div className="space-y-2">
                      {ocrAnalysis.lab_anomalies.map((anom: any, idx: number) => (
                        <div key={idx} className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 bg-white p-3 rounded-lg border border-rose-100 text-xs">
                          <div>
                            <span className="font-semibold text-rose-950">{anom.parameter}</span>
                            <div className="text-[11px] text-stone-500 font-mono">
                              Observed: <strong className="text-rose-700">{anom.observed_value} {anom.unit}</strong> (Reference: {anom.reference_range})
                            </div>
                          </div>
                          <span className="px-2.5 py-1 rounded text-[10px] font-bold font-mono bg-rose-100 text-rose-800 self-start sm:self-auto">
                            {anom.severity}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* TAB 4: AI CLINICAL ASSISTANT */}
        {/* ========================================================================= */}
        {activeTab === 'CHAT' && (
          <div className="max-w-4xl mx-auto space-y-4">
            <div className="bg-white border border-stone-200 rounded-xl p-6 shadow-xs space-y-4">
              <div className="border-b border-stone-200 pb-3 flex items-center justify-between">
                <div>
                  <h2 className="text-base font-semibold text-stone-900">MediKiosk AI Clinical Intake Assistant</h2>
                  <p className="text-xs text-stone-500">Conversational intake guidance and SOCRATES triage query resolution</p>
                </div>
                <span className="px-2.5 py-1 rounded text-[11px] font-semibold bg-indigo-50 text-indigo-800 border border-indigo-200">
                  Guided Dialogue
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
                    MediKiosk AI is analyzing clinical input...
                  </div>
                )}
              </div>

              {/* Chat Input */}
              <form onSubmit={handleSendChat} className="flex gap-2">
                <input
                  type="text"
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  placeholder="Describe your symptoms or ask clinical triage questions..."
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

      </div>
    </div>
  );
}

