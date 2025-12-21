import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad Service for managing all ad types with auto-clicker coordination
/// Handles interstitial, rewarded, and native ads with race condition protection
class AdService with ChangeNotifier {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isAdShowing = false;
  bool _isInitialized = false;
  DateTime? _lastAdShown;
  int _totalAdsWatched = 0;

  VoidCallback? onAdStarted;
  VoidCallback? onAdCompleted;
  VoidCallback? onAdFailed;
  VoidCallback? onAdFastClosed; // New: Triggered if closed < 2s

  // For race condition handling
  bool _isAdLockAcquired = false;
  DateTime? _adStartTime; // New: Track when ad was shown

  // Preloaded ads
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  // Ad Unit IDs
  static const String _bannerAdUnitId =
      'ca-app-pub-3863562453957252/4000539271';
  static const String _interstitialAdUnitId =
      'ca-app-pub-3863562453957252/3669366780';
  static const String _rewardedAdUnitId =
      'ca-app-pub-3863562453957252/2356285112';
  static const String _appOpenAdUnitId =
      'ca-app-pub-3863562453957252/7316428755';
  static const String _nativeAdUnitId =
      'ca-app-pub-3863562453957252/6003347084';

  bool get isAdShowing => _isAdShowing;
  bool get isInitialized => _isInitialized;
  int get totalAdsWatched => _totalAdsWatched;
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  NativeAd? get nativeAd => _nativeAd;

  String get bannerAdUnitId => _bannerAdUnitId;
  String get appOpenAdUnitId => _appOpenAdUnitId;

  /// Initialize the ad service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();

      // Preload ads
      _loadInterstitialAd();
      _loadRewardedAd();
      _loadNativeAd();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AdService: Failed to initialize: $e');
    }
  }

  /// Load interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            'AdService: Interstitial ad failed to load: ${error.message}',
          );
          _interstitialAd = null;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Load rewarded ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Rewarded ad failed to load: ${error.message}');
          _rewardedAd = null;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Load native ad
  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isNativeAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Native ad failed to load: ${error.message}');
          ad.dispose();
          _nativeAd = null;
          _isNativeAdLoaded = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 60), _loadNativeAd);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
      ),
    );
    _nativeAd!.load();
  }

  /// Acquire ad lock to prevent race conditions
  Future<bool> _acquireAdLock() async {
    if (_isAdLockAcquired) {
      return false; // Another ad is already in progress
    }
    _isAdLockAcquired = true;
    return true;
  }

  /// Release ad lock
  void _releaseAdLock() {
    _isAdLockAcquired = false;
  }

  /// Show interstitial ad with auto-clicker pause
  Future<AdResult> showInterstitialAd() async {
    // Acquire lock to prevent race conditions
    if (!await _acquireAdLock()) {
      return AdResult.failure('Another ad is in progress');
    }

    if (_interstitialAd == null) {
      _releaseAdLock();
      _loadInterstitialAd();
      return AdResult.failure('Ad not ready');
    }

    final completer = Completer<AdResult>();

    try {
      // Notify auto-clicker to pause
      _isAdShowing = true;
      onAdStarted?.call();
      notifyListeners();

      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _isAdShowing = false;
          _lastAdShown = DateTime.now();
          _totalAdsWatched++;

          // Penalty Detection: Check if ad was closed too fast (< 2 seconds)
          if (_adStartTime != null) {
            final duration = DateTime.now().difference(_adStartTime!);
            if (duration.inSeconds < 2) {
              onAdFastClosed?.call();
            }
          }

          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd(); // Preload next ad

          onAdCompleted?.call();
          notifyListeners();
          _releaseAdLock();

          if (!completer.isCompleted) {
            completer.complete(AdResult.success());
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isAdShowing = false;
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();

          onAdFailed?.call();
          notifyListeners();
          _releaseAdLock();

          if (!completer.isCompleted) {
            completer.complete(AdResult.failure(error.message));
          }
        },
      );

      _adStartTime = DateTime.now();
      await _interstitialAd!.show();

      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _releaseAdLock();
          return AdResult.failure('Ad timeout');
        },
      );
    } catch (e) {
      _isAdShowing = false;
      onAdFailed?.call();
      notifyListeners();
      _releaseAdLock();
      return AdResult.failure('Ad failed: $e');
    }
  }

  /// Show rewarded ad with auto-clicker pause
  Future<AdResult> showRewardedAd() async {
    // Acquire lock to prevent race conditions
    if (!await _acquireAdLock()) {
      return AdResult.failure('Another ad is in progress');
    }

    if (_rewardedAd == null) {
      _releaseAdLock();
      _loadRewardedAd();
      return AdResult.failure('Ad not ready');
    }

    final completer = Completer<AdResult>();
    int earnedReward = 0;

    try {
      // Notify auto-clicker to pause
      _isAdShowing = true;
      onAdStarted?.call();
      notifyListeners();

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _isAdShowing = false;
          _lastAdShown = DateTime.now();
          _totalAdsWatched++;

          // Penalty Detection
          if (_adStartTime != null) {
            final duration = DateTime.now().difference(_adStartTime!);
            if (duration.inSeconds < 2) {
              onAdFastClosed?.call();
            }
          }

          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd(); // Preload next ad

          onAdCompleted?.call();
          notifyListeners();
          _releaseAdLock();

          if (!completer.isCompleted) {
            completer.complete(AdResult.success(reward: earnedReward));
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isAdShowing = false;
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();

          onAdFailed?.call();
          notifyListeners();
          _releaseAdLock();

          if (!completer.isCompleted) {
            completer.complete(AdResult.failure(error.message));
          }
        },
      );

      _adStartTime = DateTime.now();
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          earnedReward = reward.amount.toInt();
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          _releaseAdLock();
          return AdResult.failure('Ad timeout');
        },
      );
    } catch (e) {
      _isAdShowing = false;
      onAdFailed?.call();
      notifyListeners();
      _releaseAdLock();
      return AdResult.failure('Ad failed: $e');
    }
  }

  /// Get native ad widget
  Widget? getNativeAdWidget() {
    if (!_isNativeAdLoaded || _nativeAd == null) {
      return null;
    }
    return AdWidget(ad: _nativeAd!);
  }

  /// Refresh native ad
  void refreshNativeAd() {
    _nativeAd?.dispose();
    _isNativeAdLoaded = false;
    _loadNativeAd();
  }

  /// Check if we can show an ad (cooldown check)
  bool canShowAd({int cooldownSeconds = 30}) {
    if (_lastAdShown == null) return true;
    final diff = DateTime.now().difference(_lastAdShown!);
    return diff.inSeconds >= cooldownSeconds;
  }

  /// Check if interstitial is ready
  bool get isInterstitialReady => _interstitialAd != null;

  /// Check if rewarded is ready
  bool get isRewardedReady => _rewardedAd != null;

  /// Skip cooldown using rewarded ad
  Future<bool> skipCooldownWithAd() async {
    final result = await showRewardedAd();
    return result.isSuccess;
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    onAdStarted = null;
    onAdCompleted = null;
    onAdFailed = null;
    super.dispose();
  }
}

/// Ad result model
class AdResult {
  final bool isSuccess;
  final String? errorMessage;
  final int reward;

  AdResult._({required this.isSuccess, this.errorMessage, this.reward = 0});

  factory AdResult.success({int reward = 0}) =>
      AdResult._(isSuccess: true, reward: reward);

  factory AdResult.failure(String message) =>
      AdResult._(isSuccess: false, errorMessage: message);
}
