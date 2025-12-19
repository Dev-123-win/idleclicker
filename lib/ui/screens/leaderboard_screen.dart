import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../ui/theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';
import '../widgets/native_ad_widget.dart';

/// Leaderboard Screen
class LeaderboardScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onBack;

  const LeaderboardScreen({
    super.key,
    required this.user,
    required this.onBack,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  bool _isLoading = true;
  String _selectedTimeframe = 'daily';

  // Mock leaderboard data - in production, this would come from Firestore
  final List<LeaderboardEntry> _dailyLeaderboard = [];
  final List<LeaderboardEntry> _weeklyLeaderboard = [];
  final List<LeaderboardEntry> _allTimeLeaderboard = [];
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    // Simulate loading from Firestore
    await Future.delayed(const Duration(seconds: 1));

    // Generate mock data
    final mockUsers = _generateMockLeaderboard();

    setState(() {
      _dailyLeaderboard.addAll(mockUsers);
      _weeklyLeaderboard.addAll(
        mockUsers
            .map(
              (e) => e.copyWith(
                taps: (e.taps * 7).round(),
                coins: (e.coins * 7).round(),
              ),
            )
            .toList(),
      );
      _allTimeLeaderboard.addAll(
        mockUsers
            .map(
              (e) => e.copyWith(
                taps: (e.taps * 30).round(),
                coins: (e.coins * 30).round(),
              ),
            )
            .toList(),
      );

      // Find user's rank
      _userRank =
          _dailyLeaderboard.indexWhere((e) => e.email == widget.user.email) + 1;
      if (_userRank == 0) {
        _userRank = 156; // User not in top, assign random rank
      }

      _isLoading = false;
    });

    _animController.forward();
  }

  List<LeaderboardEntry> _generateMockLeaderboard() {
    final names = [
      'TapMaster_Pro',
      'GoldDigger99',
      'SpeedTapper',
      'CoinKing',
      'MissionHunter',
      'AutoClicker_1',
      'DiamondHands',
      'EnergyMax',
      'TapLegend',
      'CryptoMiner',
    ];

    return List.generate(10, (i) {
      return LeaderboardEntry(
        rank: i + 1,
        username: names[i],
        email: '${names[i].toLowerCase()}@email.com',
        taps: (10000 - (i * 800)) + (i * 100),
        coins: (5000 - (i * 400)) + (i * 50),
        avatar: names[i][0],
      );
    });
  }

  List<LeaderboardEntry> get _currentLeaderboard {
    switch (_selectedTimeframe) {
      case 'weekly':
        return _weeklyLeaderboard;
      case 'allTime':
        return _allTimeLeaderboard;
      default:
        return _dailyLeaderboard;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
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
              _buildTimeframeTabs(),
              _buildUserRankCard(),
              const NativeAdWidget(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
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
            'LEADERBOARD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadLeaderboard();
            },
            icon: const Icon(Icons.refresh, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTimeframeChip('daily', 'Daily'),
          const SizedBox(width: 12),
          _buildTimeframeChip('weekly', 'Weekly'),
          const SizedBox(width: 12),
          _buildTimeframeChip('allTime', 'All Time'),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String value, String label) {
    final isSelected = _selectedTimeframe == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTimeframe = value);
        _animController.reset();
        _animController.forward();
      },
      child: Container(
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
                  '#$_userRank',
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
                    _userRank <= 10
                        ? 'Top 10! 🏆'
                        : _userRank <= 100
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
    if (_currentLeaderboard.length < 3) return const SizedBox();

    final top1 = _currentLeaderboard[0];
    final top2 = _currentLeaderboard[1];
    final top3 = _currentLeaderboard[2];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPodiumPlace(top2, 2, 100, 0.8),
          _buildPodiumPlace(top1, 1, 130, 1.0),
          _buildPodiumPlace(top3, 3, 80, 0.7),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    LeaderboardEntry entry,
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
        placeColor = const Color(0xFFC0C0C0);
        break;
      case 3:
        placeColor = const Color(0xFFCD7F32);
        break;
      default:
        placeColor = Colors.white;
    }

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
                // Avatar with crown/rank
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 70 * scale,
                      height: 70 * scale,
                      margin: const EdgeInsets.only(top: 15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: placeColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: placeColor.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          entry.avatar,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24 * scale,
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
                          size: 28,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.username,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * scale,
                  ),
                ),
                const SizedBox(height: 8),
                // Podium block
                Container(
                  width: 80 * scale,
                  height: height,
                  decoration:
                      NeumorphicDecoration.convex(
                        borderRadius: 12,
                        color: AppTheme.surfaceDark,
                      ).copyWith(
                        border: Border.all(
                          color: placeColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#$place',
                        style: TextStyle(
                          color: placeColor,
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _formatNumber(entry.coins),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10 * scale,
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
      child: NeumorphicCard(
        padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Coins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.toll, color: AppTheme.primary, size: 16),
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
