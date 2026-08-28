'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { fetchAiAgents, sendChatMessage, AiAgentMetadata, ChatMessagePayload, ToolExecutionResult } from '@/lib/api/ai';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  engine?: string;
  toolCalls?: ToolExecutionResult[];
  timestamp: string;
}

const DEFAULT_SUGGESTIONS: Record<string, string[]> = {
  arogya_sathi_agent: [
    'What should I do to prevent heatstroke during a heatwave?',
    'Analyze heat stress: body temp 38°C, outdoor 42°C, humidity 70%, 90 mins working outside.',
    'What NDMA precautions should I take for high AQI pollution spikes?',
  ],
  medikiosk_agent: [
    'I have acute chest pain and breathlessness for 1 hour. Triage me.',
    'Help me prepare my OPD intake history for a doctor consultation.',
    'Extract medical entities from prescription: Paracetamol 500mg BD for 5 days.',
  ],
  rakshak_mitra_agent: [
    'Calculate burnout risk: 90 days field deployment, 65 duty hours/week, PHQ-9 score 18.',
    'Suggest commander welfare actions for high operational stress personnel.',
    'Provide confidential coping techniques for prolonged military duty fatigue.',
  ],
  nyaya_sahay_agent: [
    'Assess distress level for SC/ST atrocity victim in chargesheet legal stage.',
    'What legal aid and protection options are available under SC/ST Act 1989?',
    'Trigger escalation dispatch for high distress victim receiving intimidation.',
  ],
  general_assistant_agent: [
    'How do I use the SvasthyaSetu platform across the 4 applications?',
    'What are the key preventive health guidelines for seasonal infections?',
  ],
};

