import 'package:alarm/auth/auth_page.dart';
import 'package:alarm/auth/login_page.dart';
import 'package:alarm/auth/register_page.dart';
import 'package:alarm/games/grid_memory_game_page.dart';
import 'package:alarm/games/motivation_typing_page.dart';
import 'package:alarm/helpers/permission_helper.dart';
import 'package:alarm/presentation/screens/main_shell.dart';
import 'package:alarm/screens/good_morning.dart';
import 'package:alarm/screens/permission_screen.dart';
import 'package:alarm/screens/splash_page.dart';
import 'package:alarm/services/native_channel_service.dart';
import 'package:alarm/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

/// App Entry Point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await initializeDateFormatting('tr_TR', null);
  await NotificationService.initialize();

  // Check permissions using the helper class
  final bool allCriticalPermissionsGranted =
      await PermissionHelper.areCriticalPermissionsGranted();

  setupNativeChannelHandler();

  // Start the application
  runApp(
    MyApp(
      initialRoute: !allCriticalPermissionsGranted ? '/permissions' : '/splash',
    ),
  );
}

/// Main Flutter App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute, this.alarmPayload});

  final String initialRoute;
  final String? alarmPayload;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Comes from native_channel_service.dart
      title: 'Flutter Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1527),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
          primary: Colors.tealAccent,
          secondary: Colors.tealAccent,
          background: const Color(0xFF0B1527),
          surface: const Color(0xFF121E33),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121E33),
          foregroundColor: Colors.tealAccent,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: initialRoute,

      /// App Routes
      routes: {
        '/': (_) => const MainShell(),
        '/permissions': (_) => const PermissionScreen(),
        '/typing': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final alarmId = args?['alarmId'] as int?;
          return MotivationTypingPage(alarmId: alarmId);
        },
        '/memory': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final alarmId = args?['alarmId'] as int?;
          return GridMemoryGamePage(alarmId: alarmId);
        },
        '/goodMorning': (_) => const GoodMorningPage(),
        '/auth': (_) => const AuthPage(),
        '/login': (_) => const LoginPage(),
        '/splash': (_) => const SplashPage(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}

// Required setup for the intl package
Future<void> initializeDateFormatting(String locale, String? _) async {
  Intl.defaultLocale = locale;
}
