import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../core/services/game_service.dart';
import '../widgets/neumorphic_widgets.dart';
import '../widgets/native_ad_widget.dart';

/// Leaderboard Screen
class LeaderboardScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onBack;

  const LeaderboardScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isLoading = true;

  // Mock leaderboard data - in production, this would come from Firestore
  final List<LeaderboardEntry> _dailyLeaderboard = [];
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final rawData = await widget.gameService.getLeaderboardData();

      setState(() {
        _dailyLeaderboard.clear();

        for (int i = 0; i < rawData.length; i++) {
          final data = rawData[i];
          final entry = LeaderboardEntry(
            rank: i + 1,
            username: data['email']?.split('@')[0] ?? 'Explorer',
            email: data['email'] ?? '',
            taps: data['totalTaps'] ?? 0,
            coins: data['appCoins'] ?? 0,
            avatar: (data['email'] ?? 'E')[0].toUpperCase(),
          );
          _dailyLeaderboard.add(entry);
        }

        // Find user's rank in top 10
        final index = _dailyLeaderboard.indexWhere(
          (e) => e.email == widget.user.email,
        );
        _userRank = index != -1 ? index + 1 : 0;

        _isLoading = false;
      });

      _animController.reset();
      _animController.forward();
    } catch (e) {
      debugPrint('Leaderboard: Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<LeaderboardEntry> get _currentLeaderboard {
    return _dailyLeaderboard;
  }

  @override
  void dispose() {
    _animController.dispose();
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
            _buildUserRankCard(),
            const NativeAdWidget(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _currentLeaderboard.isEmpty
                  ? _buildEmptyState()
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildPodium()),
                        _buildLeaderboardList(),
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
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEADERBOARD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            Text(
              'Updates every 24 hours',
              style: TextStyle(
                color: AppTheme.primary.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: NeumorphicCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _userRank > 0 ? '#$_userRank' : '-',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Rank',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    _userRank > 0 && _userRank <= 10
                        ? 'Top 10! 🏆'
                        : _userRank > 0 && _userRank <= 100
                        ? 'Top 100! ⭐'
                        : 'Keep tapping!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.user.totalTaps}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'taps',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final top1 = _currentLeaderboard.isNotEmpty ? _currentLeaderboard[0] : null;
    final top2 = _currentLeaderboard.length > 1 ? _currentLeaderboard[1] : null;
    final top3 = _currentLeaderboard.length > 2 ? _currentLeaderboard[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPodiumPlace(top2, 2, 100, 0.85),
          _buildPodiumPlace(top1, 1, 130, 1.0),
          _buildPodiumPlace(top3, 3, 80, 0.75),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    LeaderboardEntry? entry,
    int place,
    double height,
    double scale,
  ) {
    Color placeColor;
    switch (place) {
      case 1:
        placeColor = AppTheme.primary;
        break;
      case 2:
        placeColor = const Color(0xFFE0E0E0); // Bright silver/silver
        break;
      case 3:
        placeColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        placeColor = Colors.white24;
    }

    final isVacant = entry == null;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final animValue = Curves.elasticOut.transform(
          (_animController.value * 1.5 - (place * 0.1)).clamp(0.0, 1.0),
        );
        return Transform.scale(
          scale: animValue * scale,
          child: Opacity(
            opacity: animValue,
            child: Column(
              children: [
                // Avatar/Placeholder
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 75 * scale,
                      height: 75 * scale,
                      margin: const EdgeInsets.only(top: 15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isVacant ? Colors.white10 : placeColor,
                          width: 3,
                        ),
                        boxShadow: isVacant
                            ? []
                            : [
                                BoxShadow(
                                  color: placeColor.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                        color: isVacant ? Colors.black26 : AppTheme.surfaceDark,
                      ),
                      child: Center(
                        child: isVacant
                            ? Icon(
                                Icons.person_add_alt_1,
                                color: Colors.white10,
                                size: 30 * scale,
                              )
                            : Text(
                                entry.avatar,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (place == 1)
                      const Positioned(
                        top: 0,
                        child: Icon(
                          Icons.emoji_events,
                          color: AppTheme.primary,
                          size: 30,
                        ),
                      )
                    else if (place == 2)
                      const Positioned(
                        top: 2,
                        child: Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFE0E0E0),
                          size: 24,
                        ),
                      )
                    else if (place == 3)
                      const Positioned(
                        top: 4,
                        child: Icon(
                          Icons.military_tech,
                          color: Color(0xFFCD7F32),
                          size: 24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isVacant ? 'VACANT' : entry.username,
                  style: TextStyle(
                    color: isVacant ? Colors.white24 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scale,
                    letterSpacing: isVacant ? 1 : 0,
                  ),
                ),
                const SizedBox(height: 8),
                // Podium block
                Container(
                  width: 85 * scale,
                  height: height,
                  decoration:
                      NeumorphicDecoration.convex(
                        borderRadius: 16,
                        color: isVacant
                            ? AppTheme.surfaceDark
                            : AppTheme.surface,
                      ).copyWith(
                        border: Border.all(
                          color: isVacant
                              ? Colors.white.withValues(alpha: 0.05)
                              : placeColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#$place',
                        style: TextStyle(
                          color: isVacant ? Colors.white10 : placeColor,
                          fontSize: 28 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!isVacant)
                        Text(
                          _formatNumber(entry.coins),
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: AppTheme.primary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'The Arena is Empty!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No miners have reached the top yet.\nBe the first to claim the throne!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          NeumorphicButton(
            onPressed: widget.onBack,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            child: const Text(
              'START MINING',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    // Only show from index 3 onwards as top 3 are in podium
    final listItems = _currentLeaderboard.sublist(
      _currentLeaderboard.length > 3 ? 3 : _currentLeaderboard.length,
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = listItems[index];
        final delay = (index + 3) * 0.05;
        final animValue = Curves.easeOutCubic.transform(
          ((_animController.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - animValue)),
              child: Opacity(
                opacity: animValue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildLeaderboardItem(entry),
                ),
              ),
            );
          },
        );
      }, childCount: listItems.length),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    Color getRankColor() {
      switch (entry.rank) {
        case 1:
          return const Color(0xFFFFD700); // Gold
        case 2:
          return const Color(0xFFC0C0C0); // Silver
        case 3:
          return const Color(0xFFCD7F32); // Bronze
        default:
          return Colors.white54;
      }
    }

    IconData? getRankIcon() {
      if (entry.rank <= 3) return Icons.emoji_events;
      return null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: NeumorphicDecoration.listCard(),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: getRankColor().withValues(alpha: 0.2),
                ),
                child: Center(
                  child: getRankIcon() != null
                      ? Icon(getRankIcon(), color: getRankColor(), size: 20)
                      : Text(
                          '${entry.rank}',
                          style: TextStyle(
                            color: getRankColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                ),
                child: Center(
                  child: Text(
                    entry.avatar,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_formatNumber(entry.taps)} taps',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Coins
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/AppCoin.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatNumber(entry.coins),
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
        ),
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
}

/// Leaderboard Entry Model
class LeaderboardEntry {
  final int rank;
  final String username;
  final String email;
  final int taps;
  final int coins;
  final String avatar;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.email,
    required this.taps,
    required this.coins,
    required this.avatar,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? username,
    String? email,
    int? taps,
    int? coins,
    String? avatar,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      username: username ?? this.username,
      email: email ?? this.email,
      taps: taps ?? this.taps,
      coins: coins ?? this.coins,
      avatar: avatar ?? this.avatar,
    );
  }
}
