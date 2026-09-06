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
    { id: 'SIH26181', name: 'ArogyaSathi', desc: 'Disaster Health', href: '/arogya' },
    { id: 'SIH26047', name: 'MediKiosk', desc: 'Clinical OPD', href: '/medikiosk' },
    { id: 'SIH26186', name: 'RakshakMitra', desc: 'Defense Welfare', href: '/rakshak' },
    { id: 'SIH26094', name: 'NyayaSahay', desc: 'Legal Support', href: '/nyaya' },
  ];

  return (
    <header className="sticky top-0 z-50 bg-stone-50/90 backdrop-blur-md border-b border-stone-200/80 font-sans">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-15 flex items-center justify-between gap-4">
        
        {/* Brand Identity */}
        <div className="flex items-center gap-3 shrink-0">
          <Link href="/" className="flex items-center gap-2.5 group">
            <span className="w-7 h-7 rounded-md bg-stone-900 flex items-center justify-center text-stone-100 font-bold text-xs tracking-tight shadow-xs group-hover:bg-stone-800 transition">
              SS
            </span>
            <div className="flex flex-col">
              <span className="font-semibold text-sm tracking-tight text-stone-900 group-hover:text-stone-700 transition">
                SvasthyaSetu
              </span>
              <span className="text-[10px] text-stone-500 font-normal">Health &amp; Defense Platform</span>
            </div>
          </Link>

          {/* Discreet Health Status */}
          <div className="hidden lg:flex items-center gap-1.5 pl-3 border-l border-stone-200 text-[11px] text-stone-500 font-normal">
            <span
              className={`w-1.5 h-1.5 rounded-full ${
                isBackendOnline === true
                  ? 'bg-emerald-600'
                  : isBackendOnline === false
                  ? 'bg-amber-500'
                  : 'bg-stone-300'
              }`}
            />
            <span>{isBackendOnline ? 'Operational' : isBackendOnline === false ? 'Simulation' : 'Connecting'}</span>
          </div>
        </div>

        {/* Minimal Core Application Switcher */}
        <nav className="flex items-center gap-1 bg-stone-200/60 p-1 rounded-lg">
          {psModules.map((ps) => {
            const isActive = pathname === ps.href;
            return (
              <Link
                key={ps.id}
                href={ps.href}
                className={`px-3 py-1.5 rounded-md text-xs font-medium transition whitespace-nowrap ${
                  isActive
                    ? 'bg-white text-stone-900 shadow-xs'
                    : 'text-stone-600 hover:text-stone-900 hover:bg-stone-200/40'
                }`}
              >
                <span>{ps.name}</span>
              </Link>
            );
          })}
        </nav>

        {/* User Account Controls */}
        <div className="flex items-center gap-3">
          {isAuthenticated && user ? (
            <div className="flex items-center gap-3">
              <div className="hidden sm:flex flex-col text-right">
                <span className="text-xs font-semibold text-stone-900">{user.full_name}</span>
                <span className="text-[10px] text-stone-500">{user.primary_role}</span>
              </div>
              <button
                onClick={logout}
                className="px-3 py-1.5 rounded-md text-xs font-medium text-stone-600 hover:text-stone-900 hover:bg-stone-200/50 border border-stone-300/70 transition"
              >
                Sign out
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="px-3 py-1.5 rounded-md text-stone-700 hover:text-stone-900 font-medium text-xs hover:bg-stone-200/50 transition"
              >
                Sign in
              </Link>
              <Link
                href="/register"
                className="px-3.5 py-1.5 rounded-md bg-stone-900 hover:bg-stone-800 text-stone-50 font-medium text-xs shadow-xs transition"
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
