import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/constants.dart';

/// Security service for app-side protections
class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();

  SecurityService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _appSignature;
  String? _deviceFingerprint;
  bool _isSecure = true;
  final List<String> _securityIssues = [];

  /// Initialize security checks
  Future<void> init() async {
    await _generateAppSignature();
    await _generateDeviceFingerprint();
    await _performSecurityChecks();
  }

  /// Get app signature for request signing
  String get appSignature => _appSignature ?? '';

  /// Get device fingerprint
  String get deviceFingerprint => _deviceFingerprint ?? '';

  /// Check if device is secure
  bool get isSecure => _isSecure;

  /// Get list of security issues
  List<String> get securityIssues => List.unmodifiable(_securityIssues);

  /// Generate app signature from package info
  Future<void> _generateAppSignature() async {
    try {
      // Generate signature from build info
      final buildData = [
        AppConstants.appName,
        AppConstants.appVersion,
        DateTime.now().millisecondsSinceEpoch.toString(),
      ].join('|');

      _appSignature = _hashString(buildData);
    } catch (e) {
      debugPrint('Error generating app signature: $e');
      _appSignature = 'unknown';
    }
  }

  /// Generate unique device fingerprint
  Future<void> _generateDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final data = [
          info.id,
          info.brand,
          info.model,
          info.device,
          info.hardware,
          info.product,
          info.fingerprint,
          info.bootloader,
          info.board,
        ].join('|');
        _deviceFingerprint = _hashString(data);
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final data = [
          info.identifierForVendor ?? '',
          info.name,
          info.model,
          info.systemName,
          info.systemVersion,
        ].join('|');
        _deviceFingerprint = _hashString(data);
      }
    } catch (e) {
      debugPrint('Error generating device fingerprint: $e');
      _deviceFingerprint = 'unknown';
    }
  }

  /// Perform all security checks
  Future<void> _performSecurityChecks() async {
    _securityIssues.clear();
    _isSecure = true;

    // Check for root/jailbreak
    final isRooted = await _checkRootAccess();
    if (isRooted) {
      _securityIssues.add('Device appears to be rooted/jailbroken');
      _isSecure = false;
    }

    // Check for debugger
    final isDebugged = _checkDebugger();
    if (isDebugged && !kDebugMode) {
      _securityIssues.add('Debugger detected');
      _isSecure = false;
    }

    // Check for emulator
    final isEmulator = await _checkEmulator();
    if (isEmulator && !kDebugMode) {
      _securityIssues.add('Running on emulator');
      // Don't mark as insecure for emulator, just log
    }

    // Check for hooking frameworks
    final hasHooks = await _checkHookingFrameworks();
    if (hasHooks) {
      _securityIssues.add('Hooking framework detected');
      _isSecure = false;
    }

    debugPrint('Security check complete. Secure: $_isSecure');
    if (_securityIssues.isNotEmpty) {
      debugPrint('Issues: ${_securityIssues.join(', ')}');
    }
  }

  /// Check for root/jailbreak access
  Future<bool> _checkRootAccess() async {
    if (Platform.isAndroid) {
      return await _checkAndroidRoot();
    } else if (Platform.isIOS) {
      return await _checkIOSJailbreak();
    }
    return false;
  }

  /// Check Android root indicators
  Future<bool> _checkAndroidRoot() async {
    // Check for common root paths
    final rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
      '/system/app/SuperSU',
      '/system/app/SuperSU.apk',
      '/system/etc/init.d/99teletext',
      '/data/adb/modules',
      '/system/xbin/magisk',
    ];

    for (final path in rootPaths) {
      if (await File(path).exists()) {
        return true;
      }
    }

    // Check for root packages
    try {
      final result = await Process.run('which', ['su']);
      if (result.exitCode == 0) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Check iOS jailbreak indicators
  Future<bool> _checkIOSJailbreak() async {
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/usr/bin/ssh',
      '/private/var/stash',
      '/private/var/lib/cydia',
      '/usr/libexec/sftp-server',
    ];

    for (final path in jailbreakPaths) {
      if (await File(path).exists()) {
        return true;
      }
    }

    // Check if app can write to system directories
    try {
      final testFile = File('/private/jb_test_file');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true; // If we can write, device is jailbroken
    } catch (_) {}

    return false;
  }

  /// Check for debugger attachment
  bool _checkDebugger() {
    // In release mode, assert is removed, so this is a simple check
    bool isDebugging = false;
    assert(() {
      isDebugging = true;
      return true;
    }());
    return isDebugging;
  }

  /// Check if running on emulator
  Future<bool> _checkEmulator() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return !info.isPhysicalDevice ||
          info.brand.toLowerCase() == 'generic' ||
          info.model.toLowerCase().contains('sdk') ||
          info.model.toLowerCase().contains('emulator') ||
          info.fingerprint.contains('generic');
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return !info.isPhysicalDevice;
    }
    return false;
  }

  /// Check for hooking frameworks (Frida, Xposed, etc.)
  Future<bool> _checkHookingFrameworks() async {
    if (Platform.isAndroid) {
      // Check for Xposed
      final xposedPaths = [
        '/system/framework/XposedBridge.jar',
        '/system/bin/app_process.orig',
        '/system/bin/app_process_xposed',
      ];

      for (final path in xposedPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Check for Frida
      try {
        final result = await Process.run('ps', []);
        if (result.stdout.toString().contains('frida')) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// Generate HMAC signature for API requests
  String signRequest({
    required String userId,
    required String timestamp,
    required String payload,
    required String secret,
  }) {
    final dataToSign = '$userId|$timestamp|$payload';
    final key = utf8.encode(secret);
    final data = utf8.encode(dataToSign);

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);

    return digest.toString();
  }

  /// Verify request timestamp is within acceptable window
  bool verifyTimestamp(String timestamp, {int maxAgeSeconds = 300}) {
    try {
      final requestTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(requestTime).inSeconds.abs();
      return diff <= maxAgeSeconds;
    } catch (_) {
      return false;
    }
  }

  /// Generate secure random nonce
  String generateNonce({int length = 32}) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Hash string using SHA256
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Encrypt sensitive data for local storage
  String encryptData(String data, String key) {
    // Simple XOR encryption for local data
    // For production, use proper encryption like AES
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final result = List<int>.filled(dataBytes.length, 0);

    for (int i = 0; i < dataBytes.length; i++) {
      result[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    return base64.encode(result);
  }

  /// Decrypt sensitive data from local storage
  String decryptData(String encrypted, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = base64.decode(encrypted);
    final result = List<int>.filled(dataBytes.length, 0);

    for (int i = 0; i < dataBytes.length; i++) {
      result[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    return utf8.decode(result);
  }

  /// Validate coin count is reasonable
  bool validateCoinsProgress({
    required int previousCoins,
    required int currentCoins,
    required int previousTaps,
    required int currentTaps,
    required Duration timePassed,
  }) {
    // Check for negative values
    if (currentCoins < 0 || currentTaps < 0) {
      return false;
    }

    // Check coins didn't decrease (unless withdrawal)
    if (currentCoins < previousCoins - 100000) {
      // Allow up to 100k decrease for withdrawal
      return false;
    }

    // Check taps are reasonable for time passed
    final hours = timePassed.inHours;
    final maxTapsPerHour = 3600; // 1 tap per second max
    final maxPossibleTaps = (hours + 1) * maxTapsPerHour;

    final tapsDiff = currentTaps - previousTaps;
    if (tapsDiff > maxPossibleTaps) {
      return false;
    }

    // Check coins match taps (roughly)
    // This is approximate since missions give different rewards
    final coinsDiff = currentCoins - previousCoins;
    final maxCoinsPerTap = 100; // Very generous limit
    if (coinsDiff > tapsDiff * maxCoinsPerTap) {
      return false;
    }

    return true;
  }
}
