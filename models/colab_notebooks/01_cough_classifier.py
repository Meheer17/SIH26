# ===== DATA SOURCES =====
# COUGHVID dataset: https://zenodo.org/records/4498364
# Kaggle: https://www.kaggle.com/datasets/andrewmvd/covid19-cough-audio-classification
# Coswara: https://github.com/iiscleap/Coswara-Data

# ===== PIP INSTALLS (Run these in Colab first) =====
# !pip install tensorflow librosa soundfile numpy matplotlib scikit-learn

import os
import glob
import librosa
import soundfile as sf
import numpy as np
import matplotlib.pyplot as plt
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns

# ===== SECTION 1: PARAMETERS =====
SAMPLE_RATE = 22050
N_MELS = 128
HOP_LENGTH = 512
N_FFT = 2048
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
CLASSES = ["DRY_COUGH", "WET_COUGH", "WHEEZING", "TB_SUSPECT", "NORMAL"]
NUM_CLASSES = len(CLASSES)

# ===== SECTION 2: PREPROCESSING & AUGMENTATION =====

def augment_audio(y, sr):
    """Apply time stretch, pitch shift, and add noise."""
    aug_type = np.random.choice([0, 1, 2, 3])
    if aug_type == 1:
        # Time stretch
        rate = np.random.uniform(0.8, 1.2)
        y = librosa.effects.time_stretch(y, rate=rate)
    elif aug_type == 2:
        # Pitch shift
        steps = np.random.randint(-2, 3)
        y = librosa.effects.pitch_shift(y, sr=sr, n_steps=steps)
    elif aug_type == 3:
        # Add background noise
        noise_amp = 0.005 * np.random.uniform() * np.amax(y)
        y = y + noise_amp * np.random.normal(size=y.shape[0])
    return y

def create_melspectrogram(audio_path, augment=False):
    """Load audio, optionally augment, generate mel-spectrogram, resize to 224x224, convert to dB."""
    try:
        y, sr = librosa.load(audio_path, sr=SAMPLE_RATE)
        
        if augment:
            y = augment_audio(y, sr)
            
        S = librosa.feature.melspectrogram(y=y, sr=sr, n_fft=N_FFT, hop_length=HOP_LENGTH, n_mels=N_MELS)
        S_dB = librosa.power_to_db(S, ref=np.max)
        
        # Resize to 224x224
        # Spectrogram is (N_MELS, TIME). We need to resize to (224, 224)
        S_dB = np.expand_dims(S_dB, axis=-1)
        S_dB_resized = tf.image.resize(S_dB, IMG_SIZE).numpy()
        
        # MobileNet expects 3 channels, duplicate the grayscale channel
        S_dB_3ch = np.concatenate([S_dB_resized, S_dB_resized, S_dB_resized], axis=-1)
        
        # Normalize to [0, 1] or [-1, 1] for MobileNetV2
        S_dB_norm = (S_dB_3ch - S_dB_3ch.min()) / (S_dB_3ch.max() - S_dB_3ch.min() + 1e-8)
        
        return S_dB_norm
    except Exception as e:
        print(f"Error processing {audio_path}: {e}")
        return None

def visualize_spectrogram(audio_path):
    """Visualize a sample spectrogram."""
    mel = create_melspectrogram(audio_path)
    if mel is not None:
        plt.figure(figsize=(10, 4))
        plt.imshow(mel[:,:,0], aspect='auto', origin='lower')
        plt.title(f'Mel-Spectrogram for {os.path.basename(audio_path)}')
        plt.colorbar(format='%+2.0f dB')
        plt.tight_layout()
        plt.show()

# ===== SECTION 3: DATASET GENERATION =====
# Note: In a real scenario, this would load from the actual dataset paths
def dummy_data_generator(num_samples=100):
    """Generates dummy data for the purpose of making this script runnable."""
    print("Generating dummy data...")
    X = []
    y = []
    for _ in range(num_samples):
        # Create a dummy noisy signal
        dummy_audio = np.random.randn(SAMPLE_RATE * 2) # 2 seconds
        S = librosa.feature.melspectrogram(y=dummy_audio, sr=SAMPLE_RATE, n_fft=N_FFT, hop_length=HOP_LENGTH, n_mels=N_MELS)
        S_dB = librosa.power_to_db(S, ref=np.max)
        S_dB = np.expand_dims(S_dB, axis=-1)
        S_dB_resized = tf.image.resize(S_dB, IMG_SIZE).numpy()
        S_dB_3ch = np.concatenate([S_dB_resized, S_dB_resized, S_dB_resized], axis=-1)
        S_dB_norm = (S_dB_3ch - S_dB_3ch.min()) / (S_dB_3ch.max() - S_dB_3ch.min() + 1e-8)
        
        X.append(S_dB_norm)
        y.append(np.random.randint(0, NUM_CLASSES))
        
    return np.array(X), np.array(y)

