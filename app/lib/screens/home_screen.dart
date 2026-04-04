import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../providers/state_providers.dart';
import '../models/analysis_result.dart';
import '../widgets/medical_background.dart';
import '../widgets/audio_widgets.dart';
import '../widgets/info_widgets.dart';
import 'result_screen.dart';

final audioServiceProvider = Provider((ref) => AudioService());

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _audioSubscription;
  StreamSubscription? _noiseLevelSubscription;
  final bool _showHealthTip = true;

  @override
  void dispose() {
    _timer?.cancel();
    _wsSubscription?.cancel();
    _audioSubscription?.cancel();
    _noiseLevelSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    ref.read(recordingProvider.notifier).setDuration(0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = ref.read(recordingProvider);
      ref.read(recordingProvider.notifier).setDuration(currentState.recordingDuration + 1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).floor().toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3'],
    );

    if (result != null && result.files.single.path != null) {
      ref.read(recordingProvider.notifier).setRecordedFile(result.files.single.path);
      ref.read(recordingProvider.notifier).setStatus('File selected: ${result.files.single.name}');
    }
  }

  void _startNoiseMonitoring() {
    final audioService = ref.read(audioServiceProvider);
    _noiseLevelSubscription?.cancel();
    _noiseLevelSubscription = audioService.noiseLevelStream.listen((level) {
      ref.read(recordingProvider.notifier).setNoiseLevel(level);
    });
  }

  void _stopNoiseMonitoring() {
    _noiseLevelSubscription?.cancel();
    ref.read(recordingProvider.notifier).setNoiseLevel(0.0);
  }

  void _toggleRecording() async {
    final audioService = ref.read(audioServiceProvider);
    final recordingState = ref.read(recordingProvider);
    final notifier = ref.read(recordingProvider.notifier);

    if (recordingState.isRecording) {
      _stopTimer();
      _stopNoiseMonitoring();
      notifier.setRecording(false);
      notifier.setAnalyzing(true);
      notifier.setStatus('Streaming to AI engine...');

      _wsChannel?.sink.add('FINISH');
      await _audioSubscription?.cancel();
      await audioService.stopRecording();
    } else {
      try {
        final hasPermission = await audioService.checkPermission();
        if (hasPermission) {
          notifier.setStatus(null);
          _wsChannel = await ApiService.connectStreaming();

          _wsSubscription = _wsChannel!.stream.listen(
            (message) {
              final data = jsonDecode(message);
              if (data['status'] == 'success') {
                final result = AnalysisResult.fromJson(data);
                _wsChannel?.sink.close();

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(result: result),
                    ),
                  );
                  notifier.setStatus(null);
                  notifier.setAnalyzing(false);
                }
              } else if (data['error'] != null) {
                notifier.setStatus('Error: ${data['error']}');
                notifier.setAnalyzing(false);
                _wsChannel?.sink.close();
              }
            },
            onError: (e) {
              notifier.setStatus('Stream error: $e');
              notifier.setAnalyzing(false);
            },
            onDone: () {
              debugPrint("WebSocket Stream Closed");
            },
          );

          final audioStream = await audioService.startStreaming();
          _audioSubscription = audioStream.listen((chunk) {
            _wsChannel?.sink.add(chunk);
          });

          _startNoiseMonitoring();
          notifier.setRecording(true);
          notifier.setStatus('Streaming Live to AI... Breath deeply');
          _startTimer();
        } else {
          notifier.setStatus('Microphone permission denied');
        }
      } catch (e) {
        notifier.setStatus('Connection error: ${e.toString()}');
        notifier.setAnalyzing(false);
      }
    }
  }

  Future<void> _runAnalysis(String path) async {
    final notifier = ref.read(recordingProvider.notifier);

    notifier.setAnalyzing(true);
    notifier.setStatus('Finalizing recording disk data...');

    try {
      String cleanPath = path;
      try {
        if (cleanPath.startsWith('file://')) {
          cleanPath = Uri.parse(cleanPath).toFilePath();
        }
      } catch (e) {
        debugPrint("URI Parse error: $e");
      }

      final targetFile = File(cleanPath);
      debugPrint("Checking file at: $cleanPath");

      int retries = 25;
      while (retries > 0) {
        if (await targetFile.exists()) {
          if (await targetFile.length() > 0) break;
        }
        debugPrint("File not ready, retrying ($retries)...");
        await Future.delayed(const Duration(milliseconds: 200));
        retries--;
      }

      if (!await targetFile.exists() || await targetFile.length() == 0) {
        throw Exception(
          "Recording file is missing or empty. This is usually due to OS-level disk sync latency. Try recording again.",
        );
      }

      notifier.setStatus('Analyzing acoustic signature...');
      final result = await ApiService.analyzeAudio(cleanPath);

      if (mounted && ref.read(recordingProvider).recordedFilePath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResultScreen(result: result)),
        );
        notifier.setStatus(null);
      }
    } catch (e) {
      if (mounted && ref.read(recordingProvider).recordedFilePath != null) {
        notifier.setStatus('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        notifier.setAnalyzing(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'RESP-AI',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: MedicalBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutBack,
                    child: _buildMainActionArea(recordingState),
                  ),
                  const SizedBox(height: 32),
                  _buildStatusCard(recordingState),
                  if (_showHealthTip && !recordingState.isRecording) ...[
                    const SizedBox(height: 40),
                    _buildHealthTipSection(),
                  ],
                  const SizedBox(height: 48),
                  _buildFooterInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.shieldAlert, color: Colors.amber, size: 12),
              SizedBox(width: 8),
              Text(
                'RESEARCH PROTOTYPE - NOT A MEDICAL DEVICE',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(LucideIcons.stethoscope, color: Colors.white, size: 32),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        const Text(
          'AI-Based Respiratory Risk Assessment',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
        const SizedBox(height: 10),
        const Text(
          'Acoustic signal processing for lung health screening',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildMainActionArea(RecordingState state) {
    return Column(
      key: ValueKey('${state.recordedFilePath != null}-${state.isRecording}'),
      children: [
        if (state.recordedFilePath == null || state.isRecording)
          _buildMicrophoneButton(state)
        else
          _buildFilePreview(state),
        const SizedBox(height: 24),
        if (!state.isRecording && !state.isAnalyzing && state.recordedFilePath == null)
          TextButton.icon(
            onPressed: () {
              ref.read(recordingProvider.notifier).setStatus(null);
              _pickFile();
            },
            icon: const Icon(LucideIcons.uploadCloud, size: 18),
            label: const Text(
              'Upload Existing Audio',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.4),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(),
      ],
    );
  }

  Widget _buildMicrophoneButton(RecordingState state) {
    final bool canInteract = !state.isAnalyzing;
    return GestureDetector(
      onTap: canInteract ? _toggleRecording : null,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (state.isRecording)
                ...[1, 2].map(
                  (i) => Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(2.0, 2.0),
                        duration: (i * 1.2).seconds,
                        curve: Curves.easeOut,
                      )
                      .fadeOut(),
                ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: state.isRecording
                        ? [const Color(0xFFEF4444), const Color(0xFF991B1B)]
                        : [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (state.isRecording ? Colors.red : const Color(0xFF2563EB))
                          .withValues(alpha: 0.35),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: Icon(
                  state.isRecording ? LucideIcons.square : LucideIcons.mic,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              if (state.isRecording)
                Positioned(
                  bottom: -16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF991B1B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      _formatDuration(state.recordingDuration),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ).animate().scale(curve: Curves.easeOutBack).fadeIn(),
            ],
          ),
          if (state.isRecording) ...[
            const SizedBox(height: 36),
            WaveformVisualizer(
              isActive: state.isRecording,
              color: Colors.redAccent,
              height: 60,
            ),
            const SizedBox(height: 16),
            NoiseIndicator(
              noiseLevel: state.noiseLevel,
              isNoisy: state.noiseLevel > 0.7,
            ),
          ],
          if (!state.isRecording && !state.isAnalyzing) ...[
            const SizedBox(height: 20),
            const Text(
              'Tap to Start Recording',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePreview(RecordingState state) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.activity, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'READY FOR ANALYSIS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontSize: 10,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.recordedFilePath!.split('/').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(recordingProvider.notifier).reset(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(LucideIcons.xCircle, color: Colors.white38, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isAnalyzing ? null : () => _runAnalysis(state.recordedFilePath!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: state.isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('ANALYZING...', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ],
                    )
                  : const Text(
                      'START AI ANALYSIS',
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(RecordingState state) {
    if (state.statusMessage == null) return const SizedBox.shrink();

    final isError = state.statusMessage!.toLowerCase().contains('error') ||
        state.statusMessage!.toLowerCase().contains('failed') ||
        state.statusMessage!.toLowerCase().contains('exception');

    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withValues(alpha: 0.1)
            : (state.isRecording ? Colors.red.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? Colors.red.withValues(alpha: 0.25)
              : (state.isRecording ? Colors.red.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isAnalyzing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
            ),
          if (state.isAnalyzing) const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.statusMessage!,
              textAlign: isError ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: isError ? Colors.redAccent : (state.isRecording ? Colors.redAccent : Colors.white70),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isError)
            GestureDetector(
              onTap: () => ref.read(recordingProvider.notifier).setStatus(null),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(LucideIcons.x, color: Colors.white38, size: 18),
              ),
            ),
        ],
      ),
    ).animate(key: ValueKey(state.statusMessage)).fadeIn().slideY(begin: 0.08);
  }

  Widget _buildHealthTipSection() {
    final tip = HealthTipCard.defaultTips[DateTime.now().second % HealthTipCard.defaultTips.length];
    return Column(
      children: [
        const Row(
          children: [
            Icon(LucideIcons.lightbulb, size: 14, color: Colors.white38),
            SizedBox(width: 8),
            Text(
              'HEALTH TIP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        tip,
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Column(
      children: [
        const SecureBadge(),
        const SizedBox(height: 24),
        Text(
          'FOR SCREENING PURPOSES ONLY - NOT A CLINICAL DIAGNOSTIC DEVICE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}
