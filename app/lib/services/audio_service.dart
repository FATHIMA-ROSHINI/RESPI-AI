import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final _record = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final StreamController<double> _noiseLevelController = StreamController<double>.broadcast();
  
  Stream<double> get noiseLevelStream => _noiseLevelController.stream;
  double _currentNoiseLevel = 0.0;
  double get currentNoiseLevel => _currentNoiseLevel;

  Future<String> getRecordingsDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'recordings');
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return path;
  }

  Future<void> _cleanupRecordings() async {
    try {
      final path = await getRecordingsDirectory();
      final dir = Directory(path);
      if (await dir.exists()) {
        final files = dir.listSync();
        for (var file in files) {
          if (file is File && file.path.endsWith('.wav')) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint("Error cleaning up: $e");
    }
  }

  Future<bool> checkPermission() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return await _record.hasPermission();
    }
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    try {
      if (await checkPermission()) {
        await _cleanupRecordings();
        final dir = await getTemporaryDirectory();

        final path = p.join(dir.path, 'resp_ai_recording.wav');

        debugPrint("CRITICAL: Starting recording to: $path");

        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        );

        if (await _record.isRecording()) {
          await _record.stop();
        }

        await _record.start(config, path: path);
        _startAmplitudeMonitoring();
      } else {
        throw Exception("Microphone permission not granted");
      }
    } catch (e) {
      debugPrint("CRITICAL Error starting recording: $e");
      rethrow;
    }
  }

  Future<Stream<List<int>>> startStreaming() async {
    if (await checkPermission()) {
      if (await _record.isRecording()) {
        await _record.stop();
      }

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      _startAmplitudeMonitoring();
      return await _record.startStream(config);
    } else {
      throw Exception("Microphone permission not granted");
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _record.onAmplitudeChanged(const Duration(milliseconds: 100)).listen(
      (amplitude) {
        double normalizedLevel;
        if (amplitude.current.isNaN || amplitude.current.isInfinite) {
          normalizedLevel = 0.0;
        } else {
          final dbNormalized = (amplitude.current + 60) / 60;
          normalizedLevel = dbNormalized.clamp(0.0, 1.0);
        }
        _currentNoiseLevel = normalizedLevel;
        _noiseLevelController.add(normalizedLevel);
      },
      onError: (e) {
        debugPrint("Amplitude monitoring error: $e");
        _currentNoiseLevel = 0.0;
        _noiseLevelController.add(0.0);
      },
    );
  }

  void _stopAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _currentNoiseLevel = 0.0;
    _noiseLevelController.add(0.0);
  }

  Future<String?> stopRecording() async {
    _stopAmplitudeMonitoring();
    try {
      final path = await _record.stop();
      debugPrint("CRITICAL: Recorder stopped. Raw path returned: $path");

      await Future.delayed(const Duration(milliseconds: 1000));

      String? cleanPath = path;
      if (cleanPath != null && cleanPath.startsWith('file://')) {
        cleanPath = Uri.parse(cleanPath).toFilePath();
      }

      if (cleanPath != null) {
        final file = File(cleanPath);
        if (await file.exists() && await file.length() > 0) {
          debugPrint("CRITICAL: Verified file at $cleanPath");
          return cleanPath;
        }
      }

      debugPrint("CRITICAL: Primary path failed. Searching fallback...");
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (var f in files) {
        if (f is File && f.path.endsWith('.wav')) {
          final size = await f.length();
          if (size > 0) {
            debugPrint("CRITICAL: Discovered fallback recording at ${f.path}");
            return f.path;
          }
        }
      }

      return cleanPath;
    } catch (e) {
      debugPrint("CRITICAL Error stopping recording: $e");
      return null;
    }
  }

  Future<bool> isRecording() async {
    return await _record.isRecording();
  }

  void dispose() {
    _stopAmplitudeMonitoring();
    _noiseLevelController.close();
    _record.dispose();
  }
}
