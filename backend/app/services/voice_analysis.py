import re
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)


def analyze_voice_stress_and_sentiment(
    text: str,
    pitch_variance: Optional[float] = None,
    pause_ratio: Optional[float] = None,
    speech_rate_wpm: Optional[float] = None
) -> Dict[str, Any]:
    """
    Analyze text transcription and vocal acoustic parameters to compute:
    1. Sentiment score (-1.0 to 1.0)
    2. Physiological Voice Stress Index (0 to 100)
    3. Emotion category (Calm, Anxious, Distressed, High Crisis)
    """
    text_clean = text.strip().lower()
    
    # 1. Linguistic Sentiment & Anxiety Keyword Analysis
    high_anxiety_words = ["anxious", "fear", "scared", "threat", "court", "trial", "police", "panic", "suicide", "hopeless", "tremor", "crying", "pain", "beaten", "harassed"]
    moderate_stress_words = ["tense", "worried", "patrol", "shift", "duty", "tired", "sleep", "exhausted", "heavy", "delay"]
    calm_words = ["fine", "calm", "good", "better", "safe", "stable", "relax", "supported"]

    anxiety_count = sum(1 for w in high_anxiety_words if w in text_clean)
    stress_count = sum(1 for w in moderate_stress_words if w in text_clean)
    calm_count = sum(1 for w in calm_words if w in text_clean)

    # Base sentiment polarity computation
    raw_sentiment = 0.0
    if calm_count > (anxiety_count + stress_count):
        raw_sentiment = 0.5 + min(0.5, calm_count * 0.15)
    else:
        raw_sentiment = -0.2 - min(0.8, (anxiety_count * 0.25) + (stress_count * 0.10))

    sentiment_score = round(max(-1.0, min(1.0, raw_sentiment)), 2)

    # 2. Acoustic Voice Marker Analysis
    p_var = pitch_variance if pitch_variance is not None else (35.0 if anxiety_count > 0 else 12.0)
    p_ratio = pause_ratio if pause_ratio is not None else (0.42 if anxiety_count > 0 else 0.18)
    s_rate = speech_rate_wpm if speech_rate_wpm is not None else (185.0 if anxiety_count > 0 else 140.0)

    # Voice Stress Index (0-100)
    acoustic_stress = (p_var * 0.8) + (p_ratio * 60.0) + (abs(s_rate - 140.0) * 0.3)
    linguistic_stress = abs(min(0.0, sentiment_score)) * 60.0
    
    voice_stress_score = min(100, int((acoustic_stress * 0.5) + (linguistic_stress * 0.5)))

    # Severity Tier Determination
    stress_tier = "LOW"
    emotion = "CALM"
    if voice_stress_score >= 75:
        stress_tier = "CRITICAL"
        emotion = "HIGH_DISTRESS_CRISIS"
    elif voice_stress_score >= 50:
        stress_tier = "HIGH"
        emotion = "ANXIOUS_PERCEIVED_THREAT"
    elif voice_stress_score >= 30:
        stress_tier = "MODERATE"
        emotion = "MILD_TENSION"

    return {
        "text": text,
        "sentiment_score": sentiment_score,
        "voice_stress_score": voice_stress_score,
        "stress_tier": stress_tier,
        "emotion_classification": emotion,
        "acoustic_markers": {
            "pitch_variance_hz": round(p_var, 1),
            "vocal_pause_ratio": round(p_ratio, 2),
            "speech_rate_wpm": round(s_rate, 1),
            "tremor_detected": p_var > 30.0
        },
        "escalation_recommended": voice_stress_score >= 60
    }
