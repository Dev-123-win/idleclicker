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
    final height =
        widget.height ??
        (widget.templateType == TemplateType.small ? 90.0 : 200.0);

    if (!_isLoaded || _nativeAd == null) {
      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