X, y = dummy_data_generator(200)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
y_train_cat = tf.keras.utils.to_categorical(y_train, NUM_CLASSES)
y_test_cat = tf.keras.utils.to_categorical(y_test, NUM_CLASSES)

# ===== SECTION 4: MODEL DEFINITION =====
def build_model():
    base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
    
    # Phase 1: Freeze base model
    base_model.trainable = False
    
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dropout(0.5)(x)
    x = Dense(128, activation='relu')(x)
    predictions = Dense(NUM_CLASSES, activation='softmax')(x)
    
    model = Model(inputs=base_model.input, outputs=predictions)
    return model, base_model

model, base_model = build_model()

# ===== SECTION 5: TRAINING =====
# Callbacks
early_stop = EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True)
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=3, min_lr=1e-6)
checkpoint = ModelCheckpoint('best_cough_model.h5', monitor='val_accuracy', save_best_only=True)

# Phase 1: Train Head (10 epochs, lr=0.001)
print("--- PHASE 1: Training Head ---")
model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.001), 
              loss='categorical_crossentropy', 
              metrics=['accuracy'])

history1 = model.fit(X_train, y_train_cat, 
                     batch_size=BATCH_SIZE, 
                     epochs=10, 
                     validation_data=(X_test, y_test_cat),
                     callbacks=[early_stop, reduce_lr, checkpoint])

# Phase 2: Fine-tuning top 30 layers (20 epochs, lr=0.0001)
print("--- PHASE 2: Fine-Tuning Top 30 Layers ---")
base_model.trainable = True
# Freeze all layers except the top 30
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001), 
              loss='categorical_crossentropy', 
              metrics=['accuracy'])

history2 = model.fit(X_train, y_train_cat, 
                     batch_size=BATCH_SIZE, 
                     epochs=20, 
                     validation_data=(X_test, y_test_cat),
                     callbacks=[early_stop, reduce_lr, checkpoint])

# ===== SECTION 6: EVALUATION =====
def plot_training_curves(history1, history2):
    acc = history1.history['accuracy'] + history2.history['accuracy']
    val_acc = history1.history['val_accuracy'] + history2.history['val_accuracy']
    loss = history1.history['loss'] + history2.history['loss']
    val_loss = history1.history['val_loss'] + history2.history['val_loss']

    plt.figure(figsize=(12, 4))
    plt.subplot(1, 2, 1)
    plt.plot(acc, label='Training Accuracy')
    plt.plot(val_acc, label='Validation Accuracy')
    plt.axvline(x=len(history1.history['accuracy'])-1, color='r', linestyle='--', label='Phase 2 start')
    plt.legend()
    plt.title('Accuracy')

    plt.subplot(1, 2, 2)
    plt.plot(loss, label='Training Loss')
    plt.plot(val_loss, label='Validation Loss')
    plt.axvline(x=len(history1.history['loss'])-1, color='r', linestyle='--', label='Phase 2 start')
    plt.legend()
    plt.title('Loss')
    plt.show()

plot_training_curves(history1, history2)

# Evaluate on test set
y_pred_probs = model.predict(X_test)
y_pred = np.argmax(y_pred_probs, axis=1)

print("\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=CLASSES))

print("\nConfusion Matrix:")
cm = confusion_matrix(y_test, y_pred)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=CLASSES, yticklabels=CLASSES)
plt.ylabel('True label')
plt.xlabel('Predicted label')
plt.title('Confusion Matrix')
plt.show()

# ===== SECTION 7: EXPORT TO TFLITE =====
print("Converting model to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
# Optional: integer quantization with representative dataset could be added here
tflite_model = converter.convert()

with open('cough_classifier.tflite', 'wb') as f:
    f.write(tflite_model)

with open('labels.txt', 'w') as f:
    for cls in CLASSES:
        f.write(f"{cls}\n")

print("Saved 'cough_classifier.tflite' and 'labels.txt'.")
