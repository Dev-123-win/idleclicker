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
    // Tier 1 - Quick Missions
    MissionModel(
      id: 'mission_1a',
      name: 'Quick Tap I',
      tier: 'tier1',
      tapRequirement: 2000,
      acReward: 40,
      energyCost: 20,
      cooldownMinutes: 15,
      interstitialAds: 1,
      rewardedAds: 0,
      adCheckpoints: [2000],
      description: 'A quick tapping session to get started.',
    ),
    MissionModel(
      id: 'mission_1b',
      name: 'Quick Tap II',
      tier: 'tier1',
      tapRequirement: 5000,
      acReward: 100,
      energyCost: 50,
      cooldownMinutes: 15,
      interstitialAds: 2,
      rewardedAds: 0,
      adCheckpoints: [2500, 5000],
      description: 'Double the taps, double the rewards!',
    ),
    // Tier 2 - Medium Missions
    MissionModel(
      id: 'mission_2a',
      name: 'Tap Master I',
      tier: 'tier2',
      tapRequirement: 10000,
      acReward: 250,
      energyCost: 100,
      cooldownMinutes: 30,
      interstitialAds: 2,
      rewardedAds: 1,
      adCheckpoints: [3300, 6600, 10000],
      description: 'Show your tapping prowess!',
    ),
    MissionModel(
      id: 'mission_2b',
      name: 'Tap Master II',
      tier: 'tier2',
      tapRequirement: 20000,
      acReward: 600,
      energyCost: 200,
      cooldownMinutes: 30,
      interstitialAds: 3,
      rewardedAds: 2,
      adCheckpoints: [5000, 10000, 15000, 20000],
      description: 'A marathon tapping session awaits!',
    ),
    // Tier 3 - Premium Missions
    MissionModel(
      id: 'mission_3a',
      name: 'Gold Rush I',
      tier: 'tier3',
      tapRequirement: 50000,
      acReward: 1500,
      energyCost: 500,
      cooldownMinutes: 60,
      interstitialAds: 5,
      rewardedAds: 3,
      adCheckpoints: [10000, 20000, 30000, 40000, 50000],
      description: 'Premium rewards for dedicated tappers.',
    ),
    MissionModel(
      id: 'mission_3b',
      name: 'Gold Rush II',
      tier: 'tier3',
      tapRequirement: 100000,
      acReward: 3500,
      energyCost: 1000,
      cooldownMinutes: 60,
      interstitialAds: 8,
      rewardedAds: 5,
      adCheckpoints: [12500, 25000, 37500, 50000, 62500, 75000, 87500, 100000],
      description: 'The ultimate tapping challenge!',
    ),
    // Special - Daily Challenge
    MissionModel(
      id: 'daily_challenge',
      name: 'Daily Challenge',
      tier: 'tier2',
      tapRequirement: 30000,
      acReward: 2000,
      energyCost: 300,
      cooldownMinutes: 0, // No cooldown, once per day
      interstitialAds: 6,
      rewardedAds: 10,
      adCheckpoints: [5000, 10000, 15000, 20000, 25000, 30000],
      description: '2x rewards! Available once daily.',
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
