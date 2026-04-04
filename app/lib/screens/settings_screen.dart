import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/medical_background.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: MedicalBackground(
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('APPEARANCE'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.moon,
                        title: 'Dark Mode',
                        subtitle: 'Enable dark theme for reduced eye strain',
                        trailing: Switch.adaptive(
                          value: themeState.isDark,
                          onChanged: (_) =>
                              ref.read(themeProvider.notifier).toggleTheme(),
                          activeTrackColor: AppTheme.medicalBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('DATA & PRIVACY'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.download,
                        title: 'Export History',
                        subtitle: 'Download your analysis history as JSON',
                        onTap: () => _exportData(context, ref),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _SettingsTile(
                        icon: LucideIcons.trash2,
                        title: 'Clear History',
                        subtitle: 'Remove all analysis records',
                        onTap: () => _showClearHistoryDialog(context, ref),
                        isDestructive: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('LEGAL'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.shield,
                        title: 'Privacy Policy',
                        onTap: () => _showLegalDialog(context, 'Privacy Policy', _privacyPolicy),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _SettingsTile(
                        icon: LucideIcons.fileText,
                        title: 'Terms of Service',
                        onTap: () => _showLegalDialog(context, 'Terms of Service', _termsOfService),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _SettingsTile(
                        icon: LucideIcons.alertTriangle,
                        title: 'Medical Disclaimer',
                        onTap: () => _showLegalDialog(context, 'Medical Disclaimer', _medicalDisclaimer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('ABOUT'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.cpu,
                        title: 'Inference Engine',
                        subtitle: 'Multi-Stage Deep Learning Pipeline',
                        onTap: null,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _SettingsTile(
                        icon: LucideIcons.code,
                        title: 'App Version',
                        subtitle: '1.0.0',
                        onTap: null,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _SettingsTile(
                        icon: LucideIcons.activity,
                        title: 'Backend Status',
                        subtitle: 'Connected to localhost:8000',
                        onTap: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildDisclaimerCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: children,
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
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
          Icon(LucideIcons.shieldAlert, color: Colors.amber.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This app is for screening purposes only and does not provide medical diagnoses. Always consult a healthcare professional for medical advice.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade300,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final historyState = ref.read(historyProvider);
      final records = historyState.records;

      if (records.isEmpty) {
        _showSnackBar(context, 'No records to export', Colors.orange);
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('Resp-AI Analysis History Export');
      buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final record in records) {
        buffer.writeln('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp)}');
        buffer.writeln('Risk Score: ${record.riskScore.toStringAsFixed(1)}/10');
        buffer.writeln('Classification: ${record.classification}');
        buffer.writeln('Condition: ${record.condition}');
        buffer.writeln('Confidence: ${(record.confidence * 100).toStringAsFixed(1)}%');
        buffer.writeln('-' * 30);
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/resp_ai_history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt');
      await file.writeAsString(buffer.toString());

      if (context.mounted) {
        _showSnackBar(context, 'Exported ${records.length} records', AppTheme.successGreen);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Export failed: $e', Colors.red);
      }
    }
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Clear All History?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will permanently delete all your analysis records. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(context);
              _showSnackBar(context, 'History cleared', AppTheme.successGreen);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.medicalBlue)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const String _privacyPolicy = '''
Resp-AI Privacy Policy

1. Data Collection
This application processes respiratory audio data locally and transmits it to our secure backend for analysis. We do not store audio recordings on our servers unless explicitly permitted by you.

2. Data Usage
Your audio data is used solely for respiratory health risk assessment. Analysis results are stored locally on your device for your reference.

3. Data Retention
Analysis history is stored locally on your device. You can delete this data at any time through the app settings.

4. Third-Party Sharing
We do not share your personal health data with third parties without your explicit consent.

5. Security
All data transmission is encrypted using TLS 1.3. Your data is processed in a secure environment.

Last Updated: February 2026
''';

  static const String _termsOfService = '''
Resp-AI Terms of Service

1. Acceptance
By using this application, you agree to these terms.

2. Medical Disclaimer
This application is NOT a medical device. It provides screening-level risk assessment only. Results should not be used for diagnosis or treatment decisions. Always consult a qualified healthcare professional.

3. User Responsibility
You are responsible for the accuracy of the data you provide and for seeking appropriate medical care.

4. Limitation of Liability
The developers and operators of this application shall not be liable for any medical decisions made based on the application's output.

5. Changes
We reserve the right to modify these terms at any time.

Last Updated: February 2026
''';

  static const String _medicalDisclaimer = '''
MEDICAL DISCLAIMER

IMPORTANT: This application is for SCREENING PURPOSES ONLY and is NOT a diagnostic device.

1. Not a Medical Device
Resp-AI is not approved by any medical regulatory authority (FDA, CE, etc.) and should not be used as a substitute for professional medical advice, diagnosis, or treatment.

2. No Diagnosis
The risk scores and condition associations provided are probabilistic assessments based on acoustic patterns. They do not constitute a medical diagnosis.

3. Seek Professional Care
Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.

4. Emergency Situations
If you think you may have a medical emergency, call your doctor or emergency services immediately. Do not rely on this application for emergency medical situations.

5. Accuracy Limitations
The AI models used have inherent limitations and may produce false positives or false negatives. Clinical validation is ongoing.
''';
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? Colors.redAccent : Colors.white;
    final subtitleColor = isDestructive
        ? Colors.redAccent.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.redAccent : AppTheme.medicalBlue)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDestructive ? Colors.redAccent : AppTheme.medicalBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
