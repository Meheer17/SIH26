'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { authApi, ConsentRecord } from '@/lib/auth/authApi';

export default function ConsentPage() {
  const { user, loading: authLoading } = useAuth();
  const [consents, setConsents] = useState<ConsentRecord[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  
  // New Grant Form State
  const [granteeName, setGranteeName] = useState('');
  const [purpose, setPurpose] = useState('Clinical OPD Consultation & History Review');
  const [durationDays, setDurationDays] = useState(30);
  const [granting, setGranting] = useState(false);
  const [showGrantModal, setShowGrantModal] = useState(false);

  const fetchConsents = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await authApi.listMyConsents();
      setConsents(data);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Failed to fetch consent records');
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchConsents();
    }
  }, [user]);

  const handleGrantConsent = async (e: React.FormEvent) => {
    e.preventDefault();
    setGranting(true);
    setError('');
    try {
      await authApi.grantConsent({
        grantee_id: `spec_${Date.now()}`,
        grantee_name: granteeName,
        purpose,
        scopes: ['vitals:read', 'medical_history:read', 'notes:write'],
        duration_days: Number(durationDays),
      });
      setShowGrantModal(false);
      setGranteeName('');
      await fetchConsents();
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Failed to grant consent');
      }
    } finally {
      setGranting(false);
    }
  };

  const handleRevoke = async (consentId: string) => {
    try {
      await authApi.revokeConsent(consentId);
      await fetchConsents();
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Failed to revoke consent');
      }
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-[calc(100vh-4rem)] flex items-center justify-center bg-slate-50 text-slate-600 font-sans">
        <div className="flex items-center gap-3">
          <svg className="animate-spin h-5 w-5 text-indigo-600" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span className="text-sm font-bold">Loading Consent Engine...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-slate-50 text-slate-900 font-sans p-6 sm:p-8 space-y-8">
      <div className="max-w-5xl mx-auto space-y-8">
        
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div>
            <div className="inline-block px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-indigo-50 text-indigo-700 border border-indigo-200 mb-2">
              DPDP Act 2023 Compliant Engine
            </div>
            <h1 className="text-2xl font-black text-slate-900 tracking-tight">Granular Consent Management</h1>
            <p className="text-xs text-slate-500 mt-1">
              Control, grant, and instantly revoke data sharing permissions with doctors, counselors, &amp; officers.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowGrantModal(true)}
              className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition flex items-center gap-1.5"
            >
              <span>+ Grant New Consent</span>
            </button>
            <Link
              href="/dashboard"
              className="px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold border border-slate-200 transition"
            >
              &larr; Back
            </Link>
          </div>
        </div>

        {error && (
          <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-bold">
            {error}
          </div>
        )}

        {/* Consents List */}
        <div className="space-y-4">
          <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500">
            Active Data Sharing Grants ({consents.length})
          </h2>

          {consents.length === 0 ? (
            <div className="bg-white border border-slate-200 rounded-2xl p-8 text-center space-y-2 shadow-sm">
              <p className="text-sm font-bold text-slate-700">No active consent records found.</p>
              <p className="text-xs text-slate-500">Your health data is completely private and not shared with anyone.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {consents.map((c) => (
                <div
                  key={c.id}
                  className={`p-6 rounded-2xl border transition shadow-sm space-y-4 ${
                    c.is_revoked
                      ? 'bg-slate-100 border-slate-200 opacity-75'
                      : 'bg-white border-slate-200 hover:border-indigo-300'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-slate-900 text-base">
                      {c.grantee_name}
                    </span>
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase border ${
                        c.is_revoked
                          ? 'bg-rose-50 text-rose-700 border-rose-200'
                          : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      }`}
                    >
                      {c.is_revoked ? 'REVOKED' : 'ACTIVE'}
                    </span>
                  </div>

                  <div>
                    <p className="text-xs font-semibold text-slate-700">{c.purpose}</p>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {c.scopes.map((s: string) => (
                        <span key={s} className="px-2 py-0.5 rounded bg-slate-100 text-slate-600 text-[10px] font-mono border border-slate-200">
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                    <span>Expires: {new Date(c.expires_at).toLocaleDateString()}</span>
                    {!c.is_revoked && (
                      <button
                        onClick={() => handleRevoke(c.id)}
                        className="px-3 py-1 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 text-xs font-bold transition"
                      >
                        Revoke Consent
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Modal for New Consent */}
        {showGrantModal && (
          <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-6 z-50">
            <div className="max-w-md w-full bg-white border border-slate-200 rounded-2xl p-6 space-y-6 shadow-2xl">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Grant Data Consent</h3>
                <p className="text-xs text-slate-500 mt-0.5">Allow a medical or welfare specialist to access specific record scopes.</p>
              </div>

              <form onSubmit={handleGrantConsent} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Specialist Name / ID</label>
                  <input
                    type="text"
                    required
                    value={granteeName}
                    onChange={(e) => setGranteeName(e.target.value)}
                    placeholder="e.g. Dr. Ananya Roy (AIIMS OPD)"
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 placeholder-slate-400 text-sm focus:outline-none focus:border-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Authorized Purpose</label>
                  <input
                    type="text"
                    required
                    value={purpose}
                    onChange={(e) => setPurpose(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-sm focus:outline-none focus:border-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Duration (Days)</label>
                  <select
                    value={durationDays}
                    onChange={(e) => setDurationDays(Number(e.target.value))}
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-sm focus:outline-none focus:border-indigo-500"
                  >
                    <option value={7}>7 Days (Temporary OPD Intake)</option>
                    <option value={30}>30 Days (Standard Care)</option>
                    <option value={90}>90 Days (Extended Welfare Assessment)</option>
                  </select>
                </div>

                <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => setShowGrantModal(false)}
                    className="px-4 py-2 rounded-xl bg-slate-100 text-slate-700 text-xs font-bold hover:bg-slate-200"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={granting}
                    className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-md shadow-indigo-600/20 disabled:opacity-50"
                  >
                    {granting ? 'Granting...' : 'Confirm Consent'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
