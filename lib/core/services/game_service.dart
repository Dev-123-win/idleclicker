import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/mission_model.dart';

import 'sync_service.dart';
import 'ad_service.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Game service - handles all game logic, Firestore free tier optimized
/// Uses local-first approach with periodic sync to minimize reads/writes
class GameService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  Timer? _energyRegenTimer;
  Timer? _syncTimer;
  Timer? _autoClickerTimer;
  Timer? _dailyFreeTimer;

  // Local state for auto-clicker
  int _dailyFreeSecondsRemaining = 0;
  int _adBoostSecondsRemaining = 0;
  DateTime? _lastFreeReset;

  // Active mission state
  MissionModel? _activeMission;
  int _missionProgress = 0;

  // Penalty state
  DateTime? _penaltyEndTime;

  // Callbacks
  Function(int)? onTapRegistered;
  Function(int)? onMissionComplete;
  Function(String)? onError;
  Function()? onAutoClickerUpdate;

  UserModel? get currentUser => _currentUser;
  MissionModel? get activeMission => _activeMission;
  int get missionProgress => _missionProgress;
  bool get isAutoClickerRunning => _autoClickerTimer?.isActive ?? false;
  int get dailyFreeSecondsRemaining => _dailyFreeSecondsRemaining;
  int get adBoostSecondsRemaining => _adBoostSecondsRemaining;

  bool get isPenaltyActive =>
      _penaltyEndTime != null && DateTime.now().isBefore(_penaltyEndTime!);
  Duration get penaltyRemaining => isPenaltyActive
      ? _penaltyEndTime!.difference(DateTime.now())
      : Duration.zero;
  bool get isBoostActive => _adBoostSecondsRemaining > 0;
  Duration get boostRemaining => Duration(seconds: _adBoostSecondsRemaining);

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

    // Setup AdService callbacks
    final adService = AdService();
    adService.onAdFastClosed = () {
      _activatePenalty();
    };

    adService.onAdStarted = () {
      if (isAutoClickerRunning) {
        stopAutoClicker();
      }
    };

    // Load Auto-Clicker Local State
    await _loadAutoClickerLocalState();

    adService.onAdCompleted = () {
      if (isBoostActive || (_currentUser?.autoClickerActive ?? false)) {
        startAutoClicker();
      }
    };
  }

  Future<void> _loadAutoClickerLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('last_autoclicker_reset');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastResetStr != null) {
      _lastFreeReset = DateTime.parse(lastResetStr);
      if (_lastFreeReset!.isBefore(today)) {
        // Reset for new day
        _dailyFreeSecondsRemaining = 600; // 10 mins
        _lastFreeReset = today;
      } else {
        _dailyFreeSecondsRemaining =
            prefs.getInt('daily_free_seconds_remaining') ?? 600;
      }
    } else {
      _dailyFreeSecondsRemaining = 600;
      _lastFreeReset = today;
    }

    _adBoostSecondsRemaining = prefs.getInt('ad_boost_seconds_remaining') ?? 0;
    await _saveAutoClickerLocalState();
    onAutoClickerUpdate?.call();
  }

  Future<void> _saveAutoClickerLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_autoclicker_reset',
      _lastFreeReset?.toIso8601String() ?? '',
    );
    await prefs.setInt(
      'daily_free_seconds_remaining',
      _dailyFreeSecondsRemaining,
    );
    await prefs.setInt('ad_boost_seconds_remaining', _adBoostSecondsRemaining);
  }

  void _activatePenalty() {
    _penaltyEndTime = DateTime.now().add(const Duration(seconds: 30));
    stopAutoClicker();
    onError?.call('Unusual activity detected. System syncing (30s)...');
    notifyListenersOrUpdateUI();
  }

  Future<void> bypassPenaltyWithAd() async {
    final result = await AdService().showRewardedAd();
    if (result.isSuccess) {
      _penaltyEndTime = null;
      notifyListenersOrUpdateUI();
    }
  }

  /// Fetch missions from Firestore
  Future<void> fetchMissions() async {
    try {
      final snapshot = await _firestore.collection('missions').get();
      if (snapshot.docs.isNotEmpty) {
        _remoteMissions = snapshot.docs
            .map((doc) => MissionModel.fromFirestore(doc.data()))
            .toList();

        // Restore active mission if ID was cached
        final prefs = await SharedPreferences.getInstance();
        final savedId = prefs.getString('activeMissionId');
        if (savedId != null && _activeMission == null) {
          try {
            _activeMission = missions.firstWhere((m) => m.id == savedId);
          } catch (_) {}
        }

        notifyListenersOrUpdateUI();
      }
    } catch (e) {
      debugPrint('Failed to fetch missions: $e');
    }
  }

  // Helper to notify (if we add ChangeNotifier later, for now just a placeholder/noop)
  void notifyListenersOrUpdateUI() {
    notifyListeners();
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
          'deviceId': _currentUser!.deviceId,
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
          await _syncToFirestore(); // Sync the result immediately to ensure consistency
          notifyListeners();
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
    // Load pending state from SyncService for optimistic UI
    await SyncService().loadCachedPending();

    final pendingTaps = SyncService().pendingTaps;
    final pendingCoins = SyncService().pendingCoins;

    if (pendingTaps > 0 || pendingCoins > 0) {
      _currentUser = _currentUser?.copyWith(
        totalTaps: (_currentUser?.totalTaps ?? 0) + pendingTaps,
        appCoins: (_currentUser?.appCoins ?? 0) + pendingCoins,
      );
    }

    // Load mission progress
    final prefs = await SharedPreferences.getInstance();
    final missionId = prefs.getString('activeMissionId');
    if (missionId != null) {
      // Find mission by ID (this assumes missions are already fetched or we'll set it when they are)
      _missionProgress = prefs.getInt('missionProgress') ?? 0;
    }
  }

  /// Save state to local cache
  Future<void> _saveCachedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeMission != null) {
      await prefs.setString('activeMissionId', _activeMission!.id);
      await prefs.setInt('missionProgress', _missionProgress);
    } else {
      await prefs.remove('activeMissionId');
      await prefs.remove('missionProgress');
    }
  }

  /// Register a tap
  void registerTap({bool isAuto = false}) {
    if (_currentUser == null) return;
    if (isPenaltyActive) return;
    if (AdService().isAdShowing) return; // DON'T register taps during ads
    if (_currentUser!.isInMissionCooldown) {
      if (isAuto) stopAutoClicker();
      return;
    }
    if (_activeMission == null) {
      if (isAuto) stopAutoClicker();
      return;
    }

    // Check energy
    final currentEnergy = _currentUser!.getCurrentEnergy();
    if (currentEnergy <= 0) {
      if (isAutoClickerRunning) {
        stopAutoClicker();
        onError?.call('Auto-clicker paused: Out of energy!');
      } else {
        HapticFeedback.mediumImpact();
        onError?.call(
          'You\'re out of energy! Take a short break or refill with AppCoins.',
        );
      }
      return;
    }

    // Consume energy (0.01 per tap = 1 per 100 taps)
    SyncService().registerTap(taps: 1, coins: 0);
    _missionProgress++;

    // Trigger Mission Ads
    if (_activeMission!.adCheckpoints.contains(_missionProgress)) {
      AdService().showInterstitialAd();
    }

    // Trigger Haptic Feedback based on setting
    _triggerHapticFeedback(isAuto: isAuto);

    // Update local user state
    if (_missionProgress % 100 == 0) {
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
    if (_missionProgress % 50 == 0) {
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

    // Enable wakelock when mission is active to keep screen on
    WakelockPlus.enable();

    _saveCachedState();

    return true;
  }

  /// Complete current mission
  void _completeMission() {
    if (_activeMission == null || _currentUser == null) return;

    // Award coins
    SyncService().registerTap(taps: 0, coins: _activeMission!.acReward);

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

    // Track completed mission for 30-day cooldown
    Map<String, DateTime> newCompletedMissions = Map.from(
      _currentUser!.completedMissions,
    );
    newCompletedMissions[_activeMission!.id] = DateTime.now();

    _currentUser = _currentUser!.copyWith(
      appCoins: _currentUser!.appCoins + _activeMission!.acReward,
      missionsCompleted: newMissionsCompleted,
      unlockedTiers: newUnlockedTiers,
      completedMissions: newCompletedMissions,
      missionCooldownEnd: cooldownEnd,
      lastSyncAt: DateTime.now(),
    );

    final reward = _activeMission!.acReward;

    _activeMission = null;
    _missionProgress = 0;

    // Disable wakelock when mission completed
    WakelockPlus.disable();

    // Immediate sync on mission completion
    _syncToFirestore();

    onMissionComplete?.call(reward);
    notifyListeners();
    _saveCachedState();
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
      notifyListeners();
    }
  }

  /// Trigger haptic feedback based on user preference
  void _triggerHapticFeedback({bool isAuto = false}) {
    if (_currentUser == null) return;

    // Don't vibrate for AutoClicker if in ECO mode
    if (isAuto && _currentUser!.hapticSetting == 'eco') {
      if (_missionProgress % 10 == 0) {
        HapticFeedback.lightImpact();
      }
      return;
    }

    switch (_currentUser!.hapticSetting) {
      case 'strong':
        HapticFeedback.mediumImpact();
        break;
      case 'eco':
        HapticFeedback.lightImpact();
        break;
      case 'off':
      default:
        break;
    }
  }

  /// Update user's haptic preference
  Future<void> updateUserHaptic(String setting) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(hapticSetting: setting);
    await _syncToFirestore();
    notifyListeners();
  }

  /// Toggle auto-clicker
  void toggleAutoClicker() {
    if (_autoClickerTimer?.isActive ?? false) {
      stopAutoClicker();
    } else {
      startAutoClicker();
    }
  }

  /// Start auto-clicker with 5 taps/sec limit
  void startAutoClicker() {
    if (_currentUser == null || _activeMission == null) return;
    if (_currentUser!.isInMissionCooldown) return;
    if (AdService().isAdShowing) return;
    if (_dailyFreeSecondsRemaining <= 0 && _adBoostSecondsRemaining <= 0) {
      onError?.call('Free Daily usage finished. Watch an ad for +10 minutes!');
      return;
    }

    const tapsPerSecond = 5;
    final interval = Duration(milliseconds: (1000 / tapsPerSecond).round());

    _autoClickerTimer?.cancel();
    _autoClickerTimer = Timer.periodic(interval, (_) {
      if (_currentUser!.getCurrentEnergy() <= 0) {
        stopAutoClicker();
        onError?.call('Auto-clicker paused: Out of energy!');
        return;
      }
      registerTap(isAuto: true);
    });

    // Start consumption timer
    _dailyFreeTimer?.cancel();
    _dailyFreeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_dailyFreeSecondsRemaining > 0) {
        _dailyFreeSecondsRemaining--;
      } else if (_adBoostSecondsRemaining > 0) {
        _adBoostSecondsRemaining--;
      } else {
        stopAutoClicker();
        onError?.call('Daily time over! Watch an ad to continue.');
      }

      _saveAutoClickerLocalState();
      onAutoClickerUpdate?.call();
    });

    _currentUser = _currentUser!.copyWith(autoClickerActive: true);
    notifyListeners();
  }

  /// Stop auto-clicker
  void stopAutoClicker() {
    _autoClickerTimer?.cancel();
    _autoClickerTimer = null;
    _dailyFreeTimer?.cancel();
    _dailyFreeTimer = null;

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(autoClickerActive: false);
      notifyListeners();
    }
    onAutoClickerUpdate?.call();
    _saveAutoClickerLocalState();
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

    await _syncToFirestore();
    notifyListeners();

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
    await _syncToFirestore();
    notifyListeners();

    return true;
  }

  /// Ad-Value Exchange: Skip Taps (Watch Ad = -300 Taps)
  Future<void> skipTapsByWatchingAd() async {
    if (_activeMission == null || isPenaltyActive) return;

    final result = await AdService().showRewardedAd();
    if (result.isSuccess) {
      _missionProgress = (_missionProgress + 300).clamp(
        0,
        _activeMission!.tapRequirement,
      );
      onTapRegistered?.call(_missionProgress);

      if (_missionProgress >= _activeMission!.tapRequirement) {
        _completeMission();
      }
    }
  }

  /// Ad-Value Exchange: Auto-Clicker Boost (Watch Ad = 10 Mins)
  Future<void> activateBoostByWatchingAd() async {
    if (isPenaltyActive) return;

    final result = await AdService().showRewardedAd();
    if (result.isSuccess) {
      _adBoostSecondsRemaining += 600; // 10 minutes
      _saveAutoClickerLocalState();
      onAutoClickerUpdate?.call();

      // Auto-start if mission is active
      if (_activeMission != null) {
        startAutoClicker();
      }
    }
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
    _syncToFirestore();
    notifyListeners();
  }

  /// Skip cooldown by paying coins
  void skipCooldownWithCoins(int cost) {
    if (_currentUser == null) return;
    if (_currentUser!.appCoins < cost) return;

    _currentUser = _currentUser!.copyWith(
      appCoins: _currentUser!.appCoins - cost,
      missionCooldownEnd: null,
    );

    _syncToFirestore();
    notifyListeners();
  }

  /// Update user's UPI ID
  Future<void> updateUpiId(String upiId) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(upiId: upiId);
    await _syncToFirestore();
    notifyListeners();
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
          'deviceId': _currentUser!.deviceId,
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
          notifyListeners();

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

  /// Fetch genuine leaderboard data - Updates only once every 24 hours (Free Tier Optimized)
  Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString('lastLeaderboardUpdate');
      final cachedData = prefs.getString('cachedLeaderboard');

      if (lastUpdateStr != null && cachedData != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final now = DateTime.now();

        // If less than 24 hours have passed, return the cached data immediately
        if (now.difference(lastUpdate).inHours < 24) {
          debugPrint(
            'GameService: Using cached leaderboard (Updates in ${24 - now.difference(lastUpdate).inHours}h)',
          );
          final List<dynamic> decoded = jsonDecode(cachedData);
          return decoded.cast<Map<String, dynamic>>();
        }
      }

      // 24h passed or no cache: Fetch from Worker
      final response = await http.get(
        Uri.parse('$_workerUrl/api/leaderboard'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Save to cache for the next 24 hours
        await prefs.setString(
          'lastLeaderboardUpdate',
          DateTime.now().toIso8601String(),
        );
        await prefs.setString('cachedLeaderboard', response.body);

        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('GameService: Leaderboard fetch error: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _energyRegenTimer?.cancel();
    _syncTimer?.cancel();
    _autoClickerTimer?.cancel();
    WakelockPlus.disable(); // Ensure wakelock is released
    _saveCachedState();
    _syncToFirestore();
    super.dispose();
  }
}
