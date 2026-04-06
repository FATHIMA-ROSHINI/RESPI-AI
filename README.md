# RESP-AI 🫁

**AI-Powered Acoustic Respiratory Risk Assessment System**

---

## Overview

RESP-AI is an end-to-end artificial intelligence system designed to **analyze respiratory audio signals** (lung sounds) and estimate respiratory health risk in real-time. The system utilizes a high-performance Python backend with deep learning models and a responsive Flutter frontend to provide immediate feedback on respiratory health.

> ⚠️ **Disclaimer**: RESP-AI is a **research prototype** for screening purposes only. It is **NOT** a medical device and should not be used for clinical diagnosis.

---

## Key Features

- Real-time Audio Streaming via WebSockets
- Two-Stage AI Cascade (CNN + MLP)
- Risk Scoring (0-10)
- Patient Database with SQLite
- PDF Report Generation
- Cross-Platform (Android, iOS, Windows, macOS, Linux)

---

## Tech Stack

- **Backend**: Python, FastAPI, PyTorch, Librosa
- **Frontend**: Flutter, Riverpod, SQLite

---

## Quick Start

### Backend
```bash
cd backend
pip install -r requirements.txt
python main.py
```

### Frontend
```bash
cd app
flutter pub get
flutter run -d windows
```

---

## License

Copyright © 2026 Fathima Roshini Siyad