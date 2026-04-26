import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../providers/jarvis_provider.dart';

class ArcReactor extends StatefulWidget {
  final JarvisState state;
  final double size;
  final VoidCallback? onTap;

  const ArcReactor({
    super.key,
    required this.state,
    this.size = 200,
    this.onTap,
  });

  @override
  State<ArcReactor> createState() => _ArcReactorState();
}

class _ArcReactorState extends State<ArcReactor>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _updateAnimationForState();
  }

  @override
  void didUpdateWidget(ArcReactor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationForState();
    }
  }

  void _updateAnimationForState() {
    switch (widget.state) {
      case JarvisState.idle:
        _pulseController.duration = const Duration(milliseconds: 2000);
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
        _rippleController.stop();
        _rippleController.reset();
        break;

      case JarvisState.listening:
        _pulseController.duration = const Duration(milliseconds: 300);
        _pulseController.repeat(reverse: true);
        _rippleController.repeat();
        break;

      case JarvisState.processing:
        _pulseController.duration = const Duration(milliseconds: 800);
        _pulseController.repeat(reverse: true);
        _rippleController.stop();
        break;

      case JarvisState.speaking:
        _pulseController.duration = const Duration(milliseconds: 1500);
        _pulseController.repeat(reverse: true);
        _rippleController.stop();
        _rippleController.reset();
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _rippleController,
            _rotationController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              painter: _ArcReactorPainter(
                pulseValue: _pulseAnimation.value,
                rippleValue: _rippleController.isAnimating
                    ? _rippleAnimation.value
                    : 1.0,
                rippleOpacity: _rippleController.isAnimating
                    ? (1.0 - _rippleController.value)
                    : 0.0,
                rotationValue: _rotationController.value,
                state: widget.state,
              ),
              size: Size(widget.size, widget.size),
            );
          },
        ),
      ),
    );
  }
}

class _ArcReactorPainter extends CustomPainter {
  final double pulseValue;
  final double rippleValue;
  final double rippleOpacity;
  final double rotationValue;
  final JarvisState state;

  _ArcReactorPainter({
    required this.pulseValue,
    required this.rippleValue,
    required this.rippleOpacity,
    required this.rotationValue,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Outer glow
    final glowIntensity = state == JarvisState.listening ? 0.6 : 0.3;
    final glowRadius = maxRadius * pulseValue;

    for (int i = 4; i >= 0; i--) {
      final paint = Paint()
        ..color = AppConstants.accentColor
            .withOpacity(glowIntensity * (1 - i / 5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20.0 + i * 10.0);
      canvas.drawCircle(center, glowRadius * (1 + i * 0.05), paint);
    }

    // Ripple effect (when listening)
    if (rippleOpacity > 0) {
      final ripplePaint = Paint()
        ..color = AppConstants.accentColor.withOpacity(rippleOpacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, maxRadius * rippleValue, ripplePaint);
    }

    // Outer ring
    final outerRingPaint = Paint()
      ..color = AppConstants.accentColor.withOpacity(0.8 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, maxRadius * 0.9 * pulseValue, outerRingPaint);

    // Inner segmented ring (rotating)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationValue * 2 * pi);

    final segmentPaint = Paint()
      ..color = AppConstants.accentColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final segmentRadius = maxRadius * 0.72 * pulseValue;
    for (int i = 0; i < 8; i++) {
      final startAngle = (i * pi / 4) + 0.1;
      final sweepAngle = pi / 6;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: segmentRadius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );
    }
    canvas.restore();

    // Middle ring
    final middleRingPaint = Paint()
      ..color = AppConstants.accentColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
        center, maxRadius * 0.55 * pulseValue, middleRingPaint);

    // Inner rotating segments
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotationValue * 2 * pi * 1.5);

    final innerSegPaint = Paint()
      ..color = AppConstants.accentColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final innerSegRadius = maxRadius * 0.42 * pulseValue;
    for (int i = 0; i < 6; i++) {
      final startAngle = (i * pi / 3) + 0.15;
      final sweepAngle = pi / 5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: innerSegRadius),
        startAngle,
        sweepAngle,
        false,
        innerSegPaint,
      );
    }
    canvas.restore();

    // Core circle
    final coreGradient = RadialGradient(
      colors: [
        AppConstants.accentColor.withOpacity(0.9 * pulseValue),
        AppConstants.accentColor.withOpacity(0.4 * pulseValue),
        AppConstants.accentColor.withOpacity(0.0),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: maxRadius * 0.28),
      );
    canvas.drawCircle(center, maxRadius * 0.28 * pulseValue, corePaint);

    // Bright center dot
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * pulseValue);
    canvas.drawCircle(center, maxRadius * 0.06, dotPaint);

    // Inner white ring
    final innerWhiteRing = Paint()
      ..color = Colors.white.withOpacity(0.3 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, maxRadius * 0.15, innerWhiteRing);
  }

  @override
  bool shouldRepaint(_ArcReactorPainter oldDelegate) => true;
}
