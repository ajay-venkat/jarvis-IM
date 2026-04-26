import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class WakeWordIndicator extends StatefulWidget {
  final bool isActive;

  const WakeWordIndicator({super.key, required this.isActive});

  @override
  State<WakeWordIndicator> createState() => _WakeWordIndicatorState();
}

class _WakeWordIndicatorState extends State<WakeWordIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? AppConstants.successGreen
                      .withOpacity(0.3 * _glowAnimation.value)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive
                      ? AppConstants.successGreen
                          .withOpacity(_glowAnimation.value)
                      : Colors.grey.withOpacity(0.5),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: AppConstants.successGreen
                                .withOpacity(0.4 * _glowAnimation.value),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isActive
                    ? 'Listening for Jarvis...'
                    : 'Wake word off',
                style: TextStyle(
                  color: widget.isActive
                      ? AppConstants.successGreen
                          .withOpacity(0.7 + 0.3 * _glowAnimation.value)
                      : Colors.grey.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
