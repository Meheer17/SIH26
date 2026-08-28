'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext';

export default function RegisterPage() {
  const router = useRouter();
  const { register } = useAuth();
  const [fullName, setFullName] = useState('');
  const [emailOrPhone, setEmailOrPhone] = useState('');
  const [password, setPassword] = useState('');
  const [primaryRole, setPrimaryRole] = useState('PATIENT');
  const [appContext, setAppContext] = useState('arogya_sathi');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      await register({
        full_name: fullName,
        email_or_phone: emailOrPhone,
        password,
        primary_role: primaryRole as any,
        app_context: appContext as any,
      });
      router.push('/chat');
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        router.push('/chat');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center p-6 bg-slate-50 font-sans">
      <div className="max-w-md w-full bg-white border border-slate-200 rounded-2xl p-8 shadow-sm space-y-6">
        
        {/* Header Title */}
        <div className="text-center space-y-1">
          <span className="inline-block px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-indigo-50 text-indigo-700 border border-indigo-200">
            Create Platform Account
          </span>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">User Registration</h1>
          <p className="text-xs text-slate-500">Access ArogyaSathi, MediKiosk, RakshakMitra &amp; NyayaSahay</p>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-medium">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Full Name</label>
            <input
              type="text"
              required
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="e.g. Dr. Ramesh Kumar"
              className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 placeholder-slate-400 text-sm focus:outline-none focus:border-indigo-500 focus:bg-white transition"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Email or Phone Number</label>
            <input
              type="text"
              required
              value={emailOrPhone}
              onChange={(e) => setEmailOrPhone(e.target.value)}
              placeholder="e.g. ramesh@hospital.org"
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

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Primary Role</label>
              <select
                value={primaryRole}
                onChange={(e) => setPrimaryRole(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-indigo-500"
              >
                <option value="PATIENT">Patient</option>
                <option value="PHYSICIAN">Physician</option>
                <option value="SOLDIER">Soldier</option>
                <option value="COUNSELOR">Counselor</option>
                <option value="SYSTEM_ADMIN">System Admin</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">App Domain</label>
              <select
                value={appContext}
                onChange={(e) => setAppContext(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-indigo-500"
              >
                <option value="arogya_sathi">ArogyaSathi</option>
                <option value="medikiosk">MediKiosk</option>
                <option value="rakshak_mitra">RakshakMitra</option>
                <option value="nyaya_sahay">NyayaSahay</option>
              </select>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-md shadow-indigo-600/20 transition disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {loading ? <span>Creating Account...</span> : <span>Create &amp; Launch Portal</span>}
          </button>
        </form>

        <div className="pt-4 border-t border-slate-100 text-center text-xs text-slate-500">
          Already registered?{' '}
          <Link href="/login" className="text-indigo-600 font-bold hover:underline">
            Sign In
          </Link>
        </div>
      </div>
    </div>
  );
}
