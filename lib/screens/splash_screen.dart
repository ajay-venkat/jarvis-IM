import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/arc_reactor.dart';
import '../providers/jarvis_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _showText = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Show text after a short delay
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showText = true);
      }
    });

    // Navigate to home after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Arc Reactor animation
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.accentColor
                            .withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: AppConstants.accentColor
                            .withOpacity(0.15 * _glowAnimation.value),
                        blurRadius: 120,
                        spreadRadius: 60,
                      ),
                    ],
                  ),
                  child: ArcReactor(
                    state: JarvisState.idle,
                    size: 180,
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // J.A.R.V.I.S text
            if (_showText)
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  children: [
                    Text(
                      'J.A.R.V.I.S',
                      style: GoogleFonts.orbitron(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.accentColor,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: AppConstants.accentColor.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        'Just A Rather Very Intelligent System',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          color: AppConstants.textSecondary,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 60),

            // Loading indicator
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor:
                      AppConstants.accentColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.accentColor.withOpacity(0.6),
                  ),
                  minHeight: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
