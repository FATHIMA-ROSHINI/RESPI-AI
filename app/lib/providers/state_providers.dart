import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordingState {
  final bool isRecording;
  final bool isAnalyzing;
  final String? statusMessage;
  final String? recordedFilePath;
  final int recordingDuration;
  final double noiseLevel;
  final String? selectedPatientId;

  RecordingState({
    this.isRecording = false,
    this.isAnalyzing = false,
    this.statusMessage,
    this.recordedFilePath,
    this.recordingDuration = 0,
    this.noiseLevel = 0.0,
    this.selectedPatientId,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isAnalyzing,
    String? statusMessage,
    String? recordedFilePath,
    int? recordingDuration,
    double? noiseLevel,
    String? selectedPatientId,
    bool clearStatus = false,
    bool clearFilePath = false,
    bool clearPatient = false,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      recordedFilePath: clearFilePath ? null : (recordedFilePath ?? this.recordedFilePath),
      recordingDuration: recordingDuration ?? this.recordingDuration,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      selectedPatientId: clearPatient ? null : (selectedPatientId ?? this.selectedPatientId),
    );
  }
}

class RecordingNotifier extends Notifier<RecordingState> {
  @override
  RecordingState build() => RecordingState();

  void setRecording(bool isRecording) {
    state = state.copyWith(isRecording: isRecording);
  }

  void setAnalyzing(bool isAnalyzing) {
    state = state.copyWith(isAnalyzing: isAnalyzing);
  }

  void setStatus(String? message) {
    if (message == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(statusMessage: message);
    }
  }

  void setRecordedFile(String? path) {
    if (path == null) {
      state = state.copyWith(clearFilePath: true);
    } else {
      state = state.copyWith(recordedFilePath: path);
    }
  }

  void setDuration(int duration) {
    state = state.copyWith(recordingDuration: duration);
  }

  void setNoiseLevel(double level) {
    state = state.copyWith(noiseLevel: level);
  }

  void setSelectedPatient(String? patientId) {
    if (patientId == null) {
      state = state.copyWith(clearPatient: true);
    } else {
      state = state.copyWith(selectedPatientId: patientId);
    }
  }

  void reset() {
    state = RecordingState();
  }
}

final recordingProvider = NotifierProvider<RecordingNotifier, RecordingState>(
  () {
    return RecordingNotifier();
  },
);
