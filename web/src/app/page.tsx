'use client';

import { useState } from 'react';
import Link from 'next/link';
import { checkBackendHealth, HealthResponse } from '@/lib/api/apiClient';
import { API_BASE_URL } from '@/lib/api/endpoints';

const APPLICATION_CARDS = [
  {
    id: 'arogya_sathi',
    title: 'ArogyaSathi',
    subtitle: 'Disaster Health & Vitals Monitoring',
    icon: '🫀',
    color: 'from-emerald-500/20 to-teal-500/10 border-emerald-500/30 text-emerald-400',
    description: 'Continuous health monitoring for rural & disaster-prone areas. Detects heat stress, dehydration probability, AQI respiratory risks, and NDMA advisories.',
    targetAgent: 'arogya_sathi_agent',
    accentBtn: 'bg-emerald-600 hover:bg-emerald-500',
  },
  {
    id: 'medikiosk',
    title: 'MediKiosk',
    subtitle: 'OPD Clinical Intake & History Triage',
    icon: '🏥',
    color: 'from-sky-500/20 to-indigo-500/10 border-sky-500/30 text-sky-400',
    description: 'Captures structured clinical history (SOCRATES/OLDCARTS/AYUSH Prakriti) before patient enters OPD. Digitizes prescriptions via ML Kit OCR and flags clinical red flags.',
    targetAgent: 'medikiosk_agent',
    accentBtn: 'bg-sky-600 hover:bg-sky-500',
  },
  {
    id: 'rakshak_mitra',
    title: 'RakshakMitra',
    subtitle: 'Armed Forces Stress & Burnout Support',
    icon: '🎖️',
    color: 'from-amber-500/20 to-orange-500/10 border-amber-500/30 text-amber-400',
    description: 'Proactive early-warning burnout predictor for defense & police personnel. Analyzes duty hours, deployment duration, leave gap ratio, and recommends commander welfare actions.',
    targetAgent: 'rakshak_mitra_agent',
    accentBtn: 'bg-amber-600 hover:bg-amber-500',
  },
  {
    id: 'nyaya_sahay',
    title: 'NyayaSahay',
    subtitle: 'Atrocity Victim Legal Rehabilitation',
    icon: '⚖️',
    color: 'from-purple-500/20 to-pink-500/10 border-purple-500/30 text-purple-400',
    description: 'Continuous psychological & legal support for SC/ST atrocity victims. Correlates distress scores with legal case stage milestones (FIR, trial) and triggers multi-tier escalation.',
    targetAgent: 'nyaya_sahay_agent',
    accentBtn: 'bg-purple-600 hover:bg-purple-500',
  },
];

