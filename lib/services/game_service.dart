import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../models/user_model.dart';
import '../models/mission_model.dart';
import '../core/constants.dart';
import 'hive_service.dart';
import 'service_locator.dart';

/// Core game logic service
class GameService extends ChangeNotifier {
  UserModel? _user;
  MissionModel? _currentMission;
  final Random _random = Random();

  // Ad trigger tracking
  int _tapsSinceLastAd = 0;
  int _nextAdTriggerTap = 0;
  bool _adCooldownActive = false;
  DateTime? _adCooldownEnd;

  /// Current user
  UserModel? get user => _user;

  /// Current mission
  MissionModel? get currentMission => _currentMission;

  /// Whether ad cooldown is active
  bool get adCooldownActive => _adCooldownActive;

  /// Seconds remaining in ad cooldown
  int get adCooldownSeconds {
    if (_adCooldownEnd == null) return 0;
    final remaining = _adCooldownEnd!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Initialize game with user
  void initialize(UserModel user) {
    _user = user;
    _currentMission = Missions.getMission(user.currentMissionIndex);
    _calculateNextAdTrigger();
    notifyListeners();
  }

  /// Load user from local storage
  Future<bool> loadFromLocal() async {
    final user = getService<HiveService>().getUser();
    if (user != null) {
      initialize(user);
      return true;
    }
    return false;
  }

  /// Process a tap
  Future<TapResult> tap() async {
    if (_user == null) {
      return TapResult(
        success: false,
        coinsEarned: 0,
        shouldShowAd: false,
        message: 'User not initialized',
      );
    }

    if (_adCooldownActive && adCooldownSeconds > 0) {
      return TapResult(
        success: false,
        coinsEarned: 0,
        shouldShowAd: false,
        message: 'Please wait $adCooldownSeconds seconds',
      );
    }

    // Reset cooldown if expired
    if (_adCooldownActive && adCooldownSeconds <= 0) {
      _adCooldownActive = false;
      _adCooldownEnd = null;
    }

    // Only process if current mission is a tap mission
    if (_currentMission == null || !_currentMission!.isTapMission) {
      return TapResult(
        success: false,
        coinsEarned: 0,
        shouldShowAd: false,
        message: 'Complete the ad mission first',
      );
    }

    // Increment taps
    _user!.totalTaps++;
    _user!.sessionTaps++;
    _user!.currentMissionProgress++;
    _tapsSinceLastAd++;

    // Trigger haptic feedback
    if (_user!.hapticEnabled) {
      await _triggerHaptic();
    }

    // Check if we should show an ad
    bool shouldShowAd = _tapsSinceLastAd >= _nextAdTriggerTap;

    // Check mission completion
    bool missionCompleted =
        _user!.currentMissionProgress >= _currentMission!.target;

    if (missionCompleted) {
      return _completeMission();
    }

    // Save locally
    await _saveLocal();

    if (shouldShowAd) {
      _tapsSinceLastAd = 0;
      _calculateNextAdTrigger();
    }

    return TapResult(
      success: true,
      coinsEarned: 0, // Coins only on mission completion
      shouldShowAd: shouldShowAd,
      missionProgress: _user!.currentMissionProgress,
      missionTarget: _currentMission!.target,
    );
  }

  /// Complete current mission and award coins
  TapResult _completeMission() {
    if (_user == null || _currentMission == null) {
      return TapResult(success: false, coinsEarned: 0, shouldShowAd: false);
    }

    final reward = _currentMission!.reward;

    // Award coins
    _user!.totalCoins += reward;
    _user!.lifetimeCoins += reward;

    // Mark mission complete
    _user!.completedMissionIds.add(_currentMission!.id);
    _user!.currentMissionIndex++;
    _user!.currentMissionProgress = 0;

    // Load next mission
    _currentMission = Missions.getMission(_user!.currentMissionIndex);

    // Save locally
    _saveLocal();

    notifyListeners();

    return TapResult(
      success: true,
      coinsEarned: reward,
      shouldShowAd: true, // Show ad on mission completion
      missionCompleted: true,
      message: 'Mission completed! +$reward coins',
    );
  }

  /// Process ad watch for ad missions
  Future<TapResult> watchAd() async {
    if (_user == null) {
      return TapResult(success: false, coinsEarned: 0, shouldShowAd: false);
    }

    if (_currentMission == null || !_currentMission!.isAdMission) {
      // Not an ad mission - this is a skip taps ad
      return TapResult(
        success: true,
        coinsEarned: 0,
        shouldShowAd: false,
        message: 'Ad watched',
      );
    }

    // Increment ad watch progress
    _user!.currentMissionProgress++;
    _user!.adsWatchedToday++;
    _user!.lastAdWatchDate = DateTime.now();

    // Check mission completion
    if (_user!.currentMissionProgress >= _currentMission!.target) {
      return _completeMission();
    }

    await _saveLocal();
    notifyListeners();

    return TapResult(
      success: true,
      coinsEarned: 0,
      shouldShowAd: false,
      missionProgress: _user!.currentMissionProgress,
      missionTarget: _currentMission!.target,
    );
  }

  /// Start ad cooldown after watching
  void startAdCooldown() {
    _adCooldownActive = true;
    _adCooldownEnd = DateTime.now().add(
      Duration(seconds: AppConstants.adCooldownSeconds),
    );
    notifyListeners();
  }

  /// Calculate next random ad trigger point
  void _calculateNextAdTrigger() {
    final isHardTier = _user?.isInHardTier ?? false;
    final interval = isHardTier
        ? AppConstants.hardTierAdInterval
        : AppConstants.easyTierAdInterval;

    // Random trigger between 60-100% of interval
    final minTap = (interval * 0.6).round();
    final maxTap = interval;
    _nextAdTriggerTap = minTap + _random.nextInt(maxTap - minTap + 1);
  }

  /// Trigger haptic feedback
  Future<void> _triggerHaptic() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 10, amplitude: 64);
      }
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Save user to local storage
  Future<void> _saveLocal() async {
    if (_user != null) {
      await getService<HiveService>().saveUser(_user!);
    }
  }

  /// Update user from external source
  void updateUser(UserModel user) {
    _user = user;
    _currentMission = Missions.getMission(user.currentMissionIndex);
    notifyListeners();
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptic(bool enabled) async {
    if (_user != null) {
      _user!.hapticEnabled = enabled;
      await _saveLocal();
      notifyListeners();
    }
  }

  /// Check if withdrawal is possible
  bool get canWithdraw => _user?.canWithdraw ?? false;

  /// Get current coins
  int get currentCoins => _user?.totalCoins ?? 0;

  /// Get coins in rupees
  double get coinsInRupees => (_user?.totalCoins ?? 0) / 1000;
}

/// Result of a tap action
class TapResult {
  final bool success;
  final int coinsEarned;
  final bool shouldShowAd;
  final bool missionCompleted;
  final String? message;
  final int? missionProgress;
  final int? missionTarget;

  TapResult({
    required this.success,
    required this.coinsEarned,
    required this.shouldShowAd,
    this.missionCompleted = false,
    this.message,
    this.missionProgress,
    this.missionTarget,
  });
}
