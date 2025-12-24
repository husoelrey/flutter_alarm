import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Global navigator key to access the navigator from outside the widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Method channel for communication with native code
const platform = MethodChannel('com.example.alarm/native');

// Holds the ID of the most recently triggered alarm from the native side
int? nativeAlarmId;

/// Checks if there is any pending navigation instruction from the native side (e.g. Memory Game).
Future<void> checkPendingNavigation() async {
  try {
    debugPrint("Checking for pending navigation...");
    final result = await platform.invokeMethod('checkPendingNavigation');
    if (result != null && result is Map) {
      final route = result['route'] as String?;
      final alarmId = result['alarmId'] as int?;

      if (route != null && alarmId != null) {
        debugPrint("Pending navigation found: $route, ID: $alarmId");
        
        // Wait a bit to ensure context is ready if called too early
        if (navigatorKey.currentContext == null) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (navigatorKey.currentContext != null) {
          if (route == '/memory') {
             Navigator.of(navigatorKey.currentContext!)
            .pushReplacementNamed('/memory', arguments: {"alarmId": alarmId});
          } else if (route == '/typing') {
             Navigator.of(navigatorKey.currentContext!)
            .pushReplacementNamed('/typing', arguments: {"alarmId": alarmId});
          }
        }
      }
    }
  } catch (e) {
    debugPrint("Error checking pending navigation: $e");
  }
}

/// Sets up the method call handler to listen for calls from native code.
void setupNativeChannelHandler() {
  // Checks if the specified route is currently active
  bool isCurrentRoute(String name) =>
      navigatorKey.currentContext != null &&
      ModalRoute.of(navigatorKey.currentContext!)?.settings.name == name;

  platform.setMethodCallHandler((call) async {
    final alarmId = call.arguments["alarmId"] as int?;
    debugPrint("Native call received: ${call.method} | id=$alarmId");
    if (alarmId == null) return;

    switch (call.method) {
      case "openMemoryPage":
        nativeAlarmId = alarmId;
        if (isCurrentRoute('/memory')) {
          debugPrint("/memory is already open -> not opening a new page");
          return;
        }

        void openMemory() => Navigator.of(navigatorKey.currentContext!)
            .pushReplacementNamed('/memory', arguments: {"alarmId": alarmId});

        // Ensure the context is available before navigating
        if (navigatorKey.currentContext != null) {
          openMemory();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (navigatorKey.currentContext != null) openMemory();
          });
        }
        break;

      case "openTypingPage":
        if (isCurrentRoute('/typing')) {
          debugPrint("⚠️ /typing is already open");
          return;
        }
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushReplacementNamed(
            '/typing',
            arguments: {"alarmId": alarmId},
          );
        }
        break;
    }
  });
}
