import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _isAutoClickerActive = false;
  bool _isPausedForAd = false;
  int _selectedSpeed = 5; // taps per second
  int _tapsGenerated = 0;
  Timer? _autoClickerTimer;
  Timer? _rentalTimer;
  Duration _rentalRemaining = Duration.zero;

  // Speed tiers with their costs
  static const Map<int, int> speedTiers = {
    5: 0, // Free tier
    10: 100, // 100 AC for 1 hour
    20: 200, // 200 AC for 1 hour
    50: 500, // 500 AC for 1 hour
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupAdCallbacks();
    _loadAutoClickerState();

    // Setup error handling
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
      if (_isAutoClickerActive) {
        setState(() => _isPausedForAd = true);
        _pauseAutoClicker();
      }
    };

    _adService.onAdCompleted = () {
      if (_isPausedForAd) {
        setState(() => _isPausedForAd = false);
        _resumeAutoClicker();
      }
    };

    _adService.onAdFailed = () {
      if (_isPausedForAd) {
        setState(() => _isPausedForAd = false);
        _resumeAutoClicker();
      }
    };
  }

  void _loadAutoClickerState() {
    final user = widget.user;
    if (user.autoClickerActive && user.autoClickerRentalExpiry != null) {
      if (user.autoClickerRentalExpiry!.isAfter(DateTime.now())) {
        _isAutoClickerActive = true;
        _selectedSpeed = user.autoClickerSpeed;
        _rentalRemaining = user.autoClickerRentalExpiry!.difference(
          DateTime.now(),
        );
        _startAutoClicker();
        _startRentalTimer();
      }
    }
  }

  void _startAutoClicker() {
    if (_isAutoClickerActive || _isPausedForAd) return;

    setState(() => _isAutoClickerActive = true);
    _gearController.repeat();
    HapticFeedback.mediumImpact();

    // Start tapping at selected speed
    final interval = Duration(milliseconds: (1000 / _selectedSpeed).round());
    _autoClickerTimer = Timer.periodic(interval, (_) {
      if (!_isPausedForAd && widget.gameService.activeMission != null) {
        widget.gameService.registerTap();
        setState(() => _tapsGenerated++);
      }
    });
  }

  void _pauseAutoClicker() {
    _autoClickerTimer?.cancel();
    _gearController.stop();
  }

  void _resumeAutoClicker() {
    if (!_isAutoClickerActive) return;

    _gearController.repeat();
    final interval = Duration(milliseconds: (1000 / _selectedSpeed).round());
    _autoClickerTimer = Timer.periodic(interval, (_) {
      if (!_isPausedForAd && widget.gameService.activeMission != null) {
        widget.gameService.registerTap();
        setState(() => _tapsGenerated++);
      }
    });
  }

  void _stopAutoClicker() {
    _autoClickerTimer?.cancel();
    _gearController.stop();
    _gearController.reset();
    setState(() {
      _isAutoClickerActive = false;
      _tapsGenerated = 0;
    });
    HapticFeedback.lightImpact();
  }

  void _startRentalTimer() {
    _rentalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_rentalRemaining.inSeconds > 0) {
        setState(() {
          _rentalRemaining -= const Duration(seconds: 1);
        });
      } else {
        _stopAutoClicker();
        _rentalTimer?.cancel();
        _showRentalExpiredDialog();
      }
    });
  }

  void _showRentalExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RentalExpiredDialog(
        onRenew: () {
          Navigator.pop(context);
          _showSpeedUpgradeSheet();
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _showSpeedUpgradeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpeedUpgradeSheet(
        currentSpeed: _selectedSpeed,
        userCoins: widget.user.appCoins,
        onSelect: (speed, duration) async {
          Navigator.pop(context);
          await _activateSpeed(speed, duration);
        },
      ),
    );
  }

  Future<void> _activateSpeed(int speed, Duration duration) async {
    final cost = speedTiers[speed] ?? 0;

    if (cost > 0 && widget.user.appCoins < cost) {
      AppSnackBar.error(context, 'Need $cost AC to unlock this speed');
      return;
    }

    // Deduct coins if not free tier
    if (cost > 0) {
      widget.gameService.skipCooldownWithCoins(cost);
    }

    setState(() {
      _selectedSpeed = speed;
      _rentalRemaining = duration;
    });

    _startAutoClicker();
    _startRentalTimer();
  }

  Future<void> _watchAdForBoost() async {
    final result = await _adService.showRewardedAd();
    if (result.isSuccess && mounted) {
      // Add 15 minutes to rental
      setState(() {
        _rentalRemaining += const Duration(minutes: 15);
      });
      if (mounted) {
        AppSnackBar.success(context, '+15 minutes added!');
      }
    }
  }

  @override
  void dispose() {
    // Clear snackbars when leaving the screen
    ScaffoldMessenger.of(context).clearSnackBars();

    _pulseController.dispose();
    _gearController.dispose();
    _autoClickerTimer?.cancel();
    _rentalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CyberBackground(
        child: SafeArea(
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
                      _buildSpeedSelector(),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          NeumorphicIconButton(
            icon: Icons.arrow_back,
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
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
                  Text(
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
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _gearController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            if (_isAutoClickerActive)
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

            // Main gear container
            NeumorphicContainer(
              width: 180,
              height: 180,
              borderRadius: 90,
              isConvex: _isAutoClickerActive,
              child: Transform.rotate(
                angle: _gearController.value * 6.28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gear icon
                    Icon(
                      Icons.settings,
                      size: 80,
                      color: _isAutoClickerActive
                          ? AppTheme.energyColor
                          : Colors.white38,
                    ),
                    // Speed indicator
                    if (_isAutoClickerActive)
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
                          child: Text(
                            '${_selectedSpeed}x',
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
    return NeumorphicCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.touch_app,
            value: _formatNumber(_tapsGenerated),
            label: 'Taps Generated',
            color: AppTheme.primary,
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          _buildStatItem(
            icon: Icons.timer,
            value: _formatDuration(_rentalRemaining),
            label: 'Time Remaining',
            color: AppTheme.energyColor,
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          _buildStatItem(
            icon: Icons.speed,
            value: '$_selectedSpeed/s',
            label: 'Tap Speed',
            color: AppTheme.accent,
          ),
        ],
      ),
    );
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

  Widget _buildSpeedSelector() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT SPEED',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: speedTiers.keys.map((speed) {
              final isSelected = _selectedSpeed == speed;
              final cost = speedTiers[speed]!;
              final isLocked = cost > widget.user.appCoins && cost > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: isLocked
                      ? null
                      : () => setState(() => _selectedSpeed = speed),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.energyColor,
                                AppTheme.energyColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.energyColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : NeumorphicDecoration.flat(borderRadius: 12),
                    child: Column(
                      children: [
                        Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : (isLocked ? Colors.white38 : Colors.white),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cost == 0 ? 'FREE' : '$cost AC',
                          style: TextStyle(
                            color: isSelected ? Colors.black54 : Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                        if (isLocked)
                          Icon(Icons.lock, color: Colors.white24, size: 12),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: NeumorphicButton(
            onPressed: _isAutoClickerActive
                ? _stopAutoClicker
                : () =>
                      _activateSpeed(_selectedSpeed, const Duration(hours: 1)),
            backgroundColor: _isAutoClickerActive ? AppTheme.error : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isAutoClickerActive ? Icons.stop : Icons.play_arrow,
                  color: _isAutoClickerActive ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAutoClickerActive ? 'STOP' : 'START',
                  style: TextStyle(
                    color: _isAutoClickerActive ? Colors.white : Colors.black,
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
                child: Icon(Icons.play_circle_outline, color: AppTheme.primary),
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
                      'Get +15 minutes free rental time',
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '0:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Rental Expired Dialog
class _RentalExpiredDialog extends StatelessWidget {
  final VoidCallback onRenew;
  final VoidCallback onDismiss;

  const _RentalExpiredDialog({required this.onRenew, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: NeumorphicDecoration.convex(borderRadius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off, color: AppTheme.warning, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Rental Expired',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your auto-clicker rental has ended. Renew to continue tapping automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    child: const Text(
                      'LATER',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NeumorphicButton(
                    onPressed: onRenew,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: const Text(
                      'RENEW',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Speed Upgrade Bottom Sheet
class _SpeedUpgradeSheet extends StatelessWidget {
  final int currentSpeed;
  final int userCoins;
  final Function(int speed, Duration duration) onSelect;

  const _SpeedUpgradeSheet({
    required this.currentSpeed,
    required this.userCoins,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Duration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildDurationOption(context, const Duration(hours: 1), 'FREE', 0),
          const SizedBox(height: 12),
          _buildDurationOption(context, const Duration(hours: 4), '50 AC', 50),
          const SizedBox(height: 12),
          _buildDurationOption(
            context,
            const Duration(hours: 12),
            '100 AC',
            100,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDurationOption(
    BuildContext context,
    Duration duration,
    String price,
    int cost,
  ) {
    final isAffordable = cost <= userCoins;
    final hours = duration.inHours;

    return GestureDetector(
      onTap: isAffordable ? () => onSelect(currentSpeed, duration) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAffordable
                ? AppTheme.primary.withValues(alpha: 0.3)
                : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$hours ${hours == 1 ? 'Hour' : 'Hours'}',
              style: TextStyle(
                color: isAffordable ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAffordable
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                price,
                style: TextStyle(
                  color: isAffordable ? AppTheme.primary : Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
