'use client';

import { useState } from 'react';
import Link from 'next/link';
import { checkBackendHealth, HealthResponse } from '@/lib/api/apiClient';

const PROBLEM_STATEMENTS = [
  {
    id: 'SIH26181',
    title: 'ArogyaSathi',
    subtitle: 'Qualcomm MedTech Track',
    badge: 'Disaster Health Companion',
    href: '/arogya',
    icon: '🫀',
    accentColor: 'border-teal-500 text-teal-700 bg-teal-50/50',
    btnBg: 'bg-teal-700 hover:bg-teal-800 text-white',
    description: 'Real-time heat stress monitoring, environmental weather/AQI hazard telemetry, body hydration & vitals anomaly engine, plus 1-tap SOS emergency trigger.',
    features: ['Heat Stress Formula', 'AQI Respiratory Hazard', 'Gemini Health Assistant', '1-Tap SOS Dispatch'],
  },
  {
    id: 'SIH26047',
    title: 'MediKiosk',
    subtitle: 'Ministry of Ayush Track',
    badge: 'Patient Case-Taking & Triage',
    href: '/medikiosk',
    icon: '🏥',
    accentColor: 'border-blue-500 text-blue-700 bg-blue-50/50',
    btnBg: 'bg-blue-700 hover:bg-blue-800 text-white',
    description: 'Structured clinical dialogue (SOCRATES & AYUSH Prakriti/Vikriti), prescription OCR document digitizer, and automated physician summary generator.',
    features: ['SOCRATES Dialogue', 'AYUSH Prakriti Mode', 'Medical Document OCR', 'Physician Summary Output'],
  },
  {
    id: 'SIH26186',
    title: 'RakshakMitra',
    subtitle: 'Ministry of Home Affairs Track',
    badge: 'Uniformed Forces Stress System',
    href: '/rakshak',
    icon: '🎖️',
    accentColor: 'border-slate-800 text-slate-800 bg-slate-100/70',
    btnBg: 'bg-slate-900 hover:bg-slate-800 text-white',
    description: 'Burnout & stress predictor for armed forces, leave gap & deployment matrix analyzer, anonymized unit commander heatmap, and voice mood recorder.',
    features: ['Burnout Predictor', 'Commander Unit Heatmap', 'Voice Mood Analyzer', 'Welfare Action Engine'],
  },
  {
    id: 'SIH26094',
    title: 'NyayaSahay',
    subtitle: 'Ministry of Social Justice Track',
    badge: 'Victim Mental Health System',
    href: '/nyaya',
    icon: '⚖️',
    accentColor: 'border-indigo-600 text-indigo-700 bg-indigo-50/50',
    btnBg: 'bg-indigo-700 hover:bg-indigo-800 text-white',
    description: 'Dynamic psychological distress score monitor for atrocity victims, case timeline milestone correlation (FIR to trial), and multi-tier district escalation workflow.',
    features: ['Dynamic Distress Index', 'Legal Milestone Correlation', 'Multi-Tier Escalation', 'NHAA 14566 Integration'],
  },
];

const PLATFORM_FOUNDATION = [
  { title: 'Bhashini Multilingual', desc: '10+ Indian languages with speech-to-text & text-to-speech support.', icon: '🌐', link: '/chat' },
  { title: 'DPDP Consent Engine', desc: 'Granular, purpose-bound audio/text consent tracking for data privacy.', icon: '🔒', link: '/consent' },
  { title: 'Emergency SOS Broadcast', desc: 'Instant GPS & vitals payload dispatcher with 5s countdown.', icon: '🆘', link: '/sos-demo' },
  { title: 'Hybrid AI Engine', desc: 'Gemini Cloud API + on-device LiteRT/TFLite intelligence layer.', icon: '🧠', link: '/chat' },
];

