import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/user_model.dart';
import '../../core/services/game_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';

class ReferralScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onBack;

  const ReferralScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
  });

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _codeController = TextEditingController();
  bool _isRedeeming = false;

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppSnackBar.error(context, 'Please enter a referral code');
      return;
    }

    if (code == widget.user.referralCode) {
      AppSnackBar.warning(context, 'You cannot use your own referral code');
      return;
    }

    setState(() => _isRedeeming = true);

    final success = await widget.gameService.redeemReferralCode(code);

    if (mounted) {
      setState(() => _isRedeeming = false);
      if (success) {
        AppSnackBar.success(
          context,
          'Referral code redeemed! You earned 2,500 AC',
        );
        _codeController.clear();
      } else {
        AppSnackBar.error(context, 'Invalid or expired referral code');
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRedeemed = widget.user.referredBy != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildIllustration(),
                    const SizedBox(height: 32),
                    _buildShareSection(),
                    const SizedBox(height: 32),
                    if (!hasRedeemed) ...[
                      _buildRedeemSection(),
                      const SizedBox(height: 32),
                    ],
                    _buildRulesSection(),
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
          NeumorphicIconButton(
            icon: Icons.arrow_back,
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          const Text(
            'REFER & EARN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add_outlined,
            size: 80,
            color: AppTheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Multiply Your Earnings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Invite friends and get paid per referral',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'YOUR REFERRAL CODE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: NeumorphicDecoration.concave(borderRadius: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.user.referralCode,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.user.referralCode),
                    );
                    AppSnackBar.success(context, 'Code copied to clipboard!');
                    HapticFeedback.mediumImpact();
                  },
                  child: const Icon(Icons.copy, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NeumorphicButton(
            onPressed: () {
              // In production, use Share Plus package
              Clipboard.setData(
                ClipboardData(
                  text:
                      'Join me on AppCoins! Use my code ${widget.user.referralCode} to get 2,500 AC bonus. Download now!',
                ),
              );
              AppSnackBar.success(context, 'Referral message copied!');
            },
            child: const Center(
              child: Text(
                'SHARE CODE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WERE YOU REFERRED?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: NeumorphicTextField(
                controller: _codeController,
                hintText: 'Enter Friend\'s Code',
                prefixIcon: Icons.card_giftcard,
              ),
            ),
            const SizedBox(width: 16),
            NeumorphicIconButton(
              icon: Icons.check,
              onPressed: _isRedeeming ? null : _redeemCode,
              iconColor: AppTheme.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOW IT WORKS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildRuleStep(
          '1',
          'Share your referral code with your friends and family.',
        ),
        _buildRuleStep(
          '2',
          'Ask them to enter your code during their registration or in their profile.',
        ),
        _buildRuleStep(
          '3',
          'Once they enter your code, BOTH of you get a reward!',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: AppTheme.primary),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Your friend gets 2,500 AC instantly. You get 2,000 AC for every referral!',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleStep(String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
