import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Device service for generating unique device fingerprint
class DeviceService {
  static DeviceService? _instance;
  static DeviceService get instance => _instance ??= DeviceService();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _deviceId;

  /// Initialize and generate device ID
  Future<void> init() async {
    _deviceId = await _generateDeviceId();
  }

  /// Get the unique device ID
  String get deviceId => _deviceId ?? 'unknown';

  /// Generate unique device fingerprint
  Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Combine multiple identifiers for uniqueness
        final fingerprint = [
          androidInfo.id,
          androidInfo.brand,
          androidInfo.device,
          androidInfo.model,
          androidInfo.hardware,
          androidInfo.fingerprint,
        ].join('-');
        return _hashString(fingerprint);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final fingerprint = [
          iosInfo.identifierForVendor ?? '',
          iosInfo.name,
          iosInfo.model,
          iosInfo.systemName,
        ].join('-');
        return _hashString(fingerprint);
      }
    } catch (e) {
      debugPrint('Error generating device ID: $e');
    }
    return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Simple hash function for device fingerprint
  String _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      int char = input.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash.abs().toRadixString(36);
  }

  /// Get device info map for debugging
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'version': info.version.release,
          'brand': info.brand,
          'model': info.model,
          'isPhysicalDevice': info.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'version': info.systemVersion,
          'model': info.model,
          'name': info.name,
          'isPhysicalDevice': info.isPhysicalDevice,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return {'platform': 'Unknown'};
  }
}
