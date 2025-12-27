import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/mission_model.dart';
import '../core/constants.dart';

/// Hive local storage service
class HiveService {
  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  late Box<UserModel> _userBox;
  late Box<dynamic> _settingsBox;
  late Box<Map<dynamic, dynamic>> _syncQueueBox;

  bool _initialized = false;

  /// Initialize Hive and register adapters
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MissionModelAdapter());
    }

    // Open boxes
    _userBox = await Hive.openBox<UserModel>(AppConstants.userBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _syncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>(
      AppConstants.syncQueueBox,
    );

    _initialized = true;
  }

  /// Get user box
  Box<UserModel> get userBox => _userBox;

  /// Get settings box
  Box<dynamic> get settingsBox => _settingsBox;

  /// Get sync queue box
  Box<Map<dynamic, dynamic>> get syncQueueBox => _syncQueueBox;

  // ============ User Methods ============

  /// Save user to local storage
  Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', user);
  }

  /// Get current user from local storage
  UserModel? getUser() {
    return _userBox.get('current_user');
  }

  /// Delete current user
  Future<void> deleteUser() async {
    await _userBox.delete('current_user');
  }

  /// Check if user exists
  bool hasUser() {
    return _userBox.containsKey('current_user');
  }

  // ============ Settings Methods ============

  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // ============ Sync Queue Methods ============

  /// Add data to sync queue
  Future<void> addToSyncQueue(Map<String, dynamic> data) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _syncQueueBox.put(timestamp, data);
  }

  /// Get all pending sync items
  List<Map<String, dynamic>> getPendingSyncItems() {
    return _syncQueueBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Clear sync queue after successful sync
  Future<void> clearSyncQueue() async {
    await _syncQueueBox.clear();
  }

  /// Get sync queue count
  int get syncQueueCount => _syncQueueBox.length;

  // ============ Cleanup ============

  /// Close all boxes
  Future<void> close() async {
    await _userBox.close();
    await _settingsBox.close();
    await _syncQueueBox.close();
  }

  /// Clear all data (for logout)
  Future<void> clearAll() async {
    await _userBox.clear();
    await _settingsBox.clear();
    await _syncQueueBox.clear();
  }
}
