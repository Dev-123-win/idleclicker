import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Material 3 Theme for Tap-to-Earn App
class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFFFD700); // Gold
  static const Color primaryDark = Color(0xFFC5A000); // Darker Gold
  static const Color secondary = Color(0xFF4A5568); // Slate
  static const Color background = Color(0xFF121212); // True Black/Dark for OLED
  static const Color surface = Color(0xFF1E1E1E); // Standard Dark Surface
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  // Semantic Colors
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color energyColor = Color(0xFF00E5FF); // Cyan Accent

  // Legacy/Compatibility Colors (Mapped to new scheme)
  static const Color surfaceLight = Color(0xFF2C2C2C);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFF4A5568);

  static Color get neumorphicDark => Colors.black.withValues(alpha: 0.3);
  static Color get neumorphicLight => Colors.white.withValues(alpha: 0.05);
  static Color get shadowHigh => Colors.black.withValues(alpha: 0.5);
  static Color get highlightHigh => Colors.white.withValues(alpha: 0.1);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,

      // Material 3 Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        onSurface: Colors.white,
        error: error,
        onError: Colors.black,
      ),

      // Typography
      textTheme:
          GoogleFonts.rajdhaniTextTheme(
            ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ).copyWith(
            headlineLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            titleLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            labelLarge: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

      // Component Themes
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0, // Flat look
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

// Deprecated class kept for temporary compatibility if needed,
// but essentially defined to do nothing or standard box decoration.
class NeumorphicDecoration {
  static BoxDecoration flat({
    double borderRadius = 12,
    Color? color,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color ?? AppTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    );
  }

  static BoxDecoration convex({double borderRadius = 12, Color? color}) {
    return flat(borderRadius: borderRadius, color: color);
  }

  static BoxDecoration concave({double borderRadius = 12, Color? color}) {
    return flat(borderRadius: borderRadius, color: color);
  }

  static BoxDecoration listCard({double borderRadius = 16}) {
    return flat(borderRadius: borderRadius, color: AppTheme.surface);
  }

  static BoxDecoration button({
    Color? color,
    double borderRadius = 12,
    bool isPressed = false,
  }) {
    return flat(borderRadius: borderRadius, color: color, isPressed: isPressed);
  }
}
