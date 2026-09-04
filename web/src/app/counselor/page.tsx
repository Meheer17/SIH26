"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ArrowLeft, MessageSquare, ShieldAlert, Send, Bot, User, PhoneCall } from "lucide-react";

export default function CulturalCounselorPage() {
  const [persona, setPersona] = useState("COMPASSIONATE_COUNSELOR");
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState<any[]>([
    { role: "assistant", text: "Namaste. I am your SvasthyaSetu Cultural Companion. I am standing by in a safe, confidential space." }
  ]);

  const handleSend = async () => {
    if (!input.trim()) return;
    const userMsg = input;
    setInput("");
    setMessages((prev) => [...prev, { role: "user", text: userMsg }]);

    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/mind-family/counselor-chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_message: userMsg,
          target_persona: persona
        })
      });
      if (res.ok) {
        const data = await res.json();
        setMessages((prev) => [
          ...prev,
          {
            role: "assistant",
            text: data.response,
            strategies: data.actionable_coping_strategies,
            helplines: data["24x7_helplines"]
          }
        ]);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div className="flex items-center gap-4">
            <Link href="/" className="p-2 rounded-xl bg-slate-900 border border-slate-800 hover:bg-slate-800 transition">
              <ArrowLeft className="w-5 h-5 text-slate-400" />
            </Link>
            <div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-purple-500/10 text-purple-400 border border-purple-500/20">
                Feature 10 • Culturally Aware AI Counselor
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-white mt-1">
                AI Cultural Counselor & Helpline Router
              </h1>
            </div>
          </div>

          <select
            value={persona}
            onChange={(e) => setPersona(e.target.value)}
            className="bg-slate-900 border border-slate-800 text-xs text-purple-300 rounded-xl px-3 py-2 outline-none cursor-pointer"
          >
            <option value="COMPASSIONATE_COUNSELOR">General Compassionate Persona</option>
            <option value="MILITARY_PEER">Military Comrade Persona (CAPF)</option>
            <option value="SC_ST_LEGAL_COUNSELOR">Trauma-Informed Atrocity Support</option>
          </select>
        </div>

        {/* Chat Window */}
        <div className="bg-slate-900/70 border border-slate-800 rounded-2xl p-6 flex flex-col h-[520px]">
          <div className="flex-1 overflow-y-auto space-y-4 pr-2">
            {messages.map((m, idx) => (
              <div key={idx} className={`flex gap-3 ${m.role === "user" ? "justify-end" : "justify-start"}`}>
                {m.role === "assistant" && (
                  <div className="w-8 h-8 rounded-full bg-purple-500/10 border border-purple-500/30 flex items-center justify-center shrink-0">
                    <Bot className="w-4 h-4 text-purple-400" />
                  </div>
                )}
                <div className={`p-4 rounded-2xl max-w-lg space-y-2 text-sm ${
                  m.role === "user"
                    ? "bg-purple-600 text-white rounded-br-none"
                    : "bg-slate-950 border border-slate-800 text-slate-200 rounded-bl-none"
                }`}>
                  <p>{m.text}</p>
                  {m.strategies && (
                    <div className="mt-2 pt-2 border-t border-slate-800 text-xs space-y-1">
                      <span className="font-semibold text-purple-400">Actionable Coping Exercise:</span>
                      <ul className="list-disc list-inside text-slate-400 space-y-0.5">
                        {m.strategies.map((s: string, sIdx: number) => (
                          <li key={sIdx}>{s}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {m.helplines && (
                    <div className="mt-2 p-2.5 rounded-xl bg-purple-500/10 border border-purple-500/20 text-xs space-y-1 text-purple-300">
                      <div className="flex items-center gap-1 font-bold">
                        <PhoneCall className="w-3.5 h-3.5" /> 24x7 Emergency Helplines
                      </div>
                      <p>KIRAN: {m.helplines.KIRAN_Mental_Health} | Tele-MANAS: {m.helplines.Tele_MANAS}</p>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* Input Box */}
          <div className="pt-4 border-t border-slate-800 flex gap-3">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSend()}
              placeholder="Express what you're feeling right now..."
              className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white outline-none focus:border-purple-500 transition"
            />
            <button
              onClick={handleSend}
              disabled={loading}
              className="px-5 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-semibold text-sm transition flex items-center gap-2 shadow-lg shadow-purple-600/25 disabled:opacity-50"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
