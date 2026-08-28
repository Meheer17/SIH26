'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';

const DEMO_TEST_ACCOUNTS = [
  {
    name: 'Rahul Sharma',
    role: 'PATIENT',
    email: 'arogya_user@example.com',
    app: '🫀 ArogyaSathi',
    color: 'from-emerald-500/20 via-teal-500/10 to-transparent border-emerald-500/30 text-emerald-400',
  },
  {
    name: 'Dr. Ananya Sharma',
    role: 'PHYSICIAN',
    email: 'dr_sharma@hospital.org',
    app: '🏥 MediKiosk',
    color: 'from-sky-500/20 via-indigo-500/10 to-transparent border-sky-500/30 text-sky-400',
  },
  {
    name: 'Capt. Vikram Verma',
    role: 'SOLDIER',
    email: 'capt_verma@forces.gov.in',
    app: '🎖️ RakshakMitra',
    color: 'from-amber-500/20 via-orange-500/10 to-transparent border-amber-500/30 text-amber-400',
  },
  {
    name: 'Rajesh Kumar',
    role: 'COUNSELOR',
    email: 'legal_officer@district.gov.in',
    app: '⚖️ NyayaSahay',
    color: 'from-purple-500/20 via-pink-500/10 to-transparent border-purple-500/30 text-purple-400',
  },
  {
    name: 'Admin Director',
    role: 'SYSTEM_ADMIN',
    email: 'admin@svasthya.gov.in',
    app: '🔒 System Admin',
    color: 'from-rose-500/20 via-indigo-500/10 to-transparent border-rose-500/30 text-rose-400',
  },
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
    <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-slate-950 text-slate-100 font-sans relative overflow-hidden">
      {/* Background Glow Effects */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-indigo-600/20 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-emerald-600/20 rounded-full blur-3xl pointer-events-none" />

      {/* Navigation Return Header */}
      <div className="w-full max-w-4xl flex items-center justify-between mb-6 z-10">
        <Link href="/" className="text-xs font-bold text-slate-400 hover:text-white flex items-center gap-1.5">
          ← Back to Homepage
        </Link>
        <div className="text-xs text-slate-500 font-mono">
          Pre-seeded DB Password: <code className="text-emerald-400">demo123456</code>
        </div>
      </div>

      <div className="max-w-4xl w-full grid grid-cols-1 lg:grid-cols-12 gap-6 relative z-10">
        {/* Left Panel - Pre-seeded Test Accounts Display */}
        <div className="lg:col-span-6 bg-slate-900/80 border border-slate-800 rounded-3xl p-6 shadow-2xl backdrop-blur-2xl space-y-4">
          <div>
            <div className="inline-block px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
              ⚡ Pre-seeded DB Test Accounts
            </div>
            <h2 className="text-xl font-extrabold text-white mt-1">One-Tap Sign In Cards</h2>
            <p className="text-xs text-slate-400">Click any account card to auto-fill credentials &amp; authenticate</p>
          </div>

          <div className="space-y-2.5">
            {DEMO_TEST_ACCOUNTS.map((acc) => (
              <button
                key={acc.email}
                type="button"
                onClick={() => handleQuickDemoSelect(acc.email)}
                className={`w-full p-3.5 rounded-2xl text-left bg-gradient-to-r ${acc.color} border hover:scale-[1.02] transition duration-200 shadow-md group`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-white group-hover:text-indigo-300 transition">{acc.name}</span>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-950/80 border border-slate-800">
                    {acc.app}
                  </span>
                </div>
                <div className="flex items-center justify-between mt-1 text-[11px] text-slate-400">
                  <span className="font-mono text-slate-300">{acc.email}</span>
                  <span className="text-indigo-400 font-semibold text-[10px]">One-Tap Login →</span>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Right Panel - Manual Sign In Form */}
        <div className="lg:col-span-6 bg-slate-900/80 border border-slate-800 rounded-3xl p-6 shadow-2xl backdrop-blur-2xl space-y-5 flex flex-col justify-between">
          <div className="space-y-4">
            <div className="space-y-1">
              <h2 className="text-2xl font-extrabold text-white tracking-tight">Manual Sign In</h2>
              <p className="text-xs text-slate-400">Or enter custom registered credentials below</p>
            </div>

            {error && (
              <div className="p-3 rounded-xl bg-rose-950/50 border border-rose-500/30 text-rose-300 text-xs font-medium">
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
                  placeholder="e.g. arogya_user@example.com"
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
                {loading ? <span>Authenticating...</span> : <span>Sign In to AI Portal</span>}
              </button>
            </form>
          </div>

          <div className="pt-3 border-t border-slate-800 text-center text-xs text-slate-400">
            Don&apos;t have an account?{' '}
            <Link href="/register" className="text-indigo-400 font-semibold hover:underline">
              Register now
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
