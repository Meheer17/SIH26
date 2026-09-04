# ===== DATA SOURCES =====
# i2b2 2010: https://portal.dbmi.hms.harvard.edu/projects/n2c2-nlp/ (requires registration)
# Synthetic Indian Clinical Notes: https://data.mendeley.com/ (search 'synthetic Indian clinical notes')
# BC5CDR: https://biocreative.bioinformatics.udel.edu/tasks/biocreative-v/track-3-cdr/
# NCBI Disease Corpus: https://www.ncbi.nlm.nih.gov/CBBresearch/Dogan/DISEASE/

# ===== PIP INSTALLS =====
# Run these in a Colab cell before executing the script:
# !pip install transformers datasets torch seqeval spacy numpy accelerate

import os
import random
import numpy as np
import torch
import spacy
from transformers import AutoTokenizer, AutoModelForTokenClassification, Trainer, TrainingArguments, DataCollatorForTokenClassification
from datasets import Dataset, DatasetDict
from seqeval.metrics import precision_score, recall_score, f1_score, classification_report

# ===== SECTION: CONSTANTS & SETUP =====
MODEL_CHECKPOINT = "bert-base-multilingual-uncased"
OUTPUT_DIR = "./results_ner"
SAVE_DIR = "models/trained/medical_ner_model/"

# Define the entity labels (BIO format)
LABEL_LIST = [
    "O",
    "B-SYMPTOM", "I-SYMPTOM",
    "B-MEDICATION", "I-MEDICATION",
    "B-DOSAGE", "I-DOSAGE",
    "B-CONDITION", "I-CONDITION",
    "B-BODY_PART", "I-BODY_PART"
]

label2id = {label: i for i, label in enumerate(LABEL_LIST)}
id2label = {i: label for i, label in enumerate(LABEL_LIST)}

os.makedirs(SAVE_DIR, exist_ok=True)

# ===== SECTION: DEMO DATASET GENERATION =====
def generate_synthetic_data(num_samples=250):
    """
    Generate synthetic Indian clinical sentences with BIO tags.
    """
    templates = [
        "Patient has {symptom} since yesterday .",
        "Prescribed {medication} {dosage} for {condition} .",
        "Complains of severe {symptom} in the {body_part} .",
        "Advised to take {medication} {dosage} after meals .",
        "Diagnosis is {condition} with acute {symptom} .",
        "Take {medication} {dosage} for {symptom} .",
        "{symptom} in {body_part} observed .",
        "Patient with {condition} needs {medication} {dosage} ."
    ]
    
    symptoms = [("bukhar", "B-SYMPTOM"), ("fever", "B-SYMPTOM"), ("sir dard", "B-SYMPTOM", "I-SYMPTOM"), ("headache", "B-SYMPTOM"), ("pet dard", "B-SYMPTOM", "I-SYMPTOM"), ("stomach pain", "B-SYMPTOM", "I-SYMPTOM"), ("cough", "B-SYMPTOM"), ("khasi", "B-SYMPTOM"), ("nausea", "B-SYMPTOM")]
    medications = [("Crocin", "B-MEDICATION"), ("Dolo-650", "B-MEDICATION"), ("Combiflam", "B-MEDICATION"), ("Becosules", "B-MEDICATION"), ("Shelcal", "B-MEDICATION"), ("Paracetamol", "B-MEDICATION")]
    dosages = [("BD", "B-DOSAGE"), ("OD", "B-DOSAGE"), ("TDS", "B-DOSAGE"), ("HS", "B-DOSAGE"), ("SOS", "B-DOSAGE"), ("500mg", "B-DOSAGE"), ("1tab", "B-DOSAGE")]
    conditions = [("Typhoid", "B-CONDITION"), ("Dengue", "B-CONDITION"), ("Malaria", "B-CONDITION"), ("Viral Infection", "B-CONDITION", "I-CONDITION"), ("Hypertension", "B-CONDITION"), ("Diabetes", "B-CONDITION")]
    body_parts = [("head", "B-BODY_PART"), ("stomach", "B-BODY_PART"), ("leg", "B-BODY_PART"), ("chest", "B-BODY_PART"), ("gala", "B-BODY_PART"), ("throat", "B-BODY_PART"), ("back", "B-BODY_PART")]

    data = []
    
    for _ in range(num_samples):
        template = random.choice(templates)
        tokens = []
        tags = []
        
        for word in template.split():
            if word == "{symptom}":
                choice = random.choice(symptoms)
                tokens.extend(choice[0].split())
                tags.extend(choice[1:])
            elif word == "{medication}":
                choice = random.choice(medications)
                tokens.extend(choice[0].split())
                tags.extend(choice[1:])
            elif word == "{dosage}":
                choice = random.choice(dosages)
                tokens.extend(choice[0].split())
                tags.extend(choice[1:])
            elif word == "{condition}":
                choice = random.choice(conditions)
                tokens.extend(choice[0].split())
                tags.extend(choice[1:])
            elif word == "{body_part}":
                choice = random.choice(body_parts)
                tokens.extend(choice[0].split())
                tags.extend(choice[1:])
            else:
                tokens.append(word)
                tags.append("O")
                
        data.append({"tokens": tokens, "ner_tags": [label2id[tag] for tag in tags]})
        
    return data

