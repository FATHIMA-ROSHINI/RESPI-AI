import 'dart:ui';
import 'package:flutter/material.dart';

class MedicalBackground extends StatelessWidget {
  final Widget child;
  const MedicalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Color
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0F172A), // Slate 900
          ),
        ),

        // Blurred Mesh Orbs
        Positioned(
          top: -100,
          right: -100,
          child: _BlurredOrb(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
            size: 400,
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: _BlurredOrb(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            size: 500,
          ),
        ),
        Positioned(
          top: 200,
          left: -150,
          child: _BlurredOrb(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            size: 350,
          ),
        ),

        // Noise Texture Overlay (Simulated via subtle opacity)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.02),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ),

        // The actual content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _BlurredOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurredOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
