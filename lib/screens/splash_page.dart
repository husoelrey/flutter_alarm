import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:alarm/presentation/screens/main_shell.dart';
import 'package:alarm/auth/auth_page.dart';

/// Acts as a gatekeeper for the app's authentication state.
///
/// This widget listens to Firebase's `authStateChanges` stream and decides
/// whether to show the main application (`MainShell`) or the `AuthPage` based
/// on whether a user is currently signed in.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for the initial authentication state, show a loading screen.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If the snapshot has data, it means a user is logged in.
        if (snapshot.hasData) {
          // User is signed in, show the main part of the app.
          return const MainShell();
        }
        
        // If the snapshot has no data, no user is signed in.
        // Show the authentication page.
        return const AuthPage();
      },
    );
  }
}
