import re
import logging
from typing import Dict, Any, Optional, List

logger = logging.getLogger(__name__)


def analyze_voice_stress_and_sentiment(
    text: str,
    pitch_variance: Optional[float] = None,
    pause_ratio: Optional[float] = None,
    speech_rate_wpm: Optional[float] = None,
    vocal_tremor_score: Optional[float] = None,
    audio_duration_sec: Optional[float] = None
) -> Dict[str, Any]:
    """
    Analyze text transcription and vocal acoustic parameters to compute:
    1. Sentiment score (-1.0 to 1.0)
    2. Physiological Voice Stress Index (0 to 100)
    3. Voice Fatigue & Exhaustion Index (0 to 100)
    4. Emotion category & clinical welfare recommendations
    """
    text_clean = text.strip().lower() if text else ""
    
    # 1. Linguistic Sentiment, Stress & Fatigue Keyword Analysis
    high_anxiety_words = ["anxious", "fear", "scared", "threat", "court", "trial", "police", "panic", "suicide", "hopeless", "tremor", "crying", "pain", "beaten", "harassed", "attack"]
    stress_words = ["tense", "worried", "patrol", "shift", "duty", "pressure", "heavy", "delay", "struggling", "danger"]
    fatigue_words = ["tired", "exhausted", "fatigued", "sleep", "sleepy", "drained", "weak", "weary", "night watch", "burnout", "headache", "dizzy", "unfocused"]
    calm_words = ["fine", "calm", "good", "better", "safe", "stable", "relax", "supported", "rested", "okay"]

    anxiety_count = sum(1 for w in high_anxiety_words if w in text_clean)
    stress_count = sum(1 for w in stress_words if w in text_clean)
    fatigue_count = sum(1 for w in fatigue_words if w in text_clean)
    calm_count = sum(1 for w in calm_words if w in text_clean)

    # Base sentiment polarity computation
    raw_sentiment = 0.0
    total_negative = anxiety_count + stress_count + fatigue_count
    if calm_count > total_negative:
        raw_sentiment = 0.5 + min(0.5, calm_count * 0.15)
    else:
        raw_sentiment = -0.2 - min(0.8, (anxiety_count * 0.25) + (stress_count * 0.12) + (fatigue_count * 0.15))

    sentiment_score = round(max(-1.0, min(1.0, raw_sentiment)), 2)

    # 2. Acoustic Voice Marker Analysis
    p_var = pitch_variance if pitch_variance is not None else (36.0 if anxiety_count > 0 else (22.0 if stress_count > 0 else 12.0))
    p_ratio = pause_ratio if pause_ratio is not None else (0.45 if fatigue_count > 0 else (0.35 if anxiety_count > 0 else 0.18))
    s_rate = speech_rate_wpm if speech_rate_wpm is not None else (110.0 if fatigue_count > 0 else (185.0 if anxiety_count > 0 else 140.0))
    tremor = vocal_tremor_score if vocal_tremor_score is not None else (0.65 if anxiety_count > 0 else 0.15)

    # 3. Voice Stress Index (0-100)
    acoustic_stress = (p_var * 0.8) + (tremor * 40.0) + (abs(s_rate - 140.0) * 0.3)
    linguistic_stress = abs(min(0.0, sentiment_score)) * 60.0
    voice_stress_score = min(100, max(5, int((acoustic_stress * 0.5) + (linguistic_stress * 0.5))))

    # 4. Voice Fatigue Index (0-100)
    # Slow speech rate (< 120 wpm), high vocal pauses (> 0.35), and fatigue linguistic cues
    acoustic_fatigue = (p_ratio * 70.0) + (max(0.0, (140.0 - s_rate)) * 0.4)
    linguistic_fatigue = min(60.0, fatigue_count * 25.0)
    voice_fatigue_score = min(100, max(8, int((acoustic_fatigue * 0.55) + (linguistic_fatigue * 0.45))))

    # 5. Severity Tiers Determination
    stress_tier = "LOW"
    if voice_stress_score >= 75:
        stress_tier = "CRITICAL"
    elif voice_stress_score >= 50:
        stress_tier = "HIGH"
    elif voice_stress_score >= 30:
        stress_tier = "MODERATE"

    fatigue_tier = "RESTED"
    if voice_fatigue_score >= 75:
        fatigue_tier = "CRITICAL_BURNOUT"
    elif voice_fatigue_score >= 50:
        fatigue_tier = "HIGH_EXHAUSTION"
    elif voice_fatigue_score >= 30:
        fatigue_tier = "MILD_FATIGUE"

    emotion = "CALM_AND_ALERT"
    if voice_stress_score >= 75:
        emotion = "HIGH_DISTRESS_CRISIS"
    elif voice_fatigue_score >= 65:
        emotion = "HEAVY_SLEEP_DEPRIVED_FATIGUE"
    elif voice_stress_score >= 50:
        emotion = "ANXIOUS_PERCEIVED_THREAT"
    elif voice_fatigue_score >= 40:
        emotion = "MILD_DUTY_FATIGUE"
    elif voice_stress_score >= 30:
        emotion = "MILD_TENSION"

    # 6. Actionable Clinical Recommendations
    recommendations: List[str] = []
    if voice_fatigue_score >= 60:
        recommendations.append("🛌 Immediate 6-8 hours restorative sleep cycle recommended. Suspend extended night duty shifts.")
        recommendations.append("💧 Hydrate with electrolyte-rich fluids (ORS / fresh water) to combat metabolic dehydration.")
    elif voice_fatigue_score >= 35:
        recommendations.append("☕ Schedule a 20-minute power nap or quiet decompression break between duty watches.")

    if voice_stress_score >= 60:
        recommendations.append("🧘 Perform 4-7-8 tactical box breathing exercises (inhale 4s, hold 7s, exhale 8s) to down-regulate sympathetic arousal.")
        recommendations.append("🤝 Connect with Unit Welfare Officer or confidential counseling support.")
    elif voice_stress_score < 35 and voice_fatigue_score < 35:
        recommendations.append("✅ Physiological baseline is stable. Continue balanced duty rotation and hydration.")

    return {
        "text": text,
        "sentiment_score": sentiment_score,
        "voice_stress_score": voice_stress_score,
        "voice_fatigue_score": voice_fatigue_score,
        "stress_tier": stress_tier,
        "fatigue_tier": fatigue_tier,
        "emotion_classification": emotion,
        "acoustic_markers": {
            "pitch_variance_hz": round(p_var, 1),
            "vocal_pause_ratio": round(p_ratio, 2),
            "speech_rate_wpm": round(s_rate, 1),
            "tremor_score": round(tremor, 2),
            "tremor_detected": tremor > 0.4 or p_var > 30.0,
            "speech_cadence": "Slow / Hesitant" if s_rate < 120 else ("Fast / Agitated" if s_rate > 165 else "Normal")
        },
        "recommendations": recommendations,
        "escalation_recommended": voice_stress_score >= 60 or voice_fatigue_score >= 75
    }

