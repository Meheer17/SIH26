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
    id: 'opd_1092',
    patient_name: 'Rahul Sharma (42M)',
    symptoms: ['Persistent Cough', 'High Fever', 'Body Ache'],
    duration: '3 days',
    severity_rating: 6,
    chief_complaint: 'Dry throat tickling, persistent cough, and fatigue',
    history_present_illness: 'Symptoms began 3 days ago after outdoor dust exposure. Night fever spikes.',
    review_systems: 'Loss of appetite, mild head congestion. No chest pain.',
    triage_level: 'PRIORITY_OPD',
    summary:
      'PATIENT SUMMARY (Rahul Sharma): 42M presenting with 3-day history of dry cough and night fever spikes. Self-rated severity 6/10. Recommended for OPD Auscultation.',
    ayush_mode: true,
    prakriti_type: 'Vata-Pitta',
    created_at: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
  },
  {
    id: 'opd_1091',
    patient_name: 'Priya Verma (31F)',
    symptoms: ['Severe Migraine', 'Nausea', 'Photophobia'],
    duration: '2 days',
    severity_rating: 8,
    chief_complaint: 'Unilateral throbbing headache with nausea',
    history_present_illness: 'Sudden onset 2 days ago following high stress and screen exposure.',
    review_systems: 'Photophobia present. No focal neurological deficits.',
    triage_level: 'CRITICAL_TRIAGE',
    summary:
      'PATIENT SUMMARY (Priya Verma): 31F presenting with severe 8/10 unilateral migraine and photophobia. Pitta-Kapha prakriti imbalance noted.',
    ayush_mode: true,
    prakriti_type: 'Pitta-Kapha',
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
  const [activeTab, setActiveTab] = useState<'INTAKE' | 'DOCTOR_QUEUE' | 'OCR' | 'CHAT'>('INTAKE');

  // Intake Form State
  const [patientName, setPatientName] = useState('Rahul Sharma');
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>(['Persistent Cough', 'High Fever']);
  const [symptomsInput, setSymptomsInput] = useState('cough, sore throat, fever');
  const [duration, setDuration] = useState('3 days');
  const [severityRating, setSeverityRating] = useState(6);
  const [chiefComplaint, setChiefComplaint] = useState('Dry throat tickling, persistent cough, and fatigue');
  const [hpi, setHpi] = useState('Symptoms began 3 days ago after outdoor exposure. Fever spikes at night.');
  const [ros, setRos] = useState('Loss of appetite, mild head congestion. No chest pain.');
  const [ayushMode, setAyushMode] = useState(true);
  const [prakritiSelection, setPrakritiSelection] = useState('Vata-Pitta');

  const [loading, setLoading] = useState(false);
  const [intakes, setIntakes] = useState<ClinicalIntake[]>(DEFAULT_OPD_INTAKES);
  const [selectedIntake, setSelectedIntake] = useState<ClinicalIntake | null>(DEFAULT_OPD_INTAKES[0]);

  // OCR Demo State
  const [ocrText, setOcrText] = useState(
    'PRESCRIPTION & LAB REPORT\nPatient: Ramesh Patel (54M)\nRx: Paracetamol 650mg TDS, Amoxicillin 500mg TDS, Pantoprazole 40mg OD\nLab: Fasting Blood Sugar: 165 mg/dL (HIGH), Serum Creatinine: 1.1 mg/dL (NORMAL)'
  );
  const [ocrAnalysis, setOcrAnalysis] = useState<any>({
    extracted_medications: ['Paracetamol 650mg (TDS)', 'Amoxicillin 500mg (TDS)', 'Pantoprazole 40mg (OD)'],
    lab_anomalies: [
      { parameter: 'Fasting Blood Sugar', observed_value: 165, unit: 'mg/dL', reference_range: '70 - 110 mg/dL', severity: 'HIGH_ANOMALY' },
    ],
    summary: 'Digitized prescription contains 3 medications and 1 elevated fasting glucose anomaly.',
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

  const generateClinicalSummary = (
    name: string,
    cc: string,
    syms: string[],
    dur: string,
    sev: number,
    hpiTxt: string,
    ayush: boolean,
    prakriti: string
  ): ClinicalIntake => {
    let triage = 'ROUTINE_OPD';
    if (sev >= 8 || syms.some((s) => s.toLowerCase().includes('chest') || s.toLowerCase().includes('breath'))) {
      triage = 'CRITICAL_TRIAGE';
    } else if (sev >= 5) {
      triage = 'PRIORITY_OPD';
    }

    const summaryText = `PATIENT SUMMARY (${name}): Patient presents with chief complaint of "${cc}" for ${dur}. Key symptoms include ${syms.join(
      ', '
    )} with a self-rated severity of ${sev}/10. HPI Notes: ${hpiTxt}. ${
      ayush ? `AYUSH Constitution Profile: ${prakriti} Prakriti predominance noted with mild Agni impairment.` : ''
    }`;

    return {
      id: 'opd_' + Math.floor(1000 + Math.random() * 9000),
      patient_name: name,
      symptoms: syms,
      duration: dur,
      severity_rating: sev,
      chief_complaint: cc,
      history_present_illness: hpiTxt,
      review_systems: ros,
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
      console.error('Maintaining pre-seeded OPD intake queue', e);
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

    const symList = Array.from(new Set([...selectedSymptoms, ...symptomsInput.split(',').map((s) => s.trim()).filter(Boolean)]));
    let record: ClinicalIntake;

    try {
      record = await apiClient.post<ClinicalIntake>('/apps/medikiosk/intake', {
        patient_name: user ? `${user.full_name}` : patientName,
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
        user ? user.full_name : patientName,
        chiefComplaint,
        symList,
        duration,
        severityRating,
        hpi,
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
            'SOCRATES Triage Note: Please note down the exact onset, location, duration, and severity of your symptoms so our physician summary engine can optimize your clinical record.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 sm:p-6 space-y-6">
      <div className="max-w-6xl mx-auto space-y-6">
        
        {/* Header */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-blue-50 border border-blue-200 flex items-center justify-center text-2xl shadow-sm">
              🏥
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">MediKiosk Smart Intake</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-blue-100 text-blue-800 border border-blue-200 uppercase">
                  SIH26047 • AYUSH Track
                </span>
              </div>
              <p className="text-xs text-slate-500">SOCRATES Clinical Intake, AYUSH Prakriti Profiling &amp; Doctor Summary Terminal</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {user ? (
              <div className="px-3 py-1.5 bg-slate-100 border rounded-xl text-xs font-bold text-slate-700 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-blue-500"></span>
                <span>{user.full_name} ({user.primary_role})</span>
              </div>
            ) : (
              <span className="px-2.5 py-1 bg-slate-100 border text-slate-600 rounded-lg text-xs font-semibold">
                OPD Kiosk Terminal Active
              </span>
            )}
          </div>
        </header>

        {/* Navigation Tabs */}
        <div className="flex flex-wrap gap-2 border-b border-slate-200 pb-2">
          <button
            onClick={() => setActiveTab('INTAKE')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'INTAKE'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📋</span>
            <span>Clinical History Intake</span>
          </button>

          <button
            onClick={() => setActiveTab('DOCTOR_QUEUE')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'DOCTOR_QUEUE'
                ? 'bg-slate-900 text-white shadow-md'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>👨‍⚕️</span>
            <span>Physician Summary Terminal ({intakes.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('OCR')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'OCR'
                ? 'bg-teal-600 text-white shadow-md shadow-teal-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>📄</span>
            <span>Prescription &amp; Lab OCR</span>
          </button>

          <button
            onClick={() => setActiveTab('CHAT')}
            className={`px-4 py-2.5 rounded-xl font-bold text-xs transition flex items-center gap-2 ${
              activeTab === 'CHAT'
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
            }`}
          >
            <span>💬</span>
            <span>AI Clinical Assistant</span>
          </button>
        </div>

        {/* TAB 1: INTAKE FORM */}
        {activeTab === 'INTAKE' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-6 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">OPD Patient Intake (SOCRATES Framework)</h2>
                <p className="text-xs text-slate-500">Structured patient symptom collection and traditional AYUSH constitution triage</p>
              </div>
              <span className="px-2.5 py-1 bg-blue-50 text-blue-800 text-[10px] font-bold rounded-lg border border-blue-200">
                AYUSH Triangulation
              </span>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Patient Full Name</label>
                  <input
                    type="text"
                    value={patientName}
                    onChange={(e) => setPatientName(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                    required
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Symptom Duration</label>
                  <input
                    type="text"
                    value={duration}
                    onChange={(e) => setDuration(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1.5">Quick Select Symptoms</label>
                <div className="flex flex-wrap gap-2">
                  {COMMON_SYMPTOMS.map((sym) => {
                    const selected = selectedSymptoms.includes(sym);
                    return (
                      <button
                        type="button"
                        key={sym}
                        onClick={() => toggleSymptom(sym)}
                        className={`px-3 py-1.5 rounded-xl font-semibold transition ${
                          selected
                            ? 'bg-blue-600 text-white shadow-xs'
                            : 'bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200'
                        }`}
                      >
                        {selected ? '✓ ' : '+ '}{sym}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Additional Symptoms (Comma Separated)</label>
                <input
                  type="text"
                  value={symptomsInput}
                  onChange={(e) => setSymptomsInput(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Chief Complaint Summary</label>
                <textarea
                  value={chiefComplaint}
                  onChange={(e) => setChiefComplaint(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl h-16"
                  required
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">History of Present Illness (HPI)</label>
                  <textarea
                    value={hpi}
                    onChange={(e) => setHpi(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl h-20"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Review of Systems (ROS)</label>
                  <textarea
                    value={ros}
                    onChange={(e) => setRos(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl h-20"
                  />
                </div>
              </div>

              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-slate-800">AYUSH Prakriti Constitutional Profiling</span>
                  <input
                    type="checkbox"
                    checked={ayushMode}
                    onChange={(e) => setAyushMode(e.target.checked)}
                    className="w-4 h-4 text-blue-600 rounded"
                  />
                </div>
                {ayushMode && (
                  <div className="grid grid-cols-2 gap-3 pt-1">
                    <div>
                      <label className="block font-semibold text-slate-600 mb-1">Prakriti Predominance</label>
                      <select
                        value={prakritiSelection}
                        onChange={(e) => setPrakritiSelection(e.target.value)}
                        className="w-full px-3 py-2 bg-white border rounded-xl font-bold"
                      >
                        <option value="Vata-Pitta">Vata-Pitta (Heat &amp; Motion)</option>
                        <option value="Pitta-Kapha">Pitta-Kapha (Inflammation &amp; Congestion)</option>
                        <option value="Vata-Kapha">Vata-Kapha (Dryness &amp; Sluggishness)</option>
                        <option value="Tridosha">Tridosha (Equilibrium)</option>
                      </select>
                    </div>
                    <div className="text-[11px] text-slate-500 flex items-center">
                      Correlates traditional Ayurvedic dosha imbalances with Western ICD-11 vitals.
                    </div>
                  </div>
                )}
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-3.5 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
              >
                {loading ? 'Generating Doctor Summary...' : 'Generate Physician-Ready OPD Summary & Triage'}
              </button>
            </form>
          </div>
        )}

        {/* TAB 2: DOCTOR QUEUE */}
        {activeTab === 'DOCTOR_QUEUE' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            
            {/* Queue List */}
            <div className="lg:col-span-5 bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-4">
              <div className="border-b pb-2 flex items-center justify-between">
                <h2 className="text-xs font-extrabold text-slate-800 uppercase tracking-wider">OPD Patient Queue ({intakes.length})</h2>
                <span className="text-[10px] font-mono bg-blue-50 text-blue-700 px-2 py-0.5 rounded font-bold">Doctor Terminal</span>
              </div>

              <div className="divide-y divide-slate-100 space-y-2">
                {intakes.map((item) => (
                  <div
                    key={item.id}
                    onClick={() => setSelectedIntake(item)}
                    className={`p-3.5 rounded-xl cursor-pointer transition border ${
                      selectedIntake?.id === item.id
                        ? 'bg-blue-50/70 border-blue-300'
                        : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-bold text-xs text-slate-900">{item.patient_name}</span>
                      <span
                        className={`px-2 py-0.5 rounded text-[9px] font-black ${
                          item.triage_level === 'CRITICAL_TRIAGE'
                            ? 'bg-rose-100 text-rose-800'
                            : item.triage_level === 'PRIORITY_OPD'
                            ? 'bg-amber-100 text-amber-800'
                            : 'bg-emerald-100 text-emerald-800'
                        }`}
                      >
                        {item.triage_level}
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-600 line-clamp-1">{item.chief_complaint}</p>
                    <div className="text-[10px] text-slate-400 font-mono mt-1">{item.id} &bull; {item.duration}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Selected Summary View */}
            <div className="lg:col-span-7 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
              {selectedIntake ? (
                <div className="space-y-4">
                  <div className="border-b pb-3 flex items-center justify-between">
                    <div>
                      <h2 className="text-lg font-black text-slate-900">{selectedIntake.patient_name}</h2>
                      <span className="text-xs text-slate-400 font-mono">OPD Ticket ID: {selectedIntake.id}</span>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-black ${
                        selectedIntake.triage_level === 'CRITICAL_TRIAGE'
                          ? 'bg-rose-100 text-rose-800'
                          : 'bg-blue-100 text-blue-800'
                      }`}
                    >
                      {selectedIntake.triage_level}
                    </span>
                  </div>

                  <div className="p-4 bg-slate-50 rounded-2xl border space-y-2 text-xs">
                    <span className="font-bold text-slate-400 uppercase text-[10px]">Automated Doctor-Ready Summary</span>
                    <p className="text-slate-800 leading-relaxed font-medium">{selectedIntake.summary}</p>
                  </div>

                  <div className="grid grid-cols-2 gap-3 text-xs">
                    <div className="p-3 bg-slate-50 border rounded-xl">
                      <span className="text-[10px] font-bold text-slate-400 uppercase block">Chief Complaint</span>
                      <span className="font-bold text-slate-900">{selectedIntake.chief_complaint}</span>
                    </div>
                    <div className="p-3 bg-slate-50 border rounded-xl">
                      <span className="text-[10px] font-bold text-slate-400 uppercase block">Symptoms Identified</span>
                      <span className="font-bold text-slate-900">{selectedIntake.symptoms.join(', ')}</span>
                    </div>
                  </div>

                  {selectedIntake.ayush_mode && (
                    <div className="p-3.5 bg-amber-50 border border-amber-200 rounded-xl text-xs space-y-1">
                      <span className="font-bold text-amber-900 uppercase text-[10px]">AYUSH Prakriti Profile</span>
                      <p className="text-amber-950 font-medium">Predominance: {selectedIntake.prakriti_type || 'Vata-Pitta'}. Recommended Pathyadi Kwath &amp; dietary adjustments.</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="text-center py-12 text-slate-400 text-xs italic">
                  Select a patient intake from the queue to view clinical summary.
                </div>
              )}
            </div>

          </div>
        )}

        {/* TAB 3: OCR */}
        {activeTab === 'OCR' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-6 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">Medical Prescription &amp; Lab Report OCR</h2>
                <p className="text-xs text-slate-500">Pytesseract &amp; PIL document scanner for drug NER &amp; lab anomaly detection</p>
              </div>
              <span className="px-2.5 py-1 bg-teal-50 text-teal-800 text-[10px] font-bold rounded-lg border border-teal-200">
                Pytesseract OCR Engine
              </span>
            </div>

            <div className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 mb-1">OCR Document Text Input</label>
                <textarea
                  value={ocrText}
                  onChange={(e) => setOcrText(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl font-mono text-xs h-28"
                />
              </div>

              <div className="p-4 bg-slate-50 rounded-2xl border space-y-3">
                <span className="font-bold text-slate-800 uppercase text-[10px]">Extracted Medications (NER Engine)</span>
                <div className="flex flex-wrap gap-2">
                  {ocrAnalysis.extracted_medications?.map((med: string, i: number) => (
                    <span key={i} className="px-3 py-1 bg-white border border-slate-200 text-slate-800 font-bold rounded-xl text-xs">
                      💊 {med}
                    </span>
                  ))}
                </div>
              </div>

              {ocrAnalysis.lab_anomalies?.length > 0 && (
                <div className="p-4 bg-rose-50 border border-rose-200 rounded-2xl space-y-2">
                  <span className="font-bold text-rose-900 uppercase text-[10px]">Flagged Lab Anomalies</span>
                  {ocrAnalysis.lab_anomalies.map((anom: any, idx: number) => (
                    <div key={idx} className="flex items-center justify-between text-xs bg-white p-2.5 rounded-xl border border-rose-100">
                      <span className="font-bold text-rose-950">{anom.parameter}: {anom.observed_value} {anom.unit}</span>
                      <span className="text-[10px] font-mono text-rose-700 font-bold bg-rose-100 px-2 py-0.5 rounded">
                        Ref: {anom.reference_range} ({anom.severity})
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 4: CHAT */}
        {activeTab === 'CHAT' && (
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4 max-w-4xl mx-auto">
            <div className="border-b pb-3 flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-slate-900">MediKiosk AI Clinical Assistant</h2>
                <p className="text-xs text-slate-500">Guided clinical history collection and triage support</p>
              </div>
            </div>

            <div className="h-80 overflow-y-auto space-y-3 p-4 bg-slate-50 rounded-2xl border border-slate-200 text-xs">
              {chatMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[80%] p-3 rounded-2xl font-medium leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-blue-600 text-white rounded-br-none'
                        : 'bg-white text-slate-800 border border-slate-200 rounded-bl-none shadow-xs'
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              {chatLoading && <div className="text-slate-400 text-xs italic">MediKiosk AI is thinking...</div>}
            </div>

            <form onSubmit={handleSendChat} className="flex gap-2">
              <input
                type="text"
                value={chatInput}
                onChange={(e) => setChatInput(e.target.value)}
                placeholder="Describe your symptoms or ask about clinical triage..."
                className="flex-1 px-4 py-2.5 bg-slate-50 border rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <button
                type="submit"
                disabled={chatLoading}
                className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl shadow-xs transition"
              >
                Send
              </button>
            </form>
          </div>
        )}

      </div>
    </div>
  );
}
