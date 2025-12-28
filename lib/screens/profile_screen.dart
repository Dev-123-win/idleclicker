import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/mission_model.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import '../widgets/ads/native_ad_widget.dart';

/// Profile screen with user stats
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gameService = getService<GameService>();
    final user = gameService.user;
    final formatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          children: [
            // Avatar
            RepaintBoundary(
              child: Container(
                width: 100,
                height: 100,
                decoration: NeumorphicDecoration.goldFlat(radius: 50),
                child: Center(
                  child: Text(
                    user?.email.substring(0, 1).toUpperCase() ?? 'U',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().scale(curve: Curves.elasticOut),
            ),

            const SizedBox(height: 16),

            Text(
              user?.email ?? 'User',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 4),

            Text(
              'Member since ${DateFormat('MMM yyyy').format(user?.createdAt ?? DateTime.now())}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // Stats grid
            RepaintBoundary(
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.monetization_on,
                    label: 'Total Coins',
                    value: formatter.format(user?.totalCoins ?? 0),
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    icon: Icons.emoji_events,
                    label: 'Lifetime Coins',
                    value: formatter.format(user?.lifetimeCoins ?? 0),
                    color: AppColors.warning,
                  ),
                  _StatCard(
                    icon: Icons.touch_app,
                    label: 'Total Taps',
                    value: formatter.format(user?.totalTaps ?? 0),
                    color: AppColors.info,
                  ),
                  _StatCard(
                    icon: Icons.check_circle,
                    label: 'Missions Done',
                    value:
                        '${user?.completedMissionIds.length ?? 0}/${Missions.all.length}',
                    color: AppColors.success,
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
            ),

            const SizedBox(height: 24),

            // Native ad
            const NativeAdWidget(templateType: TemplateType.medium),

            const SizedBox(height: 24),

            // Settings section
            Container(
              decoration: NeumorphicDecoration.flat(),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    trailing: Switch(
                      value: user?.hapticEnabled ?? true,
                      onChanged: (value) {
                        gameService.toggleHaptic(value);
                      },
                      activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
                      thumbColor: WidgetStatePropertyAll(AppColors.gold),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.help,
                    title: 'FAQ',
                    onTap: () => Navigator.pushNamed(context, '/faq'),
                  ),
                  _SettingsItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: AppColors.error,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await getService<AuthService>().logout();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: NeumorphicDecoration.flat(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.textMuted),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? AppColors.textPrimary),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: AppColors.textMuted)
              : null),
      onTap: onTap,
    );
  }
}
