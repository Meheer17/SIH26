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
      <div className="min-h-[calc(100vh-4rem)] flex items-center justify-center bg-slate-50 text-slate-600 font-sans">
        <div className="flex items-center gap-3">
          <svg className="animate-spin h-5 w-5 text-indigo-600" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span className="text-sm font-bold">Loading SvasthyaSetu Dashboard...</span>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center p-6 bg-slate-50 text-slate-900 text-center space-y-4 font-sans">
        <div className="w-12 h-12 rounded-2xl bg-indigo-50 border border-indigo-200 text-indigo-700 flex items-center justify-center font-bold text-lg">
          !
        </div>
        <h2 className="text-2xl font-black">Authentication Required</h2>
        <p className="text-xs text-slate-500 max-w-sm">
          Please log in or register an account to access the SvasthyaSetu role-based portal.
        </p>
        <div className="flex gap-3">
          <Link href="/login" className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md shadow-indigo-600/20 transition">
            Sign In
          </Link>
          <Link href="/register" className="px-5 py-2.5 rounded-xl bg-white border border-slate-300 hover:bg-slate-50 text-slate-800 font-bold text-xs shadow-sm transition">
            Register
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-slate-50 text-slate-900 font-sans p-6 sm:p-8 space-y-8">
      <div className="max-w-6xl mx-auto space-y-8">

        {/* Executive User Header */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-indigo-600 text-white font-black text-xl flex items-center justify-center shadow-md shadow-indigo-600/20">
              {user.full_name.charAt(0).toUpperCase()}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-extrabold text-slate-900">{user.full_name}</h1>
                {user.is_admin && (
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase bg-amber-50 text-amber-800 border border-amber-300">
                    System Admin
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-500 font-mono mt-0.5">{user.email_or_phone}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {user.is_admin && (
              <Link
                href="/admin/roles"
                className="px-4 py-2 rounded-xl bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-200 text-xs font-bold transition flex items-center gap-1.5"
              >
                <span>Admin Roles</span>
              </Link>
            )}
            <Link
              href="/consent"
              className="px-4 py-2 rounded-xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 text-xs font-bold transition flex items-center gap-1.5"
            >
              <span>Consent Engine</span>
            </Link>
            <button
              onClick={() => {
                logout();
                router.push('/login');
              }}
              className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-rose-50 text-slate-700 hover:text-rose-700 border border-slate-200 hover:border-rose-200 text-xs font-bold transition"
            >
              Sign Out
            </button>
          </div>
        </header>

        {/* User RBAC Security Tier */}
        <section className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-3">
          <h2 className="text-xs font-bold uppercase tracking-wider text-slate-400">Assigned RBAC Security Tiers</h2>
          <div className="flex flex-wrap gap-2">
            {user.mapped_roles.map((role) => (
              <span
                key={role}
                className="px-3.5 py-1.5 rounded-xl text-xs font-bold bg-indigo-50 border border-indigo-200 text-indigo-700 flex items-center gap-2"
              >
                <span className="w-2 h-2 rounded-full bg-indigo-600 animate-pulse"></span>
                {role}
              </span>
            ))}
          </div>
        </section>

        {/* 4 Application Portal Grid */}
        <section className="space-y-4">
          <div className="border-b border-slate-200 pb-3">
            <h2 className="text-xl font-extrabold text-slate-900 tracking-tight">Platform Applications</h2>
            <p className="text-xs text-slate-500">Access specialized domain AI agents and health management tools</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            {/* ArogyaSathi */}
            <div className="bg-white border border-slate-200 hover:border-emerald-400 rounded-2xl p-6 transition shadow-sm hover:shadow-md space-y-4 flex flex-col justify-between group">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold uppercase px-3 py-1 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200">
                    Disaster &amp; Health Monitoring
                  </span>
                  <span className="text-xs text-slate-400 font-mono">v1.2</span>
                </div>
                <h3 className="text-lg font-extrabold text-slate-900 group-hover:text-emerald-700 transition">ArogyaSathi</h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Continuous heat stress index, dehydration probability, respiratory AQI risk monitoring, and automated emergency SOS triggers.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-bold text-emerald-700 border-t border-slate-100">
                <span>Target Role: {user.primary_role}</span>
                <Link href="/chat?agent=arogya_sathi_agent" className="hover:underline">Launch App &rarr;</Link>
              </div>
            </div>

            {/* MediKiosk */}
            <div className="bg-white border border-slate-200 hover:border-sky-400 rounded-2xl p-6 transition shadow-sm hover:shadow-md space-y-4 flex flex-col justify-between group">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold uppercase px-3 py-1 rounded-full bg-sky-50 text-sky-800 border border-sky-200">
                    OPD Intake &amp; Triage
                  </span>
                  <span className="text-xs text-slate-400 font-mono">v1.2</span>
                </div>
                <h3 className="text-lg font-extrabold text-slate-900 group-hover:text-sky-700 transition">MediKiosk</h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Conversational clinical history (SOCRATES), OCR document processing, medical NER, AYUSH history mode, and physician terminal.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-bold text-sky-700 border-t border-slate-100">
                <span>Target Role: {user.primary_role}</span>
                <Link href="/chat?agent=medikiosk_agent" className="hover:underline">Launch App &rarr;</Link>
              </div>
            </div>

            {/* RakshakMitra */}
            <div className="bg-white border border-slate-200 hover:border-amber-400 rounded-2xl p-6 transition shadow-sm hover:shadow-md space-y-4 flex flex-col justify-between group">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold uppercase px-3 py-1 rounded-full bg-amber-50 text-amber-800 border border-amber-200">
                    Forces Welfare &amp; Burnout
                  </span>
                  <span className="text-xs text-slate-400 font-mono">v1.2</span>
                </div>
                <h3 className="text-lg font-extrabold text-slate-900 group-hover:text-amber-700 transition">RakshakMitra</h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  HRMS data correlation, voice mood journal analysis, burnout prediction models, and anonymized commander heatmaps.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-bold text-amber-700 border-t border-slate-100">
                <span>Target Role: {user.primary_role}</span>
                <Link href="/chat?agent=rakshak_mitra_agent" className="hover:underline">Launch App &rarr;</Link>
              </div>
            </div>

            {/* NyayaSahay */}
            <div className="bg-white border border-slate-200 hover:border-purple-400 rounded-2xl p-6 transition shadow-sm hover:shadow-md space-y-4 flex flex-col justify-between group">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold uppercase px-3 py-1 rounded-full bg-purple-50 text-purple-800 border border-purple-200">
                    Atrocity Victim Support
                  </span>
                  <span className="text-xs text-slate-400 font-mono">v1.2</span>
                </div>
                <h3 className="text-lg font-extrabold text-slate-900 group-hover:text-purple-700 transition">NyayaSahay</h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Proactive multi-channel outreach, voice stress analysis (VSA), case timeline correlation, and multi-tier government escalation.
                </p>
              </div>
              <div className="pt-2 flex items-center justify-between text-xs font-bold text-purple-700 border-t border-slate-100">
                <span>Target Role: {user.primary_role}</span>
                <Link href="/chat?agent=nyaya_sahay_agent" className="hover:underline">Launch App &rarr;</Link>
              </div>
            </div>

          </div>
        </section>

      </div>
    </div>
  );
}
