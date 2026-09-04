# 🏗️ SvasthyaSetu — Complete Feature Implementation Guide

> **For each of the 18 features**: Screens (Flutter + Web), Backend endpoints, MongoDB collections, tools needed, and how they connect.

---

## 🏛️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND                              │
│                                                              │
│  ┌─────────────────┐        ┌──────────────────────┐        │
│  │  Flutter Mobile  │        │   Next.js Web App     │        │
│  │  (app/lib/)      │        │   (web/src/app/)      │        │
│  │                  │        │                       │        │
│  │  4 Sub-Apps:     │        │  4 Sub-App Routes:    │        │
│  │  • ArogyaSathi   │        │  • /arogya            │        │
│  │  • MediKiosk     │        │  • /medikiosk         │        │
│  │  • RakshakMitra  │        │  • /rakshak           │        │
│  │  • NyayaSahay    │        │  • /nyaya             │        │
│  └────────┬─────────┘        └──────────┬────────────┘        │
│           │                              │                    │
│           └──────────┬───────────────────┘                    │
│                      │  HTTP/REST API                         │
│                      ▼                                        │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              FastAPI Backend (backend/app/)            │    │
│  │                                                       │    │
│  │  Services: ML Models, Bhashini, OCR, Weather, ABDM   │    │
│  │  Database: MongoDB (motor async driver)               │    │
│  │  Auth: JWT tokens                                     │    │
│  │  AI: Bedrock/Gemini LLM via OpenAI-compatible API     │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

---

# 📱 SUB-APP 1: ArogyaSathi (Personal Health Companion)

## Features in ArogyaSathi: F1 (Cough), F2 (Anemia), F7 (Family Graph), F8 (Medicine), F12 (Digital Twin), F18 (Health Karma)

---

### Feature 1: 🫁 Cough-to-Diagnosis

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/screening/cough_screen.dart` | Main screen: Record button → waveform → result card |
| `app/lib/features/screening/services/cough_service.dart` | Audio processing + API/TFLite inference service |

**Screen Flow**:
1. Mic permission request → Record button (10s countdown with animated ring)
2. Waveform visualization during recording (use `just_audio` for playback preview)
3. Processing animation → Send to backend OR run TFLite locally
4. Result card: Cough type, Severity badge (LOW/MODERATE/HIGH), Recommendation text
5. "Save to Health Record" button → stores in Digital Twin

**Flutter Tools**: `record: ^5.1.0`, `just_audio: ^0.9.39`, `tflite_flutter: ^0.11.0`, `fftea: ^2.0.1`, `permission_handler: ^11.3.0`

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/screening/cough/page.tsx` | Full cough screening page |
| `web/src/components/AudioRecorder.tsx` | Reusable WebRTC recorder with waveform |

**Web Tools**: `recordrtc`, `wavesurfer.js`, browser `MediaRecorder` API

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/cough_analysis.py` | ✅ EXISTS — Load TFLite/sklearn model, extract features, classify |
| `backend/app/api/v1/endpoints/screening.py` | `POST /api/v1/screening/cough-analysis` (multipart audio upload) |

**API**: `POST /api/v1/screening/cough-analysis` → `{ cough_type, severity, risk_assessment, recommendation, audio_features }`

**MongoDB Collection**: `cough_screenings` — `{ user_id, audio_features, cough_type, severity, created_at }`

---

### Feature 2: 🩸 Nail Bed Anemia Screening

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/screening/anemia_screen.dart` | Camera capture → guide overlay → result |
| `app/lib/features/screening/services/anemia_service.dart` | Image processing + TFLite/API |

**Screen Flow**:
1. Camera preview with nail-bed overlay guide (transparent rectangle showing where to place finger)
2. Capture button → OpenCV-like preprocessing on device
3. Send to backend OR TFLite locally
4. Result: Hb estimate (g/dL), Severity color band (green→yellow→orange→red), Action steps
5. Comparison with previous readings (if any)

**Flutter Tools**: `camera: ^0.11.0+2`, `image: ^4.2.0`, `tflite_flutter: ^0.11.0`

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/screening/anemia/page.tsx` | Camera + canvas ROI extraction + result |

**Web Tools**: `navigator.mediaDevices.getUserMedia()`, `<canvas>` API for pixel analysis

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/anemia_screening.py` | [NEW] OpenCV preprocessing + model inference |
| `backend/app/api/v1/endpoints/screening.py` | Add `POST /api/v1/screening/anemia` |

