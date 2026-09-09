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
    { name: 'Clinical & OPD', href: '/medikiosk', icon: '🏥' },
    { name: 'Diagnostics & Screening', href: '/screening', icon: '🫁' },
    { name: 'ASHA & Community', href: '/asha', icon: '👩‍⚕️' },
    { name: 'Mind & Wellness', href: '/rakshak', icon: '🧠' },
    { name: 'Safety & Evidence', href: '/covert-sos', icon: '🛡️' },
    { name: 'Digital Twin', href: '/digital-twin', icon: '🧬' },
    { name: 'Health Karma', href: '/karma', icon: '🏆' },
    { name: 'AI Companion', href: '/chat', icon: '🤖' },
  ];

  return (
    <header className="sticky top-0 z-50 bg-slate-900 border-b border-slate-800 text-white font-sans shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
        
        {/* Unified Brand Logo */}
        <div className="flex items-center gap-3 shrink-0">
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-teal-500 to-indigo-600 flex items-center justify-center text-white font-black text-lg shadow-lg shadow-teal-500/20 group-hover:scale-105 transition">
              SS
            </div>
            <div className="flex flex-col">
              <span className="font-extrabold text-base tracking-tight text-white flex items-center gap-1.5">
                SvasthyaSetu
                <span className="px-2 py-0.5 rounded-full text-[9px] font-bold bg-teal-500/20 text-teal-300 border border-teal-500/30">
                  SUPER-APP
                </span>
              </span>
              <span className="text-[10px] font-medium text-slate-400">National Healthcare &amp; Resilience Platform</span>
            </div>
          </Link>

          {/* Backend & ML Live Status Indicator */}
          <div className="hidden xl:flex items-center gap-2 pl-3 border-l border-slate-800 text-[11px] font-medium text-slate-300">
            <span
              className={`w-2 h-2 rounded-full ${
                isBackendOnline === true
                  ? 'bg-emerald-400 animate-pulse ring-4 ring-emerald-400/20'
                  : isBackendOnline === false
                  ? 'bg-amber-400 ring-4 ring-amber-400/20'
                  : 'bg-slate-500'
              }`}
            />
            <span>{isBackendOnline ? 'Live ML Engines Online' : 'Connecting ML Backend...'}</span>
          </div>
        </div>

        {/* Unified Navigation Hubs */}
        <div className="flex items-center gap-1 overflow-x-auto py-1 scrollbar-none">
          {navHubs.map((hub) => {
            const isActive = pathname === hub.href;
            return (
              <Link
                key={hub.name}
                href={hub.href}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition whitespace-nowrap ${
                  isActive
                    ? 'bg-teal-600 text-white shadow-sm shadow-teal-600/30'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <span>{hub.icon}</span>
                <span>{hub.name}</span>
              </Link>
            );
          })}
        </div>

        {/* Emergency SOS Quick Button & User Profile */}
        <div className="flex items-center gap-3 shrink-0">
          <Link
            href="/sos-demo"
            className="hidden sm:flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-rose-600/90 hover:bg-rose-600 text-white text-xs font-bold shadow-md shadow-rose-600/30 hover:scale-105 transition"
          >
            <span className="animate-ping w-1.5 h-1.5 rounded-full bg-white"></span>
            <span>1-Tap SOS</span>
          </Link>

          {isAuthenticated && user ? (
            <div className="flex items-center gap-2.5">
              <div className="hidden sm:flex flex-col text-right">
                <span className="text-xs font-bold text-white">{user.full_name}</span>
                <span className="text-[10px] font-semibold text-teal-400 uppercase tracking-wider">{user.primary_role}</span>
              </div>
              <button
                onClick={logout}
                className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-rose-950 hover:text-rose-300 text-slate-300 text-xs font-semibold transition border border-slate-700"
              >
                Sign Out
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="px-3 py-1.5 rounded-lg text-slate-300 hover:text-white text-xs font-semibold hover:bg-slate-800 transition"
              >
                Sign In
              </Link>
              <Link
                href="/register"
                className="px-3.5 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white text-xs font-bold shadow-md shadow-teal-600/20 transition"
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

