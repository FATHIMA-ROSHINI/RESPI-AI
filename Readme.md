# RESP-AI 🫁

**AI-Powered Acoustic Respiratory Risk Assessment System**

---

## Overview

RESP-AI is an end-to-end artificial intelligence system designed to **analyze respiratory audio signals** (lung sounds) and estimate respiratory health risk in real-time. The system utilizes a high-performance Python backend with deep learning models and a responsive Flutter frontend to provide immediate feedback on respiratory health.

The system identifies abnormal respiratory sound patterns (such as wheezes and crackles) and maps them to an interpretable **risk score (0-10)** and **disease association**, mimicking a clinical triage workflow.

> ⚠️ **Disclaimer**: RESP-AI is a **research prototype** for screening purposes only. It is **NOT** a medical device and should not be used for clinical diagnosis. Always consult with a qualified healthcare professional.

---

## Key Features

| Feature | Description |
|---------|-------------|
| 🎙️ **Real-time Audio Streaming** | Live microphone capture streamed directly to AI engine via WebSockets |
| 🧠 **Two-Stage AI Cascade** | Stage 1: Symptom detection (CNN) → Stage 2: Disease classification (MLP) |
| 📊 **Risk Scoring** | Visual 0-10 risk score with color-coded indicators |
| 👥 **Patient Database** | Full CRUD operations for patient records |
| 📈 **History Tracking** | SQLite-based analysis history with filtering |
| 📄 **PDF Reports** | Generate professional clinical reports |
| 📤 **Share Functionality** | Share results via text, email, or messaging apps |
| 📱 **Cross-Platform** | Android, iOS, Windows, macOS, Linux |

---

## Technology Stack

### Backend

| Technology | Purpose |
|------------|---------|
| **Python** | Core programming language |
| **FastAPI** | Web framework for REST API and WebSocket |
| **PyTorch** | Deep learning model inference |
| **Librosa** | Audio signal processing and feature extraction |
| **NumPy** | Numerical computing |

### Frontend (Flutter)

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Riverpod** | State management |
| **SQLite (sqflite)** | Local database for history and patients |
| **PDF** | PDF report generation |
| **Share Plus** | Native sharing functionality |

---

## System Architecture

```
┌─────────────┐     WebSocket      ┌─────────────┐
│   Mobile    │ ──────────────────▶│   Backend   │
│   / Desktop │                    │   (FastAPI) │
│    App     │◀───────────────────│             │
└─────────────┘                    └──────┬──────┘
                                           │
                                    ┌──────▼──────┐
                                    │ AI Pipeline │
                                    ├─────────────┤
                                    │ Stage 1:    │
                                    │ Respiratory │
                                    │ CNN         │
                                    ├─────────────┤
                                    │ Stage 2:    │
                                    │ Disease     │
                                    │ Classifier  │
                                    └─────────────┘
```

### Two-Stage AI Pipeline

1. **Stage 1: RespiratoryCNN**
   - Input: MFCC spectrograms (40 coefficients)
   - Output: Risk score (0-10), detected anomalies (crackles, wheezes)
   - Architecture: 3-layer CNN with MaxPooling and Dropout

2. **Stage 2: DiseaseClassifier**
   - Input: 512-dimensional feature embeddings from Stage 1
   - Output: Disease probability distribution
   - Classes: Normal, Asthma, COPD, Pneumonia, Other

3. **Gatekeeper Logic**
   - If risk score < 3.5 → "No abnormality detected"
   - Prevents misleading disease labels for healthy subjects

---

## Installation & Setup

### Prerequisites

- **Python 3.8+** with pip
- **Flutter SDK 3.x+**

---

### 1. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
pip install -r requirements.txt

# Start the backend server
python main.py
```

The backend will run at:
- **Local**: `http://127.0.0.1:8000`
- **Network**: `http://0.0.0.0:8000` (accessible from other devices)

---

### 2. Frontend Setup (Flutter)

```bash
# Navigate to app directory
cd app

# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d android

# Run in browser
flutter run -d chrome
```

---

### 3. Mobile Deployment (Android)

**Configure Backend IP:**

Edit `app/lib/services/api_service.dart` to set your computer's IP address:

```dart
static String get _baseUrl {
    return 'http://192.168.1.3:8000';  // Your computer's IP
}
```

**Build APK:**

```bash
cd app
flutter build apk --debug
```

The APK will be at: `app/build/app/outputs/flutter-apk/app-debug.apk`

---

## How to Use

### 1. Start the Backend

```bash
cd backend
python main.py
```

### 2. Launch the App

```bash
cd app
flutter run -d windows
```

### 3. Record Respiratory Audio

**Option A: Live Recording**
- Tap the microphone button
- Breathe normally into the microphone
- Recording duration: 5-30 seconds
- Tap stop to analyze

**Option B: Upload Audio File**
- Tap "Upload Existing Audio"
- Select a WAV/MP3 file
- Tap "Start AI Analysis"

### 4. View Results

The clinical report displays:
- **Risk Score**: 0-10 scale with color indicator
- **Classification**: Normal / Abnormal
- **Condition**: Associated respiratory condition
- **Confidence**: Model confidence percentage
- **Recommended Next Steps**: Based on risk level

### 5. Save & Share

- **Save to History**: Automatically saved after analysis
- **Export PDF**: Generate clinical report
- **Share**: Send results via text, email, or apps

### 6. View History

- Navigate to History tab
- View all past analyses
- Filter by date range (7 days, 30 days, All)
- Export individual reports
- View risk trend graph

---

## Project Structure

### Backend (`backend/`)

