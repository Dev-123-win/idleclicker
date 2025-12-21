import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';

/// Optimized Sync Service for Firestore Free Tier
/// Features:
/// - Optimistic UI updates (instant response)
/// - Batched backend sync at intervals
/// - Offline queue with retry
/// - Checksum validation
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Cloudflare Worker URL - Replace with your actual URL
  static const String _workerBaseUrl =
      'https://idleminer-backend.earnplay12345.workers.dev';
  static const String _syncSecret = 'super_secure_sync_secret_123';

  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 10);
  static const int _maxOfflineQueueSize = 100;

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  List<Map<String, dynamic>> _offlineQueue = [];

  // Local state tracking
  int _pendingTaps = 0;
  int _pendingCoins = 0;
  // Callbacks
  Function(bool success, String? error)? onSyncComplete;
  Function(bool isOnline)? onConnectivityChange;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingChanges => _pendingTaps + _pendingCoins;

  /// Initialize sync service
  Future<void> initialize(UserModel user) async {
    // Load cached state
    await _loadOfflineQueue();

    // Start sync timer
    _startSyncTimer(user);

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      onConnectivityChange?.call(isOnline);

      if (isOnline && _offlineQueue.isNotEmpty) {
        _processOfflineQueue(user);
      }
    });
  }

  /// Start periodic sync timer
  void _startSyncTimer(UserModel user) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _performSync(user);
    });
  }

  /// Register optimistic tap update
  void registerTap({int coins = 1}) {
    _pendingTaps++;
    _pendingCoins += coins;
  }

  /// Perform sync to backend
  Future<SyncResult> _performSync(UserModel user) async {
    if (_isSyncing || (_pendingTaps == 0 && _pendingCoins == 0)) {
      return SyncResult(success: true, noChanges: true);
    }

    _isSyncing = true;

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _queueOfflineSync(user);
        return SyncResult(success: false, error: 'No internet connection');
      }

      // Prepare sync data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newTotalTaps = user.totalTaps + _pendingTaps;
      final newTotalCoins = user.appCoins + _pendingCoins;

      final syncData = {
        'userId': user.uid,
        'totalTaps': newTotalTaps,
        'appCoins': newTotalCoins,
        'energy': user.getCurrentEnergy(),
        'missionsCompleted': user.missionsCompleted,
        'upiId': user.upiId,
        'hapticSetting': user.hapticSetting,
        'autoClickerActive': user.autoClickerActive,
        'clientTimestamp': timestamp,
        'checksum': _generateChecksum(
          user.uid,
          newTotalTaps,
          newTotalCoins,
          timestamp,
        ),
      };

      // Send to Cloudflare Worker
      final response = await http
          .post(
            Uri.parse('$_workerBaseUrl/api/sync'),
            headers: {
              'Content-Type': 'application/json',
              'X-Sync-Secret': _syncSecret,
            },
            body: jsonEncode(syncData),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Success - clear pending
        _pendingTaps = 0;
        _pendingCoins = 0;
        _lastSyncTime = DateTime.now();

        await _clearCachedPending();

        onSyncComplete?.call(true, null);
        return SyncResult(success: true);
      } else if (response.statusCode == 429) {
        // Rate limited
        final data = jsonDecode(response.body);
        return SyncResult(
          success: false,
          error: 'Rate limited',
          retryAfter: Duration(milliseconds: data['retryAfter'] ?? 60000),
        );
      } else {
        // Other error - queue for retry
        _queueOfflineSync(user);
        return SyncResult(
          success: false,
          error: 'Connection unstable. We\'ll try syncing again in a moment!',
        );
      }
    } catch (e) {
      _queueOfflineSync(user);
      return SyncResult(
        success: false,
        error:
            'Heads up! We\'re having trouble connecting to the server. Your progress is saved locally.',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Force immediate sync
  Future<SyncResult> forceSync(UserModel user) async {
    return await _performSync(user);
  }

  /// Queue sync for offline processing
  void _queueOfflineSync(UserModel user) {
    if (_offlineQueue.length >= _maxOfflineQueueSize) {
      _offlineQueue.removeAt(0); // Remove oldest
    }

    _offlineQueue.add({
      'userId': user.uid,
      'pendingTaps': _pendingTaps,
      'pendingCoins': _pendingCoins,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _saveOfflineQueue();
  }

  /// Process offline queue when back online
  Future<void> _processOfflineQueue(UserModel user) async {
    if (_offlineQueue.isEmpty) return;

    // Aggregate all offline changes
    int totalTaps = 0;
    int totalCoins = 0;

    for (final item in _offlineQueue) {
      totalTaps += item['pendingTaps'] as int;
      totalCoins += item['pendingCoins'] as int;
    }

    // Add to pending and sync
    _pendingTaps += totalTaps;
    _pendingCoins += totalCoins;
    _offlineQueue.clear();

    await _saveOfflineQueue();
    await _performSync(user);
  }

  /// Generate checksum for anti-tamper
  String _generateChecksum(String userId, int taps, int coins, int timestamp) {
    final data = '$userId:$taps:$coins:$timestamp';
    int hash = 0;
    for (int i = 0; i < data.length; i++) {
      final char = data.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & 0x7FFFFFFF;
    }
    return hash.toRadixString(36);
  }

  /// Save offline queue to local storage
  Future<void> _saveOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offlineQueue', jsonEncode(_offlineQueue));
  }

  /// Load offline queue from local storage
  Future<void> _loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString('offlineQueue');
    if (queueJson != null) {
      _offlineQueue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
    }
  }

  /// Clear cached pending state
  Future<void> _clearCachedPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pendingTaps');
    await prefs.remove('pendingCoins');
  }

  /// Dispose sync service
  void dispose() {
    _syncTimer?.cancel();
    _saveOfflineQueue();
  }
}

/// Sync result model
class SyncResult {
  final bool success;
  final bool noChanges;
  final String? error;
  final Duration? retryAfter;

  SyncResult({
    required this.success,
    this.noChanges = false,
    this.error,
    this.retryAfter,
  });
}