const FEATURE_MODULE_LINKS = [
  {
    title: '🧠 AI Agent Hub',
    subtitle: 'Strands & Bedrock Mantle',
    path: '/chat',
    description: 'Multi-agent reasoning with domain tools (heat stress, triage, burnout, distress).',
    badge: 'Core Engine',
  },
  {
    title: '💾 Encrypted Storage SDK',
    subtitle: 'Offline-First Local DB',
    path: '/storage-demo',
    description: 'Single-invoke AES-256 local storage with automatic background offline sync queue.',
    badge: 'Offline SDK',
  },
  {
    title: '🆘 One-Tap SOS & Alerts',
    subtitle: 'Emergency & Multi-Tier',
    path: '/sos-demo',
    description: 'GPS + vitals snapshot emergency trigger with 5s cancel window and multi-tier routing.',
    badge: 'Emergency',
  },
  {
    title: '📊 Role Dashboard',
    subtitle: 'Multi-Role Access',
    path: '/dashboard',
    description: 'Personalized views for Patients, Doctors, Officers, Counselors, and Administrators.',
    badge: 'Dashboard',
  },
  {
    title: '🔒 Role Management',
    subtitle: 'Granular RBAC Control',
    path: '/admin/roles',
    description: 'Manage mapped roles, admin privileges, and user access permissions.',
    badge: 'RBAC',
  },
  {
    title: '✅ Consent Engine',
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
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans flex flex-col selection:bg-indigo-500 selection:text-white">
      {/* Top Navigation Bar */}
      <nav className="sticky top-0 z-50 border-b border-slate-800 bg-slate-900/90 backdrop-blur-xl px-6 py-3.5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-indigo-600 via-purple-600 to-emerald-500 flex items-center justify-center text-white font-black text-xl shadow-lg shadow-indigo-500/20">
            S
          </div>
          <div>
            <span className="font-extrabold text-base tracking-tight text-white flex items-center gap-2">
              SvasthyaSetu
              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-indigo-500/10 text-indigo-400 border border-indigo-500/30">
                SIH 2026
              </span>
            </span>
            <p className="text-[11px] text-slate-400">Bridge to Health — Unified Platform</p>
          </div>
        </div>

        {/* Header Links */}
        <div className="hidden lg:flex items-center gap-4 text-xs font-semibold">
          <Link href="/chat" className="text-slate-300 hover:text-indigo-400 transition">💬 AI Chat Hub</Link>
          <Link href="/dashboard" className="text-slate-300 hover:text-indigo-400 transition">📊 Dashboard</Link>
          <Link href="/storage-demo" className="text-slate-300 hover:text-indigo-400 transition">💾 Local Storage SDK</Link>
          <Link href="/sos-demo" className="text-slate-300 hover:text-indigo-400 transition">🆘 SOS &amp; Alerts</Link>
          <Link href="/admin/roles" className="text-slate-300 hover:text-indigo-400 transition">🔒 Admin Roles</Link>
          <Link href="/consent" className="text-slate-300 hover:text-indigo-400 transition">✅ Consent Engine</Link>
          <a href="http://localhost:8000/docs" target="_blank" rel="noreferrer" className="text-slate-400 hover:text-white transition">📖 API Docs</a>
        </div>

        <div className="flex items-center gap-2.5">
          <Link
            href="/login"
            className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-bold text-slate-200 border border-slate-700 transition"
          >
            🔑 Sign In
          </Link>
          <Link
            href="/register"
            className="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-xs font-bold text-white shadow-lg shadow-indigo-600/30 transition"
          >
            📝 Register
          </Link>
        </div>
      </nav>

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-6 sm:p-10 space-y-12">
        {/* Hero Banner */}
        <section className="relative rounded-3xl p-8 sm:p-12 bg-gradient-to-br from-slate-900 via-indigo-950/40 to-slate-900 border border-slate-800 shadow-2xl overflow-hidden text-center space-y-6">
          <div className="absolute -top-32 -left-32 w-80 h-80 bg-indigo-600/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute -bottom-32 -right-32 w-80 h-80 bg-emerald-600/20 rounded-full blur-3xl pointer-events-none" />

          <div className="inline-block px-4 py-1.5 rounded-full text-xs font-bold tracking-wider uppercase bg-indigo-500/10 text-indigo-400 border border-indigo-500/30">
            One Foundation • Four Life-Saving Missions
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight text-white max-w-4xl mx-auto leading-tight">
            SvasthyaSetu — <span className="bg-gradient-to-r from-indigo-400 via-purple-400 to-emerald-400 bg-clip-text text-transparent">Bridge to Health</span>
          </h1>

          <p className="text-slate-300 max-w-2xl mx-auto text-sm sm:text-base leading-relaxed">
            Unified healthcare platform serving general public, hospital OPDs, armed forces personnel, and atrocity victims. Powered by Strands AI Agents, AWS Bedrock Mantle, and Encrypted Offline Storage.
          </p>

          <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
            <Link
              href="/chat"
              className="px-6 py-3.5 rounded-2xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-sm shadow-xl shadow-indigo-600/30 transition hover:scale-105 flex items-center gap-2"
            >
              <span>💬 Launch AI Agent Hub</span>
            </Link>
            <Link
              href="/login"
              className="px-6 py-3.5 rounded-2xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 font-bold text-sm transition hover:scale-105"
            >
              🔑 Demo Test Logins
            </Link>
            <a
              href="http://localhost:8000/docs"
              target="_blank"
              rel="noreferrer"
              className="px-6 py-3.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-slate-400 border border-slate-800 font-semibold text-sm transition"
            >
              📖 Swagger API Docs
            </a>
          </div>
        </section>

        {/* 4 Core Applications Portal Grid */}
        <section id="apps" className="space-y-6">
          <div className="flex items-center justify-between border-b border-slate-800 pb-4">
            <div>
              <h2 className="text-2xl font-black text-white flex items-center gap-2">
                <span>The Four Life-Saving Applications</span>
              </h2>
              <p className="text-xs text-slate-400">Same core foundation, four specialized domain missions</p>
            </div>
            <Link href="/chat" className="text-xs font-bold text-indigo-400 hover:underline">
              Explore All AI Agents →
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {APPLICATION_CARDS.map((app) => (
              <div
                key={app.id}
                className={`p-6 rounded-3xl bg-slate-900/80 border backdrop-blur-xl ${app.color} space-y-4 hover:border-indigo-500/50 transition duration-300 shadow-xl flex flex-col justify-between`}
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-3xl">{app.icon}</span>
                    <span className="px-3 py-1 rounded-full text-[11px] font-bold bg-slate-950/80 border border-slate-800 text-slate-300">
                      {app.subtitle}
                    </span>
                  </div>
                  <h3 className="text-xl font-bold text-white">{app.title}</h3>
                  <p className="text-xs text-slate-300 leading-relaxed">{app.description}</p>
                </div>

                <div className="pt-2 flex items-center justify-between">
                  <Link
                    href={`/chat?agent=${app.targetAgent}`}
                    className={`px-4 py-2 rounded-xl text-white font-bold text-xs shadow-md ${app.accentBtn} transition`}
                  >
                    Open {app.title} AI
                  </Link>
                  <Link href="/login" className="text-xs font-semibold text-slate-400 hover:text-white">
                    Sign In as Role →
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Core Platform Modules & Navigation Links Grid */}
        <section className="space-y-6">
          <div className="border-b border-slate-800 pb-4">
            <h2 className="text-2xl font-black text-white">Platform Shared Infrastructure Hub</h2>
            <p className="text-xs text-slate-400">Reusable engines built once and shared across all 4 applications</p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {FEATURE_MODULE_LINKS.map((item, idx) => (
              <Link
                key={idx}
                href={item.path}
                className="p-5 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-indigo-500/40 hover:bg-slate-900 transition duration-200 space-y-2 group shadow-lg"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-indigo-400 uppercase tracking-wider">{item.subtitle}</span>
                  <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-slate-950 border border-slate-800 text-slate-400">
                    {item.badge}
                  </span>
                </div>
                <h3 className="font-bold text-white text-base group-hover:text-indigo-300 transition">{item.title}</h3>
                <p className="text-xs text-slate-400 leading-relaxed">{item.description}</p>
                <div className="pt-1 text-[11px] font-semibold text-indigo-400 flex items-center gap-1 group-hover:translate-x-1 transition">
                  Launch Module →
                </div>
              </Link>
            ))}
          </div>
        </section>

        {/* Live Backend Connection Tester Card */}
        <section className="bg-slate-900/80 border border-slate-800 rounded-3xl p-6 sm:p-8 backdrop-blur-xl shadow-2xl space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-800">
            <div>
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
                FastAPI Backend Service Status
              </h2>
              <p className="text-xs text-slate-400 font-mono mt-0.5">
                Endpoint: <code className="text-indigo-300">{API_BASE_URL}/health</code>
              </p>
            </div>
            <button
              onClick={testConnection}
              disabled={status === 'loading'}
              className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-bold text-xs transition shadow-lg shadow-indigo-600/30 disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {status === 'loading' ? <span>Testing API...</span> : <span>Test Live Connection</span>}
            </button>
          </div>

          {status === 'success' && healthData && (
            <div className="p-4 rounded-2xl bg-emerald-950/40 border border-emerald-500/30 text-emerald-300 text-xs space-y-1">
              <div className="font-bold text-emerald-400">✅ FastAPI Backend Connection Healthy</div>
              <div className="grid grid-cols-3 gap-2 pt-1 font-mono text-[11px]">
                <div>Service: {healthData.service}</div>
                <div>Uptime: {healthData.uptime_seconds}s</div>
                <div>Version: {healthData.version}</div>
              </div>
            </div>
          )}

          {status === 'error' && (
            <div className="p-4 rounded-2xl bg-rose-950/40 border border-rose-500/30 text-rose-300 text-xs font-mono">
              ⚠️ {errorMsg}
            </div>
          )}
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-800 bg-slate-950 py-8 px-6 text-center text-xs text-slate-500 space-y-2">
        <p>SvasthyaSetu — Bridge to Health • Unified Platform for ArogyaSathi, MediKiosk, RakshakMitra &amp; NyayaSahay</p>
        <p className="text-[11px] text-slate-600">Built with Next.js 16, Flutter 3, FastAPI, Strands Agents, &amp; AWS Bedrock Mantle</p>
      </footer>
    </div>
  );
}
