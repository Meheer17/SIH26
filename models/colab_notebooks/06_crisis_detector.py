# ===== SECTION: DATA SOURCES & SETUP =====
# DATA SOURCE: 
# Reddit SuicideWatch from Kaggle https://www.kaggle.com/datasets/nikhileswarkomati/suicide-watch
# SDCNL: https://www.kaggle.com/datasets/aunanya875/suicidal-tweet-detection-dataset
# BharatGen MHQA: https://aikosh.ai/
#
# Colab Setup Instructions:
# Run the following in a Colab cell before running this script:
# !pip install transformers datasets torch scikit-learn numpy matplotlib accelerate

import os
import numpy as np
import torch
from datasets import Dataset
from transformers import (
    DistilBertTokenizerFast, 
    DistilBertForSequenceClassification, 
    Trainer, 
    TrainingArguments
)
from sklearn.metrics import accuracy_score, precision_recall_fscore_support, confusion_matrix
import matplotlib.pyplot as plt

# ===== SECTION: PREPROCESSING =====
# CLASSES: SAFE (0), MILD_DISTRESS (1), MODERATE_DISTRESS (2), CRISIS (3)
# LABEL MAPPING: 
#   SuicideWatch explicit ideation -> CRISIS
#   SuicideWatch distress -> MODERATE_DISTRESS
#   depression posts -> MILD_DISTRESS
#   CasualConversation -> SAFE
#
# Indian Context Examples:
# - 'Mujhe jeene ka mann nahi hai' -> CRISIS
# - 'Bahut akela feel hota hai' -> MODERATE_DISTRESS

def clean_text(text):
    import re
    text = re.sub(r'http\S+', '', text) # Remove URLs
    text = re.sub(r'@\w+', '', text)    # Remove usernames
    return text.strip()

# Dummy Data Generator to make script runnable
texts = [
    "I am having a good day.", 
    "I feel a bit sad today.", 
    "Bahut akela feel hota hai.", 
    "I can't take this anymore, I want to end it.",
    "Mujhe jeene ka mann nahi hai",
    "Just chatting with friends.",
    "Feeling overwhelmed with work."
] * 50
labels = [0, 1, 2, 3, 3, 0, 1] * 50

cleaned_texts = [clean_text(t) for t in texts]

tokenizer = DistilBertTokenizerFast.from_pretrained('distilbert-base-uncased')

def tokenize_function(examples):
    return tokenizer(examples["text"], padding="max_length", truncation=True, max_length=256)

dataset = Dataset.from_dict({"text": cleaned_texts, "label": labels})
dataset = dataset.map(tokenize_function, batched=True)

# Split dataset
dataset = dataset.train_test_split(test_size=0.2, seed=42)
train_dataset = dataset['train']
test_dataset = dataset['test']

# ===== SECTION: MODEL DEFINITION =====
model = DistilBertForSequenceClassification.from_pretrained(
    'distilbert-base-uncased', 
    num_labels=4
)

# ===== SECTION: TRAINING =====
# Class weights: Heavily weight CRISIS (3) class for high recall
class WeightedTrainer(Trainer):
    def compute_loss(self, model, inputs, return_outputs=False, num_items_in_batch=None):
        labels = inputs.pop("labels")
        outputs = model(**inputs)
        logits = outputs.logits
        # Heavy weight on CRISIS (index 3)
        loss_fct = torch.nn.CrossEntropyLoss(weight=torch.tensor([1.0, 1.5, 2.0, 5.0]).to(model.device))
        loss = loss_fct(logits.view(-1, self.model.config.num_labels), labels.view(-1))
        return (loss, outputs) if return_outputs else loss

def compute_metrics(pred):
    labels = pred.label_ids
    preds = pred.predictions.argmax(-1)
    
    # SAFETY ESCALATION CHECK
    probs = torch.nn.functional.softmax(torch.tensor(pred.predictions), dim=-1)
    crisis_probs = probs[:, 3]
    escalations = (crisis_probs > 0.3).sum().item()
    print(f"\n[SAFETY] Escalations triggered (Crisis prob > 0.3): {escalations}")
    
    precision, recall, f1, _ = precision_recall_fscore_support(labels, preds, average=None)
    acc = accuracy_score(labels, preds)
    
    # Pad to handle missing classes in small test set
    recall_full = np.zeros(4)
    for i, c in enumerate(np.unique(labels)):
        recall_full[c] = recall[i]
        
    f1_full = np.zeros(4)
    for i, c in enumerate(np.unique(labels)):
        f1_full[c] = f1[i]
    
    return {
        'accuracy': acc,
        'f1_safe': f1_full[0],
        'f1_mild': f1_full[1],
        'f1_mod': f1_full[2],
        'f1_crisis': f1_full[3],
        'recall_crisis': recall_full[3]
    }

# Ensure output dir is writable or use tmp/local
training_args = TrainingArguments(
    output_dir='./results',
    learning_rate=2e-5,
    per_device_train_batch_size=32,
    per_device_eval_batch_size=32,
    num_train_epochs=3,
    weight_decay=0.01,
    eval_strategy="epoch",  # updated param name
    save_strategy="epoch",
    load_best_model_at_end=True,
    logging_dir='./logs',
    report_to="none" # Disable W&B etc for plain colab run
)

trainer = WeightedTrainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=test_dataset,
    compute_metrics=compute_metrics
)

trainer.train()

# ===== SECTION: EVALUATION =====
eval_results = trainer.evaluate()
print("\nEvaluation Results:", eval_results)

crisis_recall = eval_results.get('eval_recall_crisis', 0)
if crisis_recall > 0.95:
    print(f"\nSUCCESS: CRISIS recall is {crisis_recall:.2%} (> 95%)")
else:
    print(f"\nWARNING: CRISIS recall is {crisis_recall:.2%} (<= 95%)")

predictions = trainer.predict(test_dataset)
preds = np.argmax(predictions.predictions, axis=-1)
cm = confusion_matrix(test_dataset['label'], preds)
print("\nConfusion Matrix:\n", cm)

# ===== SECTION: EXPORT =====
save_path = "/home/mahi17/Github/sih26/models/trained/crisis_detector_model/"
os.makedirs(save_path, exist_ok=True)
model.save_pretrained(save_path)
tokenizer.save_pretrained(save_path)
print(f"\nModel and Tokenizer successfully saved to {save_path}")
