import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../../core/services/game_service.dart';

/// Wraps standard Material widgets to replace Neumorphic widgets
/// while keeping the same API surface for the rest of the app.

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? color;
  // Ignored parameters kept for API compatibility:
  final bool isConvex;
  final bool isPressed;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.isConvex = false,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class NeumorphicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primary,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : child,
    );
  }
}

class NeumorphicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const NeumorphicTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 16,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      color: color ?? AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon, size: size * 0.5, color: iconColor),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.surfaceVariant,
        fixedSize: Size(size, size),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class NeumorphicProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? progressColor;
  final Color? backgroundColor;
  final double borderRadius;
  final String? heroTag;

  const NeumorphicProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.progressColor,
    this.backgroundColor,
    this.borderRadius = 4,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget bar = LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: height,
      backgroundColor: backgroundColor ?? AppTheme.surfaceVariant,
      color: progressColor ?? AppTheme.primary,
      borderRadius: BorderRadius.circular(borderRadius),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: bar);
    }
    return bar;
  }
}

// NeumorphicDecoration class removed; imported from app_theme.dart

// ------ Existing Logic Components (Unchanged logic, updated visuals) ------

class EnergyBar extends StatelessWidget {
  final int current;
  final int max;
  final double height;

  const EnergyBar({
    super.key,
    required this.current,
    required this.max,
    this.height = 12,
  });

  Color _getEnergyColor() {
    final percentage = current / max;
    if (percentage > 0.7) return AppTheme.energyColor;
    if (percentage > 0.2) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = current / max;
    final isLow = percentage < 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isLow ? Icons.battery_alert_rounded : Icons.bolt,
                  color: _getEnergyColor(),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Energy',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isLow)
              const RefillButton()
            else
              Text(
                '$current / $max',
                style: TextStyle(
                  color: _getEnergyColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        NeumorphicProgressBar(
          value: current / max,
          height: height,
          progressColor: _getEnergyColor(),
          heroTag: 'energy_bar',
        ),
      ],
    );
  }
}

class SharedCoinDisplay extends StatelessWidget {
  final int amount;
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final bool isVertical;
  final MainAxisAlignment alignment;

  const SharedCoinDisplay({
    super.key,
    required this.amount,
    this.iconSize = 24,
    this.fontSize = 20,
    this.showLabel = false,
    this.isVertical = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'coin_display',
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            return DefaultTextStyle(
              style: DefaultTextStyle.of(toHeroContext).style,
              child: toHeroContext.widget,
            );
          },
      child: Material(
        color: Colors.transparent,
        child: isVertical ? _buildVertical() : _buildHorizontal(),
      ),
    );
  }

  Widget _buildHorizontal() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Image.asset('assets/AppCoin.png', width: iconSize, height: iconSize),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatNumber(amount),
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showLabel)
              const Text(
                'AppCoins',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVertical() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/AppCoin.png', width: iconSize, height: iconSize),
        const SizedBox(height: 4),
        Text(
          _formatNumber(amount),
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showLabel)
          const Text(
            'AppCoins',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
      ],
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
}

class RefillButton extends StatelessWidget {
  const RefillButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final gameService = context.read<GameService>();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Low Energy!'),
            content: const Text('Want to refill your energy to keep mining?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('NOT NOW'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  gameService.refillEnergyWithAC();
                },
                child: const Text('REFILL (2000 AC)'),
              ),
            ],
          ),
        );
      },
      child:
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: AppTheme.error, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'REFILL',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
    );
  }
}

/// Helper for standard SnackBars
class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black, // Better contrast on light bg
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: AppTheme.success,
      icon: Icons.check_circle,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: AppTheme.error,
      icon: Icons.error_outline,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: AppTheme.warning,
      icon: Icons.warning_amber_rounded,
    );
  }
}
