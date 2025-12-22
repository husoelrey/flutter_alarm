import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to manage local notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String alarmChannelId = 'alarm_channel_id';
  static const String alarmChannelName = 'Alarm Notifications';
  static const String alarmChannelDesc = 'Channel for Alarm notifications';

  /// Initializes the notification service.
  static Future<void> initialize() async {
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: initAndroid);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("Notification tapped with payload: ${response.payload}");
      },
    );

    await _createNotificationChannel();
  }

  /// Creates the notification channel for Android.
  static Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
      alarmChannelId,
      alarmChannelName,
      description: alarmChannelDesc,
      importance: Importance.max,
      playSound: false, // Sound will be played by the RingService
    );

    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      debugPrint("Notification channel '$alarmChannelId' created or updated.");
    } catch (e) {
      debugPrint("Failed to create notification channel: $e");
    }
  }
}
