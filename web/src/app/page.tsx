'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';
import Link from 'next/link';
import { checkBackendHealth, HealthResponse } from '@/lib/api/apiClient';
import { API_BASE_URL } from '@/lib/api/endpoints';

const APPLICATION_CARDS = [
  {
    id: 'arogya_sathi',
    title: 'ArogyaSathi',
    subtitle: 'Disaster Health & Vitals Monitoring',
    badgeColor: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    cardBorder: 'hover:border-emerald-400',
    btnBg: 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-600/20',
    description: 'Continuous health monitoring for rural & disaster-prone areas. Detects heat stress, dehydration risk, AQI respiratory hazards, and NDMA advisories.',
    targetAgent: 'arogya_sathi_agent',
  },
  {
    id: 'medikiosk',
    title: 'MediKiosk',
    subtitle: 'OPD Clinical History & Triage',
    badgeColor: 'bg-sky-50 text-sky-700 border-sky-200',
    cardBorder: 'hover:border-sky-400',
    btnBg: 'bg-sky-600 hover:bg-sky-700 shadow-sky-600/20',
    description: 'Captures structured clinical history (SOCRATES/AYUSH Prakriti) before patient enters OPD. Digitizes prescriptions via ML Kit OCR and flags clinical red flags.',
    targetAgent: 'medikiosk_agent',
  },
  {
    id: 'rakshak_mitra',
    title: 'RakshakMitra',
    subtitle: 'Armed Forces Stress & Burnout',
    badgeColor: 'bg-amber-50 text-amber-700 border-amber-200',
    cardBorder: 'hover:border-amber-400',
    btnBg: 'bg-amber-600 hover:bg-amber-700 shadow-amber-600/20',
    description: 'Proactive early-warning burnout predictor for defense & police personnel. Analyzes duty hours, deployment duration, leave gap ratio, and recommends welfare actions.',
    targetAgent: 'rakshak_mitra_agent',
  },
  {
    id: 'nyaya_sahay',
    title: 'NyayaSahay',
    subtitle: 'Atrocity Victim Legal Rehabilitation',
    badgeColor: 'bg-purple-50 text-purple-700 border-purple-200',
    cardBorder: 'hover:border-purple-400',
    btnBg: 'bg-purple-600 hover:bg-purple-700 shadow-purple-600/20',
    description: 'Continuous psychological & legal support for SC/ST atrocity victims. Correlates distress scores with legal case stage milestones (FIR, trial) and triggers multi-tier escalation.',
    targetAgent: 'nyaya_sahay_agent',
  },
];

