# ===== SECTION: DATA SOURCES & SETUP =====
# DATA SOURCE: RAVDESS - https://zenodo.org/records/1188976 or Kaggle https://www.kaggle.com/datasets/uwrfkaggler/ravdess-emotional-speech-audio
# CREMA-D: https://github.com/CheyneyComputerScience/CREMA-D
# TESS: https://www.kaggle.com/datasets/ejlok1/toronto-emotional-speech-set-tess
# SAVEE: https://www.kaggle.com/datasets/ejlok1/surrey-audiovisual-expressed-emotion-savee
#
# Colab Setup Instructions:
# Run the following in a Colab cell before running this script:
# !pip install tensorflow librosa soundfile numpy matplotlib scikit-learn

import os
import glob
import numpy as np
import librosa
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Dense, Dropout, BatchNormalization, Lambda
from tensorflow.keras.callbacks import EarlyStopping
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix, mean_absolute_error
import matplotlib.pyplot as plt

# ===== SECTION: PREPROCESSING =====
def extract_features(file_path):
    try:
        y, sr = librosa.load(file_path, sr=22050)
        
        # 40 MFCCs (mean + std = 80)
        mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40)
        mfcc_mean = np.mean(mfcc.T, axis=0)
        mfcc_std = np.std(mfcc.T, axis=0)
        
        # 12 Chroma features (mean)
        chroma = np.mean(librosa.feature.chroma_stft(y=y, sr=sr).T, axis=0)
        
        # Spectral Centroid (mean) = 1
        cent = np.mean(librosa.feature.spectral_centroid(y=y, sr=sr))
        
        # Spectral Bandwidth (mean) = 1
        bandwidth = np.mean(librosa.feature.spectral_bandwidth(y=y, sr=sr))
        
        # Spectral Rolloff (mean) = 1
        rolloff = np.mean(librosa.feature.spectral_rolloff(y=y, sr=sr))
        
        # Zero Crossing Rate (mean) = 1
        zcr = np.mean(librosa.feature.zero_crossing_rate(y))
        
        # RMS Energy (mean + std = 2)
        rms = librosa.feature.rms(y=y)
        rms_mean = np.mean(rms.T, axis=0)
        rms_std = np.std(rms.T, axis=0)
        
        # Mel Spectrogram stats (mean = 128)
        mel = np.mean(librosa.feature.melspectrogram(y=y, sr=sr).T, axis=0)
        
        # Total = 80 + 12 + 1 + 1 + 1 + 1 + 2 + 128 = 226 features
        features = np.hstack([mfcc_mean, mfcc_std, chroma, cent, bandwidth, rolloff, zcr, rms_mean, rms_std, mel])
        return features
    except Exception as e:
        print(f"Error extracting features from {file_path}: {e}")
        return None

def load_dummy_data(num_samples=1000):
    """Generates dummy features since dataset isn't physically present here."""
    print("Generating dummy dataset for demonstration...")
    X = np.random.randn(num_samples, 226)
    
    # 8 emotions: neutral, calm, happy, sad, angry, fearful, disgust, surprise
    emotions = ['neutral', 'calm', 'happy', 'sad', 'angry', 'fearful', 'disgust', 'surprise']
    
    # Stress mapping
    stress_map = {'calm': 15, 'happy': 25, 'sad': 55, 'angry': 80, 'fearful': 75, 'disgust': 60, 'surprise': 45, 'neutral': 10}
    
    y_emo = np.random.choice(emotions, num_samples)
    y_stress = np.array([stress_map[e] for e in y_emo])
    
    return X, y_emo, y_stress

X, y_emo, y_stress = load_dummy_data()

# Encode emotions
label_encoder = LabelEncoder()
y_emo_encoded = label_encoder.fit_transform(y_emo)

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

X_train, X_test, y_emo_train, y_emo_test, y_stress_train, y_stress_test = train_test_split(
    X_scaled, y_emo_encoded, y_stress, test_size=0.2, random_state=42
)

# ===== SECTION: MODEL DEFINITION =====
def build_model(input_shape, num_classes):
    inputs = Input(shape=(input_shape,))
    
    # 3-layer MLP
    x = Dense(512, activation='relu')(inputs)
    x = BatchNormalization()(x)
    x = Dropout(0.3)(x)
    
    x = Dense(256, activation='relu')(x)
    x = BatchNormalization()(x)
    x = Dropout(0.3)(x)
    
    x = Dense(128, activation='relu')(x)
    x = BatchNormalization()(x)
    x = Dropout(0.3)(x)
    
    # Dual Head: Classification (8 emotions softmax)
    emotion_out = Dense(num_classes, activation='softmax', name='emotion_output')(x)
    
    # Dual Head: Regression (stress score 0-100 sigmoid*100)
    stress_out_sigmoid = Dense(1, activation='sigmoid')(x)
    stress_out = Lambda(lambda t: t * 100.0, name='stress_output')(stress_out_sigmoid)
    
    model = Model(inputs=inputs, outputs=[emotion_out, stress_out])
    
    # Compile
    optimizer = tf.keras.optimizers.Adam(learning_rate=0.001)
    
    model.compile(
        optimizer=optimizer,
        loss={'emotion_output': 'sparse_categorical_crossentropy', 'stress_output': 'mse'},
        loss_weights={'emotion_output': 1.0, 'stress_output': 0.01}, # Balance regression MSE with classification loss
        metrics={'emotion_output': 'accuracy', 'stress_output': 'mae'}
    )
    
    return model

model = build_model(input_shape=X_train.shape[1], num_classes=len(label_encoder.classes_))
model.summary()

# ===== SECTION: TRAINING =====
early_stopping = EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True)

history = model.fit(
    X_train,
    {'emotion_output': y_emo_train, 'stress_output': y_stress_train},
    validation_data=(X_test, {'emotion_output': y_emo_test, 'stress_output': y_stress_test}),
    epochs=100,
    batch_size=64,
    callbacks=[early_stopping],
    verbose=1
)

# ===== SECTION: EVALUATION =====
results = model.evaluate(X_test, {'emotion_output': y_emo_test, 'stress_output': y_stress_test})
print(f"\nEvaluation Results - Loss: {results[0]:.4f}")

preds = model.predict(X_test)
emo_preds = np.argmax(preds[0], axis=1)
stress_preds = preds[1].flatten()

print("\nEmotion Classification Report:")
print(classification_report(y_emo_test, emo_preds, target_names=label_encoder.classes_))

print(f"\nStress MAE: {mean_absolute_error(y_stress_test, stress_preds):.2f}")

print("\nConfusion Matrix:")
print(confusion_matrix(y_emo_test, emo_preds))

# ===== SECTION: EXPORT =====
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

tflite_path = "voice_stress_analyzer.tflite"
with open(tflite_path, "wb") as f:
    f.write(tflite_model)
print(f"\nModel exported to {tflite_path} (Size: {len(tflite_model) / 1024 / 1024:.2f} MB)")
