import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/user_model.dart';
import '../../core/models/mission_model.dart';
import '../../core/services/game_service.dart';
import '../../core/services/ad_service.dart';
import '../../ui/theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';
import '../widgets/tap_button.dart';
import '../widgets/native_ad_widget.dart';

/// Main Home Screen with Tap Interface
class HomeScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onNavigateToMissions;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToAutoClicker;
  final VoidCallback onNavigateToLeaderboard;

  const HomeScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onNavigateToMissions,
    required this.onNavigateToProfile,
    required this.onNavigateToAutoClicker,
    required this.onNavigateToLeaderboard,
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

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _displayCoins = widget.user.appCoins;

    _initAnimations();
    _setupGameCallbacks();
    _startCooldownTimer();
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

    widget.gameService.onUserUpdate = (user) {
      setState(() {
        _currentUser = user;
        _animateCoinCounter(user.appCoins);
      });
    };

    widget.gameService.onMissionComplete = () {
      _showMissionCompleteDialog();
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
      AppSnackBar.warning(context, 'Select a mission first!');
      return;
    }

    // Animations and haptics handled by TapButton
    widget.gameService.registerTap();
  }

  void _showMissionCompleteDialog() {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MissionCompleteDialog(
        reward: widget.gameService.activeMission?.acReward ?? 0,
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingTile(
                icon: Icons.volume_up,
                title: 'Sound Effects',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: AppTheme.primary,
                ),
              ),
              _buildSettingTile(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: AppTheme.primary,
                ),
              ),
              _buildSettingTile(
                icon: Icons.notifications,
                title: 'Notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & FAQ',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showHelpDialog();
                },
              ),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'About',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                ),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'TapMine',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 TapMine. All rights reserved.',
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showSkipCooldownDialog() {
    final adService = AdService();

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
              Icon(Icons.timer_off, color: AppTheme.primary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Skip Cooldown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Time remaining: ${_formatDuration(_remainingCooldown)}',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),

              // Watch ad option
              NeumorphicButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await adService.showRewardedAd();
                  if (result.isSuccess && mounted) {
                    widget.gameService.skipCooldownWithAd();
                    if (!mounted) return;
                    setState(() {
                      _remainingCooldown = Duration.zero;
                    });
                    AppSnackBar.success(context, 'Cooldown skipped!');
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text(
                      'WATCH AD (FREE)',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Pay with coins option
              GestureDetector(
                onTap: () {
                  if ((_currentUser?.appCoins ?? 0) >= 50) {
                    Navigator.pop(context);
                    widget.gameService.skipCooldownWithCoins(50);
                    setState(() {
                      _remainingCooldown = Duration.zero;
                    });
                    AppSnackBar.success(context, 'Cooldown skipped! -50 AC');
                  } else {
                    AppSnackBar.error(context, 'Not enough coins');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.toll, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '50 AC',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'WAIT',
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
      body: CyberBackground(
        child: SafeArea(
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
                      if (isInCooldown) _buildCooldownBanner(),
                      if (activeMission != null && !isInCooldown)
                        _buildActiveMissionCard(activeMission),
                      const Spacer(),
                      Transform.scale(
                        scale: buttonScale,
                        child: _buildTapArea(isInCooldown),
                      ),
                      if (!isInCooldown && !isSmallScreen)
                        const NativeAdWidget(),
                      const Spacer(),
                      _buildBottomNav(),
                    ],
                  );
                },
              ),

              // Floating tap particles
              ..._particles.map((p) => _buildTapParticle(p)),
            ],
          ),
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
          // Coin display
          NeumorphicContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 16,
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _coinPulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _coinPulseController.value * 0.1,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '₹',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatCoins(_displayCoins),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '≈ ₹${(_displayCoins / 1000).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Settings button
          NeumorphicIconButton(
            icon: Icons.settings,
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
    );
  }

  String _formatCoins(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    }
    if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return coins.toString();
  }

  Widget _buildCooldownBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
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
                  child: Text(
                    '+${mission.acReward} AC',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
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
        TapButton(
          onTap: _handleTap,
          isEnabled: !isInCooldown && widget.gameService.activeMission != null,
          isAutoClickerActive: widget.gameService.isAutoClickerRunning,
          currentEnergy: _currentUser?.getCurrentEnergy() ?? 100,
          maxEnergy: _currentUser?.maxEnergy ?? 100,
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

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: NeumorphicDecoration.flat(borderRadius: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', true, () {}),
          _buildNavItem(
            Icons.flag,
            'Missions',
            false,
            widget.onNavigateToMissions,
          ),
          _buildNavItem(
            Icons.smart_toy,
            'Auto',
            false,
            widget.onNavigateToAutoClicker,
          ),
          _buildNavItem(
            Icons.leaderboard,
            'Rank',
            false,
            widget.onNavigateToLeaderboard,
          ),
          _buildNavItem(
            Icons.person,
            'Profile',
            false,
            widget.onNavigateToProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: isActive
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  )
                : null,
            child: Icon(
              icon,
              color: isActive ? AppTheme.primary : Colors.white38,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.primary : Colors.white38,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: 500,
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help & FAQ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _FaqItem(
                      question: 'How do I earn AppCoins?',
                      answer:
                          'Select a mission and start tapping! Completing missions awards you AppCoins (AC). You can also earn by watching ads or referring friends.',
                    ),
                    _FaqItem(
                      question: 'How do I withdraw?',
                      answer:
                          'Go to your Profile. If you have at least 100,000 AC, you can request a withdrawal to your UPI ID. Withdrawals take 7-10 days.',
                    ),
                    _FaqItem(
                      question: 'What is Energy?',
                      answer:
                          'Energy is required to tap. It regenerates over time (1 per minute). You can refill it instantly using AppCoins or watching ads.',
                    ),
                    _FaqItem(
                      question: 'How does Auto-Clicker work?',
                      answer:
                          'Auto-Clicker taps for you automatically! You can activate it from the Auto-Clicker tab. Upgrading it increases tap speed.',
                    ),
                    _FaqItem(
                      question: 'Why is my screen red?',
                      answer:
                          'If you are in a Mission Cooldown, you cannot start a new mission until the timer expires. You can skip the cooldown by watching an ad.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Center(
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                      const Icon(Icons.toll, color: AppTheme.primary),
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

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