export default function AiChatPage() {
  const [agents, setAgents] = useState<AiAgentMetadata[]>([]);
  const [selectedAgentId, setSelectedAgentId] = useState<string>('arogya_sathi_agent');
  const [messages, setMessages] = useState<Record<string, Message[]>>({});
  const [inputMessage, setInputMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [showContextDrawer, setShowContextDrawer] = useState(false);

  // Context State Parameters
  const [envTemp, setEnvTemp] = useState('38');
  const [humidity, setHumidity] = useState('65');
  const [bodyTemp, setBodyTemp] = useState('37.2');
  const [dutyHours, setDutyHours] = useState('55');
  const [caseStage, setCaseStage] = useState('chargesheet');

  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    async function loadAgents() {
      const data = await fetchAiAgents();
      setAgents(data.agents);
      if (data.agents.length > 0 && !selectedAgentId) {
        setSelectedAgentId(data.agents[0].agent_id);
      }
    }
    loadAgents();
  }, [selectedAgentId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, selectedAgentId]);

  const activeAgent = agents.find((a) => a.agent_id === selectedAgentId) || agents[0];
  const currentMessages = messages[selectedAgentId] || [];

  const handleSendMessage = async (textToSend?: string) => {
    const query = textToSend || inputMessage;
    if (!query.trim() || loading) return;

    const userMsgId = Date.now().toString();
    const newUserMsg: Message = {
      id: userMsgId,
      role: 'user',
      content: query,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => ({
      ...prev,
      [selectedAgentId]: [...(prev[selectedAgentId] || []), newUserMsg],
    }));

    if (!textToSend) setInputMessage('');
    setLoading(true);

    try {
      const historyPayload: ChatMessagePayload[] = [
        ...(messages[selectedAgentId] || []).map((m) => ({ role: m.role, content: m.content })),
        { role: 'user', content: query },
      ];

      const contextPayload = {
        env_temp_c: parseFloat(envTemp),
        humidity_percent: parseFloat(humidity),
        body_temp_c: parseFloat(bodyTemp),
        duty_hours_per_week: parseFloat(dutyHours),
        case_stage: caseStage,
      };

      const response = await sendChatMessage(selectedAgentId, historyPayload, contextPayload);

      const assistantMsg: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response.content,
        engine: response.engine,
        toolCalls: response.tool_calls,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };

      setMessages((prev) => ({
        ...prev,
        [selectedAgentId]: [...(prev[selectedAgentId] || []), assistantMsg],
      }));
    } catch {
      const errorMsg: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: '⚠️ Service temporarily operating in offline mode. Please verify backend connection.',
        engine: 'offline_fallback',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => ({
        ...prev,
        [selectedAgentId]: [...(prev[selectedAgentId] || []), errorMsg],
      }));
    } finally {
      setLoading(false);
    }
  };

  const suggestions = DEFAULT_SUGGESTIONS[selectedAgentId] || DEFAULT_SUGGESTIONS['arogya_sathi_agent'];

  return (
    <div className="flex flex-col h-screen bg-slate-950 text-slate-100 font-sans overflow-hidden">
      {/* Top Header */}
      <header className="h-16 border-b border-slate-800 bg-slate-900/90 backdrop-blur-xl px-6 flex items-center justify-between shrink-0 z-20">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-indigo-600 to-emerald-500 flex items-center justify-center text-white font-extrabold text-lg shadow-lg shadow-indigo-500/20">
            S
          </div>
          <div>
            <h1 className="text-sm font-bold text-white tracking-tight flex items-center gap-2">
              SvasthyaSetu AI Engine Hub
              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                Strands + Bedrock Mantle
              </span>
            </h1>
            <p className="text-[11px] text-slate-400">Unified Multi-Agent Portal (4 Apps)</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => setShowContextDrawer(!showContextDrawer)}
            className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200 border border-slate-700 transition flex items-center gap-1.5"
          >
            <span>⚙️ Vitals Context</span>
          </button>
          <Link
            href="/dashboard"
            className="px-3 py-1.5 rounded-xl bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-400 border border-indigo-500/30 text-xs font-semibold transition"
          >
            Dashboard
          </Link>
          <Link
            href="/login"
            className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold transition"
          >
            Sign Out
          </Link>
        </div>
      </header>

      {/* Main Workspace */}
      <div className="flex flex-1 overflow-hidden relative">
        {/* Left Sidebar - AI Agents List */}
        <aside className="w-80 border-r border-slate-800 bg-slate-900/60 backdrop-blur-md p-4 flex flex-col gap-4 overflow-y-auto shrink-0">
          <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider px-1">
            Active AI Agents ({agents.length})
          </div>

          <div className="space-y-2">
            {agents.map((agent) => {
              const isSelected = agent.agent_id === selectedAgentId;
              let badgeColor = 'bg-indigo-500/20 border-indigo-500/30 text-indigo-400';
              if (agent.agent_id.includes('arogya')) badgeColor = 'bg-emerald-500/20 border-emerald-500/30 text-emerald-400';
              if (agent.agent_id.includes('medikiosk')) badgeColor = 'bg-sky-500/20 border-sky-500/30 text-sky-400';
              if (agent.agent_id.includes('rakshak')) badgeColor = 'bg-amber-500/20 border-amber-500/30 text-amber-400';
              if (agent.agent_id.includes('nyaya')) badgeColor = 'bg-purple-500/20 border-purple-500/30 text-purple-400';

              return (
                <button
                  key={agent.agent_id}
                  onClick={() => setSelectedAgentId(agent.agent_id)}
                  className={`w-full p-3.5 rounded-2xl text-left border transition duration-200 ${
                    isSelected
                      ? `${badgeColor} shadow-lg shadow-indigo-950/50`
                      : 'bg-slate-900/50 border-slate-800 text-slate-300 hover:bg-slate-800/60'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold truncate">{agent.name}</span>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-slate-950/80 border border-slate-800 text-slate-400 font-mono">
                      {agent.tools_count} tools
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-400 mt-1 line-clamp-2 leading-relaxed">
                    {agent.description}
                  </p>
                </button>
              );
            })}
          </div>

          {/* Agent Information Widget */}
          {activeAgent && (
            <div className="mt-auto p-4 rounded-2xl bg-slate-950/80 border border-slate-800 space-y-2">
              <div className="text-[11px] font-bold text-slate-300 uppercase tracking-wider flex items-center justify-between">
                <span>Agent System Info</span>
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              </div>
              <div className="text-xs text-slate-400 space-y-1">
                <div><strong className="text-slate-300">Model:</strong> {activeAgent.model_id}</div>
                <div><strong className="text-slate-300">Engine:</strong> Strands + AWS Bedrock</div>
                <div><strong className="text-slate-300">Status:</strong> Ready</div>
              </div>
            </div>
          )}
        </aside>

        {/* Right Drawer - Live Context Drawer */}
        {showContextDrawer && (
          <div className="absolute top-0 right-0 h-full w-80 bg-slate-900/95 border-l border-slate-800 backdrop-blur-2xl p-5 z-30 space-y-4 shadow-2xl overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <span>⚙️ Live Vitals Context</span>
              </h3>
              <button
                onClick={() => setShowContextDrawer(false)}
                className="text-slate-400 hover:text-white text-xs px-2 py-1 rounded-lg bg-slate-800"
              >
                Close ✕
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block text-slate-400 mb-1">Ambient Temperature (°C)</label>
                <input
                  type="number"
                  value={envTemp}
                  onChange={(e) => setEnvTemp(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">Relative Humidity (%)</label>
                <input
                  type="number"
                  value={humidity}
                  onChange={(e) => setHumidity(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">Body Temperature (°C)</label>
                <input
                  type="number"
                  value={bodyTemp}
                  onChange={(e) => setBodyTemp(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">Weekly Duty Hours</label>
                <input
                  type="number"
                  value={dutyHours}
                  onChange={(e) => setDutyHours(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">Atrocity Case Stage</label>
                <select
                  value={caseStage}
                  onChange={(e) => setCaseStage(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-indigo-500"
                >
                  <option value="fir">FIR Registered</option>
                  <option value="chargesheet">Chargesheet Filed</option>
                  <option value="trial">Court Trial</option>
                  <option value="adjournment">Court Adjournment</option>
                </select>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-800 text-[11px] text-slate-400 leading-relaxed">
              These live parameters are fed into the AI context for computing real-time risk scores and recommendations.
            </div>
          </div>
        )}

        {/* Center Panel - Main Chat Timeline */}
        <main className="flex-1 flex flex-col bg-slate-950 overflow-hidden">
          {/* Active Agent Banner */}
          <div className="p-4 border-b border-slate-800/80 bg-slate-900/40 flex items-center justify-between shrink-0">
            <div>
              <h2 className="text-sm font-bold text-white flex items-center gap-2">
                {activeAgent?.name || 'AI Assistant'}
              </h2>
              <p className="text-xs text-slate-400 truncate max-w-xl">{activeAgent?.description}</p>
            </div>
            <div className="text-xs text-slate-400 bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-xl flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span>Strands Connected</span>
            </div>
          </div>

          {/* Messages Scroll Area */}
          <div className="flex-1 p-6 overflow-y-auto space-y-6">
            {currentMessages.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-center max-w-md mx-auto space-y-4 text-slate-400">
                <div className="w-16 h-16 rounded-3xl bg-indigo-600/10 border border-indigo-500/20 flex items-center justify-center text-3xl">
                  💬
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white">Start Conversation</h3>
                  <p className="text-xs text-slate-400 mt-1">
                    Ask {activeAgent?.name} anything or select one of the suggested queries below.
                  </p>
                </div>
              </div>
            ) : (
              currentMessages.map((msg) => (
                <div
                  key={msg.id}
                  className={`flex flex-col ${msg.role === 'user' ? 'items-end' : 'items-start'}`}
                >
                  <div
                    className={`max-w-2xl rounded-3xl p-4 shadow-lg text-sm leading-relaxed ${
                      msg.role === 'user'
                        ? 'bg-indigo-600 text-white rounded-br-none shadow-indigo-600/20'
                        : 'bg-slate-900 border border-slate-800 text-slate-200 rounded-bl-none'
                    }`}
                  >
                    <div className="whitespace-pre-wrap">{msg.content}</div>

                    {/* Render Tool Execution Cards if present */}
                    {msg.toolCalls && msg.toolCalls.length > 0 && (
                      <div className="mt-3 pt-3 border-t border-slate-800 space-y-2">
                        {msg.toolCalls.map((tc, idx) => (
                          <div
                            key={idx}
                            className="p-3 rounded-2xl bg-slate-950/90 border border-slate-800 text-xs space-y-1.5"
                          >
                            <div className="font-bold text-indigo-400 flex items-center justify-between">
                              <span>🛠️ Tool Executed: {tc.tool_name}</span>
                              <span className="text-[10px] px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                Success
                              </span>
                            </div>
                            <div className="bg-slate-900 p-2 rounded-xl font-mono text-[11px] text-slate-300 overflow-x-auto">
                              {JSON.stringify(tc.result, null, 2)}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                  <span className="text-[10px] text-slate-500 mt-1.5 px-1">{msg.timestamp}</span>
                </div>
              ))
            )}

            {loading && (
              <div className="flex items-center gap-3 p-4 rounded-2xl bg-slate-900/60 border border-slate-800 max-w-xs text-xs text-slate-400">
                <svg className="animate-spin h-4 w-4 text-indigo-400" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <span>Agent reasoning via Bedrock Mantle...</span>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* Quick Suggestions Chips */}
          <div className="px-6 py-2 bg-slate-950/80 border-t border-slate-900 flex items-center gap-2 overflow-x-auto">
            <span className="text-[11px] font-semibold text-slate-500 shrink-0">Suggestions:</span>
            {suggestions.map((s, idx) => (
              <button
                key={idx}
                onClick={() => handleSendMessage(s)}
                className="px-3 py-1.5 rounded-full bg-slate-900 hover:bg-slate-800 border border-slate-800 text-xs text-slate-300 shrink-0 transition"
              >
                {s}
              </button>
            ))}
          </div>

          {/* Bottom Chat Input Box */}
          <div className="p-4 border-t border-slate-800 bg-slate-900/80 backdrop-blur-xl shrink-0">
            <div className="max-w-4xl mx-auto flex items-center gap-3">
              <input
                type="text"
                value={inputMessage}
                onChange={(e) => setInputMessage(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                placeholder={`Ask ${activeAgent?.name || 'Agent'}...`}
                className="flex-1 px-5 py-3.5 rounded-2xl bg-slate-950 border border-slate-800 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-indigo-500 transition"
              />
              <button
                onClick={() => handleSendMessage()}
                disabled={loading || !inputMessage.trim()}
                className="px-6 py-3.5 rounded-2xl bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold text-sm transition shadow-lg shadow-indigo-600/30 disabled:opacity-50 flex items-center gap-2"
              >
                <span>Send</span>
              </button>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
