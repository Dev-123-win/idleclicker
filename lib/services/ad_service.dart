import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  // Preloaded ads
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  AppOpenAd? _appOpenAd;

  bool _isInitialized = false;
  bool _isShowingAd = false;

  /// Initialize AdMob SDK
  Future<void> init() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    // Preload ads
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadRewardedInterstitialAd();
    _loadAppOpenAd();
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

  /// Load interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
              _isShowingAd = false;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
              _isShowingAd = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: ${error.message}');
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Show interstitial ad (for screen transitions)
  Future<bool> showInterstitialAd() async {
    if (_isShowingAd) return false;
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return false;
    }

    _isShowingAd = true;
    await _interstitialAd!.show();
    return true;
  }

  /// Check if interstitial is ready
  bool get isInterstitialReady => _interstitialAd != null;

  // ============ Rewarded Ads (for skip taps) ============

  /// Load rewarded ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Show rewarded ad with callback (for skip taps feature)
  Future<bool> showRewardedAd({
    required void Function() onRewarded,
    void Function()? onDismissed,
  }) async {
    if (_isShowingAd) return false;
    if (_rewardedAd == null) {
      _loadRewardedAd();
      return false;
    }

    _isShowingAd = true;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        _isShowingAd = false;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        _isShowingAd = false;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );

    return true;
  }

  /// Check if rewarded ad is ready
  bool get isRewardedReady => _rewardedAd != null;

  // ============ Rewarded Interstitial Ads (for missions) ============

  /// Load rewarded interstitial ad
  void _loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded interstitial failed to load: ${error.message}');
          Future.delayed(
            const Duration(seconds: 30),
            _loadRewardedInterstitialAd,
          );
        },
      ),
    );
  }

  /// Show rewarded interstitial ad (for mission start)
  Future<bool> showRewardedInterstitialAd({
    required void Function() onRewarded,
    void Function()? onDismissed,
  }) async {
    if (_isShowingAd) return false;
    if (_rewardedInterstitialAd == null) {
      _loadRewardedInterstitialAd();
      return false;
    }

    _isShowingAd = true;

    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedInterstitialAd = null;
            _loadRewardedInterstitialAd();
            _isShowingAd = false;
            onDismissed?.call();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _rewardedInterstitialAd = null;
            _loadRewardedInterstitialAd();
            _isShowingAd = false;
          },
        );

    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );

    return true;
  }

  /// Check if rewarded interstitial is ready
  bool get isRewardedInterstitialReady => _rewardedInterstitialAd != null;

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
          debugPrint('App open ad failed to load: ${error.message}');
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
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _appOpenAd?.dispose();
  }
}
