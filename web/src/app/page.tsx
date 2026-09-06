'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { checkBackendHealth, HealthResponse } from '@/lib/api/apiClient';
import { API_BASE_URL } from '@/lib/api/endpoints';

const CORE_APPLICATIONS = [
  {
    id: 'arogya',
    href: '/arogya',
    problemCode: 'SIH26181',
    category: 'Rural & Disaster Health',
    name: 'ArogyaSathi',
    question: 'How am I doing right now?',
    summary:
      'Continuous physiological and environmental telemetry for field and rural settings. Monitors real-time vital equilibrium, thermal stress, hydration loss, and air-quality respiratory hazards with automated SOS dispatch.',
    accent: 'border-emerald-800/20 text-emerald-900',
    tagBg: 'bg-emerald-50 text-emerald-800 border-emerald-200',
    btnText: 'Open ArogyaSathi',
  },
  {
    id: 'medikiosk',
    href: '/medikiosk',
    problemCode: 'SIH26047',
    category: 'Clinical OPD Intake',
    name: 'MediKiosk',
    question: 'What does the doctor need to know?',
    summary:
      'Structured pre-consultation clinical intake and history capture. Translates patient symptoms into doctor-ready SOCRATES summaries, integrates AYUSH Prakriti profiling, and digitizes prescriptions with anomaly detection.',
    accent: 'border-sky-800/20 text-sky-900',
    tagBg: 'bg-sky-50 text-sky-800 border-sky-200',
    btnText: 'Open MediKiosk',
  },
  {
    id: 'rakshak',
    href: '/rakshak',
    problemCode: 'SIH26186',
    category: 'Defense & Police Welfare',
    name: 'RakshakMitra',
    question: 'Does my unit need attention?',
    summary:
      'Early-stage burnout and psychological fatigue assessment for armed forces and police units. Correlates continuous deployment days, leave gaps, and acoustic voice tremor analysis into actionable operational rosters.',
    accent: 'border-amber-800/20 text-amber-900',
    tagBg: 'bg-amber-50 text-amber-800 border-amber-200',
    btnText: 'Open RakshakMitra',
  },
  {
    id: 'nyaya',
    href: '/nyaya',
    problemCode: 'SIH26094',
    category: 'Legal Rehabilitation',
    name: 'NyayaSahay',
    question: 'What support do I need?',
    summary:
      'Safe, confidential legal-medical assistance for atrocity victims. Maps psychological distress scores against formal legal case milestones (FIR, trial, compensation) with multi-tier district protection escalation.',
    accent: 'border-purple-800/20 text-purple-900',
    tagBg: 'bg-purple-50 text-purple-800 border-purple-200',
    btnText: 'Open NyayaSahay',
  },
];

const PLATFORM_CAPABILITIES = [
  {
    title: 'Multi-Agent AI Hub',
    subtitle: 'Clinical Reasoning',
    path: '/chat',
    description: 'Autonomous reasoning agents equipped with clinical, legal, and operational assessment tools.',
  },
  {
    title: 'Offline-First Storage',
    subtitle: 'Encrypted Local SDK',
    path: '/storage-demo',
    description: 'Hardware-backed AES-256 local encrypted database with seamless background synchronization.',
  },
  {
    title: 'Emergency SOS Hub',
    subtitle: 'Multi-Channel Alert',
    path: '/sos-demo',
    description: 'High-accuracy live GPS pinning, OpenStreetMap reverse geocoding, and WhatsApp emergency dispatch.',
  },
  {
    title: 'Consent & Privacy',
    subtitle: 'DPDP Act Engine',
    path: '/consent',
    description: 'Granular, purpose-bound patient consent with audio explanations for varying literacy levels.',
  },
];

