import 'package:flutter/material.dart';

/// Child-friendly color palette for ChorePal
class ChorePalColors {
  // Primary colors
  static const Color skyBlue = Color(0xFF4FC3F7);
  static const Color lightBlue = Color(0xFF81D4FA); // Light blue
  static const Color darkBlue = Color(0xFF0277BD); // Dark blue
  static const Color grassGreen = Color(0xFF66BB6A);
  static const Color sunshineOrange = Color(0xFFFFB74D);
  static const Color strawberryPink = Color(0xFFEC407A);
  static const Color lavenderPurple = Color(0xFFAB47BC);
  static const Color lemonYellow = Color(0xFFFFF176);
  static const Color mintGreen = Color(0xFF81C784);
  static const Color peachPink = Color(0xFFFF8A65);
  
  // Soft backgrounds
  static const Color softBlue = Color(0xFFE3F2FD);
  static const Color softGreen = Color(0xFFE8F5E9);
  static const Color softPink = Color(0xFFFCE4EC);
  static const Color softYellow = Color(0xFFFFF9C4);
  static const Color softBackground = Color(0xFFF8F9FA);
  
  // Text colors
  static const Color textPrimary = Color(0xFF37474F);
  static const Color textSecondary = Color(0xFF78909C);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [lightBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient rewardGradient = LinearGradient(
    colors: [sunshineOrange, strawberryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [grassGreen, mintGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [softBlue, softGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [lavenderPurple, strawberryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dark mode gradients
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF252525)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Rich dark blue gradient for dark mode accents
  static const LinearGradient darkBlueGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glassmorphism colors
  static Color glassBackground = Colors.white.withOpacity(0.25);
  static Color glassBorder = Colors.white.withOpacity(0.3);
  
  // Shadow colors
  static BoxShadow lightShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );
  
  static BoxShadow mediumShadow = BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 30,
    offset: const Offset(0, 12),
  );
}

