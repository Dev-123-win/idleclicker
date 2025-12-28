import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/constants.dart';

/// AdMob advertising service
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService();

  // Production Ad Unit IDs
  static const String _prodBannerAdUnitId =
      'ca-app-pub-3863562453957252/4000539271';
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-3863562453957252/3669366780';
  static const String _prodRewardedAdUnitId =
      'ca-app-pub-3863562453957252/2356285112';
  static const String _prodRewardedInterstitialAdUnitId =
      'ca-app-pub-3863562453957252/5980806527';
  static const String _prodNativeAdUnitId =
      'ca-app-pub-3863562453957252/6003347084';
  static const String _prodAppOpenAdUnitId =
      'ca-app-pub-3863562453957252/7316428755';

  // Test Ad Unit IDs (for development)
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';
  static const String _testNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _testAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';

  // Use test IDs in debug mode, production IDs in release
  String get bannerAdUnitId =>
      kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  String get rewardedAdUnitId =>
      kDebugMode ? _testRewardedAdUnitId : _prodRewardedAdUnitId;
  String get rewardedInterstitialAdUnitId => kDebugMode
      ? _testRewardedInterstitialAdUnitId
      : _prodRewardedInterstitialAdUnitId;
  String get nativeAdUnitId =>
      kDebugMode ? _testNativeAdUnitId : _prodNativeAdUnitId;
  String get appOpenAdUnitId =>
      kDebugMode ? _testAppOpenAdUnitId : _prodAppOpenAdUnitId;

  // Pooled ads for zero-latency
  final List<InterstitialAd> _interstitialPool = [];
  final List<RewardedAd> _rewardedPool = [];
  final List<RewardedInterstitialAd> _rewardedInterstitialPool = [];
  AppOpenAd? _appOpenAd;

  // Max pool sizes
  static const int _maxPoolSize = 2;

  // Ad tracking
  DateTime? _lastInterstitialTime;
  int _screenSwitchCount = 0;

  bool _isInitialized = false;
  bool _isShowingAd = false;

  /// Initialize AdMob SDK
  Future<void> init() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    // Set initial time to prevent ad immediately on first switch if desired
    _lastInterstitialTime = DateTime.now();

    // Preload ads
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadRewardedInterstitialAd();
    _loadAppOpenAd();

    // Preload native ads
    _preloadNativeAd(TemplateType.small);
    _preloadNativeAd(TemplateType.medium);
  }

  // ============ Native Ad Preloading ============
  final Map<TemplateType, List<NativeAd>> _preloadedNativeAds = {
    TemplateType.small: [],
    TemplateType.medium: [],
  };

  void _preloadNativeAd(TemplateType type) {
    if (_preloadedNativeAds[type]!.length >= 2) return; // Buffer of 2

    NativeAd? ad;
    ad = createNativeAd(
      templateType: type,
      onLoaded: (_) {
        if (ad != null) _preloadedNativeAds[type]?.add(ad);
        debugPrint('Preloaded native ad loaded: $type');
      },
      onFailed: (failedAd, error) {
        failedAd.dispose();
        debugPrint('Preloaded native ad failed: $type - ${error.message}');
        // Retry after delay
        Future.delayed(
          const Duration(seconds: 30),
          () => _preloadNativeAd(type),
        );
      },
    );
    ad.load();
  }

  /// Get a preloaded native ad or create a new one if none available
  NativeAd? getNativeAd(TemplateType type) {
    if (_preloadedNativeAds[type]!.isNotEmpty) {
      final ad = _preloadedNativeAds[type]!.removeAt(0);
      // Trigger a new preload to refill the buffer
      _preloadNativeAd(type);
      return ad;
    }
    return null;
  }

  // ============ Banner Ads ============

  /// Create banner ad
  BannerAd createBannerAd({
    AdSize size = AdSize.banner,
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );
  }

  // ============ Interstitial Ads (for screen transitions) ============

  /// Load interstitial ad into pool
  void _loadInterstitialAd() {
    if (_interstitialPool.length >= _maxPoolSize) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialPool.add(ad);
          debugPrint('Interstitial pool size: ${_interstitialPool.length}');
          // If still below max, load another
          if (_interstitialPool.length < _maxPoolSize) _loadInterstitialAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: ${error.message}');
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Show interstitial ad from pool
  Future<bool> showInterstitialAd({bool force = false}) async {
    if (_isShowingAd) return false;

    if (!force && _lastInterstitialTime != null) {
      final difference = DateTime.now().difference(_lastInterstitialTime!);
      if (difference.inMinutes < AppConstants.minMinutesBetweenInterstitials) {
        return false;
      }
    }

    if (_interstitialPool.isEmpty) {
      _loadInterstitialAd();
      return false;
    }

    _isShowingAd = true;
    final ad = _interstitialPool.removeAt(0);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
        _isShowingAd = false;
        _lastInterstitialTime = DateTime.now();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
        _isShowingAd = false;
      },
    );

    await ad.show();
    return true;
  }

  /// Records a screen switch and shows an ad if requirements are met
  void recordScreenSwitch() {
    _screenSwitchCount++;
    if (_screenSwitchCount >= AppConstants.screenSwitchesBetweenAds) {
      showInterstitialAd().then((shown) {
        if (shown) {
          _screenSwitchCount = 0;
        }
      });
    }
  }

  /// Check if interstitial is ready
  bool get isInterstitialReady => _interstitialPool.isNotEmpty;

  // ============ Rewarded Ads (for skip taps) ============

  /// Load rewarded ad into pool
  void _loadRewardedAd() {
    if (_rewardedPool.length >= _maxPoolSize) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedPool.add(ad);
          debugPrint('Rewarded pool size: ${_rewardedPool.length}');
          if (_rewardedPool.length < _maxPoolSize) _loadRewardedAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed: ${error.message}');
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Show rewarded ad from pool
  Future<bool> showRewardedAd({
    required void Function() onRewarded,
    void Function()? onDismissed,
  }) async {
    if (_isShowingAd) return false;
    if (_rewardedPool.isEmpty) {
      _loadRewardedAd();
      return false;
    }

    _isShowingAd = true;
    final ad = _rewardedPool.removeAt(0);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
        _isShowingAd = false;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        _isShowingAd = false;
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );

    return true;
  }

  /// Check if rewarded ad is ready
  bool get isRewardedReady => _rewardedPool.isNotEmpty;

  // ============ Rewarded Interstitial Ads (for missions) ============

  /// Load rewarded interstitial ad into pool
  void _loadRewardedInterstitialAd() {
    if (_rewardedInterstitialPool.length >= _maxPoolSize) return;

    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialPool.add(ad);
          debugPrint(
            'Rewarded Interstitial pool size: ${_rewardedInterstitialPool.length}',
          );
          if (_rewardedInterstitialPool.length < _maxPoolSize)
            _loadRewardedInterstitialAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded interstitial failed: ${error.message}');
          Future.delayed(
            const Duration(seconds: 30),
            _loadRewardedInterstitialAd,
          );
        },
      ),
    );
  }

  /// Show rewarded interstitial ad from pool
  Future<bool> showRewardedInterstitialAd({
    required void Function() onRewarded,
    void Function()? onDismissed,
  }) async {
    if (_isShowingAd) return false;
    if (_rewardedInterstitialPool.isEmpty) {
      _loadRewardedInterstitialAd();
      return false;
    }

    _isShowingAd = true;
    final ad = _rewardedInterstitialPool.removeAt(0);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedInterstitialAd();
        _isShowingAd = false;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedInterstitialAd();
        _isShowingAd = false;
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );

    return true;
  }

  /// Check if rewarded interstitial is ready
  bool get isRewardedInterstitialReady => _rewardedInterstitialPool.isNotEmpty;

  // ============ App Open Ads ============

  /// Load app open ad
  void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('App open ad failed: ${error.message}');
          Future.delayed(const Duration(seconds: 60), _loadAppOpenAd);
        },
      ),
    );
  }

  /// Show app open ad
  Future<bool> showAppOpenAd() async {
    if (_isShowingAd) return false;
    if (_appOpenAd == null) {
      _loadAppOpenAd();
      return false;
    }

    _isShowingAd = true;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        _isShowingAd = false;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        _isShowingAd = false;
      },
    );

    await _appOpenAd!.show();
    return true;
  }

  // ============ Native Ads ============

  /// Create native ad
  NativeAd createNativeAd({
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
    TemplateType templateType = TemplateType.medium,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: templateType,
        mainBackgroundColor: const Color(0xFF161B22),
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF0D1117),
          backgroundColor: const Color(0xFFFFD700),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFF0F6FC),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF8B949E),
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF6E7681),
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    for (var ad in _interstitialPool) {
      ad.dispose();
    }
    _interstitialPool.clear();

    for (var ad in _rewardedPool) {
      ad.dispose();
    }
    _rewardedPool.clear();

    for (var ad in _rewardedInterstitialPool) {
      ad.dispose();
    }
    _rewardedInterstitialPool.clear();

    for (var pool in _preloadedNativeAds.values) {
      for (var ad in pool) {
        ad.dispose();
      }
      pool.clear();
    }

    _appOpenAd?.dispose();
  }
}
