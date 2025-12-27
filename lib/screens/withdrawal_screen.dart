import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/game_service.dart';
import '../services/sync_service.dart';
import '../services/service_locator.dart';

/// Withdrawal screen with UPI integration
class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _upiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _currentStatus;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenToWithdrawalStatus();
  }

  void _loadUserData() {
    final user = getService<GameService>().user;
    if (user != null) {
      _upiController.text = user.upiId ?? '';
      _currentStatus = user.withdrawalStatus;
    }
  }

  void _listenToWithdrawalStatus() {
    final user = getService<GameService>().user;
    if (user != null) {
      _statusSubscription = getService<SyncService>().listenToWithdrawalStatus(
        user.uid,
        (status) {
          if (mounted) {
            setState(() => _currentStatus = status);
            if (status == 'completed') {
              _showCompletedDialog();
            }
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    final gameService = getService<GameService>();
    if (!gameService.canWithdraw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 100,000 coins required for withdrawal'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = gameService.user!;
      final withdrawAmount = user.totalCoins;

      // Update Firestore with withdrawal request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'withdrawalStatus': 'pending',
            'upiId': _upiController.text.trim(),
            'pendingWithdrawalAmount': withdrawAmount,
            'lastWithdrawalDate': DateTime.now().toIso8601String(),
          });

      // Reset local coins (will be confirmed when admin approves)
      setState(() {
        _currentStatus = 'pending';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'Withdrawal Complete!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: 8),
            Text(
              'Money has been sent to your UPI account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameService = getService<GameService>();
    final coins = gameService.currentCoins;
    final rupees = gameService.coinsInRupees;
    final canWithdraw = gameService.canWithdraw;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Withdraw'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance card
              Container(
                padding: const EdgeInsets.all(AppDimensions.lg),
                decoration: NeumorphicDecoration.flat(),
                child: Column(
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/AppCoin.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.monetization_on,
                            size: 32,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$coins',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '= ₹${rupees.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              // Minimum amount info
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: canWithdraw
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      canWithdraw ? Icons.check_circle : Icons.info,
                      color: canWithdraw
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        canWithdraw
                            ? 'You can withdraw ₹${rupees.toStringAsFixed(0)}'
                            : 'Minimum ₹100 (100,000 coins) required',
                        style: TextStyle(
                          color: canWithdraw
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 24),

              // Current status
              if (_currentStatus != null)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _currentStatus!,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: _getStatusColor(
                        _currentStatus!,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(_currentStatus!),
                        color: _getStatusColor(_currentStatus!),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Withdrawal Status',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _currentStatus!.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(_currentStatus!),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              // UPI field
              Text(
                'UPI ID',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: NeumorphicDecoration.flat(),
                child: TextFormField(
                  controller: _upiController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'yourname@upi',
                    prefixIcon: Icon(
                      Icons.account_balance,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppDimensions.md),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'UPI ID is required';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9._-]+@[a-zA-Z]{3,}$',
                    ).hasMatch(value)) {
                      return 'Enter a valid UPI ID';
                    }
                    return null;
                  },
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 24),

              // Withdraw button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      canWithdraw && _currentStatus != 'pending' && !_isLoading
                      ? _submitWithdrawal
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.surfaceLight,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _currentStatus == 'pending'
                              ? 'Withdrawal Pending...'
                              : 'Withdraw ₹${rupees.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Info
              Text(
                '• Withdrawals are processed within 24-48 hours\n'
                '• Missions will reset after successful withdrawal\n'
                '• Money will be sent directly to your UPI account',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }
}
