# SvasthyaSetu (Bridge to Health) — SIH 2026 Testing & Feature Guide

> **Unified Platform for Smart India Hackathon 2026**
> Integrating: **SIH26181** (Qualcomm), **SIH26047** (Ministry of Ayush), **SIH26186** (Ministry of Home Affairs), and **SIH26094** (Ministry of Social Justice & Empowerment).

---

## 📋 Table of Contents
1. [Where to Login & Role Switching in Mobile App](#1-where-to-login--role-switching-in-mobile-app)
2. [Demo Test Accounts Cheatsheet](#2-demo-test-accounts-cheatsheet)
3. [The 4 Problem Statement Applications (Testing Guide)](#3-the-4-problem-statement-applications)
   - [🫀 ArogyaSathi (SIH26181 — Qualcomm)](#1-arogyasathi-sih26181--qualcomm)
   - [🏥 MediKiosk (SIH26047 — Ayush)](#2-medikiosk-sih26047--ayush)
   - [🎖️ RakshakMitra (SIH26186 — MHA / Armed Forces)](#3-rakshakmitra-sih26186--mha--armed-forces)
   - [⚖️ NyayaSahay (SIH26094 — MoSJE / Legal-Forensic)](#4-nyayasahay-sih26094--mosje--legal-forensic)
4. [The 8 Breakthrough Innovations (Testing Guide)](#4-the-8-breakthrough-innovations)
   - [1. Community Immunity Network (CIN BLE Mesh)](#1-community-immunity-network-cin)
   - [2. Acoustic Cough & Palmar Anemia AI Screening](#2-acoustic-cough--palmar-anemia-ai-screening)
   - [3. Panic Disguise SOS (Stealth Calculator)](#3-panic-disguise-sos-stealth-calculator)
   - [4. Family Health Risk Graph (Genogram Lineage AI)](#4-family-health-risk-graph)
   - [5. 3D Organ Digital Twin & Health Karma](#5-3d-organ-digital-twin--health-karma)
   - [6. On-Device Federated Learning (FedAvg)](#6-on-device-federated-learning-fedavg)
   - [7. ASHA Field Copilot (Maternal ANC Triage)](#7-asha-field-copilot)
   - [8. BSA 2023 Tamper-Evident Evidence Chain](#8-bsa-2023-tamper-evident-evidence-chain)
5. [Platform Shared Services & Tools](#5-platform-shared-services--tools)
   - [1-Tap Emergency SOS Dispatcher](#1-tap-emergency-sos-dispatcher)
   - [SvasthyaStorage Encrypted SDK Demo](#svasthyastorage-encrypted-sdk-demo)
   - [DPDP Act 2023 Consent Manager](#dpdp-act-2023-consent-manager)
   - [Admin RBAC Matrix](#admin-rbac-matrix)
   - [Multi-Agent Clinical AI Reasoning Hub](#multi-agent-clinical-ai-reasoning-hub)
6. [Website Route Directory & Navigation](#6-website-route-directory--navigation)
7. [Machine Learning Models Deep Dive (`models/`)](#7-machine-learning-models-deep-dive)

---

## 1. Where to Login & Role Switching in Mobile App

The mobile application provides three convenient ways to log in and switch personas:

```
+-----------------------------------------------------------------------+
|  [SS] SvasthyaSetu Unified                      [SOS Icon]  [LOGIN]   | <-- 1. Top AppBar Login Button
+-----------------------------------------------------------------------+
|  Quick Demo Switcher:                                                 |
|  [ 🫀 Patient ]  [ 🏥 Doctor ]  [ 🎖️ Officer ]  [ ⚖️ Counselor ]       | <-- 2. 1-Tap Quick Persona Chips
+-----------------------------------------------------------------------+
|  [Apps]       [Innovations]     [AI Chat]     [Tools & SOS] [Account] | <-- 3. Bottom Nav Tabs (5 Tabs)
+-----------------------------------------------------------------------+
```

1. **Top-Right AppBar Button**:
   - Tap **"Login"** (or the User Avatar circle if logged in) at the top right of the screen.
   - When authenticated, tapping the avatar reveals a dropdown menu with shortcuts to the **Admin Role Matrix**, **DPDP Consent Manager**, and **Sign Out**.
2. **Account Tab (Tab 4 on Bottom Bar)**:
   - Tap **"Account"** at the bottom navigation bar.
   - Displays your ABHA Health ID, Aadhaar KYC verification status, assigned RBAC permissions, and **1-Tap Quick Demo Login Buttons**.
3. **1-Tap Quick Switcher on the Apps Tab (Tab 0)**:
   - Tap any chip at the top of the **Apps** tab to immediately authenticate into that persona without typing passwords.

---

## 2. Demo Test Accounts Cheatsheet

| Role Persona | Target Application | Email | Password | Primary Capabilities |
|---|---|---|---|---|
| **Rural Patient** | ArogyaSathi & MediKiosk | `arogya_user@example.com` | `demo123456` | Vitals monitoring, voice intake, personal records |
| **OPD Physician** | MediKiosk | `dr_sharma@hospital.org` | `demo123456` | OPD Physician Queue, red flag triage, dual prescription |
| **Forces Officer** | RakshakMitra | `capt_verma@forces.gov.in` | `demo123456` | Wellbeing logs, Unit Stress Heatmap, welfare alerts |
| **Legal Counselor** | NyayaSahay | `legal_officer@district.gov.in` | `demo123456` | Distress logs, Atrocity Escalation Desk, intervention |

---

## 3. The 4 Problem Statement Applications

### 1. 🫀 ArogyaSathi (SIH26181 — Qualcomm)
*Disaster Health, Vital Signs Telemetry & Heat Stress Monitoring*

- **Core Capabilities**:
  - Continuous vital signs capture (Heart Rate, SpO2, Body Temp, Ambient Temp, Humidity, Hydration).
  - Open-Meteo live weather integration for real-time localized weather data.
  - Heat stress calculation with NDMA guideline severity classification (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`).
  - Native multi-lingual Text-To-Speech (TTS) audio advisory.
  - Real-time physical accelerometer fall detection with a 5-second cancel countdown and auto-SOS.
- **Step-by-Step Testing Procedure**:
  1. Open the **Apps** tab $\rightarrow$ tap **"Launch ArogyaSathi App"** (or navigate to `/arogya` on the web).
  2. Tap **"Fetch Live Weather"** to auto-fill ambient temperature and humidity for current GPS coordinates.
  3. Enter vitals:
     - Heart Rate: `112 bpm`
     - SpO2: `93 %`
     - Body Temp: `38.8 °C`
     - Activity Level: `Heavy`
     - Time Since Water: `120 mins`
  4. Tap **"Record & Compute Heat Stress"**:
     - The app evaluates the heat stress index, classifies it as `CRITICAL`, triggers a warning banner, and speaks the hydration advisory aloud over device speakers.
  5. **Test Fall Detection**: Shake the phone vigorously. An emergency dialog will appear with a 5-second countdown timer before auto-dispatching SOS.

---

### 2. 🏥 MediKiosk (SIH26047 — Ayush)
*Offline-First Pre-OPD Clinical History Intake & Triage*

- **Core Capabilities**:
  - Voice-dictated clinical intake using native on-device speech-to-text.
  - Structured clinical history capture using the SOCRATES protocol (Site, Onset, Character, Radiation, Associations, Timing, Exacerbating, Severity).
  - AYUSH Prakriti Tridosha profile toggle (Vata / Pitta / Kapha).
  - Dual prescription engine reconciling Allopathic medicine with AYUSH formulations.
  - Doctor's OPD Triage Queue with red-flag severity prioritization.
- **Step-by-Step Testing Procedure**:
  1. **Patient Workflow** (logged in as `arogya_user@example.com`):
     - Tap **"Voice Dictate Intake"** to speak symptoms into the microphone.
     - Toggle the **AYUSH Prakriti Mode** switch.
     - Enter chief complaint: *"Persistent dry cough for 3 days with throat irritation."*
     - Tap **"Submit Clinical Intake"** $\rightarrow$ App returns Triage Status: `Yellow (Moderate)` and plays audible confirmation.
  2. **Doctor Workflow** (switch to `dr_sharma@hospital.org`):
     - Open MediKiosk: The screen switches to the **OPD Physician Queue**.
     - Tap the newly submitted intake card to view red flag indicators, vital stats, and dual-prescription recommendations.

---

### 3. 🎖️ RakshakMitra (SIH26186 — MHA / Armed Forces)
*Burnout Predictor & Mental Wellbeing for Defense Personnel*

- **Core Capabilities**:
  - Multi-factor Burnout Index computation based on deployment duration, leave gap ratio, duty hours, and subjective assessments.
  - Voice journal dictation with acoustic prosodic analysis.
  - Garrison / Unit Stress Heatmap for Welfare Officers to spot burnout clusters.
  - Proactive welfare intervention alerts.
- **Step-by-Step Testing Procedure**:
  1. **Soldier Workflow** (logged in as `capt_verma@forces.gov.in`):
     - Enter deployment metrics:
       - Deployment Days: `120`
       - Leave Gap Ratio: `0.85`
       - Duty Hours / Week: `68`
       - Subjective Assessment: `17 / 20`
     - Tap **"Voice Journal Dictation"** to log audio thoughts: *"Long border duty shifts with disrupted sleep."*
     - Tap **"Calculate & Record Wellbeing"** $\rightarrow$ Burnout Index evaluated at `78 / 100` (`CRITICAL`), accompanied by spoken audio feedback.
  2. **Welfare Officer Workflow**:
     - Scroll down to the **Unit Stress Heatmap** to inspect garrison battalion stress levels (e.g., *Alpha Company: 82% Critical*).

---

### 4. ⚖️ NyayaSahay (SIH26094 — MoSJE / Legal-Forensic)
*Psychological & Legal Rehabilitation for Atrocity Victims*

- **Core Capabilities**:
  - Longitudinal psychological distress scoring correlated with legal case stage milestones (`FIR Filed` $\rightarrow$ `Investigation` $\rightarrow$ `Chargesheet` $\rightarrow$ `Trial` $\rightarrow$ `Post-Trial`).
  - Voice stress acoustic prosody analysis (pitch variance, jitter, pause ratio).
  - Legal Counselor Escalation Desk with incident case notes and emergency intervention protocols.
- **Step-by-Step Testing Procedure**:
  1. **Victim Workflow**:
     - Select Case Stage: `Trial`.
     - Enter days since incident: `120`.
     - In the diary check-in, type: *"Extremely anxious about court trial testimony tomorrow."*
     - Tap **"Analyze Voice & Text Stress"** $\rightarrow$ Prosodic score evaluated at `78.5%` (`High Stress - Fearful`).
     - Tap **"Submit Wellbeing Log"** $\rightarrow$ Updates distress trajectory and triggers counselor alert if score $> 70$.
  2. **Legal Counselor Workflow** (logged in as `legal_officer@district.gov.in`):
     - Inspect the **Atrocity Escalation Desk** to review flagged cases requiring immediate legal counseling and witness protection assistance.

---

## 4. The 8 Breakthrough Innovations

Access these features via **Bottom Tab 1 ("Innovations")** on mobile or the **Innovations Grid** on the website (`/#innovations`).

| # | Innovation Module | Mobile Screen | Web Route | Interactive Testing Flow |
|---|---|---|---|---|
| **1** | **Community Immunity Network (CIN)** | Tab 1 $\rightarrow$ *CIN Mesh Swarm* | `/cin` | Tap **"Simulate BLE Node Discovery"** to establish peer-to-peer mesh gossip syncing epidemic tokens without internet or SIM. |
| **2** | **Acoustic Cough & Palmar Anemia** | Tab 1 $\rightarrow$ *Acoustic Cough & Anemia* | `/screening` | 1. Tap **"Record Cough Audio"** to run Zero Crossing Rate & spectral analysis for TB/Wheeze screening.<br>2. Tap **"Capture Palmar Image"** to run RGB colorimetry for non-invasive Hb (g/dL) estimation. |
| **3** | **Panic Disguise SOS (Stealth Calculator)** | Tab 1 $\rightarrow$ *Panic Disguise SOS* | `/covert-sos` | A functioning math calculator. Type `9999=` or shake the phone to trigger stealth silent emergency dispatch. |
| **4** | **Family Health Risk Graph** | Tab 1 $\rightarrow$ *Family Health Risk Graph* | `/family-graph` | Interactive pedigree lineage genogram calculating hereditary diabetes, cardiac, and sickle-cell risk scores. |
| **5** | **3D Organ Digital Twin & Karma** | Tab 1 $\rightarrow$ *Groundbreaking Suite* (Tab 0/1) | `/digital-twin` & `/karma` | Real-time cardiovascular, pulmonary, and metabolic score simulation + gamified Karma wellness rewards. |
| **6** | **On-Device Federated AI** | Tab 1 $\rightarrow$ *Groundbreaking Suite* (Tab 2) | `/federated` | Displays privacy-preserving on-device gradient aggregation (`FedAvg`) rounds and local accuracy. |
| **7** | **ASHA Field Copilot** | Tab 1 $\rightarrow$ *Groundbreaking Suite* (Tab 3) | `/asha` | MoHFW Ante-Natal Care high-risk maternal triage decision tree for rural frontline workers. |
| **8** | **BSA 2023 Evidence Chain** | Tab 1 $\rightarrow$ *Groundbreaking Suite* (Tab 4) | `/evidence` | Bharatiya Sakshya Adhiniyam Sec 63 compliant SHA-256 Merkle tree evidence locker. |

---

## 5. Platform Shared Services & Tools

Access these features via **Bottom Tab 3 ("Tools & SOS")** on mobile or the **Platform Services Grid** on the website (`/#features`).

### 1-Tap Emergency SOS Dispatcher
- **Mobile**: Top AppBar SOS icon or Tab 3 $\rightarrow$ *1-Tap Emergency SOS*.
- **Web**: `/sos-demo`.
- **How to test**: Tap the red emergency button. The app captures GPS coordinates, vitals snapshot, and plays an audible 5-second countdown with an immediate **"Cancel"** option before sending alerts to emergency services.

### SvasthyaStorage Encrypted SDK Demo
- **Mobile**: Tab 3 $\rightarrow$ *SvasthyaStorage SDK*.
- **Web**: `/storage-demo`.
- **How to test**: Enter a patient record key and JSON payload $\rightarrow$ Tap **"Encrypt & Save (AES-256-GCM)"** $\rightarrow$ View encrypted ciphertext and test offline decryption and background sync.

### DPDP Act 2023 Consent Manager
- **Mobile**: User Avatar menu $\rightarrow$ *DPDP Consent Manager* or Tab 3.
- **Web**: `/consent`.
- **How to test**: View active consent artifacts, toggle purpose-bound permissions (`Teleconsultation`, `Research Data`, `Emergency Vitals Sharing`), and listen to audio consent explanations designed for low-literacy users.

### Admin RBAC Matrix
- **Mobile**: User Avatar menu $\rightarrow$ *Admin Role Matrix* or Tab 3.
- **Web**: `/admin/roles`.
- **How to test**: View the complete user-to-role access control table and dynamically update permissions for Physicians, Officers, and Counselors.

### Multi-Agent Clinical AI Reasoning Hub
- **Mobile**: Bottom Tab 2 (`AI Chat`).
- **Web**: `/chat`.
- **How to test**: Chat with specialized clinical, triage, defense, and legal agents powered by Strands multi-agent architecture.

---

## 6. Website Route Directory & Navigation

Every module is available as a dedicated interactive web page:

| Application / Module | Web URL | Key Interactive Features |
|---|---|---|
| **Landing & Navigation Hub** | `/` | Direct app launchers, innovation cards, platform services, and backend health tester |
| **ArogyaSathi Dashboard** | `/arogya` | Heat stress telemetry, weather fetch, vitals monitor, SOS dispatch |
| **MediKiosk Clinical Hub** | `/medikiosk` | Voice clinical history intake, SOCRATES questions, OPD Physician Queue |
| **RakshakMitra Welfare** | `/rakshak` | Burnout Index calculator, voice mood analysis, unit stress heatmap |
| **NyayaSahay Legal Aid** | `/nyaya` | Distress trajectory, case milestones, voice stress analyzer, counselor desk |
| **Community Immunity Mesh** | `/cin` | BLE mesh topology visualizer, offline token sync simulation |
| **Acoustic & Palmar Screening**| `/screening` | Audio Mel-spectrogram cough classifier & camera RGB hemoglobin colorimetry |
| **Panic Disguise SOS** | `/covert-sos` | Stealth calculator interface with panic PIN `9999=` and shake trigger |
| **Family Risk Genogram** | `/family-graph` | Multi-generational pedigree risk tree (Diabetes, Cardiac, Sickle-Cell) |
| **Organ Digital Twin** | `/digital-twin` | Real-time multi-organ physiological simulation |
| **Health Karma Rewards** | `/karma` | Gamified wellness points and streak tracking |
| **Federated Learning AI** | `/federated` | Privacy-preserving on-device gradient aggregation (`FedAvg`) monitor |
| **ASHA Field Copilot** | `/asha` | High-risk maternal ante-natal triage workflow |
| **BSA 2023 Evidence Locker** | `/evidence` | Cryptographic SHA-256 Merkle chain of custody for legal forensics |
| **1-Tap Emergency SOS** | `/sos-demo` | Emergency GPS snapshot and alert dispatcher |
| **Encrypted Storage SDK** | `/storage-demo` | Single-invoke AES-256-GCM local DB with background queue |
| **DPDP Consent Manager** | `/consent` | Granular purpose-bound data consent management |
| **Admin RBAC Matrix** | `/admin/roles` | Granular permission control matrix |
| **AI Agent Hub** | `/chat` | Multi-agent clinical reasoning engine |
| **User Sign In** | `/login` | Full credentials login + 1-tap demo persona selectors |
| **User Registration** | `/register` | ABHA ID registration & Aadhaar KYC onboarding |

---

## 7. Machine Learning Models Deep Dive

The platform includes 6 Python machine learning blueprints in [`models/colab_notebooks/`](file:///home/mahi17/Github/sih26/models/colab_notebooks/):

```
models/
├── colab_notebooks/
│   ├── 01_cough_classifier.py        # MobileNetV2 Mel-spectrogram Audio Classifier
│   ├── 02_anemia_detector.py         # EfficientNetB0 CIELAB Colorimetry Detector
│   ├── 03_voice_stress_analyzer.py   # 226-dim Acoustic Feature Extractor + MLP
│   ├── 04_medical_ner.py             # BioBERT Biomedical Named Entity Recognizer
│   ├── 05_epidemic_predictor.py      # SEIR Dynamical Equations + Spatial Forecaster
│   └── 06_crisis_detector.py         # DistilBERT High-Recall Crisis Classifier
```

### 1. `01_cough_classifier.py` (Acoustic TB & Respiratory Screener)
- **Architecture**: MobileNetV2 transfer learning with Mel-spectrogram inputs (224x224x3).
- **Data Sources**: COUGHVID, Coswara, Kaggle COVID-19 Cough Audio.
- **Classes**: `DRY_COUGH`, `WET_COUGH`, `WHEEZING`, `TB_SUSPECT`, `NORMAL`.
- **Edge Deployment**: Quantized to INT8 TFLite for real-time offline mobile execution.

### 2. `02_anemia_detector.py` (Non-Invasive Palmar Hemoglobin Estimator)
- **Architecture**: EfficientNetB0 with HSV skin-mask nail/palm segmentation and CIELAB color space transformation.
- **Output**: Multi-task network producing continuous Hemoglobin (g/dL) regression and anemia stage classification (`NORMAL`, `MILD`, `MODERATE`, `SEVERE`).
- **Edge Deployment**: INT8 quantized TFLite model for camera-based screening.

### 3. `03_voice_stress_analyzer.py` (Acoustic Prosody & Stress Analyzer)
- **Architecture**: 226 acoustic feature extractor (40 MFCCs mean/std, 12 chroma, spectral centroid, bandwidth, rolloff, Zero Crossing Rate, RMS energy) connected to a multi-task MLP.
- **Output**: Continuous Stress Score (0–100) and emotion classification (`calm`, `happy`, `sad`, `angry`, `fearful`, `disgust`, `surprise`).

### 4. `04_medical_ner.py` (Clinical Prescription & Notes Digitizer)
- **Architecture**: BioBERT token classification fine-tuned on biomedical entities.
- **Entity Types**: `B-SYMPTOM`, `I-SYMPTOM`, `B-DIAGNOSIS`, `B-MEDICATION`, `B-DOSAGE`, `B-ANATOMY`.

### 5. `05_epidemic_predictor.py` (Syndromic Outbreak Early Warning)
- **Architecture**: Differential SEIR (Susceptible-Exposed-Infectious-Recovered) dynamical simulation coupled with spatial ridge regression on temperature, humidity, and population mobility.
- **Output**: Reproduction number ($R_0$) trajectory and district-level outbreak risk tiers.

### 6. `06_crisis_detector.py` (High-Recall Suicide & Distress Detector)
- **Architecture**: DistilBERT sequence classification with class-weighted Cross-Entropy loss ($W=5.0$ on `CRISIS` class) to ensure $>95\%$ recall.
- **Languages**: Handles English and Hinglish distress signals (e.g., *"Mujhe jeene ka mann nahi hai"* $\rightarrow$ immediate counselor escalation).
