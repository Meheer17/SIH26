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

      setStatus(`Single Invoke Save Succeeded!\nKey: [${rec.collection}:${rec.key}]\nEncrypted: ${rec.is_encrypted} | Sync Queued: ${rec.is_synced ? 'No' : 'Yes'}`);
      refreshQueue();
    } catch (err: unknown) {
      setStatus(`Error saving: ${err instanceof Error ? err.message : String(err)}`);
    }
  };

  const handleGet = async () => {
    const data = await SvasthyaStorage.get({
      collection,
      key,
      isSensitive: isEncrypt,
    });

    if (data) {
      setStatus(`Decrypted Record Successfully Retrieved!\nKey: [${collection}:${key}]\nData: ${JSON.stringify(data, null, 2)}`);
    } else {
      setStatus(`Record [${key}] not found in collection [${collection}].`);
    }
  };

  const handleSync = async () => {
    setStatus('Triggering background offline sync dispatcher...');
    const res = await SvasthyaStorage.syncAllPending(async () => {
      await new Promise((r) => setTimeout(r, 300));
      return true;
    });

    setStatus(`Offline Sync Complete!\nSynced ${res.synced_count} records to backend.\nRemaining in offline queue: ${res.remaining}`);
    refreshQueue();
  };

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-slate-50 text-slate-900 p-6 sm:p-8 font-sans">
      <div className="max-w-3xl mx-auto space-y-6">
        <header className="flex items-center justify-between border-b border-slate-200 pb-4">
          <div>
            <h1 className="text-2xl font-black text-slate-900 flex items-center gap-2">
              <span>Offline-First Local Storage SDK</span>
            </h1>
            <p className="text-xs text-slate-500">Encrypted Local DB (AES-256) &amp; Offline Queue Sync Engine</p>
          </div>
          <Link href="/chat" className="px-4 py-2 rounded-xl bg-white border border-slate-200 text-slate-700 hover:bg-slate-100 text-xs font-bold shadow-sm">
            &larr; Back to AI Chat
          </Link>
        </header>

        <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Target Application Collection</label>
            <select
              value={collection}
              onChange={(e) => setCollection(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-indigo-500 font-semibold"
            >
              <option value={StorageCollection.arogyaVitals}>ArogyaSathi (Vitals &amp; Heat Index)</option>
              <option value={StorageCollection.medikioskIntake}>MediKiosk (Clinical OPD Intake)</option>
              <option value={StorageCollection.rakshakBurnout}>RakshakMitra (Burnout Assessment)</option>
              <option value={StorageCollection.nyayaDistress}>NyayaSahay (Victim Distress Score)</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Record Key</label>
            <input
              type="text"
              value={key}
              onChange={(e) => setKey(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-indigo-500 font-mono"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Payload Content (JSON or String)</label>
            <textarea
              rows={4}
              value={payload}
              onChange={(e) => setPayload(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 font-mono text-xs focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div className="flex items-center gap-6 pt-1">
            <label className="flex items-center gap-2 text-xs font-semibold text-slate-700 cursor-pointer">
              <input
                type="checkbox"
                checked={isEncrypt}
                onChange={(e) => setIsEncrypt(e.target.checked)}
                className="w-4 h-4 rounded text-emerald-600 border-slate-300"
              />
              <span>AES-256 Encryption at Rest</span>
            </label>

            <label className="flex items-center gap-2 text-xs font-semibold text-slate-700 cursor-pointer">
              <input
                type="checkbox"
                checked={isSyncOnline}
                onChange={(e) => setIsSyncOnline(e.target.checked)}
                className="w-4 h-4 rounded text-indigo-600 border-slate-300"
              />
              <span>Queue for Offline Auto-Sync</span>
            </label>
          </div>

          <div className="grid grid-cols-2 gap-3 pt-2">
            <button
              onClick={handleSave}
              className="py-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-md shadow-emerald-600/20"
            >
              Save Local Record
            </button>
            <button
              onClick={handleGet}
              className="py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md shadow-indigo-600/20"
            >
              Retrieve &amp; Decrypt Record
            </button>
          </div>
        </div>

        {/* Console Display */}
        <div className="bg-white border border-slate-200 rounded-2xl p-4 font-mono text-xs text-indigo-900 whitespace-pre-wrap leading-relaxed shadow-sm">
          {status}
        </div>

        {/* Queue Display */}
        <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-bold text-slate-900">Offline Sync Queue ({pendingQueue.length})</h2>
            <button
              onClick={handleSync}
              disabled={pendingQueue.length === 0}
              className="px-4 py-2 rounded-xl bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold shadow-sm disabled:opacity-50"
            >
              Trigger Backend Sync Now
            </button>
          </div>

          {pendingQueue.length === 0 ? (
            <p className="text-xs text-slate-400 italic">All local records are synchronized with backend API.</p>
          ) : (
            <div className="space-y-2 max-h-60 overflow-y-auto">
              {pendingQueue.map((item, idx) => (
                <div key={idx} className="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between text-xs">
                  <div>
                    <span className="font-bold text-slate-900">[{item.collection}]</span>{' '}
                    <span className="text-slate-600">{item.key}</span>
                  </div>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-100 text-amber-800 border border-amber-200">
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
