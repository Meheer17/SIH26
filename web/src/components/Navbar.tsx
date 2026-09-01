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

  const roles = user?.mapped_roles || (user ? [user.primary_role] : []);
  const isAdmin = user?.is_admin || roles.includes('SYSTEM_ADMIN');

  // Dynamic role-based navigation links
  const getNavLinks = () => {
    if (!isAuthenticated || !user) {
      return [
        { label: 'Sign In', href: '/' },
        { label: 'Register', href: '/register' },
      ];
    }

    if (isAdmin) {
      return [
        { label: 'Admin Dashboard', href: '/dashboard' },
        { label: '🎖️ RakshakMitra', href: '/rakshak' },
        { label: '🫀 ArogyaSathi', href: '/arogya' },
        { label: '🏥 MediKiosk', href: '/medikiosk' },
        { label: '⚖️ NyayaSahay', href: '/nyaya' },
        { label: 'RBAC Control', href: '/admin/roles' },
      ];
    }

    const links = [];
    if (roles.includes('SOLDIER') || roles.includes('WELFARE_OFFICER')) {
      links.push({ label: '🎖️ RakshakMitra Workspace', href: '/rakshak' });
    }
    if (roles.includes('PATIENT')) {
      links.push({ label: '🫀 ArogyaSathi Health', href: '/arogya' });
    }
    if (roles.includes('PHYSICIAN')) {
      links.push({ label: '🏥 MediKiosk OPD', href: '/medikiosk' });
    }
    if (roles.includes('COUNSELOR') || roles.includes('VICTIM')) {
      links.push({ label: '⚖️ NyayaSahay Legal Aid', href: '/nyaya' });
    }
    return links;
  };

  const navLinks = getNavLinks();

  return (
    <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-md border-b border-slate-200 shadow-sm font-sans">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        
        {/* Brand Logo */}
        <div className="flex items-center gap-3">
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="w-9 h-9 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-black text-lg shadow-md shadow-indigo-600/20 group-hover:bg-indigo-700 transition">
              S
            </div>
            <div className="flex flex-col">
              <span className="font-extrabold text-base tracking-tight text-slate-900 flex items-center gap-2">
                SvasthyaSetu
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-indigo-50 text-indigo-700 border border-indigo-200">
                  SIH 2026
                </span>
              </span>
              <span className="text-[10px] font-medium text-slate-500">Bridge to Health &amp; Defense Platform</span>
            </div>
          </Link>

          {/* Backend Status Indicator */}
          <div className="hidden md:flex items-center gap-1.5 pl-3 border-l border-slate-200 text-[11px] font-medium text-slate-500">
            <span
              className={`w-2 h-2 rounded-full ${
                isBackendOnline === true
                  ? 'bg-emerald-500 animate-pulse'
                  : isBackendOnline === false
                  ? 'bg-rose-500'
                  : 'bg-slate-300'
              }`}
            />
            <span>{isBackendOnline ? 'API Online' : isBackendOnline === false ? 'API Offline' : 'Connecting...'}</span>
          </div>
        </div>

        {/* Role-tailored Navigation Links */}
        <nav className="hidden md:flex items-center gap-1 text-xs font-semibold text-slate-600">
          {navLinks.map((link) => {
            const isActive = pathname === link.href;
            return (
              <Link
                key={link.href}
                href={link.href}
                className={`px-3.5 py-2 rounded-lg transition ${
                  isActive
                    ? 'bg-indigo-50 text-indigo-700 font-bold border border-indigo-100'
                    : 'hover:bg-slate-100 hover:text-slate-900'
                }`}
              >
                {link.label}
              </Link>
            );
          })}
        </nav>

        {/* Auth Actions */}
        <div className="flex items-center gap-3">
          {isAuthenticated && user ? (
            <div className="flex items-center gap-3">
              <div className="hidden sm:flex flex-col text-right">
                <span className="text-xs font-bold text-slate-900">{user.full_name}</span>
                <span className="text-[10px] font-semibold text-indigo-600 uppercase tracking-wider">{user.primary_role}</span>
              </div>
              <button
                onClick={logout}
                className="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-rose-50 hover:text-rose-700 text-slate-700 font-semibold text-xs transition border border-slate-200"
              >
                Sign Out
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/"
                className="px-3.5 py-2 rounded-xl text-slate-700 hover:text-slate-900 font-bold text-xs hover:bg-slate-100 transition"
              >
                Sign In
              </Link>
              <Link
                href="/register"
                className="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md shadow-indigo-600/20 transition hover:scale-[1.02]"
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
