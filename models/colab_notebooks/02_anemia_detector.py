# ===== DATA SOURCES =====
# Fingernail Anemia Dataset (Mendeley): https://data.mendeley.com/datasets/2xx4j3kjg2/1
# Kaggle: https://www.kaggle.com/datasets/biswaranjanrao/non-invasive-anemia-detection
# HuggingFace: https://huggingface.co/JetX-GT/nail-anemia-detector

# ===== PIP INSTALLS (Run these in Colab first) =====
# !pip install tensorflow opencv-python-headless Pillow numpy matplotlib scikit-learn albumentations

import os
import cv2
import numpy as np
import matplotlib.pyplot as plt
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Input
from tensorflow.keras.models import Model
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, confusion_matrix, classification_report
import albumentations as A
import seaborn as sns

# ===== SECTION 1: PARAMETERS =====
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
CLASSES = ["NORMAL", "MILD", "MODERATE", "SEVERE"]
NUM_CLASSES = len(CLASSES)

# ===== SECTION 2: PREPROCESSING & AUGMENTATION =====
def segment_nail_bed(image):
    """
    Apply OpenCV HSV skin mask to segment nail bed. 
    This is a simplified segmentation placeholder.
    """
    hsv = cv2.cvtColor(image, cv2.COLOR_RGB2HSV)
    
    # Define generic skin/nail color range in HSV
    lower = np.array([0, 20, 70], dtype="uint8")
    upper = np.array([20, 255, 255], dtype="uint8")
    
    mask = cv2.inRange(hsv, lower, upper)
    
    # Morphological operations to clean mask
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    
    # Extract ROI (Bounding box around largest contour)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if contours:
        c = max(contours, key=cv2.contourArea)
        x, y, w, h = cv2.boundingRect(c)
        roi = image[y:y+h, x:x+w]
    else:
        roi = image # Fallback
        
    return roi

def preprocess_image(image_path):
    """Load image, segment nail bed, resize, convert to LAB color space."""
    image = cv2.imread(image_path)
    if image is None: return None
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    roi = segment_nail_bed(image)
    resized = cv2.resize(roi, IMG_SIZE)
    
    # Convert to CIELAB color space
    lab_image = cv2.cvtColor(resized, cv2.COLOR_RGB2LAB)
    
    # Normalize to [0, 1]
    lab_norm = lab_image.astype(np.float32) / 255.0
    return lab_norm

# Albumentations Augmentation Pipeline
aug_pipeline = A.Compose([
    A.Rotate(limit=15, p=0.5),
    A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0, p=0.5),
    A.HorizontalFlip(p=0.5)
])

def augment_data(image):
    # albumentations expects uint8 for image manipulation
    img_uint8 = (image * 255).astype(np.uint8)
    augmented = aug_pipeline(image=img_uint8)
    return augmented['image'].astype(np.float32) / 255.0

# ===== SECTION 3: DATASET GENERATION =====
# Note: In a real scenario, this would load from the actual dataset paths
def dummy_data_generator(num_samples=100):
    """Generates dummy data for the purpose of making this script runnable."""
    print("Generating dummy data...")
    X = []
    y_reg = []
    y_clf = []
    for _ in range(num_samples):
        # Create random LAB image
        dummy_img = np.random.rand(224, 224, 3)
        X.append(dummy_img)
        
        # Generate random Hb level (e.g., between 5 and 16)
        hb = np.random.uniform(5.0, 16.0)
        y_reg.append(hb)
        
        # Determine class based on Hb
        if hb >= 12.0:
            c = 0 # NORMAL
        elif hb >= 10.0:
            c = 1 # MILD
        elif hb >= 7.0:
            c = 2 # MODERATE
        else:
            c = 3 # SEVERE
        y_clf.append(c)
        
    return np.array(X), np.array(y_reg), np.array(y_clf)

X, y_reg, y_clf = dummy_data_generator(200)
X_train, X_test, y_reg_train, y_reg_test, y_clf_train, y_clf_test = train_test_split(
    X, y_reg, y_clf, test_size=0.2, random_state=42
)
y_clf_train_cat = tf.keras.utils.to_categorical(y_clf_train, NUM_CLASSES)
y_clf_test_cat = tf.keras.utils.to_categorical(y_clf_test, NUM_CLASSES)

