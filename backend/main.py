import os
import torch
import shutil
import io
import numpy as np
import librosa
from fastapi import FastAPI, UploadFile, File, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
try:
    from backend.model import RespiratoryCNN
    from backend.model_stage2 import DiseaseClassifier
    from backend.preprocessing import AudioPreprocessor
except ImportError:
    from model import RespiratoryCNN
    from model_stage2 import DiseaseClassifier
    from preprocessing import AudioPreprocessor


# Global variables for model
model = None
stage2_model = None
processor = None
device = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load model on startup
    global model, stage2_model, processor, device
    
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = RespiratoryCNN().to(device)
    stage2_model = DiseaseClassifier().to(device)
    processor = AudioPreprocessor()
    
    # Correct base path for weights (same directory as this file)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Load Stage 1 Weights
    weights_path = os.path.join(base_dir, "model_weights.pth")
    if os.path.exists(weights_path):
        print(f"Loading Stage 1 weights from {weights_path}")
        model.load_state_dict(torch.load(weights_path, map_location=device))
    else:
        # Fallback to current working directory
        weights_path = "backend/model_weights.pth"
        if os.path.exists(weights_path):
             print(f"Loading Stage 1 weights from CWD {weights_path}")
             model.load_state_dict(torch.load(weights_path, map_location=device))
        else:
            print("Warning: Stage 1 weights not found. Using random initialization.")
    
    # Load Stage 2 Weights
    stage2_weights_path = os.path.join(base_dir, "model_stage2_weights.pth")
    if os.path.exists(stage2_weights_path):
        print(f"Loading Stage 2 weights from {stage2_weights_path}")
        stage2_model.load_state_dict(torch.load(stage2_weights_path, map_location=device))
    else:
        # Fallback to current working directory
        stage2_weights_path = "backend/model_stage2_weights.pth"
        if os.path.exists(stage2_weights_path):
             print(f"Loading Stage 2 weights from CWD {stage2_weights_path}")
             stage2_model.load_state_dict(torch.load(stage2_weights_path, map_location=device))
        else:
            print("Warning: Stage 2 weights not found. Disease prediction will be random.")

    model.eval()
    stage2_model.eval()
    yield

    # Cleanup if needed

app = FastAPI(
    title="Resp-AI API",
    description="Acoustic Respiratory Risk Assessment System",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Resp-AI Inference Engine is Online", "system": "ready"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.websocket("/api/ws-analyze")
async def websocket_analyze(websocket: WebSocket):
    await websocket.accept()
    audio_buffer = io.BytesIO()
    print("WebSocket client connected.")
    
    try:
        while True:
            # We use receive() to handle both bytes and text
            message = await websocket.receive()
            
            if "bytes" in message:
                audio_buffer.write(message["bytes"])
            
            elif "text" in message:
                if message["text"] == "FINISH":
                    # Time to analyze!
                    print(f"Received FINISH command. Buffer size: {audio_buffer.tell()} bytes.")
                    
                    if audio_buffer.tell() < 1000:
                        await websocket.send_json({"error": "Audio too short."})
                        continue

                    # Process
                    try:
                        # 1. Get raw bytes
                        raw_bytes = audio_buffer.getvalue()
                        
                        # 2. Convert raw PCM 16-bit bytes to numpy array
                        # Flutter sends 16-bit Little Endian PCM
                        audio_np = np.frombuffer(raw_bytes, dtype=np.int16).astype(np.float32)
                        
                        # 3. Normalize to [-1.0, 1.0] as expected by librosa/AI models
                        audio_np = audio_np / 32768.0
                        
                        # 4. Run inference pipeline
                        features = processor.extract_features(audio_np, is_path=False)
                        features = features.unsqueeze(0).to(device)
                        
                        with torch.no_grad():
                            risk_prediction, embeddings = model(features)
                            probability = risk_prediction.item()
                            disease_probs = stage2_model.predict_probs(embeddings)
                            top_prob, top_class_idx = torch.max(disease_probs, 1)
                            
                            predicted_disease = stage2_model.classes[top_class_idx.item()]
                            disease_confidence = top_prob.item()

                        risk_score = round(probability * 10, 1)
                        classification = "Normal"
                        if risk_score >= 7:
                            classification = "High Risk"
                        elif risk_score >= 4:
                            classification = "Mild Risk"

                        # Gatekeeper Logic: Override disease prediction if risk is low
                        if risk_score < 3.5:
                            predicted_disease = "No abnormality detected"
                            disease_confidence_str = "N/A"
                            disclaimer = "No significant abnormal patterns detected in the respiratory audio."
                        else:
                            disease_confidence_str = f"{disease_confidence*100:.1f}%"
                            disclaimer = "Probabilistic association only. Not a clinical diagnosis."

                        result = {
                            "status": "success",
                            "filename": "Live Stream",
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
                                "medical_disclaimer": "This system provides probabilistic risk assessment and pattern association. It is not a diagnostic device."
                            }
                        }
                        
                        await websocket.send_json(result)
                        print(f"Analysis sent successfully: {classification}")
                        
                        # Reset buffer for next potential use in same session or just wait for close
                        audio_buffer = io.BytesIO()

                    except Exception as e:
                        print(f"Analysis error: {e}")
                        await websocket.send_json({"error": str(e)})
                
                elif message["text"] == "CLEAR":
                    audio_buffer = io.BytesIO()
                    print("Buffer cleared.")

    except WebSocketDisconnect:
        print("WebSocket Disconnected.")
    except Exception as e:
        print(f"WebSocket Error: {e}")

@app.post("/api/analyze")
async def analyze_audio(file: UploadFile = File(...)):
    global model, stage2_model, processor, device
    
    # Validation
    filename = file.filename or "audio.wav"
    if not filename.endswith(('.wav', '.mp3')):
        raise HTTPException(status_code=400, detail="Invalid file format. Please upload a WAV or MP3 file.")
    
    temp_path = f"temp_{filename}"
    try:
        # Save temp file
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Process
        if processor is None or model is None or stage2_model is None or device is None:
             raise HTTPException(status_code=500, detail="Models are not loaded. Check the server logs.")

        # extract_features returns (1, n_mfcc, time_steps) i.e. (C, H, W)
        features = processor.extract_features(temp_path)
        
        # Add Batch Dimension -> (1, 1, n_mfcc, time_steps)
        features = features.unsqueeze(0)
        
        features = features.to(device)
        
        # Inference
        with torch.no_grad():
            # Stage 1: Symptom Detection
            risk_prediction, embeddings = model(features)
            probability = risk_prediction.item()
            
            # Stage 2: Disease Association
            disease_probs = stage2_model.predict_probs(embeddings)
            top_prob, top_class_idx = torch.max(disease_probs, 1)
            
            predicted_disease = stage2_model.classes[top_class_idx.item()]
            disease_confidence = top_prob.item()
            
        # Cleanup
        if os.path.exists(temp_path):
            os.remove(temp_path)
        
        # Risk Mapping
        # Probability 0.0 - 1.0 -> Risk 0 - 10
        risk_score = round(probability * 10, 1)
        
        classification = "Normal"
        if risk_score >= 7:
            classification = "High Risk"
        elif risk_score >= 4:
            classification = "Mild Risk"
            
        # Gatekeeper Logic: Override disease prediction if risk is low
        if risk_score < 3.5:
            predicted_disease = "No abnormality detected"
            disease_confidence_str = "N/A"
            disclaimer = "No significant abnormal patterns detected in the respiratory audio."
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
                "medical_disclaimer": "This system provides probabilistic risk assessment and pattern association. It is not a diagnostic device."
            }
        }
        
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

