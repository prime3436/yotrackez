import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/cyber_blade_wings_logo.dart';
import '../main.dart';
import 'onboarding_screen.dart';

/// Pitch-black startup screen featuring the rotating Cyber Blade Wings emblem
/// and smooth entrance scale transition into the main YOTRACKEZ dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _startStartupSequence();
  }

  Future<void> _startStartupSequence() async {
    // Load settings concurrently with the splash animation
    await Future.wait([
      UserSettings.instance.load(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);

    if (!mounted) return;

    setState(() => _exiting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final destination = UserSettings.instance.onboarded
        ? const MainShell()
        : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, _) => destination,
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: AnimatedScale(
          scale: _exiting ? 1.4 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: _exiting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rotating Cyber Blade Wings Emblem
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surface,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: AppTheme.glowShadow(AppTheme.primary),
                  ),
                  child: const CyberBladeWingsLogo(
                    size: 110,
                    animateStartupScan: true, // Top & Bottom wings fly out + Cyberpunk Grey laser scan (NO ROTATION)
                    animationDuration: Duration(milliseconds: 2200),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.4, 0.4), curve: Curves.easeOutBack),

                const SizedBox(height: 36),

                // App Title
                Text(
                  'YOTRACKEZ',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: AppTheme.textPrimary,
                      ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 10),

                // Subtitle Status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: 500.ms),
                    const SizedBox(width: 8),
                    Text(
                      'INITIALIZING AI ENGINE...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            letterSpacing: 2.5,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
