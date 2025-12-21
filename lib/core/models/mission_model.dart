/// Mission model representing tap missions
class MissionModel {
  final String id;
  final String name;
  final String tier; // 'tier1', 'tier2', 'tier3'
  final int tapRequirement;
  final int acReward;
  final int energyCost;
  final int cooldownMinutes;
  final int interstitialAds;
  final int rewardedAds;
  final List<int> adCheckpoints; // Tap counts where ads trigger
  final String description;
  final bool isSpecial;
  final bool isWeekendOnly;

  const MissionModel({
    required this.id,
    required this.name,
    required this.tier,
    required this.tapRequirement,
    required this.acReward,
    required this.energyCost,
    required this.cooldownMinutes,
    required this.interstitialAds,
    required this.rewardedAds,
    required this.adCheckpoints,
    this.description = '',
    this.isSpecial = false,
    this.isWeekendOnly = false,
  });

  /// Get tier display name
  String get tierDisplayName {
    switch (tier) {
      case 'tier1':
        return 'Quick';
      case 'tier2':
        return 'Medium';
      case 'tier3':
        return 'Premium';
      default:
        return 'Unknown';
    }
  }

  /// Calculate estimated time in minutes
  int get estimatedTimeManual =>
      (tapRequirement / 400).ceil(); // ~400 taps/min manual
  int get estimatedTimeAutoClicker =>
      (tapRequirement / 600).ceil(); // ~600 taps/min auto

  /// Get AC per tap ratio
  double get acPerTap => acReward / tapRequirement;

  /// Check if tier is unlocked
  /// Check if tier is unlocked
  bool isUnlockedFor(List<String> unlockedTiers) {
    return unlockedTiers.contains(tier);
  }

  /// Create from Firestore
  factory MissionModel.fromFirestore(Map<String, dynamic> data) {
    return MissionModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      tier: data['tier'] ?? 'tier1',
      tapRequirement: data['tapRequirement'] ?? 0,
      acReward: data['acReward'] ?? 0,
      energyCost: data['energyCost'] ?? 0,
      cooldownMinutes: data['cooldownMinutes'] ?? 0,
      interstitialAds: data['interstitialAds'] ?? 0,
      rewardedAds: data['rewardedAds'] ?? 0,
      adCheckpoints: List<int>.from(data['adCheckpoints'] ?? []),
      description: data['description'] ?? '',
      isSpecial: data['isSpecial'] ?? false,
      isWeekendOnly: data['isWeekendOnly'] ?? false,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'tapRequirement': tapRequirement,
      'acReward': acReward,
      'energyCost': energyCost,
      'cooldownMinutes': cooldownMinutes,
      'interstitialAds': interstitialAds,
      'rewardedAds': rewardedAds,
      'adCheckpoints': adCheckpoints,
      'description': description,
      'isSpecial': isSpecial,
      'isWeekendOnly': isWeekendOnly,
    };
  }
}

