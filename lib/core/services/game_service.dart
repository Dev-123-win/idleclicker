import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/mission_model.dart';

import 'sync_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Game service - handles all game logic, Firestore free tier optimized
/// Uses local-first approach with periodic sync to minimize reads/writes
class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  Timer? _energyRegenTimer;
  Timer? _syncTimer;
  Timer? _autoClickerTimer;

  // Local state for batching
  int _pendingTaps = 0;
  int _pendingCoins = 0;
  bool _isDirty = false;

  // Active mission state
  MissionModel? _activeMission;
  int _missionProgress = 0;

  // Callbacks
  Function(UserModel)? onUserUpdate;
  Function(int)? onTapRegistered;
  Function()? onMissionComplete;
  Function(String)? onError;

  UserModel? get currentUser => _currentUser;
  MissionModel? get activeMission => _activeMission;
  int get missionProgress => _missionProgress;
  bool get isAutoClickerRunning => _autoClickerTimer?.isActive ?? false;

  // ... (existing imports)

  // Remote missions
  List<MissionModel> _remoteMissions = [];

  // Cloudflare Worker URL
  // TODO: Replace with your actual Cloudflare Worker URL
  static const String _workerUrl =
      'https://idleminer-backend.earnplay12345.workers.dev';

  List<MissionModel> get missions =>
      _remoteMissions.isNotEmpty ? _remoteMissions : Missions.all;

  /// Initialize game service with user
  Future<void> initialize(UserModel user) async {
    _currentUser = user;

    // Start energy regeneration timer (every minute)
    _energyRegenTimer?.cancel();
    _energyRegenTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _regenerateEnergy();
    });

    // Initialize SyncService
    await SyncService().initialize(_currentUser!);

    // Load cached state
    await _loadCachedState();

    // Fetch remote missions
    fetchMissions();
  }

  /// Fetch missions from Firestore
  Future<void> fetchMissions() async {
    try {
      final snapshot = await _firestore.collection('missions').get();
      if (snapshot.docs.isNotEmpty) {
        _remoteMissions = snapshot.docs
            .map((doc) => MissionModel.fromFirestore(doc.data()))
            .toList();
        // Sort by tier/difficulty if needed
        notifyListenersOrUpdateUI();
      }
    } catch (e) {
      debugPrint('Failed to fetch missions: $e');
      // Fallback to local missions is automatic via getter
    }
  }

  // Helper to notify (if we add ChangeNotifier later, for now just a placeholder/noop)
  void notifyListenersOrUpdateUI() {
    // implementing a basic callback if needed, or just let the next UI build pick it up
    // Since MissionScreen doesn't listen to GameService changes for the *list* specifically,
    // we might need to reload the screen or use a FutureBuilder.
    // For now, we'll just cache it.
  }

  // ... (rest of the file)

  /// Redeem referral code via Cloudflare Worker
  Future<bool> redeemReferralCode(String code) async {
    if (_currentUser == null) return false;
    if (_currentUser!.referredBy != null) {
      onError?.call(
        'Wait, you\'re all set! You\'ve already redeemed a referral code.',
      );
      return false;
    }
    if (code.toUpperCase() == _currentUser!.referralCode) {
      onError?.call('Nice try! You can\'t redeem your own referral code.');
      return false;
    }

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        onError?.call('Session expired. Please log in again to continue.');
        return false;
      }

      // Call Cloudflare Worker
      final response = await http.post(
        Uri.parse('$_workerUrl/api/referral'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _currentUser!.uid,
          'referralCode': code.toUpperCase(),
          'idToken': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local user state based on server response (optimistic/authoritative mix)
          // Worker returns the bonus amount and success message
          // Ideally we should re-fetch user or sync.
          // But for instant feedback let's update local state if successful

          final bonus = data['bonus'] as int? ?? 1000;
          _currentUser = _currentUser!.copyWith(
            referredBy: code.toUpperCase(),
            appCoins: _currentUser!.appCoins + bonus,
          );
          _isDirty = true;
          await _syncToFirestore(); // Sync the result immediately to ensure consistency
          onUserUpdate?.call(_currentUser!);
          return true;
        } else {
          onError?.call(data['error'] ?? 'Invalid referral code');
          return false;
        }
      } else {
        final data = jsonDecode(response.body);
        onError?.call(data['error'] ?? 'Server error. Please try again.');
        return false;
      }
    } catch (e) {
      onError?.call(
        'We couldn\'t process the referral. Check your connection!',
      );
      return false;
    }
  }

  /// Load cached local state
  Future<void> _loadCachedState() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingTaps = prefs.getInt('pendingTaps') ?? 0;
    _pendingCoins = prefs.getInt('pendingCoins') ?? 0;

    // Apply pending state to user
    if (_pendingTaps > 0 || _pendingCoins > 0) {
      _currentUser = _currentUser?.copyWith(
        totalTaps: (_currentUser?.totalTaps ?? 0) + _pendingTaps,
        appCoins: (_currentUser?.appCoins ?? 0) + _pendingCoins,
      );
      _isDirty = true;
    }
  }

  /// Save state to local cache
  Future<void> _saveCachedState() async {
    if (!_isDirty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pendingTaps', _pendingTaps);
    await prefs.setInt('pendingCoins', _pendingCoins);

    _isDirty = false;
  }

  /// Register a tap
  void registerTap() {
    if (_currentUser == null) return;
    if (_currentUser!.isInMissionCooldown) return;
    if (_activeMission == null) return;

    // Check energy
    final currentEnergy = _currentUser!.getCurrentEnergy();
    if (currentEnergy <= 0) {
      onError?.call(
        'You\'re out of energy! Take a short break or refill with AppCoins.',
      );
      return;
    }

    // Consume energy (0.01 per tap = 1 per 100 taps)
    SyncService().registerTap(coins: 0);
    _missionProgress++;
    _isDirty = true;

    // Update local user state
    if (_pendingTaps % 100 == 0) {
      _currentUser = _currentUser!.copyWith(
        energy: (currentEnergy - 1).clamp(0, _currentUser!.maxEnergy),
        lastEnergyUpdate: DateTime.now(),
      );
    }

    onTapRegistered?.call(_missionProgress);

    // Check for mission completion
    if (_missionProgress >= _activeMission!.tapRequirement) {
      _completeMission();
    }

    // Save every 50 taps
    if (_pendingTaps % 50 == 0) {
      _saveCachedState();
    }
  }

  /// Start a mission
  Future<bool> startMission(MissionModel mission) async {
    if (_currentUser == null) return false;
    if (_currentUser!.isInMissionCooldown) {
      onError?.call(
        'You\'re on cooldown! Wait a bit before starting a new mission.',
      );
      return false;
    }

    // Check tier unlock
    if (!mission.isUnlockedFor(_currentUser!.unlockedTiers)) {
      onError?.call('Unlock more missions to reach this tier!');
      return false;
    }

    // Check energy
    final currentEnergy = _currentUser!.getCurrentEnergy();
    if (currentEnergy < mission.energyCost ~/ 100) {
      onError?.call('Not enough energy for this mission!');
      return false;
    }

    _activeMission = mission;
    _missionProgress = 0;

    return true;
  }

  /// Complete current mission
  void _completeMission() {
    if (_activeMission == null || _currentUser == null) return;

    // Award coins
    _pendingCoins += _activeMission!.acReward;

    // Update missions completed count
    final newMissionsCompleted = _currentUser!.missionsCompleted + 1;

    // Check for tier unlocks
    List<String> newUnlockedTiers = List.from(_currentUser!.unlockedTiers);
    if (newMissionsCompleted >= 5 && !newUnlockedTiers.contains('tier2')) {
      newUnlockedTiers.add('tier2');
    }
    if (newMissionsCompleted >= 15 && !newUnlockedTiers.contains('tier3')) {
      newUnlockedTiers.add('tier3');
    }

    // Calculate cooldown end time with time-of-day multiplier
    final cooldownMultiplier = _getCooldownMultiplier();
    final adjustedCooldown =
        (_activeMission!.cooldownMinutes * cooldownMultiplier).round();
    final cooldownEnd = DateTime.now().add(Duration(minutes: adjustedCooldown));

    _currentUser = _currentUser!.copyWith(
      appCoins: _currentUser!.appCoins + _activeMission!.acReward,
      // totalTaps updated via SyncService
      missionsCompleted: newMissionsCompleted,
      unlockedTiers: newUnlockedTiers,
      missionCooldownEnd: cooldownEnd,
      lastSyncAt: DateTime.now(),
    );

    _activeMission = null;
    _missionProgress = 0;
    _isDirty = true;

    // Immediate sync on mission completion
    _syncToFirestore();

    onMissionComplete?.call();
    onUserUpdate?.call(_currentUser!);
  }

  /// Get cooldown multiplier based on time of day (IST)
  double _getCooldownMultiplier() {
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final hour = now.hour;

    if (hour >= 6 && hour < 12) {
      return 1.2; // Morning: 20% longer
    } else if (hour >= 12 && hour < 18) {
      return 1.0; // Afternoon: standard
    } else if (hour >= 18 && hour < 23) {
      return 0.8; // Evening: 20% shorter
    } else {
      return 2.0; // Night: double
    }
  }

  /// Regenerate energy
  void _regenerateEnergy() {
    if (_currentUser == null) return;

    final newEnergy = _currentUser!.getCurrentEnergy();
    if (newEnergy != _currentUser!.energy) {
      _currentUser = _currentUser!.copyWith(
        energy: newEnergy,
        lastEnergyUpdate: DateTime.now(),
      );
      onUserUpdate?.call(_currentUser!);
    }
  }

  /// Toggle auto-clicker
  void toggleAutoClicker() {
    if (_autoClickerTimer?.isActive ?? false) {
      stopAutoClicker();
    } else {
      startAutoClicker();
    }
  }

  /// Start auto-clicker
  void startAutoClicker() {
    if (_currentUser == null || _activeMission == null) return;
    if (_currentUser!.isInMissionCooldown) return;

    // Calculate interval based on tier
    int tapsPerSecond = 5; // Free tier
    if (_currentUser!.hasPremiumAutoClicker) {
      switch (_currentUser!.autoClickerTier) {
        case 'bronze':
          tapsPerSecond = 8;
          break;
        case 'silver':
          tapsPerSecond = 12;
          break;
        case 'gold':
          tapsPerSecond = 15;
          break;
      }
    }

    final interval = Duration(milliseconds: (1000 / tapsPerSecond).round());

    _autoClickerTimer?.cancel();
    _autoClickerTimer = Timer.periodic(interval, (_) {
      if (_currentUser!.getCurrentEnergy() <= 0) {
        stopAutoClicker();
        onError?.call('Auto-clicker paused: Out of energy!');
        return;
      }
      registerTap();
    });

    _currentUser = _currentUser!.copyWith(autoClickerActive: true);
    onUserUpdate?.call(_currentUser!);
  }

  /// Stop auto-clicker
  void stopAutoClicker() {
    _autoClickerTimer?.cancel();
    _autoClickerTimer = null;

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(autoClickerActive: false);
      onUserUpdate?.call(_currentUser!);
    }
  }

  /// Skip cooldown with AC
  Future<bool> skipCooldownWithAC() async {
    if (_currentUser == null) return false;
    if (!_currentUser!.isInMissionCooldown) return true;

    final remainingMinutes = _currentUser!.remainingMissionCooldown.inMinutes;
    final cost = (remainingMinutes / 5).ceil() * 1000; // 1000 AC per 5 minutes

    if (_currentUser!.appCoins < cost) {
      onError?.call('Not enough AppCoins! Need $cost AC.');
      return false;
    }

    _currentUser = _currentUser!.copyWith(
      appCoins: _currentUser!.appCoins - cost,
      missionCooldownEnd: null,
    );

    _isDirty = true;
    await _syncToFirestore();
    onUserUpdate?.call(_currentUser!);

    return true;
  }

  /// Refill energy with AC
  Future<bool> refillEnergyWithAC() async {
    if (_currentUser == null) return false;

    const cost = 2000; // 2000 AC for 50 energy
    if (_currentUser!.appCoins < cost) {
      onError?.call('You need $cost AC for an energy refill.');
      return false;
    }

    final newEnergy = (_currentUser!.getCurrentEnergy() + 50).clamp(
      0,
      _currentUser!.maxEnergy,
    );

    _currentUser = _currentUser!.copyWith(
      appCoins: _currentUser!.appCoins - cost,
      energy: newEnergy,
      lastEnergyUpdate: DateTime.now(),
    );

    _isDirty = true;
    await _syncToFirestore();
    onUserUpdate?.call(_currentUser!);

    return true;
  }

  /// Force sync via SyncService
  Future<void> _syncToFirestore() async {
    if (_currentUser == null) return;
    await SyncService().forceSync(_currentUser!);
    _saveCachedState();
  }

  /// Force sync (e.g., on app close)
  Future<void> forceSync() async {
    await _syncToFirestore();
  }

  /// Skip cooldown by watching an ad
  void skipCooldownWithAd() {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(missionCooldownEnd: null);

    _isDirty = true;
    _syncToFirestore();
    onUserUpdate?.call(_currentUser!);
  }

  /// Skip cooldown by paying coins
  void skipCooldownWithCoins(int cost) {
    if (_currentUser == null) return;
    if (_currentUser!.appCoins < cost) return;

    _currentUser = _currentUser!.copyWith(
      appCoins: _currentUser!.appCoins - cost,
      missionCooldownEnd: null,
    );

    _isDirty = true;
    _syncToFirestore();
    onUserUpdate?.call(_currentUser!);
  }

  /// Update user's UPI ID
  Future<void> updateUpiId(String upiId) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(upiId: upiId);

    _isDirty = true;
    await _syncToFirestore();
    onUserUpdate?.call(_currentUser!);
  }

  /// Request withdrawal via Cloudflare Worker
  Future<bool> requestWithdrawal({
    required int amount,
    required String upiId,
  }) async {
    if (_currentUser == null) return false;
    if (_currentUser!.appCoins < amount) {
      onError?.call(
        'You don\'t have enough balance yet! Keep mining to reach ₹100.',
      );
      return false;
    }

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        onError?.call('Your session has timed out. Please log in again.');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_workerUrl/api/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _currentUser!.uid,
          'amount': amount,
          'upiId': upiId,
          'idToken': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local state - verify if server also deducted or waiting for separate sync
          // The worker handles the deduction in Firestore.
          // We should optimistically deduct here to reflect UI immediately
          _currentUser = _currentUser!.copyWith(
            appCoins: _currentUser!.appCoins - amount,
          );
          onUserUpdate?.call(_currentUser!);

          // Sync to ensure state matches (though worker just updated it, so maybe just fetch?)
          // Actually, since worker updated it, our local state is now stale compared to server if we rely on next sync.
          // But we just manually updated it to match what we expect.
          // Let's force a fetch just in case or wait for next sync.
          return true;
        } else {
          onError?.call(
            data['error'] ?? 'Withdrawal failed. Please check your UPI ID.',
          );
          return false;
        }
      } else {
        final data = jsonDecode(response.body);
        onError?.call(
          data['error'] ??
              'Our withdrawal service is temporarily busy. Try again shortly.',
        );
        return false;
      }
    } catch (e) {
      onError?.call(
        'Something went wrong with the withdrawal. Check your connection!',
      );
      return false;
    }
  }

  /// Dispose timers
  void dispose() {
    _energyRegenTimer?.cancel();
    _syncTimer?.cancel();
    _autoClickerTimer?.cancel();
    _saveCachedState();
    _syncToFirestore();
  }
}
