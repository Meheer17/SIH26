"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Mic, MicOff, Volume2, Sparkles, Languages, RefreshCw, CheckCircle2, HeartPulse } from "lucide-react";

export default function VoiceJournalPage() {
  const [isRecording, setIsRecording] = useState(false);
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const [transcript, setTranscript] = useState("");
  const [language, setLanguage] = useState("hi-IN");
  const [loading, setLoading] = useState(false);
  const [journalResult, setJournalResult] = useState<any>(null);
  const [history, setHistory] = useState<any[]>([]);

  useEffect(() => {
    let interval: any = null;
    if (isRecording) {
      interval = setInterval(() => {
        setRecordingSeconds((prev) => prev + 1);
      }, 1000);
    } else {
      clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [isRecording]);

  const handleStartRecording = () => {
    setIsRecording(true);
    setRecordingSeconds(0);
    setTranscript("");
    setJournalResult(null);
  };

  const handleStopRecording = async () => {
    setIsRecording(false);
    const demoTranscripts: Record<string, string> = {
      "hi-IN": "आज मुझे बहुत थकान लग रही है और सिर में हल्का सा दर्द है। गर्मी बहुत ज़्यादा है।",
      "ta-IN": "இன்று எனக்கு மிகவும் சோர்வாக இருக்கிறது மற்றும் லேசான தலைவலி உள்ளது.",
      "en-IN": "I am feeling quite exhausted today and have a mild headache due to severe heat."
    };
    const text = demoTranscripts[language] || demoTranscripts["hi-IN"];
    setTranscript(text);

    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/apps/voice-journal", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          transcript: text,
          language: language,
          audio_duration_sec: recordingSeconds || 12
        })
      });
      if (res.ok) {
        const data = await res.json();
        setJournalResult(data);
        fetchHistory();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchHistory = async () => {
    try {
      const res = await fetch("http://localhost:8000/api/v1/apps/voice-journal");
      if (res.ok) {
        const data = await res.json();
        setHistory(data);
      }
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        {/* Navigation & Header */}
        <div className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div className="flex items-center gap-4">
            <Link href="/" className="p-2 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 transition">
              <ArrowLeft className="w-5 h-5 text-slate-400" />
            </Link>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                  Feature 5 • Bhashini ASR
                </span>
              </div>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                Multilingual Voice Journaling
              </h1>
            </div>
          </div>
          <div className="flex items-center gap-2 bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-800 text-xs">
            <Languages className="w-4 h-4 text-indigo-400" />
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="bg-transparent text-slate-200 outline-none cursor-pointer"
            >
              <option value="hi-IN" className="bg-slate-900">Hindi (हिंदी)</option>
              <option value="ta-IN" className="bg-slate-900">Tamil (தமிழ்)</option>
              <option value="en-IN" className="bg-slate-900">English (India)</option>
            </select>
          </div>
        </div>

        {/* Main Recorder Card */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-slate-900/70 backdrop-blur border border-slate-800 rounded-2xl p-6 flex flex-col items-center justify-center text-center space-y-6">
            <div className="relative">
              <div className={`w-32 h-32 rounded-full flex items-center justify-center transition-all duration-300 ${
                isRecording
                  ? "bg-rose-500/20 border-2 border-rose-500 animate-pulse text-rose-400 shadow-lg shadow-rose-500/20"
                  : "bg-indigo-500/10 border border-indigo-500/30 text-indigo-400 hover:scale-105"
              }`}>
                {isRecording ? <Mic className="w-12 h-12" /> : <MicOff className="w-12 h-12" />}
              </div>
              {isRecording && (
                <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 bg-rose-500 text-white text-xs px-2.5 py-0.5 rounded-full font-mono">
                  {recordingSeconds}s
                </div>
              )}
            </div>

            <div className="space-y-2">
              <h3 className="text-lg font-semibold text-white">
                {isRecording ? "Listening to your voice..." : "Speak Your Health Journal"}
              </h3>
              <p className="text-xs text-slate-400 max-w-xs">
                Speak in your preferred language. SvasthyaSetu transcribes, translates, and extracts acoustic mood indicators.
              </p>
            </div>

            <div className="flex gap-3">
              {!isRecording ? (
                <button
                  onClick={handleStartRecording}
                  className="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-medium text-sm transition flex items-center gap-2 shadow-lg shadow-indigo-600/25"
                >
                  <Mic className="w-4 h-4" /> Start Recording
                </button>
              ) : (
                <button
                  onClick={handleStopRecording}
                  className="px-6 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white font-medium text-sm transition flex items-center gap-2 shadow-lg shadow-rose-600/25"
                >
                  <MicOff className="w-4 h-4" /> Stop & Analyze
                </button>
              )}
            </div>
          </div>

          {/* Transcript & Sentiment Analysis Output */}
          <div className="bg-slate-900/70 backdrop-blur border border-slate-800 rounded-2xl p-6 space-y-4">
            <h3 className="text-sm font-semibold text-slate-300 flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-indigo-400" /> Bhashini AI Sentiment Breakdown
            </h3>

            {loading ? (
              <div className="flex items-center justify-center py-12 text-slate-400 gap-3 text-sm">
                <RefreshCw className="w-5 h-5 animate-spin text-indigo-400" /> Processing audio & translating...
              </div>
            ) : journalResult ? (
              <div className="space-y-4">
                <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 space-y-1">
                  <span className="text-[10px] text-slate-500 font-semibold uppercase tracking-wider">Raw Transcription ({journalResult.language})</span>
                  <p className="text-sm text-slate-200">{journalResult.transcript}</p>
                </div>

                <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 space-y-1">
                  <span className="text-[10px] text-indigo-400 font-semibold uppercase tracking-wider">Bhashini English Translation</span>
                  <p className="text-sm text-slate-300 italic">{journalResult.translated_text}</p>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="p-3 rounded-xl bg-indigo-500/10 border border-indigo-500/20">
                    <span className="text-xs text-indigo-300">Emotion Marker</span>
                    <p className="text-lg font-bold text-indigo-400 mt-0.5">{journalResult.emotion}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20">
                    <span className="text-xs text-emerald-300">Sentiment Score</span>
                    <p className="text-lg font-bold text-emerald-400 mt-0.5">{(journalResult.sentiment_score * 100).toFixed(0)} / 100</p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center py-12 text-slate-500 text-sm">
                Record your voice to view real-time transcription and mood analytics.
              </div>
            )}
          </div>
        </div>

        {/* History List */}
        <div className="bg-slate-900/70 backdrop-blur border border-slate-800 rounded-2xl p-6 space-y-4">
          <h3 className="text-sm font-semibold text-slate-300">Recent Voice Journal Logs</h3>
          <div className="space-y-2">
            {history.length > 0 ? (
              history.map((item, idx) => (
                <div key={idx} className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between">
                  <div className="space-y-0.5">
                    <p className="text-sm text-slate-200 font-medium">{item.transcript}</p>
                    <span className="text-xs text-slate-500">{new Date(item.created_at).toLocaleString()} • {item.language}</span>
                  </div>
                  <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                    {item.emotion}
                  </span>
                </div>
              ))
            ) : (
              <div className="text-xs text-slate-500 py-4 text-center">No previous journal entries found.</div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
