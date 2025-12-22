import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Material 3 physics-based tap button with fluid animations
/// Designed for instant UI feedback with realistic touch response
class TapButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isEnabled;
  final bool isAutoClickerActive;
  final int currentEnergy;
  final int maxEnergy;

  const TapButton({
    super.key,
    required this.onTap,
    this.isEnabled = true,
    this.isAutoClickerActive = false,
    this.currentEnergy = 100,
    this.maxEnergy = 100,
  });

  @override
  State<TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<TapButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  final List<_TapRipple> _ripples = [];
  final List<_EnergyParticle> _particles = [];
  final math.Random _random = math.Random();

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Ultra-fast scale animation for instant feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    // Continuous pulse for idle state (slower, more subtle in Material 3)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    // Glow animation for energy state
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;

    setState(() => _isPressed = true);
    _scaleController.forward();

    // Instant haptic feedback
    if (widget.currentEnergy <= 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact(); // Crisp click feel
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;

    setState(() {
      _isPressed = false;
    });

    _scaleController.reverse();

    // Trigger tap callback immediately (optimistic update)
    widget.onTap();

    // Add ripple effect at tap location
    _addRipple(details.localPosition);

    // Spawn energy particles
    _spawnParticles(details.localPosition);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _addRipple(Offset position) {
    final ripple = _TapRipple(
      position: position,
      controller:
          AnimationController(
              duration: const Duration(milliseconds: 600),
              vsync: this,
            )
            ..forward().then((_) {
              setState(() {
                _ripples.removeWhere((r) => r.position == position);
              });
            }),
    );

    setState(() => _ripples.add(ripple));
  }

  void _spawnParticles(Offset center) {
    final particleCount = 8 + _random.nextInt(4);

    for (int i = 0; i < particleCount; i++) {
      final angle =
          (i / particleCount) * 2 * math.pi + _random.nextDouble() * 0.5;
      final velocity = 100 + _random.nextDouble() * 100;
      final size = 4.0 + _random.nextDouble() * 4;

      final particle = _EnergyParticle(
        position: center,
        velocity: Offset(
          math.cos(angle) * velocity,
          math.sin(angle) * velocity,
        ),
        size: size,
        color: _random.nextBool() ? AppTheme.primary : AppTheme.energyColor,
        controller:
            AnimationController(
                duration: Duration(milliseconds: 500 + _random.nextInt(300)),
                vsync: this,
              )
              ..forward().then((_) {
                setState(() {
                  _particles.removeWhere((p) => p.position == center);
                });
              }),
      );

      setState(() => _particles.add(particle));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    for (final particle in _particles) {
      particle.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energyPercent = widget.currentEnergy / widget.maxEnergy;
    // Calculate button scale based on press state and pulse
    final baseScale =
        1.0 - (_scaleController.value * 0.05); // Subtle compression
    final pulseScale = widget.isEnabled && !_isPressed
        ? 1.0 + (_pulseController.value * 0.02)
        : 1.0;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Energy ring indicator
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: _EnergyRingPainter(
                  progress: energyPercent,
                  glowIntensity: _glowController.value,
                  isActive: widget.isEnabled,
                ),
              );
            },
          ),

          // Main tap button with Physics-based Material 3 feel
          GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleController, _pulseController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: baseScale * pulseScale,
                  child: Container(
                    width: 160,
                    height: 160,
                    // Material 3 Physical Model
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Gradient surface for depth
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isEnabled
                            ? _isPressed
                                  ? [
                                      AppTheme.surfaceVariant,
                                      AppTheme.surfaceVariant,
                                    ] // Flat when pressed
                                  : [
                                      AppTheme
                                          .surfaceLight, // Highlight top-left
                                      const Color(
                                        0xFF1A1A1A,
                                      ), // Shadow bottom-right
                                    ]
                            : [Colors.grey.shade900, Colors.grey.shade900],
                      ),
                      // Physical shadow (elevation)
                      boxShadow: widget.isEnabled && !_isPressed
                          ? [
                              // Ambient Shadow
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 10),
                                blurRadius: 20,
                              ),
                              // Key Light Shadow (Primary Color Glow)
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              // Reduced shadow when pressed
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: const Offset(0, 2),
                                blurRadius: 5,
                              ),
                            ],
                      border: Border.all(
                        color: widget.isEnabled
                            ? AppTheme.primary.withValues(alpha: 0.3)
                            : Colors.white10,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Inner circle with icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 5,
                                spreadRadius: -2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              Icon(
                                    widget.isAutoClickerActive
                                        ? Icons.settings
                                        : Icons.touch_app_rounded,
                                    size: 48,
                                    color: widget.isEnabled
                                        ? AppTheme.primary
                                        : Colors.grey,
                                  )
                                  .animate(
                                    target: widget.isAutoClickerActive ? 1 : 0,
                                  )
                                  .rotate(
                                    duration: 2.seconds,
                                    curve: Curves.linear,
                                  ),
                        ),

                        // Ripples (Rendered inside the button bounds)
                        ..._ripples.map((ripple) {
                          return AnimatedBuilder(
                            animation: ripple.controller,
                            builder: (context, child) {
                              final progress = ripple.controller.value;
                              final opacity = 1.0 - progress;

                              return Positioned(
                                left:
                                    ripple.position.dx -
                                    80 -
                                    10, // Relative to center
                                top: ripple.position.dy - 80 - 10,
                                child:
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: opacity * 0.3,
                                        ),
                                      ),
                                    ).animate().scale(
                                      begin: const Offset(0, 0),
                                      end: const Offset(5, 5),
                                      duration: 600.ms,
                                    ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Tap particles (outside)
          ..._particles.map(
            (particle) => AnimatedBuilder(
              animation: particle.controller,
              builder: (context, child) {
                final progress = particle.controller.value;
                final opacity = 1 - progress;
                final offset = particle.velocity * progress;

                return Positioned(
                  left: particle.position.dx + offset.dx - particle.size / 2,
                  top: particle.position.dy + offset.dy - particle.size / 2,
                  child: Container(
                    width: particle.size,
                    height: particle.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: particle.color.withValues(alpha: opacity),
                      boxShadow: [
                        BoxShadow(
                          color: particle.color.withValues(
                            alpha: opacity * 0.5,
                          ),
                          blurRadius: particle.size * 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Auto-clicker badge
          if (widget.isAutoClickerActive)
            Positioned(
              top: 0,
              child:
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.energyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.energyColor.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.energyColor.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: AppTheme.energyColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AUTO ACTIVE',
                              style: TextStyle(
                                color: AppTheme.energyColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds, color: Colors.white24),
            ),
        ],
      ),
    );
  }
}

/// Energy ring painter for visual feedback
class _EnergyRingPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final bool isActive;

  _EnergyRingPainter({
    required this.progress,
    required this.glowIntensity,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, bgPaint);

    if (!isActive) return;

    // Energy arc
    final arcPaint = Paint()
      ..color = Color.lerp(
        AppTheme.energyColor,
        AppTheme.primary,
        glowIntensity,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Glow effect
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.2 + glowIntensity * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at top
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isActive != isActive;
  }
}

/// Tap ripple effect data
class _TapRipple {
  final Offset position;
  final AnimationController controller;

  _TapRipple({required this.position, required this.controller});
}

/// Energy particle data
class _EnergyParticle {
  final Offset position;
  final Offset velocity;
  final double size;
  final Color color;
  final AnimationController controller;

  _EnergyParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.controller,
  });
}
