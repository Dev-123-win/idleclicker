import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';

/// Animated coin counter with number animation
class CoinCounter extends StatefulWidget {
  final int coins;
  final bool showRupees;
  final TextStyle? style;

  const CoinCounter({
    super.key,
    required this.coins,
    this.showRupees = true,
    this.style,
  });

  @override
  State<CoinCounter> createState() => _CoinCounterState();
}

class _CoinCounterState extends State<CoinCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousCoins = 0;
  int _displayCoins = 0;

  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _displayCoins = widget.coins;
    _previousCoins = widget.coins;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addListener(() {
      setState(() {
        _displayCoins =
            (_previousCoins +
                    ((_animation.value) * (widget.coins - _previousCoins)))
                .round();
      });
    });
  }

  @override
  void didUpdateWidget(CoinCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins) {
      _previousCoins = _displayCoins;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rupees = _displayCoins / 1000;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coin icon
            Image.asset(
              'assets/AppCoin.png',
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.monetization_on, color: AppColors.gold, size: 28),
            ),
            const SizedBox(width: 8),
            // Coin count
            Text(
              _formatter.format(_displayCoins),
              style:
                  widget.style ??
                  Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        if (widget.showRupees) ...[
          const SizedBox(height: 4),
          Text(
            '≈ ₹${rupees.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Compact coin display for headers
class CoinDisplay extends StatelessWidget {
  final int coins;

  const CoinDisplay({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.compact();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/AppCoin.png',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.monetization_on, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 6),
          Text(
            formatter.format(coins),
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
