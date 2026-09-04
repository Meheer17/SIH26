# SvasthyaSetu — Master Task Board & Feature Integration Roadmap

> **Status Legend**: 
> - 🟢 **Completed**
> - 🟡 **In Progress**
> - ⚪ **Pending**

---

## 📋 Task Board Overview

| ID | Feature Name | Category | Backend Endpoint | Web UI (Next.js) | Mobile UI (Flutter) | Status |
|---|--------------|----------|------------------|------------------|---------------------|--------|
| **F1** | Cough-to-Diagnosis Audio Screener | Screening | `/api/v1/screening/cough` | `/screening/cough` | `CoughScreeningScreen` | 🟢 Completed |
| **F2** | Non-Invasive Nail Bed Anemia Estimator | Screening | `/api/v1/screening/anemia` | `/screening/anemia` | `CoughScreeningScreen` | 🟢 Completed |
| **F3** | Dynamic Fever & Outbreak Heatmap | CIN / Epidemic | `/api/v1/epidemic/heatmap` | `/epidemic/heatmap` | `CinScreen` | 🟢 Completed |
| **F4** | Dead Man’s Switch / Covert SOS Trigger | Emergency | `/api/v1/covert-sos/deadman` | `/covert-sos/deadman` | `PanicDisguiseScreen` | 🟢 Completed |
| **F5** | Multilingual Voice Journaling + Bhashini | Wellness | `/api/v1/apps/voice-journal` | `/voice-journal` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F6** | Dual Prescription Engine (Allopathic + AYUSH) | Clinical | `/api/v1/clinical/dual-prescription` | `/clinical/dual-prescription` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F7** | Family Health Graph & Genetic Risk Mapper | Family / Clinical | `/api/v1/mind-family/family-graph` | `/family-graph` | `FamilyGraphScreen` | 🟢 Completed |
| **F8** | Gamified Smart Medicine Adherence | Wellness | `/api/v1/apps/adherence` | `/adherence` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F9** | Community Immunity Network (CIN Hub) | CIN | `/api/v1/cin/hub` | `/cin/hub` | `CinScreen` | 🟢 Completed |
| **F10** | Cultural AI Counselor & Crisis Escalation | Mental Health | `/api/v1/mind-family/counselor` | `/counselor` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F11** | Real-time Heat Stress & Environmental Advisory | Disaster / Health | `/api/v1/apps/heat-stress` | `/heat-stress` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F12** | Longitudinal Digital Twin & Health Score | Core / AI | `/api/v1/apps/digital-twin` | `/digital-twin` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F13** | Universal ABDM / FHIR R4 Data Bridge | Standards | `/api/v1/clinical/abdm` | `/abdm` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F14** | Privacy-Preserving Federated Learning | AI Pipeline | `/api/v1/ai/federated` | `/federated` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F15** | ASHA Worker Copilot & Triage Assistant | Field Companion | `/api/v1/apps/asha-copilot` | `/asha` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F16** | Cryptographic Evidence Chain for Legal | Legal / Security | `/api/v1/covert-sos/evidence` | `/evidence` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F17** | Offline-First Edge AI Fallback Engine | Core Architecture | `/api/v1/ai/edge-fallback` | `/edge-ai` | `GroundbreakingSuiteScreen` | 🟢 Completed |
| **F18** | Health Karma & Community Incentives | Gamification | `/api/v1/apps/karma` | `/karma` | `GroundbreakingSuiteScreen` | 🟢 Completed |

---

## 🏃 Active Tasks & Milestones

### Phase 1: Backend API Enhancement & Endpoints (All 18 Features)
- [x] Implemented `/api/v1/screening/cough` & `/api/v1/screening/anemia-colorimetry`
- [x] Implemented `/api/v1/clinical/dual-prescription` & `/api/v1/clinical/abdm/link`
- [x] Implemented `/api/v1/apps/voice-journal`, `/api/v1/apps/adherence`, `/api/v1/apps/heat-stress`, `/api/v1/apps/digital-twin`, `/api/v1/apps/asha-copilot`, `/api/v1/apps/karma`
- [x] Implemented `/api/v1/covert-sos/covert-trigger`, `/api/v1/covert-sos/deadman-ping`, `/api/v1/covert-sos/evidence/log`
- [x] Implemented `/api/v1/mind-family/counselor-chat` & `/api/v1/mind-family/family-health-graph`
- [x] Implemented `/api/v1/ai/federated/weights`, `/api/v1/ai/federated/status`, `/api/v1/ai/edge-fallback/status`
- [x] Implemented `/api/v1/cin/sync` & `/api/v1/epidemic/clusters`

### Phase 2: Web UI (Next.js 16 + Tailwind CSS 4 + Lucide Icons)
- [x] `/screening/page.tsx` — Non-invasive cough & nail bed anemia screener
- [x] `/voice-journal/page.tsx` — Bhashini ASR & multilingual sentiment journal
- [x] `/clinical/dual-prescription/page.tsx` — Allopathic + AYUSH parallel prescription generator
- [x] `/heat-stress/page.tsx` — Live WBGT heat index & NDMA disaster advisories
- [x] `/digital-twin/page.tsx` — 3D Organ Health Twin avatar & longitudinal risk score
- [x] `/abdm/page.tsx` — Ayushman Bharat ABHA card link & HL7 FHIR R4 JSON preview
- [x] `/federated/page.tsx` — Privacy-preserving FedAvg training node & Differential Privacy meter
- [x] `/asha/page.tsx` — Rural field resident intake & maternal high-risk triage
- [x] `/evidence/page.tsx` — Cryptographic SHA-256 Merkle block legal audit trail
- [x] `/edge-ai/page.tsx` — Zero-connectivity TFLite model cache manager
- [x] `/karma/page.tsx` — Health Karma points balance, badges & Jan Aushadhi voucher marketplace
- [x] `/counselor/page.tsx` — Cultural AI mental health counselor & 24x7 crisis helpline router
- [x] `/adherence/page.tsx` — Gamified pill streak calendar & dose intake log

### Phase 3: Mobile UI (Flutter 3.11)
- [x] `cough_screening_screen.dart` — Audio recording & colorimetry
- [x] `family_graph_screen.dart` — Hereditary risk tree
- [x] `panic_disguise_screen.dart` — Stealth SOS trigger
- [x] `cin_screen.dart` — Mesh epidemic intelligence
- [x] `groundbreaking_suite_screen.dart` — Complete 7-in-1 innovation suite
