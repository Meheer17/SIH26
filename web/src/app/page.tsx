'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';
import Link from 'next/link';

const DEMO_TEST_ACCOUNTS = [
  {
    name: 'Capt. Vikram Verma',
    role: 'SOLDIER',
    email: 'capt_verma@forces.gov.in',
    app: 'RakshakMitra — Armed Forces Stress & Burnout Core',
    icon: '🎖️',
    color: 'bg-amber-50/80 text-amber-900 border-amber-200 hover:border-amber-400 hover:bg-amber-100/60',
    badge: 'bg-amber-200/60 text-amber-800',
    targetRoute: '/rakshak',
    desc: 'Access Soldier Burnout Predictor, Voice Mood Journaling & Anonymized Commander Heatmap',
  },
  {
    name: 'Rahul Sharma',
    role: 'PATIENT',
    email: 'arogya_user@example.com',
    app: 'ArogyaSathi — Disaster & Health Telemetry',
    icon: '🫀',
    color: 'bg-emerald-50/80 text-emerald-900 border-emerald-200 hover:border-emerald-400 hover:bg-emerald-100/60',
    badge: 'bg-emerald-200/60 text-emerald-800',
    targetRoute: '/arogya',
    desc: 'Access Continuous Vitals, Heat Stress Index, AQI Telemetry & Automated Emergency SOS',
  },
  {
    name: 'Dr. Ananya Sharma',
    role: 'PHYSICIAN',
    email: 'dr_sharma@hospital.org',
    app: 'MediKiosk — OPD Clinical History & Triage',
    icon: '🏥',
    color: 'bg-sky-50/80 text-sky-900 border-sky-200 hover:border-sky-400 hover:bg-sky-100/60',
    badge: 'bg-sky-200/60 text-sky-800',
    targetRoute: '/medikiosk',
    desc: 'Access Patient Clinical Intake Queue, AYUSH Profiling & Clinical Red-Flag Detector',
  },
  {
    name: 'Rajesh Kumar',
    role: 'COUNSELOR',
    email: 'legal_officer@district.gov.in',
    app: 'NyayaSahay — Legal Aid & Distress Support',
    icon: '⚖️',
    color: 'bg-purple-50/80 text-purple-900 border-purple-200 hover:border-purple-400 hover:bg-purple-100/60',
    badge: 'bg-purple-200/60 text-purple-800',
    targetRoute: '/nyaya',
    desc: 'Access Atrocity Victim Legal Milestones, Dynamic Distress Tracking & Counselor Escalations',
  },
  {
    name: 'Admin Director',
    role: 'SYSTEM_ADMIN',
    email: 'admin@svasthya.gov.in',
    app: 'Unified Command & RBAC Dashboard',
    icon: '🛡️',
    color: 'bg-rose-50/80 text-rose-900 border-rose-200 hover:border-rose-400 hover:bg-rose-100/60',
    badge: 'bg-rose-200/60 text-rose-800',
    targetRoute: '/dashboard',
    desc: 'Full system administrative oversight, role mappings, and platform configuration',
  },
];

