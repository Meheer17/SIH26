'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';

const DEMO_ROLES = [
  { role: 'Patient', email: 'arogya_user@example.com', badge: '🫀 ArogyaSathi', color: 'from-emerald-500/20 to-teal-500/10 border-emerald-500/30 text-emerald-400' },
  { role: 'OPD Doctor', email: 'dr_sharma@hospital.org', badge: '🏥 MediKiosk', color: 'from-sky-500/20 to-indigo-500/10 border-sky-500/30 text-sky-400' },
  { role: 'Armed Forces Officer', email: 'capt_verma@forces.gov.in', badge: '🎖️ RakshakMitra', color: 'from-amber-500/20 to-orange-500/10 border-amber-500/30 text-amber-400' },
  { role: 'SC/ST Legal Counselor', email: 'legal_officer@district.gov.in', badge: '⚖️ NyayaSahay', color: 'from-purple-500/20 to-pink-500/10 border-purple-500/30 text-purple-400' },
];

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();
  const [emailOrPhone, setEmailOrPhone] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (email: string, pass: string) => {
    setLoading(true);
    setError('');

    try {
      await login(email, pass);
      router.push('/chat');
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        // Soft fallback for demo mode
        router.push('/chat');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    handleLogin(emailOrPhone, password);
  };

  const handleQuickDemoSelect = (email: string) => {
    setEmailOrPhone(email);
    setPassword('demo123456');
    handleLogin(email, 'demo123456');
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-slate-950 text-slate-100 font-sans relative overflow-hidden">
      {/* Dynamic Background Glows */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-indigo-600/20 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-emerald-600/20 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-md w-full bg-slate-900/80 border border-slate-800 rounded-3xl p-8 shadow-2xl backdrop-blur-2xl space-y-6 relative z-10">
        <div className="text-center space-y-2">
          <div className="inline-block px-3.5 py-1 rounded-full text-xs font-bold tracking-wider bg-indigo-500/10 text-indigo-400 border border-indigo-500/30 uppercase">
            SvasthyaSetu Unified AI Platform
          </div>
          <h1 className="text-3xl font-extrabold text-white tracking-tight">Sign In</h1>
          <p className="text-xs text-slate-400">Access ArogyaSathi, MediKiosk, RakshakMitra & NyayaSahay</p>
        </div>

        {/* Quick Demo Role Picker */}
        <div className="space-y-2">
          <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider text-center">
            ⚡ Quick Demo One-Tap Sign In
          </label>
          <div className="grid grid-cols-2 gap-2">
            {DEMO_ROLES.map((item) => (
              <button
                key={item.role}
                type="button"
                onClick={() => handleQuickDemoSelect(item.email)}
                className={`p-2.5 rounded-xl text-left bg-gradient-to-br ${item.color} border hover:scale-[1.02] transition duration-200`}
              >
                <div className="text-xs font-bold">{item.badge}</div>
                <div className="text-[10px] text-slate-300 font-medium">{item.role}</div>
              </button>
            ))}
          </div>
        </div>

        <div className="relative flex py-1 items-center">
          <div className="flex-grow border-t border-slate-800"></div>
          <span className="flex-shrink mx-3 text-[10px] font-bold text-slate-500 uppercase tracking-wider">or email login</span>
          <div className="flex-grow border-t border-slate-800"></div>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-rose-950/50 border border-rose-500/30 text-rose-300 text-xs font-medium">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1">Email or Phone</label>
            <input
              type="text"
              required
              value={emailOrPhone}
              onChange={(e) => setEmailOrPhone(e.target.value)}
              placeholder="e.g. user@example.com or 9876543210"
              className="w-full px-4 py-3 rounded-xl bg-slate-950/80 border border-slate-800 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-indigo-500 transition"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1">Password</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full px-4 py-3 rounded-xl bg-slate-950/80 border border-slate-800 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-indigo-500 transition"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold text-sm transition shadow-lg shadow-indigo-600/30 disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {loading ? (
              <span>Authenticating...</span>
            ) : (
              <span>Sign In to AI Portal</span>
            )}
          </button>
        </form>

        <div className="pt-3 border-t border-slate-800 text-center text-xs text-slate-400">
          Need a new account?{' '}
          <Link href="/register" className="text-indigo-400 font-semibold hover:underline">
            Register now
          </Link>
        </div>
      </div>
    </div>
  );
}