export default function Home() {
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [healthData, setHealthData] = useState<HealthResponse | null>(null);
  const [errorMsg, setErrorMsg] = useState<string>('');

  const testConnection = async () => {
    setStatus('loading');
    setErrorMsg('');
    try {
      const data = await checkBackendHealth();
      setHealthData(data);
      setStatus('success');
    } catch (err: unknown) {
      setStatus('error');
      if (err instanceof Error) {
        setErrorMsg(err.message);
      } else {
        setErrorMsg('Unable to connect to the backend service.');
      }
    }
  };

  return (
    <div className="space-y-16 pb-20 font-sans text-stone-900">
      {/* Editorial Hero Banner */}
      <section className="border-b border-stone-200/80 bg-stone-100/40 py-16 sm:py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto space-y-6 text-center sm:text-left">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-medium bg-stone-200/80 text-stone-800 border border-stone-300/60">
            <span>Unified Healthcare &amp; Defense Intelligence Platform</span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-semibold tracking-tight text-stone-900 leading-tight">
            Technology designed for human resilience, clinical clarity, and timely care.
          </h1>

          <p className="text-stone-600 text-base sm:text-lg leading-relaxed max-w-2xl">
            SvasthyaSetu bridges continuous personal health monitoring, clinical OPD triage, armed forces welfare, and confidential legal-medical rehabilitation into one cohesive, high-trust system.
          </p>

          <div className="flex flex-wrap items-center gap-3 pt-2">
            <Link
              href="/arogya"
              className="px-5 py-2.5 rounded-lg bg-stone-900 hover:bg-stone-800 text-stone-50 text-xs font-medium shadow-xs transition"
            >
              Explore ArogyaSathi &rarr;
            </Link>
            <Link
              href="/login"
              className="px-5 py-2.5 rounded-lg bg-white hover:bg-stone-100 text-stone-800 text-xs font-medium border border-stone-300/80 shadow-2xs transition"
            >
              Sign In Portal
            </Link>
          </div>
        </div>
      </section>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16">
        {/* Core Four Applications Section */}
        <section className="space-y-8">
          <div className="border-b border-stone-200 pb-3 flex flex-col sm:flex-row sm:items-baseline justify-between gap-2">
            <div>
              <h2 className="text-xl font-semibold tracking-tight text-stone-900">Four Dedicated Mission Applications</h2>
              <p className="text-xs text-stone-500 mt-0.5">Each crafted for a specific human-centered purpose and operational environment</p>
            </div>
            <Link href="/chat" className="text-xs font-medium text-stone-600 hover:text-stone-900">
              Open Unified AI Assistant &rarr;
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {CORE_APPLICATIONS.map((app) => (
              <div
                key={app.id}
                className="bg-white border border-stone-200/90 rounded-xl p-6 shadow-2xs flex flex-col justify-between hover:border-stone-400/80 transition duration-200 space-y-6"
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold uppercase tracking-wider text-stone-500">
                      {app.category}
                    </span>
                    <span className={`text-[10px] font-medium px-2 py-0.5 rounded-full border ${app.tagBg}`}>
                      {app.problemCode}
                    </span>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-stone-900">{app.name}</h3>
                    <p className="text-xs text-stone-500 italic mt-0.5">&ldquo;{app.question}&rdquo;</p>
                  </div>

                  <p className="text-xs text-stone-600 leading-relaxed">{app.summary}</p>
                </div>

                <div className="pt-4 border-t border-stone-100 flex items-center justify-between">
                  <Link
                    href={app.href}
                    className="px-4 py-2 rounded-lg bg-stone-900 hover:bg-stone-800 text-stone-50 text-xs font-medium transition shadow-2xs"
                  >
                    {app.btnText}
                  </Link>
                  <Link href="/login" className="text-xs text-stone-500 hover:text-stone-900 font-medium">
                    Account Access &rarr;
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Shared Architecture Capabilities */}
        <section className="space-y-6">
          <div className="border-b border-stone-200 pb-3">
            <h2 className="text-xl font-semibold tracking-tight text-stone-900">Platform Infrastructure</h2>
            <p className="text-xs text-stone-500 mt-0.5">Underlying privacy, offline synchronization, and emergency routing protocols</p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {PLATFORM_CAPABILITIES.map((cap, idx) => (
              <Link
                key={idx}
                href={cap.path}
                className="bg-white border border-stone-200/80 rounded-xl p-4 shadow-2xs hover:border-stone-400/80 transition duration-200 space-y-2 group block"
              >
                <span className="text-[10px] font-semibold text-stone-500 uppercase tracking-wider block">
                  {cap.subtitle}
                </span>
                <h4 className="text-sm font-semibold text-stone-900 group-hover:text-stone-700 transition">
                  {cap.title}
                </h4>
                <p className="text-xs text-stone-500 leading-relaxed">{cap.description}</p>
              </Link>
            ))}
          </div>
        </section>

        {/* Service Connectivity Verification */}
        <section className="bg-stone-50 border border-stone-200 rounded-xl p-5 sm:p-6 shadow-2xs">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="text-sm font-semibold text-stone-900 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-600"></span>
                Backend Health Verification
              </h3>
              <p className="text-xs text-stone-500 mt-0.5">
                Target Service: <code className="text-stone-700 font-mono text-[11px]">{API_BASE_URL}/health</code>
              </p>
            </div>
            <button
              type="button"
              onClick={testConnection}
              disabled={status === 'loading'}
              className="px-3.5 py-1.5 rounded-lg bg-stone-900 hover:bg-stone-800 text-stone-50 text-xs font-medium transition disabled:opacity-50"
            >
              {status === 'loading' ? 'Checking...' : 'Verify Connectivity'}
            </button>
          </div>

          {status === 'success' && healthData && (
            <div className="mt-4 p-3 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-900 text-xs font-mono">
              <span className="font-semibold">Service Online:</span> {healthData.service} &bull; Uptime: {healthData.uptime_seconds}s &bull; v{healthData.version}
            </div>
          )}

          {status === 'error' && (
            <div className="mt-4 p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono">
              {errorMsg}
            </div>
          )}
        </section>
      </div>

      {/* Editorial Clean Footer */}
      <footer className="border-t border-stone-200 bg-stone-50 py-8 px-4 text-center text-xs text-stone-500 space-y-1 mt-12">
        <p className="font-medium text-stone-700">SvasthyaSetu &mdash; Unified Healthcare &amp; Defense Platform</p>
        <p className="text-[11px] text-stone-400">Developed for Smart India Hackathon 2026</p>
      </footer>
    </div>
  );
}

