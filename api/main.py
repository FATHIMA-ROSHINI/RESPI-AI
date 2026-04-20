import os
import torch
import shutil
import io
import numpy as np
import librosa
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from model import RespiratoryCNN
from model_stage2 import DiseaseClassifier
from preprocessing import AudioPreprocessor

model = None
stage2_model = None
processor = None
device = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global model, stage2_model, processor, device
    device = torch.device("cpu")
    model = RespiratoryCNN().to(device)
    stage2_model = DiseaseClassifier().to(device)
    processor = AudioPreprocessor()
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    weights_path = os.path.join(base_dir, "model_weights.pth")
    if os.path.exists(weights_path):
        model.load_state_dict(torch.load(weights_path, map_location=device))
    
    stage2_weights_path = os.path.join(base_dir, "model_stage2_weights.pth")
    if os.path.exists(stage2_weights_path):
        stage2_model.load_state_dict(torch.load(stage2_weights_path, map_location=device))
    
    model.eval()
    stage2_model.eval()
    yield

app = FastAPI(title="Resp-AI API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Resp-AI is Online"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/api/analyze")
async def analyze_audio(file: UploadFile = File(...)):
    global model, stage2_model, processor, device
    
    filename = file.filename or "audio.wav"
    if not filename.endswith(('.wav', '.mp3')):
        raise HTTPException(status_code=400, detail="Invalid file format")
    
    temp_path = f"temp_{filename}"
    try:
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        features = processor.extract_features(temp_path)
        features = features.unsqueeze(0).to(device)
        
        with torch.no_grad():
            risk_prediction, embeddings = model(features)
            probability = risk_prediction.item()
            disease_probs = stage2_model.predict_probs(embeddings)
            top_prob, top_class_idx = torch.max(disease_probs, 1)
            predicted_disease = stage2_model.classes[top_class_idx.item()]
            disease_confidence = top_prob.item()
        
        os.remove(temp_path)
        
        risk_score = round(probability * 10, 1)
        classification = "Normal"
        if risk_score >= 7:
            classification = "High Risk"
        elif risk_score >= 4:
            classification = "Mild Risk"
        
        if risk_score < 3.5:
            predicted_disease = "No abnormality detected"
            disease_confidence_str = "N/A"
            disclaimer = "No significant abnormal patterns detected."
        else:
            disease_confidence_str = f"{disease_confidence*100:.1f}%"
            disclaimer = "Probabilistic association only. Not a clinical diagnosis."
        
        return {
            "filename": filename,
            "risk_score": risk_score,
            "probability": probability,
            "classification": classification,
            "disease_association": {
                "condition": predicted_disease,
                "confidence": disease_confidence_str,
                "disclaimer": disclaimer
            },
            "details": {
                "detected_anomalies": ["Abnormal Patterns"] if risk_score >= 4.0 else [],
                "medical_disclaimer": "This system provides probabilistic risk assessment."
            }
        }
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        raise HTTPException(status_code=500, detail=str(e))