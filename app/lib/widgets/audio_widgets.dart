import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:async';

class WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  final Color? color;
  final double height;

  const WaveformVisualizer({
    super.key,
    this.isActive = false,
    this.color,
    this.height = 80,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> {
  final List<double> _values = List.generate(40, (_) => 0.0);
  Timer? _timer;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (widget.isActive && mounted) {
        setState(() {
          for (int i = 0; i < _values.length; i++) {
            _values[i] = _random.nextDouble();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF3B82F6);

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _values.map((value) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: widget.isActive 
                ? 8 + (value * (widget.height - 16))
                : 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: widget.isActive ? 0.9 : 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AnimatedRiskCircle extends StatefulWidget {
  final double score;
  final double size;

  const AnimatedRiskCircle({
    super.key,
    required this.score,
    this.size = 160,
  });

  @override
  State<AnimatedRiskCircle> createState() => _AnimatedRiskCircleState();
}

class _AnimatedRiskCircleState extends State<AnimatedRiskCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(double value) {
    if (value >= 7) return const Color(0xFFEF4444);
    if (value >= 4) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        final color = _getColor(currentScore);
        final progress = currentScore / 10;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    'RISK',
                    style: TextStyle(
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class NoiseIndicator extends StatelessWidget {
  final double noiseLevel;
  final bool isNoisy;

  const NoiseIndicator({
    super.key,
    required this.noiseLevel,
    this.isNoisy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isNoisy
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNoisy
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNoisy ? Icons.volume_up : Icons.check_circle,
            size: 14,
            color: isNoisy ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            isNoisy ? 'Background Noise Detected' : 'Clear Audio',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isNoisy ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = const Color(0xFF3B82F6),
    this.size = 12,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * _controller.value),
                blurRadius: widget.size * 0.8,
                spreadRadius: widget.size * 0.3,
              ),
            ],
          ),
        );
      },
    );
  }
}
