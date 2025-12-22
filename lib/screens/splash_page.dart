import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A splash screen that checks the user's authentication state and navigates accordingly.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationState();
  }

  /// Waits for a moment, then checks if a user is signed in and navigates.
  Future<void> _checkAuthenticationState() async {
    // A short delay for the splash effect
    await Future.delayed(const Duration(seconds: 1));

    // Listen for the first authentication state change to determine if a user is logged in.
    final user = await FirebaseAuth.instance.authStateChanges().first;

    if (!mounted) return;

    // Navigate to the appropriate screen
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/'); // User is signed in
    } else {
      Navigator.pushReplacementNamed(context, '/auth'); // User is not signed in
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
