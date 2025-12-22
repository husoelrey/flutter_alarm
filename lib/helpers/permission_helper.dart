import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// A helper class for handling permission-related logic.
class PermissionHelper {
  /// Checks if the current Android version is 12 (API 31) or higher.
  static Future<bool> _isAndroid12OrHigher() async {
    // This is a simplification. A real app should use a package like `device_info_plus`
    // to check the actual Android SDK version.
    if (Platform.isAndroid) {
      return true;
    }
    return false;
  }

  /// Checks the status of all critical permissions required for the app to function.
  /// This does not request permissions, it only checks their current state.
  static Future<bool> areCriticalPermissionsGranted() async {
    if (!Platform.isAndroid) {
      return true; // Assume true for non-Android platforms
    }

    debugPrint("Checking critical permissions status...");

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final overlayStatus = await Permission.systemAlertWindow.status;
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    final notificationStatus = await Permission.notification.status;

    final batteryGranted = batteryStatus.isGranted;
    final overlayGranted = overlayStatus.isGranted;
    final exactAlarmGranted = exactAlarmStatus.isGranted;
    final notificationGranted = notificationStatus.isGranted;

    final bool needsExactAlarmCheck = await _isAndroid12OrHigher();

    final bool allGranted = batteryGranted &&
        overlayGranted &&
        notificationGranted &&
        (!needsExactAlarmCheck || exactAlarmGranted);

    debugPrint(
        "Permission Status (Check): Battery=$batteryGranted, Overlay=$overlayGranted, ExactAlarm=$exactAlarmGranted (Required: $needsExactAlarmCheck), Notification=$notificationGranted");
    debugPrint("All critical permissions granted: $allGranted");

    return allGranted;
  }
}
