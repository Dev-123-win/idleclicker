import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Physics-based tap button with iOS-like spring animation
class TapButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool enabled;
  final int cooldownSeconds;

  const TapButton({
    super.key,
    required this.onTap,
    this.enabled = true,
    this.cooldownSeconds = 0,
  });

  @override
  State<TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<TapButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;

  final List<_CoinParticle> _particles = [];
  final Random _random = Random();

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        )..addListener(() {
          setState(() {
            for (var i = _particles.length - 1; i >= 0; i--) {
              _particles[i].update();
              if (_particles[i].isDead) {
                _particles.removeAt(i);
              }
            }
          });
        });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.cooldownSeconds > 0) return;
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.cooldownSeconds > 0) return;
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _spawnParticles();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _spawnParticles() {
    for (int i = 0; i < 8; i++) {
      _particles.add(_CoinParticle(_random));
    }
    if (!_particleController.isAnimating) {
      _particleController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = AppDimensions.tapButtonSize;
    final disabled = !widget.enabled || widget.cooldownSeconds > 0;

    return SizedBox(
      width: size + 40,
      height: size + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle layer
          if (_particles.isNotEmpty)
            CustomPaint(
              size: Size(size + 40, size + 40),
              painter: _ParticlePainter(_particles),
            ),

          // Glow effect
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: size + 20,
                height: size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: disabled
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.gold.withValues(
                              alpha: 0.2 + (_glowController.value * 0.2),
                            ),
                            blurRadius: 20 + (_glowController.value * 15),
                            spreadRadius: 5 + (_glowController.value * 5),
                          ),
                        ],
                ),
              );
            },
          ),

          // Main button
          GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: disabled
                      ? LinearGradient(
                          colors: [AppColors.surfaceLight, AppColors.surface],
                        )
                      : AppColors.goldGradient,
                  boxShadow: _isPressed
                      // Pressed state - simulate inset with reduced shadow and darker color
                      ? [
                          BoxShadow(
                            color: AppColors.neumorphicDark.withValues(
                              alpha: 0.6,
                            ),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ]
                      // Normal state
                      : [
                          BoxShadow(
                            color: disabled
                                ? AppColors.neumorphicDark.withValues(
                                    alpha: 0.5,
                                  )
                                : AppColors.goldDark.withValues(alpha: 0.4),
                            offset: const Offset(0, 8),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: AppColors.neumorphicLight.withValues(
                              alpha: 0.1,
                            ),
                            offset: const Offset(0, -4),
                            blurRadius: 10,
                          ),
                        ],
                ),
                child: Center(
                  child: widget.cooldownSeconds > 0
                      ? _buildCooldownOverlay()
                      : _buildCoinIcon(disabled),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinIcon(bool disabled) {
    return Image.asset(
      'assets/AppCoin.png',
      width: AppDimensions.tapButtonIconSize,
      height: AppDimensions.tapButtonIconSize,
      color: disabled ? AppColors.textMuted : null,
      colorBlendMode: disabled ? BlendMode.saturation : null,
      errorBuilder: (_, __, ___) => Icon(
        Icons.touch_app,
        size: AppDimensions.tapButtonIconSize * 0.6,
        color: disabled ? AppColors.textMuted : AppColors.background,
      ),
    );
  }

  Widget _buildCooldownOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer, size: 40, color: AppColors.textMuted),
        const SizedBox(height: 8),
        Text(
          '${widget.cooldownSeconds}s',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Coin particle for burst effect
class _CoinParticle {
  double x = 0;
  double y = 0;
  double vx;
  double vy;
  double size;
  double alpha = 1.0;
  double rotation;
  double rotationSpeed;

  _CoinParticle(Random random)
    : vx = (random.nextDouble() - 0.5) * 8,
      vy = -random.nextDouble() * 8 - 4,
      size = random.nextDouble() * 12 + 8,
      rotation = random.nextDouble() * 2 * pi,
      rotationSpeed = (random.nextDouble() - 0.5) * 0.3;

  void update() {
    x += vx;
    y += vy;
    vy += 0.3; // Gravity
    alpha -= 0.03;
    rotation += rotationSpeed;
  }

  bool get isDead => alpha <= 0;
}

/// Particle painter for coin burst
class _ParticlePainter extends CustomPainter {
  final List<_CoinParticle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = AppColors.gold.withValues(alpha: particle.alpha);

      canvas.save();
      canvas.translate(center.dx + particle.x, center.dy + particle.y);
      canvas.rotate(particle.rotation);

      // Draw coin shape (ellipse)
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.7,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
