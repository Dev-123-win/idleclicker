import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/game_service.dart';
import '../../core/services/ad_service.dart';
import '../../ui/theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';

/// Auto-Clicker Management Screen
class AutoClickerScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onBack;

  const AutoClickerScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
  });

  @override
  State<AutoClickerScreen> createState() => _AutoClickerScreenState();
}

class _AutoClickerScreenState extends State<AutoClickerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _gearController;
  final AdService _adService = AdService();

  bool _isPausedForAd = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupAdCallbacks();
    _loadAutoClickerState();

    // Setup GameService callbacks
    widget.gameService.onAutoClickerUpdate = () {
      if (mounted) setState(() {});
    };

    widget.gameService.onError = (error) {
      if (mounted) {
        AppSnackBar.error(context, error);
      }
    };
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _gearController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  void _setupAdCallbacks() {
    _adService.onAdStarted = () {
      if (widget.gameService.isAutoClickerRunning) {
        setState(() => _isPausedForAd = true);
        widget.gameService.stopAutoClicker();
      }
    };

    _adService.onAdCompleted = () {
      if (_isPausedForAd) {
        setState(() => _isPausedForAd = false);
        widget.gameService.startAutoClicker();
      }
    };

    _adService.onAdFailed = () {
      if (_isPausedForAd) {
        setState(() => _isPausedForAd = false);
        widget.gameService.startAutoClicker();
      }
    };
  }

  void _loadAutoClickerState() {
    // Current state handled by GameService and listener
    if (widget.gameService.isAutoClickerRunning) {
      _gearController.repeat();
    }
  }

  void _toggleAutoClicker() {
    if (widget.gameService.isAutoClickerRunning) {
      widget.gameService.stopAutoClicker();
      _gearController.stop();
    } else {
      widget.gameService.startAutoClicker();
      if (widget.gameService.isAutoClickerRunning) {
        _gearController.repeat();
      }
    }
    setState(() {});
  }

  Future<void> _watchAdForBoost() async {
    await widget.gameService.activateBoostByWatchingAd();
  }

  @override
  void dispose() {
    ScaffoldMessenger.of(context).clearSnackBars();
    _pulseController.dispose();
    _gearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAutoClickerVisual(),
                    const SizedBox(height: 24),
                    _buildStatsCard(),
                    const SizedBox(height: 24),
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildControlButtons(),
                    const SizedBox(height: 24),
                    _buildAdBoostCard(),
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
          const Expanded(
            child: Text(
              'AUTO-CLICKER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          if (_isPausedForAd)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause, color: AppTheme.warning, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'PAUSED',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoClickerVisual() {
    final isActive = widget.gameService.isAutoClickerRunning;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _gearController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Container(
                width: 200 + (_pulseController.value * 20),
                height: 200 + (_pulseController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.energyColor.withValues(
                      alpha: 0.3 - (_pulseController.value * 0.2),
                    ),
                    width: 2,
                  ),
                ),
              ),

            NeumorphicContainer(
              width: 180,
              height: 180,
              borderRadius: 90,
              isConvex: isActive,
              child: Transform.rotate(
                angle: _gearController.value * 6.28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      size: 80,
                      color: isActive ? AppTheme.energyColor : Colors.white38,
                    ),
                    if (isActive)
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.energyColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '5x',
                            style: TextStyle(
                              color: AppTheme.energyColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard() {
    final dailyFree = widget.gameService.dailyFreeSecondsRemaining;
    final adBoost = widget.gameService.adBoostSecondsRemaining;

    return NeumorphicCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.timer,
            value: _formatSeconds(dailyFree),
            label: 'Daily Free',
            color: AppTheme.primary,
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          _buildStatItem(
            icon: Icons.bolt,
            value: _formatSeconds(adBoost),
            label: 'Ad Boost',
            color: AppTheme.energyColor,
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          _buildStatItem(
            icon: Icons.speed,
            value: '5/s',
            label: 'Tap Speed',
            color: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'AUTO-CLICKER STATUS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.gameService.isAutoClickerRunning
                ? 'CLICKER IS ACTIVE'
                : 'CLICKER IS IDLE',
            style: TextStyle(
              color: widget.gameService.isAutoClickerRunning
                  ? AppTheme.energyColor
                  : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Speed restricted to 5 taps/sec for stability.',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    final isActive = widget.gameService.isAutoClickerRunning;
    return Row(
      children: [
        Expanded(
          child: NeumorphicButton(
            onPressed: _toggleAutoClicker,
            backgroundColor: isActive ? AppTheme.error : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.stop : Icons.play_arrow,
                  color: isActive ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'STOP' : 'START',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdBoostCard() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch Ad for Boost',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Get +10 minutes free usage time',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeumorphicButton(
            onPressed: _watchAdForBoost,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'WATCH AD',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