/// Predefined missions based on PRD
class Missions {
  static const List<MissionModel> all = [
    // Tier 1 - Quick Missions (The Hook)
    MissionModel(
      id: 'mission_1a',
      name: 'First Steps',
      tier: 'tier1',
      tapRequirement: 1000,
      acReward: 2000,
      energyCost: 10,
      cooldownMinutes: 5,
      interstitialAds: 10,
      rewardedAds: 0,
      adCheckpoints: [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000],
      description: 'Your journey begins here. Fast rewards for new miners!',
    ),
    MissionModel(
      id: 'mission_1b',
      name: 'Quick Tap',
      tier: 'tier1',
      tapRequirement: 2000,
      acReward: 3000,
      energyCost: 20,
      cooldownMinutes: 5,
      interstitialAds: 18,
      rewardedAds: 0,
      adCheckpoints: [200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000],
      description: 'Pick up the pace! More taps, more coins.',
    ),
    MissionModel(
      id: 'mission_1c',
      name: 'Speed Run',
      tier: 'tier1',
      tapRequirement: 3000,
      acReward: 4000,
      energyCost: 30,
      cooldownMinutes: 5,
      interstitialAds: 29,
      rewardedAds: 0,
      adCheckpoints: [300, 600, 900, 1200, 1500, 1800, 2100, 2400, 2700, 3000],
      description: 'Test your speed in this high-energy sprint.',
    ),

    // Tier 2 - Intermediate Missions (The Grind)
    MissionModel(
      id: 'mission_2a',
      name: 'Coin Hunter',
      tier: 'tier2',
      tapRequirement: 5000,
      acReward: 5000,
      energyCost: 50,
      cooldownMinutes: 15,
      interstitialAds: 56,
      rewardedAds: 0,
      adCheckpoints: [1000, 2000, 3000, 4000, 5000],
      description: 'Hunt for coins across deeper layers of the mine.',
    ),
    MissionModel(
      id: 'mission_2b',
      name: 'Tap Master',
      tier: 'tier2',
      tapRequirement: 8000,
      acReward: 6000,
      energyCost: 80,
      cooldownMinutes: 15,
      interstitialAds: 88,
      rewardedAds: 0,
      adCheckpoints: [2000, 4000, 6000, 8000],
      description: 'Master the art of consistent tapping for big rewards.',
    ),
    MissionModel(
      id: 'mission_2c',
      name: 'Marathon',
      tier: 'tier2',
      tapRequirement: 12000,
      acReward: 7000,
      energyCost: 120,
      cooldownMinutes: 15,
      interstitialAds: 130,
      rewardedAds: 0,
      adCheckpoints: [3000, 6000, 9000, 12000],
      description: 'An endurance test for the most dedicated miners.',
    ),

    // Tier 3 - Premium Missions (The Profit)
    MissionModel(
      id: 'mission_3a',
      name: 'Gold Rush',
      tier: 'tier3',
      tapRequirement: 20000,
      acReward: 2000,
      energyCost: 200,
      cooldownMinutes: 30,
      interstitialAds: 180,
      rewardedAds: 2,
      adCheckpoints: [5000, 10000, 15000, 20000],
      description: 'High-stakes mining. Maximum profit extraction!',
    ),
    MissionModel(
      id: 'mission_3b',
      name: 'Mega Jackpot',
      tier: 'tier3',
      tapRequirement: 50000,
      acReward: 5000,
      energyCost: 500,
      cooldownMinutes: 30,
      interstitialAds: 450,
      rewardedAds: 5,
      adCheckpoints: [12500, 25000, 37500, 50000],
      description: 'The ultimate challenge. Can you hit the jackpot?',
    ),
    MissionModel(
      id: 'mission_3c',
      name: 'Legendary Tap',
      tier: 'tier3',
      tapRequirement: 100000,
      acReward: 10000,
      energyCost: 1000,
      cooldownMinutes: 60,
      interstitialAds: 900,
      rewardedAds: 10,
      adCheckpoints: [25000, 50000, 75000, 100000],
      description: 'The mining legend. Only for the 1%!',
    ),

    // Special - Daily Challenge
    MissionModel(
      id: 'daily_challenge',
      name: 'Daily Challenge',
      tier: 'tier2',
      tapRequirement: 30000,
      acReward: 15000,
      energyCost: 300,
      cooldownMinutes: 0,
      interstitialAds: 300,
      rewardedAds: 5,
      adCheckpoints: [5000, 10000, 15000, 20000, 25000, 30000],
      description: 'Once-a-day treasure trove! 2x Rewards.',
      isSpecial: true,
    ),
  ];

  static List<MissionModel> getByTier(String tier) {
    return all.where((m) => m.tier == tier && !m.isSpecial).toList();
  }

  static List<MissionModel> getAvailableFor(List<String> unlockedTiers) {
    return all.where((m) => m.isUnlockedFor(unlockedTiers)).toList();
  }

  static MissionModel? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
