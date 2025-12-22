import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/game_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';

class WithdrawalScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onBack;

  const WithdrawalScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  bool _isProcessing = false;

  Future<void> _processWithdrawal() async {
    if (!widget.user.canWithdraw) {
      AppSnackBar.warning(
        context,
        'Need ${100000 - widget.user.appCoins} more AC to withdraw',
      );
      return;
    }

    if (widget.user.upiId == null || widget.user.upiId!.isEmpty) {
      AppSnackBar.warning(context, 'Please set your UPI ID first');
      _showEditUpiDialog();
      return;
    }

    setState(() => _isProcessing = true);

    final success = await widget.gameService.requestWithdrawal(
      amount: 100000,
      upiId: widget.user.upiId!,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        AppSnackBar.success(
          context,
          'Withdrawal request submitted! Processing in 7-10 days.',
        );
      } else {
        AppSnackBar.error(
          context,
          'Withdrawal failed. Please try again later.',
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final progress = widget.user.appCoins / 100000;
    final canWithdraw = widget.user.canWithdraw;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildProgressSection(progress, canWithdraw),
                    const SizedBox(height: 24),
                    _buildPaymentDetailsSection(),
                    const SizedBox(height: 32),
                    _buildRulesSection(),
                    const SizedBox(height: 32),
                    _buildWithdrawButton(canWithdraw),
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
            'WITHDRAW',
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

  Widget _buildBalanceCard() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(24),
      color: AppTheme.surfaceDark,
      child: Column(
        children: [
          const Text(
            'WITHDRAWABLE BALANCE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.user.withdrawableAmountInr.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/AppCoin.png', width: 16, height: 16),
              const SizedBox(width: 6),
              Text(
                '${widget.user.appCoins} AC',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress, bool canWithdraw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Withdrawal Progress',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              canWithdraw ? 'READY' : '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: canWithdraw ? AppTheme.success : AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NeumorphicProgressBar(
          value: progress.clamp(0.0, 1.0),
          height: 16,
          progressColor: canWithdraw ? AppTheme.success : AppTheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          canWithdraw
              ? 'Congratulations! You have reached the minimum threshold.'
              : 'Earn ${100000 - widget.user.appCoins} more AC to unlock withdrawal.',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WITHDRAWAL RULES',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildRuleItem(
          Icons.payments_outlined,
          'Minimum Withdrawal',
          'The minimum withdrawal amount is ₹100 (100,000 AC).',
        ),
        _buildRuleItem(
          Icons.timer_outlined,
          'Processing Time',
          'Withdrawals are manually verified and processed within 7-10 business days.',
        ),
        _buildRuleItem(
          Icons.refresh_outlined,
          'Cooldown Period',
          'You can only withdraw once every 15 days to ensure system stability.',
        ),
        _buildRuleItem(
          Icons.security_outlined,
          'Account Integrity',
          'Any use of scripts, bots, or multiple accounts for farming will result in permanent ban.',
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        NeumorphicCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: NeumorphicDecoration.flat(borderRadius: 12),
                child: const Icon(
                  Icons.account_balance,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPI ID',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    Text(
                      widget.user.upiId?.isNotEmpty == true
                          ? widget.user.upiId!
                          : 'Not set yet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              NeumorphicIconButton(
                icon: Icons.edit_outlined,
                onPressed: _showEditUpiDialog,
                size: 40,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: NeumorphicDecoration.flat(
              borderRadius: 10,
            ).copyWith(color: AppTheme.surfaceLight.withValues(alpha: 0.1)),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton(bool canWithdraw) {
    return NeumorphicButton(
      onPressed: canWithdraw && !_isProcessing ? _processWithdrawal : null,
      isLoading: _isProcessing,
      backgroundColor: canWithdraw ? null : AppTheme.surface,
      child: Center(
        child: Text(
          canWithdraw ? 'REQUEST WITHDRAWAL' : 'MIN ₹100 REQUIRED',
          style: TextStyle(
            color: canWithdraw ? Colors.black : Colors.white24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
