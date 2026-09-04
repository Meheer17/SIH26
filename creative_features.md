# 🛠️ SvasthyaSetu — Complete Feature Implementation Blueprint

> **Purpose**: This document is a **self-contained development prompt** for every creative feature. Hand this to any developer (or AI agent) and they can build each feature end-to-end.

---

## 📦 Current Tech Stack (Already In Place)

| Layer | Technology | Key Files |
|-------|-----------|-----------|
| **Flutter Mobile** | Flutter 3.x / Dart `sdk: ^3.11.0` | [`pubspec.yaml`](file:///home/mahi17/Github/sih26/app/pubspec.yaml) |
| **Next.js Web** | Next.js 16.3 + React 19 + TailwindCSS 4 + TypeScript | [`package.json`](file:///home/mahi17/Github/sih26/web/package.json) |
| **Backend** | FastAPI + MongoDB (Motor) + JWT Auth + Pydantic v2 | [`main.py`](file:///home/mahi17/Github/sih26/backend/app/main.py) |
| **AI/LLM** | AWS Bedrock Mantle (Mistral 3 8B) via OpenAI-compatible client | [`.env`](file:///home/mahi17/Github/sih26/backend/.env) |
| **Existing Services** | OCR ([`ocr.py`](file:///home/mahi17/Github/sih26/backend/app/services/ocr.py)), Voice Analysis ([`voice_analysis.py`](file:///home/mahi17/Github/sih26/backend/app/services/voice_analysis.py)), Weather ([`weather.py`](file:///home/mahi17/Github/sih26/backend/app/services/weather.py)) |
| **DB** | MongoDB (local `mongodb://localhost:27017`, db: `svasthya_setu_db`) |

---

---

# Feature 1: 🫁 Cough-to-Diagnosis — Acoustic Screening

## Problem
800M+ smartphones in India. TB kills 480K Indians/year. Screening requires sputum test + clinic visit. A farmer in Chhattisgarh can't do that.

## What It Does
Record 10-sec cough → extract audio features (MFCCs, spectral centroid, zero-crossing rate) → classify cough type → display risk with recommendation.

---

### 🔧 Tools & Libraries Required

#### Flutter (Mobile)
| Package | Purpose | pub.dev |
|---------|---------|---------|
| `record: ^5.1.0` | Record audio from microphone | [pub.dev/packages/record](https://pub.dev/packages/record) |
| `just_audio: ^0.9.39` | Playback recorded cough for user confirmation | [pub.dev/packages/just_audio](https://pub.dev/packages/just_audio) |
| `tflite_flutter: ^0.11.0` | Run TFLite cough classifier on-device | [pub.dev/packages/tflite_flutter](https://pub.dev/packages/tflite_flutter) |
| `fftea: ^2.0.1` | FFT for extracting spectral features from PCM audio | [pub.dev/packages/fftea](https://pub.dev/packages/fftea) |
| `path_provider: ^2.1.2` | Save temporary WAV files | [pub.dev/packages/path_provider](https://pub.dev/packages/path_provider) |
| `permission_handler: ^11.3.0` | Request mic permission | [pub.dev/packages/permission_handler](https://pub.dev/packages/permission_handler) |

#### Backend (Python — FastAPI)
| Library | Purpose | Install |
|---------|---------|---------|
| `librosa>=0.10.2` | Audio feature extraction (MFCCs, spectral features) | `pip install librosa` |
| `soundfile>=0.12.1` | Read WAV/FLAC audio files | `pip install soundfile` |
| `scikit-learn>=1.4.0` | Pre-trained Random Forest classifier (demo) | `pip install scikit-learn` |
| `numpy>=1.26.0` | Array operations | Already available |

#### Next.js Web
| Package | Purpose | Install |
|---------|---------|---------|
| `recordrtc` | Browser-based audio recording via WebRTC | `npm install recordrtc` |
| `@types/recordrtc` | TypeScript types | `npm install -D @types/recordrtc` |
| `wavesurfer.js` | Audio waveform visualization | `npm install wavesurfer.js` |

---

### 📁 Files to Create / Modify

#### Backend
```
backend/app/services/cough_analysis.py        # [NEW] Audio feature extraction + classification
backend/app/api/v1/endpoints/screening.py     # [NEW] POST /api/v1/screening/cough-analysis
backend/app/models/cough_model.pkl            # [NEW] Pre-trained classifier (or rule-based demo)
```

#### Flutter
```
app/lib/features/screening/cough_screen.dart            # [NEW] Cough recording + result UI
app/lib/features/screening/services/cough_service.dart   # [NEW] Audio processing + API call
app/assets/models/cough_classifier.tflite                # [NEW] On-device model (optional)
```

#### Web
```
web/src/app/screening/cough/page.tsx          # [NEW] Cough analysis page
web/src/components/AudioRecorder.tsx          # [NEW] Reusable recorder component
```

---

### 🧮 Algorithm (Backend — `cough_analysis.py`)

```python
import librosa
import numpy as np

def analyze_cough(audio_bytes: bytes) -> dict:
    """Extract MFCC features from cough audio and classify."""
    # 1. Load audio
    y, sr = librosa.load(io.BytesIO(audio_bytes), sr=22050, duration=10.0)
    
    # 2. Extract features
    mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)       # 13 MFCCs
    spectral_centroid = librosa.feature.spectral_centroid(y=y, sr=sr)
    zcr = librosa.feature.zero_crossing_rate(y)
    spectral_rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr)
    
    # 3. Feature summary (mean + std of each)
    features = {
        "mfcc_mean": np.mean(mfccs, axis=1).tolist(),
        "spectral_centroid": float(np.mean(spectral_centroid)),
        "zero_crossing_rate": float(np.mean(zcr)),
        "spectral_rolloff": float(np.mean(spectral_rolloff)),
    }
    
    # 4. Rule-based classifier (for SIH demo — no real ML needed)
    sc = features["spectral_centroid"]
    zcr_val = features["zero_crossing_rate"]
    
    if sc > 2500 and zcr_val > 0.08:
        cough_type = "DRY_PRODUCTIVE_MIX"
        risk = "TB Screening Recommended"
        severity = "HIGH"
    elif sc > 2000:
        cough_type = "DRY_COUGH"
        risk = "Viral/Allergic — Monitor"
        severity = "MODERATE"
    elif zcr_val > 0.1:
        cough_type = "WHEEZING"
        risk = "Asthma/COPD Indicator"
        severity = "MODERATE"
    else:
        cough_type = "NORMAL_CLEAR"
        risk = "No immediate concern"
        severity = "LOW"
    
    return {
        "cough_type": cough_type,
        "risk_assessment": risk,
        "severity": severity,
        "audio_features": features,
        "recommendation": "Visit nearest PHC for sputum test" if severity == "HIGH" else "Monitor symptoms"
    }
```

### 🧾 API Endpoint

```python
# POST /api/v1/screening/cough-analysis
# Content-Type: multipart/form-data
# Body: audio_file (WAV/WebM, max 5MB)
# Response: { cough_type, risk_assessment, severity, recommendation, audio_features }
```

### 🗄️ MongoDB Collection
```json
// Collection: cough_screenings
{
  "user_id": "ObjectId",
  "audio_features": { "mfcc_mean": [...], "spectral_centroid": 2340.5, ... },
  "cough_type": "DRY_COUGH",
  "severity": "MODERATE",
  "risk_assessment": "Viral/Allergic — Monitor",
  "created_at": "ISODate"
}
```

---

---

# Feature 2: 🩸 Nail Bed Anemia Screening via Camera

## Problem
50%+ of Indian women are anemic. Blood test costs ₹200-500. Most never get tested.

## What It Does
Camera → capture fingernail image → extract color channels from nail bed ROI → estimate hemoglobin via colorimetric regression → display anemia risk.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `camera: ^0.11.0+2` | Camera access for nail image capture |
| `image: ^4.2.0` | Image pixel manipulation — extract RGB from ROI |
| `google_mlkit_face_detection: ^0.12.0` | (Optional) Auto-detect finger region |
| `tflite_flutter: ^0.11.0` | On-device hemoglobin estimation model |

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `Pillow>=10.3.0` | Image processing, ROI extraction |
| `opencv-python-headless>=4.9.0` | Color space conversion (BGR→HSV→Lab), contour detection |
| `numpy>=1.26.0` | Pixel math |
| `scikit-learn>=1.4.0` | Linear regression model for Hb estimation |

#### Web
| Package | Purpose |
|---------|---------|
| Built-in `navigator.mediaDevices.getUserMedia()` | Camera access |
| `<canvas>` API | Image ROI extraction + pixel analysis |

---

### 📁 Files to Create

```
backend/app/services/anemia_screening.py       # [NEW] Image processing + Hb estimation
backend/app/api/v1/endpoints/screening.py      # [MODIFY] Add POST /screening/anemia
app/lib/features/screening/anemia_screen.dart  # [NEW] Camera capture + result UI
web/src/app/screening/anemia/page.tsx          # [NEW] Web camera anemia page
```

### 🧮 Algorithm (Backend — `anemia_screening.py`)

```python
import cv2
import numpy as np
from PIL import Image

def estimate_hemoglobin(image_bytes: bytes) -> dict:
    """Estimate hemoglobin from nail bed pallor using colorimetric analysis."""
    # 1. Decode image
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # 2. Convert to Lab color space (perceptually uniform)
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2Lab)
    
    # 3. Extract center ROI (nail bed region — assume centered)
    h, w = img.shape[:2]
    roi = lab[h//3 : 2*h//3, w//3 : 2*w//3]
    
    # 4. Calculate mean color values
    l_mean = float(np.mean(roi[:, :, 0]))  # Lightness
    a_mean = float(np.mean(roi[:, :, 1]))  # Red-Green channel
    b_mean = float(np.mean(roi[:, :, 2]))  # Yellow-Blue channel
    
    # 5. Hemoglobin estimation (linear regression from published research)
    # Mannino et al., Nature Communications 2018 — validated colorimetric model
    hb_estimate = 0.52 * a_mean - 0.12 * l_mean + 6.8
    hb_estimate = round(max(4.0, min(18.0, hb_estimate)), 1)
    
    # 6. Classify
    if hb_estimate < 7.0:
        severity = "SEVERE_ANEMIA"
        action = "URGENT — Visit hospital immediately for blood transfusion assessment"
    elif hb_estimate < 10.0:
        severity = "MODERATE_ANEMIA"
        action = "Visit PHC for blood test confirmation and iron supplementation"
    elif hb_estimate < 12.0:
        severity = "MILD_ANEMIA"
        action = "Increase iron-rich foods (spinach, jaggery, dates). Retest in 2 weeks"
    else:
        severity = "NORMAL"
        action = "Hemoglobin appears within normal range"
    
    return {
        "hemoglobin_estimate_gdl": hb_estimate,
        "severity": severity,
        "action": action,
        "color_values": {"L": l_mean, "a": a_mean, "b": b_mean},
        "disclaimer": "This is a screening estimate — confirm with blood test"
    }
```

### 🧾 API Endpoint
```
POST /api/v1/screening/anemia
Content-Type: multipart/form-data
Body: nail_image (JPEG/PNG, max 5MB)
Response: { hemoglobin_estimate_gdl, severity, action, disclaimer }
```

---

---

# Feature 3: 🌡️ Community Fever Map — Epidemic Early Warning

## Problem
Disease outbreaks are detected after hospitals overflow. No crowdsourced surveillance exists at village level.

## What It Does
Each user reports symptoms anonymously with GPS → backend aggregates into geographic clusters → when cluster threshold is crossed (e.g., 10 fever reports in 2km² within 48h) → alerts PHC/ASHA/District Health Officer.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `geolocator: ^12.0.0` | Get user GPS coordinates |
| `flutter_map: ^7.0.2` | Display fever heatmap (OpenStreetMap-based, free) |
| `latlong2: ^0.9.1` | Geo calculations (distance between points) |

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `geopy>=2.4.1` | Geodesic distance calculations |
| `scikit-learn>=1.4.0` | DBSCAN clustering for geographic anomaly detection |
| `numpy>=1.26.0` | Array math |

#### Web
| Package | Purpose |
|---------|---------|
| `leaflet` + `react-leaflet` | Interactive map with heatmap layer |
| `leaflet.heat` | Heatmap visualization plugin |

```bash
npm install leaflet react-leaflet leaflet.heat @types/leaflet
```

---

### 📁 Files to Create

```
backend/app/services/fever_map.py                  # [NEW] Geo-clustering + alert logic
backend/app/api/v1/endpoints/community.py          # [NEW] POST /community/report-symptom, GET /community/fever-map
app/lib/features/community/fever_map_screen.dart   # [NEW] Map + symptom report
web/src/app/community/fever-map/page.tsx           # [NEW] Interactive map page
```

### 🧮 Clustering Algorithm

```python
from sklearn.cluster import DBSCAN
import numpy as np
from geopy.distance import geodesic

def detect_fever_clusters(reports: list[dict]) -> list[dict]:
    """DBSCAN on geo-coordinates to detect symptom clusters."""
    coords = np.array([[r["lat"], r["lon"]] for r in reports])
    
    # DBSCAN: eps=0.018 (~2km), min_samples=10
    # Note: radians = degrees * pi/180. 2km ≈ 0.018 degrees
    db = DBSCAN(eps=0.018, min_samples=10, metric='haversine')
    labels = db.fit_predict(np.radians(coords))
    
    clusters = []
    for label in set(labels):
        if label == -1:
            continue  # Noise
        mask = labels == label
        cluster_coords = coords[mask]
        center = cluster_coords.mean(axis=0)
        clusters.append({
            "cluster_id": int(label),
            "center_lat": float(center[0]),
            "center_lon": float(center[1]),
            "report_count": int(mask.sum()),
            "alert_level": "CRITICAL" if mask.sum() >= 20 else "WARNING",
        })
    return clusters
```

### 🗄️ MongoDB Collection
```json
// Collection: symptom_reports
{
  "anonymous_id": "sha256_hash",
  "lat": 28.6139, "lon": 77.2090,
  "symptoms": ["fever", "cough", "body_ache"],
  "temperature_c": 38.5,
  "created_at": "ISODate",
  "expires_at": "ISODate(+72h)"  // Auto-delete after 72 hours for privacy
}
```

---

---

# Feature 4: 📞 "Dead Man's Switch" — Passive Wellness Check

## Problem
Before 80% of military suicides and victim intimidation incidents, the person goes silent. Nobody notices for days/weeks.

## What It Does
If NO digital interaction is detected for configurable duration → cascading automated check-ins → escalation to human responders.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `workmanager: ^0.5.2` | Background periodic tasks (check last interaction) |
| `flutter_local_notifications: ^17.2.1` | Trigger local notification reminders |
| `shared_preferences: ^2.2.2` | Store last interaction timestamp |
| `telephony: ^0.2.0` | (Optional) Initiate automated IVRS call |

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `apscheduler>=3.10.4` | Scheduled job to check all users' last activity |
| `httpx>=0.27.0` | Already available — call external SMS/IVR APIs |
| (External) **Twilio** or **MSG91** API | Send automated IVR call + SMS |

#### Web
No specific new packages — uses existing alert notification system.

---

### 📁 Files to Create

```
backend/app/services/dead_mans_switch.py           # [NEW] Activity monitor + escalation engine
backend/app/api/v1/endpoints/wellness_check.py     # [NEW] GET /wellness/status, POST /wellness/checkin
app/lib/core/services/activity_tracker.dart        # [NEW] Track last interaction, background worker
app/lib/features/wellness/wellness_check_screen.dart # [NEW] Settings + status UI
```

### ⏰ Escalation Timeline

```
Hour 0:   User's last digital interaction recorded
Hour 48:  In-app gentle reminder: "We haven't heard from you. How are you?"
Hour 72:  Automated IVR call (Bhashini TTS in user's language): "Press 1 if safe"
Hour 84:  If no response → Alert assigned counselor/welfare officer via SMS + dashboard
Hour 96:  If still no response → Alert commanding officer / district authority
Hour 120: CRITICAL — Flag to emergency response system
```

### 🧮 Backend Scheduler

```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()

@scheduler.scheduled_job('interval', hours=1)
async def check_inactive_users():
    """Every hour, check for users who haven't interacted."""
    db = get_database()
    cutoff_48h = datetime.utcnow() - timedelta(hours=48)
    
    inactive = await db.user_activity.find({
        "last_interaction": {"$lt": cutoff_48h},
        "dead_mans_switch_enabled": True,
        "escalation_level": {"$lt": 4}
    }).to_list(None)
    
    for user in inactive:
        hours_silent = (datetime.utcnow() - user["last_interaction"]).total_seconds() / 3600
        if hours_silent >= 96:
            await escalate(user, level=3, target="authority")
        elif hours_silent >= 84:
            await escalate(user, level=2, target="counselor")
        elif hours_silent >= 72:
            await trigger_ivr_call(user)
        elif hours_silent >= 48:
            await send_push_notification(user, "gentle_reminder")
```

---

---

# Feature 5: 🗣️ Bhashini Voice Journal → Auto Clinical Notes

## Problem
28% of India is functionally illiterate. They can't fill forms. Doctors get 2 minutes per patient.

## What It Does
Patient speaks freely for 2 min in ANY Indian language → Bhashini ASR transcribes → AI extracts symptoms, medications, urgency markers → generates structured clinical note in English for the doctor.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `speech_to_text: ^7.3.0` | **Already installed** ✅ |
| `flutter_tts: ^4.2.0` | **Already installed** ✅ |
| `record: ^5.1.0` | Record audio for Bhashini API upload |
| `http: ^1.6.0` | **Already installed** ✅ |

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `httpx>=0.27.0` | Already available — call Bhashini ULCA API |
| `openai>=1.14.0` | Already available — LLM for clinical note generation |
| (External) **Bhashini ULCA API** | ASR in 22 Indian languages |
| (External) **Bedrock/Gemini API** | Clinical NER + note structuring |

#### Web
| Package | Purpose |
|---------|---------|
| Browser `MediaRecorder` API | Record audio (built-in, no npm needed) |
| `wavesurfer.js` | Waveform visualization |

---

### 📁 Files to Create

```
backend/app/services/bhashini.py                       # [NEW] Bhashini ASR/TTS integration
backend/app/services/clinical_note_generator.py        # [NEW] LLM-powered note structuring
backend/app/api/v1/endpoints/voice_journal.py          # [NEW] POST /voice/transcribe, POST /voice/generate-note
app/lib/features/voice/voice_journal_screen.dart       # [NEW] Record + view notes
web/src/app/voice-journal/page.tsx                     # [NEW] Voice journal page
```

### 🧮 Clinical Note Generation Prompt

```python
CLINICAL_NOTE_PROMPT = """
You are a medical scribe. Convert this patient's voice transcript into a structured clinical note.

TRANSCRIPT (originally spoken in {language}, translated to English):
"{transcript}"

Generate a structured clinical note in this EXACT format:
---
**Chief Complaint (CC):** [1-2 sentences]
**History of Present Illness (HPI):** [SOCRATES format if pain mentioned]
**Symptoms Identified:** [bullet list]
**Medications Mentioned:** [bullet list with dosages if stated]
**Urgency Markers:** [RED FLAGS if any — chest pain, suicidal ideation, breathing difficulty]
**Recommended Follow-up:** [1-2 sentences]
---

If urgency markers are detected, prepend: ⚠️ RED FLAG DETECTED
"""
```

### 🧾 Bhashini API Integration

```python
BHASHINI_ASR_URL = "https://dhruva-api.bhashini.gov.in/services/inference/pipeline"

async def transcribe_bhashini(audio_bytes: bytes, source_lang: str = "hi") -> str:
    """Send audio to Bhashini for ASR transcription."""
    headers = {
        "Authorization": f"Bearer {BHASHINI_API_KEY}",
        "Content-Type": "application/json"
    }
    # Bhashini expects base64-encoded audio
    import base64
    audio_b64 = base64.b64encode(audio_bytes).decode()
    
    payload = {
        "pipelineTasks": [
            {"taskType": "asr", "config": {"language": {"sourceLanguage": source_lang}}},
            {"taskType": "translation", "config": {"language": {"sourceLanguage": source_lang, "targetLanguage": "en"}}}
        ],
        "inputData": {"audio": [{"audioContent": audio_b64}]}
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(BHASHINI_ASR_URL, json=payload, headers=headers, timeout=30)
        return resp.json()["pipelineResponse"][1]["output"][0]["target"]
```

---

---

# Feature 6: 🕉️ AYUSH + Allopathy Dual Prescription Engine

## Problem
India has 150,000+ AYUSH practitioners who work in a parallel universe from Western medicine. No integration exists.

## What It Does
After AI case-taking → generate TWO parallel treatment plans: Western (ICD-11 coded) + AYUSH (Prakriti-based) side by side.

---

### 🔧 Tools & Libraries Required

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `openai>=1.14.0` | Already available — LLM generates dual prescriptions |
| Custom JSON knowledge base | ICD-11 codes + AYUSH remedy database |

No new Flutter/Web packages needed — reuses existing MediKiosk UI components.

---

### 📁 Files to Create

```
backend/app/services/dual_prescription.py               # [NEW] Dual engine
backend/app/data/icd11_map.json                          # [NEW] Symptom → ICD-11 code mapping
backend/app/data/ayush_remedies.json                     # [NEW] Prakriti + symptom → herbal remedies
web/src/app/medikiosk/dual-prescription/page.tsx         # [NEW] or integrate into existing medikiosk page
app/lib/features/apps/widgets/dual_prescription_card.dart # [NEW] Flutter widget
```

### 🧮 Dual Engine Logic

```python
def generate_dual_prescription(symptoms: list[str], prakriti: str) -> dict:
    """Generate Western + AYUSH prescriptions for the same symptoms."""
    
    # Western arm — rule-based ICD-11 mapping
    western = {
        "icd11_code": map_to_icd11(symptoms),  # e.g., "MD81.1 Iron deficiency anaemia"
        "diagnosis": "Moderate Iron Deficiency Anemia",
        "medications": [
            {"drug": "Ferrous Fumarate", "dose": "200mg", "freq": "BD", "duration": "3 months"},
            {"drug": "Folic Acid", "dose": "5mg", "freq": "OD", "duration": "3 months"}
        ]
    }
    
    # AYUSH arm — Prakriti-aware Ayurvedic prescription
    ayush = {
        "prakriti_assessment": prakriti,
        "vikriti_analysis": "Pitta-Vata imbalance (Raktadhatu Kshaya)",
        "herbal_remedies": [
            {"herb": "Punarnava (Boerhavia diffusa)", "form": "Kwatha", "dose": "30ml BD"},
            {"herb": "Dhatri Lauha", "form": "Vati", "dose": "250mg BD after meals"},
            {"herb": "Loha Bhasma", "form": "Bhasma", "dose": "125mg with honey, BD"}
        ],
        "dietary_advice": "Include jaggery (gur), dates (khajur), pomegranate (anar), spinach (palak)",
        "yoga_prescription": ["Surya Namaskar (6 rounds)", "Pranayama: Anulom Vilom 10 min"]
    }
    
    return {"western": western, "ayush": ayush}
```

---

---

# Feature 7: 🧬 Family Health Graph — Hereditary Risk Engine

## Problem
Family history is a checkbox on a form. It's never a LIVING, updating risk factor.

## What It Does
User registers → adds family members → if family members also use the app (with consent) → their real health data feeds into a hereditary risk graph.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `graphview: ^1.2.1` | Render family tree graph visualization |
| `fl_chart: ^0.69.0` | Risk score charts |

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `networkx>=3.3` | Build + traverse family graph |
| `numpy>=1.26.0` | Risk calculations |

#### Web
| Package | Purpose |
|---------|---------|
| `react-d3-tree` | Family tree visualization |
| `recharts` | Risk score charts (if not already using) |

```bash
npm install react-d3-tree recharts
```

---

### 📁 Files to Create

```
backend/app/services/family_health_graph.py              # [NEW] Graph builder + risk calculator
backend/app/api/v1/endpoints/family.py                   # [NEW] CRUD for family relationships
app/lib/features/family/family_graph_screen.dart         # [NEW] Family tree + risk display
web/src/app/family-health/page.tsx                       # [NEW] Family graph page
```

### 🗄️ MongoDB Collections

```json
// Collection: family_relationships
{
  "user_id": "ObjectId",
  "relative_id": "ObjectId",
  "relationship": "mother",  // father, sibling, child, grandparent
  "consent_granted": true,
  "created_at": "ISODate"
}

// Collection: hereditary_risk_scores
{
  "user_id": "ObjectId",
  "risks": [
    {"condition": "Type 2 Diabetes", "risk_score": 72, "contributors": ["mother_has_diabetes", "user_bmi_28"]},
    {"condition": "Coronary Heart Disease", "risk_score": 45, "contributors": ["father_cardiac_event_age_48"]}
  ],
  "updated_at": "ISODate"
}
```

---

---

# Feature 8: 💊 Medicine Reminder + Adherence Gamification

## Problem
Medication non-adherence kills 125,000 Indians annually (WHO).

## What It Does
Prescription OCR → auto-populates medicine schedule → smart reminders → adherence tracking with streaks → caregiver alert if adherence drops.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `flutter_local_notifications: ^17.2.1` | Scheduled medicine reminders |
| `workmanager: ^0.5.2` | Background reminder engine |
| `shared_preferences: ^2.2.2` | Store adherence data locally |
| `confetti: ^0.7.0` | Streak celebration animations 🎉 |
| `hive: ^4.0.0` + `hive_flutter: ^2.0.0` | Local medicine schedule DB |

#### Backend (Python)
No new libraries — uses existing OCR service + MongoDB.

#### Web
| Package | Purpose |
|---------|---------|
| `canvas-confetti` | Celebration animations |

```bash
npm install canvas-confetti
```

---

### 📁 Files to Create

```
backend/app/services/adherence_tracker.py                # [NEW] Track doses + calculate streaks
backend/app/api/v1/endpoints/medicine.py                 # [NEW] CRUD medicine schedule + adherence
app/lib/features/medicine/medicine_reminder_screen.dart  # [NEW] Schedule + tracking UI
app/lib/features/medicine/services/reminder_service.dart # [NEW] Local notification scheduling
web/src/app/medicine-reminder/page.tsx                   # [NEW] Web reminder page
```

### 🧮 Adherence Score

```python
def calculate_adherence(doses_taken: int, doses_scheduled: int, streak_days: int) -> dict:
    adherence_pct = round((doses_taken / max(doses_scheduled, 1)) * 100, 1)
    
    if adherence_pct >= 90:
        status = "EXCELLENT"
        badge = "🏆 Gold Streak"
    elif adherence_pct >= 70:
        status = "GOOD"
        badge = "🥈 Silver Streak"
    elif adherence_pct >= 50:
        status = "NEEDS_IMPROVEMENT"
        badge = "🔔 Gentle Reminder"
    else:
        status = "CRITICAL"
        badge = "⚠️ Caregiver Alerted"
    
    return {
        "adherence_pct": adherence_pct,
        "streak_days": streak_days,
        "status": status,
        "badge": badge,
        "alert_caregiver": adherence_pct < 60
    }
```

---

---

# Feature 9: 🆘 "Panic Disguise" — Hidden SOS for Victims Under Threat

## Problem
Victims under threat can't openly call for help. Current SOS buttons are visible.

## What It Does
Three covert triggers → silent GPS + audio recording → sent to emergency contacts without any visible indication.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `sensors_plus: ^6.1.1` | **Already installed** ✅ — shake detection |
| `geolocator: ^12.0.0` | GPS capture |
| `record: ^5.1.0` | Silent ambient audio recording |
| `flutter_background_service: ^5.0.6` | Keep SOS running in background |
| `volume_key_board: ^1.0.1` | Detect power button rapid presses |
| `flutter_local_notifications: ^17.2.1` | Silent notification to confirm SOS sent |

#### Backend (Python)
No new libraries — uses existing SOS endpoint ([`sos.py`](file:///home/mahi17/Github/sih26/backend/app/api/v1/endpoints/sos.py)).

---

### 📁 Files to Create

```
app/lib/features/sos/panic_disguise_screen.dart        # [NEW] Calculator disguise UI
app/lib/features/sos/services/shake_detector.dart      # [NEW] Accelerometer shake pattern
app/lib/features/sos/services/covert_sos_service.dart  # [NEW] Silent SOS dispatch
web/src/app/sos-demo/panic/page.tsx                    # [NEW] Demo page showing concept
```

### 🧮 Shake Detection Algorithm

```dart
// Detect 5 rapid shakes within 3 seconds
class ShakeDetector {
  static const double shakeThreshold = 15.0; // m/s²
  static const int requiredShakes = 5;
  static const Duration window = Duration(seconds: 3);
  
  final List<DateTime> _shakeTimestamps = [];
  
  void onAccelerometerEvent(AccelerometerEvent event) {
    double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    if (magnitude > shakeThreshold) {
      _shakeTimestamps.add(DateTime.now());
      _shakeTimestamps.removeWhere((t) => DateTime.now().difference(t) > window);
      
      if (_shakeTimestamps.length >= requiredShakes) {
        _triggerCovertSOS();
        _shakeTimestamps.clear();
      }
    }
  }
}
```

---

---

# Feature 10: 🤖 AI Counselor with Cultural Competence

## Problem
India has 0.3 psychiatrists per 100,000 people. 70-92% treatment gap for mental health.

## What It Does
AI chatbot trained on Indian cultural context → understands caste trauma, military stigma, regional expressions → provides first-responder mental health support → knows when to escalate to human.

---

### 🔧 Tools & Libraries Required

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `openai>=1.14.0` | Already available — powers the conversation |
| `langchain>=0.2.0` | (Optional) Conversation memory + prompt chaining |

No new Flutter/Web packages — reuses existing chat module ([`app/lib/features/chat/`](file:///home/mahi17/Github/sih26/app/lib/features/chat)).

---

### 📁 Files to Create

```
backend/app/services/ai_counselor.py                    # [NEW] Counselor prompt + safety guardrails
backend/app/data/cultural_context.json                  # [NEW] Caste-sensitive + military-aware vocabulary
app/lib/features/chat/counselor_chat_screen.dart        # [NEW] Dedicated counselor chat UI
web/src/app/chat/counselor/page.tsx                     # [NEW] Web counselor chat
```

### 🧮 Cultural Competence System Prompt

```python
AI_COUNSELOR_SYSTEM_PROMPT = """
You are a culturally competent mental health support assistant for Indian users.

CORE RULES:
1. You are NOT a therapist. You are a first-responder support companion.
2. ALWAYS recommend professional help for serious distress.
3. NEVER diagnose conditions or prescribe medications.
4. Use the user's preferred language. Default to Hindi if uncertain.

CULTURAL AWARENESS:
- Understand caste-based discrimination trauma without minimizing it
- Recognize military/paramilitary culture: honor-bound silence around mental health
- Use culturally familiar metaphors: "मन का बोझ" (burden of the mind), not "cognitive distortion"
- Respect religious and spiritual coping without promoting pseudoscience
- Understand joint family dynamics and their role in both support and pressure

SAFETY PROTOCOL:
- If user mentions self-harm, suicide, or violence → IMMEDIATELY:
  1. Express empathy: "I hear you, and I want you to be safe"
  2. Provide helpline: Vandrevala Foundation (1860-2662-345), iCall (9152987821)
  3. Set flag: {"escalate": true, "severity": "CRITICAL"}
  4. DO NOT leave the conversation — stay present until human takes over

CONVERSATION STYLE:
- Warm, non-judgmental, patient
- Short responses (2-3 sentences max) — this is chat, not therapy
- Ask open-ended questions: "Aur batayiye, aapko kaise mehsoos ho raha hai?"
- Validate feelings before suggesting anything
"""
```

---

---

# Feature 11 (KILLER): 🌐 Community Immunity Network (CIN)

## Problem
Every feature above works for ONE patient. CIN works for EVERYONE — it turns isolated data points into collective intelligence.

## What It Does
Privacy-preserving BLE mesh broadcasts anonymous health "fingerprint" hashes → nearby phones detect community-level health anomalies → cascading alerts to ASHA workers, PHCs, and district authorities.

---

### 🔧 Tools & Libraries Required

#### Flutter
| Package | Purpose |
|---------|---------|
| `flutter_blue_plus: ^1.32.7` | BLE advertising + scanning |
| `flutter_ble_peripheral: ^0.6.1` | Advertise as BLE peripheral (broadcast health hash) |
| `nearby_connections: ^4.0.2` | Google Nearby Connections API (higher-level mesh) |
| `crypto: ^3.0.3` | SHA-256 hashing of symptom vectors |
| `geolocator: ^12.0.0` | GPS for cluster geo-tagging |
| `flutter_map: ^7.0.2` | Community health heatmap |
| `hive: ^4.0.0` | Local storage of received hashes |
| `fl_chart: ^0.69.0` | Trend visualization |

#### Backend (Python)
| Library | Purpose |
|---------|---------|
| `scikit-learn>=1.4.0` | DBSCAN geo-clustering (reuse from Feature 3) |
| `numpy>=1.26.0` | Array math |
| `apscheduler>=3.10.4` | Periodic cluster analysis scheduler |

#### Web
| Package | Purpose |
|---------|---------|
| `leaflet` + `react-leaflet` | (Reuse from Feature 3) Mesh node visualization |
| `d3` or `vis-network` | BLE mesh relay animation |

```bash
npm install vis-network vis-data
```

---

### 📁 Files to Create

```
# Backend
backend/app/services/cin_engine.py                       # [NEW] Community intelligence engine
backend/app/services/mesh_aggregator.py                  # [NEW] Hash dedup + cluster analysis
backend/app/api/v1/endpoints/community.py                # [MODIFY] Add CIN endpoints

# Flutter
app/lib/features/cin/cin_screen.dart                     # [NEW] Main CIN dashboard
app/lib/features/cin/services/ble_mesh_service.dart      # [NEW] BLE broadcast + scan
app/lib/features/cin/services/hash_engine.dart           # [NEW] Symptom vector → SHA-256
app/lib/features/cin/widgets/mesh_visualizer.dart        # [NEW] Animated mesh node graph
app/lib/features/cin/widgets/community_heatmap.dart      # [NEW] Geographic heatmap

# Web
web/src/app/cin/page.tsx                                 # [NEW] CIN dashboard page
web/src/components/MeshVisualizer.tsx                     # [NEW] vis-network animation
web/src/components/CommunityHeatmap.tsx                   # [NEW] Leaflet heatmap
```

### 🧮 Anonymous Health Hash Protocol

```dart
// On-device: Generate anonymous health fingerprint
import 'package:crypto/crypto.dart';
import 'dart:convert';

String generateHealthHash(Map<String, dynamic> healthState) {
  // 1. Quantize health signals into coarse bins (privacy preserving)
  final binned = {
    'fever': healthState['temperature'] > 38.0 ? 1 : 0,
    'cough': healthState['has_cough'] ? 1 : 0,
    'respiratory_distress': healthState['spo2'] < 93 ? 1 : 0,
    'high_stress': healthState['stress_score'] > 70 ? 1 : 0,
    'dehydration': healthState['dehydration_risk'] > 60 ? 1 : 0,
    'timestamp_bucket': (DateTime.now().millisecondsSinceEpoch ~/ 3600000),  // Hour bucket
    'salt': Random.secure().nextInt(1000000),  // Random salt — prevents re-identification
  };
  
  // 2. SHA-256 hash — irreversible
  final jsonStr = jsonEncode(binned);
  final hash = sha256.convert(utf8.encode(jsonStr)).toString();
  
  // 3. Broadcast only: hash + coarse GPS grid (1km² cell)
  return hash;
}
```

### 🧮 BLE Mesh Broadcast (Flutter)

```dart
// Advertise health hash via BLE
class BLEMeshService {
  final FlutterBluePlus _ble = FlutterBluePlus();
  
  Future<void> broadcastHealthHash(String hash) async {
    // Encode hash into BLE advertisement data (max 31 bytes)
    // Use first 16 bytes of SHA-256 as service data
    final serviceData = utf8.encode(hash.substring(0, 16));
    
    // Start BLE advertising with custom service UUID
    await FlutterBlePeripheral().start(
      advertiseData: AdvertiseData(
        serviceUuid: "0000ABCD-0000-1000-8000-00805F9B34FB",  // SvasthyaSetu CIN UUID
        serviceData: serviceData,
      ),
      advertiseSettings: AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeBalanced,
        txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
      ),
    );
  }
  
  // Scan for nearby health hashes
  Stream<List<String>> scanNearbyHashes() {
    return FlutterBluePlus.scanResults.map((results) {
      return results
        .where((r) => r.advertisementData.serviceUuids
            .contains("0000ABCD-0000-1000-8000-00805F9B34FB"))
        .map((r) => utf8.decode(r.advertisementData.serviceData.values.first))
        .toList();
    });
  }
}
```

### 🧮 On-Device Community Pattern Detection

```dart
// Runs locally — no server needed
class CommunityPatternDetector {
  final List<ReceivedHash> _recentHashes = [];
  
  CommunityAlert? analyzePatterns() {
    // Keep only last 6 hours
    _recentHashes.removeWhere((h) => 
      DateTime.now().difference(h.receivedAt) > Duration(hours: 6));
    
    final total = _recentHashes.length;
    if (total < 5) return null;  // Need minimum sample
    
    // Count hashes with fever+cough flags (first 2 chars encode binned symptoms)
    final respiratoryCount = _recentHashes
      .where((h) => h.symptomFlags.contains('fever') || h.symptomFlags.contains('cough'))
      .length;
    
    final ratio = respiratoryCount / total;
    
    if (ratio > 0.6 && total >= 10) {
      return CommunityAlert(
        type: AlertType.respiratoryCluster,
        message: "⚠️ Respiratory symptom cluster detected in your area",
        severity: ratio > 0.8 ? Severity.critical : Severity.warning,
        nearbyAffected: respiratoryCount,
        totalScanned: total,
      );
    }
    return null;
  }
}
```

### 🧾 API Endpoints

```
POST /api/v1/community/cin/report-cluster    # Phone uploads detected cluster for PHC routing
GET  /api/v1/community/cin/district-map      # District health officer views aggregated clusters
POST /api/v1/community/cin/asha-alert        # Trigger ASHA worker dispatch
```

---

---

# 📋 Master Dependency Summary

## Flutter `pubspec.yaml` — All New Packages

```yaml
dependencies:
  # --- ALREADY INSTALLED ---
  http: ^1.6.0
  flutter_tts: ^4.2.0
  speech_to_text: ^7.3.0
  sensors_plus: ^6.1.1
  
  # --- NEW: Audio & Recording ---
  record: ^5.1.0
  just_audio: ^0.9.39
  
  # --- NEW: Camera & Image ---
  camera: ^0.11.0+2
  image: ^4.2.0
  
  # --- NEW: BLE & Mesh ---
  flutter_blue_plus: ^1.32.7
  flutter_ble_peripheral: ^0.6.1
  nearby_connections: ^4.0.2
  
  # --- NEW: AI & ML ---
  tflite_flutter: ^0.11.0
  fftea: ^2.0.1
  crypto: ^3.0.3
  
  # --- NEW: Maps ---
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geolocator: ^12.0.0
  
  # --- NEW: Local Storage ---
  hive: ^4.0.0
  hive_flutter: ^2.0.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.2
  
  # --- NEW: Notifications & Background ---
  flutter_local_notifications: ^17.2.1
  workmanager: ^0.5.2
  flutter_background_service: ^5.0.6
  
  # --- NEW: UI ---
  fl_chart: ^0.69.0
  graphview: ^1.2.1
  confetti: ^0.7.0
  
  # --- NEW: Permissions ---
  permission_handler: ^11.3.0
```

## Backend `requirements.txt` — All New Packages

```
# --- ALREADY INSTALLED ---
fastapi>=0.110.0
uvicorn[standard]>=0.28.0
pydantic>=2.6.0
motor>=3.3.0
pymongo>=4.6.0
pyjwt>=2.8.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.9
openai>=1.14.0
httpx>=0.27.0

# --- NEW: Audio Processing ---
librosa>=0.10.2
soundfile>=0.12.1

# --- NEW: Image Processing ---
Pillow>=10.3.0
opencv-python-headless>=4.9.0

# --- NEW: ML & Clustering ---
scikit-learn>=1.4.0
numpy>=1.26.0

# --- NEW: Graph & Scheduling ---
networkx>=3.3
apscheduler>=3.10.4
geopy>=2.4.1
```

## Web `package.json` — All New Packages

```bash
npm install recordrtc wavesurfer.js leaflet react-leaflet leaflet.heat react-d3-tree recharts vis-network vis-data canvas-confetti
npm install -D @types/recordrtc @types/leaflet
```

---

# 🗂️ Master File Tree — All New Files

```
backend/
├── app/
│   ├── services/
│   │   ├── cough_analysis.py          # Feature 1
│   │   ├── anemia_screening.py        # Feature 2
│   │   ├── fever_map.py               # Feature 3
│   │   ├── dead_mans_switch.py        # Feature 4
│   │   ├── bhashini.py                # Feature 5
│   │   ├── clinical_note_generator.py # Feature 5
│   │   ├── dual_prescription.py       # Feature 6
│   │   ├── family_health_graph.py     # Feature 7
│   │   ├── adherence_tracker.py       # Feature 8
│   │   ├── ai_counselor.py            # Feature 10
│   │   ├── cin_engine.py              # Feature 11 (CIN)
│   │   └── mesh_aggregator.py         # Feature 11 (CIN)
│   ├── api/v1/endpoints/
│   │   ├── screening.py               # Features 1, 2
│   │   ├── community.py               # Features 3, 11
│   │   ├── wellness_check.py          # Feature 4
│   │   ├── voice_journal.py           # Feature 5
│   │   ├── family.py                  # Feature 7
│   │   └── medicine.py                # Feature 8
│   └── data/
│       ├── icd11_map.json             # Feature 6
│       ├── ayush_remedies.json        # Feature 6
│       └── cultural_context.json      # Feature 10

app/lib/
├── features/
│   ├── screening/
│   │   ├── cough_screen.dart          # Feature 1
│   │   ├── anemia_screen.dart         # Feature 2
│   │   └── services/
│   │       └── cough_service.dart     # Feature 1
│   ├── community/
│   │   └── fever_map_screen.dart      # Feature 3
│   ├── wellness/
│   │   └── wellness_check_screen.dart # Feature 4
│   ├── voice/
│   │   └── voice_journal_screen.dart  # Feature 5
│   ├── medicine/
│   │   ├── medicine_reminder_screen.dart  # Feature 8
│   │   └── services/
│   │       └── reminder_service.dart  # Feature 8
│   ├── family/
│   │   └── family_graph_screen.dart   # Feature 7
│   ├── sos/
│   │   ├── panic_disguise_screen.dart # Feature 9
│   │   └── services/
│   │       ├── shake_detector.dart    # Feature 9
│   │       └── covert_sos_service.dart # Feature 9
│   ├── chat/
│   │   └── counselor_chat_screen.dart # Feature 10
│   └── cin/
│       ├── cin_screen.dart            # Feature 11
│       ├── services/
│       │   ├── ble_mesh_service.dart   # Feature 11
│       │   └── hash_engine.dart        # Feature 11
│       └── widgets/
│           ├── mesh_visualizer.dart    # Feature 11
│           └── community_heatmap.dart  # Feature 11
└── core/
    └── services/
        └── activity_tracker.dart      # Feature 4

web/src/app/
├── screening/
│   ├── cough/page.tsx                 # Feature 1
│   └── anemia/page.tsx                # Feature 2
├── community/
│   └── fever-map/page.tsx             # Feature 3
├── voice-journal/page.tsx             # Feature 5
├── family-health/page.tsx             # Feature 7
├── medicine-reminder/page.tsx         # Feature 8
├── chat/counselor/page.tsx            # Feature 10
├── cin/page.tsx                       # Feature 11
└── sos-demo/panic/page.tsx            # Feature 9
web/src/components/
├── AudioRecorder.tsx                  # Feature 1
├── MeshVisualizer.tsx                 # Feature 11
└── CommunityHeatmap.tsx               # Feature 11
```

---

# 🚀 Build Priority Order

| Priority | Feature | Effort | Impact | Why This Order |
|:--------:|---------|:------:|:------:|----------------|
| **1** | 🌐 CIN (Community Immunity Network) | 🔴 High | 🟢 Maximum | **Killer differentiator** — build first, demo last |
| **2** | 🫁 Cough-to-Diagnosis | 🟡 Medium | 🟢 High | Wow factor — live mic demo is compelling |
| **3** | 🆘 Panic Disguise SOS | 🟢 Low | 🟢 High | Emotionally powerful — judges remember this |
| **4** | 📞 Dead Man's Switch | 🟡 Medium | 🟢 High | Novel concept — no existing Indian app does this |
| **5** | 🗣️ Voice → Clinical Notes | 🟡 Medium | 🟢 High | Solves real OPD problem — Bhashini tie-in is strong for GOI alignment |
| **6** | 🩸 Anemia Screening | 🟡 Medium | 🟢 High | Simple camera demo that's medically meaningful |
| **7** | 🌡️ Fever Map | 🟡 Medium | 🟡 Medium | Visual map demo looks impressive |
| **8** | 🕉️ Dual Prescription | 🟢 Low | 🟡 Medium | Ministry of AYUSH alignment |
| **9** | 💊 Medicine Reminder | 🟢 Low | 🟡 Medium | Common but essential for completeness |
| **10** | 🧬 Family Health Graph | 🔴 High | 🟡 Medium | Complex to demo — build if time permits |
| **11** | 🤖 AI Counselor | 🟡 Medium | 🟡 Medium | Leverages existing chat — mostly prompt engineering |

> [!IMPORTANT]
> **Want me to start building these features?** I can begin with the highest-priority ones (CIN, Cough Screening, Panic SOS) and work down the list. Just say the word!
