import 'package:flutter/material.dart';
import '../../core/models/mission_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/game_service.dart';
import '../../ui/theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';

/// Mission Selection Screen
class MissionScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onBack;
  final VoidCallback onMissionStarted;

  const MissionScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
    required this.onMissionStarted,
  });

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController.forward();

    // Setup error handling
    widget.gameService.onError = (error) {
      if (mounted) {
        AppSnackBar.error(context, error);
      }
    };
  }

  @override
  void dispose() {
    // Clear snackbars when leaving the screen
    ScaffoldMessenger.of(context).clearSnackBars();

    _listController.dispose();
    super.dispose();
  }

  List<MissionModel> _getFilteredMissions() {
    final allMissions = widget.gameService.missions;

    return allMissions.where((m) {
      if (m.isSpecial) return false;
      if (widget.user.isMissionOnCooldown(m.id)) return false;

      switch (_selectedFilter) {
        case 'available':
          return m.isUnlockedFor(widget.user.unlockedTiers) &&
              !widget.user.isInMissionCooldown;
        case 'tier1':
          return m.tier == 'tier1';
        case 'tier2':
          return m.tier == 'tier2';
        case 'tier3':
          return m.tier == 'tier3';
        default:
          return true;
      }
    }).toList();
  }

  List<MissionModel> _getCompletedMissions() {
    final allMissions = widget.gameService.missions;
    return allMissions
        .where((m) => widget.user.isMissionOnCooldown(m.id))
        .toList();
  }

  void _startMission(MissionModel mission) async {
    final success = await widget.gameService.startMission(mission);
    if (success) {
      widget.onMissionStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final missions = _getFilteredMissions();
    final completed = _getCompletedMissions();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Stats banner
            _buildStatsBanner(),

            // Filter tabs
            _buildFilterTabs(),

            // Mission list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (missions.isNotEmpty) ...[
                    const Text(
                      'AVAILABLE MISSIONS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...missions.asMap().entries.map((entry) {
                      return _buildAnimatedCard(entry.value, entry.key);
                    }),
                  ],
                  if (completed.isNotEmpty &&
                      (_selectedFilter == 'all' ||
                          _selectedFilter == 'completed')) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'COMPLETED (COOLDOWN)',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...completed.asMap().entries.map((entry) {
                      return _buildAnimatedCard(
                        entry.value,
                        entry.key + missions.length,
                        isCompleted: true,
                      );
                    }),
                  ],
                  if (missions.isEmpty && completed.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Text(
                          'No missions found in this category.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                ],
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
          NeumorphicIconButton(
            icon: Icons.arrow_back,
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          const Text(
            'MISSIONS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: NeumorphicCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              icon: Icons.check_circle,
              value: '${widget.user.missionsCompleted}',
              label: 'Completed',
              color: AppTheme.success,
            ),
            Container(width: 1, height: 40, color: Colors.white12),
            SharedCoinDisplay(
              amount: widget.user.appCoins,
              iconSize: 20,
              fontSize: 16,
              showLabel: true,
            ),
            Container(width: 1, height: 40, color: Colors.white12),
            _buildStatItem(
              icon: Icons.local_fire_department,
              value: '${widget.user.currentStreak}',
              label: 'Streak',
              color: AppTheme.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    IconData? icon,
    Widget? iconWidget,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        if (iconWidget != null)
          iconWidget
        else
          Icon(icon!, color: color, size: 20),
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

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip('all', 'All'),
          _buildFilterChip('available', 'Available'),
          _buildFilterChip('completed', 'Completed'),
          _buildFilterChip('tier1', 'Quick'),
          _buildFilterChip('tier2', 'Medium'),
          _buildFilterChip('tier3', 'Premium'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _listController.reset();
        _listController.forward();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        constraints: const BoxConstraints(minWidth: 80, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              )
            : NeumorphicDecoration.flat(borderRadius: 20),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(
    MissionModel mission,
    int index, {
    bool isCompleted = false,
  }) {
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        final delay = (index * 0.05).clamp(0.0, 0.5);
        final animValue = Curves.easeOutCubic.transform(
          ((_listController.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: _buildMissionCard(mission, isCompleted: isCompleted),
    );
  }

  Widget _buildMissionCard(MissionModel mission, {bool isCompleted = false}) {
    final isUnlocked = mission.isUnlockedFor(widget.user.unlockedTiers);
    final isInCooldown = widget.user.isInMissionCooldown;
    final canStart = isUnlocked && !isInCooldown && !isCompleted;

    Color tierColor;
    switch (mission.tier) {
      case 'tier1':
        tierColor = AppTheme.success;
        break;
      case 'tier2':
        tierColor = AppTheme.warning;
        break;
      case 'tier3':
        tierColor = AppTheme.primary;
        break;
      default:
        tierColor = Colors.white54;
    }

    // Calculate remaining days if completed
    int remainingDays = 0;
    if (isCompleted) {
      final completionDate = widget.user.completedMissions[mission.id]!;
      remainingDays =
          30 - DateTime.now().difference(completionDate).inDays.clamp(0, 30);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isCompleted ? 0.7 : 1.0,
        child: NeumorphicCard(
          onTap: canStart ? () => _startMission(mission) : null,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: NeumorphicDecoration.flat(borderRadius: 12)
                        .copyWith(
                          color: tierColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: tierColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                    child: Text(
                      mission.tierDisplayName.toUpperCase(),
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  // Reward
                  Row(
                    children: [
                      Image.asset('assets/AppCoin.png', width: 18, height: 18),
                      const SizedBox(width: 4),
                      Text(
                        '+${mission.acReward}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Mission name
              Text(
                mission.name,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                mission.description,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMissionStat(
                    Icons.touch_app,
                    '${mission.tapRequirement}',
                    'taps',
                  ),
                  _buildMissionStat(
                    Icons.bolt,
                    '${mission.energyCost}',
                    'energy',
                  ),
                  _buildMissionStat(
                    Icons.timer,
                    '${mission.cooldownMinutes}m',
                    'cooldown',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Start button
              SizedBox(
                width: double.infinity,
                child: isCompleted
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: NeumorphicDecoration.flat(borderRadius: 12)
                            .copyWith(
                              color: AppTheme.success.withValues(alpha: 0.05),
                              border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.2),
                              ),
                            ),
                        child: Center(
                          child: Text(
                            'RESETS IN $remainingDays DAYS',
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      )
                    : isInCooldown
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: NeumorphicDecoration.flat(borderRadius: 12)
                            .copyWith(
                              color: AppTheme.warning.withValues(alpha: 0.05),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.2),
                              ),
                            ),
                        child: Center(
                          child: Text(
                            'COOLDOWN ACTIVE',
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      )
                    : !isUnlocked
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock,
                              color: Colors.white38,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mission.tier == 'tier2'
                                  ? 'Complete 5 Quick missions'
                                  : 'Complete 10 Medium missions',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : NeumorphicButton(
                        onPressed: () => _startMission(mission),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text(
                          'START MISSION',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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

  Widget _buildMissionStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}
