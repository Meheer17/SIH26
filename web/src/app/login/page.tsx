'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';

const DEMO_PERSONAS = [
  {
    name: 'Rahul Sharma',
    role: 'Patient (ArogyaSathi)',
    email: 'arogya_user@example.com',
    target: '/arogya',
  },
  {
    name: 'Dr. Ananya Sharma',
    role: 'Physician (MediKiosk)',
    email: 'dr_sharma@hospital.org',
    target: '/medikiosk',
  },
  {
    name: 'Capt. Vikram Verma',
    role: 'Defense Officer (RakshakMitra)',
    email: 'capt_verma@forces.gov.in',
    target: '/rakshak',
  },
  {
    name: 'Rajesh Kumar',
    role: 'Legal Counselor (NyayaSahay)',
    email: 'legal_officer@district.gov.in',
    target: '/nyaya',
  },
  {
    name: 'Director Admin',
    role: 'System Administrator',
    email: 'admin@svasthya.gov.in',
    target: '/dashboard',
  },
];

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();
  const [emailOrPhone, setEmailOrPhone] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showDemoAccess, setShowDemoAccess] = useState(false);

  const handleLogin = async (email: string, pass: string) => {
    setLoading(true);
    setError('');

    try {
      const loggedUser: any = await login(email, pass);
      const roles = loggedUser?.mapped_roles || [loggedUser?.primary_role];
      const hasAdmin = loggedUser?.is_admin || roles?.includes('SYSTEM_ADMIN');

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
    <div className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center p-4 sm:p-6 font-sans text-stone-900">
      <div className="max-w-md w-full space-y-6">
        
        {/* Back Link */}
        <div>
          <Link href="/" className="text-xs text-stone-500 hover:text-stone-900 font-medium transition flex items-center gap-1">
            &larr; Back to overview
          </Link>
        </div>

        {/* Primary Clean Sign In Card */}
        <div className="bg-white border border-stone-200/90 rounded-2xl p-6 sm:p-8 shadow-sm space-y-6">
          <div className="space-y-1">
            <h1 className="text-xl font-semibold tracking-tight text-stone-900">Sign in to SvasthyaSetu</h1>
            <p className="text-xs text-stone-500">Access your health, clinical, defense, or legal dashboard</p>
          </div>

          {error && (
            <div className="p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs font-medium">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1">
              <label className="block text-xs font-medium text-stone-700">Email address or mobile</label>
              <input
                type="text"
                required
                value={emailOrPhone}
                onChange={(e) => setEmailOrPhone(e.target.value)}
                placeholder="name@organization.gov.in"
                className="w-full px-3.5 py-2.5 rounded-lg bg-stone-50 border border-stone-200 text-stone-900 placeholder-stone-400 text-xs focus:outline-none focus:border-stone-500 focus:bg-white transition"
              />
            </div>

            <div className="space-y-1">
              <div className="flex items-center justify-between">
                <label className="block text-xs font-medium text-stone-700">Password</label>
              </div>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-3.5 py-2.5 rounded-lg bg-stone-50 border border-stone-200 text-stone-900 placeholder-stone-400 text-xs focus:outline-none focus:border-stone-500 focus:bg-white transition"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 rounded-lg bg-stone-900 hover:bg-stone-800 text-stone-50 font-medium text-xs shadow-xs transition disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {loading ? 'Authenticating...' : 'Sign In'}
            </button>
          </form>

          <div className="pt-2 border-t border-stone-100 flex items-center justify-between text-xs text-stone-500">
            <span>New user?</span>
            <Link href="/register" className="text-stone-900 font-medium hover:underline">
              Create an account
            </Link>
          </div>
        </div>

        {/* Unobtrusive Evaluator Demo Access Accordion */}
        <div className="bg-stone-50/80 border border-stone-200/80 rounded-xl overflow-hidden">
          <button
            type="button"
            onClick={() => setShowDemoAccess(!showDemoAccess)}
            className="w-full px-4 py-3 text-left flex items-center justify-between text-xs font-medium text-stone-600 hover:text-stone-900 hover:bg-stone-100/60 transition"
          >
            <span className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-stone-400"></span>
              Prototype Evaluator Demo Personas
            </span>
            <span className="text-[11px] text-stone-400 font-mono">
              {showDemoAccess ? 'Hide &minus;' : 'View 1-tap accounts &plus;'}
            </span>
          </button>

          {showDemoAccess && (
            <div className="px-4 pb-4 pt-1 border-t border-stone-200/60 space-y-2">
              <p className="text-[11px] text-stone-500 leading-relaxed">
                Click any persona below to authenticate with pre-seeded demonstration records (Password: <code className="font-mono text-stone-700">demo123456</code>):
              </p>
              <div className="grid grid-cols-1 gap-1.5 pt-1">
                {DEMO_PERSONAS.map((p) => (
                  <button
                    key={p.email}
                    type="button"
                    onClick={() => handleQuickDemoSelect(p.email)}
                    className="w-full px-3 py-2 rounded-lg bg-white border border-stone-200/80 hover:border-stone-400 text-left flex items-center justify-between transition shadow-2xs group"
                  >
                    <div>
                      <span className="text-xs font-medium text-stone-900 block group-hover:text-stone-700">{p.name}</span>
                      <span className="text-[10px] text-stone-500">{p.role}</span>
                    </div>
                    <span className="text-[11px] text-stone-500 font-medium group-hover:text-stone-900">
                      Sign In &rarr;
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

      </div>
    </div>
  );
}