**API**: `POST /api/v1/screening/anemia` → `{ hemoglobin_estimate_gdl, severity, action, color_values, disclaimer }`

**MongoDB**: `anemia_screenings` — `{ user_id, hemoglobin_estimate, severity, color_values, image_hash, created_at }`

**Backend Tools**: `opencv-python-headless>=4.9.0`, `Pillow>=10.3.0`, `numpy`

---

### Feature 7: 🧬 Family Health Graph

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/family/family_graph_screen.dart` | ✅ EXISTS — Interactive family tree + risk scores |

**Screen Flow**:
1. Family tree visualization (parent-child-sibling graph nodes)
2. Add family member dialog (name, relationship, known conditions)
3. Per-member risk contribution indicator
4. Overall hereditary risk cards (Diabetes, Heart Disease, Cancer, etc.)

**Flutter Tools**: `graphview: ^1.2.1`, `fl_chart: ^0.69.0`

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/family-graph/page.tsx` | ✅ EXISTS — D3 tree + risk dashboard |

**Web Tools**: `react-d3-tree`, `recharts`

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/health_graph.py` | ✅ EXISTS — Graph builder + risk calculator |
| `backend/app/api/v1/endpoints/family.py` | [NEW] CRUD family relationships + risk calculation |

**API**:
- `POST /api/v1/family/add-member` → Add family relationship
- `GET /api/v1/family/graph/{user_id}` → Full family tree with risk scores
- `GET /api/v1/family/risk/{user_id}` → Hereditary risk summary

**MongoDB**: `family_relationships`, `hereditary_risk_scores`

**Backend Tools**: `networkx>=3.3`

---

### Feature 8: 💊 Medicine Reminder + Gamification

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/medicine/medicine_reminder_screen.dart` | Schedule list + adherence stats |
| `app/lib/features/medicine/services/reminder_service.dart` | Local notifications + background worker |

**Screen Flow**:
1. Medicine list with scheduled times (card per medicine)
2. "Take" button → confetti animation on completion → streak counter updates
3. Adherence ring chart (daily, weekly, monthly views)
4. OCR: Scan prescription → auto-populate medicine schedule
5. Caregiver alert settings

**Flutter Tools**: `flutter_local_notifications: ^17.2.1`, `workmanager: ^0.5.2`, `confetti: ^0.7.0`, `hive: ^4.0.0`, `hive_flutter: ^2.0.0`

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/medicine-reminder/page.tsx` | Medicine schedule + adherence charts |

**Web Tools**: `canvas-confetti`, `recharts`

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/adherence_tracker.py` | [NEW] Streak calculation + caregiver alerts |
| `backend/app/api/v1/endpoints/medicine.py` | [NEW] CRUD medicine schedule + adherence |

**API**:
- `POST /api/v1/medicine/schedule` → Add medicine to schedule
- `POST /api/v1/medicine/take` → Log dose taken
- `GET /api/v1/medicine/adherence/{user_id}` → Adherence stats + streak

**MongoDB**: `medicine_schedules`, `dose_logs`, `adherence_stats`

---

### Feature 12: 🧠 Digital Twin

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/twin/digital_twin_screen.dart` | [NEW] Risk forecast charts + What-If slider |

**Screen Flow**:
1. Health summary dashboard (current Hb, BMI, stress, adherence)
2. 6-month trajectory chart with confidence bands (median + p10/p90)
3. "What If?" section: dropdown → select intervention → see chart update
4. Risk alerts (projected thresholds crossed)

**Flutter Tools**: `fl_chart: ^0.69.0` (already planned)

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/digital-twin/page.tsx` | [NEW] Interactive trajectory dashboard |

