'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';
import { checkBackendHealth } from '@/lib/api/apiClient';

export default function Navbar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();
  const isAuthenticated = !!user;

  const [isBackendOnline, setIsBackendOnline] = useState<boolean | null>(null);

  useEffect(() => {
    checkBackendHealth()
      .then(() => setIsBackendOnline(true))
      .catch(() => setIsBackendOnline(false));
  }, []);

  const navHubs = [
    { name: 'Command Center', href: '/', icon: '⚡' },
    { name: 'Clinical & OPD', href: '/medikiosk', icon: '🩺' },
    { name: 'Palmar Anemia & Cough', href: '/screening', icon: '🔬' },
    { name: 'ASHA Copilot', href: '/asha', icon: '👩‍⚕️' },
    { name: 'Rakshak Welfare', href: '/rakshak', icon: '🧠' },
    { name: 'Nyaya Legal Aid', href: '/nyaya', icon: '⚖️' },
    { name: 'Stealth SOS & Vault', href: '/covert-sos', icon: '🛡️' },
    { name: 'Digital Twin', href: '/digital-twin', icon: '🧬' },
    { name: 'Health Karma', href: '/karma', icon: '🏆' },
    { name: 'AI Companion', href: '/chat', icon: '💬' },
  ];

  return (
    <header className="sticky top-0 z-50 bg-slate-950/80 backdrop-blur-xl border-b border-slate-800/80 text-slate-100 font-sans shadow-lg shadow-black/20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
        
        {/* Brand Logo & Live System Status */}
        <div className="flex items-center gap-3 shrink-0">
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-teal-500 via-cyan-500 to-indigo-500 flex items-center justify-center text-slate-950 font-black text-lg shadow-md shadow-teal-500/25 group-hover:scale-105 transition duration-300">
              ✚
            </div>
            <div className="flex flex-col">
              <span className="font-extrabold text-base tracking-tight text-white flex items-center gap-1.5">
                SvasthyaSetu
                <span className="px-2 py-0.5 rounded-full text-[9px] font-bold bg-teal-500/10 text-teal-400 border border-teal-500/20">
                  SIH 2026
                </span>
              </span>
              <span className="text-[10px] font-medium text-slate-400">National Healthcare &amp; Resilience Grid</span>
            </div>
          </Link>

          {/* Backend & ML Engines Live Status Indicator */}
          <div className="hidden xl:flex items-center gap-2 pl-3 border-l border-slate-800 text-[11px] font-medium text-slate-400">
            <span
              className={`w-2.5 h-2.5 rounded-full transition-all ${
                isBackendOnline === true
                  ? 'bg-emerald-400 animate-pulse ring-4 ring-emerald-500/20'
                  : isBackendOnline === false
                  ? 'bg-amber-400 ring-4 ring-amber-500/20'
                  : 'bg-slate-600'
              }`}
            />
            <span>
              {isBackendOnline
                ? '5 ML Engines & FastAPI Live'
                : isBackendOnline === false
                ? 'Connecting ML Backend...'
                : 'Checking System Status...'}
            </span>
          </div>
        </div>

        {/* Navigation Tabs */}
        <nav className="flex items-center gap-1 overflow-x-auto py-1 scrollbar-none">
          {navHubs.map((hub) => {
            const isActive = pathname === hub.href;
            return (
              <Link
                key={hub.name}
                href={hub.href}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all whitespace-nowrap ${
                  isActive
                    ? 'bg-gradient-to-r from-teal-500/20 to-cyan-500/20 text-teal-300 border border-teal-500/30 shadow-sm shadow-teal-500/10'
                    : 'text-slate-400 hover:bg-slate-900/80 hover:text-slate-200'
                }`}
              >
                <span>{hub.icon}</span>
                <span>{hub.name}</span>
              </Link>
            );
          })}
        </nav>

        {/* Action Controls & User Account */}
        <div className="flex items-center gap-3 shrink-0">
          <Link
            href="/sos-demo"
            className="hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-lg bg-gradient-to-r from-rose-600 to-pink-600 hover:from-rose-500 hover:to-pink-500 text-white text-xs font-bold shadow-md shadow-rose-600/25 hover:shadow-lg hover:shadow-rose-600/40 transition duration-300"
          >
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-white"></span>
            </span>
            <span>Emergency SOS</span>
          </Link>

          {isAuthenticated && user ? (
            <div className="flex items-center gap-3 border-l border-slate-800 pl-3">
              <div className="hidden sm:flex flex-col text-right">
                <span className="text-xs font-bold text-slate-200">{user.full_name}</span>
                <span className="text-[10px] font-semibold text-teal-400 tracking-wide">{user.primary_role}</span>
              </div>
              <button
                onClick={logout}
                className="px-3 py-1.5 rounded-lg bg-slate-900 hover:bg-rose-950 hover:text-rose-300 text-slate-300 text-xs font-semibold transition border border-slate-800"
              >
                Sign out
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="px-3 py-1.5 rounded-lg text-slate-300 hover:text-white text-xs font-semibold hover:bg-slate-900 transition"
              >
                Sign in
              </Link>
              <Link
                href="/register"
                className="px-3.5 py-1.5 rounded-lg bg-gradient-to-r from-teal-500 to-cyan-500 hover:from-teal-400 hover:to-cyan-400 text-slate-950 text-xs font-extrabold shadow-sm shadow-teal-500/20 transition"
              >
                Register
              </Link>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
