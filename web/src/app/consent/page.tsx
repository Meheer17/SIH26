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
      <div className="min-h-screen flex items-center justify-center bg-slate-950 text-slate-300 font-sans">
        <div className="flex items-center gap-3">
          <svg className="animate-spin h-5 w-5 text-indigo-500" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span className="text-sm font-medium">Loading Consent Engine...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans p-6">
      <div className="max-w-5xl mx-auto space-y-8">
        
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
          <div>
            <div className="inline-block px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 mb-2">
              DPDP Act 2023 Compliant Engine
            </div>
            <h1 className="text-2xl font-extrabold text-white">Granular Consent Management</h1>
            <p className="text-xs text-slate-400 mt-1">
              Control, grant, and instantly revoke data sharing permissions with doctors, counselors, &amp; officers.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowGrantModal(true)}
              className="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold shadow-lg shadow-indigo-600/30 transition flex items-center gap-1.5"
            >
              <span>+ Grant New Consent</span>
            </button>
            <Link
              href="/dashboard"
              className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold transition"
            >
              &larr; Back
            </Link>
          </div>
        </div>

        {error && (
          <div className="p-4 rounded-xl bg-rose-950/40 border border-rose-500/30 text-rose-300 text-xs font-medium">
            {error}
          </div>
        )}

        {/* Consents List */}
        <div className="space-y-4">
          <h2 className="text-sm font-bold uppercase tracking-wider text-slate-400">
            Active Data Sharing Grants ({consents.length})
          </h2>

          {consents.length === 0 ? (
            <div className="bg-slate-900/40 border border-slate-800 rounded-2xl p-8 text-center space-y-2">
              <p className="text-sm text-slate-400">No active consent records found.</p>
              <p className="text-xs text-slate-500">Your health data is completely private and not shared with anyone.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {consents.map((c) => (
                <div
                  key={c.id}
                  className={`p-6 rounded-2xl border backdrop-blur-lg space-y-4 transition ${
                    c.is_revoked
                      ? 'bg-slate-950/50 border-slate-800/80 opacity-60'
                      : 'bg-slate-900/80 border-indigo-500/30 hover:border-indigo-500/50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-white text-base flex items-center gap-2">
                      <span>👨‍⚕️</span> {c.grantee_name}
                    </span>
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase border ${
                        c.is_revoked
                          ? 'bg-rose-500/10 text-rose-400 border-rose-500/20'
                          : 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                      }`}
                    >
                      {c.is_revoked ? 'REVOKED' : 'ACTIVE'}
                    </span>
                  </div>

                  <div>
                    <p className="text-xs font-semibold text-slate-300">{c.purpose}</p>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {c.scopes.map((s) => (
                        <span key={s} className="px-2 py-0.5 rounded bg-slate-950 text-slate-400 text-[10px] font-mono border border-slate-800">
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="pt-2 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
                    <span>Expires: {new Date(c.expires_at).toLocaleDateString()}</span>
                    {!c.is_revoked && (
                      <button
                        onClick={() => handleRevoke(c.id)}
                        className="px-3 py-1 rounded-lg bg-rose-600/20 hover:bg-rose-600 text-rose-300 hover:text-white text-xs font-semibold transition"
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
          <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-6 z-50">
            <div className="max-w-md w-full bg-slate-900 border border-slate-800 rounded-3xl p-6 space-y-6 shadow-2xl">
              <div>
                <h3 className="text-lg font-bold text-white">Grant Data Consent</h3>
                <p className="text-xs text-slate-400 mt-0.5">Allow a medical or welfare specialist to access specific record scopes.</p>
              </div>

              <form onSubmit={handleGrantConsent} className="space-y-4">
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Specialist Name / ID</label>
                  <input
                    type="text"
                    required
                    value={granteeName}
                    onChange={(e) => setGranteeName(e.target.value)}
                    placeholder="e.g. Dr. Ananya Roy (AIIMS OPD)"
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Authorized Purpose</label>
                  <input
                    type="text"
                    required
                    value={purpose}
                    onChange={(e) => setPurpose(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-white text-sm focus:outline-none focus:border-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Duration (Days)</label>
                  <select
                    value={durationDays}
                    onChange={(e) => setDurationDays(Number(e.target.value))}
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-white text-sm focus:outline-none focus:border-indigo-500"
                  >
                    <option value={7}>7 Days (Temporary OPD Intake)</option>
                    <option value={30}>30 Days (Standard Care)</option>
                    <option value={90}>90 Days (Extended Welfare Assessment)</option>
                  </select>
                </div>

                <div className="flex justify-end gap-3 pt-4 border-t border-slate-800">
                  <button
                    type="button"
                    onClick={() => setShowGrantModal(false)}
                    className="px-4 py-2 rounded-xl bg-slate-800 text-slate-300 text-xs font-semibold"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={granting}
                    className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold disabled:opacity-50"
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
