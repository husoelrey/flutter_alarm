import 'package:flutter/material.dart';

/// Centralizes all colors used in the application.
class AppColors {
  // Main Backgrounds
  static const Color background = Color(0xFF0B1527);
  static const Color surface = Color(0xFF121E33);
  
  // Accents & Primary
  static const Color primary = Colors.tealAccent;
  static const Color secondary = Colors.deepPurple;
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textDisabled = Colors.white54; // or grey[500] logic

  // Functional Colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Colors.greenAccent;
  
  // Gradients (for games etc.)
  static const List<Color> gameGradient = [
    Color(0xFF221B36), 
    Color(0xFF0D0B14)
  ];
  
  // Game Specific
  static const Color tileDefault = Color(0xFF1A1E3F);
  static const Color tileHint = Colors.tealAccent;
  static const Color tileWrong = Color(0xFFE53935);
}
