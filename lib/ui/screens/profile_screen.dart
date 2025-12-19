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

  const ProfileScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _upiController = TextEditingController();
  late AnimationController _animController;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _upiController.text = widget.user.upiId ?? '';
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

    _upiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showWithdrawDialog() {
    if (!widget.user.canWithdraw) {
      AppSnackBar.warning(
        context,
        'Need ${100000 - widget.user.appCoins} more AC to withdraw',
      );
      return;
    }

    // Check if UPI is set
    if (widget.user.upiId == null || widget.user.upiId!.isEmpty) {
      AppSnackBar.warning(context, 'Please add your UPI ID first');
      _showEditUpiDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _WithdrawDialog(
        user: widget.user,
        onConfirm: () async {
          Navigator.pop(context);
          await _processWithdrawal();
        },
      ),
    );
  }

  Future<void> _processWithdrawal() async {
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ProcessingDialog(),
    );

    // Process withdrawal via GameService
    final success = await widget.gameService.requestWithdrawal(
      amount: 100000,
      upiId: widget.user.upiId!,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Close processing dialog

    if (success) {
      HapticFeedback.heavyImpact();
      AppSnackBar.success(
        context,
        'Withdrawal request submitted! Processing in 7-10 days.',
      );
    } else {
      AppSnackBar.error(context, 'Withdrawal failed. Please try again.');
    }
  }

  void _showEditUpiDialog() {
    final controller = TextEditingController(text: widget.user.upiId ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter UPI ID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your earnings will be sent to this UPI ID',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 24),
              NeumorphicTextField(
                controller: controller,
                hintText: 'yourname@upi',
                prefixIcon: Icons.account_balance,
                keyboardType: TextInputType.text,
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
                        final upi = controller.text.trim();
                        if (upi.isEmpty || !upi.contains('@')) {
                          AppSnackBar.error(
                            context,
                            'Please enter a valid UPI ID',
                          );
                          return;
                        }

                        Navigator.pop(context);
                        await widget.gameService.updateUpiId(upi);
                        if (!mounted) return;
                        setState(() {});

                        AppSnackBar.success(
                          context,
                          'UPI ID updated successfully',
                        );
                      },
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Text(
                        'SAVE',
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

  void _showLanguageDialog() {
    final languages = ['English', 'हिंदी', 'தமிழ்', 'తెలుగు', 'ಕನ್ನಡ'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...languages.map(
                (lang) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(context);
                    AppSnackBar.success(context, 'Language changed to $lang');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _selectedLanguage == lang
                          ? AppTheme.primary.withOpacity(0.2)
                          : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedLanguage == lang
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        lang,
                        style: TextStyle(
                          color: _selectedLanguage == lang
                              ? AppTheme.primary
                              : Colors.white,
                          fontWeight: _selectedLanguage == lang
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CyberBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildProfileCard(),
                _buildStatsGrid(),
                _buildReferralSection(),
                _buildWithdrawSection(),
                _buildAccountSettings(),
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          NeumorphicIconButton(
            icon: Icons.arrow_back,
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          const Text(
            'PROFILE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
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
                      color: AppTheme.primary.withOpacity(0.4),
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
                  color: AppTheme.warning.withOpacity(0.2),
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
                child: _buildStatCard(
                  icon: Icons.toll,
                  value: _formatNumber(widget.user.appCoins),
                  label: 'AppCoins',
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.play_circle_filled,
                  value: '${widget.user.totalAdsWatched}',
                  label: 'Ads Watched',
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 16),
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
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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

  Widget _buildWithdrawSection() {
    final progress = widget.user.appCoins / 100000;
    final canWithdraw = widget.user.canWithdraw;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeumorphicCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Withdrawal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '₹${widget.user.withdrawableAmountInr.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            NeumorphicProgressBar(value: progress.clamp(0.0, 1.0), height: 12),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.user.appCoins} / 100,000 AC',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  canWithdraw
                      ? 'Ready!'
                      : '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: canWithdraw ? AppTheme.success : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            NeumorphicButton(
              onPressed: _showWithdrawDialog,
              backgroundColor: canWithdraw ? null : AppTheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canWithdraw ? Icons.account_balance_wallet : Icons.lock,
                    color: canWithdraw ? Colors.black : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    canWithdraw ? 'WITHDRAW ₹100' : 'MIN ₹100 REQUIRED',
                    style: TextStyle(
                      color: canWithdraw ? Colors.black : Colors.white38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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

  Widget _buildAccountSettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: NeumorphicCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 16),

            // UPI ID
            _buildSettingItem(
              icon: Icons.account_balance,
              title: 'UPI ID',
              value: widget.user.upiId ?? 'Not set',
              onTap: _showEditUpiDialog,
            ),

            const Divider(color: Colors.white12),

            // Language
            _buildSettingItem(
              icon: Icons.language,
              title: 'Language',
              value: _selectedLanguage,
              onTap: _showLanguageDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
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
            const Text(
              'Share your code to earn 2,000 AC!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
                child: const Center(
                  child: Text(
                    'REDEEM CODE (+1000 AC)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
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

/// Withdraw Dialog
class _WithdrawDialog extends StatelessWidget {
  final UserModel user;
  final VoidCallback onConfirm;

  const _WithdrawDialog({required this.user, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    const withdrawAmount = 100000; // Minimum withdrawal
    const fee = 2000; // Transaction fee
    const netAmount = withdrawAmount - fee;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: NeumorphicDecoration.convex(borderRadius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: AppTheme.primary,
              size: 48,
            ),

            const SizedBox(height: 16),

            const Text(
              'Confirm Withdrawal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            _buildRow('Amount', '$withdrawAmount AC', '₹100'),
            _buildRow('Transaction Fee', '-$fee AC', '-₹2'),
            const Divider(color: Colors.white24, height: 24),
            _buildRow(
              'You Receive',
              '',
              '₹${(netAmount / 1000).toStringAsFixed(0)}',
              isTotal: true,
            ),

            const SizedBox(height: 8),

            Text(
              'Processing time: 7-10 business days',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
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
                    onPressed: onConfirm,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: const Text(
                      'CONFIRM',
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
    );
  }

  Widget _buildRow(
    String label,
    String ac,
    String inr, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white70,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              if (ac.isNotEmpty)
                Text(
                  ac,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              if (ac.isNotEmpty) const SizedBox(width: 8),
              Text(
                inr,
                style: TextStyle(
                  color: isTotal ? AppTheme.primary : Colors.white,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Processing Dialog
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
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Processing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Please wait', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