| File | Description |
|------|-------------|
| `main.py` | FastAPI server, API endpoints, WebSocket handler |
| `model.py` | Stage 1: RespiratoryCNN architecture |
| `model_stage2.py` | Stage 2: DiseaseClassifier MLP |
| `preprocessing.py` | Audio preprocessing (MFCC, filtering) |
| `train.py` | Training script for Stage 1 CNN |
| `train_stage2.py` | Training script for Stage 2 classifier |
| `dataset.py` | ICBHI dataset loader |
| `dataset_fraiwan.py` | Fraiwan dataset loader |

### Frontend (`app/lib/`)

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── analysis_result.dart      # AI result model
│   ├── history_record.dart       # History entry model
│   └── patient.dart              # Patient model
├── providers/
│   ├── history_provider.dart     # History state management
│   ├── patient_provider.dart     # Patient state management
│   ├── state_providers.dart      # Recording state
│   └── theme_provider.dart       # Theme switching
├── services/
│   ├── api_service.dart          # Backend communication
│   ├── audio_service.dart        # Microphone recording
│   ├── database_service.dart     # SQLite operations
│   └── report_service.dart       # PDF generation
├── screens/
│   ├── home_screen.dart          # Main recording screen
│   ├── result_screen.dart        # Analysis results
│   ├── history_screen.dart       # History list
│   ├── settings_screen.dart      # App settings
│   └── main_shell.dart           # Navigation shell
├── widgets/
│   ├── audio_widgets.dart        # Recording UI components
│   ├── medical_background.dart    # Background styling
│   ├── medical_gauge.dart        # Risk score gauge
│   ├── risk_trend_graph.dart     # History graph
│   └── info_widgets.dart         # Info cards
└── theme/
    └── app_theme.dart             # App theming
```

---

## API Endpoints

### REST Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Health check |
| `POST` | `/api/analyze` | File upload analysis |

### WebSocket Endpoint

| Endpoint | Description |
|----------|-------------|
| `/api/ws-analyze` | Real-time streaming analysis |

---

## Key Functions

### AudioService (`lib/services/audio_service.dart`)

```dart
// Check microphone permission
Future<bool> checkPermission()

// Start recording to file
Future<void> startRecording(String filePath)

// Start streaming to WebSocket
Stream<List<int>> startStreaming()

// Stop recording
Future<void> stopRecording()
```

### ApiService (`lib/services/api_service.dart`)

```dart
// Analyze audio file
static Future<AnalysisResult> analyzeAudio(String filePath)

// Connect to WebSocket for streaming
static WebSocketChannel connectStreaming()
```

### DatabaseService (`lib/services/database_service.dart`)

```dart
// Insert analysis record
Future<void> insertRecord(HistoryRecord record)

// Get all records
Future<List<HistoryRecord>> getAllRecords()

// Get records for date range
Future<List<HistoryRecord>> getRecordsForRange(DateTime start, DateTime end)

// Patient CRUD
Future<void> insertPatient(Patient patient)
Future<List<Patient>> getAllPatients()
Future<void> deletePatient(String id)
```

### ReportService (`lib/services/report_service.dart`)

```dart
// Generate and share PDF
static Future<void> generateAndShareReport(HistoryRecord record)

// Export PDF to file
static Future<String> exportReportToFile(HistoryRecord record)

// View saved PDF
static Future<void> viewPdfFromFile(String filePath)
```

---

## Configuration

### Backend IP Address

For mobile devices to connect to the backend, update the IP in:

**File:** `app/lib/services/api_service.dart`

```dart
static String get _baseUrl {
    return 'http://192.168.1.3:8000';  // Your computer's IP
}
```

To find your IP:
- Windows: `ipconfig` → IPv4 Address
- Look for addresses like `192.168.x.x`

### Firewall Settings

If mobile cannot connect, allow port 8000:

```bash
# Windows (Admin)
netsh advfirewall firewall add rule name="RespAI" dir=in action=allow protocol=tcp localport=8000
```

---

## Training Data

The AI models were trained on:

| Dataset | Description |
|---------|-------------|
| **ICBHI 2017** | Respiratory sound database |
| **COSWARA** | COVID-19 respiratory sound |
| **Fraiwan** | Lung sound dataset |

---

## Troubleshooting

### Common Issues

**1. Backend not connecting from mobile**
- Verify computer and mobile on same network
- Check firewall allows port 8000
- Update IP address in `api_service.dart`

**2. "Database not initialized" error**
- Ensure `DatabaseService.initialize()` is called in `main.dart`

**3. PDF export not working**
- Check storage permissions on mobile
- Ensure `share_plus` package is installed

**4. Microphone permission denied**
- Grant microphone permission in device settings

### Network Connection Modes

| Mode | Setup | IP Address |
|------|-------|------------|
| **Windows Desktop** | Run locally | `127.0.0.1:8000` |
| **Android Emulator** | Use `10.0.2.2` | `10.0.2.2:8000` |
| **Physical Device (WiFi)** | Same network | `192.168.x.x:8000` |
| **Physical Device (USB)** | Use `adb reverse` | `127.0.0.1:8000` |

---

## Ethical Considerations

1. **Not for Clinical Use**: RESP-AI is a research prototype for educational and screening purposes only.

2. **Privacy**: Audio is processed in-memory and not stored on the server (unless explicitly saved by user).

3. **Transparency**: All outputs include disclaimers advising consultation with healthcare professionals.

4. **Accuracy**: Model accuracy depends on training data quality and may vary across populations.

---

## License

Copyright © 2026 RESP-AI Project Team

This project is for research and educational purposes. Not intended for clinical diagnosis.

---

## Credits

- **ICBHI 2017 Challenge** - Respiratory sound dataset
- **COSWARA Project** - COVID-19 respiratory sounds
- **Fraiwan Dataset** - Lung sound recordings
- **Flutter** - Cross-platform framework
- **FastAPI** - Python web framework

---

*Last updated: March 2026*
