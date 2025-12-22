import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../ui/theme/app_theme.dart';

/// Physics-based Splash Screen with unique "Gold Strike" animation
/// Pure Flutter code - no external assets required
///
/// Now waits for [initializationFuture] to complete before calling [onComplete].
/// If initialization finishes before the minimum animation duration, animation continues.
/// If animation finishes before initialization, it loops until ready.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Future<void>? initializationFuture;

  const SplashScreen({
    super.key,
    required this.onComplete,
    this.initializationFuture,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _springController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _ringExpand;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  final List<GoldParticle> _particles = [];
  final math.Random _random = math.Random();

  // Spring physics for bouncy logo
  late SpringSimulation _springSimulation;
  double _springValue = 0.0;

  bool _initializationComplete = false;
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Main controller for logo entrance
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Particle system controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Pulse controller for glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Spring controller for physics bounce
    _springController = AnimationController(vsync: this);

    // Logo scale with overshoot curve
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Logo opacity
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Ring expansion
    _ringExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutQuart),
      ),
    );

    // Text slide up
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Text opacity
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    // Spring physics setup
    const spring = SpringDescription(mass: 1, stiffness: 200, damping: 10);
    _springSimulation = SpringSimulation(spring, 0, 1, 5);

    _springController.addListener(() {
      setState(() {
        _springValue = _springSimulation.x(_springController.value);
      });
    });
  }

  void _generateParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(
        GoldParticle(
          angle: _random.nextDouble() * 2 * math.pi,
          speed: 100 + _random.nextDouble() * 200,
          size: 2 + _random.nextDouble() * 4,
          delay: _random.nextDouble() * 0.5,
          lifetime: 0.5 + _random.nextDouble() * 0.5,
          rotationSpeed: (_random.nextDouble() - 0.5) * 10,
          isGold: _random.nextDouble() > 0.3,
        ),
      );
    }
  }

  void _startAnimationSequence() async {
    // Start main animation
    _mainController.forward();

    // Start particle burst after logo appears
    await Future.delayed(const Duration(milliseconds: 500));
    _particleController.forward();

    // Start spring bounce
    _springController.animateTo(
      1.0,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
    );

    // Start listening for initialization completion in parallel
    _waitForInitialization();

    // Wait for minimum animation time (2.5 seconds from start)
    await Future.delayed(const Duration(milliseconds: 2500));
    _animationComplete = true;

    // Check if we can complete now
    _checkAndComplete();
  }

  void _waitForInitialization() async {
    if (widget.initializationFuture != null) {
      await widget.initializationFuture;
    }
    _initializationComplete = true;
    _checkAndComplete();
  }

  void _checkAndComplete() {
    // Only complete when BOTH animation is done AND initialization is done
    if (_animationComplete && _initializationComplete && mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [AppTheme.surface, AppTheme.background, Colors.black],
              ),
            ),
          ),

          // Particle system
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  centerX: MediaQuery.of(context).size.width / 2,
                  centerY: MediaQuery.of(context).size.height / 2 - 50,
                ),
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated rings
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        _buildRing(
                          size: 200 * _ringExpand.value,
                          opacity: 0.2 * _ringExpand.value,
                        ),
                        // Middle ring
                        _buildRing(
                          size: 160 * _ringExpand.value,
                          opacity: 0.4 * _ringExpand.value,
                        ),
                        // Inner ring with pulse
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return _buildRing(
                              size: 120 * _ringExpand.value,
                              opacity:
                                  (0.6 + _pulseController.value * 0.4) *
                                  _ringExpand.value,
                              isGlow: true,
                            );
                          },
                        ),
                        // Logo
                        child!,
                      ],
                    );
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_mainController]),
                    builder: (context, _) {
                      final bounceScale = _springValue.clamp(0.0, 1.2);
                      return Transform.scale(
                        scale: _logoScale.value * (0.8 + bounceScale * 0.2),
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // App name with slide animation
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.primaryDark,
                                    AppTheme.primary,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              child: Text(
                                'TAPMINE',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 8,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TAP • EARN • WITHDRAW',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.accent,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w300,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, _) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Column(
                    children: [
                      // Show indeterminate progress if still initializing after animation completes
                      SizedBox(
                        width: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: _animationComplete && !_initializationComplete
                              ? LinearProgressIndicator(
                                  backgroundColor: AppTheme.surfaceDark,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary.withValues(alpha: 0.8),
                                  ),
                                  minHeight: 3,
                                )
                              : LinearProgressIndicator(
                                  value: _mainController.value,
                                  backgroundColor: AppTheme.surfaceDark,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary.withValues(alpha: 0.8),
                                  ),
                                  minHeight: 3,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _animationComplete && !_initializationComplete
                            ? 'PREPARING...'
                            : 'LOADING...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing({
    required double size,
    required double opacity,
    bool isGlow = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: opacity),
          width: isGlow ? 3 : 1,
        ),
        boxShadow: isGlow
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: opacity * 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(50, 50),
          painter: CoinIconPainter(),
        ),
      ),
    );
  }
}

/// Coin icon painter
class CoinIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw coin edge
    final edgePaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, edgePaint);

    // Draw inner circle
    final innerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.7, innerPaint);

    // Draw dollar sign or coin symbol
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.5),
          fontSize: size.width * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gold particle model
class GoldParticle {
  final double angle;
  final double speed;
  final double size;
  final double delay;
  final double lifetime;
  final double rotationSpeed;
  final bool isGold;

  GoldParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
    required this.lifetime,
    required this.rotationSpeed,
    required this.isGold,
  });
}

/// Particle system painter
class ParticlePainter extends CustomPainter {
  final List<GoldParticle> particles;
  final double progress;
  final double centerX;
  final double centerY;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate particle progress with delay
      final adjustedProgress = ((progress - particle.delay) / particle.lifetime)
          .clamp(0.0, 1.0);

      if (adjustedProgress <= 0 || adjustedProgress >= 1) continue;

      // Physics-based deceleration
      final distance =
          particle.speed * adjustedProgress * (1 - adjustedProgress * 0.5);

      final x = centerX + math.cos(particle.angle) * distance;
      final y =
          centerY +
          math.sin(particle.angle) * distance -
          adjustedProgress * 50 * (1 - adjustedProgress); // Gravity curve

      // Fade out
      final opacity = (1 - adjustedProgress) * (1 - adjustedProgress);

      final paint = Paint()
        ..color = (particle.isGold ? AppTheme.primary : AppTheme.accent)
            .withValues(alpha: opacity);

      // Draw particle with rotation
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(adjustedProgress * particle.rotationSpeed);

      if (particle.isGold) {
        // Draw small diamond shape for gold particles
        final path = Path()
          ..moveTo(0, -particle.size)
          ..lineTo(particle.size, 0)
          ..lineTo(0, particle.size)
          ..lineTo(-particle.size, 0)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Draw circle for silver particles
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
