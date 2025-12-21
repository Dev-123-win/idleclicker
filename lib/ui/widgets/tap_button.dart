import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// High-performance tap button with unique physics-based animations
/// Designed for instant UI feedback with optimistic updates
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
  late AnimationController _rippleController;
  late AnimationController _glowController;

  final List<_TapRipple> _ripples = [];
  final List<_EnergyParticle> _particles = [];
  final math.Random _random = math.Random();

  bool _isPressed = false;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Ultra-fast scale animation for instant feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 30),
      vsync: this,
    );

    // Continuous pulse for idle state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

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
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;

    setState(() {
      _isPressed = false;
      _tapCount++;
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
              duration: const Duration(milliseconds: 500),
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
    final particleCount = 6 + _random.nextInt(4);

    for (int i = 0; i < particleCount; i++) {
      final angle =
          (i / particleCount) * 2 * math.pi + _random.nextDouble() * 0.5;
      final velocity = 150 + _random.nextDouble() * 100;
      final size = 3.0 + _random.nextDouble() * 4;

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
                duration: Duration(milliseconds: 400 + _random.nextInt(200)),
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
    _rippleController.dispose();
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

          // Ripple effects
          ..._ripples.map(
            (ripple) => AnimatedBuilder(
              animation: ripple.controller,
              builder: (context, child) {
                final scale = 1 + ripple.controller.value * 2;
                final opacity = 1 - ripple.controller.value;

                return Positioned(
                  left: ripple.position.dx - 25,
                  top: ripple.position.dy - 25,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(
                            alpha: opacity * 0.5,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Energy particles
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

          // Main tap button
          GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleController, _pulseController]),
              builder: (context, child) {
                final baseScale = 1.0 - (_scaleController.value * 0.08);
                final pulseScale = widget.isEnabled && !_isPressed
                    ? 1.0 + (_pulseController.value * 0.02)
                    : 1.0;

                return Transform.scale(
                  scale: baseScale * pulseScale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.isEnabled
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.surfaceLight,
                                AppTheme.surface,
                                AppTheme.surfaceDark,
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade800,
                                Colors.grey.shade900,
                              ],
                            ),
                      boxShadow: [
                        // Outer shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: _isPressed
                              ? const Offset(2, 2)
                              : const Offset(6, 6),
                          blurRadius: _isPressed ? 8 : 16,
                        ),
                        // Inner highlight
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          offset: _isPressed
                              ? const Offset(-1, -1)
                              : const Offset(-4, -4),
                          blurRadius: _isPressed ? 4 : 12,
                        ),
                        // Glow effect when active
                        if (widget.isEnabled)
                          BoxShadow(
                            color: AppTheme.primary.withValues(
                              alpha: 0.1 + (_glowController.value * 0.1),
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                      ],
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
                            color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                          ),
                          child: Icon(
                            widget.isAutoClickerActive
                                ? Icons.settings
                                : Icons.touch_app,
                            size: 48,
                            color: widget.isEnabled
                                ? AppTheme.primary
                                : Colors.grey,
                          ),
                        ),

                        // Tap counter badge
                        if (_tapCount > 0)
                          Positioned(
                            bottom: 16,
                            child: AnimatedOpacity(
                              opacity: _tapCount % 10 == 0 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+${_tapCount % 10 == 0 ? 10 : _tapCount % 10}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Auto-clicker indicator
          if (widget.isAutoClickerActive)
            Positioned(
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.energyColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'AUTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, bgPaint);

    // Energy arc
    final arcPaint = Paint()
      ..color = isActive
          ? Color.lerp(AppTheme.energyColor, AppTheme.primary, glowIntensity)!
          : Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
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
    if (isActive && progress > 0) {
      final glowPaint = Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.1 + glowIntensity * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
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
