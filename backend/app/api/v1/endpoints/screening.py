"""
Non-Invasive Diagnostic Screening Router
Cough Acoustic Biomarker Analysis & Camera Anemia Colorimetry
"""
from fastapi import APIRouter, File, UploadFile, Body
from typing import Optional, Dict, Any
from pydantic import BaseModel
from app.services.cough_analysis import analyze_cough_audio_bytes
from app.services.clinical_engine import analyze_palmar_anemia_colorimetry

router = APIRouter()

class AnemiaRGBInput(BaseModel):
    red: int = 180
    green: int = 135
    blue: int = 125

@router.post("/cough")
async def screen_cough_audio(file: UploadFile = File(...)):
    """
    Accepts uploaded cough audio WAV/MP3 file and analyzes spectral acoustic biomarkers.
    """
    contents = await file.read()
    res = analyze_cough_audio_bytes(contents, file.filename)
    return res

@router.post("/cough-demo")
def screen_cough_demo():
    """Demo endpoint returning sample acoustic cough biomarker diagnosis."""
    sample_bytes = b"DEMO_AUDIO_WAVEFORM_SAMPLE_12345"
    return analyze_cough_audio_bytes(sample_bytes, "demo.wav")

@router.post("/anemia-colorimetry")
def screen_anemia_colorimetry(rgb: AnemiaRGBInput = Body(...)):
    """
    Accepts average RGB values from palmar surface / conjunctiva camera crop.
    Estimates Hemoglobin level (g/dL) non-invasively.
    """
    return analyze_palmar_anemia_colorimetry(rgb.red, rgb.green, rgb.blue)
