# 🤖 SvasthyaSetu — Complete ML Model Training & Implementation Blueprint

> **Purpose**: Detailed plan for EVERY ML model needed across all 18 features. Includes datasets, architectures, Colab training guides, TFLite conversion, and deployment. **No code — just the roadmap.**

---

## 📂 Models Folder Structure

```
models/
├── README.md                              # This document
├── colab_notebooks/                       # Google Colab notebooks (.ipynb)
│   ├── 01_cough_classifier.ipynb          # Cough → disease type classification
│   ├── 02_anemia_detector.ipynb           # Nail bed image → hemoglobin estimation
│   ├── 03_voice_stress_analyzer.ipynb     # Audio → stress/emotion classification
│   ├── 04_medical_ner.ipynb               # Clinical text → symptom/drug extraction
│   ├── 05_epidemic_predictor.ipynb        # Geo-temporal clustering + risk prediction
│   └── 06_crisis_detector.ipynb           # Text → suicidal ideation detection
│
├── trained/                               # Final exported models (after Colab training)
│   ├── cough_classifier.tflite            # On-device cough model (~5MB)
│   ├── cough_classifier_labels.txt        # Class labels for cough model
│   ├── anemia_estimator.tflite            # On-device anemia model (~15MB)
│   ├── voice_stress.tflite                # On-device voice stress model (~3MB)
│   ├── medical_ner_model/                 # PyTorch/ONNX NER model (backend only)
│   │   ├── config.json
│   │   ├── model.safetensors
│   │   └── tokenizer/
│   ├── crisis_detector_model/             # Backend crisis detection model
│   │   ├── config.json
│   │   └── model.safetensors
│   └── epidemic_predictor.pkl             # Scikit-learn Random Forest (backend only)
│
├── data/                                  # Preprocessed datasets (gitignored, README only)
│   ├── README.md                          # Download instructions for each dataset
│   ├── cough/                             # COUGHVID + Coswara processed spectrograms
│   ├── anemia/                            # Fingernail images with Hb labels
│   ├── voice/                             # RAVDESS + Coswara audio features
│   ├── medical_ner/                       # i2b2 + synthetic Indian clinical notes
│   ├── crisis/                            # Reddit SuicideWatch + Hinglish text
│   └── epidemic/                          # IDSP weekly reports + GPS-tagged symptoms
│
└── configs/                               # Model hyperparameters & training configs
    ├── cough_config.yaml
    ├── anemia_config.yaml
    ├── voice_config.yaml
    ├── ner_config.yaml
    ├── crisis_config.yaml
    └── epidemic_config.yaml
```

---

---

# 🔬 MODEL 1: Cough Classifier

> **Used by**: Feature 1 (Cough-to-Diagnosis), Feature 14 (Federated Learning)

## Overview

| Property | Value |
|----------|-------|
| **Task** | Audio multi-class classification |
| **Input** | 10-second cough audio (WAV/WebM) |
| **Output** | Class: `DRY_COUGH`, `WET_COUGH`, `WHEEZING`, `TB_SUSPECT`, `NORMAL` |
| **Architecture** | MobileNetV2 on Mel-spectrogram images |
| **Deployment** | TFLite on Flutter + FastAPI backend fallback |
| **Model Size Target** | < 8 MB (quantized) |

## Datasets

