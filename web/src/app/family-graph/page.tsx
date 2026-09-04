"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, GitFork, HeartHandshake, User, Shield, RefreshCw } from "lucide-react";

export default function FamilyGraphPage() {
  const [graphData, setGraphData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const [chatPersona, setChatPersona] = useState("COMPASSIONATE_COUNSELOR");
  const [userMsg, setUserMsg] = useState("");
  const [chatResponse, setChatResponse] = useState<any>(null);
  const [chatLoading, setChatLoading] = useState(false);

  const fetchGraph = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/mind-family/family-health-graph/demo");
      if (res.ok) {
        const data = await res.json();
        setGraphData(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const sendCounselorMessage = async () => {
    if (!userMsg.trim()) return;
    setChatLoading(true);
    try {
      const res = await fetch("http://localhost:8000/api/v1/mind-family/counselor-chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ user_message: userMsg, target_persona: chatPersona })
      });
      if (res.ok) {
        const data = await res.json();
        setChatResponse(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setChatLoading(false);
    }
  };

  useEffect(() => {
    fetchGraph();
  }, []);

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#0F172A]">
      <header className="bg-white border-b border-slate-200 px-6 py-4 sticky top-0 z-10 shadow-sm">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 transition text-slate-600"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-purple-100 text-purple-800">
                NetworkX Hereditary Graph &amp; Mental Health AI
              </span>
              <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
                Family Lineage Graph &amp; Cultural AI Counselor
              </h1>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8 grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* NetworkX Family Health Graph */}
        <div className="space-y-6">
          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="font-bold text-slate-900 flex items-center gap-2">
                <GitFork className="w-5 h-5 text-purple-600" /> Pedigree Hereditary Risk Graph
              </h2>
              <button
                onClick={fetchGraph}
                className="p-1.5 rounded-lg border border-slate-200 hover:bg-slate-50"
              >
                <RefreshCw className={`w-4 h-4 text-slate-600 ${loading ? "animate-spin" : ""}`} />
              </button>
            </div>
            <p className="text-xs text-slate-500">
              Traverses pedigree family nodes to compute hereditary cardiometabolic risk and inter-generational trauma vulnerability.
            </p>

            {graphData && (
              <div className="space-y-4">
                <div className="p-4 bg-purple-50 rounded-xl border border-purple-200">
                  <span className="text-xs font-semibold text-purple-800 uppercase">Hereditary Risk Summary</span>
                  <div className="mt-3 space-y-3">
                    {graphData.hereditary_risks.map((risk: any, i: number) => (
                      <div key={i} className="bg-white p-3 rounded-lg border border-purple-100 flex items-center justify-between">
                        <div>
                          <p className="font-bold text-slate-900 text-sm">{risk.condition}</p>
                          <p className="text-xs text-slate-500">{risk.category}</p>
                        </div>
                        <div className="text-right">
                          <span className="text-sm font-extrabold text-purple-700">{risk.estimated_genetic_vulnerability_pct}%</span>
                          <p className="text-[10px] text-slate-400">Weight: {risk.hereditary_weight_score}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="p-4 bg-slate-50 rounded-xl border border-slate-200">
                  <p className="text-xs font-semibold text-slate-700 mb-2">Family Tree Nodes &amp; Lineages</p>
                  <div className="flex flex-wrap gap-2">
                    {graphData.genogram_graph_topology.nodes.map((node: any) => (
                      <span key={node.id} className="px-3 py-1 bg-white border border-slate-200 rounded-lg text-xs font-medium text-slate-800 flex items-center gap-1">
                        <User className="w-3.5 h-3.5 text-slate-400" /> {node.label} ({node.relation})
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Cultural AI Counselor */}
        <div className="space-y-6">
          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
            <h2 className="font-bold text-slate-900 flex items-center gap-2">
              <HeartHandshake className="w-5 h-5 text-emerald-600" /> Cultural Mental Health Companion
            </h2>
            <p className="text-xs text-slate-500">
              Culturally tuned counseling for operational military stress, SC/ST atrocity trauma, and patient wellness.
            </p>

            <div className="flex gap-2">
              {[
                { id: "COMPASSIONATE_COUNSELOR", label: "General Patient" },
                { id: "MILITARY_PEER", label: "Military / CAPF" },
                { id: "SC_ST_LEGAL_COUNSELOR", label: "Trauma & Legal" },
              ].map((p) => (
                <button
                  key={p.id}
                  onClick={() => setChatPersona(p.id)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold border transition ${
                    chatPersona === p.id
                      ? "bg-slate-900 text-white border-slate-900"
                      : "bg-slate-50 text-slate-700 border-slate-200 hover:bg-slate-100"
                  }`}
                >
                  {p.label}
                </button>
              ))}
            </div>

            <div className="space-y-3">
              <textarea
                value={userMsg}
                onChange={(e) => setUserMsg(e.target.value)}
                placeholder="Express how you are feeling or share what is causing stress..."
                className="w-full p-3 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 h-24"
              />

              <button
                onClick={sendCounselorMessage}
                disabled={chatLoading}
                className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm rounded-lg transition shadow-sm"
              >
                {chatLoading ? "Analyzing empathetic context..." : "Talk with AI Counselor"}
              </button>
            </div>

            {chatResponse && (
              <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl space-y-3 mt-4">
                <p className="text-sm font-medium text-emerald-900">{chatResponse.response}</p>
                <div>
                  <p className="text-xs font-semibold text-emerald-800 uppercase mb-1">Coping Strategies:</p>
                  <ul className="text-xs text-emerald-950 space-y-1 list-disc pl-4">
                    {chatResponse.actionable_coping_strategies.map((strat: string, idx: number) => (
                      <li key={idx}>{strat}</li>
                    ))}
                  </ul>
                </div>
                <div className="pt-2 border-t border-emerald-200 flex justify-between text-[11px] text-emerald-800 font-mono">
                  <span>Tele-MANAS: 14416</span>
                  <span>KIRAN: 1800-599-0019</span>
                </div>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
