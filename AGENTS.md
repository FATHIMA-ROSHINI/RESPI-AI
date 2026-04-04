# AGENTS.md - Resp-AI Codebase Guide

Resp-AI is an acoustic respiratory risk assessment system with:
- **Backend**: Python/FastAPI with PyTorch deep learning models
- **Flutter App**: Cross-platform mobile/desktop app (`app/`)
- **Web Frontend**: Next.js/React web app (`frontend/`)

## Build/Lint/Test Commands

### Flutter App (`app/`)
```bash
cd app && flutter pub get           # Install dependencies
flutter run -d windows              # Run on Windows
flutter run -d macos                # Run on macOS
flutter run -d chrome               # Run in browser
flutter analyze                     # Lint
flutter analyze --no-fatal-infos    # Lint (ignore info-level)
flutter test                        # Run all tests
flutter test test/path/file_test.dart              # Single test file
flutter test --name "testName" test/path/file.dart # Single test
flutter build windows               # Build release
```

### Python Backend (`backend/`)
```bash
pip install -r requirements.txt     # Install dependencies
python main.py                      # Start server (port 8000)
uvicorn main:app --reload --port 8000  # With hot reload
pytest backend/tests/               # Run all tests
pytest backend/tests/test_file.py -v              # Single file
pytest backend/tests/test_file.py::test_name -v   # Single test
```

### Next.js Frontend (`frontend/`)
```bash
cd frontend && npm install          # Install dependencies
npm run dev                         # Development server
npm run build                       # Production build
npm run lint                        # Lint
```

## Code Style Guidelines

### Flutter/Dart (`app/lib/`)

**Imports Order**: Dart SDK → Flutter SDK → External packages (alphabetical) → Internal imports (relative)

**Naming**:
- Classes: `PascalCase` (`RecordingState`, `HomeScreen`)
- Variables/Functions: `camelCase` (`isRecording`, `toggleRecording`)
- Files: `snake_case` (`home_screen.dart`)
- Providers: `camelCaseProvider` (`recordingProvider`)

**State Management (Riverpod)**:
```dart
class RecordingState {
  final bool isRecording;
  RecordingState({this.isRecording = false});
  RecordingState copyWith({bool? isRecording}) {
    return RecordingState(isRecording: isRecording ?? this.isRecording);
  }
}

class RecordingNotifier extends Notifier<RecordingState> {
  @override
  RecordingState build() => RecordingState();
  void setRecording(bool value) {
    state = state.copyWith(isRecording: value);
  }
}

final recordingProvider = NotifierProvider<RecordingNotifier, RecordingState>(
  () => RecordingNotifier(),
);
```

**Widgets**: Use `const` constructors. Private helpers prefixed with `_` (`_buildHeader()`).

**Colors**: Use `AppTheme` constants: `medicalBlue`, `successGreen`, `warningAmber`, `dangerRed`, `darkBg`.

### Python Backend (`backend/`)

**Imports Order**: Standard library → Third-party → Local imports

**Naming**:
- Classes: `PascalCase` (`RespiratoryCNN`)
- Functions/Variables: `snake_case` (`extract_features`)
- Constants: `UPPER_SNAKE_CASE` (`SAMPLE_RATE`)

**Type Hints**: Use for function signatures (`def process(data: np.ndarray) -> torch.Tensor:`)

### TypeScript/React (`frontend/src/`)
Use functional components with interfaces for props. No semicolons preferred.

## Architecture Notes

**AI Model Pipeline (DO NOT MODIFY STAGE 1)**:
- Stage 1 (`model.py`): RespiratoryCNN - FROZEN, validated, do not retrain
- Stage 2 (`model_stage2.py`): DiseaseClassifier - Can be retrained
- Gatekeeper Logic: Risk score < 3.5 → "No abnormality detected"

**API Endpoints**:
- `GET /` - Health check
- `POST /api/analyze` - File upload analysis
- `WebSocket /api/ws-analyze` - Real-time streaming

**Flutter Structure**:
```
lib/
├── main.dart           # App entry
├── models/             # Data models
├── providers/          # Riverpod state
├── screens/            # UI screens
├── services/           # API, audio services
├── theme/              # App theming
└── widgets/            # Reusable widgets
```

## Important Files

| File | Purpose |
|------|---------|
| `backend/main.py` | FastAPI server entry |
| `backend/model.py` | Stage 1 CNN (FROZEN) |
| `backend/model_stage2.py` | Stage 2 classifier |
| `backend/preprocessing.py` | Audio feature extraction |
| `app/lib/main.dart` | Flutter app entry |
| `app/lib/screens/main_shell.dart` | Navigation shell |

## Error Handling

Flutter: Wrap async calls in try/catch, show user-friendly messages.
Python: Use `HTTPException` for API errors.

## Medical Disclaimer

All outputs must include: "NOT A MEDICAL DEVICE - For screening purposes only."
