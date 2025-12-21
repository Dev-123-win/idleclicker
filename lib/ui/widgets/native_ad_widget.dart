import 'package:flutter/material.dart';
import '../../core/services/ad_service.dart';
import '../theme/app_theme.dart';

/// Native Ad Widget with premium styling
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _adService.addListener(_onAdStateChanged);
  }

  void _onAdStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _adService.removeListener(_onAdStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adWidget = _adService.getNativeAdWidget();

    if (adWidget == null) {
      // Transparent placeholder to reserve space without showing loading UI
      return const SizedBox(height: 320);
    }

    return Container(
      height: 320,

      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: adWidget,
    );
  }
}
