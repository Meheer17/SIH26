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
    app: 'ArogyaSathi',
    color: 'bg-emerald-50 text-emerald-800 border-emerald-200 hover:border-emerald-400',
    badge: 'bg-emerald-100 text-emerald-700',
  },
  {
    name: 'Dr. Ananya Sharma',
    role: 'PHYSICIAN',
    email: 'dr_sharma@hospital.org',
    app: 'MediKiosk',
    color: 'bg-sky-50 text-sky-800 border-sky-200 hover:border-sky-400',
    badge: 'bg-sky-100 text-sky-700',
  },
  {
    name: 'Capt. Vikram Verma',
    role: 'SOLDIER',
    email: 'capt_verma@forces.gov.in',
    app: 'RakshakMitra',
    color: 'bg-amber-50 text-amber-800 border-amber-200 hover:border-amber-400',
    badge: 'bg-amber-100 text-amber-700',
  },
  {
    name: 'Rajesh Kumar',
    role: 'COUNSELOR',
    email: 'legal_officer@district.gov.in',
    app: 'NyayaSahay',
    color: 'bg-purple-50 text-purple-800 border-purple-200 hover:border-purple-400',
    badge: 'bg-purple-100 text-purple-700',
  },
  {
    name: 'Admin Director',
    role: 'SYSTEM_ADMIN',
    email: 'admin@svasthya.gov.in',
    app: 'System Admin',
    color: 'bg-rose-50 text-rose-800 border-rose-200 hover:border-rose-400',
    badge: 'bg-rose-100 text-rose-700',
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
      const loggedUser = await login(email, pass);
      const roles = loggedUser?.mapped_roles || [loggedUser?.primary_role];
      const hasAdmin = loggedUser?.is_admin || roles.includes('SYSTEM_ADMIN');

      if (hasAdmin) {
        router.push('/dashboard');
      } else if (roles.includes('PATIENT')) {
        router.push('/arogya');
      } else if (roles.includes('PHYSICIAN')) {
        router.push('/medikiosk');
      } else if (roles.includes('SOLDIER') || roles.includes('WELFARE_OFFICER')) {
        router.push('/rakshak');
      } else if (roles.includes('COUNSELOR') || roles.includes('VICTIM')) {
        router.push('/nyaya');
      } else {
        router.push('/dashboard');
      }
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Login failed. Please verify credentials.');
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
    <div className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center p-6 bg-slate-50 font-sans">
      <div className="max-w-4xl w-full space-y-6">
        
        {/* Header Breadcrumb */}
        <div className="flex items-center justify-between">
          <Link href="/" className="text-xs font-bold text-slate-500 hover:text-indigo-600 transition flex items-center gap-1">
            &larr; Back to Homepage
          </Link>
          <div className="text-xs text-slate-500 font-mono">
            Demo DB Password: <code className="text-emerald-700 font-bold">demo123456</code>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          
          {/* Left Column: Pre-seeded Test Accounts Display */}
          <div className="lg:col-span-6 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
            <div>
              <span className="inline-block px-3 py-1 rounded-full text-[11px] font-bold bg-indigo-50 text-indigo-700 border border-indigo-200 uppercase tracking-wider">
                Pre-seeded DB Test Accounts
              </span>
              <h2 className="text-xl font-black text-slate-900 mt-2">One-Tap Sign In Cards</h2>
              <p className="text-xs text-slate-500">Click any account to auto-authenticate with JWT tokens</p>
            </div>

            <div className="space-y-2.5">
              {DEMO_TEST_ACCOUNTS.map((acc) => (
                <button
                  key={acc.email}
                  type="button"
                  onClick={() => handleQuickDemoSelect(acc.email)}
                  className={`w-full p-3.5 rounded-xl text-left border transition duration-200 shadow-sm hover:shadow group ${acc.color}`}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-900 group-hover:text-indigo-700 transition">{acc.name}</span>
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border border-slate-200 ${acc.badge}`}>
                      {acc.app}
                    </span>
                  </div>
                  <div className="flex items-center justify-between mt-1 text-[11px]">
                    <span className="font-mono text-slate-600">{acc.email}</span>
                    <span className="text-indigo-600 font-bold text-[10px]">One-Tap Login &rarr;</span>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Right Column: Manual Sign In Form */}
          <div className="lg:col-span-6 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-5 flex flex-col justify-between">
            <div className="space-y-4">
              <div>
                <h2 className="text-2xl font-black text-slate-900 tracking-tight">Manual Sign In</h2>
                <p className="text-xs text-slate-500">Or enter custom registered credentials below</p>
              </div>

              {error && (
                <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-medium">
                  {error}
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Email or Phone</label>
                  <input
                    type="text"
                    required
                    value={emailOrPhone}
                    onChange={(e) => setEmailOrPhone(e.target.value)}
                    placeholder="e.g. dr_sharma@hospital.org"
                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 placeholder-slate-400 text-sm focus:outline-none focus:border-indigo-500 focus:bg-white transition"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Password</label>
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 placeholder-slate-400 text-sm focus:outline-none focus:border-indigo-500 focus:bg-white transition"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-md shadow-indigo-600/20 transition disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {loading ? <span>Authenticating...</span> : <span>Sign In to AI Portal</span>}
                </button>
              </form>
            </div>

            <div className="pt-4 border-t border-slate-100 text-center text-xs text-slate-500">
              Need a new account?{' '}
              <Link href="/register" className="text-indigo-600 font-bold hover:underline">
                Register now
              </Link>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
