import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/mission_model.dart';
import '../services/game_service.dart';
import '../services/ad_service.dart';
import '../services/service_locator.dart';
import '../widgets/ads/native_ad_widget.dart';

/// Missions list screen
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gameService = getService<GameService>();
    final currentIndex = gameService.user?.currentMissionIndex ?? 0;
    final completedIds = gameService.user?.completedMissionIds ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Missions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount:
            Missions.all.length +
            (Missions.all.length ~/ 5), // Include native ads
        itemBuilder: (context, index) {
          // Show native ad every 5 missions
          final missionIndex = index - (index ~/ 6);
          if (index > 0 && index % 6 == 5) {
            return const NativeAdWidget(
              templateType: TemplateType.small,
              height: 100,
            );
          }

          if (missionIndex >= Missions.all.length) return const SizedBox();

          final mission = Missions.all[missionIndex];
          final isCompleted = completedIds.contains(mission.id);
          final isCurrent = missionIndex == currentIndex;
          final isLocked = missionIndex > currentIndex;

          return RepaintBoundary(
            child:
                _MissionCard(
                      mission: mission,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isLocked: isLocked,
                      onStart: isCurrent
                          ? () => _startMission(context, mission)
                          : null,
                    )
                    .animate(delay: Duration(milliseconds: 50 * missionIndex))
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }

  void _startMission(BuildContext context, MissionModel mission) {
    final adService = getService<AdService>();

    // Show rewarded interstitial ad before starting mission
    adService.showRewardedInterstitialAd(
      onRewarded: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mission "${mission.title}" started! Swipe to Home to tap.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // User swipes back to home tab to start tapping
      },
      onDismissed: () {},
    );
  }
}

class _MissionCard extends StatelessWidget {
  final MissionModel mission;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback? onStart;

  const _MissionCard({
    required this.mission,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: isCurrent ? Border.all(color: AppColors.gold, width: 2) : null,
        boxShadow: NeumorphicDecoration.flat().boxShadow,
      ),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : isCurrent
                          ? AppColors.gold
                          : AppColors.surfaceLight,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : isLocked
                          ? Icons.lock
                          : mission.isAdMission
                          ? Icons.play_circle
                          : Icons.touch_app,
                      color: isCompleted || isCurrent
                          ? AppColors.background
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and tier
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mission.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Tier badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: mission.isEasyTier
                                    ? AppColors.success.withValues(alpha: 0.2)
                                    : AppColors.error.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mission.isEasyTier ? 'Easy' : 'Hard',
                                style: TextStyle(
                                  color: mission.isEasyTier
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mission.description,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Mission details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Target
                  Row(
                    children: [
                      Icon(
                        mission.isAdMission
                            ? Icons.play_arrow
                            : Icons.touch_app,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mission.isAdMission
                            ? '${mission.target} ads'
                            : '${mission.target} taps',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  // Reward
                  Row(
                    children: [
                      Image.asset(
                        'assets/AppCoin.png',
                        width: 16,
                        height: 16,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.monetization_on,
                          size: 16,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${mission.reward}',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Start button (for current mission)
              if (isCurrent && onStart != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.background,
                    ),
                    child: Text(
                      mission.isAdMission ? 'Watch Ads' : 'Start Tapping',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
