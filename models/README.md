# 🤖 SvasthyaSetu — ML Models

> This folder contains all ML model training scripts, trained model files, and data for the SvasthyaSetu platform.

## 📂 Directory Structure

```
models/
├── README.md                              ← You are here
├── colab_notebooks/                       ← Google Colab training scripts
│   ├── 01_cough_classifier.py             ← Cough → disease type (MobileNetV2)
│   ├── 02_anemia_detector.py              ← Nail bed → hemoglobin (EfficientNet-B0)
│   ├── 03_voice_stress_analyzer.py        ← Voice → stress/emotion (MLP)
│   ├── 04_medical_ner.py                  ← Clinical text → entities (BERT NER)
│   ├── 05_epidemic_predictor.py           ← Geo-clusters → outbreak risk (DBSCAN + RF)
│   └── 06_crisis_detector.py              ← Text → crisis detection (DistilBERT)
│
├── trained/                               ← Trained model files (after Colab training)
│   ├── cough_classifier.tflite            ← On-device cough model
│   ├── cough_classifier_labels.txt        ← Class labels
│   ├── anemia_estimator.tflite            ← On-device anemia model
│   ├── voice_stress.tflite                ← On-device stress model
│   ├── medical_ner_model/                 ← Backend NER model (PyTorch)
│   ├── crisis_detector_model/             ← Backend crisis model (PyTorch)
│   └── epidemic_predictor.pkl             ← Backend outbreak predictor (sklearn)
│
├── data/                                  ← Datasets (see download instructions below)
│   └── README.md                          ← Download links for each dataset
│
└── configs/                               ← Model hyperparameters (YAML)
```

## 🚀 Quick Start

### Step 1: Open notebook in Google Colab
1. Upload any `.py` file from `colab_notebooks/` to Google Colab
2. Or copy-paste into a Colab notebook cell

### Step 2: Download datasets
Follow the links in the data source comments at the top of each script.

### Step 3: Train
Run the script — it handles everything: preprocessing, training, evaluation, export.

### Step 4: Download trained model
After training completes, download the `.tflite` or model directory and place it in `trained/`.

### Step 5: Deploy
- **Flutter**: Copy `.tflite` files to `app/assets/models/`
- **Backend**: Models in `trained/` are loaded by FastAPI services automatically

## 📊 Model Summary

| # | Model | Architecture | Input | Output | Size | Device |
|:-:|-------|-------------|-------|--------|:----:|:------:|
| 1 | Cough Classifier | MobileNetV2 | 10s audio → spectrogram | 5 cough types | ~8MB | Mobile + Server |
| 2 | Anemia Detector | EfficientNet-B0 | Nail photo | Hb g/dL + severity | ~20MB | Mobile + Server |
| 3 | Voice Stress | 3-layer MLP | Voice features (226-dim) | Emotion + stress 0-100 | ~3MB | Mobile + Server |
| 4 | Medical NER | BERT multilingual | Clinical text | Symptoms/Drugs/Dosages | ~400MB | Server only |
| 5 | Epidemic Predictor | DBSCAN + Random Forest | GPS + symptoms | Cluster risk level | ~5MB | Server only |
| 6 | Crisis Detector | DistilBERT | Chat message | SAFE/DISTRESS/CRISIS | ~260MB | Server only |

## 📥 Data Sources

| Model | Dataset | Link |
|-------|---------|------|
| Cough | COUGHVID (30K+ recordings) | https://zenodo.org/records/4498364 |
| Cough | Coswara (IISc, 10K+ samples) | https://github.com/iiscleap/Coswara-Data |
| Cough | Solicited TB Cough (700K+) | https://escholarship.org/uc/item/1hp1j0z4 |
| Anemia | Fingernail Ghana (6K images) | https://data.mendeley.com/datasets/2xx4j3kjg2/1 |
| Anemia | Kaggle Anemia Detection | https://www.kaggle.com/datasets/biswaranjanrao/non-invasive-anemia-detection |
| Voice | RAVDESS (7.3K files) | https://zenodo.org/records/1188976 |
| Voice | CREMA-D (7.4K files) | https://github.com/CheyneyComputerScience/CREMA-D |
| Voice | TESS (2.8K files) | https://www.kaggle.com/datasets/ejlok1/toronto-emotional-speech-set-tess |
| NER | i2b2 2010 Clinical Notes | https://portal.dbmi.hms.harvard.edu/projects/n2c2-nlp/ |
| NER | NCBI Disease Corpus | https://www.ncbi.nlm.nih.gov/CBBresearch/Dogan/DISEASE/ |
| Epidemic | IDSP Weekly Reports | https://idsp.nic.in/ |
| Epidemic | WHO Outbreak News | https://www.who.int/emergencies/disease-outbreak-news |
| Crisis | Reddit SuicideWatch | https://www.kaggle.com/datasets/nikhileswarkomati/suicide-watch |
| Crisis | SDCNL Tweets | https://www.kaggle.com/datasets/aunanya875/suicidal-tweet-detection-dataset |
