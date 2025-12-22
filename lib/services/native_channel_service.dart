import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Global navigator key to access the navigator from outside the widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Method channel for communication with native code
const platform = MethodChannel('com.example.alarm/native');

// Holds the ID of the most recently triggered alarm from the native side
int? nativeAlarmId;

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
