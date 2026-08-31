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
  triage_level: string;
  summary: string;
  ayush_mode: boolean;
  created_at: string;
}

export default function MediKioskPage() {
  const { user } = useAuth();
  
  // Intake Form State
  const [symptomsInput, setSymptomsInput] = useState('cough, sore throat, mild fever');
  const [duration, setDuration] = useState('3 days');
  const [severityRating, setSeverityRating] = useState(5);
  const [chiefComplaint, setChiefComplaint] = useState('Dry throat tickling & cough');
  const [hpi, setHpi] = useState('Onset after traveling on flight. No shortness of breath.');
  const [ros, setRos] = useState('Normal appetite, mild head congestion.');
  const [ayushMode, setAyushMode] = useState(false);
  
  const [loading, setLoading] = useState(false);
  const [uploadingOcr, setUploadingOcr] = useState(false);
  const [ocrResult, setOcrResult] = useState<any>(null);

  const [intakes, setIntakes] = useState<ClinicalIntake[]>([]);
  const [selectedIntake, setSelectedIntake] = useState<ClinicalIntake | null>(null);

  const fetchIntakes = async () => {
    try {
      const data = await apiClient.get('/apps/medikiosk/intake');
      setIntakes(data);
    } catch (e) {
      console.error('Failed to load clinical records', e);
    }
  };

  useEffect(() => {
    if (user) {
      fetchIntakes();
    }
  }, [user]);

  const handleOcrUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingOcr(true);
    try {
      const formData = new FormData();
      formData.append('file', file);

      const token = localStorage.getItem('svasthya_access_token');
      const response = await fetch('http://localhost:8000/api/v1/apps/medikiosk/ocr', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
        },
        body: formData,
      });

      if (!response.ok) {
        throw new Error('OCR Document Digitizing Failed');
      }

      const resData = await response.json();
      setOcrResult(resData);
      alert('Medical Document Digitized via Python OCR engine!');
    } catch (err: any) {
      alert(err.message || 'OCR Upload Failed');
    } finally {
      setUploadingOcr(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const symptomsList = symptomsInput.split(',').map((s) => s.trim()).filter(Boolean);
      await apiClient.post('/apps/medikiosk/intake', {
        symptoms: symptomsList,
        duration,
        severity_rating: severityRating,
        chief_complaint: chiefComplaint,
        history_present_illness: hpi,
        review_systems: ros,
        ayush_mode: ayushMode,
      });
      alert('Clinical history intake successfully saved!');
      fetchIntakes();
    } catch (err: any) {
      alert(err.message || 'Intake submission failed');
    } finally {
      setLoading(false);
    }
  };

  if (!user) {
    return <div className="p-8 text-center text-xs text-slate-500 font-bold">Please log in to view MediKiosk</div>;
  }

  const isDoctorOrAdmin = user.mapped_roles.some(
    (role) => role === 'PHYSICIAN' || role === 'SYSTEM_ADMIN'
  );

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        
        <header className="flex items-center justify-between bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-3">
            <span className="text-2xl">🏥</span>
            <div>
              <h1 className="text-xl font-extrabold text-slate-900">MediKiosk Clinical Console</h1>
              <p className="text-xs text-slate-500">OPD Intake dialogues &amp; triage matching</p>
            </div>
          </div>
          <div className="flex gap-2">
            <div className="px-3.5 py-2 bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-bold rounded-xl flex items-center">
              Active Mode: {isDoctorOrAdmin ? '🩺 Physician Terminal' : '👤 Patient Kiosk'}
            </div>
            <Link href="/dashboard" className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition">
              &larr; Dashboard
            </Link>
          </div>
        </header>

        {isDoctorOrAdmin ? (
          // ==========================================
          // PHYSICIAN TERMINAL VIEW
          // ==========================================
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-start">
            
            {/* List Left */}
            <div className="md:col-span-5 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
              <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">OPD Waiting Queue</h2>
              <div className="divide-y max-h-[500px] overflow-y-auto pr-1">
                {intakes.length > 0 ? (
                  intakes.map((i) => {
                    const isCritical = i.triage_level === 'CRITICAL_EMERGENCY';
                    return (
                      <button
                        key={i.id}
                        onClick={() => setSelectedIntake(i)}
                        className={`w-full py-3 text-left transition flex justify-between items-center ${
                          selectedIntake?.id === i.id ? 'bg-indigo-50 px-2 rounded-xl' : ''
                        }`}
                      >
                        <div>
                          <div className="font-bold text-xs text-slate-800">{i.patient_name}</div>
                          <div className="text-[10px] text-slate-400 font-mono mt-0.5">{new Date(i.created_at).toLocaleTimeString()}</div>
                        </div>
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[9px] font-black uppercase ${
                            isCritical ? 'bg-rose-50 text-rose-700 border border-rose-200' : 'bg-slate-50 text-slate-600 border'
                          }`}
                        >
                          {i.triage_level}
                        </span>
                      </button>
                    );
                  })
                ) : (
                  <div className="py-8 text-center text-xs text-slate-400 italic">No clinic records in database.</div>
                )}
              </div>
            </div>

            {/* Structured Report Right */}
            <div className="md:col-span-7">
              {selectedIntake ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                  <div className="flex justify-between items-center border-b pb-2">
                    <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider">Physician Intake Report</h2>
                    <span className="font-mono text-[10px] text-slate-400">ID: {selectedIntake.id}</span>
                  </div>

                  <div className="grid grid-cols-2 gap-3 text-xs">
                    <div>
                      <span className="block text-slate-400 font-bold uppercase text-[9px]">Chief Complaint</span>
                      <p className="font-bold text-slate-800">{selectedIntake.chief_complaint}</p>
                    </div>
                    <div>
                      <span className="block text-slate-400 font-bold uppercase text-[9px]">Triage status</span>
                      <p className="font-bold text-rose-600">{selectedIntake.triage_level}</p>
                    </div>
                  </div>

                  <div className="space-y-1 text-xs">
                    <span className="block text-slate-400 font-bold uppercase text-[9px]">Symptoms Checklist</span>
                    <div className="flex flex-wrap gap-1.5">
                      {selectedIntake.symptoms.map((s) => (
                        <span key={s} className="px-2 py-0.5 bg-slate-50 border rounded-xl text-[10px]">
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="p-4 bg-slate-50 border rounded-xl space-y-2 text-xs">
                    <span className="block text-indigo-700 font-black uppercase text-[10px]">Doctor-ready AI Summary</span>
                    <p className="text-slate-700 leading-relaxed font-sans">{selectedIntake.summary}</p>
                  </div>

                  {selectedIntake.ayush_mode && (
                    <div className="p-4 bg-emerald-50/50 border border-emerald-100 rounded-xl text-xs text-emerald-800">
                      <span className="font-bold">Ayurvedic (AYUSH) indicators recorded:</span> prakriti constitution profiles and ahara schedules logged.
                    </div>
                  )}
                </div>
              ) : (
                <div className="bg-white border border-slate-200 rounded-2xl p-12 shadow-sm text-center text-slate-400 text-xs italic">
                  Select a waiting patient from the queue to view their structured clinical chart.
                </div>
              )}
            </div>

          </div>
        ) : (
          // ==========================================
          // PATIENT KIOSK VIEW
          // ==========================================
          <div className="space-y-6 max-w-xl mx-auto">
            {/* Python Document OCR Dropzone */}
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-3">
              <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">
                📸 Python Medical Document &amp; Prescription OCR Scanner
              </h2>
              <p className="text-xs text-slate-500">
                Upload paper prescriptions or lab reports to auto-extract medications and flag lab anomalies.
              </p>
              <input
                type="file"
                accept="image/*,.pdf"
                onChange={handleOcrUpload}
                disabled={uploadingOcr}
                className="w-full text-xs text-slate-600 file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-sky-50 file:text-sky-700 hover:file:bg-sky-100 transition"
              />

              {ocrResult && (
                <div className="p-4 bg-slate-50 border border-slate-200 rounded-xl text-xs space-y-3 font-mono">
                  <div className="font-bold text-sky-800 border-b pb-1">Extracted Prescriptions &amp; Lab Entities:</div>
                  <div>
                    <span className="font-bold text-slate-700">Medications:</span>
                    <ul className="list-disc pl-4 text-slate-600 font-sans mt-0.5">
                      {ocrResult.extracted_medications.map((m: string, idx: number) => (
                        <li key={idx}>{m}</li>
                      ))}
                    </ul>
                  </div>

                  {ocrResult.lab_anomalies.length > 0 && (
                    <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-amber-900 font-sans">
                      <div className="font-bold text-amber-900 mb-1">⚠️ Out-Of-Range Lab Anomalies Flagged:</div>
                      {ocrResult.lab_anomalies.map((anom: any, idx: number) => (
                        <div key={idx} className="text-[11px]">
                          • {anom.parameter}: {anom.observed_value} {anom.unit} (Ref: {anom.reference_range})
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>

            <form onSubmit={handleSubmit} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
              <h2 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider border-b pb-2">Structured Symptom Dialogues</h2>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Chief Complaint (Short summary of reason for visit)</label>
                <input
                  type="text"
                  required
                  value={chiefComplaint}
                  onChange={(e) => setChiefComplaint(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                  placeholder="e.g. Coughing and chest heaviness"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Symptoms (comma separated)</label>
                <input
                  type="text"
                  required
                  value={symptomsInput}
                  onChange={(e) => setSymptomsInput(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                  placeholder="cough, headache, fever"
                />
              </div>

              <div className="grid grid-cols-2 gap-3 text-xs">
                <div>
                  <label className="block text-slate-600 font-bold mb-1">Duration</label>
                  <input
                    type="text"
                    required
                    value={duration}
                    onChange={(e) => setDuration(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                    placeholder="e.g. 5 days"
                  />
                </div>
                <div>
                  <label className="block text-slate-600 font-bold mb-1">Severity scale (1 to 10)</label>
                  <input
                    type="number"
                    min="1"
                    max="10"
                    required
                    value={severityRating}
                    onChange={(e) => setSeverityRating(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border rounded-xl"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">History of Present Illness (HPI Timeline)</label>
                <textarea
                  required
                  value={hpi}
                  onChange={(e) => setHpi(e.target.value)}
                  rows={3}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                  placeholder="Describe when and how the symptoms evolved..."
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Review of Systems (ROS Other symptoms)</label>
                <textarea
                  required
                  value={ros}
                  onChange={(e) => setRos(e.target.value)}
                  rows={2}
                  className="w-full px-3 py-2 bg-slate-50 border rounded-xl text-xs"
                  placeholder="Note any other organs, stomach problems, sleep cycles..."
                />
              </div>

              <div className="flex items-center gap-2 text-xs">
                <input
                  type="checkbox"
                  id="ayushCheck"
                  checked={ayushMode}
                  onChange={(e) => setAyushMode(e.target.checked)}
                  className="rounded"
                />
                <label htmlFor="ayushCheck" className="text-slate-600 font-bold">Include traditional AYUSH Prakriti profiling questionnaire</label>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-3.5 bg-sky-600 hover:bg-sky-700 text-white font-bold text-xs rounded-xl shadow-md transition disabled:opacity-50"
              >
                {loading ? 'Processing intake summary...' : 'Submit Symptoms Intake'}
              </button>
            </form>
          </div>
        )}

      </div>
    </div>
  );
}
