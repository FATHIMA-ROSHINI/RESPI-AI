import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/analysis_result.dart';
import '../providers/history_provider.dart';
import '../providers/state_providers.dart';
import '../widgets/medical_background.dart';
import '../widgets/audio_widgets.dart';
import '../theme/app_theme.dart';

import '../services/report_service.dart';
import '../models/history_record.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final AnalysisResult result;

  const ResultScreen({super.key, required this.result});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _savedToHistory = false;
  HistoryRecord? _currentRecord;
  final List<String> _selectedSymptoms = [];
  final List<String> _availableSymptoms = [
    'Cough',
    'Shortness of breath',
    'Wheezing',
    'Chest pain',
    'Sputum production',
    'Fever',
    'Fatigue',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSaveToHistory();
    });
  }

  Future<void> _autoSaveToHistory() async {
    if (!_savedToHistory) {
      _savedToHistory = true;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Saving to database...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        final patientId = ref.read(recordingProvider).selectedPatientId;
        
        final record = await ref.read(historyProvider.notifier).addFromAnalysis(
          riskScore: widget.result.riskScore,
          classification: widget.result.classification,
          condition: widget.result.diseaseAssociation.condition,
          confidence: _parseConfidence(widget.result.diseaseAssociation.confidence),
          patientId: patientId,
        );
        
        if (mounted) {
          setState(() {
            _currentRecord = record;
          });
          
          if (record != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Analysis saved to history'),
                  ],
                ),
                backgroundColor: AppTheme.successGreen,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Failed to save analysis'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error saving to history: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Error: $e'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
    
    if (_currentRecord != null) {
      final updatedRecord = _currentRecord!.copyWith(symptoms: _selectedSymptoms);
      ref.read(historyProvider.notifier).updateRecord(updatedRecord);
      _currentRecord = updatedRecord;
    }
  }

  double _parseConfidence(String confidence) {
    if (confidence == 'N/A') return 0.0;
    try {
      return double.parse(confidence.replaceAll('%', '')) / 100;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CLINICAL REPORT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Colors.white70, size: 20),
            onPressed: () => _showShareOptions(context),
            tooltip: 'Share Report',
          ),
          IconButton(
            icon: const Icon(LucideIcons.download, color: Colors.white70, size: 20),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: MedicalBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 110),
              child: Column(
                children: [
                  _buildRiskIndicator(),
                  const SizedBox(height: 28),
                  _buildPatternCard(),
                  const SizedBox(height: 20),
                  _buildSymptomSelectionCard(),
                  const SizedBox(height: 20),
                  _buildDetailsCard(),
                  const SizedBox(height: 20),
                  _buildNextStepsCard(),
                  const SizedBox(height: 40),
                  _buildDisclaimerCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedRiskCircle(score: widget.result.riskScore, size: 150)
          .animate()
          .fadeIn(duration: 500.ms)
          .scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildPatternCard() {
    final condition = widget.result.diseaseAssociation.condition.toLowerCase();
    final isNormal = condition.contains('normal') ||
        condition.contains('no abnormality') ||
        condition.contains('healthy');

    final accentColor = isNormal ? AppTheme.successGreen : AppTheme.medicalBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PATTERN ASSOCIATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.target, size: 10, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.result.diseaseAssociation.confidence} confidence',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isNormal ? LucideIcons.checkCircle : LucideIcons.activity,
                  size: 28,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.result.diseaseAssociation.condition,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Text(
            widget.result.diseaseAssociation.disclaimer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.08);
  }

  Widget _buildDetailsCard() {
    final anomalies = widget.result.details['detected_anomalies'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.info, size: 14, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                'ANALYSIS DETAILS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMetric(
                'PROBABILITY',
                '${(widget.result.probability * 100).toStringAsFixed(1)}%',
                LucideIcons.percent,
              ),
              const SizedBox(width: 20),
              _buildMetric(
                'CLASSIFICATION',
                widget.result.classification,
                LucideIcons.tag,
              ),
            ],
          ),
          if (anomalies.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 14),
            const Text(
              'DETECTED ANOMALIES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: anomalies.map((a) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    a.toString(),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08);
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.blueAccent.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepsCard() {
    final isHighRisk = widget.result.riskScore >= 7;
    final isModerateRisk = widget.result.riskScore >= 4 && widget.result.riskScore < 7;

    List<String> steps;
    if (isHighRisk) {
      steps = [
        'Consult a healthcare professional immediately',
        'Do not delay seeking medical attention',
        'Bring this report to your appointment',
      ];
    } else if (isModerateRisk) {
      steps = [
        'Schedule an appointment with your doctor',
        'Monitor symptoms for any changes',
        'Consider a follow-up assessment in 1-2 weeks',
      ];
    } else {
      steps = [
        'Continue regular health monitoring',
        'Maintain healthy respiratory habits',
        'Schedule routine check-ups as recommended',
      ];
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.listChecks,
                size: 14,
                color: isHighRisk
                    ? Colors.redAccent
                    : isModerateRisk
                        ? Colors.amber
                        : Colors.green,
              ),
              const SizedBox(width: 8),
              const Text(
                'RECOMMENDED NEXT STEPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08);
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: Colors.amber.shade400, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.result.details['medical_disclaimer'] ??
                  'This analysis is for screening purposes only and should not replace professional medical diagnosis.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.amber.shade300,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateShareText() {
    final result = widget.result;
    final riskLevel = result.riskScore >= 7 ? 'HIGH' : (result.riskScore >= 4 ? 'MODERATE' : 'LOW');
    
    return '''
RESP-AI CLINICAL REPORT
========================

Date: ${DateFormat('MMMM d, yyyy - h:mm a').format(DateTime.now())}

ANALYSIS SUMMARY
----------------
Risk Score: ${result.riskScore.toStringAsFixed(1)} / 10.0 ($riskLevel)
Classification: ${result.classification}
Condition: ${result.diseaseAssociation.condition}
Confidence: ${result.diseaseAssociation.confidence}

RECOMMENDED NEXT STEPS
----------------------
${result.riskScore >= 7 ? 'URGENT: Consult a healthcare professional immediately.' : (result.riskScore >= 4 ? 'MODERATE: Schedule an appointment with your doctor.' : 'LOW: Continue regular health monitoring.')}

DISCLAIMER
----------
This report is generated by an AI screening tool and is NOT a medical diagnosis. Always consult with a qualified medical professional for diagnosis and treatment.

---
RESP-AI - Respiratory Risk Assessment
''';
  }

  Future<void> _shareAsText() async {
    try {
      await Share.share(
        _generateShareText(),
        subject: 'RESP-AI Clinical Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(context, LucideIcons.share2, 'Share', _shareAsText),
                _buildShareOption(context, LucideIcons.fileText, 'Text', _shareAsText),
                _buildShareOption(context, LucideIcons.copy, 'Copy', _copyToClipboard),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    try {
      await Share.share(
        _generateShareText(),
        subject: 'RESP-AI Clinical Report',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report copied to clipboard'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copy failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildShareOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.thermometer, size: 14, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'REPORTED SYMPTOMS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSymptoms.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom);
              return GestureDetector(
                onTap: () => _toggleSymptom(symptom),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.medicalBlue.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.medicalBlue.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    symptom,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.medicalBlue : Colors.white54,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.08);
  }

  void _showExportDialog(BuildContext context) {
    if (_currentRecord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the report to be saved')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.fileDown, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text(
              'Export PDF Report',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Generate a professional PDF report with all analysis details and your reported symptoms.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Saving PDF...'),
                      ],
                    ),
                  ),
                );

                final filePath = await ReportService.exportReportToFile(_currentRecord!);
                
                final updatedRecord = _currentRecord!.copyWith(reportPath: filePath);
                await ref.read(historyProvider.notifier).updateRecord(updatedRecord);
                
                setState(() {
                  _currentRecord = updatedRecord;
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report saved to: $filePath'),
                      backgroundColor: AppTheme.successGreen,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'View',
                        textColor: Colors.white,
                        onPressed: () => _viewPdf(filePath),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewPdf(String filePath) async {
    try {
      await ReportService.viewPdfFromFile(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
