import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../../core/services/game_service.dart';

/// Neumorphic Container Widget
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isConvex;
  final bool isPressed;
  final Color? color;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.isConvex = false,
    this.isPressed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: isConvex
            ? NeumorphicDecoration.convex(borderRadius: borderRadius)
            : isPressed
            ? NeumorphicDecoration.flat(
                borderRadius: borderRadius,
                isPressed: true,
              )
            : NeumorphicDecoration.flat(
                color: color ?? AppTheme.surface,
                borderRadius: borderRadius,
              ),
        child: child,
      ),
    );
  }
}

/// Neumorphic Button with press animation
class NeumorphicButton extends StatefulWidget {
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
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(vertical: 18),
    this.backgroundColor,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: widget.padding,
            decoration: _isPressed
                ? NeumorphicDecoration.flat(
                    borderRadius: widget.borderRadius,
                    isPressed: true,
                  )
                : NeumorphicDecoration.convex(
                    borderRadius: widget.borderRadius,
                  ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Text Field
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
    return Container(
      decoration: NeumorphicDecoration.concave(),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 22),
          suffixIcon: suffixIcon,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Card
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
    this.borderRadius = 20,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: NeumorphicDecoration.flat(
              borderRadius: borderRadius,
              color: color ?? AppTheme.surface,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Icon Button
class NeumorphicIconButton extends StatefulWidget {
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
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
          HapticFeedback.lightImpact();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.size,
          height: widget.size,
          decoration: _isPressed
              ? NeumorphicDecoration.flat(
                  borderRadius: widget.size / 2,
                  isPressed: true,
                )
              : NeumorphicDecoration.convex(borderRadius: widget.size / 2),
          child: Icon(
            widget.icon,
            color: widget.iconColor ?? Colors.white70,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Progress Bar
class NeumorphicProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? progressColor;
  final Color? backgroundColor;
  final double borderRadius;
  final String? heroTag;

  const NeumorphicProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.progressColor,
    this.backgroundColor,
    this.borderRadius = 6,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget progressBar = Container(
      height: height,
      decoration: NeumorphicDecoration.concave(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  progressColor ?? AppTheme.primary,
                  (progressColor ?? AppTheme.primary).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: (progressColor ?? AppTheme.primary).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: progressBar);
    }
    return progressBar;
  }
}

/// Energy Progress Bar with glow
class EnergyBar extends StatelessWidget {
  final int current;
  final int max;
  final double height;

  const EnergyBar({
    super.key,
    required this.current,
    required this.max,
    this.height = 16,
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
    final isLow = percentage < 0.15; // Show refill below 15%

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
                const SizedBox(width: 4),
                const Text(
                  'Energy',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
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

/// Shared Coin Display with Hero animation for Data Continuity
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
            backgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Low Energy!',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Want to refill your energy to keep mining?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'NOT NOW',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              NeumorphicButton(
                onPressed: () {
                  Navigator.pop(context);
                  gameService.refillEnergyWithAC();
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: const Text(
                  'REFILL (2000 AC)',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child:
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3),
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
              .shimmer(duration: 1200.ms, color: Colors.white54)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 800.ms,
              ),
    );
  }
}

/// Premium SnackBar helper
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
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppTheme.surfaceLight,
        duration: duration,
        dismissDirection: DismissDirection.down,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: AppTheme.success,
      icon: Icons.check_circle_outline,
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
