# FieldAI — Offline Agricultural Intelligence Platform

> **Intelligence for the field. Even without internet.**

FieldAI is an offline-first mobile application built with **Flutter**, designed specifically for agricultural extension workers, smallholder farmers, and agronomists operating in remote or low-connectivity regions.

---

## Key Capabilities

1. **Offline-First Edge AI Diagnostics**:
   - On-device foliar disease diagnosis for Solanaceous crops (Tomato, Potato, Pepper) without requiring cloud connectivity.
   - Chromatic lesion geometry extraction and multi-class pathogen identification (*Early Blight*, *Late Blight*, *Septoria Leaf Spot*, *Leaf Mold*, *Healthy Foliage*).
   - Instant Integrated Pest Management (IPM) treatment recommendations.

2. **Multilingual Localization (4 Languages)**:
   - 🇬🇧 **English (`en`)**
   - 🇪🇹 **Amharic (`am` / አማርኛ)**
   - 🇪🇹 **Tigrinya (`ti` / ትግርኛ)**
   - 🇪🇹 **Afaan Oromoo (`om` / Oromiffa)**
   - Dynamic in-app language switcher with persistent local storage.

3. **Light & Dark Mode**:
   - Polished agricultural color system tailored for outdoor high-glare sunlight (Light Mode) and low-light fieldwork (Dark Mode).

4. **Local SQLite Persistence & Sync**:
   - On-device SQLite database storing field diagnoses, GPS coordinates, weather microclimates, and symptom notes.
   - Resilient background synchronization queue to sync records when internet connectivity is restored.

5. **Actionable Treatment Plans & Dosage Calculator**:
   - Multi-phase structured recovery schedules (*Phase 1: Emergency Sanitation*, *Phase 2: Bio/Chemical Rescue*, *Phase 3: Soil Spore Barriers*, *Phase 4: Plant Nutrition & Rotation*).
   - Dynamic field area dosage calculator (computes water liters, fungicide grams, neem oil mL, and 16L knapsack sprayer tanks).
   - Local SQLite milestone tracker and SMS/clipboard plan exporter for field extension.

6. **Offline Agronomy Field Guide & Encyclopedia**:
   - Comprehensive offline catalog of Solanaceae, Cereals, Legumes, and Cash Crops.
   - In-depth plant pathology, conducive microclimates, organic remedies, and IPM protocols.

7. **Cloud Sync & Queue Manager**:
   - Complete queue inspector with background batch upload triggers and server latency diagnostics.

8. **Offline RAG Agronomy Assistant**:
   - Evidence-based advisory engine grounded in FAO and CABI Plantwise agricultural extension manuals.

9. **Outbreak Risk & Regional Analytics**:
   - Regional spore proliferation vulnerability meter and pathogen prevalence breakdown with JSON data export.

---

## 🏗️ Architecture Overview

```
lib/
├── core/
│   ├── ai/               # Edge inference engine & chromatic lesion analysis
│   ├── database/         # SQLite on-device database & sync tracking
│   ├── localization/     # LanguageService & AppStrings (en, am, ti, om)
│   ├── network/          # Dio HTTP client for cloud sync & RAG chat
│   ├── sync/             # SyncService background synchronization queue
│   ├── theme/            # ThemeService & high-contrast Light/Dark palettes
│   └── treatment/        # TreatmentPlanService & dosage calculation engine
├── features/
│   ├── ai_assistant/     # Agronomic RAG chat interface
│   ├── analytics/        # Spore vulnerability meter & JSON exporter
│   ├── auth/             # Sign-in & offline guest access
│   ├── dashboard/        # Operational overview, quick tools & system controls
│   ├── disease_analysis/ # Leaf scanner & AI explanation protocols
│   ├── field_guide/      # Offline Agronomy Encyclopedia & Crop Pathologies
│   ├── history/          # Local records list, search & filter tabs
│   ├── observations/     # GPS field observation logger
│   ├── sync_manager/     # Cloud sync inspector & server latency tester
│   └── treatment/        # Treatment plans, phase tracker & dosage calculator
└── main.dart             # App entry point & reactive state binding
```

---

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK (>= 3.0.0)
- Python 3.9+ (optional for backend and model training)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Automated Tests
```bash
flutter test
```
*(All unit & widget test suites validate language switching, theme toggling, treatment dosage calculation, and dashboard rendering).*

### 4. Run Flutter Application
```bash
flutter run
```

---

## 📡 Backend & Machine Learning (Optional)

### FastAPI Cloud Sync & RAG Server
```bash
python3 backend/server.py
```
- API Docs: `http://127.0.0.1:8000/docs`
- Endpoints: `/predictions`, `/chat` (RAG), `/sync`, `/analytics/summary`

### Model Training Pipeline (PyTorch MobileNetV3 → TFLite INT8)
```bash
python3 ml/train_fieldai_model.py --data_dir /path/to/dataset --epochs 15 --export_tflite
```

---

## 🧪 Verification & Quality

- **Flutter Analyze**: `0 issues found`
- **Flutter Test**: `100% pass rate (9/9 test suites)`
