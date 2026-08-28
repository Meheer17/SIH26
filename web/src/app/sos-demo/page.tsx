'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { AlertNotificationEngine, AlertSeverity, WebAlertRecord } from '@/lib/alerts/alertNotificationEngine';
import { SosEmergencyModule, WebSosEvent } from '@/lib/sos/sosEmergencyModule';

export default function SosDemoPage() {
  const [appContext, setAppContext] = useState('arogya_sathi');
  const [isCountdownActive, setIsCountdownActive] = useState(false);
  const [secondsRemaining, setSecondsRemaining] = useState(5);
  const [statusConsole, setStatusConsole] = useState('System Ready. Click One-Tap SOS or dispatch alerts below.');
  const [alerts, setAlerts] = useState<WebAlertRecord[]>([]);

  useEffect(() => {
    setAlerts([...AlertNotificationEngine.getActiveAlerts()]);
  }, []);

  const handleTriggerSos = () => {
    setIsCountdownActive(true);
    setStatusConsole('ONE-TAP SOS ACTIVATED! 5-second cancellation window active...');

    SosEmergencyModule.triggerSos({
      appContext,
      userId: 'P-1004',
      userName: 'Rahul Verma',
      location: {
        latitude: 32.2432,
        longitude: 77.1892,
        address_name: 'Lahaul Spiti High Altitude Outpost',
      },
      healthSnapshot: {
        heart_rate: 115,
        body_temp_c: 38.9,
        heat_index: 52.4,
        triage_status: 'CRITICAL_EMERGENCY',
      },
      emergencyContacts: ['+919876543210', '+919123456789'],
      emergencyReason: 'Severe Heatstroke & Respiratory Distress Emergency',
      onCountdown: (sec) => {
        setSecondsRemaining(sec);
      },
      onConfirmed: (event: WebSosEvent) => {
        setIsCountdownActive(false);
        setStatusConsole(`EMERGENCY SOS CONFIRMED & DISPATCHED! ID: ${event.sos_id}\nResponders Notified: Local Ambulance (108), Emergency Cell, Caregivers.`);
      },
    });
  };

  const handleCancelSos = () => {
    SosEmergencyModule.cancelSos();
    setIsCountdownActive(false);
    setStatusConsole('Emergency SOS cancelled by user during countdown.');
  };

  const handleDispatchTier = async (severity: typeof AlertSeverity[keyof typeof AlertSeverity]) => {
    const rec = await AlertNotificationEngine.dispatchAlert({
      appContext,
      severity,
      title: 'Health Threshold Warning',
      message: `Vitals crossed safety limits for ${appContext} context.`,
      recipients: ['+919876543210'],
      escalationTimeoutSeconds: 10,
    });

    setAlerts([...AlertNotificationEngine.getActiveAlerts()]);
    setStatusConsole(`Dispatched [${severity}] Alert ID: ${rec.alert_id}\nChannels: ${rec.channels.join(', ')}`);
  };

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-slate-50 text-slate-900 p-6 sm:p-8 font-sans relative overflow-hidden">
      {/* 5s Countdown Cancel Overlay */}
      {isCountdownActive && (
        <div className="fixed inset-0 bg-slate-900/80 backdrop-blur-md z-50 flex flex-col items-center justify-center p-6 text-center space-y-6">
          <div className="w-24 h-24 rounded-full bg-rose-500/20 border-2 border-rose-500 flex items-center justify-center text-xl font-black text-rose-500 animate-bounce uppercase">
            SOS
          </div>
          <div>
            <h2 className="text-2xl font-black text-white">DISPATCHING EMERGENCY SOS</h2>
            <p className="text-xs text-slate-300 mt-1">Captured GPS Coordinates &amp; Latest Vitals Snapshot</p>
          </div>
          <div className="text-7xl font-black text-rose-500 tracking-tighter">{secondsRemaining}</div>
          <button
            onClick={handleCancelSos}
            className="px-8 py-4 rounded-2xl bg-white text-rose-600 font-bold text-sm shadow-xl transition hover:scale-105"
          >
            CANCEL EMERGENCY SOS (5s Window)
          </button>
        </div>
      )}

      <div className="max-w-3xl mx-auto space-y-6">
        <header className="flex items-center justify-between border-b border-slate-200 pb-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 flex items-center gap-2">
              <span>One-Tap SOS &amp; Multi-Tier Alerts</span>
            </h1>
            <p className="text-xs text-slate-500">GPS + Vitals Snapshot | Multi-Channel Escalation Routing</p>
          </div>
          <Link href="/chat" className="px-4 py-2 rounded-xl bg-white border border-slate-200 text-slate-700 hover:bg-slate-100 text-xs font-bold shadow-sm">
            &larr; Back to AI Chat
          </Link>
        </header>

        <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-6">
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Target Application Context</label>
            <select
              value={appContext}
              onChange={(e) => setAppContext(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-rose-500 font-semibold"
            >
              <option value="arogya_sathi">ArogyaSathi (Heatstroke / Fall Alert)</option>
              <option value="medikiosk">MediKiosk (OPD Triage Red-Flag)</option>
              <option value="rakshak_mitra">RakshakMitra (Personnel Crisis)</option>
              <option value="nyaya_sahay">NyayaSahay (Victim Threat Intimidation)</option>
            </select>
          </div>

          {/* Red SOS Button */}
          <div className="py-6 flex flex-col items-center justify-center">
            <button
              onClick={handleTriggerSos}
              className="w-44 h-44 rounded-full bg-rose-600 hover:bg-rose-700 active:scale-95 shadow-xl shadow-rose-600/30 border-4 border-rose-200 flex flex-col items-center justify-center text-white space-y-1 transition duration-200"
            >
              <span className="text-xl font-black tracking-widest uppercase">ONE-TAP SOS</span>
            </button>
          </div>

          {/* Alert Buttons */}
          <div className="space-y-2">
            <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider text-center">
              Dispatch Multi-Tier Test Alerts
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <button
                onClick={() => handleDispatchTier(AlertSeverity.LOW)}
                className="py-2.5 px-3 rounded-xl bg-sky-50 text-sky-700 border border-sky-200 text-xs font-bold hover:bg-sky-100"
              >
                LOW (Banner)
              </button>
              <button
                onClick={() => handleDispatchTier(AlertSeverity.MODERATE)}
                className="py-2.5 px-3 rounded-xl bg-amber-50 text-amber-700 border border-amber-200 text-xs font-bold hover:bg-amber-100"
              >
                MODERATE (Push)
              </button>
              <button
                onClick={() => handleDispatchTier(AlertSeverity.HIGH)}
                className="py-2.5 px-3 rounded-xl bg-orange-50 text-orange-700 border border-orange-200 text-xs font-bold hover:bg-orange-100"
              >
                HIGH (Push+SMS)
              </button>
              <button
                onClick={() => handleDispatchTier(AlertSeverity.CRITICAL_SOS)}
                className="py-2.5 px-3 rounded-xl bg-rose-50 text-rose-700 border border-rose-200 text-xs font-bold hover:bg-rose-100"
              >
                CRITICAL (All+Call)
              </button>
            </div>
          </div>
        </div>

        {/* Console Display */}
        <div className="bg-white border border-slate-200 rounded-2xl p-4 font-mono text-xs text-rose-900 whitespace-pre-wrap leading-relaxed shadow-sm">
          {statusConsole}
        </div>

        {/* Active Banners Display */}
        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
          <h2 className="text-sm font-bold text-slate-900">Active In-App Notification Banners ({alerts.length})</h2>
          {alerts.length === 0 ? (
            <p className="text-xs text-slate-400 italic">No active alert banners.</p>
          ) : (
            <div className="space-y-2">
              {alerts.map((rec, idx) => (
                <div key={idx} className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between text-xs">
                  <div>
                    <span className="font-bold text-rose-700">[{rec.severity}]</span>{' '}
                    <span className="text-slate-900 font-bold">{rec.title}</span>
                    <p className="text-slate-500 text-[11px] mt-0.5">{rec.message}</p>
                  </div>
                  {!rec.is_acknowledged && (
                    <button
                      onClick={() => {
                        AlertNotificationEngine.acknowledgeAlert(rec.alert_id);
                        setAlerts([...AlertNotificationEngine.getActiveAlerts()]);
                      }}
                      className="px-3 py-1 rounded-lg bg-emerald-100 text-emerald-800 border border-emerald-300 font-bold text-[10px]"
                    >
                      ACK
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
