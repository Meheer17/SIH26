'use client';

import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';

export default function DashboardPage() {
  const router = useRouter();
  const { user, loading, logout } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-950 text-slate-300 font-sans">
        <div className="flex items-center gap-3">
          <svg className="animate-spin h-5 w-5 text-indigo-500" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span className="text-sm font-medium">Loading SvasthyaSetu Portal...</span>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-slate-950 text-slate-100 text-center space-y-4">
        <h2 className="text-2xl font-bold">Authentication Required</h2>
        <p className="text-sm text-slate-400 max-w-sm">
          Please log in or register an account to access the SvasthyaSetu applications.
        </p>
        <div className="flex gap-4">
          <Link href="/login" className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-medium text-sm transition">
            Log In
          </Link>
          <Link href="/register" className="px-5 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-medium text-sm transition">
            Register
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans p-6">
      <div className="max-w-6xl mx-auto space-y-8">

        {/* Top Navbar */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900/80 border border-slate-800 rounded-2xl p-5 backdrop-blur-xl">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-indigo-600 to-purple-600 flex items-center justify-center text-white font-black text-xl shadow-lg">
              SS
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold text-white">{user.full_name}</h1>
                {user.is_admin && (
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-amber-500/20 text-amber-300 border border-amber-500/30">
                    SYSTEM ADMIN
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-400 font-mono">{user.email_or_phone}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {user.is_admin && (
              <Link
                href="/admin/roles"
                className="px-4 py-2 rounded-xl bg-amber-600/20 hover:bg-amber-600/30 text-amber-300 border border-amber-500/30 text-xs font-semibold transition flex items-center gap-1.5"
              >
                <span>⚙️</span>
                <span>Admin Role Manager</span>
              </Link>
            )}
            <Link
              href="/consent"
              className="px-4 py-2 rounded-xl bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-300 border border-indigo-500/30 text-xs font-semibold transition flex items-center gap-1.5"
            >
              <span>✅</span>
              <span>Consent Engine</span>
            </Link>
            <button
              onClick={() => {
                logout();
                router.push('/login');
              }}
              className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-rose-900/40 text-slate-300 hover:text-rose-300 text-xs font-semibold transition"
            >
              Sign Out
            </button>
          </div>
        </header>

        {/* User RBAC Profile Card */}
        <section className="bg-slate-900/50 border border-slate-800 rounded-2xl p-6 space-y-4">
          <h2 className="text-sm font-bold uppercase tracking-wider text-slate-400">Assigned RBAC Security Tiers</h2>
          <div className="flex flex-wrap gap-2">
            {user.mapped_roles.map((role) => (
              <span
                key={role}
                className="px-3.5 py-1.5 rounded-xl text-xs font-bold bg-indigo-950/60 border border-indigo-500/30 text-indigo-300 flex items-center gap-2"
              >
                <span className="w-2 h-2 rounded-full bg-indigo-400 animate-ping"></span>
                {role}
              </span>
            ))}
          </div>
        </section>

        {/* Application Cards Grid */}
        <section className="space-y-4">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <span>🚀</span>
            <span>SvasthyaSetu Applications</span>
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            {/* ArogyaSathi */}
            <div className="bg-slate-900/80 border border-rose-500/20 hover:border-rose-500/50 rounded-2xl p-6 transition backdrop-blur-lg space-y-4 group">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-rose-500/10 text-rose-400 flex items-center justify-center text-xl font-bold border border-rose-500/20">
                  🫀
                </div>
                <span className="text-[10px] font-bold uppercase px-2.5 py-1 rounded-full bg-rose-500/10 text-rose-300 border border-rose-500/20">
                  Disaster &amp; Health Monitoring
                </span>
              </div>
              <div>
                <h3 className="text-lg font-bold text-white group-hover:text-rose-400 transition">ArogyaSathi</h3>
                <p className="text-xs text-slate-400 mt-1">
                  Continuous heat stress index, dehydration probability, respiratory AQI risk monitoring, and automated emergency SOS triggers.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-semibold text-rose-400">
                <span>Active Target Role: {user.primary_role}</span>
                <span>Launch App &rarr;</span>
              </div>
            </div>

            {/* MediKiosk */}
            <div className="bg-slate-900/80 border border-blue-500/20 hover:border-blue-500/50 rounded-2xl p-6 transition backdrop-blur-lg space-y-4 group">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center text-xl font-bold border border-blue-500/20">
                  🏥
                </div>
                <span className="text-[10px] font-bold uppercase px-2.5 py-1 rounded-full bg-blue-500/10 text-blue-300 border border-blue-500/20">
                  OPD Intake &amp; Triage
                </span>
              </div>
              <div>
                <h3 className="text-lg font-bold text-white group-hover:text-blue-400 transition">MediKiosk</h3>
                <p className="text-xs text-slate-400 mt-1">
                  Conversational clinical history (SOCRATES), OCR document processing, medical NER, AYUSH history mode, and physician terminal.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-semibold text-blue-400">
                <span>Active Target Role: {user.primary_role}</span>
                <span>Launch App &rarr;</span>
              </div>
            </div>

            {/* RakshakMitra */}
            <div className="bg-slate-900/80 border border-emerald-500/20 hover:border-emerald-500/50 rounded-2xl p-6 transition backdrop-blur-lg space-y-4 group">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center text-xl font-bold border border-emerald-500/20">
                  🎖️
                </div>
                <span className="text-[10px] font-bold uppercase px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-300 border border-emerald-500/20">
                  Forces Welfare &amp; Burnout
                </span>
              </div>
              <div>
                <h3 className="text-lg font-bold text-white group-hover:text-emerald-400 transition">RakshakMitra</h3>
                <p className="text-xs text-slate-400 mt-1">
                  HRMS data correlation, voice mood journal analysis, burnout prediction models, and anonymized commander heatmaps.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-semibold text-emerald-400">
                <span>Active Target Role: {user.primary_role}</span>
                <span>Launch App &rarr;</span>
              </div>
            </div>

            {/* NyayaSahay */}
            <div className="bg-slate-900/80 border border-amber-500/20 hover:border-amber-500/50 rounded-2xl p-6 transition backdrop-blur-lg space-y-4 group">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center text-xl font-bold border border-amber-500/20">
                  ⚖️
                </div>
                <span className="text-[10px] font-bold uppercase px-2.5 py-1 rounded-full bg-amber-500/10 text-amber-300 border border-amber-500/20">
                  Atrocity Victim Support
                </span>
              </div>
              <div>
                <h3 className="text-lg font-bold text-white group-hover:text-amber-400 transition">NyayaSahay</h3>
                <p className="text-xs text-slate-400 mt-1">
                  Proactive multi-channel outreach, voice stress analysis (VSA), case timeline correlation, and multi-tier government escalation.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-semibold text-amber-400">
                <span>Active Target Role: {user.primary_role}</span>
                <span>Launch App &rarr;</span>
              </div>
            </div>

          </div>
        </section>

      </div>
    </div>
  );
}