| Dataset | Size | What It Contains | Download Link |
|---------|------|------------------|---------------|
| **COUGHVID** | 30,000+ recordings | Crowdsourced coughs, expert-labeled subset of ~2,800 | [Zenodo](https://zenodo.org/records/4498364) or [Kaggle](https://www.kaggle.com/datasets/andrewmvd/covid19-cough-audio-classification) |
| **Coswara** (IISc Bangalore) | 10,000+ samples | Coughs + breathing + speech from COVID/healthy subjects, Indian demographic data | [GitHub](https://github.com/iiscleap/Coswara-Data) / [Zenodo](https://zenodo.org/records/7195430) |
| **Solicited TB Cough** | 700,000+ sounds | Multi-country TB triage dataset, clinical diagnostics | [eScholarship](https://escholarship.org/uc/item/1hp1j0z4) |
| **CAGE-TB** | ~3,000 | Smartphone-recorded TB coughs | [Makerere University](https://air.ug/research/cage-tb/) |
| **Figshare TB** | 456 (230 TB+, 226 healthy) | Small, balanced, expert-curated | [Figshare](https://doi.org/10.1371/journal.pone.0302651.t002) |

## How to Train (Colab Pipeline)

### Step 1: Data Preprocessing
1. **Download** COUGHVID + Coswara datasets into `models/data/cough/raw/`
2. **Normalize audio**: Resample all files to 22,050 Hz mono using `librosa.load(file, sr=22050)`
3. **Trim/pad**: All clips to exactly 5 seconds (110,250 samples) — pad with zeros if shorter, trim if longer
4. **Generate Mel-spectrograms**: Using `librosa.feature.melspectrogram()` with:
   - `n_mels=128` (128 mel bands)
   - `hop_length=512`
   - `n_fft=2048`
   - Convert to dB: `librosa.power_to_db(S, ref=np.max)`
5. **Save as images**: Each spectrogram → 224×224 PNG (matching MobileNet input)
6. **Label mapping**: Map expert annotations to 5 classes
7. **Split**: 70% train, 15% validation, 15% test (stratified)

### Step 2: Model Architecture
1. **Base model**: `tf.keras.applications.MobileNetV2(input_shape=(224,224,3), include_top=False, weights='imagenet')`
2. **Freeze** base layers initially
3. **Custom head**:
   - `GlobalAveragePooling2D()`
   - `Dropout(0.3)`
   - `Dense(128, activation='relu')`
   - `Dropout(0.2)`
   - `Dense(5, activation='softmax')` ← 5 cough classes
4. **Loss**: `categorical_crossentropy`
5. **Optimizer**: Adam, lr=0.001 initially

### Step 3: Training Strategy
1. **Phase 1 — Transfer learning** (10 epochs): Freeze base, train head only. lr=0.001
2. **Phase 2 — Fine-tuning** (20 epochs): Unfreeze top 30 layers of MobileNetV2. lr=0.0001
3. **Data augmentation**: Time stretch (±10%), pitch shift (±2 semitones), add background noise at random SNR (15-30 dB)
4. **Callbacks**: `EarlyStopping(patience=5)`, `ReduceLROnPlateau(factor=0.5, patience=3)`, `ModelCheckpoint(save_best_only=True)`

### Step 4: TFLite Conversion
1. Convert: `tf.lite.TFLiteConverter.from_keras_model(model)`
2. **Quantization**: `converter.optimizations = [tf.lite.Optimize.DEFAULT]` (dynamic range)
3. **Representative dataset**: Provide 100 sample spectrograms for full integer quantization if needed
4. Save as `models/trained/cough_classifier.tflite`
5. Save labels as `models/trained/cough_classifier_labels.txt`

### Step 5: Deployment
- **Flutter**: Load `.tflite` with `tflite_flutter` package → preprocess audio to spectrogram on-device using `fftea` → run inference
- **Backend fallback**: If on-device fails or for web, send audio to `POST /api/v1/screening/cough-analysis` → backend runs same model with `librosa` preprocessing

### Expected Metrics
| Metric | Target | Notes |
|--------|--------|-------|
| Accuracy | > 85% | On 5-class test set |
| F1 (weighted) | > 0.82 | Important since classes are imbalanced |
| Inference time (mobile) | < 200ms | On mid-range Android |
| Model size | < 8 MB | After quantization |

---

---

# 🔬 MODEL 2: Anemia Detector (Nail Bed)

> **Used by**: Feature 2 (Anemia Screening), Feature 12 (Digital Twin input)

## Overview

| Property | Value |
|----------|-------|
| **Task** | Image regression (Hb estimation) + binary classification (anemic/not) |
| **Input** | Fingernail photograph (JPEG, centered on nail bed) |
| **Output** | Estimated hemoglobin (g/dL) + severity class |
| **Architecture** | EfficientNet-B0 with regression head |
| **Deployment** | TFLite on Flutter + FastAPI backend (OpenCV) |
| **Model Size Target** | < 20 MB (quantized) |

## Datasets

| Dataset | Size | What It Contains | Download Link |
|---------|------|------------------|---------------|
| **Fingernail Anemia (Ghana)** | ~6,000 images | Fingernail images + lab-confirmed Hb values | [Mendeley Data](https://data.mendeley.com/datasets/2xx4j3kjg2/1) |
| **CP-AnemiC** | 1,500+ images | Conjunctival pallor images from children + Hb | [Mendeley Data](https://data.mendeley.com/datasets/2xx4j3kjg2/1) |
| **Skin & Fingernails Hb Dataset** | 250 patients | RGB images + Hb levels from lab tests | [Scientific Data / Figshare](https://www.nature.com/sdata/) |
| **Kaggle Anemia Detection** | ~1,200 | Community-contributed nail images | [Kaggle](https://www.kaggle.com/datasets/biswaranjanrao/non-invasive-anemia-detection) |
| **HuggingFace Nail Anemia** | Pre-trained | Pre-trained nail anemia detector | [HuggingFace](https://huggingface.co/JetX-GT/nail-anemia-detector) |

## How to Train (Colab Pipeline)

### Step 1: Data Preprocessing
1. **Download** all nail bed datasets into `models/data/anemia/raw/`
2. **Nail bed segmentation**: Use OpenCV to isolate the nail region:
   - Convert to HSV color space
   - Apply skin-tone mask to find nail boundaries
   - Crop to the nail bed ROI (region of interest)
   - Resize to 224×224 pixels
3. **Color space conversion**: Convert cropped ROI to CIELAB color space
   - L (lightness), a* (red-green), b* (yellow-blue)
   - These correlate with hemoglobin concentration
4. **Label**: Each image gets its lab-confirmed Hb value as the regression target
5. **Augmentation**: Random rotation (±15°), brightness jitter (±20%), horizontal flip
6. **Split**: 70/15/15 stratified by Hb severity bins

### Step 2: Model Architecture (Dual-Head)
1. **Base**: `tf.keras.applications.EfficientNetB0(include_top=False, weights='imagenet')`
2. **Shared features**: `GlobalAveragePooling2D()` → `Dense(256, activation='relu')` → `Dropout(0.4)`
3. **Head 1 — Regression**: `Dense(1, activation='linear')` → predicts Hb in g/dL
4. **Head 2 — Classification**: `Dense(4, activation='softmax')` → NORMAL, MILD, MODERATE, SEVERE
5. **Loss**: Combined loss = `0.7 * MSE(hb_regression)` + `0.3 * categorical_crossentropy(severity)`
6. **Optimizer**: Adam, lr=0.0005

### Step 3: Training Strategy
1. **Phase 1**: Freeze EfficientNet base, train heads only (15 epochs, lr=0.001)
2. **Phase 2**: Unfreeze top 20 blocks, fine-tune (30 epochs, lr=0.00005)
3. **Key trick**: Use **Lab color channels** as additional input (concatenate with CNN features before the Dense layers) — this is what published research shows works best
4. **Callbacks**: Same as Model 1

### Step 4: TFLite Conversion
- Same process as Model 1
- Output: `models/trained/anemia_estimator.tflite` (< 20MB)

### Step 5: Deployment
- **Flutter**: Camera capture → OpenCV-like cropping (using `image` package) → TFLite inference
- **Backend**: Receives image → OpenCV preprocessing → model inference → returns `{hemoglobin_estimate_gdl, severity}`

### Expected Metrics
| Metric | Target | Notes |
|--------|--------|-------|
| MAE (Hb estimation) | < 1.5 g/dL | Mean Absolute Error on Hb prediction |
| Classification Accuracy | > 80% | 4-class severity |
| Sensitivity (Severe Anemia) | > 90% | Critical: don't miss severe cases |

---

---

# 🔬 MODEL 3: Voice Stress Analyzer

> **Used by**: Feature 5 (Voice Journal → Clinical Notes), Feature 10 (AI Counselor), Feature 4 (Dead Man's Switch), RakshakMitra sub-app

## Overview

| Property | Value |
|----------|-------|
| **Task** | Audio multi-class classification (emotion/stress) |
| **Input** | 5-30 second voice clip |
| **Output** | Emotion class + stress score (0-100) |
| **Architecture** | 2-layer MLP on hand-crafted audio features (MFCC + spectral) |
| **Deployment** | TFLite on Flutter + FastAPI backend |
| **Model Size Target** | < 3 MB |

## Datasets

| Dataset | Size | Emotions | Download Link |
|---------|------|----------|---------------|
| **RAVDESS** | 7,356 files | 8 emotions (calm, happy, sad, angry, fearful, surprise, disgust, neutral) | [Zenodo](https://zenodo.org/records/1188976) / [Kaggle](https://www.kaggle.com/datasets/uwrfkaggler/ravdess-emotional-speech-audio) |
| **CREMA-D** | 7,442 files | 6 emotions | [GitHub](https://github.com/CheyneyComputerScience/CREMA-D) |
| **TESS** | 2,800 files | 7 emotions | [Kaggle](https://www.kaggle.com/datasets/ejlok1/toronto-emotional-speech-set-tess) |
| **SAVEE** | 480 files | 7 emotions (British English, male only) | [Kaggle](https://www.kaggle.com/datasets/ejlok1/surrey-audiovisual-expressed-emotion-savee) |
| **Coswara** (voice subset) | 5,000+ | Health status labels (can proxy for stress) | [GitHub](https://github.com/iiscleap/Coswara-Data) |

## How to Train (Colab Pipeline)

### Step 1: Feature Extraction
For each audio file, extract these features using `librosa`:

| Feature Group | Features | Dimension | Why |
|---------------|----------|-----------|-----|
| **MFCC** | `librosa.feature.mfcc(n_mfcc=40)` → mean + std | 80 | Captures timbre/vocal quality |
| **Chroma** | `librosa.feature.chroma_stft()` → mean | 12 | Harmonic content |
| **Spectral Centroid** | `librosa.feature.spectral_centroid()` → mean | 1 | Brightness of voice |
| **Spectral Bandwidth** | `librosa.feature.spectral_bandwidth()` → mean | 1 | Width of frequency distribution |
| **Spectral Rolloff** | `librosa.feature.spectral_rolloff()` → mean | 1 | High-frequency energy |
| **Zero Crossing Rate** | `librosa.feature.zero_crossing_rate()` → mean | 1 | Voice stability |
| **RMS Energy** | `librosa.feature.rms()` → mean + std | 2 | Loudness/intensity |
| **Mel Spectrogram stats** | `librosa.feature.melspectrogram()` → mean | 128 | Overall spectral shape |
| | | **Total: ~226** | |

### Step 2: Label Mapping (Emotion → Stress Score)
Map the discrete emotions to a continuous stress scale:

| Emotion | Stress Score | Rationale |
|---------|:------------:|-----------|
| Calm/Neutral | 10-20 | Baseline |
| Happy | 20-30 | Low arousal positive |
| Sad | 50-60 | Moderate negative |
| Fearful | 70-80 | High arousal negative |
| Angry | 75-85 | High arousal negative |
| Disgust | 55-65 | Moderate negative |
| Surprise | 40-50 | Variable |

### Step 3: Model Architecture
Use a simple but effective MLP (Multi-Layer Perceptron):

1. **Input**: 226-dimensional feature vector
2. **Layer 1**: `Dense(512, activation='relu')` → `BatchNormalization()` → `Dropout(0.3)`
3. **Layer 2**: `Dense(256, activation='relu')` → `BatchNormalization()` → `Dropout(0.3)`
4. **Layer 3**: `Dense(128, activation='relu')` → `Dropout(0.2)`
5. **Head 1 — Classification**: `Dense(8, activation='softmax')` → emotion class
6. **Head 2 — Regression**: `Dense(1, activation='sigmoid')` × 100 → stress score (0-100)
7. **Loss**: `0.5 * categorical_crossentropy + 0.5 * MSE`

### Step 4: Training
- **Optimizer**: Adam, lr=0.001
- **Epochs**: 100 with `EarlyStopping(patience=10)`
- **Batch size**: 64
- **Class balancing**: Use `class_weight` parameter since RAVDESS is balanced, but combined datasets may not be

### Step 5: TFLite Conversion
- Same process, but this model is tiny (~3MB) — can skip quantization

### Expected Metrics
| Metric | Target |
|--------|--------|
| Emotion Accuracy | > 75% |
| Stress Score MAE | < 12 points |
| Inference time | < 50ms |

---

---

# 🔬 MODEL 4: Medical NER (Named Entity Recognition)

> **Used by**: Feature 5 (Voice Journal → Clinical Notes), Feature 6 (Dual Prescription), MediKiosk OCR pipeline

## Overview

| Property | Value |
|----------|-------|
| **Task** | Token classification (NER) |
| **Input** | Clinical text (English, transliterated Hindi) |
| **Output** | Tagged entities: `SYMPTOM`, `MEDICATION`, `DOSAGE`, `CONDITION`, `BODY_PART` |
| **Architecture** | Fine-tuned `bert-base-multilingual-uncased` or `ai4bharat/IndicBERT` |
| **Deployment** | Backend only (FastAPI — too large for mobile) |
| **Model Size** | ~400 MB (full precision) |

## Datasets

| Dataset | Size | Description | Download Link |
|---------|------|-------------|---------------|
| **i2b2 2010 Medication Challenge** | 871 clinical notes | Gold-standard medication NER (drug, dosage, frequency, route, duration) | [DBMI Portal](https://portal.dbmi.hms.harvard.edu/projects/n2c2-nlp/) (requires free registration) |
| **i2b2 2012 Temporal Relations** | 310 discharge summaries | Events, temporal expressions, clinical events | Same portal as above |
| **Synthetic Indian Clinical Notes** | 10,000 notes | 5 specialties, Indian clinical documentation style | [Mendeley Data](https://data.mendeley.com/) (search "synthetic Indian clinical notes") |
| **BC5CDR** | 1,500 PubMed articles | Chemical-Disease NER | [BioCreative](https://biocreative.bioinformatics.udel.edu/tasks/biocreative-v/track-3-cdr/) |
| **NCBI Disease Corpus** | 793 PubMed abstracts | Disease name NER | [NCBI](https://www.ncbi.nlm.nih.gov/CBBresearch/Dogan/DISEASE/) |

## How to Train (Colab Pipeline)

### Step 1: Data Preparation
1. **Download** i2b2 datasets (requires signing a Data Use Agreement — free for research/academic)
2. **Convert** to BIO/IOB2 tagging format:
   - `B-SYMPTOM`, `I-SYMPTOM`, `B-MEDICATION`, `I-MEDICATION`, etc.
   - Example: `"Patient has [B-SYMPTOM]fever[I-SYMPTOM] and [B-SYMPTOM]headache since 3 days. Taking [B-MEDICATION]Paracetamol [B-DOSAGE]500mg [B-FREQUENCY]twice daily"`
3. **Augment with Indian context**: Add transliterated medical terms:
   - "bukhar" → SYMPTOM (fever in Hindi)
   - "sir mein dard" → SYMPTOM (headache in Hindi)
   - "Crocin" → MEDICATION (Indian brand name)
4. **Tokenize** with BERT tokenizer — handle subword alignment for NER tags

### Step 2: Model Architecture
1. **Base model**: `transformers.AutoModelForTokenClassification.from_pretrained('bert-base-multilingual-uncased')`
2. **Custom labels**: 11 classes (B/I for 5 entity types + O)
3. **Training**: Use HuggingFace `Trainer` with:
   - lr=2e-5
   - epochs=5
   - batch_size=16
   - warmup_steps=500
   - weight_decay=0.01

### Step 3: Evaluation
- Use `seqeval` library for NER-specific metrics (entity-level precision/recall/F1)

### Step 4: Export
- Save model to `models/trained/medical_ner_model/`
- Load in FastAPI using `transformers` pipeline

### Alternative (Simpler for Demo)
If full BERT NER is too heavy, use **spaCy** with a custom rule-based + pattern matching pipeline:
1. Build a medical dictionary of 500+ common Indian symptoms and medications
2. Use `spacy.Matcher` with regex patterns for dosages ("500mg", "BD", "OD", "TDS")
3. This requires NO training — just dictionary curation
4. Falls back to LLM (Bedrock) for complex cases

### Expected Metrics
| Metric | Target |
|--------|--------|
| Entity-level F1 | > 0.80 |
| SYMPTOM recall | > 0.85 |
| MEDICATION recall | > 0.90 |

---

---

# 🔬 MODEL 5: Epidemic Cluster Predictor

> **Used by**: Feature 3 (Fever Map), Feature 11 (CIN), Feature 15 (ASHA Copilot)

## Overview

| Property | Value |
|----------|-------|
| **Task** | Geospatial clustering + outbreak risk scoring |
| **Input** | Geo-tagged symptom reports (lat, lon, symptoms, timestamp) |
| **Output** | Cluster map + risk level per cluster + 7-day outbreak probability |
| **Architecture** | DBSCAN for clustering + Random Forest for risk scoring |
| **Deployment** | Backend only (FastAPI) |
| **Model Size** | < 5 MB (scikit-learn pickle) |

## Datasets

| Dataset | Description | Download Link |
|---------|-------------|---------------|
| **IDSP Weekly Outbreak Reports** | Official Indian disease surveillance data (district-level) | [IDSP/NCDC](https://idsp.nic.in/) (weekly reports section) |
| **WHO Disease Outbreak News** | Global outbreak reports with geo-location | [WHO DON](https://www.who.int/emergencies/disease-outbreak-news) |
| **GHDx India** | Institute for Health Metrics & Evaluation — India health data | [GHDx](http://ghdx.healthdata.org/geography/india) |
| **Dataful India** | Compiled IDSP outbreak data in machine-readable format | [Dataful](https://dataful.in/) |
| **IHIP (Integrated Health Information Platform)** | India's newer digital surveillance platform | [IHIP](https://ihip.nhp.gov.in/) |
| **Kaggle Dengue/Malaria Datasets** | Historical dengue/malaria case data with geo info | Search [Kaggle](https://www.kaggle.com/search?q=india+dengue+cases+district) |

## How to Train (Colab Pipeline)

### Step 1: Clustering (No Training Needed)
DBSCAN is unsupervised — just configure parameters:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `eps` | 0.018 radians (~2 km) | Disease clusters within 2km radius |
| `min_samples` | 10 | Minimum 10 reports to form a cluster |
| `metric` | 'haversine' | Geographic distance on Earth's surface |

**Process**:
1. Collect symptom reports with GPS coordinates
2. Convert to radians: `np.radians(coordinates)`
3. Run `DBSCAN(eps=0.018, min_samples=10, metric='haversine').fit(coords)`
4. Each cluster gets a center point, size, and symptom composition

### Step 2: Risk Scoring Model (Random Forest)
Train a Random Forest to predict outbreak severity (7-day risk):

**Features per cluster**:
| Feature | How to Compute |
|---------|----------------|
| `cluster_size` | Number of reports in cluster |
| `growth_rate` | Reports_today / Reports_yesterday |
| `symptom_diversity` | Number of unique symptom types |
| `fever_ratio` | % of reports with fever |
| `respiratory_ratio` | % with cough/breathing difficulty |
| `population_density` | Census data for the area |
| `past_outbreak_history` | Was there an outbreak here in the last 12 months? |
| `weather_temperature` | From weather API (already have this service) |
| `weather_humidity` | Mosquito-borne diseases correlate with humidity |

**Labels** (from historical IDSP data):
- `LOW_RISK` (cluster stayed small, resolved)
- `MODERATE_RISK` (cluster grew but contained)
- `HIGH_RISK` (cluster led to official outbreak declaration)

**Training**: `RandomForestClassifier(n_estimators=100, max_depth=10)`

### Step 3: Export
- `joblib.dump(model, 'models/trained/epidemic_predictor.pkl')`
- Load in FastAPI with `joblib.load()`

### Expected Metrics
| Metric | Target |
|--------|--------|
| Cluster detection (DBSCAN) | Visual validation against known outbreaks |
| Risk classification accuracy | > 75% (limited by data availability) |
| False alarm rate | < 20% |

---

---

# 🔬 MODEL 6: Crisis Detection (Mental Health)

> **Used by**: Feature 10 (AI Counselor), Feature 4 (Dead Man's Switch), NyayaSahay

## Overview

| Property | Value |
|----------|-------|
| **Task** | Text binary/multi-class classification |
| **Input** | User chat message or journal entry |
| **Output** | `SAFE`, `MILD_DISTRESS`, `MODERATE_DISTRESS`, `CRISIS` (+ confidence) |
| **Architecture** | Fine-tuned `distilbert-base-uncased` |
| **Deployment** | Backend only (FastAPI) |
| **Model Size** | ~260 MB |

## Datasets

| Dataset | Size | Description | Download Link |
|---------|------|-------------|---------------|
| **Reddit SuicideWatch + Depression** | ~230,000 posts | Labeled subreddit posts (crisis vs non-crisis) | [Kaggle](https://www.kaggle.com/datasets/nikhileswarkomati/suicide-watch) |
| **CLPsych Shared Task** | ~65,000 posts | Clinical assessment of suicidal ideation in social media | [CLPsych](https://clpsych.org/) (requires registration) |
| **SDCNL (Suicide Detection)** | 36,000 posts | Binary classification (suicide/non-suicide) | [Kaggle](https://www.kaggle.com/datasets/aunanya875/suicidal-tweet-detection-dataset) |
| **Hindi-English Code-Mixed** | ~5,000 | Hinglish suicidal ideation posts | Search on HuggingFace / ACL Anthology |
| **BharatGen MHQA** | ~2,000 | Indian mental health QA dataset | [AIKosh](https://aikosh.ai/) |

## How to Train (Colab Pipeline)

### Step 1: Data Preparation
1. **Download** Reddit SuicideWatch dataset from Kaggle
2. **Label mapping**:
   - SuicideWatch posts with explicit ideation → `CRISIS`
   - SuicideWatch posts with distress but no ideation → `MODERATE_DISTRESS`
   - Depression subreddit posts → `MILD_DISTRESS`
   - CasualConversation subreddit posts → `SAFE`
3. **Text cleaning**: Remove URLs, usernames, normalize whitespace
4. **Add Indian context**: Augment with Hinglish examples:
   - "Mujhe jeene ka mann nahi hai" → `CRISIS`
   - "Bahut akela feel hota hai" → `MODERATE_DISTRESS`
   - "Thoda sad hu aaj" → `MILD_DISTRESS`
5. **Split**: 80/10/10 stratified

### Step 2: Model Architecture
1. **Base**: `transformers.AutoModelForSequenceClassification.from_pretrained('distilbert-base-uncased', num_labels=4)`
2. **Training with HuggingFace Trainer**:
   - lr=2e-5
   - epochs=3
   - batch_size=32
   - max_seq_length=256
3. **Class weights**: Heavily weight `CRISIS` class to maximize recall (better to false-alarm than miss)

### Step 3: Safety Threshold
- If `CRISIS` probability > 0.3 → trigger escalation (low threshold on purpose)
- Always pair with keyword detection: explicit words like "suicide", "kill myself", "marna chahta hu" → immediate escalation regardless of model score

### Expected Metrics
| Metric | Target |
|--------|--------|
| CRISIS Recall | > 95% | (CRITICAL: never miss a crisis) |
| Overall Accuracy | > 80% |
| CRISIS Precision | > 60% | (some false positives are acceptable) |

---

---

# 🔬 MODELS 7 & 8: Digital Twin + Federated Learning

> These are **algorithmic engines**, not traditional ML models. They don't need separate training datasets.

## Model 7: Digital Twin Trajectory Engine

| Property | Value |
|----------|-------|
| **Task** | Time-series health trajectory simulation |
| **Method** | Monte Carlo simulation with Bayesian priors |
| **Training Data Needed** | None — uses published medical literature constants |
| **Deployment** | Backend only (Python) |

### How It Works (No Colab Needed)
1. **No dataset to train on** — uses population-level medical constants from published research:
   - Hemoglobin drift rate on/off iron tablets: ~0.5 g/dL per month (WHO guidelines)
   - BMI change rate with diet intervention: ~0.2 kg/m² per month
   - Diabetes risk from family history: +40% if 1 parent, +70% if both (ADA)
2. **Monte Carlo simulation**: 100 random trajectories per metric
3. **Output**: Median + 10th/90th percentile confidence bands
4. **Calibration**: As user adds more data points, Bayesian updating narrows the confidence bands

### Key Medical Constants (From Literature)
| Parameter | Source | Value |
|-----------|--------|-------|
| Hb recovery with iron supplementation | WHO | +0.5–1.0 g/dL per month |
| Hb decline without treatment | Published meta-analysis | -0.2 g/dL per month |
| Diabetes risk with 1 diabetic parent | American Diabetes Association | 40% lifetime risk |
| Stress score reduction with yoga | NIMHANS Bangalore study | -15% over 8 weeks |

---

## Model 8: Federated Cough Model (FedAvg)

| Property | Value |
|----------|-------|
| **Task** | On-device training + server-side aggregation |
| **Method** | Federated Averaging (McMahan et al., 2017) |
| **Training Data** | Each phone's local cough recordings (NEVER leaves device) |
| **Deployment** | Flutter (local training) + FastAPI (aggregation server) |

### How It Works
1. **Start**: All phones get the same pre-trained `cough_classifier.tflite` (from Model 1)
2. **Local fine-tuning**: When a user does a cough screening and provides feedback ("this was wrong"), the model fine-tunes locally on that example
3. **Upload**: Only encrypted weight deltas (not audio!) are sent to the server
4. **Aggregate**: Server runs FedAvg → weighted average of all deltas
5. **Distribute**: Updated global model pushed to all phones

### For Demo Purposes
- Simulate with 5 "virtual clients" in the Colab notebook
- Show that the model improves after aggregation without any raw data exchange
- Display a "Privacy Dashboard" that shows "0 bytes of audio uploaded"

---

---

# 📊 Master Colab Notebook Structure

Each Colab notebook follows this standardized structure:

```
## Notebook Template
├── Section 1: Setup & Imports
│   ├── GPU check: !nvidia-smi
│   ├── Install deps: !pip install librosa tensorflow scikit-learn transformers
│   └── Mount Google Drive (to save models)
│
├── Section 2: Data Download & Preprocessing
│   ├── Download dataset (kaggle API or wget)
│   ├── Explore data (visualize samples, class distribution)
│   └── Preprocess (spectrogram, image resize, tokenize, etc.)
│
├── Section 3: Model Definition
│   ├── Define architecture
│   ├── Print model.summary()
│   └── Define callbacks
│
├── Section 4: Training
│   ├── Phase 1: Transfer learning (frozen base)
│   ├── Phase 2: Fine-tuning (unfrozen top layers)
│   └── Plot training/validation loss and accuracy curves
│
├── Section 5: Evaluation
│   ├── Confusion matrix
│   ├── Classification report (precision, recall, F1)
│   ├── Per-class analysis
│   └── Edge case testing
│
├── Section 6: TFLite Conversion
│   ├── Convert to .tflite
│   ├── Quantize (optional)
│   ├── Verify TFLite output matches Keras output
│   └── Report model size
│
└── Section 7: Export
    ├── Download .tflite file
    ├── Download labels.txt
    └── Instructions for placing in `models/trained/`
```

---

# 🛠️ Master Dependency Table

## Colab Environment (pip install)

```
# All notebooks
tensorflow>=2.16.0
numpy>=1.26.0
matplotlib>=3.8.0
scikit-learn>=1.4.0
pandas>=2.2.0
seaborn>=0.13.0

# Model 1 (Cough)
librosa>=0.10.2
soundfile>=0.12.1

# Model 2 (Anemia)
opencv-python-headless>=4.9.0
Pillow>=10.3.0
albumentations>=1.4.0    # Advanced image augmentation

# Model 3 (Voice)
librosa>=0.10.2          # Already listed above

# Model 4 (Medical NER)
transformers>=4.40.0
datasets>=2.19.0
seqeval>=1.2.2
tokenizers>=0.19.0
accelerate>=0.30.0

# Model 5 (Epidemic)
geopandas>=0.14.0
folium>=0.16.0
geopy>=2.4.1

# Model 6 (Crisis)
transformers>=4.40.0     # Already listed above
datasets>=2.19.0         # Already listed above
```

## Backend Additions (requirements.txt)

```
# For loading trained models
tensorflow-cpu>=2.16.0   # CPU-only for server inference (smaller install)
transformers>=4.40.0     # For NER and crisis detection
torch>=2.3.0             # Backend for transformers models
joblib>=1.4.0            # For loading scikit-learn models
```

## Flutter Additions (pubspec.yaml)

```yaml
dependencies:
  tflite_flutter: ^0.11.0      # Load and run .tflite models
  fftea: ^2.0.1                # On-device FFT for audio preprocessing
```

---

# 🗓️ Training Order & Time Estimates

| Priority | Model | Colab Training Time | Complexity | Dependencies |
|:--------:|-------|:-------------------:|:----------:|:------------:|
| **1** | 🫁 Cough Classifier | ~2 hours (T4 GPU) | Medium | None |
| **2** | 🩸 Anemia Detector | ~3 hours (T4 GPU) | Medium | None |
| **3** | 🗣️ Voice Stress | ~30 minutes (CPU OK) | Low | None |
| **4** | 🤖 Crisis Detector | ~1 hour (T4 GPU) | Medium | None |
| **5** | 📋 Medical NER | ~2 hours (T4 GPU) | High | i2b2 data access |
| **6** | 🌡️ Epidemic Predictor | ~15 minutes (CPU OK) | Low | IDSP data access |
| **7** | 🧠 Digital Twin | No training | Rule-based | Published constants |
| **8** | 🔒 Federated Learning | No training | Algorithmic | Model 1 as base |

> [!TIP]
> **Start with Model 1 (Cough) and Model 3 (Voice Stress)** — they have the easiest data access (Kaggle download), shortest training time, and highest demo impact. Model 7 and 8 need zero Colab time — they're pure backend logic.

> [!IMPORTANT]
> **After training in Colab, download the `.tflite` files and place them in `models/trained/`.** The Flutter app and FastAPI backend will load them from there. The Colab notebooks are for training ONLY — they don't need to be in the deployed app.
