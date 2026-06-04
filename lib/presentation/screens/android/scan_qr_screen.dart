import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../theme/theme.dart';
import '../../../providers/pairing_provider.dart';
import '../shared/settings_screen.dart';
import 'android_connected_screen.dart';

class ScanQRScreen extends ConsumerStatefulWidget {
  const ScanQRScreen({super.key});

  @override
  ConsumerState<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends ConsumerState<ScanQRScreen> {
  bool _isScanning = false;
  bool _hasPermission = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan pairing QR Code.')),
        );
      }
    }
  }

  void _onQRScanned(BarcodeCapture capture) async {
    if (_isLoading) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isLoading = true;
      _isScanning = false;
    });

    try {
      // 1. Try to parse JSON QR data
      final Map<String, dynamic> data = jsonDecode(code);
      final String? pairId = data['pairId'];
      
      if (pairId == null || pairId.length < 12) {
        throw const FormatException('Invalid Pair ID format.');
      }

      // 2. Perform pairing connection
      await ref.read(pairingProvider.notifier).connectToDevice(pairId);

      // 3. Navigate to Android Connected Hub
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AndroidConnectedScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pair: ${e.toString().contains('FormatException') ? 'Invalid QR code.' : e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairingState = ref.watch(pairingProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickBridge Pair'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: isDark ? const BoxDecoration(gradient: AppTheme.darkBackgroundGradient) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isScanning) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 72,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Pair with Windows Desktop',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: Center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Open QuickBridge on your Windows PC and scan the generated QR Code to begin transferring files.',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                        textAlign: Center,
                      ),
                      if (pairingState.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          pairingState.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: Center,
                        ),
                      ],
                    ],
                  ),
                ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Scan QR Code'),
                        onPressed: () async {
                          if (!_hasPermission) {
                            await _requestCameraPermission();
                          }
                          if (_hasPermission) {
                            setState(() {
                              _isScanning = true;
                            });
                          }
                        },
                      ),
              ] else ...[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        MobileScanner(
                          onDetect: _onQRScanned,
                        ),
                        // Scanner overlay frame
                        Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        // Back overlay button
                        Positioned(
                          top: 16,
                          left: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.black50,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => setState(() => _isScanning = false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Center the QR Code inside the box to scan',
                  textAlign: Center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