export default function Home() {
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [healthData, setHealthData] = useState<HealthResponse | null>(null);

  const testConnection = async () => {
    setStatus('loading');
    try {
      const data = await checkBackendHealth();
      setHealthData(data);
      setStatus('success');
    } catch {
      setStatus('error');
    }
  };

  return (
    <div className="space-y-10 pb-16 font-sans bg-slate-50 min-h-screen">
      {/* Pristine Hero Section */}
      <section className="bg-white border-b border-slate-200 py-12 px-6 sm:px-12">
        <div className="max-w-5xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200 font-mono">
            <span>SMART INDIA HACKATHON 2026</span>
            <span className="text-slate-400">|</span>
            <span>UNIFIED PLATFORM PROTOTYPE</span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-black text-slate-900 tracking-tight">
            SvasthyaSetu <span className="font-light text-slate-600">(स्वास्थ्य सेतु)</span>
          </h1>

          <p className="text-slate-600 max-w-2xl mx-auto text-sm sm:text-base leading-relaxed">
            One unified healthcare platform addressing four high-priority SIH 2026 problem statements with clean clinical UI and real AI telemetry processing.
          </p>

          <div className="pt-2 flex flex-wrap justify-center gap-2">
            {PROBLEM_STATEMENTS.map((ps) => (
              <Link
                key={ps.id}
                href={ps.href}
                className="px-3 py-1.5 rounded-md bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-semibold border border-slate-300 transition flex items-center gap-1.5"
              >
                <span>{ps.icon}</span>
                <span>{ps.title}</span>
                <span className="font-mono text-[10px] text-slate-500">[{ps.id}]</span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Main Grid for 4 Problem Statements */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 space-y-10">
        <section className="space-y-4">
          <div className="flex items-center justify-between border-b border-slate-200 pb-3">
            <div>
              <h2 className="text-xl font-bold text-slate-900 tracking-tight">The 4 Problem Statements</h2>
              <p className="text-xs text-slate-500">Click any card below to launch and evaluate the interactive prototype</p>
            </div>
            <button
              onClick={testConnection}
              className="text-xs font-semibold px-3 py-1.5 bg-white border border-slate-300 rounded-md text-slate-700 hover:bg-slate-50 transition flex items-center gap-1.5"
            >
              <span className={`w-2 h-2 rounded-full ${status === 'success' ? 'bg-emerald-500' : 'bg-slate-400'}`} />
              <span>{status === 'loading' ? 'Checking API...' : status === 'success' ? 'API Online' : 'Check Backend API'}</span>
            </button>
          </div>

          {status === 'success' && healthData && (
            <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-md text-emerald-800 text-xs font-mono">
              FastAPI Connected — Service: {healthData.service} | Uptime: {healthData.uptime_seconds}s
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {PROBLEM_STATEMENTS.map((ps) => (
              <div
                key={ps.id}
                className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs hover:border-slate-400 transition flex flex-col justify-between space-y-4"
              >
                <div className="space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <span className="text-2xl">{ps.icon}</span>
                      <div>
                        <h3 className="font-bold text-base text-slate-900 flex items-center gap-2">
                          {ps.title}
                          <span className="font-mono text-xs text-slate-500 font-normal">[{ps.id}]</span>
                        </h3>
                        <p className="text-xs font-medium text-slate-500">{ps.subtitle}</p>
                      </div>
                    </div>
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold border ${ps.accentColor}`}>
                      {ps.badge}
                    </span>
                  </div>

                  <p className="text-xs text-slate-600 leading-relaxed">{ps.description}</p>

                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {ps.features.map((feat, i) => (
                      <span key={i} className="px-2 py-0.5 bg-slate-100 text-slate-700 rounded text-[10px] font-semibold border border-slate-200">
                        ✓ {feat}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                  <span className="text-[11px] font-mono text-slate-400">Problem Statement #{ps.id}</span>
                  <Link
                    href={ps.href}
                    className={`px-4 py-2 rounded-md font-bold text-xs shadow-xs transition flex items-center gap-1 ${ps.btnBg}`}
                  >
                    <span>Launch Prototype</span>
                    <span>&rarr;</span>
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* World-Changing Scalable Healthcare Innovations */}
        <section className="space-y-4">
          <div className="border-b border-slate-200 pb-3 flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold text-slate-900 tracking-tight">World-Changing Scalable Innovations</h2>
              <p className="text-xs text-slate-500">11 breakthrough features engineered for massive scale across India</p>
            </div>
            <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 rounded border border-emerald-300 text-xs font-bold font-mono">
              SIH2026 SPECIAL FEATURES
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            <Link
              href="/cin"
              className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs hover:border-emerald-500 transition space-y-3 group block"
            >
              <div className="flex items-center justify-between">
                <span className="text-2xl">🌐</span>
                <span className="px-2 py-0.5 bg-emerald-50 text-emerald-700 rounded text-[10px] font-bold border border-emerald-200">
                  KILLER FEATURE
                </span>
              </div>
              <h3 className="font-bold text-base text-slate-900 group-hover:text-emerald-700 transition">
                Community Immunity Network (CIN)
              </h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Offline BLE peer-to-peer mesh health intelligence. Swarms anonymous zero-knowledge symptom hashes to predict local outbreaks without internet.
              </p>
              <div className="pt-2 text-xs font-semibold text-emerald-700 flex items-center gap-1">
                <span>Explore P2P Mesh Dashboard</span> <span>&rarr;</span>
              </div>
            </Link>

            <Link
              href="/screening"
              className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs hover:border-blue-500 transition space-y-3 group block"
            >
              <div className="flex items-center justify-between">
                <span className="text-2xl">🫁</span>
                <span className="px-2 py-0.5 bg-blue-50 text-blue-700 rounded text-[10px] font-bold border border-blue-200">
                  NON-INVASIVE ML
                </span>
              </div>
              <h3 className="font-bold text-base text-slate-900 group-hover:text-blue-700 transition">
                Acoustic Cough &amp; Palmar Anemia Diagnostic Suite
              </h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Cough audio spectral centroid classifier + camera-based conjunctival/palmar R/G colorimetry for non-invasive Hb estimation.
              </p>
              <div className="pt-2 text-xs font-semibold text-blue-700 flex items-center gap-1">
                <span>Launch Diagnostic Suite</span> <span>&rarr;</span>
              </div>
            </Link>

            <Link
              href="/epidemic"
              className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs hover:border-rose-500 transition space-y-3 group block"
            >
              <div className="flex items-center justify-between">
                <span className="text-2xl">🌡️</span>
                <span className="px-2 py-0.5 bg-rose-50 text-rose-700 rounded text-[10px] font-bold border border-rose-200">
                  SPATIAL DBSCAN
                </span>
              </div>
              <h3 className="font-bold text-base text-slate-900 group-hover:text-rose-700 transition">
                Epidemic Early Warning &amp; Geo-Heatmap
              </h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                DBSCAN spatial clustering on geotagged symptom reports and heat-stress telemetry for automated epidemic outbreak detection.
              </p>
              <div className="pt-2 text-xs font-semibold text-rose-700 flex items-center gap-1">
                <span>View Heatmap Clusters</span> <span>&rarr;</span>
              </div>
            </Link>

            <Link
              href="/covert-sos"
              className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs hover:border-purple-500 transition space-y-3 group block"
            >
              <div className="flex items-center justify-between">
                <span className="text-2xl">🆘</span>
                <span className="px-2 py-0.5 bg-purple-50 text-purple-700 rounded text-[10px] font-bold border border-purple-200">
                  STEALTH SOS
                </span>
              </div>
              <h3 className="font-bold text-base text-slate-900 group-hover:text-purple-700 transition">
                Panic Disguise SOS &amp; Dead Man&apos;s Switch
              </h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Disguised calculator interface, accelerometer shake trigger, and passive inactivity dead man&apos;s switch for high-risk personnel &amp; victims.
              </p>
              <div className="pt-2 text-xs font-semibold text-purple-700 flex items-center gap-1">
                <span>Test Covert Triggers</span> <span>&rarr;</span>
              </div>
            </Link>

            <Link
              href="/family-graph"
              className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs hover:border-indigo-500 transition space-y-3 group block md:col-span-2"
            >
              <div className="flex items-center justify-between">
                <span className="text-2xl">🧬</span>
                <span className="px-2 py-0.5 bg-indigo-50 text-indigo-700 rounded text-[10px] font-bold border border-indigo-200">
                  GRAPH AI + COUNSELOR
                </span>
              </div>
              <h3 className="font-bold text-base text-slate-900 group-hover:text-indigo-700 transition">
                Family Health Risk Graph &amp; Cultural AI Counselor
              </h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                NetworkX family lineage graph for hereditary risk calculation + empathetic AI mental health companion tailored for military, trauma, and patient care.
              </p>
              <div className="pt-2 text-xs font-semibold text-indigo-700 flex items-center gap-1">
                <span>Launch Family Graph &amp; Counselor</span> <span>&rarr;</span>
              </div>
            </Link>
          </div>
        </section>

        {/* Groundbreaking SIH Innovations */}
        <section className="space-y-4">
          <div className="border-b border-slate-200 pb-3 flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-slate-900 tracking-tight">Groundbreaking Innovations for SIH 2026</h2>
              <p className="text-xs text-slate-500">Key architectural differentiators engineered for maximum hackathon impact</p>
            </div>
            <span className="px-2.5 py-1 bg-amber-50 text-amber-700 rounded border border-amber-200 text-xs font-bold font-mono">
              SIH INNOVATIONS
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white rounded-lg border border-slate-200 p-5 space-y-2 hover:border-blue-400 transition">
              <div className="flex items-center justify-between">
                <span className="text-xl">🌿</span>
                <span className="px-2 py-0.5 bg-blue-50 text-blue-700 rounded text-[10px] font-bold border border-blue-200 font-mono">SIH26047 + SIH26181</span>
              </div>
              <h3 className="font-bold text-sm text-slate-900">Dual AYUSH-Western Clinical Triangulation</h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Correlates Western ICD-11 vital thresholds with traditional AYUSH Prakriti-Vikriti heat imbalances (Vata/Pitta/Kapha) for dual-perspective doctor summaries.
              </p>
            </div>

            <div className="bg-white rounded-lg border border-slate-200 p-5 space-y-2 hover:border-slate-400 transition">
              <div className="flex items-center justify-between">
                <span className="text-xl">🎙️</span>
                <span className="px-2 py-0.5 bg-slate-100 text-slate-700 rounded text-[10px] font-bold border border-slate-200 font-mono">SIH26186 + SIH26094</span>
              </div>
              <h3 className="font-bold text-sm text-slate-900">Acoustic Micro-Tremor Voice Stress Profiler</h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Analyzes pitch jitter &amp; micro-shimmer in 5s voice clips to compute objective trauma &amp; burnout stress scores in 10+ Indian languages via Bhashini.
              </p>
            </div>

            <div className="bg-white rounded-lg border border-slate-200 p-5 space-y-2 hover:border-teal-400 transition">
              <div className="flex items-center justify-between">
                <span className="text-xl">📡</span>
                <span className="px-2 py-0.5 bg-teal-50 text-teal-700 rounded text-[10px] font-bold border border-teal-200 font-mono">SIH26181 + SIH26186</span>
              </div>
              <h3 className="font-bold text-sm text-slate-900">Offline BLE Mesh Telemetry Relay</h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Encrypts and relays peer-to-peer vital telemetry &amp; SOS payloads across nearby Bluetooth nodes in zero-cellular disaster or border outposts.
              </p>
            </div>
          </div>
        </section>

        {/* Core Platform Foundation */}
        <section className="space-y-4">
          <div className="border-b border-slate-200 pb-3">
            <h2 className="text-lg font-bold text-slate-900 tracking-tight">Shared Platform Foundation</h2>
            <p className="text-xs text-slate-500">65% shared infrastructure powering all four solutions</p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {PLATFORM_FOUNDATION.map((item, idx) => (
              <Link
                key={idx}
                href={item.link}
                className="bg-white rounded-lg border border-slate-200 p-4 hover:border-slate-400 transition space-y-1.5 block group"
              >
                <div className="flex items-center gap-2">
                  <span className="text-lg">{item.icon}</span>
                  <h4 className="font-bold text-sm text-slate-900 group-hover:text-teal-700 transition">{item.title}</h4>
                </div>
                <p className="text-xs text-slate-500 leading-relaxed">{item.desc}</p>
              </Link>
            ))}
          </div>
        </section>
      </div>

      {/* Clean Footer */}
      <footer className="border-t border-slate-200 bg-white py-6 text-center text-xs text-slate-500 font-sans space-y-1">
        <p className="font-bold text-slate-800">SvasthyaSetu — Smart India Hackathon 2026</p>
        <p className="text-[11px] text-slate-400 font-mono">SIH26181 • SIH26047 • SIH26186 • SIH26094</p>
      </footer>
    </div>
  );
}

