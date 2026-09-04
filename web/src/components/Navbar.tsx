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

  const psModules = [
    { id: 'SIH26181', name: 'ArogyaSathi', icon: '🫀', href: '/arogya', badge: 'Qualcomm' },
    { id: 'SIH26047', name: 'MediKiosk', icon: '🏥', href: '/medikiosk', badge: 'Ayush' },
    { id: 'SIH26186', name: 'RakshakMitra', icon: '🎖️', href: '/rakshak', badge: 'MHA' },
    { id: 'SIH26094', name: 'NyayaSahay', icon: '⚖️', href: '/nyaya', badge: 'MoSJE' },
  ];

  return (
    <header className="sticky top-0 z-50 bg-white border-b border-slate-200 font-sans shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
        
        {/* Brand Logo */}
        <div className="flex items-center gap-3 shrink-0">
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="w-8 h-8 rounded-lg bg-teal-600 flex items-center justify-center text-white font-black text-base shadow-xs group-hover:bg-teal-700 transition">
              SS
            </div>
            <div className="flex flex-col">
              <span className="font-bold text-sm tracking-tight text-slate-900 flex items-center gap-1.5">
                SvasthyaSetu
                <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-700 border border-slate-200">
                  SIH 2026
                </span>
              </span>
              <span className="text-[10px] font-medium text-slate-500">Bridge to Health &amp; Defense Platform</span>
            </div>
          </Link>

          {/* Backend Status Indicator */}
          <div className="hidden lg:flex items-center gap-1.5 pl-3 border-l border-slate-200 text-[11px] font-medium text-slate-600">
            <span
              className={`w-2 h-2 rounded-full ${
                isBackendOnline === true
                  ? 'bg-emerald-500 animate-pulse'
                  : isBackendOnline === false
                  ? 'bg-amber-500'
                  : 'bg-slate-300'
              }`}
            />
            <span>{isBackendOnline ? 'API Connected' : isBackendOnline === false ? 'Live Simulation' : 'Connecting...'}</span>
          </div>
        </div>

        {/* Problem Statement Switcher Buttons */}
        <div className="flex items-center gap-1 overflow-x-auto py-1 scrollbar-none">
          {psModules.map((ps) => {
            const isActive = pathname === ps.href;
            return (
              <Link
                key={ps.id}
                href={ps.href}
                className={`px-2.5 py-1.5 rounded-md text-xs font-semibold flex items-center gap-1.5 transition whitespace-nowrap ${
                  isActive
                    ? 'bg-slate-900 text-white shadow-xs'
                    : 'bg-slate-50 text-slate-700 hover:bg-slate-100 border border-slate-200'
                }`}
              >
                <span>{ps.icon}</span>
                <span>{ps.name}</span>
                <span
                  className={`text-[9px] px-1 py-0.2 rounded font-mono ${
                    isActive ? 'bg-slate-800 text-slate-200' : 'bg-slate-200 text-slate-600'
                  }`}
                >
                  {ps.id}
                </span>
              </Link>
            );
          })}
        </div>

        {/* Auth Actions & User Info */}
        <div className="flex items-center gap-3">
          {isAuthenticated && user ? (
            <div className="flex items-center gap-3">
              <div className="hidden sm:flex flex-col text-right">
                <span className="text-xs font-bold text-slate-900">{user.full_name}</span>
                <span className="text-[10px] font-semibold text-teal-600 uppercase tracking-wider">{user.primary_role}</span>
              </div>
              <button
                onClick={logout}
                className="px-3.5 py-2 rounded-lg bg-slate-100 hover:bg-rose-50 hover:text-rose-700 text-slate-700 font-semibold text-xs transition border border-slate-200"
              >
                Sign Out
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="px-3.5 py-2 rounded-lg text-slate-700 hover:text-slate-900 font-bold text-xs hover:bg-slate-100 transition"
              >
                Sign In
              </Link>
              <Link
                href="/register"
                className="px-4 py-2 rounded-lg bg-teal-600 hover:bg-teal-700 text-white font-bold text-xs shadow-xs transition"
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
