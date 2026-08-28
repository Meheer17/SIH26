'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { SvasthyaStorage, StorageCollection, StorageRecord } from '@/lib/storage/svasthyaStorageSdk';

export default function StorageDemoPage() {
  const [collection, setCollection] = useState<string>(StorageCollection.arogyaVitals);
  const [key, setKey] = useState('vitals_sample_101');
  const [payload, setPayload] = useState('{\n  "heart_rate": 84,\n  "body_temp_c": 37.8,\n  "location": "Lahaul Outpost"\n}');
  const [isEncrypt, setIsEncrypt] = useState(true);
  const [isSyncOnline, setIsSyncOnline] = useState(true);
  const [status, setStatus] = useState('SDK Ready. Test single-invoke local saving, encryption, and sync.');
  const [pendingQueue, setPendingQueue] = useState<StorageRecord[]>([]);

  useEffect(() => {
    refreshQueue();
  }, []);

  const refreshQueue = () => {
    setPendingQueue(SvasthyaStorage.getUnsyncedRecords());
  };

  const handleSave = async () => {
    try {
      let parsedData: Record<string, unknown>;
      try {
        parsedData = JSON.parse(payload);
      } catch {
        parsedData = { raw_content: payload };
      }

      const rec = await SvasthyaStorage.save({
        collection,
        key,
        data: parsedData,
        isSensitive: isEncrypt,
        syncOnline: isSyncOnline,
      });

      setStatus(`✅ Single Invoke Save Succeeded!\nKey: [${rec.collection}:${rec.key}]\nEncrypted: ${rec.is_encrypted} | Sync Queued: ${rec.is_synced ? 'No' : 'Yes'}`);
      refreshQueue();
    } catch (err: unknown) {
      setStatus(`❌ Error saving: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleGet = async () => {
    const data = await SvasthyaStorage.get({
      collection,
      key,
      isSensitive: isEncrypt,
    });

    if (data) {
      setStatus(`🔓 Decrypted Record Successfully Retrieved!\nKey: [${collection}:${key}]\nData: ${JSON.stringify(data, null, 2)}`);
    } else {
      setStatus(`⚠️ Record [${key}] not found in collection [${collection}].`);
    }
  };

  const handleSync = async () => {
    setStatus('🔄 Triggering background offline sync dispatcher...');
    const res = await SvasthyaStorage.syncAllPending(async () => {
      await new Promise((r) => setTimeout(r, 300));
      return true; // Mock successful upload to backend
    });

    setStatus(`✨ Offline Sync Complete!\nSynced ${res.synced_count} records to backend.\nRemaining in offline queue: ${res.remaining}`);
    refreshQueue();
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-8 font-sans">
      <div className="max-w-3xl mx-auto space-y-6">
        <header className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div>
            <h1 className="text-2xl font-extrabold tracking-tight text-white flex items-center gap-2">
              <span>💾 Offline Local Storage SDK</span>
            </h1>
            <p className="text-xs text-slate-400">Encrypted Local DB (AES-256) &amp; Offline Queue Sync Engine</p>
          </div>
          <Link href="/chat" className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-semibold">
            ← Back to AI Chat
          </Link>
        </header>

        <div className="bg-slate-900/90 border border-slate-800 rounded-3xl p-6 shadow-2xl space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Target Application Collection</label>
            <select
              value={collection}
              onChange={(e) => setCollection(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white text-sm focus:outline-none focus:border-indigo-500"
            >
              <option value={StorageCollection.arogyaVitals}>🫀 ArogyaSathi (Vitals &amp; Heat Index)</option>
              <option value={StorageCollection.medikioskIntake}>🏥 MediKiosk (Clinical OPD Intake)</option>
              <option value={StorageCollection.rakshakBurnout}>🎖️ RakshakMitra (Burnout Assessment)</option>
              <option value={StorageCollection.nyayaDistress}>⚖️ NyayaSahay (Victim Distress Score)</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Record Key</label>
            <input
              type="text"
              value={key}
              onChange={(e) => setKey(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white text-sm focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Payload Content (JSON or String)</label>
            <textarea
              rows={4}
              value={payload}
              onChange={(e) => setPayload(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-emerald-400 font-mono text-xs focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div className="flex items-center gap-6 pt-2">
            <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer">
              <input
                type="checkbox"
                checked={isEncrypt}
                onChange={(e) => setIsEncrypt(e.target.checked)}
                className="w-4 h-4 rounded bg-slate-950 border-slate-800 text-emerald-500"
              />
              <span>AES-256 Encryption at Rest</span>
            </label>

            <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer">
              <input
                type="checkbox"
                checked={isSyncOnline}
                onChange={(e) => setIsSyncOnline(e.target.checked)}
                className="w-4 h-4 rounded bg-slate-950 border-slate-800 text-indigo-500"
              />
              <span>Queue for Offline Auto-Sync</span>
            </label>
          </div>

          <div className="grid grid-cols-2 gap-3 pt-2">
            <button
              onClick={handleSave}
              className="py-3.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-xs shadow-lg shadow-emerald-600/30"
            >
              💾 Save Local Record
            </button>
            <button
              onClick={handleGet}
              className="py-3.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs shadow-lg shadow-indigo-600/30"
            >
              🔓 Retrieve &amp; Decrypt Local Record
            </button>
          </div>
        </div>

        {/* Status Console Display */}
        <div className="bg-slate-950 border border-slate-800 rounded-2xl p-4 font-mono text-xs text-sky-400 whitespace-pre-wrap leading-relaxed shadow-inner">
          {status}
        </div>

        {/* Offline Queue Section */}
        <div className="bg-slate-900/60 border border-slate-800 rounded-3xl p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-bold text-white flex items-center gap-2">
              <span>Offline Sync Queue ({pendingQueue.length})</span>
            </h2>
            <button
              onClick={handleSync}
              disabled={pendingQueue.length === 0}
              className="px-4 py-2 rounded-xl bg-amber-500/20 hover:bg-amber-500/30 text-amber-400 border border-amber-500/30 text-xs font-semibold disabled:opacity-50"
            >
              🔄 Trigger Backend Sync Now
            </button>
          </div>

          {pendingQueue.length === 0 ? (
            <p className="text-xs text-slate-500 italic">All local records are synchronized with backend API.</p>
          ) : (
            <div className="space-y-2 max-h-60 overflow-y-auto">
              {pendingQueue.map((item, idx) => (
                <div key={idx} className="p-3 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between text-xs">
                  <div>
                    <span className="font-bold text-slate-300">[{item.collection}]</span>{' '}
                    <span className="text-slate-400">{item.key}</span>
                  </div>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    PENDING SYNC
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
