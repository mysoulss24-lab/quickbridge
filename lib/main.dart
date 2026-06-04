import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/theme.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/shared/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  // Note: Firebase options need to be generated using FlutterFire CLI or provided in firebase config files.
  // We initialize with default configuration here.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e. Make sure you set up firebase configs.');
  }

  // 2. Initialize Notification Services
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    const ProviderScope(
      child: QuickBridgeApp(),
    ),
  );
}

class QuickBridgeApp extends ConsumerWidget {
  const QuickBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'QuickBridge',
      debugShowCheckedModeBanner: false,
      
      // Light & Dark theme configs using Material 3 style guides
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      
      home: const SplashScreen(),
    );
  }
}
