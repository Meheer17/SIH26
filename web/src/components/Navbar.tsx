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
    { name: 'Diagnostics', href: '/screening', icon: '🔬' },
    { name: 'ASHA & Community', href: '/asha', icon: '👩‍⚕️' },
    { name: 'Mind & Wellness', href: '/rakshak', icon: '🧠' },
    { name: 'Safety & Vault', href: '/covert-sos', icon: '🛡️' },
    { name: 'Digital Twin', href: '/digital-twin', icon: '🧬' },
    { name: 'Health Karma', href: '/karma', icon: '🏆' },
    { name: 'AI Companion', href: '/chat', icon: '💬' },
  ];

  return (
    <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-md border-b border-slate-200/80 text-slate-800 font-sans shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
        
        {/* Medical Platform Brand Logo */}
        <div className="flex items-center gap-3 shrink-0">
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-teal-600 to-cyan-600 flex items-center justify-center text-white font-black text-base shadow-sm shadow-teal-600/20 group-hover:scale-105 transition">
              ✚
            </div>
            <div className="flex flex-col">
              <span className="font-extrabold text-base tracking-tight text-slate-900 flex items-center gap-1.5">
                SvasthyaSetu
                <span className="px-2 py-0.5 rounded-full text-[9px] font-bold bg-teal-50 text-teal-700 border border-teal-200">
                  HEALTH PORTAL
                </span>
              </span>
              <span className="text-[10px] font-medium text-slate-500">National Healthcare &amp; Resilience Platform</span>
            </div>
          </Link>

          {/* Backend & ML Live Status Indicator */}
          <div className="hidden xl:flex items-center gap-2 pl-3 border-l border-slate-200 text-[11px] font-medium text-slate-600">
            <span
              className={`w-2 h-2 rounded-full ${
                isBackendOnline === true
                  ? 'bg-emerald-500 animate-pulse ring-4 ring-emerald-500/20'
                  : isBackendOnline === false
                  ? 'bg-amber-500 ring-4 ring-amber-500/20'
                  : 'bg-slate-300'
              }`}
            />
            <span>{isBackendOnline ? 'Live ML Engines Online' : 'Connecting ML Backend...'}</span>
          </div>
        </div>

        {/* Clean Navigation Hubs */}
        <div className="flex items-center gap-1 overflow-x-auto py-1 scrollbar-none">
          {navHubs.map((hub) => {
            const isActive = pathname === hub.href;
            return (
              <Link
                key={hub.name}
                href={hub.href}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition whitespace-nowrap ${
                  isActive
                    ? 'bg-teal-50 text-teal-700 border border-teal-200/80 shadow-xs'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
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
            className="hidden sm:flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold shadow-xs hover:shadow-sm transition"
          >
            <span className="animate-ping w-1.5 h-1.5 rounded-full bg-white"></span>
            <span>Emergency SOS</span>
          </Link>

          {isAuthenticated && user ? (
            <div className="flex items-center gap-2.5">
              <div className="hidden sm:flex flex-col text-right">
                <span className="text-xs font-bold text-slate-900">{user.full_name}</span>
                <span className="text-[10px] font-semibold text-teal-600 uppercase tracking-wider">{user.primary_role}</span>
              </div>
              <button
                onClick={logout}
                className="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-rose-50 hover:text-rose-600 text-slate-700 text-xs font-semibold transition border border-slate-200"
              >
                Sign Out
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="px-3 py-1.5 rounded-lg text-slate-700 hover:text-slate-900 text-xs font-semibold hover:bg-slate-100 transition"
              >
                Sign In
              </Link>
              <Link
                href="/register"
                className="px-3.5 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold shadow-xs transition"
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