export default function HomePage() {
  const router = useRouter();
  const { user, login, logout } = useAuth();
  const [emailOrPhone, setEmailOrPhone] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (email: string, pass: string, targetOverride?: string) => {
    setLoading(true);
    setError('');

    try {
      const loggedUser = await login(email, pass);
      if (targetOverride) {
        router.push(targetOverride);
        return;
      }
      const roles = loggedUser?.mapped_roles || [loggedUser?.primary_role];
      const hasAdmin = loggedUser?.is_admin || roles.includes('SYSTEM_ADMIN');

      if (hasAdmin) {
        router.push('/dashboard');
      } else if (roles.includes('PATIENT')) {
        router.push('/arogya');
      } else if (roles.includes('PHYSICIAN')) {
        router.push('/medikiosk');
      } else if (roles.includes('SOLDIER') || roles.includes('WELFARE_OFFICER')) {
        router.push('/rakshak');
      } else if (roles.includes('COUNSELOR') || roles.includes('VICTIM')) {
        router.push('/nyaya');
      } else {
        router.push('/dashboard');
      }
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Authentication failed. Please verify credentials.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    handleLogin(emailOrPhone, password);
  };

  return (
    <div className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center p-6 bg-slate-50 font-sans">
      <div className="max-w-5xl w-full space-y-6">
        
        {/* Hero Branding Header */}
        <div className="text-center space-y-2">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full text-xs font-bold bg-indigo-50 text-indigo-700 border border-indigo-200 uppercase tracking-wider">
            <span>🇮🇳 SvasthyaSetu — Role-Isolated Health &amp; Defense Platform</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
            Sign In to Access Your Application
          </h1>
          <p className="text-sm text-slate-600 max-w-xl mx-auto">
            Choose your official role or enter your credentials. You will be routed directly to your designated platform workspace.
          </p>
        </div>

        {/* Active Session Info Banner */}
        {user && (
          <div className="bg-indigo-50 border border-indigo-200 rounded-2xl p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm">
            <div className="flex items-center gap-3">
              <span className="w-3 h-3 rounded-full bg-emerald-500 animate-pulse"></span>
              <div>
                <p className="text-xs font-bold text-indigo-950">
                  Active Session: <span className="text-indigo-600 font-extrabold">{user.full_name}</span> ({user.primary_role})
                </p>
                <p className="text-[11px] text-indigo-700">Click any role below to switch accounts and jump to that platform workspace.</p>
              </div>
            </div>
            <button
              onClick={logout}
              className="px-3.5 py-1.5 bg-white hover:bg-rose-50 text-rose-700 border border-rose-200 rounded-xl text-xs font-bold transition self-start sm:self-auto shadow-sm"
            >
              Clear / Sign Out
            </button>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          
          {/* Left Column: One-Tap Role Selection Cards */}
          <div className="lg:col-span-7 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <div className="border-b pb-3">
              <span className="text-[11px] font-bold uppercase tracking-wider text-indigo-600">Fast Developer &amp; Officer Access</span>
              <h2 className="text-lg font-black text-slate-900">Select Your Role to Sign In</h2>
              <p className="text-xs text-slate-500">Each role has isolated access restricted to their respective domain tools.</p>
            </div>

            <div className="space-y-3">
              {DEMO_TEST_ACCOUNTS.map((acc) => (
                <button
                  key={acc.email}
                  type="button"
                  onClick={() => handleLogin(acc.email, 'demo123456', acc.targetRoute)}
                  className={`w-full p-4 rounded-xl text-left border transition-all duration-200 shadow-sm hover:shadow-md group flex items-start gap-3.5 ${acc.color}`}
                >
                  <span className="text-2xl mt-0.5">{acc.icon}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-extrabold text-sm text-slate-900 group-hover:text-indigo-900 transition">
                        {acc.name}
                      </span>
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${acc.badge}`}>
                        {acc.role}
                      </span>
                    </div>
                    <div className="text-xs font-semibold text-slate-700 mt-0.5">{acc.app}</div>
                    <div className="text-[11px] text-slate-500 mt-1 line-clamp-1">{acc.desc}</div>
                  </div>
                  <span className="text-slate-400 group-hover:translate-x-1 transition font-bold text-sm mt-2">&rarr;</span>
                </button>
              ))}
            </div>
          </div>

          {/* Right Column: Direct Credential Login Form */}
          <div className="lg:col-span-5 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex flex-col justify-between space-y-6">
            <div className="space-y-4">
              <div className="border-b pb-3">
                <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Custom Credentials</span>
                <h2 className="text-lg font-black text-slate-900">Direct Sign In</h2>
                <p className="text-xs text-slate-500">Enter your registered email or phone number</p>
              </div>

              {error && (
                <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-semibold">
                  {error}
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Email or Phone</label>
                  <input
                    type="text"
                    required
                    value={emailOrPhone}
                    onChange={(e) => setEmailOrPhone(e.target.value)}
                    placeholder="e.g. capt_verma@forces.gov.in"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 bg-slate-50 focus:bg-white text-xs focus:ring-2 focus:ring-indigo-500 focus:outline-none transition"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Password</label>
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter password (demo123456)"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 bg-slate-50 focus:bg-white text-xs focus:ring-2 focus:ring-indigo-500 focus:outline-none transition"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md shadow-indigo-600/20 transition disabled:opacity-50"
                >
                  {loading ? 'Authenticating...' : 'Sign In to Workspace &rarr;'}
                </button>
              </form>
            </div>

            <div className="pt-4 border-t text-center space-y-2">
              <p className="text-xs text-slate-500">
                New user?{' '}
                <Link href="/register" className="text-indigo-600 font-bold hover:underline">
                  Create an account
                </Link>
              </p>
              <p className="text-[10px] text-slate-400">
                Default Demo Password for test accounts: <code className="font-mono font-bold text-slate-600">demo123456</code>
              </p>
            </div>

          </div>

        </div>

      </div>
    </div>
  );
}
