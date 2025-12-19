import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cyber-Industrial Neumorphic Theme for Tap-to-Earn App
class AppTheme {
  // Industrial Luxury Palette - Dark Neumorphism
  static const Color background = Color(0xFF1E1E24);
  static const Color surface = Color(0xFF252530);
  static const Color surfaceLight = Color(0xFF2C2C38);
  static const Color surfaceDark = Color(0xFF16161C);
  static const Color primary = Color(0xFFFFD700); // Gold
  static const Color primaryDark = Color(0xFFB8860B); // Dark Gold
  static const Color secondary = Color(0xFF4A5568); // Industrial Grey
  static const Color accent = Color(0xFFE0E0E0); // Silver
  static const Color energyColor = Color(0xFF00FFC2); // Energy Cyan
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);

  // Neumorphic shadow colors
  static Color get neumorphicDark => Colors.black.withValues(alpha: 0.5);
  static Color get neumorphicLight => Colors.white.withValues(alpha: 0.05);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
          displayMedium: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
          displaySmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          headlineMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
          bodyMedium: const TextStyle(fontSize: 14, color: Colors.white60),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceLight,
        contentTextStyle: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );
  }
}

/// Neumorphic Container decoration helper
class NeumorphicDecoration {
  static BoxDecoration flat({
    Color color = AppTheme.surface,
    double borderRadius = 20,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed
          ? [
              BoxShadow(
                color: AppTheme.neumorphicDark,
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: AppTheme.neumorphicLight,
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: -2,
              ),
            ]
          : [
              BoxShadow(
                color: AppTheme.neumorphicDark,
                offset: const Offset(6, 6),
                blurRadius: 12,
              ),
              BoxShadow(
                color: AppTheme.neumorphicLight,
                offset: const Offset(-6, -6),
                blurRadius: 12,
              ),
            ],
    );
  }

  static BoxDecoration concave({
    Color color = AppTheme.surfaceDark,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.surfaceDark, AppTheme.surface],
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.neumorphicDark,
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: AppTheme.neumorphicLight,
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: -4,
        ),
      ],
    );
  }

  static BoxDecoration convex({
    Color color = AppTheme.surface,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.surfaceLight, AppTheme.surfaceDark],
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.neumorphicDark,
          offset: const Offset(6, 6),
          blurRadius: 12,
        ),
        BoxShadow(
          color: AppTheme.neumorphicLight,
          offset: const Offset(-6, -6),
          blurRadius: 12,
        ),
      ],
    );
  }
}