**Web Tools**: `recharts` (already planned), animated line charts

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/digital_twin.py` | [NEW] Monte Carlo simulation + Bayesian trajectory |
| `backend/app/api/v1/endpoints/digital_twin.py` | [NEW] |

**API**:
- `GET /api/v1/twin/forecast/{user_id}` → 6-month trajectory with confidence bands
- `POST /api/v1/twin/what-if` → `{ user_id, intervention: "stop_iron_tablets" }` → modified forecast

**MongoDB**: `digital_twin_snapshots` — `{ user_id, trajectories, what_if_history, updated_at }`

**Backend Tools**: `numpy`, `scipy` (for stats)

---

### Feature 18: 🎯 Health Karma

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/karma/karma_dashboard_screen.dart` | [NEW] Karma score, tier badge, leaderboard |

**Screen Flow**:
1. Karma score with animated tier badge (शिष्य → सेवक → रक्षक → योद्धा → गुरु)
2. Progress bar to next tier
3. This week's earned points with activity list
4. Village/community leaderboard (top 10)
5. Available rewards section

**Flutter Tools**: `fl_chart`, `confetti` (tier-up celebration)

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/karma/page.tsx` | [NEW] Community leaderboard + rewards |

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/karma_engine.py` | [NEW] Points calculator + tier logic + leaderboard |
| `backend/app/api/v1/endpoints/karma.py` | [NEW] |

**API**:
- `GET /api/v1/karma/score/{user_id}` → Score, tier, next-tier progress
- `GET /api/v1/karma/leaderboard?scope=village` → Top users
- `POST /api/v1/karma/award` → Internal: award points for action

**MongoDB**: `karma_scores`, `karma_transactions`, `karma_leaderboard`

---

---

# 🏥 SUB-APP 2: MediKiosk (AI Health Kiosk)

## Features: F5 (Voice Journal), F6 (Dual Prescription), F13 (ABDM Bridge)

---

### Feature 5: 🗣️ Bhashini Voice → Clinical Notes

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/voice/voice_journal_screen.dart` | [NEW] Record → transcription → structured note |

**Screen Flow**:
1. Language selector (22 Indian languages via Bhashini)
2. Record button (2-minute max) → waveform animation
3. Real-time transcription display (streaming from Bhashini ASR)
4. "Generate Clinical Note" button → LLM structures into CC/HPI/Symptoms/Meds format
5. Note preview → Edit → Save/Share with doctor

**Flutter Tools**: `record: ^5.1.0` (shared with F1), `speech_to_text: ^7.3.0` (already installed)

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/voice-journal/page.tsx` | Browser audio recorder + transcription + note |

**Web Tools**: Browser `MediaRecorder` API, `wavesurfer.js`

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/bhashini.py` | [NEW] Bhashini ULCA API integration (ASR + translation) |
| `backend/app/services/clinical_note_generator.py` | [NEW] LLM prompt → structured clinical note |
| `backend/app/api/v1/endpoints/voice_journal.py` | [NEW] |

**External APIs**: Bhashini ULCA API (`https://dhruva-api.bhashini.gov.in`), Bedrock LLM

**API**:
- `POST /api/v1/voice/transcribe` → `{ audio_file, source_language }` → `{ transcript, translated_en }`
- `POST /api/v1/voice/generate-note` → `{ transcript, language }` → `{ clinical_note }`

**MongoDB**: `voice_journals` — `{ user_id, audio_url, transcript, clinical_note, language, created_at }`

**Backend Tools**: `httpx` (already installed), external Bhashini API key needed

---

### Feature 6: 🕉️ AYUSH + Allopathy Dual Prescription

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/apps/widgets/dual_prescription_card.dart` | [NEW] Side-by-side prescription card |

**Screen Flow**:
1. Symptom input (from voice journal or manual)
2. Optional Prakriti assessment (5 questions → Vata/Pitta/Kapha)
3. Split-view: Left = Western (ICD-11 coded), Right = AYUSH (Prakriti-based)
4. Each side shows: Diagnosis, Medications/Herbs, Dosage, Duration
5. Export as PDF

**Flutter Tools**: No new packages — reuses existing MediKiosk UI

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/medikiosk/dual-prescription/page.tsx` | [NEW] OR integrate into existing medikiosk page |

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/dual_prescription.py` | [NEW] LLM + knowledge base for dual Rx |
| `backend/app/data/icd11_map.json` | [NEW] Symptom → ICD-11 code mapping |
| `backend/app/data/ayush_remedies.json` | [NEW] Prakriti + symptom → herbal remedies |

**API**: `POST /api/v1/prescription/dual` → `{ symptoms, prakriti }` → `{ western: {...}, ayush: {...} }`

**MongoDB**: `prescriptions` — `{ user_id, symptoms, western_rx, ayush_rx, created_at }`

---

### Feature 13: 📡 ABDM Bridge

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/abdm/abha_link_screen.dart` | [NEW] ABHA ID linking + consent flow |

