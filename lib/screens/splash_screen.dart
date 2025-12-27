import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';

/// Animated splash screen with coin drop physics
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _coinController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Coin drop animation
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Particle animation
    _particleController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2000),
        )..addListener(() {
          setState(() {
            for (var particle in _particles) {
              particle.update();
            }
            _particles.removeWhere((p) => p.isDead);
          });
        });

    // Generate particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(_random));
    }

    // Start animations
    _coinController.forward();
    _particleController.repeat();

    // Trigger completion after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _coinController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.surface,
                  AppColors.background,
                ],
              ),
            ),
          ),

          // Particle layer
          CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(_particles),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated coin with glow
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(
                              alpha: 0.3 + (_glowController.value * 0.3),
                            ),
                            blurRadius: 30 + (_glowController.value * 20),
                            spreadRadius: 5 + (_glowController.value * 10),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: _buildCoin(),
                ),

                const SizedBox(height: 40),

                // App name
                Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                Text(
                  'Tap. Earn. Withdraw.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ).animate(delay: 1200.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 60),

                // Loading indicator
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ).animate(delay: 1400.ms).fadeIn().scaleX(begin: 0, end: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoin() {
    return AnimatedBuilder(
      animation: _coinController,
      builder: (context, child) {
        // Bounce physics
        final progress = _coinController.value;
        final bounce = _calculateBounce(progress);

        // Rotation during fall
        final rotation = progress * 2 * pi;

        return Transform.translate(
          offset: Offset(0, -200 * (1 - bounce)),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(scale: 0.5 + (bounce * 0.5), child: child),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.goldGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.goldDark.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/AppCoin.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.monetization_on,
                size: 60,
                color: AppColors.background.withValues(alpha: 0.8),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Calculate bounce animation value
  double _calculateBounce(double t) {
    if (t < 0.6) {
      // Fall down
      return Curves.easeIn.transform(t / 0.6);
    } else if (t < 0.75) {
      // First bounce up
      final bounceT = (t - 0.6) / 0.15;
      return 1.0 - (0.15 * Curves.easeOut.transform(bounceT));
    } else if (t < 0.85) {
      // First bounce down
      final bounceT = (t - 0.75) / 0.1;
      return 0.85 + (0.15 * Curves.easeIn.transform(bounceT));
    } else if (t < 0.92) {
      // Second bounce up
      final bounceT = (t - 0.85) / 0.07;
      return 1.0 - (0.05 * Curves.easeOut.transform(bounceT));
    } else {
      // Settle
      final bounceT = (t - 0.92) / 0.08;
      return 0.95 + (0.05 * Curves.easeIn.transform(bounceT));
    }
  }
}

/// Particle class for gold sparkles
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;
  double life;
  final Random random;

  _Particle(this.random)
    : x = random.nextDouble() * 400,
      y = random.nextDouble() * 800,
      vx = (random.nextDouble() - 0.5) * 2,
      vy = -random.nextDouble() * 2 - 0.5,
      size = random.nextDouble() * 4 + 2,
      alpha = random.nextDouble() * 0.6 + 0.2,
      life = 1.0;

  void update() {
    x += vx;
    y += vy;
    life -= 0.005;
    alpha = life * 0.6;

    if (life <= 0) {
      // Respawn
      x = random.nextDouble() * 400;
      y = 800 + random.nextDouble() * 100;
      life = 1.0;
    }
  }

  bool get isDead => false; // Particles respawn
}

/// Painter for particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = AppColors.gold.withValues(alpha: particle.alpha);
      canvas.drawCircle(
        Offset(
          (particle.x / 400) * size.width,
          (particle.y / 800) * size.height,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
