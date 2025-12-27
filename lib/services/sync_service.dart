import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'hive_service.dart';
import 'security_service.dart';
import 'service_locator.dart';

/// Sync service for 3-hour interval data synchronization with security
class SyncService {
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  final String _workerUrl = AppConstants.workerBaseUrl;
  final Set<String> _usedNonces = {}; // Track used nonces

  /// Start periodic sync timer
  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(hours: AppConstants.syncIntervalHours),
      (_) => sync(),
    );
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Perform sync with security measures
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;

    try {
      final user = getService<HiveService>().getUser();
      if (user == null) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'No user to sync');
      }

      final security = getService<SecurityService>();

      // Check device security
      if (!security.isSecure && !kDebugMode) {
        _isSyncing = false;
        return SyncResult(
          success: false,
          message: 'Device security check failed',
        );
      }

      // Generate timestamp and nonce
      final timestamp = DateTime.now().toIso8601String();
      final nonce = security.generateNonce();

      // Validate local data before sending
      if (_lastSyncTime != null) {
        final previousUser = getService<HiveService>()
            .getSetting<Map<String, dynamic>>('last_sync_user');
        if (previousUser != null) {
          final isValid = security.validateCoinsProgress(
            previousCoins: previousUser['totalCoins'] ?? 0,
            currentCoins: user.totalCoins,
            previousTaps: previousUser['totalTaps'] ?? 0,
            currentTaps: user.totalTaps,
            timePassed: DateTime.now().difference(_lastSyncTime!),
          );

          if (!isValid) {
            debugPrint('Local data validation failed - possible tampering');
            _isSyncing = false;
            return SyncResult(
              success: false,
              message: 'Data validation failed',
            );
          }
        }
      }

      // Get pending sync items
      final pendingItems = getService<HiveService>().getPendingSyncItems();

      // Prepare sync payload
      final payload = {
        'userId': user.uid,
        'deviceId': user.deviceId,
        'deviceFingerprint': security.deviceFingerprint,
        'data': user.toJson(),
        'pendingItems': pendingItems,
        'timestamp': timestamp,
        'nonce': nonce,
        'appSignature': security.appSignature,
      };

      // Generate request signature
      final payloadString = jsonEncode(payload);
      final signature = security.signRequest(
        userId: user.uid,
        timestamp: timestamp,
        payload: payloadString,
        secret: AppConstants.syncSecret, // Add to constants
      );

      // Send to Cloudflare Worker with security headers
      final response = await http
          .post(
            Uri.parse('$_workerUrl/api/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${user.uid}',
              'X-Timestamp': timestamp,
              'X-Nonce': nonce,
              'X-Signature': signature,
              'X-Device-Fingerprint': security.deviceFingerprint,
            },
            body: payloadString,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Verify response nonce (anti-replay)
        final responseNonce = response.headers['x-response-nonce'];
        if (responseNonce != null && _usedNonces.contains(responseNonce)) {
          throw Exception('Replay attack detected');
        }
        if (responseNonce != null) {
          _usedNonces.add(responseNonce);
          // Keep nonce cache manageable
          if (_usedNonces.length > 1000) {
            _usedNonces.clear();
          }
        }

        // Update local user with server data if needed
        if (responseData['user'] != null) {
          final serverUser = UserModel.fromJson(responseData['user']);
          await getService<HiveService>().saveUser(serverUser);
        }

        // Store current user state for next validation
        await getService<HiveService>().saveSetting('last_sync_user', {
          'totalCoins': user.totalCoins,
          'totalTaps': user.totalTaps,
        });

        // Clear sync queue
        await getService<HiveService>().clearSyncQueue();

        _lastSyncTime = DateTime.now();
        _isSyncing = false;

        return SyncResult(
          success: true,
          message: 'Sync successful',
          lastSyncTime: _lastSyncTime,
        );
      } else if (response.statusCode == 403) {
        throw Exception('Security verification failed');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded');
      } else {
        throw Exception('Sync failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      _isSyncing = false;
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  /// Force immediate sync
  Future<SyncResult> forceSync() async {
    return sync();
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if sync is needed
  bool get needsSync {
    if (_lastSyncTime == null) return true;
    final hoursSinceSync = DateTime.now().difference(_lastSyncTime!).inHours;
    return hoursSinceSync >= AppConstants.syncIntervalHours;
  }

  /// Listen to withdrawal status changes from Firestore
  StreamSubscription<DocumentSnapshot>? listenToWithdrawalStatus(
    String userId,
    void Function(String status) onStatusChanged,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final status = data?['withdrawalStatus'] as String?;
            if (status != null) {
              onStatusChanged(status);
            }
          }
        });
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final DateTime? lastSyncTime;

  SyncResult({required this.success, required this.message, this.lastSyncTime});
}
