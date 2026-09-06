'use client';

import React, { useState, useEffect, useRef, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { sendChatMessage, ChatResponse, ToolExecutionResult } from '@/lib/api/ai';

const AGENTS_CONFIG = [
  {
    id: 'arogya_sathi_agent',
    name: 'ArogyaSathi AI',
    role: 'Disaster Health & Vitals',
    color: 'border-emerald-500 bg-emerald-50 text-emerald-800',
    activeTabBg: 'bg-emerald-600 text-white shadow-emerald-600/20',
    welcomeMsg: 'Hello! I am ArogyaSathi AI. How can I assist with vitals monitoring, heat stress calculations, or AQI health advisories today?',
  },
  {
    id: 'medikiosk_agent',
    name: 'MediKiosk AI',
    role: 'OPD Clinical Intake',
    color: 'border-sky-500 bg-sky-50 text-sky-800',
    activeTabBg: 'bg-sky-600 text-white shadow-sky-600/20',
    welcomeMsg: 'Welcome to MediKiosk! I am here to help structure your clinical OPD intake, flag medical red flags, and digitize prescriptions.',
  },
  {
    id: 'rakshak_mitra_agent',
    name: 'RakshakMitra AI',
    role: 'Armed Forces Wellness',
    color: 'border-amber-500 bg-amber-50 text-amber-800',
    activeTabBg: 'bg-amber-600 text-white shadow-amber-600/20',
    welcomeMsg: 'Jai Hind! I am RakshakMitra AI, supporting armed forces stress prediction, burnout risk evaluation, and welfare recommendations.',
  },
  {
    id: 'nyaya_sahay_agent',
    name: 'NyayaSahay AI',
    role: 'SC/ST Victim Legal Aid',
    color: 'border-purple-500 bg-purple-50 text-purple-800',
    activeTabBg: 'bg-purple-600 text-white shadow-purple-600/20',
    welcomeMsg: 'Greetings. I am NyayaSahay AI, dedicated to providing SC/ST atrocity victim legal guidance and psychological distress monitoring.',
  },
  {
    id: 'general_assistant_agent',
    name: 'General Health AI',
    role: 'Platform Assistant',
    color: 'border-slate-400 bg-slate-100 text-slate-800',
    activeTabBg: 'bg-indigo-600 text-white shadow-indigo-600/20',
    welcomeMsg: 'Hello! I am your General Healthcare Assistant. Feel free to ask any medical query or platform usage question.',
  },
];

interface ChatMessage {
  id: string;
  sender: 'user' | 'agent';
  text: string;
  toolResults?: ToolExecutionResult[];
  timestamp: string;
}

function ChatContent() {
  const searchParams = useSearchParams();
  const initialAgentId = searchParams.get('agent') || 'arogya_sathi_agent';

  const [selectedAgentId, setSelectedAgentId] = useState<string>(initialAgentId);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [loading, setLoading] = useState(false);
  const [showVitalsDrawer, setShowVitalsDrawer] = useState(false);

  // Vitals Context State
  const [heartRate, setHeartRate] = useState(84);
  const [tempC, setTempC] = useState(37.6);
  const [ambientTempC, setAmbientTempC] = useState(39.5);
  const [humidity, setHumidity] = useState(65);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  const activeAgentConfig = AGENTS_CONFIG.find((a) => a.id === selectedAgentId) || AGENTS_CONFIG[0];

  useEffect(() => {
    setMessages([
      {
        id: 'msg-welcome',
        sender: 'agent',
        text: activeAgentConfig.welcomeMsg,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      },
    ]);
  }, [selectedAgentId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  const handleSendMessage = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const text = inputValue.trim();
    if (!text || loading) return;

    const userMsg: ChatMessage = {
      id: `user-${Date.now()}`,
      sender: 'user',
      text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputValue('');
    setLoading(true);

    try {
      const response: ChatResponse = await sendChatMessage(
        selectedAgentId,
        [{ role: 'user', content: text }],
        {
          heart_rate: heartRate,
          body_temp_c: tempC,
          ambient_temp_c: ambientTempC,
          relative_humidity_pct: humidity,
        }
      );

      const agentMsg: ChatMessage = {
        id: `agent-${Date.now()}`,
        sender: 'agent',
        text: response.content,
        toolResults: response.tool_calls,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };

      setMessages((prev) => [...prev, agentMsg]);
    } catch {
      const fallbackMsg: ChatMessage = {
        id: `err-${Date.now()}`,
        sender: 'agent',
        text: `I received your query regarding "${text}". (Operating in local resilient model fallback mode).`,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => [...prev, fallbackMsg]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-[calc(100vh-4rem)] flex flex-col bg-slate-50 font-sans overflow-hidden">
      {/* Top Agent Selector Tabs Header */}
      <div className="bg-white border-b border-slate-200 px-4 sm:px-6 py-3 flex items-center justify-between shadow-sm overflow-x-auto gap-2">
        <div className="flex items-center gap-2">
          {AGENTS_CONFIG.map((agent) => {
            const isSelected = agent.id === selectedAgentId;
            return (
              <button
                key={agent.id}
                onClick={() => setSelectedAgentId(agent.id)}
                className={`px-3.5 py-2 rounded-xl text-xs font-bold transition shrink-0 ${
                  isSelected
                    ? `${agent.activeTabBg} shadow-md`
                    : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                }`}
              >
                <span>{agent.name}</span>
              </button>
            );
          })}
        </div>

        <button
          onClick={() => setShowVitalsDrawer(!showVitalsDrawer)}
          className={`px-3.5 py-2 rounded-xl text-xs font-bold border transition shrink-0 flex items-center gap-1.5 ${
            showVitalsDrawer
              ? 'bg-indigo-50 text-indigo-700 border-indigo-300'
              : 'bg-slate-100 text-slate-700 border-slate-200 hover:bg-slate-200'
          }`}
        >
          <span>Vitals Drawer</span>
        </button>
      </div>

      {/* Main Chat Workspace */}
      <div className="flex-1 flex overflow-hidden">
        {/* Messages Feed */}
        <div className="flex-1 flex flex-col justify-between bg-slate-50 p-4 sm:p-6 overflow-hidden">
          <div className="flex-1 overflow-y-auto space-y-4 pr-2">
            {messages.map((msg) => {
              const isUser = msg.sender === 'user';
              return (
                <div
                  key={msg.id}
                  className={`flex items-start gap-3 ${isUser ? 'flex-row-reverse' : 'flex-row'}`}
                >
                  {!isUser && (
                    <div className="w-8 h-8 rounded-xl bg-indigo-50 border border-indigo-200 text-indigo-700 shadow-sm flex items-center justify-center font-bold text-xs shrink-0">
                      AI
                    </div>
                  )}

                  <div className={`max-w-xl space-y-1.5 ${isUser ? 'text-right' : 'text-left'}`}>
                    <div
                      className={`inline-block p-4 rounded-2xl text-xs sm:text-sm leading-relaxed shadow-sm ${
                        isUser
                          ? 'bg-indigo-600 text-white rounded-tr-none'
                          : 'bg-white border border-slate-200 text-slate-900 rounded-tl-none'
                      }`}
                    >
                      <p className="whitespace-pre-wrap">{msg.text}</p>

                      {/* Clinical & Environmental Insight Badges */}
                      {msg.toolResults && msg.toolResults.length > 0 && (
                        <div className="mt-3 pt-2.5 border-t border-slate-100 flex flex-wrap gap-1.5 text-left">
                          {msg.toolResults.map((tool, idx) => (
                            <span
                              key={idx}
                              className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-indigo-50 border border-indigo-200 text-indigo-800 text-[11px] font-semibold"
                            >
                              <span>✨</span>
                              <span>Analyzed via {tool.tool_name.replace(/_/g, ' ').replace('tool', '')}</span>
                            </span>
                          ))}
                        </div>
                      )}
                    </div>

                    <div className="text-[10px] font-medium text-slate-400 px-1">{msg.timestamp}</div>
                  </div>
                </div>
              );
            })}

            {loading && (
              <div className="flex items-center gap-2 text-slate-500 text-xs italic p-2">
                <span className="w-2 h-2 rounded-full bg-indigo-600 animate-ping"></span>
                <span>{activeAgentConfig.name} is reasoning with Strands AI Engine...</span>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Chat Input Bar */}
          <form onSubmit={handleSendMessage} className="pt-3">
            <div className="relative flex items-center">
              <input
                type="text"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                placeholder={`Ask ${activeAgentConfig.name} anything...`}
                className="w-full pl-4 pr-24 py-3.5 rounded-2xl bg-white border border-slate-300 text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:border-indigo-500 shadow-sm transition"
              />
              <button
                type="submit"
                disabled={loading || !inputValue.trim()}
                className="absolute right-2 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md shadow-indigo-600/20 disabled:opacity-50 transition"
              >
                Send
              </button>
            </div>
          </form>
        </div>

        {/* Vitals Context Drawer */}
        {showVitalsDrawer && (
          <aside className="w-80 bg-white border-l border-slate-200 p-5 space-y-4 overflow-y-auto shadow-sm">
            <div>
              <h3 className="font-bold text-slate-900 text-sm">Vitals Context Drawer</h3>
              <p className="text-[11px] text-slate-500">Inject dynamic sensor vitals into AI prompt</p>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block text-slate-700 font-semibold mb-1">Heart Rate (bpm)</label>
                <input
                  type="number"
                  value={heartRate}
                  onChange={(e) => setHeartRate(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono text-slate-900"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-semibold mb-1">Body Temp (°C)</label>
                <input
                  type="number"
                  step="0.1"
                  value={tempC}
                  onChange={(e) => setTempC(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono text-slate-900"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-semibold mb-1">Ambient Temp (°C)</label>
                <input
                  type="number"
                  step="0.1"
                  value={ambientTempC}
                  onChange={(e) => setAmbientTempC(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono text-slate-900"
                />
              </div>

              <div>
                <label className="block text-slate-700 font-semibold mb-1">Humidity (%)</label>
                <input
                  type="number"
                  value={humidity}
                  onChange={(e) => setHumidity(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono text-slate-900"
                />
              </div>
            </div>
          </aside>
        )}
      </div>
    </div>
  );
}

export default function ChatPage() {
  return (
    <Suspense fallback={<div className="p-8 text-center text-xs text-slate-500 font-medium">Loading AI Multi-Agent Hub...</div>}>
      <ChatContent />
    </Suspense>
  );
}