**Screen Flow**:
1. Enter 14-digit ABHA number → OTP verification
2. Consent management: Select which data to share
3. Linked status badge on profile
4. "Push to Health Locker" button after each screening
5. Pull existing records from other hospitals

**Flutter Tools**: No new packages — uses `http` for API calls

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/abdm/page.tsx` | [NEW] ABDM linking dashboard |

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/abdm_bridge.py` | [NEW] ABDM sandbox API integration |
| `backend/app/services/fhir_converter.py` | [NEW] Convert screenings → FHIR R4 bundles |
| `backend/app/api/v1/endpoints/abdm.py` | [NEW] |

**External APIs**: ABDM Sandbox (`https://dev.abdm.gov.in`), requires ABDM sandbox credentials

**API**:
- `POST /api/v1/abdm/link-abha` → Link ABHA ID to SvasthyaSetu account
- `POST /api/v1/abdm/push-record` → Push screening to ABDM Health Locker
- `POST /api/v1/abdm/consent-request` → Request consent to pull records
- `GET /api/v1/abdm/pull-records` → Pull records from linked ABDM facilities

**Backend Tools**: `fhir.resources` (Python FHIR library), `httpx` (already installed), `pyjwt` (already installed)

**MongoDB**: `abdm_links` — `{ user_id, abha_id, linked_at, consent_artifacts }`

---

---

# 🛡️ SUB-APP 3: RakshakMitra (Protector for Forces/Frontline)

## Features: F3 (Fever Map), F4 (Dead Man's Switch), F10 (AI Counselor), F11 (CIN), F15 (ASHA Copilot)

---

### Feature 3: 🌡️ Community Fever Map

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/community/fever_map_screen.dart` | [NEW] Map + symptom report form |

**Screen Flow**:
1. OpenStreetMap with heatmap overlay (color-coded by cluster severity)
2. "Report Symptoms" FAB → anonymous form (symptoms checklist, temperature, GPS auto-capture)
3. Active cluster alerts in bottom sheet
4. Zoom into cluster → see report count, dominant symptoms, trend line

**Flutter Tools**: `flutter_map: ^7.0.2`, `latlong2: ^0.9.1`, `geolocator: ^12.0.0`

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/community/fever-map/page.tsx` | [NEW] Leaflet map + report submission |

**Web Tools**: `leaflet`, `react-leaflet`, `leaflet.heat`

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/fever_map.py` | [NEW] DBSCAN clustering + alert logic |
| `backend/app/services/epidemic_clustering.py` | ✅ EXISTS |
| `backend/app/api/v1/endpoints/community.py` | [NEW] |

**API**:
- `POST /api/v1/community/report-symptom` → Anonymous symptom report with GPS
- `GET /api/v1/community/fever-map` → All active clusters with heatmap data
- `GET /api/v1/community/cluster/{id}` → Cluster detail (report count, trend)

**MongoDB**: `symptom_reports` (TTL index: auto-delete after 72h for privacy)

**Backend Tools**: `scikit-learn` (DBSCAN), `geopy`, `numpy`

---

### Feature 4: 📞 Dead Man's Switch

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/wellness/wellness_check_screen.dart` | [NEW] Enable/disable + status + emergency contacts |
| `app/lib/core/services/activity_tracker.dart` | [NEW] Track last interaction timestamp |

**Screen Flow**:
1. Toggle: Enable/Disable Dead Man's Switch
2. Set silence threshold (48h/72h/96h)
3. Configure emergency contacts (3 levels: counselor → supervisor → authority)
4. Status card: "Last interaction: 2 hours ago ✅" or "⚠️ 60 hours — reminder sent"
5. Manual "I'm okay" check-in button

**Flutter Tools**: `workmanager: ^0.5.2`, `flutter_local_notifications: ^17.2.1`, `shared_preferences: ^2.2.2`

