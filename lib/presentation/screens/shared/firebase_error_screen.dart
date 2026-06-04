import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbridge/core/theme/theme.dart';
import 'package:quickbridge/presentation/providers/pairing_provider.dart';
import '../android/scan_qr_screen.dart';
import '../windows/qr_pair_screen.dart';

class FirebaseConfigErrorScreen extends ConsumerWidget {
  const FirebaseConfigErrorScreen({super.key});

  void _enterDemoMode(BuildContext context, WidgetRef ref) {
    // 1. Enable Demo Mode
    ref.read(demoModeProvider.notifier).state = true;

    // 2. Navigate to Home
    final Widget nextScreen = Platform.isAndroid ? const ScanQRScreen() : const QRPairScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : const Color(0xFFF8FAFC),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Warning Header Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 40,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Firebase Configuration Missing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'QuickBridge requires a Firebase project setup to perform secure file transfers over the cloud. No active Firebase configurations were found on your device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      
                      // Step-by-Step Instructions
                      Text(
                        'How to configure Firebase:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStep(
                        index: '1',
                        title: 'Install Firebase CLI',
                        desc: 'npm install -g firebase-tools',
                        isDark: isDark,
                      ),
                      _buildStep(
                        index: '2',
                        title: 'Login to Firebase',
                        desc: 'firebase login',
                        isDark: isDark,
                      ),
                      _buildStep(
                        index: '3',
                        title: 'Configure Platforms',
                        desc: 'flutterfire configure',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      ElevatedButton(
                        onPressed: () => _enterDemoMode(context, ref),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.offline_bolt_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Run in Offline Demo Mode', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          // Simple exit/restart simulation
                          SystemNavigator.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Exit Application',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String index,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              index,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        desc,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      GestureThresholdDetector(desc: desc),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GestureThresholdDetector extends StatefulWidget {
  final String desc;
  const GestureThresholdDetector({super.key, required this.desc});

  @override
  State<GestureThresholdDetector> createState() => _GestureThresholdDetectorState();
}

class _GestureThresholdDetectorState extends State<GestureThresholdDetector> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.desc));
        setState(() {
          _copied = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _copied = false;
            });
          }
        });
      },
      child: Icon(
        _copied ? Icons.check_circle_outline_rounded : Icons.copy_rounded,
        size: 16,
        color: _copied ? Colors.green : const Color(0xFF6366F1),
      ),
    );
  }
}
