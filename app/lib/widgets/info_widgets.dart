import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HealthTipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? accentColor;

  const HealthTipCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = LucideIcons.heartPulse,
    this.accentColor,
  });

  static final List<HealthTipCard> defaultTips = [
    HealthTipCard(
      title: 'Breathing Exercise',
      description: 'Practice deep breathing for 5 minutes daily to improve lung capacity.',
      icon: LucideIcons.wind,
      accentColor: const Color(0xFF3B82F6),
    ),
    HealthTipCard(
      title: 'Stay Hydrated',
      description: 'Drink 8 glasses of water daily to keep respiratory passages moist.',
      icon: LucideIcons.droplets,
      accentColor: const Color(0xFF06B6D4),
    ),
    HealthTipCard(
      title: 'Regular Check-ups',
      description: 'Schedule annual respiratory health screenings for early detection.',
      icon: LucideIcons.calendarCheck,
      accentColor: const Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }
}

class OfflineIndicator extends StatelessWidget {

  final bool isOffline;

  const OfflineIndicator({super.key, this.isOffline = false});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.wifiOff, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          const Text(
            'Offline Mode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class SecureBadge extends StatelessWidget {
  const SecureBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, size: 12, color: Colors.green.shade400),
          const SizedBox(width: 5),
          Text(
            'End-to-End Encrypted',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
