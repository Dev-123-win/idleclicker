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

    switch (_selectedFilter) {
      case 'available':
        return allMissions
            .where(
              (m) =>
                  m.isUnlockedFor(widget.user.unlockedTiers) &&
                  !widget.user.isInMissionCooldown,
            )
            .toList();
      case 'tier1':
        return allMissions
            .where((m) => m.tier == 'tier1' && !m.isSpecial)
            .toList();
      case 'tier2':
        return allMissions
            .where((m) => m.tier == 'tier2' && !m.isSpecial)
            .toList();
      case 'tier3':
        return allMissions
            .where((m) => m.tier == 'tier3' && !m.isSpecial)
            .toList();
      default:
        return allMissions.where((m) => !m.isSpecial).toList();
    }
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CyberBackground(
        child: SafeArea(
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
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: missions.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _listController,
                      builder: (context, child) {
                        final delay = index * 0.1;
                        final animValue = Curves.easeOutCubic.transform(
                          ((_listController.value - delay) / (1 - delay)).clamp(
                            0.0,
                            1.0,
                          ),
                        );
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - animValue)),
                          child: Opacity(opacity: animValue, child: child),
                        );
                      },
                      child: _buildMissionCard(missions[index]),
                    );
                  },
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
            _buildStatItem(
              icon: Icons.toll,
              value: '${widget.user.appCoins}',
              label: 'AppCoins',
              color: AppTheme.primary,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(MissionModel mission) {
    final isUnlocked = mission.isUnlockedFor(widget.user.unlockedTiers);
    final isInCooldown = widget.user.isInMissionCooldown;
    final canStart = isUnlocked && !isInCooldown;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
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
                    Icon(Icons.toll, color: AppTheme.primary, size: 18),
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
                _buildMissionStat(
                  Icons.play_circle_outline,
                  '${mission.interstitialAds + mission.rewardedAds}',
                  'ads',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Start button
            SizedBox(
              width: double.infinity,
              child: isInCooldown
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.3),
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
