import os
import joblib
import numpy as np
from typing import Dict, Any, List

# Load real trained ML model
_ANEMIA_MODEL_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../models/trained/anemia_estimator.pkl"))
_ANEMIA_MODEL = None
if os.path.exists(_ANEMIA_MODEL_PATH):
    try:
        _ANEMIA_MODEL = joblib.load(_ANEMIA_MODEL_PATH)
    except Exception:
        _ANEMIA_MODEL = None


def analyze_palmar_anemia_colorimetry(red_avg: int, green_avg: int, blue_avg: int) -> Dict[str, Any]:
    """
    Colorimetric hemoglobin estimation based on RGB parameters of palmar / conjunctival tissue.
    Uses trained Gradient Boosting Regressor model on color chromaticity features.
    """
    if red_avg + green_avg + blue_avg == 0:
        red_avg, green_avg, blue_avg = 180, 140, 130

    r = float(red_avg)
    g = float(green_avg)
    b = float(blue_avg)
    total = r + g + b + 1e-6
    rg_ratio = r / (g + 1e-6)
    r_norm = r / total
    g_norm = g / total
    b_norm = b / total
    norm_diff = (r - g) / (r + g + 1e-6)

    feature_vec = np.array([[r, g, b, rg_ratio, r_norm, g_norm, b_norm, norm_diff]])

    if _ANEMIA_MODEL is not None:
        predicted_hb = float(_ANEMIA_MODEL.predict(feature_vec)[0])
        estimated_hb = round(min(max(predicted_hb, 5.0), 18.0), 1)
        model_name = "GradientBoosting-Palmar-Colorimetry (Real Trained)"
    else:
        estimated_hb = round(min(max(rg_ratio * 9.2, 5.5), 16.5), 1)
        model_name = "Heuristic-Chromaticity-Formula"
    
    if estimated_hb < 8.0:
        severity = "SEVERE_ANEMIA"
        icd_code = "D50.9"
        recommendations = "Urgent medical evaluation needed. Iron supplementation & dietary assessment required."
        urgency = "HIGH"
    elif estimated_hb < 11.0:
        severity = "MODERATE_ANEMIA"
        icd_code = "D50.8"
        recommendations = "Increase intake of iron-rich foods (green leafy vegetables, jaggery, pulses) + Iron-Folic Acid tablets."
        urgency = "MODERATE"
    elif estimated_hb < 12.0:
        severity = "MILD_ANEMIA"
        icd_code = "D50.0"
        recommendations = "Dietary modifications and repeat screening in 30 days."
        urgency = "LOW"
    else:
        severity = "NORMAL_HEMOGLOBIN"
        icd_code = "Z00.0"
        recommendations = "Hemoglobin parameters within normal reference ranges."
        urgency = "NORMAL"

    return {
        "status": "SUCCESS",
        "estimated_hb_g_dl": estimated_hb,
        "anemia_severity": severity,
        "icd_10_code": icd_code,
        "ml_model": model_name,
        "colorimetric_rgb": {
            "red": red_avg,
            "green": green_avg,
            "blue": blue_avg,
            "rg_ratio": round(rg_ratio, 3),
            "red_chromaticity": round(r_norm, 3),
            "green_chromaticity": round(g_norm, 3)
        },
        "triage_urgency": urgency,
        "clinical_action": recommendations
    }



# Dual Prescription Knowledge Base: ICD-11 to Allopathy + AYUSH
DUAL_PATHWAY_DB = {
    "HEAT_STRESS": {
        "icd11": "NF00.0 (Heat Exhaustion)",
        "condition": "Heat Exhaustion & Dehydration",
        "allopathy": {
            "primary": "Oral Rehydration Salts (ORS) - 1 sachet in 1L clean water",
            "supportive": "Paracetamol 500mg (only if fever > 102°F)",
            "hydration": "0.9% Normal Saline IV (if severe / altered sensorium)"
        },
        "ayush": {
            "ayurveda": "Chandanadi Vati (250mg) + Ushirasava (20ml with equal water)",
            "dietary": "Coconut water, Amla sharbat, Barley water, Bilva sherbet",
            "yoga_pranayama": "Sheetali Pranayama (10 mins) & Sheetkari Pranayama for internal body cooling",
            "homeopathy": "Glonoinum 30C (3 drops in water every 2 hours during acute heat surge)"
        }
    },
    "ANEMIA": {
        "icd11": "3A00 (Iron Deficiency Anemia)",
        "condition": "Nutritional Anemia",
        "allopathy": {
            "primary": "Ferrous Ascorbate (100mg elemental iron) + Folic Acid (1.5mg) daily after meal",
            "supportive": "Vitamin C 500mg daily to enhance iron absorption"
        },
        "ayush": {
            "ayurveda": "Punarnavadi Mandoor (2 tablets twice daily) + Dhatri Lauha",
            "dietary": "Jaggery (Gud) with roasted chana, Moringa (Drumstick) leaves soup, Beetroot & Pomegranate juice",
            "yoga_pranayama": "Anulom Vilom Pranayama (15 mins) to increase oxygenation capacity",
            "homeopathy": "Ferrum Metallicum 6X (4 tablets 3 times a day)"
        }
    },
    "HYPERTENSION": {
        "icd11": "BA00 (Essential Hypertension)",
        "condition": "High Blood Pressure",
        "allopathy": {
            "primary": "Amlodipine 5mg once daily",
            "supportive": "Telmisartan 40mg (if prescribed by physician)"
        },
        "ayush": {
            "ayurveda": "Sarpagandha Vati (1 tablet at bedtime) + Brahmi Vati",
            "dietary": "Low sodium diet, Garlic infusion water, Flaxseed daily intake",
            "yoga_pranayama": "Shavasana (15 mins daily) & Bhramari Pranayama (10 mins)",
            "homeopathy": "Rauvolfia Serpentina Q (10 drops in 1/4th cup water twice daily)"
        }
    },
    "CHRONIC_STRESS": {
        "icd11": "6B40 (Post Traumatic Stress / Chronic Anxiety)",
        "condition": "Operational Stress & Trauma",
        "allopathy": {
            "primary": "Escitalopram 10mg (under psychiatrist guidance)",
            "supportive": "Sleep hygiene & Cognitive Behavioral Therapy (CBT)"
        },
        "ayush": {
            "ayurveda": "Ashwagandha Churna (3g with warm milk at night) + Shankhpushpi Syrup",
            "dietary": "Soaked almonds, Warm nutmeg milk before sleep",
            "yoga_pranayama": "Yoga Nidra (20 mins daily deep relaxation) & Nadi Shodhana",
            "homeopathy": "Kali Phosphoricum 6X (4 tablets 3 times daily for mental burnout)"
        }
    }
}

def generate_dual_prescription(condition_key: str, custom_symptoms: List[str] = None) -> Dict[str, Any]:
    """Generates dual-path Western Allopathy + AYUSH holistic treatment recommendation."""
    key = condition_key.upper().strip()
    pathway = DUAL_PATHWAY_DB.get(key)
    
    if not pathway:
        # Default fallback to general wellness/stress
        pathway = DUAL_PATHWAY_DB["HEAT_STRESS"]

    return {
        "status": "SUCCESS",
        "condition_name": pathway["condition"],
        "icd_11_code": pathway["icd11"],
        "allopathic_pathway": pathway["allopathy"],
        "ayush_integrative_pathway": pathway["ayush"],
        "disclaimer": "This dual-path recommendation is for clinical decision support. Always consult a certified Medical Officer or Registered AYUSH Practitioner before administering prescription drugs."
    }
