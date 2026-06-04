import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quickbridge/core/theme/theme.dart';
import 'package:quickbridge/presentation/providers/pairing_provider.dart';
import '../shared/settings_screen.dart';
import 'windows_connected_screen.dart';

class QRPairScreen extends ConsumerStatefulWidget {
  const QRPairScreen({super.key});

  @override
  ConsumerState<QRPairScreen> createState() => _QRPairScreenState();
}

class _QRPairScreenState extends ConsumerState<QRPairScreen> {
  String? _qrPayload;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePairingQR();
    });
  }

  Future<void> _generatePairingQR() async {
    setState(() {
      _initializing = true;
    });
    try {
      final pairingNotifier = ref.read(pairingProvider.notifier);
      final String pairId = await pairingNotifier.startDesktopPairing();
      
      final payload = {
        'pairId': pairId,
        'deviceName': ref.read(pairingProvider).localDeviceName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      setState(() {
        _qrPayload = jsonEncode(payload);
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _initializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate pairing ID: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairing = ref.watch(pairingProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to pairing updates. If paired, transition to Desktop Hub.
    ref.listen(pairingProvider, (previous, next) {
      if (next.pairing != null && next.pairing?.status == 'paired') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WindowsConnectedScreen()),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: isDark ? const BoxDecoration(gradient: AppTheme.darkBackgroundGradient) : null,
        child: Stack(
          children: [
            // Settings top action
            Positioned(
              top: 24,
              right: 24,
              child: IconButton(
                icon: const Icon(Icons.settings_rounded, size: 28),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
            ),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left Text Column
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.computer_rounded, color: Color(0xFF6366F1), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    pairing.localDeviceName,
                                    style: const TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Pair with QuickBridge Mobile',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Scan this QR code from your Android device using the QuickBridge app to establish a secure paired connection. Only paired devices can exchange files.',
                              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                            ),
                            const SizedBox(height: 32),
                            if (_initializing)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Initializing pairing key...', style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            else
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Refresh QR Code'),
                                onPressed: _generatePairingQR,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Right QR Code Card
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: _initializing || _qrPayload == null
                                ? const SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      QrImageView(
                                        data: _qrPayload!,
                                        version: QrVersions.auto,
                                        size: 200.0,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF6366F1),
                                        ),
                                        dataModuleStyle: const QrDataModuleStyle(
                                          dataModuleShape: QrDataModuleShape.square,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Waiting for connection...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