#### Web Page
- Uses existing RakshakMitra dashboard — no new web page needed
- Admin view shows silent users with escalation level

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/dead_mans_switch.py` | [NEW] Scheduler-based activity monitor |
| `backend/app/api/v1/endpoints/wellness_check.py` | [NEW] |

**External APIs**: Twilio or MSG91 for IVR/SMS (for automated calls)

**API**:
- `POST /api/v1/wellness/checkin` → Manual "I'm okay"
- `GET /api/v1/wellness/status/{user_id}` → Current status + hours since last interaction
- `PUT /api/v1/wellness/settings` → Configure threshold + contacts

**MongoDB**: `user_activity` — `{ user_id, last_interaction, switch_enabled, escalation_level, contacts }`

**Backend Tools**: `apscheduler>=3.10.4`

---

### Feature 10: 🤖 AI Counselor

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/chat/counselor_chat_screen.dart` | [NEW] Dedicated counselor chat (different from general chat) |

**Screen Flow**:
1. Warm welcome message in user's language
2. Chat interface with typing indicator
3. Crisis detection runs on every message → if CRISIS, show helpline banner immediately
4. Session summary at end → option to share with counselor
5. Mood tracking: quick emoji selector after each session

**Flutter Tools**: No new packages — reuses existing chat module

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/chat/counselor/page.tsx` | [NEW] Web counselor chat |

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/ai_counselor.py` | [NEW] System prompt + crisis detection + conversation memory |
| `backend/app/data/cultural_context.json` | [NEW] Indian cultural vocabulary + metaphors |

**API**:
- `POST /api/v1/counselor/chat` → `{ message, session_id, language }` → `{ response, crisis_detected, escalate }`
- `GET /api/v1/counselor/session/{id}` → Full session transcript

**MongoDB**: `counselor_sessions` — `{ user_id, messages[], crisis_flags[], mood_ratings[], created_at }`

**Backend Tools**: `openai` (already installed — for LLM), crisis detection model from `models/trained/`

---

### Feature 11: 🌐 CIN (Community Immunity Network)

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/cin/cin_screen.dart` | ✅ EXISTS — CIN dashboard |
| `app/lib/features/cin/services/ble_mesh_service.dart` | [NEW] BLE broadcast + scan |
| `app/lib/features/cin/services/hash_engine.dart` | [NEW] Symptom → SHA-256 |
| `app/lib/features/cin/widgets/mesh_visualizer.dart` | [NEW] Animated mesh node graph |
| `app/lib/features/cin/widgets/community_heatmap.dart` | [NEW] Heatmap overlay |

**Screen Flow**:
1. Mesh status: "Broadcasting ✅ | 12 nearby nodes detected"
2. Community health indicator ring (% healthy vs % symptomatic nearby)
3. Alert card if cluster detected
4. Privacy badge: "Your data: SHA-256 hashed, anonymous, never leaves this screen"
5. Opt-in toggle for mesh participation

**Flutter Tools**: `flutter_blue_plus: ^1.32.7`, `flutter_ble_peripheral: ^0.6.1`, `crypto: ^3.0.3`

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/cin/page.tsx` | ✅ EXISTS — CIN dashboard |
| `web/src/components/MeshVisualizer.tsx` | [NEW] vis-network animation |
| `web/src/components/CommunityHeatmap.tsx` | [NEW] Leaflet heatmap |

**Web Tools**: `vis-network`, `vis-data`, `leaflet`, `react-leaflet`

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/cin_engine.py` | ✅ EXISTS — Community intelligence |
| `backend/app/services/mesh_aggregator.py` | [NEW] Hash dedup + cluster analysis |

**API**:
- `POST /api/v1/community/cin/report-cluster` → Phone uploads detected cluster
- `GET /api/v1/community/cin/district-map` → Aggregated cluster view for officers
- `POST /api/v1/community/cin/asha-alert` → Trigger ASHA worker dispatch

---

### Feature 15: 🚁 ASHA Copilot

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/asha/asha_copilot_screen.dart` | [NEW] Route + patient queue + visit form |

**Screen Flow**:
1. "Good Morning, Sunita ji" — personalized greeting
2. Today's route: priority-sorted patient list with distance + risk level
3. Tap patient → pre-generated visit questionnaire (based on their Digital Twin alerts)
4. Voice input for visit notes (Bhashini integration)
5. "Visit Complete" → auto-generates clinical note → pushes to ABDM