const PLATFORM_MODULES = [
  {
    title: 'AI Agent Hub',
    subtitle: 'Strands & Bedrock Mantle',
    path: '/chat',
    description: 'Multi-agent reasoning engine with specialized domain tools for clinical & crisis assessment.',
    badge: 'Core Engine',
  },
  {
    title: 'Encrypted Storage SDK',
    subtitle: 'Offline-First Local DB',
    path: '/storage-demo',
    description: 'Single-invoke AES-256 encrypted local storage with background offline sync queue.',
    badge: 'Offline SDK',
  },
  {
    title: 'One-Tap SOS & Alerts',
    subtitle: 'Emergency Routing',
    path: '/sos-demo',
    description: 'GPS + vitals snapshot emergency trigger with 5s cancel countdown and multi-tier routing.',
    badge: 'Emergency',
  },
  {
    title: 'Role Dashboard',
    subtitle: 'Multi-Role Access',
    path: '/dashboard',
    description: 'Personalized views for Patients, Doctors, Officers, Counselors, and Administrators.',
    badge: 'Dashboard',
  },
  {
    title: 'Role Management',
    subtitle: 'Granular RBAC Control',
    path: '/admin/roles',
    description: 'Manage mapped roles, admin privileges, and user access permissions.',
    badge: 'RBAC',
  },
  {
    title: 'Consent Engine',
    subtitle: 'DPDP Act Compliance',
    path: '/consent',
    description: 'Granular, purpose-bound consent management with audio explanations for literacy.',
    badge: 'Privacy',
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
        setErrorMsg('Failed to connect to FastAPI backend.');
      }
    }
  };


  return (
    <div className="space-y-12 pb-16 font-sans">
      {/* Hero Banner */}
      <section className="bg-gradient-to-b from-indigo-50/70 via-white to-slate-50 border-b border-slate-200 py-16 px-6 sm:px-12 text-center">
        <div className="max-w-4xl mx-auto space-y-6">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-bold bg-indigo-100/80 text-indigo-700 border border-indigo-200 uppercase tracking-wider">
            <span>SIH 2026 Unified Architecture</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black text-slate-900 tracking-tight leading-tight">
            SvasthyaSetu — <span className="text-indigo-600">Bridge to Health</span>
          </h1>

          <p className="text-slate-600 max-w-2xl mx-auto text-base sm:text-lg leading-relaxed font-normal">
            Enterprise healthcare intelligence platform serving rural communities, hospital OPDs, armed forces personnel, and atrocity victims.
          </p>

          <div className="flex flex-wrap items-center justify-center gap-3 pt-4">
            <Link
              href="/chat"
              className="px-6 py-3.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-lg shadow-indigo-600/25 transition hover:scale-[1.02]"
            >
              Launch AI Agent Hub
            </Link>
            <Link
              href="/login"
              className="px-6 py-3.5 rounded-xl bg-white hover:bg-slate-50 text-slate-800 font-bold text-sm border border-slate-300 shadow-sm transition hover:scale-[1.02]"
            >
              Demo Test Logins
            </Link>
          </div>
        </div>
      </section>

      {/* Main Content Area */}
      <div className="max-w-7xl mx-auto px-6 sm:px-8 space-y-12">
        {/* 4 Life-Saving Applications Section */}
        <section id="apps" className="space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-end justify-between border-b border-slate-200 pb-4 gap-2">
            <div>
              <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">The Four Platform Applications</h2>
              <p className="text-xs text-slate-500">Tailored AI reasoning agents built on a single unified architecture</p>
            </div>
            <Link href="/chat" className="text-xs font-bold text-indigo-600 hover:text-indigo-800 transition">
              Explore All AI Agents &rarr;
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {APPLICATION_CARDS.map((app) => (
              <div
                key={app.id}
                className={`bg-white rounded-2xl border border-slate-200 p-6 shadow-sm hover:shadow-md transition duration-200 space-y-4 flex flex-col justify-between ${app.cardBorder}`}
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-base font-extrabold text-slate-900">{app.title}</span>
                    <span className={`px-3 py-1 rounded-full text-xs font-bold border ${app.badgeColor}`}>
                      {app.subtitle}
                    </span>
                  </div>
                  <p className="text-xs text-slate-600 leading-relaxed">{app.description}</p>
                </div>

                <div className="pt-2 flex items-center justify-between border-t border-slate-100">
                  <Link
                    href={`/chat?agent=${app.targetAgent}`}
                    className={`px-4 py-2 rounded-xl text-white font-bold text-xs shadow-md ${app.btnBg} transition`}
                  >
                    Open {app.title} AI
                  </Link>
                  <Link href="/login" className="text-xs font-bold text-slate-500 hover:text-slate-900">
                    Sign In as Role &rarr;
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Platform Shared Modules Grid */}
        <section id="features" className="space-y-6">
          <div className="border-b border-slate-200 pb-4">
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">Shared Platform Modules</h2>
            <p className="text-xs text-slate-500">Core system services integrated across all 4 applications</p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {PLATFORM_MODULES.map((item, idx) => (
              <Link
                key={idx}
                href={item.path}
                className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm hover:shadow-md hover:border-indigo-300 transition duration-200 space-y-2 group"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-indigo-600 uppercase tracking-wider">{item.subtitle}</span>
                  <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-slate-100 border border-slate-200 text-slate-600 font-semibold">
                    {item.badge}
                  </span>
                </div>
                <h3 className="font-bold text-slate-900 text-base group-hover:text-indigo-600 transition">{item.title}</h3>
                <p className="text-xs text-slate-500 leading-relaxed">{item.description}</p>
                <div className="pt-1 text-[11px] font-bold text-indigo-600 flex items-center gap-1 group-hover:translate-x-1 transition">
                  Launch Module &rarr;
                </div>
              </Link>
            ))}
          </div>
        </section>

        {/* Live Backend Connection Tester Card */}
        <section className="bg-white border border-slate-200 rounded-2xl p-6 sm:p-8 shadow-sm space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
            <div>
              <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
                FastAPI Backend Connection Status
              </h3>
              <p className="text-xs text-slate-500 font-mono">
                Target Endpoint: <code className="text-indigo-600">{API_BASE_URL}/health</code>
              </p>
            </div>
            <button
              onClick={testConnection}
              disabled={status === 'loading'}
              className="px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs transition shadow-sm disabled:opacity-50"
            >
              {status === 'loading' ? <span>Pinging API...</span> : <span>Test API Connection</span>}
            </button>
          </div>

          {status === 'success' && healthData && (
            <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-mono">
              <div className="font-bold text-emerald-900 mb-1">FastAPI Backend Online &amp; Resilient</div>
              <div>Service: {healthData.service} | Uptime: {healthData.uptime_seconds}s | Version: {healthData.version}</div>
            </div>
          )}

          {status === 'error' && (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono">
              {errorMsg}
            </div>
          )}
        </section>
      </div>

      {/* Footer */}
      <footer className="border-t border-slate-200 bg-white py-8 px-6 text-center text-xs text-slate-500 space-y-1">
        <p className="font-semibold text-slate-700">SvasthyaSetu — Bridge to Health Unified Platform</p>
        <p className="text-[11px] text-slate-400">Next.js 16, Flutter 3, FastAPI, Strands Agents, &amp; AWS Bedrock Mantle</p>
      </footer>
    </div>
  );
}

