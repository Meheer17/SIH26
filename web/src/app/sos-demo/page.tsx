'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth/AuthContext';
import { AlertNotificationEngine, AlertSeverity, WebAlertRecord } from '@/lib/alerts/alertNotificationEngine';
import { SosEmergencyModule, WebSosEvent, EmergencyFacility, EmergencyContact } from '@/lib/sos/sosEmergencyModule';

export default function SosDemoPage() {
  const { user } = useAuth();
  const [appContext, setAppContext] = useState('arogya_sathi');
  const [isCountdownActive, setIsCountdownActive] = useState(false);
  const [secondsRemaining, setSecondsRemaining] = useState(5);
  const [statusConsole, setStatusConsole] = useState('Emergency command telemetry ready. Click One-Tap SOS or test alert escalation below.');
  const [alerts, setAlerts] = useState<WebAlertRecord[]>([]);

  // Open-Source Geocoding & Emergency Radar State
  const [userCoords, setUserCoords] = useState<{ lat: number; lon: number }>({ lat: 28.6139, lon: 77.2090 });
  const [resolvedAddress, setResolvedAddress] = useState('Kartavya Path, Raisina Hill, New Delhi, Delhi, India');
  const [nearbyHospitals, setNearbyHospitals] = useState<EmergencyFacility[]>([]);
  const [emergencyContacts, setEmergencyContacts] = useState<EmergencyContact[]>([]);
  const [lastSosEvent, setLastSosEvent] = useState<WebSosEvent | null>(null);

  useEffect(() => {
    setAlerts([...AlertNotificationEngine.getActiveAlerts()]);
    loadLocationAndRadar();
  }, []);

  const loadLocationAndRadar = async () => {
    let lat = 28.6139;
    let lon = 77.2090;

    if (typeof window !== 'undefined' && navigator.geolocation) {
      try {
        const pos: GeolocationPosition = await new Promise((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject, {
            enableHighAccuracy: true,
            timeout: 6000,
            maximumAge: 0,
          });
        });
        lat = pos.coords.latitude;
        lon = pos.coords.longitude;
        setUserCoords({ lat, lon });
      } catch (err) {
        console.warn('Geolocation denied or timed out:', err);
      }
    }

    try {
      const [geo, facilities, contacts] = await Promise.all([
        SosEmergencyModule.reverseGeocode(lat, lon),
        SosEmergencyModule.getNearbyFacilities(lat, lon, 5),
        SosEmergencyModule.getContacts(),
      ]);

      if (geo?.display_name) setResolvedAddress(geo.display_name);
      setNearbyHospitals(facilities);
      setEmergencyContacts(contacts);
    } catch (e) {
      console.error('Radar init error:', e);
    }
  };

  const handleTriggerSos = () => {
    setIsCountdownActive(true);
    setStatusConsole('🚨 ONE-TAP SOS ACTIVATED: Audio siren active. 5-second cancellation window in progress...');

    const resolvedName = user?.full_name || 'Emergency Citizen';
    SosEmergencyModule.triggerSos({
      appContext,
      userId: user?.id || 'P-1004',
      userName: resolvedName,
      location: {
        latitude: userCoords.lat,
        longitude: userCoords.lon,
        address_name: resolvedAddress,
      },
      healthSnapshot: {
        heart_rate: 118,
        body_temp_c: 38.9,
        heat_index: 52.4,
        triage_status: 'CRITICAL_EMERGENCY',
      },
      emergencyContacts: emergencyContacts.map((c) => c.phone_number),
      emergencyReason: 'Severe Heatstroke & Respiratory Distress Emergency',
      onCountdown: (sec: number) => {
        setSecondsRemaining(sec);
      },
      onConfirmed: (event: WebSosEvent) => {
        setIsCountdownActive(false);
        setLastSosEvent(event);
        setStatusConsole(
          `🚨 EMERGENCY SOS CONFIRMED & DISPATCHED\nID: ${event.sos_id}\nLocation: ${event.location.address_name}\nResponders Alerted: National Ambulance (108), Regional Trauma Cell, ICE Contacts.`
        );
      },
    });
  };

  const handleCancelSos = () => {
    SosEmergencyModule.cancelSos();
    setIsCountdownActive(false);
    setStatusConsole('✅ Emergency SOS cancelled by user during countdown window. Audio siren silenced.');
  };

  const handleDispatchTier = async (severity: typeof AlertSeverity[keyof typeof AlertSeverity]) => {
    const rec = await AlertNotificationEngine.dispatchAlert({
      appContext,
      severity,
      title: 'Health Threshold Safety Warning',
      message: `Vitals or environmental telemetry exceeded safety thresholds for ${appContext.replace('_', ' ')} context.`,
      recipients: emergencyContacts.map((c) => c.phone_number),
      escalationTimeoutSeconds: 10,
    });

    setAlerts([...AlertNotificationEngine.getActiveAlerts()]);
    setStatusConsole(`Dispatched [${severity}] Alert ID: ${rec.alert_id}\nChannels: ${rec.channels.join(', ')}`);
  };

  return (
    <div className="min-h-screen bg-[#fafaf9] text-stone-900 font-sans pb-16">
      {/* 5s Countdown Cancel Overlay */}
      {isCountdownActive && (
        <div className="fixed inset-0 bg-stone-950/90 backdrop-blur-md z-50 flex flex-col items-center justify-center p-6 text-center space-y-6">
          <div className="w-20 h-20 rounded-2xl bg-rose-600 flex items-center justify-center text-4xl text-white shadow-2xl animate-pulse">
            🚨
          </div>
          <div className="space-y-1 max-w-md">
            <h2 className="text-2xl font-bold text-white tracking-tight">DISPATCHING EMERGENCY SOS</h2>
            <p className="text-xs text-stone-400 font-mono">
              GPS: {resolvedAddress}
            </p>
          </div>
          <div className="text-7xl font-mono font-black text-rose-500 bg-stone-900 border-2 border-rose-500/50 w-28 h-28 rounded-2xl flex items-center justify-center shadow-2xl">
            {secondsRemaining}
          </div>
          <p className="text-xs text-stone-400 max-w-sm">
            Audible emergency beacon active. Dispatching ambulance, verified GPS pin, and clinical vitals snapshot upon expiry.
          </p>
          <button
            onClick={handleCancelSos}
            className="px-8 py-3.5 rounded-xl bg-white hover:bg-stone-100 text-rose-700 font-bold text-xs shadow-2xl transition hover:scale-105"
          >
            CANCEL EMERGENCY SOS (I AM SAFE)
          </button>
        </div>
      )}

      {/* Top Breadcrumb & Status */}
      <div className="border-b border-stone-200 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between text-xs text-stone-500">
          <div className="flex items-center gap-2">
            <Link href="/" className="hover:text-stone-900 transition font-medium">SvasthyaSetu</Link>
            <span>/</span>
            <span className="font-semibold text-stone-900">Emergency Dispatch Hub</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="hidden sm:inline-flex items-center gap-1.5 text-stone-600 font-medium">
              <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse"></span>
              Emergency Dispatch Ready
            </span>
            <Link href="/arogya" className="text-xs font-semibold text-stone-700 hover:text-stone-900 transition">
              &larr; Return to ArogyaSathi
            </Link>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 pt-8 space-y-8">
        
        {/* Module Header */}
        <div className="space-y-2 border-b border-stone-200 pb-6">
          <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-md bg-stone-100 border border-stone-200 text-stone-700 text-xs font-medium">
            <span>🆘</span>
            <span>Emergency Operations Center &amp; Multi-Channel Radar</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-semibold tracking-tight text-stone-900">
            Emergency Dispatch &amp; Radar Terminal
          </h1>
          <p className="text-stone-600 text-sm max-w-2xl leading-relaxed">
            OpenStreetMap GPS reverse geocoding, Overpass trauma facility radar, multi-channel WhatsApp broadcast, and tiered escalation triggers.
          </p>
        </div>

        {/* Location & Nearest Trauma Facility */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
          <div className="bg-white border border-stone-200 rounded-xl p-4 shadow-xs space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-semibold text-stone-900 flex items-center gap-1.5">
                <span>📍</span>
                <span>Verified GPS Geocode</span>
              </span>
              <span className="text-[10px] font-mono font-semibold text-emerald-800 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded">
                Live Resolved
              </span>
            </div>
            <p className="text-stone-700 font-medium leading-relaxed">{resolvedAddress}</p>
            <div className="text-[11px] text-stone-400 font-mono">
              Coordinates: {userCoords.lat.toFixed(4)}° N, {userCoords.lon.toFixed(4)}° E
            </div>
          </div>

          <div className="bg-white border border-stone-200 rounded-xl p-4 shadow-xs space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-semibold text-stone-900 flex items-center gap-1.5">
                <span>🏥</span>
                <span>Nearest Trauma Center (Overpass)</span>
              </span>
              <span className="text-[10px] font-mono font-semibold text-rose-800 bg-rose-50 border border-rose-200 px-2 py-0.5 rounded">
                Trauma Radar
              </span>
            </div>
            {nearbyHospitals.length > 0 ? (
              <div className="space-y-1">
                <p className="font-semibold text-stone-900">{nearbyHospitals[0].name}</p>
                <div className="text-[11px] text-stone-500 font-mono">
                  Distance: {nearbyHospitals[0].distance_km} km &bull; Estimated Ambulance ETA: ~{nearbyHospitals[0].estimated_eta_mins} mins
                </div>
              </div>
            ) : (
              <p className="text-stone-400 italic">Scanning regional hospitals within 10km radius...</p>
            )}
          </div>
        </div>

        {/* Main Emergency Command Trigger */}
        <div className="bg-white border border-stone-200 rounded-xl p-6 sm:p-8 shadow-xs space-y-8">
          
          <div className="space-y-1.5">
            <label className="font-semibold text-stone-700 text-xs">Emergency Alert Context Application</label>
            <select
              value={appContext}
              onChange={(e) => setAppContext(e.target.value)}
              className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-xs font-semibold text-stone-800 focus:outline-none focus:border-stone-900"
            >
              <option value="arogya_sathi">🫀 ArogyaSathi (Heatstroke / Severe Fall Emergency)</option>
              <option value="medikiosk">🏥 MediKiosk (OPD Clinical Triage Red-Flag)</option>
              <option value="rakshak_mitra">🎖️ RakshakMitra (Personnel Crisis &amp; Extreme Fatigue)</option>
              <option value="nyaya_sahay">⚖️ NyayaSahay (Victim Threat &amp; Witness Protection)</option>
            </select>
          </div>

          {/* Large SOS Button */}
          <div className="py-4 flex flex-col items-center justify-center">
            <div className="relative flex items-center justify-center">
              <div className="absolute w-48 h-48 rounded-full bg-rose-500/15 animate-ping pointer-events-none" />
              <button
                onClick={handleTriggerSos}
                className="relative w-40 h-40 rounded-full bg-stone-900 hover:bg-rose-700 active:scale-95 shadow-xl border-4 border-stone-100 flex flex-col items-center justify-center text-white space-y-1 transition duration-200 cursor-pointer"
              >
                <span className="text-2xl">🆘</span>
                <span className="text-base font-bold tracking-wider uppercase">ONE-TAP SOS</span>
                <span className="text-[10px] text-stone-400 font-mono tracking-normal">5s Safety Cancel</span>
              </button>
            </div>
            <p className="text-xs text-stone-400 text-center mt-6">
              Press to activate emergency siren, resolve precise GPS, and broadcast to 108 &amp; ICE contacts.
            </p>
          </div>

          {/* Last Dispatched SOS Event & WhatsApp Link */}
          {lastSosEvent && (
            <div className="bg-emerald-50/70 border border-emerald-200 rounded-xl p-4 space-y-3 text-xs">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-emerald-950 flex items-center gap-1.5">
                  ✓ Active SOS Broadcast Confirmed: {lastSosEvent.sos_id}
                </span>
                <span className="text-[10px] font-mono font-bold bg-emerald-100 text-emerald-900 px-2 py-0.5 rounded">
                  DISPATCHED
                </span>
              </div>

              <div className="flex flex-wrap gap-2 pt-1">
                {lastSosEvent.whatsapp_dispatch_url && (
                  <a
                    href={lastSosEvent.whatsapp_dispatch_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-4 py-2 bg-emerald-700 hover:bg-emerald-800 text-white rounded-lg text-xs font-semibold shadow-xs transition flex items-center gap-1.5"
                  >
                    <span>💬</span>
                    <span>Open WhatsApp SOS Broadcast</span>
                  </a>
                )}
                {lastSosEvent.location?.google_maps_url && (
                  <a
                    href={lastSosEvent.location.google_maps_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-4 py-2 bg-stone-900 hover:bg-stone-800 text-white rounded-lg text-xs font-semibold shadow-xs transition flex items-center gap-1.5"
                  >
                    <span>🗺️</span>
                    <span>View Live Google Map Pin</span>
                  </a>
                )}
              </div>
            </div>
          )}

          {/* Multi-Tier Test Alerts */}
          <div className="space-y-3 border-t border-stone-100 pt-6">
            <span className="text-[10px] font-semibold text-stone-400 uppercase tracking-wider block text-center">
              Dispatch Multi-Tier Test Alerts
            </span>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <button
                onClick={() => handleDispatchTier(AlertSeverity.LOW)}
                className="py-2.5 px-3 rounded-lg bg-stone-50 text-stone-700 border border-stone-200 text-xs font-semibold hover:bg-stone-100 transition"
              >
                LOW (In-App Banner)
              </button>
              <button
                onClick={() => handleDispatchTier(AlertSeverity.MODERATE)}
                className="py-2.5 px-3 rounded-lg bg-amber-50 text-amber-800 border border-amber-200 text-xs font-semibold hover:bg-amber-100 transition"
              >
                MODERATE (Push Alert)
              </button>
              <button
                onClick={() => handleDispatchTier(AlertSeverity.HIGH)}
                className="py-2.5 px-3 rounded-lg bg-orange-50 text-orange-800 border border-orange-200 text-xs font-semibold hover:bg-orange-100 transition"
              >
                HIGH (Push + SMS)
              </button>
              <button
                onClick={() => handleDispatchTier(AlertSeverity.CRITICAL_SOS)}
                className="py-2.5 px-3 rounded-lg bg-rose-50 text-rose-800 border border-rose-200 text-xs font-semibold hover:bg-rose-100 transition"
              >
                CRITICAL (108 + Siren)
              </button>
            </div>
          </div>
        </div>

        {/* Telemetry Console */}
        <div className="bg-stone-900 text-stone-100 border border-stone-800 rounded-xl p-4 font-mono text-xs whitespace-pre-wrap leading-relaxed shadow-xs">
          <div className="text-[10px] uppercase text-stone-400 font-bold mb-1 tracking-wider">Console Telemetry Log:</div>
          {statusConsole}
        </div>

        {/* Active Banners Display */}
        <div className="bg-white border border-stone-200 rounded-xl p-6 space-y-4 shadow-xs">
          <div className="flex items-center justify-between border-b border-stone-200 pb-3">
            <h2 className="text-sm font-semibold text-stone-900">Active Notification Banners</h2>
            <span className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold bg-stone-100 text-stone-700">
              {alerts.length} Active
            </span>
          </div>

          {alerts.length === 0 ? (
            <p className="text-xs text-stone-400 italic py-2">No active alert banners currently queued.</p>
          ) : (
            <div className="space-y-2">
              {alerts.map((rec, idx) => (
                <div key={idx} className="p-3.5 rounded-lg bg-stone-50 border border-stone-200 flex items-center justify-between text-xs">
                  <div className="space-y-0.5">
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-bold text-rose-700">[{rec.severity}]</span>
                      <span className="font-semibold text-stone-900">{rec.title}</span>
                    </div>
                    <p className="text-stone-500 text-[11px]">{rec.message}</p>
                  </div>
                  {!rec.is_acknowledged && (
                    <button
                      onClick={() => {
                        AlertNotificationEngine.acknowledgeAlert(rec.alert_id);
                        setAlerts([...AlertNotificationEngine.getActiveAlerts()]);
                      }}
                      className="px-3 py-1 rounded-md bg-stone-900 text-white text-[10px] font-semibold hover:bg-stone-800 transition shadow-xs"
                    >
                      Acknowledge
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