# ===== SECTION 4: MODEL DEFINITION =====
def build_dual_head_model():
    inputs = Input(shape=(224, 224, 3))
    
    # Using EfficientNetB0 as base model
    base_model = EfficientNetB0(include_top=False, weights='imagenet', input_tensor=inputs)
    
    # Phase 1: Freeze base model
    base_model.trainable = False
    
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dropout(0.4)(x)
    
    # Head 1: Regression (Hemoglobin g/dL)
    reg_head = Dense(64, activation='relu')(x)
    reg_output = Dense(1, activation='linear', name='regression_output')(reg_head)
    
    # Head 2: Classification (Severity)
    clf_head = Dense(64, activation='relu')(x)
    clf_output = Dense(NUM_CLASSES, activation='softmax', name='classification_output')(clf_head)
    
    model = Model(inputs=inputs, outputs=[reg_output, clf_output])
    return model, base_model

model, base_model = build_dual_head_model()

# ===== SECTION 5: TRAINING =====
early_stop = EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True)
checkpoint = ModelCheckpoint('best_anemia_model.h5', monitor='val_loss', save_best_only=True)

# Phase 1: Train Heads (15 epochs)
print("--- PHASE 1: Training Heads ---")
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss={'regression_output': 'mse', 'classification_output': 'categorical_crossentropy'},
    loss_weights={'regression_output': 0.7, 'classification_output': 0.3},
    metrics={'regression_output': 'mae', 'classification_output': 'accuracy'}
)

history1 = model.fit(
    X_train, {'regression_output': y_reg_train, 'classification_output': y_clf_train_cat},
    batch_size=BATCH_SIZE,
    epochs=15,
    validation_data=(X_test, {'regression_output': y_reg_test, 'classification_output': y_clf_test_cat}),
    callbacks=[early_stop, checkpoint]
)

# Phase 2: Fine-tuning top 20 blocks (30 epochs)
print("--- PHASE 2: Fine-Tuning Top 20 Blocks ---")
base_model.trainable = True
for layer in base_model.layers[:-20]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
    loss={'regression_output': 'mse', 'classification_output': 'categorical_crossentropy'},
    loss_weights={'regression_output': 0.7, 'classification_output': 0.3},
    metrics={'regression_output': 'mae', 'classification_output': 'accuracy'}
)

history2 = model.fit(
    X_train, {'regression_output': y_reg_train, 'classification_output': y_clf_train_cat},
    batch_size=BATCH_SIZE,
    epochs=30,
    validation_data=(X_test, {'regression_output': y_reg_test, 'classification_output': y_clf_test_cat}),
    callbacks=[early_stop, checkpoint]
)

# ===== SECTION 6: EVALUATION =====
# Evaluate on test set
preds_reg, preds_clf_probs = model.predict(X_test)
preds_clf = np.argmax(preds_clf_probs, axis=1)

mae = mean_absolute_error(y_reg_test, preds_reg)
print(f"\nMean Absolute Error (Hb): {mae:.2f} g/dL")

print("\nClassification Report (Severity):")
print(classification_report(y_clf_test, preds_clf, target_names=CLASSES, zero_division=0))

# Calculate sensitivity for severe anemia (Class 3)
cm = confusion_matrix(y_clf_test, preds_clf)
if np.sum(cm[3,:]) > 0:
    severe_sensitivity = cm[3,3] / np.sum(cm[3,:])
    print(f"Sensitivity for SEVERE anemia: {severe_sensitivity:.2%}")
else:
    print("Sensitivity for SEVERE anemia: N/A (no severe cases in test set)")

plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Reds', xticklabels=CLASSES, yticklabels=CLASSES)
plt.ylabel('True label')
plt.xlabel('Predicted label')
plt.title('Confusion Matrix (Severity)')
plt.show()

# ===== SECTION 7: EXPORT TO TFLITE =====
print("Converting model to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open('anemia_estimator.tflite', 'wb') as f:
    f.write(tflite_model)

print("Saved 'anemia_estimator.tflite'.")
