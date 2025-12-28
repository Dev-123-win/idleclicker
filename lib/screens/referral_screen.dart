import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/game_service.dart';
import '../services/service_locator.dart';
import '../widgets/ads/native_ad_widget.dart';

/// Referral screen with sharing functionality
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gameService = getService<GameService>();
    final referralCode = gameService.user?.referralCode ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          children: [
            // Header illustration
            RepaintBoundary(
              child: Container(
                width: 120,
                height: 120,
                decoration: NeumorphicDecoration.goldFlat(radius: 60),
                child: Icon(
                  Icons.group_add,
                  size: 60,
                  color: AppColors.background,
                ),
              ).animate().scale(curve: Curves.elasticOut),
            ),

            const SizedBox(height: 24),

            Text(
              'Invite Friends & Earn!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 8),

            Text(
              'Share your referral code and earn coins when friends join!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // Rewards info
            RepaintBoundary(
              child: Row(
                children: [
                  Expanded(
                    child: _RewardCard(
                      icon: Icons.person,
                      title: 'You Get',
                      coins: AppConstants.referrerBonus,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RewardCard(
                      icon: Icons.person_add,
                      title: 'Friend Gets',
                      coins: AppConstants.referredBonus,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
            ),

            const SizedBox(height: 32),

            // Referral code
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: NeumorphicDecoration.flat(),
              child: Column(
                children: [
                  Text(
                    'Your Referral Code',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        referralCode,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: Icon(Icons.copy, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 24),

            // Share button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    'Join TapMine and earn real money! Use my referral code: $referralCode to get ${AppConstants.referredBonus} bonus coins! Download now.',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share with Friends'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // Native ad
            const NativeAdWidget(templateType: TemplateType.medium),

            const SizedBox(height: 24),

            // How it works
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it Works',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StepItem(number: '1', text: 'Share your code with friends'),
                  _StepItem(
                    number: '2',
                    text: 'Friend enters code during registration',
                  ),
                  _StepItem(
                    number: '3',
                    text: 'Both of you get bonus coins instantly!',
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int coins;

  const _RewardCard({
    required this.icon,
    required this.title,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: NeumorphicDecoration.flat(),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                '+$coins',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
