import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/game_service.dart';
import '../services/ad_service.dart';
import '../services/service_locator.dart';
import '../widgets/tap_button.dart';
import '../widgets/coin_counter.dart';
import '../widgets/ads/banner_ad_widget.dart';

/// Main home screen with tap button
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = getService<GameService>();
  final AdService _adService = getService<AdService>();

  bool _showingAd = false;

  @override
  void initState() {
    super.initState();
    _adService.init();
  }

  Future<void> _handleTap() async {
    final result = await _gameService.tap();

    if (result.missionCompleted) {
      _showMissionCompleteDialog(result.coinsEarned);
    }

    if (result.shouldShowAd && !_showingAd) {
      await _showAd();
    }
  }

  Future<void> _showAd() async {
    setState(() => _showingAd = true);

    final shown = await _adService.showInterstitialAd(force: true);
    if (!shown) {
      // Try rewarded ad if interstitial not ready
      await _adService.showRewardedAd(
        onRewarded: () {
          _gameService.startAdCooldown();
        },
        onDismissed: () {
          setState(() => _showingAd = false);
        },
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _showingAd = false);
    }
  }

  void _showMissionCompleteDialog(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 60,
              color: AppColors.gold,
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'Mission Complete!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+$coins coins',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show ad after claiming
              _adService.showRewardedAd(onRewarded: () {});
            },
            child: const Text(
              'Claim Reward',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _gameService,
          child: Consumer<GameService>(
            builder: (context, game, _) {
              final mission = game.currentMission;
              final progress = game.user?.currentMissionProgress ?? 0;
              final target = mission?.target ?? 1;

              return Column(
                children: [
                  // Header
                  _buildHeader(game),

                  // Main content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Coin counter
                        CoinCounter(coins: game.currentCoins)
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: -0.2, end: 0),

                        const SizedBox(height: 48),

                        // Tap button
                        TapButton(
                          onTap: _handleTap,
                          enabled: mission?.isTapMission ?? false,
                          cooldownSeconds: game.adCooldownSeconds,
                        ).animate().scale(
                          delay: 300.ms,
                          curve: Curves.elasticOut,
                        ),

                        const SizedBox(height: 32),

                        // Mission progress
                        if (mission != null)
                          _buildMissionProgress(
                            mission.title,
                            progress,
                            target,
                          ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 16),

                        // Skip taps button (watch ad)
                        if (mission?.isTapMission == true)
                          _buildSkipButton().animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),

                  // Banner ad
                  const BannerAdWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GameService game) {
    final rupees = game.coinsInRupees;
    final tier = game.user?.isInHardTier == true ? 'Hard' : 'Easy';

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            decoration: BoxDecoration(
              color: game.user?.isInHardTier == true
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '$tier Tier',
              style: TextStyle(
                color: game.user?.isInHardTier == true
                    ? AppColors.error
                    : AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // Rupees earned
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Text(
              '₹${rupees.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionProgress(String title, int progress, int target) {
    final percent = (progress / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$progress / $target',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton.icon(
      onPressed: () async {
        final shown = await _adService.showRewardedAd(
          onRewarded: () {
            // Skip 100 taps
            for (int i = 0; i < 100; i++) {
              _gameService.tap();
            }
            _gameService.startAdCooldown();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Skipped 100 taps!'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );

        if (!shown) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad not ready, try again'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      icon: const Icon(Icons.fast_forward, color: AppColors.gold),
      label: const Text(
        'Watch Ad to Skip 100 Taps',
        style: TextStyle(color: AppColors.gold),
      ),
    );
  }
}
