import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/user_model.dart';
import '../../core/models/mission_model.dart';
import '../../core/services/game_service.dart';
import '../../ui/theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';
import '../widgets/tap_button.dart';
import '../widgets/native_ad_widget.dart';
import '../../core/services/payout_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Main Home Screen with Tap Interface
class HomeScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onNavigateToMissions;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToAutoClicker;
  final VoidCallback onNavigateToLeaderboard;
  final VoidCallback onNavigateToWithdrawal;
  final VoidCallback onNavigateToReferral;

  const HomeScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onNavigateToMissions,
    required this.onNavigateToProfile,
    required this.onNavigateToAutoClicker,
    required this.onNavigateToLeaderboard,
    required this.onNavigateToWithdrawal,
    required this.onNavigateToReferral,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _coinPulseController;
  late AnimationController _tapButtonController;
  late AnimationController _counterAnimController;

  UserModel? _currentUser;
  int _displayTaps = 0;
  int _displayCoins = 0;
  final List<TapParticle> _particles = [];
  Timer? _particleTimer;
  Timer? _cooldownTimer;
  Duration _remainingCooldown = Duration.zero;

  final math.Random _random = math.Random();
  DateTime? _lastManualTap;
  int _fastTapCounter = 0;
  late Stream<PayoutModel> _payoutStream;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _displayCoins = widget.user.appCoins;

    _initAnimations();
    _setupGameCallbacks();
    _startCooldownTimer();
    _payoutStream = PayoutService().getPayoutRotation();
  }

  void _initAnimations() {
    _coinPulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _tapButtonController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    _counterAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _setupGameCallbacks() {
    widget.gameService.onTapRegistered = (progress) {
      setState(() {
        _displayTaps = progress;
      });
      _spawnTapParticle();
    };

    widget.gameService.addListener(() {
      if (mounted) {
        setState(() {
          _currentUser = widget.gameService.currentUser;
          if (_currentUser != null) {
            _animateCoinCounter(_currentUser!.appCoins);
          }
        });
      }
    });

    widget.gameService.onMissionComplete = (reward) {
      _showMissionCompleteDialog(reward);
    };

    widget.gameService.onError = (error) {
      if (mounted) {
        AppSnackBar.error(context, error);
      }
    };
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentUser?.isInMissionCooldown ?? false) {
        setState(() {
          _remainingCooldown = _currentUser!.remainingMissionCooldown;
        });
      } else {
        setState(() {
          _remainingCooldown = Duration.zero;
        });
      }
    });
  }

  void _animateCoinCounter(int newValue) {
    final oldValue = _displayCoins;
    final diff = newValue - oldValue;

    _counterAnimController.reset();
    _counterAnimController.forward();

    _counterAnimController.addListener(() {
      setState(() {
        _displayCoins =
            oldValue + (diff * _counterAnimController.value).round();
      });
    });
  }

  void _spawnTapParticle() {
    final particle = TapParticle(
      x:
          MediaQuery.of(context).size.width / 2 +
          (_random.nextDouble() - 0.5) * 50,
      y: MediaQuery.of(context).size.height / 2 - 50,
      value: '+1',
      color: AppTheme.primary,
    );

    setState(() {
      _particles.add(particle);
    });

    // Remove particle after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _particles.remove(particle);
        });
      }
    });
  }

  void _handleTap() {
    if (_currentUser?.isInMissionCooldown ?? true) return;
    if (widget.gameService.activeMission == null) {
      widget.onNavigateToMissions();
      return;
    }

    // Anti-Spam Barrier
    final now = DateTime.now();
    if (_lastManualTap != null) {
      final diff = now.difference(_lastManualTap!).inMilliseconds;
      if (diff < 60) {
        _fastTapCounter++;
        if (_fastTapCounter > 20) {
          AppSnackBar.warning(
            context,
            'Whoa, slow down! Excessive speed may cause sync issues.',
          );
          _fastTapCounter = 0;
          return;
        }
      } else {
        _fastTapCounter = 0;
      }
    }
    _lastManualTap = now;

    // Animations and haptics handled by TapButton
    widget.gameService.registerTap();
  }

  void _showMissionCompleteDialog(int reward) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MissionCompleteDialog(
        reward: reward,
        onContinue: () {
          Navigator.pop(context);
          widget.onNavigateToMissions();
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPayoutTicker() {
    return StreamBuilder<PayoutModel>(
      stream: _payoutStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(height: 38);
        }

        final payout = snapshot.data!;
        return RepaintBoundary(
              child: Container(
                height: 36,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: NeumorphicDecoration.flat(borderRadius: 18),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.check_circle,
                      color: payout.isReal
                          ? AppTheme.primary
                          : AppTheme.success,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User ${payout.userName} just withdrew ₹${payout.amount.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Text(
                      '• SUCCESS',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            )
            .animate(
              key: ValueKey(payout.userName + payout.timestamp.toString()),
            )
            .fadeIn()
            .slideY(begin: 1.0, end: 0.0);
      },
    );
  }

  void _showSkipCooldownDialog() {
    final remainingMinutes =
        widget.gameService.currentUser?.remainingMissionCooldown.inMinutes ?? 0;
    final coinCost = (remainingMinutes / 5).ceil() * 1000;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Skip Cooldown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Don\'t want to wait? Skip now and start your next mission immediately!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.gameService.skipCooldownWithAd();
                      },
                      child:
                          Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Watch Ad',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'FREE',
                                    style: TextStyle(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: 1200.ms,
                                color: Colors.white70,
                              ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.gameService.skipCooldownWithCoins(coinCost);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Use Coins',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$coinCost AC',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'NOT NOW',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clear snackbars when leaving the screen
    ScaffoldMessenger.of(context).clearSnackBars();

    _coinPulseController.dispose();
    _tapButtonController.dispose();
    _counterAnimController.dispose();
    _cooldownTimer?.cancel();
    _particleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInCooldown = _currentUser?.isInMissionCooldown ?? false;
    final currentEnergy = _currentUser?.getCurrentEnergy() ?? 100;
    final activeMission = widget.gameService.activeMission;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final isSmallScreen = screenHeight < 700;
                final buttonScale = isSmallScreen
                    ? (screenHeight / 750).clamp(0.7, 1.0)
                    : 1.0;

                return Column(
                  children: [
                    _buildTopBar(),
                    _buildWithdrawalGoalPrompt(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: EnergyBar(
                        current: currentEnergy,
                        max: _currentUser?.maxEnergy ?? 100,
                      ),
                    ),
                    if (widget.gameService.isPenaltyActive)
                      _buildPenaltyBanner(),
                    if (isInCooldown && !widget.gameService.isPenaltyActive)
                      _buildCooldownBanner(),
                    if (activeMission != null &&
                        !isInCooldown &&
                        !widget.gameService.isPenaltyActive)
                      _buildActiveMissionCard(activeMission),
                    if (activeMission == null &&
                        !isInCooldown &&
                        !widget.gameService.isPenaltyActive)
                      _buildNoMissionCard(),
                    const Spacer(),
                    _buildPayoutTicker(),
                    const SizedBox(height: 12),
                    _buildBoostRow(),
                    const SizedBox(height: 12),
                    Transform.scale(
                      scale: buttonScale,
                      child: _buildTapArea(
                        isInCooldown || widget.gameService.isPenaltyActive,
                      ),
                    ),
                    if (!isInCooldown &&
                        !isSmallScreen &&
                        !widget.gameService.isPenaltyActive)
                      const NativeAdWidget(),
                    const Spacer(),
                  ],
                );
              },
            ),

            // Penalty Overlay
            if (widget.gameService.isPenaltyActive) _buildPenaltyOverlay(),

            // Floating tap particles
            ..._particles.map((p) => _buildTapParticle(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Coin display - Clickable to withdraw
          GestureDetector(
            onTap: widget.onNavigateToWithdrawal,
            behavior: HitTestBehavior.opaque,
            child: NeumorphicContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 16,
              child: SharedCoinDisplay(
                amount: _displayCoins,
                iconSize: 32,
                fontSize: 20,
              ),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Referral Share button
              NeumorphicIconButton(
                icon: Icons.share,
                onPressed: widget.onNavigateToReferral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalGoalPrompt() {
    if (_currentUser == null) return const SizedBox.shrink();

    final coins = _currentUser!.appCoins;
    // Show prompt between ₹50 and ₹99 (50k - 99k AC)
    if (coins < 50000 || coins >= 100000) return const SizedBox.shrink();

    final remaining = 100000 - coins;
    final progress = coins / 100000;

    return GestureDetector(
      onTap: widget.onNavigateToWithdrawal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: NeumorphicDecoration.flat(borderRadius: 20).copyWith(
          border: Border.all(
            color: AppTheme.energyColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: AppTheme.energyColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SO CLOSE TO WITHDRAWAL! 🚀',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Just ₹${(remaining / 1000).toStringAsFixed(1)} more to unlock ₹100 UPI!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(AppTheme.energyColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenaltyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecoration.flat(borderRadius: 16).copyWith(
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.report_problem, color: AppTheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unusual Sync Activity',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wait: ${widget.gameService.penaltyRemaining.inSeconds}s or Fast-Sync',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => widget.gameService.bypassPenaltyWithAd(),
            child: const Text(
              'FAST SYNC',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostRow() {
    if (widget.gameService.activeMission == null ||
        widget.gameService.isPenaltyActive) {
      return const SizedBox(height: 40);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skip Taps Boost
          _buildBoostChip(
            icon: Icons.fast_forward,
            label: 'Skip 300',
            onTap: () => widget.gameService.skipTapsByWatchingAd(),
          ),
          // Auto Boost
          _buildBoostChip(
            icon: Icons.bolt,
            label: widget.gameService.isBoostActive
                ? _formatDuration(widget.gameService.boostRemaining)
                : 'Auto 2m',
            isActive: widget.gameService.isBoostActive,
            color: widget.gameService.isBoostActive
                ? AppTheme.energyColor
                : AppTheme.primary,
            onTap: () => widget.gameService.activateBoostByWatchingAd(),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    final activeColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: NeumorphicDecoration.convex(borderRadius: 24).copyWith(
          border: isActive
              ? Border.all(
                  color: activeColor.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activeColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenaltyOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock, color: AppTheme.error, size: 64),
            const SizedBox(height: 24),
            const Text(
              'SYNCING DETECTED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'System lock: ${widget.gameService.penaltyRemaining.inSeconds}s',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 48),
            NeumorphicButton(
              onPressed: () => widget.gameService.bypassPenaltyWithAd(),
              child: const Text(
                'FAST SYNC WITH AD',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {}, // Do nothing, user must wait or watch ad
              child: const Text(
                'Please wait for system sync...',
                style: TextStyle(color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecoration.flat(borderRadius: 16).copyWith(
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: AppTheme.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mission Cooldown Active',
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Next mission in: ${_formatDuration(_remainingCooldown)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showSkipCooldownDialog,
            child: const Text(
              'SKIP',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissionCard(MissionModel mission) {
    final progress =
        widget.gameService.missionProgress / mission.tapRequirement;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: NeumorphicCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${widget.gameService.missionProgress} / ${mission.tapRequirement} taps',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/AppCoin.png', width: 14, height: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+${mission.acReward} AC',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NeumorphicProgressBar(value: progress, height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMissionCard() {
    return GestureDetector(
          onTap: widget.onNavigateToMissions,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: NeumorphicCard(
              color: AppTheme.primary.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.flag_outlined,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1500.ms, color: Colors.white30)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: 1000.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NO ACTIVE MISSION',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Tap here to select a mission and start earning!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1.0, 1.0),
          duration: 1000.ms,
        );
  }

  Widget _buildTapArea(bool isInCooldown) {
    return Column(
      children: [
        // Auto-clicker indicator
        if (widget.gameService.isAutoClickerRunning)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.energyColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.energyColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.energyColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AUTO-CLICKER ACTIVE',
                  style: TextStyle(
                    color: AppTheme.energyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Main tap button
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            TapButton(
              onTap: _handleTap,
              isEnabled:
                  !isInCooldown && widget.gameService.activeMission != null,
              isAutoClickerActive: widget.gameService.isAutoClickerRunning,
              currentEnergy: _currentUser?.getCurrentEnergy() ?? 100,
              maxEnergy: _currentUser?.maxEnergy ?? 100,
            ),
            if (widget.gameService.activeMission == null && !isInCooldown)
              Positioned(
                top: -10,
                child:
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.error.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'MISSION REQUIRED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                          duration: 800.ms,
                        ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Tap counter
        Text(
          '$_displayTaps',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const Text(
          'taps',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTapParticle(TapParticle particle) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Positioned(
          left: particle.x - 20,
          top: particle.y - (value * 80) - 20,
          child: Opacity(
            opacity: 1.0 - value,
            child: Transform.scale(
              scale: 1.0 + value * 0.5,
              child: Text(
                particle.value,
                style: TextStyle(
                  color: particle.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tap particle model
class TapParticle {
  final double x;
  final double y;
  final String value;
  final Color color;

  TapParticle({
    required this.x,
    required this.y,
    required this.value,
    required this.color,
  });
}

/// Mission Complete Dialog
class _MissionCompleteDialog extends StatefulWidget {
  final int reward;
  final VoidCallback onContinue;

  const _MissionCompleteDialog({
    required this.reward,
    required this.onContinue,
  });

  @override
  State<_MissionCompleteDialog> createState() => _MissionCompleteDialogState();
}

class _MissionCompleteDialogState extends State<_MissionCompleteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _coinAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _coinAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'MISSION COMPLETE!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 16),

              AnimatedBuilder(
                animation: _coinAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _coinAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/AppCoin.png', width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.reward} AC',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              NeumorphicButton(
                onPressed: widget.onContinue,
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
