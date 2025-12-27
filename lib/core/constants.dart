import 'package:flutter/material.dart';

/// App-wide constants for TapMine
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'TapMine';
  static const String appVersion = '1.0.0';

  // Game Constants
  static const int coinsPerRupee = 1000;
  static const int minWithdrawalCoins = 100000; // ₹100
  static const int referrerBonus = 2000;
  static const int referredBonus = 5000;

  // Ad Intervals
  static const int easyTierAdInterval = 50; // Show ad randomly within 50 taps
  static const int hardTierAdInterval = 40; // Show ad randomly within 40 taps
  static const int adCooldownSeconds = 10; // Cooldown after watching ad

  // Sync
  static const int syncIntervalHours = 3;
  // TODO: Replace with your deployed Cloudflare Worker URL
  static const String workerBaseUrl =
      'https://tapmine-worker.earnplay12345.workers.dev';
  // TODO: Set this to match SYNC_SECRET in Cloudflare Worker (use wrangler secret put SYNC_SECRET)
  static const String syncSecret = 'Supreet@9900';

  // Security
  static const int maxRequestAgeSeconds = 300; // 5 minutes
  static const int maxTapsPerHour = 3600; // 1 tap per second max
  static const int maxCoinsPerTap = 100; // Generous limit

  // Mission Tiers
  static const int easyTierMissionCount = 15;
  static const int hardTierMissionCount = 35;
  static const int totalMissions = 50;

  // Hive Boxes
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String syncQueueBox = 'sync_queue_box';

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Physics Constants (iOS-like)
  static const double springDamping = 0.7;
  static const double springStiffness = 500.0;
}

/// App Colors - Dark theme with gold accents
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);

  // Gold/Coin Colors
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFE55C);
  static const Color goldDark = Color(0xFFB8860B);

  // Accent Colors
  static const Color success = Color(0xFF238636);
  static const Color error = Color(0xFFF85149);
  static const Color warning = Color(0xFFD29922);
  static const Color info = Color(0xFF58A6FF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  // Neumorphic Shadows
  static const Color neumorphicLight = Color(0xFF1F2937);
  static const Color neumorphicDark = Color(0xFF0A0D10);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surfaceLight, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// App Dimensions
class AppDimensions {
  AppDimensions._();

  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Tap Button
  static const double tapButtonSize = 180.0;
  static const double tapButtonIconSize = 100.0;
}
