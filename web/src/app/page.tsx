'use client';

import { useState } from 'react';
import { checkBackendHealth, HealthResponse } from '@/lib/api/apiClient';
import { API_BASE_URL } from '@/lib/api/endpoints';

export default function Home() {
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [healthData, setHealthData] = useState<HealthResponse | null>(null);
  const [errorMsg, setErrorMsg] = useState<string>('');

  const testConnection = async () => {
    setStatus('loading');
    setErrorMsg('');
    try {
      const data = await checkBackendHealth();
      setHealthData(data);
      setStatus('success');
    } catch (err: unknown) {
      setStatus('error');
      if (err instanceof Error) {
        setErrorMsg(err.message);
      } else {
        setErrorMsg('Failed to connect to FastAPI backend.');
      }
    }
  };

  return (
    <main className="min-h-screen bg-slate-950 text-slate-100 flex flex-col items-center justify-center p-6 font-sans">
      <div className="max-w-4xl w-full space-y-8">
        
        {/* Header Badge */}
        <div className="flex justify-center">
          <span className="px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide uppercase bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 shadow-sm">
            SIH 2026 Unified Platform Architecture
          </span>
        </div>

        {/* Hero Section */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl sm:text-5xl font-extrabold tracking-tight bg-gradient-to-r from-white via-slate-200 to-indigo-300 bg-clip-text text-transparent">
            Next.js Web Application
          </h1>
          <p className="text-slate-400 max-w-xl mx-auto text-base sm:text-lg">
            Pre-configured frontend app router with TypeScript, Tailwind CSS, and a clean backend API client setup.
          </p>
        </div>

        {/* Backend API Tester Card */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 sm:p-8 backdrop-blur-xl shadow-2xl space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-800">
            <div>
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-indigo-500 animate-pulse"></span>
                FastAPI Backend Connectivity
              </h2>
              <p className="text-xs text-slate-400 mt-1 font-mono">
                Target Endpoint: <code className="text-indigo-300">{API_BASE_URL}/health</code>
              </p>
            </div>
            <button
              onClick={testConnection}
              disabled={status === 'loading'}
              className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-medium transition-all shadow-lg shadow-indigo-600/30 disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {status === 'loading' ? (
                <>
                  <svg className="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>Pinging API...</span>
                </>
              ) : (
                <>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                  <span>Test API Connection</span>
                </>
              )}
            </button>
          </div>

          {/* Connection Result */}
          {status === 'idle' && (
            <div className="p-4 rounded-xl bg-slate-950/50 border border-slate-800 text-slate-400 text-sm flex items-center gap-3">
              <span className="w-2 h-2 rounded-full bg-slate-500"></span>
              Click &quot;Test API Connection&quot; above to verify FastAPI server state.
            </div>
          )}

          {status === 'success' && healthData && (
            <div className="p-5 rounded-xl bg-emerald-950/30 border border-emerald-500/30 text-emerald-300 space-y-2 text-sm">
              <div className="flex items-center gap-2 font-semibold text-emerald-400 text-base">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
                </svg>
                Backend Server Online
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 pt-2 text-xs font-mono text-emerald-200/80">
                <div><span className="text-slate-400">Service:</span> {healthData.service}</div>
                <div><span className="text-slate-400">Uptime:</span> {healthData.uptime_seconds}s</div>
                <div><span className="text-slate-400">Version:</span> {healthData.version}</div>
              </div>
            </div>
          )}

          {status === 'error' && (
            <div className="p-5 rounded-xl bg-rose-950/30 border border-rose-500/30 text-rose-300 space-y-1 text-sm">
              <div className="flex items-center gap-2 font-semibold text-rose-400 text-base">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Connection Failed
              </div>
              <p className="text-xs font-mono text-rose-200/80">{errorMsg}</p>
            </div>
          )}
        </div>

        {/* Architecture Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="p-5 rounded-2xl bg-slate-900/50 border border-slate-800 space-y-2">
            <div className="text-xs font-bold uppercase tracking-wider text-indigo-400">App (Flutter)</div>
            <h3 className="font-semibold text-white">Mobile Application</h3>
            <p className="text-xs text-slate-400">
              Structured in <code className="text-slate-200">/app</code> with Dart <code className="text-slate-200">ApiClient</code>, endpoint resolution, &amp; exception wrappers.
            </p>
          </div>
          <div className="p-5 rounded-2xl bg-slate-900/50 border border-slate-800 space-y-2">
            <div className="text-xs font-bold uppercase tracking-wider text-indigo-400">Web (Next.js)</div>
            <h3 className="font-semibold text-white">Website Application</h3>
            <p className="text-xs text-slate-400">
              Structured in <code className="text-slate-200">/web</code> with App Router, TypeScript <code className="text-slate-200">apiClient</code>, and Tailwind CSS.
            </p>
          </div>
          <div className="p-5 rounded-2xl bg-slate-900/50 border border-slate-800 space-y-2">
            <div className="text-xs font-bold uppercase tracking-wider text-indigo-400">Backend (FastAPI)</div>
            <h3 className="font-semibold text-white">Python API Service</h3>
            <p className="text-xs text-slate-400">
              Structured in <code className="text-slate-200">/backend</code> with CORS middleware, Pydantic settings, and v1 router.
            </p>
          </div>
        </div>

      </div>
    </main>
  );
}
