# 📥 Dataset Download Guide

> Download datasets and place them in the corresponding subdirectories below.
> **⚠️ Do NOT commit raw datasets to Git** — they are too large. Add to `.gitignore`.

## Cough Classifier Data (`data/cough/`)

### Option A: COUGHVID (Recommended — Easiest)
1. Go to: https://www.kaggle.com/datasets/andrewmvd/covid19-cough-audio-classification
2. Click "Download" → extract ZIP
3. Place audio files in `data/cough/raw/`

### Option B: Coswara (Indian demographics)
1. Go to: https://github.com/iiscleap/Coswara-Data
2. Clone the repo or download specific audio folders
3. Place in `data/cough/coswara/`

### Option C: Via Kaggle API (in Colab)
```bash
!kaggle datasets download -d andrewmvd/covid19-cough-audio-classification
!unzip covid19-cough-audio-classification.zip -d data/cough/raw/
```

---

## Anemia Detector Data (`data/anemia/`)

### Option A: Mendeley Fingernail Dataset
1. Go to: https://data.mendeley.com/datasets/2xx4j3kjg2/1
2. Download the dataset
3. Place images in `data/anemia/raw/`

### Option B: Kaggle
1. Go to: https://www.kaggle.com/datasets/biswaranjanrao/non-invasive-anemia-detection
2. Download and extract
3. Place in `data/anemia/raw/`

---

## Voice Stress Data (`data/voice/`)

### RAVDESS (Primary)
1. Go to: https://www.kaggle.com/datasets/uwrfkaggler/ravdess-emotional-speech-audio
2. Download and extract
3. Place in `data/voice/ravdess/`

### TESS (Supplementary)
1. Go to: https://www.kaggle.com/datasets/ejlok1/toronto-emotional-speech-set-tess
2. Download and place in `data/voice/tess/`

---

## Medical NER Data (`data/medical_ner/`)

### i2b2 (Requires Free Registration)
1. Go to: https://portal.dbmi.hms.harvard.edu/projects/n2c2-nlp/
2. Create account and sign Data Use Agreement
3. Download i2b2 2010 challenge data
4. Place in `data/medical_ner/i2b2/`

### Note: The training script includes a built-in demo dataset with 200+ Indian clinical sentences.

---

## Crisis Detection Data (`data/crisis/`)

### Reddit SuicideWatch
1. Go to: https://www.kaggle.com/datasets/nikhileswarkomati/suicide-watch
2. Download CSV
3. Place in `data/crisis/reddit/`

---

## Epidemic Data (`data/epidemic/`)

### Note: The training script generates synthetic data for demo purposes.
### For real data, access IDSP weekly reports from https://idsp.nic.in/