**Flutter Tools**: `flutter_map` (for route), `geolocator`, `speech_to_text` (already installed)

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/asha-copilot/page.tsx` | [NEW] Supervisor dashboard — all ASHA workers + coverage |

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/asha_copilot.py` | [NEW] Route optimizer + questionnaire generator |
| `backend/app/api/v1/endpoints/asha.py` | [NEW] |

**API**:
- `GET /api/v1/asha/today-route/{asha_id}` → Priority-sorted patient list with GPS + questions
- `POST /api/v1/asha/visit-report` → Submit visit report (voice or text)
- `GET /api/v1/asha/coverage-stats` → Supervisor view of all ASHAs

**MongoDB**: `asha_routes`, `visit_reports`, `asha_coverage`

**Backend Tools**: `geopy` (distance calculations), Digital Twin service (internal dependency)

---

---

# ⚖️ SUB-APP 4: NyayaSahay (Legal Aid & Justice)

## Features: F9 (Panic SOS), F16 (Evidence Blockchain)

---

### Feature 9: 🆘 Panic Disguise SOS

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/sos/panic_disguise_screen.dart` | [NEW] Calculator disguise UI |
| `app/lib/features/sos/services/shake_detector.dart` | [NEW] Accelerometer pattern |
| `app/lib/features/sos/services/covert_sos_service.dart` | [NEW] Silent SOS dispatch |

**Screen Flow**:
1. Looks like a normal calculator app
2. Enter secret code (e.g., "911=") → triggers silent SOS
3. OR: 5 rapid shakes → SOS
4. OR: 3 rapid power button presses → SOS
5. SOS action: GPS capture + 30-sec ambient audio recording + send to 3 emergency contacts
6. NO visible indication that SOS was sent (screen stays on calculator)

**Flutter Tools**: `sensors_plus: ^6.1.1` (already installed), `geolocator`, `record`, `flutter_background_service: ^5.0.6`

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/sos-demo/panic/page.tsx` | Demo page showing the concept (not actual SOS) |

#### Backend
| File | Description |
|------|-------------|
| Uses existing `backend/app/api/v1/endpoints/sos.py` | ✅ EXISTS |

**API**: Existing SOS endpoint + enhanced with audio attachment support

---

### Feature 16: ⚖️ Evidence Blockchain

#### Flutter Screen
| File | Description |
|------|-------------|
| `app/lib/features/legal/evidence_chain_screen.dart` | [NEW] Record anchoring + verification |

**Screen Flow**:
1. "Anchor a Record" → select document type (injury photo, medical report, counselor note)
2. Camera capture or file upload → SHA-256 hash generated → shown to user
3. Hash + timestamp anchored to Merkle tree → confirmation card
4. "Verify a Record" → upload original → compare hash → PASS ✅ / FAIL ❌
5. "Export for Court" → PDF with hash, timestamp, verification instructions

**Flutter Tools**: `crypto: ^3.0.3` (shared with CIN), `camera` (shared with anemia)

