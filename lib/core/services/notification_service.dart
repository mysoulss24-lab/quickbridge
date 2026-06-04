import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initializes notification services for both Android and Windows
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) return;

    if (Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      // Create standard channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'quickbridge_transfer_channel',
        'File Transfers',
        description: 'Notifications for QuickBridge file uploads and downloads.',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } else if (Platform.isWindows) {
      await localNotifier.setup(
        appName: 'QuickBridge',
        // The shortcutId is only required if you want to bundle it as MSIX packaging.
        shortcutId: 'com.quickbridge.app',
      );
    }

    _initialized = true;
  }

  /// Displays a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (Platform.isAndroid) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'quickbridge_transfer_channel',
        'File Transfers',
        channelDescription: 'Notifications for QuickBridge file uploads and downloads.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Generate random notification ID
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } else if (Platform.isWindows) {
      final LocalNotification notification = LocalNotification(
        title: title,
        body: body,
      );
      
      notification.show();
    }
  }
}