print("Generating synthetic clinical data...")
all_data = generate_synthetic_data(300)
# Split into train/val
train_data = all_data[:250]
val_data = all_data[250:]

hf_dataset = DatasetDict({
    "train": Dataset.from_list(train_data),
    "validation": Dataset.from_list(val_data)
})

# ===== SECTION: PREPROCESSING =====
tokenizer = AutoTokenizer.from_pretrained(MODEL_CHECKPOINT)

def tokenize_and_align_labels(examples):
    tokenized_inputs = tokenizer(examples["tokens"], truncation=True, is_split_into_words=True, padding="max_length", max_length=128)
    
    labels = []
    for i, label in enumerate(examples["ner_tags"]):
        word_ids = tokenized_inputs.word_ids(batch_index=i)
        previous_word_idx = None
        label_ids = []
        for word_idx in word_ids:
            if word_idx is None:
                label_ids.append(-100) # Ignore special tokens
            elif word_idx != previous_word_idx:
                label_ids.append(label[word_idx])
            else:
                # Subword tokens: optionally mark as inner or ignore. We use -100 to only train on first subword
                label_ids.append(-100)
            previous_word_idx = word_idx
        labels.append(label_ids)

    tokenized_inputs["labels"] = labels
    return tokenized_inputs

print("Tokenizing datasets...")
tokenized_datasets = hf_dataset.map(tokenize_and_align_labels, batched=True)

# ===== SECTION: MODEL DEFINITION & TRAINING =====
model = AutoModelForTokenClassification.from_pretrained(
    MODEL_CHECKPOINT,
    num_labels=len(LABEL_LIST),
    id2label=id2label,
    label2id=label2id
)

data_collator = DataCollatorForTokenClassification(tokenizer)

def compute_metrics(p):
    predictions, labels = p
    predictions = np.argmax(predictions, axis=2)

    # Remove ignored index (special tokens)
    true_predictions = [
        [LABEL_LIST[p] for (p, l) in zip(prediction, label) if l != -100]
        for prediction, label in zip(predictions, labels)
    ]
    true_labels = [
        [LABEL_LIST[l] for (p, l) in zip(prediction, label) if l != -100]
        for prediction, label in zip(predictions, labels)
    ]

    return {
        "precision": precision_score(true_labels, true_predictions),
        "recall": recall_score(true_labels, true_predictions),
        "f1": f1_score(true_labels, true_predictions),
    }

training_args = TrainingArguments(
    output_dir=OUTPUT_DIR,
    evaluation_strategy="epoch",
    learning_rate=2e-5,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=5,
    weight_decay=0.01,
    logging_steps=10,
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_datasets["train"],
    eval_dataset=tokenized_datasets["validation"],
    data_collator=data_collator,
    tokenizer=tokenizer,
    compute_metrics=compute_metrics
)

# Uncomment the following to run training:
# print("Starting training...")
# trainer.train()
# print("Evaluation results:", trainer.evaluate())

# ===== SECTION: EXPORT =====
# print(f"Saving model to {SAVE_DIR}")
# trainer.save_model(SAVE_DIR)

# ===== SECTION: RULE-BASED SPACY ALTERNATIVE =====
print("\n--- Running spaCy Rule-based Alternative ---")
from spacy.matcher import Matcher

nlp = spacy.blank("en")
matcher = Matcher(nlp.vocab)

# Add patterns
matcher.add("SYMPTOM", [[{"LOWER": "bukhar"}], [{"LOWER": "sir"}, {"LOWER": "dard"}], [{"LOWER": "fever"}]])
matcher.add("MEDICATION", [[{"LOWER": "crocin"}], [{"LOWER": "dolo-650"}], [{"LOWER": "paracetamol"}]])
matcher.add("DOSAGE", [[{"LOWER": "bd"}], [{"LOWER": "sos"}], [{"LOWER": "500mg"}]])

text = "Patient has bukhar and sir dard. Advised Dolo-650 BD."
doc = nlp(text)
matches = matcher(doc)

for match_id, start, end in matches:
    string_id = nlp.vocab.strings[match_id]
    span = doc[start:end]
    print(f"Found Entity: {span.text} -> {string_id}")
