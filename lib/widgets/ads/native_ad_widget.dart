import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import '../../services/ad_service.dart';
import '../../services/service_locator.dart';

/// Native ad widget using template format (no Kotlin code required)
class NativeAdWidget extends StatefulWidget {
  final TemplateType templateType;
  final double? height;

  const NativeAdWidget({
    super.key,
    this.templateType = TemplateType.medium,
    this.height,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = getService<AdService>().createNativeAd(
      templateType: widget.templateType,
      onLoaded: (ad) {
        setState(() => _isLoaded = true);
      },
      onFailed: (ad, error) {
        ad.dispose();
        debugPrint('Native ad failed: ${error.message}');
      },
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final height =
        widget.height ??
        (widget.templateType == TemplateType.small ? 90.0 : 320.0);

    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }
}