#### Web Page
| File | Description |
|------|-------------|
| `web/src/app/nyaya/evidence-chain/page.tsx` | [NEW] Court-ready export + verification |

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/evidence_chain.py` | [NEW] Merkle tree builder + hash anchoring |
| `backend/app/api/v1/endpoints/evidence.py` | [NEW] |

**API**:
- `POST /api/v1/evidence/anchor` → `{ record_bytes, record_type, metadata }` → `{ anchor_hash, merkle_root, timestamp }`
- `POST /api/v1/evidence/verify` → `{ record_bytes, anchor_hash }` → `{ is_valid, tampered }`
- `GET /api/v1/evidence/export/{hash}` → Court-ready PDF

**MongoDB**: `evidence_anchors` — `{ anchor_hash, content_hash, merkle_root, record_type, timestamp }`

**Backend Tools**: `hashlib` (built-in Python), `reportlab` (for PDF generation)

---

---

# 🔧 CROSS-CUTTING PLATFORM FEATURES

## Feature 14: 🔒 Federated Learning

#### Flutter
| File | Description |
|------|-------------|
| `app/lib/features/privacy/federated_dashboard.dart` | [NEW] Privacy transparency screen |

Shows: "0 bytes uploaded", "Model improved by X%", "Your contribution: anonymous"

#### Backend
| File | Description |
|------|-------------|
| `backend/app/services/federated_server.py` | [NEW] FedAvg aggregation |
| `backend/app/api/v1/endpoints/federated.py` | [NEW] |

**API**:
- `POST /api/v1/federated/upload-gradients` → Receive encrypted model deltas
- `GET /api/v1/federated/global-model` → Download latest aggregated model
- `GET /api/v1/federated/stats` → Convergence metrics

---

## Feature 17: 📴 Offline-First AI

#### Flutter
| File | Description |
|------|-------------|
| `app/lib/core/services/offline_engine.dart` | [NEW] Orchestrates all offline capabilities |
| `app/lib/core/services/sync_queue.dart` | [NEW] Queue + conflict resolution |
| `app/lib/core/services/connectivity_monitor.dart` | [NEW] Online/offline state |

**How it works**:
- TFLite models (cough, anemia, voice stress) run locally — no internet needed
- All records saved to Hive first, then synced to MongoDB when online
- Sync badge in app bar shows pending count
- On reconnect: auto-sync with last-write-wins conflict resolution

**Flutter Tools**: `connectivity_plus: ^6.0.5`, `hive` + `hive_flutter`, `workmanager`

---

---

# 📊 MASTER FILE CREATION CHECKLIST

## Backend — All New Files to Create

| File | Feature(s) | Status |
|------|-----------|--------|
| `backend/app/services/anemia_screening.py` | F2 | 🔲 NEW |
| `backend/app/services/fever_map.py` | F3 | 🔲 NEW |
| `backend/app/services/dead_mans_switch.py` | F4 | 🔲 NEW |
| `backend/app/services/bhashini.py` | F5 | 🔲 NEW |
| `backend/app/services/clinical_note_generator.py` | F5 | 🔲 NEW |
| `backend/app/services/dual_prescription.py` | F6 | 🔲 NEW |
| `backend/app/services/adherence_tracker.py` | F8 | 🔲 NEW |
| `backend/app/services/ai_counselor.py` | F10 | 🔲 NEW |
| `backend/app/services/mesh_aggregator.py` | F11 | 🔲 NEW |
| `backend/app/services/digital_twin.py` | F12 | 🔲 NEW |
| `backend/app/services/abdm_bridge.py` | F13 | 🔲 NEW |
| `backend/app/services/fhir_converter.py` | F13 | 🔲 NEW |
| `backend/app/services/federated_server.py` | F14 | 🔲 NEW |
| `backend/app/services/asha_copilot.py` | F15 | 🔲 NEW |
| `backend/app/services/evidence_chain.py` | F16 | 🔲 NEW |
| `backend/app/services/karma_engine.py` | F18 | 🔲 NEW |

## Backend — New Endpoints

| File | Endpoints | Feature(s) |
|------|-----------|-----------|
| `backend/app/api/v1/endpoints/screening.py` | cough-analysis, anemia | F1, F2 |
| `backend/app/api/v1/endpoints/community.py` | report-symptom, fever-map, CIN | F3, F11 |
| `backend/app/api/v1/endpoints/wellness_check.py` | checkin, status, settings | F4 |
| `backend/app/api/v1/endpoints/voice_journal.py` | transcribe, generate-note | F5 |
| `backend/app/api/v1/endpoints/family.py` | add-member, graph, risk | F7 |
| `backend/app/api/v1/endpoints/medicine.py` | schedule, take, adherence | F8 |
| `backend/app/api/v1/endpoints/digital_twin.py` | forecast, what-if | F12 |
| `backend/app/api/v1/endpoints/abdm.py` | link-abha, push, pull | F13 |
| `backend/app/api/v1/endpoints/federated.py` | upload-gradients, global-model | F14 |
| `backend/app/api/v1/endpoints/asha.py` | today-route, visit-report | F15 |
| `backend/app/api/v1/endpoints/evidence.py` | anchor, verify, export | F16 |
| `backend/app/api/v1/endpoints/karma.py` | score, leaderboard, award | F18 |

## Flutter — New Screens

| File | Feature |
|------|---------|
| `app/lib/features/screening/cough_screen.dart` | F1 |
| `app/lib/features/screening/anemia_screen.dart` | F2 |
| `app/lib/features/community/fever_map_screen.dart` | F3 |
| `app/lib/features/wellness/wellness_check_screen.dart` | F4 |
| `app/lib/features/voice/voice_journal_screen.dart` | F5 |
| `app/lib/features/medicine/medicine_reminder_screen.dart` | F8 |
| `app/lib/features/sos/panic_disguise_screen.dart` | F9 |
| `app/lib/features/chat/counselor_chat_screen.dart` | F10 |
| `app/lib/features/twin/digital_twin_screen.dart` | F12 |
| `app/lib/features/abdm/abha_link_screen.dart` | F13 |
| `app/lib/features/privacy/federated_dashboard.dart` | F14 |
| `app/lib/features/asha/asha_copilot_screen.dart` | F15 |
| `app/lib/features/legal/evidence_chain_screen.dart` | F16 |
| `app/lib/features/karma/karma_dashboard_screen.dart` | F18 |

## Web — New Pages

| File | Feature |
|------|---------|
| `web/src/app/screening/cough/page.tsx` | F1 |
| `web/src/app/screening/anemia/page.tsx` | F2 |
| `web/src/app/community/fever-map/page.tsx` | F3 |
| `web/src/app/voice-journal/page.tsx` | F5 |
| `web/src/app/medikiosk/dual-prescription/page.tsx` | F6 |
| `web/src/app/family-health/page.tsx` | F7 |
| `web/src/app/medicine-reminder/page.tsx` | F8 |
| `web/src/app/chat/counselor/page.tsx` | F10 |
| `web/src/app/digital-twin/page.tsx` | F12 |
| `web/src/app/abdm/page.tsx` | F13 |
| `web/src/app/federated/page.tsx` | F14 |
| `web/src/app/asha-copilot/page.tsx` | F15 |
| `web/src/app/nyaya/evidence-chain/page.tsx` | F16 |
| `web/src/app/karma/page.tsx` | F18 |

---

# 🛠️ Master Dependency Summary

## Flutter — All Packages (pubspec.yaml)
```yaml
# Already installed
http: ^1.6.0
flutter_tts: ^4.2.0
speech_to_text: ^7.3.0
sensors_plus: ^6.1.1

