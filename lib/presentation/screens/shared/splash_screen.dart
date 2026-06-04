import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbridge/core/theme/theme.dart';
import 'package:quickbridge/presentation/providers/pairing_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_error_screen.dart';
import '../android/scan_qr_screen.dart';
import '../android/android_connected_screen.dart';
import '../windows/qr_pair_screen.dart';
import '../windows/windows_connected_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    try {
      final isDemoMode = ref.read(demoModeProvider);
      if (Firebase.apps.isEmpty && !isDemoMode) {
        throw FirebaseException(
          plugin: 'core',
          message: 'Firebase has not been initialized. No apps configured.',
        );
      }

      final pairingState = ref.read(pairingProvider);
      final bool isPaired = pairingState.pairing != null && pairingState.pairing?.status == 'paired';

      Widget nextScreen;
      if (Platform.isAndroid) {
        nextScreen = isPaired ? const AndroidConnectedScreen() : const ScanQRScreen();
      } else {
        nextScreen = isPaired ? const WindowsConnectedScreen() : const QRPairScreen();
      }

      unawaited(Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ));
    } catch (e) {
      debugPrint('Firebase not initialized or initialization failed: $e');
      if (mounted) {
        unawaited(Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const FirebaseConfigErrorScreen()),
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : const Color(0xFFF8FAFC),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Modern double gradient ring icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_calls_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'QuickBridge',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Instant Cross-Platform File Transfer',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
