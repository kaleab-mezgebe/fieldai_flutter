#!/usr/bin/env python3
"""
FieldAI - High-Performance FastAPI Backend Server
=================================================
Endpoints:
- POST /api/v1/auth/login
- POST /api/v1/auth/register
- POST /api/v1/predictions
- POST /api/v1/chat (RAG Agronomic Advisor)
- POST /api/v1/sync (Batch Field Sync)
- GET  /api/v1/analytics/summary
"""

import uvicorn
from fastapi import FastAPI, File, UploadFile, Form, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import time
import random

app = FastAPI(
    title="FieldAI API Server",
    description="Offline-First Agricultural Intelligence API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Data Models ---

class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    email: str
    password: str
    full_name: str

class ChatRequest(BaseModel):
    message: str
    context_crop: Optional[str] = "Tomato"
    context_prediction: Optional[str] = None

class SyncBatchRequest(BaseModel):
    batch_id: str
    observations: List[dict]

# --- Endpoints ---

@app.get("/")
def root():
    return {
        "service": "FieldAI Cloud Backend",
        "status": "online",
        "version": "1.0.0",
        "models": ["MobileNetV3-PlantVillage-v1", "Agronomy-RAG-v2"]
    }

@app.post("/api/v1/auth/login")
def login(req: LoginRequest):
    return {
        "access_token": "fieldai_jwt_token_sample",
        "token_type": "bearer",
        "full_name": "Field Worker #104",
        "email": req.email
    }

@app.post("/api/v1/auth/register")
def register(req: RegisterRequest):
    return {
        "access_token": f"fieldai_jwt_reg_{int(time.time())}",
        "token_type": "bearer",
        "full_name": req.full_name,
        "email": req.email
    }

@app.post("/api/v1/predictions")
async def predict_crop_disease(
    file: UploadFile = File(...),
    crop: str = Form("Tomato"),
    latitude: Optional[str] = Form(None),
    longitude: Optional[str] = Form(None),
):
    contents = await file.read()
    file_size_kb = len(contents) / 1024.0

    # Simulated AI model prediction logic
    diagnoses = [
        {
            "crop": crop,
            "condition_class": "Tomato___Early_blight",
            "condition_name": "Early Blight (Alternaria solani)",
            "confidence": 89.4,
            "severity": "Moderate",
            "status": "Action Recommended",
            "explanation": "Concentric target-board ring lesions with yellow chlorotic halos on older lower foliage.",
            "pathogen_info": "Caused by fungal pathogen Alternaria solani. Spores overwinter in crop residue and spread via wind and splashing water.",
            "conducive_factors": "Warm temperatures (24-29°C) combined with frequent rain or overhead irrigation.",
            "recommended_actions": [
                "Prune and destroy infected lower foliage immediately.",
                "Cease overhead sprinkler watering; switch to drip ground lines.",
                "Apply Copper Hydroxide (2.5g/L) or Chlorothalonil protectant spray.",
                "Apply organic straw mulch around plant base to prevent soil spore splash."
            ],
            "safety_disclaimer": "Informational AI diagnosis supporting field management decisions."
        },
        {
            "crop": crop,
            "condition_class": "Tomato___Late_blight",
            "condition_name": "Late Blight (Phytophthora infestans)",
            "confidence": 93.6,
            "severity": "Critical / Emergency",
            "status": "Critical Outbreak Risk",
            "explanation": "Rapidly expanding water-soaked dark brown necrotic blotches with pale green margins and white sporulation under humid canopy.",
            "pathogen_info": "Oomycete pathogen Phytophthora infestans. Capable of destroying entire crop fields within 7 to 10 days under favorable conditions.",
            "conducive_factors": "Cool, humid weather (15-22°C) with relative humidity above 85% and prolonged leaf wetness.",
            "recommended_actions": [
                "Rogue, bag, and bury heavily infected plants away from field immediately.",
                "Ensure strict air circulation and avoid working in wet canopy.",
                "Apply systemic fungicide (Metalaxyl-M + Mancozeb or Dimethomorph).",
                "Notify neighboring farmers of high regional late blight spore pressure."
            ],
            "safety_disclaimer": "Informational AI diagnosis supporting field management decisions."
        }
    ]

    selected = diagnoses[0]
    return {
        "id": f"pred_{int(time.time()*1000)}",
        **selected,
        "processed_file_size_kb": round(file_size_kb, 2),
        "device_geo": {"latitude": latitude, "longitude": longitude}
    }

@app.post("/api/v1/chat")
def agronomy_chat(req: ChatRequest):
    msg = req.message.lower()

    if "blight" in msg:
        answer = (
            "Early Blight (Alternaria solani) requires immediate pruning of lower infected leaves. "
            "Cease overhead watering to prevent spore splash and apply Copper Hydroxide (2.5g/L) or Chlorothalonil. "
            "Ensure 60cm row spacing to promote air circulation."
        )
        sources = [
            {"title": "FAO Agricultural Extension Manual #42", "section": "Tomato Solanaceae Pathology"},
            {"title": "CABI Plantwise Data Sheet", "section": "Alternaria solani Control"}
        ]
    elif "pest" in msg or "aphid" in msg or "whitefl" in msg:
        answer = (
            "For organic pest control against aphids and whiteflies, formulate a 0.5% neem oil solution (5ml neem oil + 2ml liquid soap / 1L water). "
            "Deploy yellow sticky traps at canopy level and introduce beneficial predatory ladybird beetles."
        )
        sources = [
            {"title": "CABI IPM Field Handbook", "section": "Vector Management in Vegetables"}
        ]
    else:
        answer = (
            f"Based on agricultural extension guidelines for {req.context_crop}: "
            "Maintain soil moisture at field capacity, inspect lower foliage weekly for early lesion spotting, "
            "and ensure balanced N-P-K fertigation to support systemic plant immunity."
        )
        sources = [
            {"title": "FAO Extension Technical Bulletin", "section": "General Field Scouting Protocols"}
        ]

    return {
        "answer": answer,
        "sources": sources,
        "timestamp": time.time()
    }

@app.post("/api/v1/sync")
def sync_batch(req: SyncBatchRequest):
    synced_ids = [obs.get("client_id") for obs in req.observations if obs.get("client_id")]
    return {
        "status": "success",
        "batch_id": req.batch_id,
        "received_count": len(req.observations),
        "synced_ids": synced_ids,
        "message": f"Successfully registered {len(synced_ids)} observation(s) into regional central registry."
    }

@app.get("/api/v1/analytics/summary")
def get_analytics():
    return {
        "risk_score": 0.72,
        "risk_level": "High",
        "disease_distribution": {
            "Early Blight": 15,
            "Late Blight": 7,
            "Septoria Leaf Spot": 9,
            "Leaf Mold": 4,
            "Healthy": 20
        },
        "total_regional_samples": 55,
        "updated_at": time.time()
    }

if __name__ == "__main__":
    print("🌾 Starting FieldAI Backend API on http://0.0.0.0:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