# Audio & Recording
record: ^5.1.0
just_audio: ^0.9.39

# Camera & Image
camera: ^0.11.0+2
image: ^4.2.0

# BLE & Mesh
flutter_blue_plus: ^1.32.7
flutter_ble_peripheral: ^0.6.1
crypto: ^3.0.3

# ML
tflite_flutter: ^0.11.0
fftea: ^2.0.1

# Maps & Location
flutter_map: ^7.0.2
latlong2: ^0.9.1
geolocator: ^12.0.0

# Local Storage
hive: ^4.0.0
hive_flutter: ^2.0.0
shared_preferences: ^2.2.2
path_provider: ^2.1.2

# Notifications & Background
flutter_local_notifications: ^17.2.1
workmanager: ^0.5.2
flutter_background_service: ^5.0.6
connectivity_plus: ^6.0.5

# UI
fl_chart: ^0.69.0
graphview: ^1.2.1
confetti: ^0.7.0

# Permissions
permission_handler: ^11.3.0
```

## Backend — requirements.txt additions
```
# Audio
librosa>=0.10.2
soundfile>=0.12.1

# Image
Pillow>=10.3.0
opencv-python-headless>=4.9.0

# ML
scikit-learn>=1.4.0
numpy>=1.26.0
tensorflow-cpu>=2.16.0
transformers>=4.40.0
torch>=2.3.0

# Graph & Geo
networkx>=3.3
geopy>=2.4.1

# Scheduling
apscheduler>=3.10.4

# ABDM/FHIR
fhir.resources>=7.1.0

# PDF generation
reportlab>=4.1.0
```

## Web — npm packages
```bash
npm install recordrtc wavesurfer.js leaflet react-leaflet leaflet.heat \
  react-d3-tree recharts vis-network vis-data canvas-confetti
npm install -D @types/recordrtc @types/leaflet
```
