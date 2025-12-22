import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/user_model.dart';
import '../../core/services/game_service.dart';
import '../../ui/theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';

/// Profile Screen with stats and withdrawal
class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onNavigateToSettings;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
    required this.onLogout,
    required this.onNavigateToSettings,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animController.forward();

    // Setup error handling
    widget.gameService.onError = (error) {
      if (mounted) {
        AppSnackBar.error(context, error);
      }
    };
  }

  @override
  void dispose() {
    // Clear snackbars when leaving the screen
    ScaffoldMessenger.of(context).clearSnackBars();

    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    _buildStatsGrid(),
                    _buildReferralSection(),
                    _buildLogoutButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'PROFILE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          NeumorphicIconButton(
            icon: Icons.settings,
            onPressed: widget.onNavigateToSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _animController.value)),
          child: Opacity(opacity: _animController.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: NeumorphicCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.user.email.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.user.email,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

              const SizedBox(height: 8),

              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppTheme.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.user.currentStreak} Day Streak',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.touch_app,
                  value: _formatNumber(widget.user.totalTaps),
                  label: 'Total Taps',
                  color: AppTheme.energyColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeumorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: SharedCoinDisplay(
                    amount: widget.user.appCoins,
                    iconSize: 28,
                    fontSize: 20,
                    showLabel: true,
                    isVertical: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  value: '${widget.user.daysActive}',
                  label: 'Days Active',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.flag,
                  value: '${widget.user.missionsCompleted}',
                  label: 'Missions Done',
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  value: '${widget.user.unlockedTiers.length}',
                  label: 'Tiers Unlocked',
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    IconData? icon,
    Widget? iconWidget,
    required String value,
    required String label,
    required Color color,
  }) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (iconWidget != null)
            iconWidget
          else
            Icon(icon!, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: widget.onLogout,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppTheme.error, size: 20),
            SizedBox(width: 8),
            Text(
              'LOG OUT',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildReferralSection() {
    final hasRedeemed = widget.user.referredBy != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: NeumorphicCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Refer & Earn',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Share your code to earn 2,000 ',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Image.asset('assets/AppCoin.png', width: 14, height: 14),
                const Text(
                  ' AC!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.user.referralCode,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white54),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.user.referralCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (!hasRedeemed) ...[
              const SizedBox(height: 20),
              NeumorphicButton(
                onPressed: _showRedeemReferralDialog,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'REDEEM CODE (+1000 ',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Image.asset('assets/AppCoin.png', width: 14, height: 14),
                      const Text(
                        ' AC)',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (hasRedeemed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Referred by: ${widget.user.referredBy}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRedeemReferralDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Redeem Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              NeumorphicTextField(
                controller: controller,
                hintText: 'Enter 6-digit code',
                prefixIcon: Icons.card_giftcard,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () async {
                        final code = controller.text.trim();
                        if (code.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid code length'),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close dialog

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const _ProcessingDialog(),
                        );

                        final success = await widget.gameService
                            .redeemReferralCode(code);

                        // Close loading
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }

                        if (!mounted) return;

                        if (success) {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code redeemed! +1000 AC Bonus!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to redeem code.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'REDEEM',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: NeumorphicDecoration.convex(borderRadius: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 24),
            Text(
              'Processing...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
