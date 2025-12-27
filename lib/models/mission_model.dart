import 'package:hive/hive.dart';

part 'mission_model.g.dart';

/// Mission types
enum MissionType {
  taps, // Complete X taps
  watchAds, // Watch X ads
}

/// Mission tier - affects difficulty and rewards
enum MissionTier {
  easy, // Missions 1-15: fewer taps, fewer ads, higher rewards
  hard, // Missions 16-50: more taps, more ads, lower rewards
}

/// Mission model for defining game missions
@HiveType(typeId: 1)
class MissionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int target; // Number of taps or ads required

  @HiveField(4)
  final int reward; // Coins earned on completion

  @HiveField(5)
  final int missionTypeIndex; // 0 = taps, 1 = watchAds

  @HiveField(6)
  final int tierIndex; // 0 = easy, 1 = hard

  @HiveField(7)
  final int adsTriggered; // Number of ads shown during this mission

  @HiveField(8)
  final int order; // Mission order (1-50)

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
    required this.missionTypeIndex,
    required this.tierIndex,
    required this.adsTriggered,
    required this.order,
  });

  MissionType get missionType => MissionType.values[missionTypeIndex];

  MissionTier get tier => MissionTier.values[tierIndex];

  bool get isEasyTier => tier == MissionTier.easy;
  bool get isHardTier => tier == MissionTier.hard;
  bool get isTapMission => missionType == MissionType.taps;
  bool get isAdMission => missionType == MissionType.watchAds;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target': target,
      'reward': reward,
      'missionType': missionType.name,
      'tier': tier.name,
      'adsTriggered': adsTriggered,
      'order': order,
    };
  }

  /// Create from JSON
  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      target: json['target'] as int,
      reward: json['reward'] as int,
      missionTypeIndex: json['missionType'] == 'watchAds' ? 1 : 0,
      tierIndex: json['tier'] == 'hard' ? 1 : 0,
      adsTriggered: json['adsTriggered'] as int,
      order: json['order'] as int,
    );
  }
}

/// All 50 missions for the game
class Missions {
  Missions._();

  static final List<MissionModel> all = [
    // ===== EASY TIER (Missions 1-15) - ~₹50 total =====
    MissionModel(
      id: 'mission_1',
      title: 'Welcome Tap',
      description: 'Your first steps! Tap 50 times to start earning.',
      target: 50,
      reward: 3000,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 1,
      order: 1,
    ),
    MissionModel(
      id: 'mission_2',
      title: 'Getting Started',
      description: 'Keep the momentum going with 100 taps!',
      target: 100,
      reward: 2500,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 2,
      order: 2,
    ),
    MissionModel(
      id: 'mission_3',
      title: 'First Ad',
      description: 'Watch 3 rewarded ads to earn bonus coins.',
      target: 3,
      reward: 2000,
      missionTypeIndex: 1,
      tierIndex: 0,
      adsTriggered: 3,
      order: 3,
    ),
    MissionModel(
      id: 'mission_4',
      title: 'Momentum',
      description: 'Build your momentum with 150 taps.',
      target: 150,
      reward: 2000,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 3,
      order: 4,
    ),
    MissionModel(
      id: 'mission_5',
      title: 'Keep Tapping',
      description: 'Stay focused and complete 200 taps.',
      target: 200,
      reward: 2000,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 4,
      order: 5,
    ),
    MissionModel(
      id: 'mission_6',
      title: 'Ad Break',
      description: 'Take a break and watch 3 ads.',
      target: 3,
      reward: 1800,
      missionTypeIndex: 1,
      tierIndex: 0,
      adsTriggered: 3,
      order: 6,
    ),
    MissionModel(
      id: 'mission_7',
      title: 'Rising Star',
      description: 'You\'re becoming a pro! Complete 300 taps.',
      target: 300,
      reward: 2500,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 6,
      order: 7,
    ),
    MissionModel(
      id: 'mission_8',
      title: 'Halfway Easy',
      description: 'Halfway through easy tier! 400 taps to go.',
      target: 400,
      reward: 3000,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 8,
      order: 8,
    ),
    MissionModel(
      id: 'mission_9',
      title: 'Ad Fan',
      description: 'Watch 5 ads to unlock bonus rewards.',
      target: 5,
      reward: 2000,
      missionTypeIndex: 1,
      tierIndex: 0,
      adsTriggered: 5,
      order: 9,
    ),
    MissionModel(
      id: 'mission_10',
      title: 'Consistent',
      description: 'Consistency is key! Complete 500 taps.',
      target: 500,
      reward: 3500,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 10,
      order: 10,
    ),
    MissionModel(
      id: 'mission_11',
      title: 'Marathon Start',
      description: 'Starting the marathon with 600 taps!',
      target: 600,
      reward: 4000,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 12,
      order: 11,
    ),
    MissionModel(
      id: 'mission_12',
      title: 'Ad Veteran',
      description: 'You\'re getting good at this! Watch 5 ads.',
      target: 5,
      reward: 2500,
      missionTypeIndex: 1,
      tierIndex: 0,
      adsTriggered: 5,
      order: 12,
    ),
    MissionModel(
      id: 'mission_13',
      title: 'Power Tapper',
      description: 'Show your power with 800 taps!',
      target: 800,
      reward: 5000,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 16,
      order: 13,
    ),
    MissionModel(
      id: 'mission_14',
      title: 'Near Halfway',
      description: 'Almost at the halfway point! 1000 taps.',
      target: 1000,
      reward: 6000,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 20,
      order: 14,
    ),
    MissionModel(
      id: 'mission_15',
      title: 'Halfway Hero',
      description: 'Congratulations! You\'ve earned ₹50. Keep going for ₹100!',
      target: 1200,
      reward: 8200,
      missionTypeIndex: 0,
      tierIndex: 0,
      adsTriggered: 24,
      order: 15,
    ),

    // ===== HARD TIER (Missions 16-50) - ~₹50 more = ₹100 total =====
    MissionModel(
      id: 'mission_16',
      title: 'Real Challenge',
      description: 'The real challenge begins! 1500 taps.',
      target: 1500,
      reward: 1500,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 30,
      order: 16,
    ),
    MissionModel(
      id: 'mission_17',
      title: 'Ad Warrior',
      description: 'Prove your dedication. Watch 5 ads.',
      target: 5,
      reward: 600,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 17,
    ),
    MissionModel(
      id: 'mission_18',
      title: 'Grinding',
      description: 'Time to grind! Complete 1800 taps.',
      target: 1800,
      reward: 1200,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 36,
      order: 18,
    ),
    MissionModel(
      id: 'mission_19',
      title: 'Persistence',
      description: 'Persistence pays off. 2000 taps!',
      target: 2000,
      reward: 1000,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 40,
      order: 19,
    ),
    MissionModel(
      id: 'mission_20',
      title: 'Ad Master',
      description: 'Master the ads. Watch 5 more.',
      target: 5,
      reward: 500,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 20,
    ),
    MissionModel(
      id: 'mission_21',
      title: 'Endurance I',
      description: 'Test your endurance. 2500 taps!',
      target: 2500,
      reward: 1200,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 50,
      order: 21,
    ),
    MissionModel(
      id: 'mission_22',
      title: 'Endurance II',
      description: 'Keep going! 2800 taps.',
      target: 2800,
      reward: 1000,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 56,
      order: 22,
    ),
    MissionModel(
      id: 'mission_23',
      title: 'Ad Collector',
      description: 'Collect more rewards. Watch 5 ads.',
      target: 5,
      reward: 400,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 23,
    ),
    MissionModel(
      id: 'mission_24',
      title: 'Tough Road',
      description: 'The road gets tough. 3000 taps!',
      target: 3000,
      reward: 1100,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 60,
      order: 24,
    ),
    MissionModel(
      id: 'mission_25',
      title: 'Quarter Done',
      description: 'Quarter of hard tier done! 3200 taps.',
      target: 3200,
      reward: 1000,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 64,
      order: 25,
    ),
    MissionModel(
      id: 'mission_26',
      title: 'Dedicated',
      description: 'You\'re truly dedicated. 3500 taps!',
      target: 3500,
      reward: 950,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 70,
      order: 26,
    ),
    MissionModel(
      id: 'mission_27',
      title: 'Ad Expert I',
      description: 'Become an ad expert. Watch 5 ads.',
      target: 5,
      reward: 400,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 27,
    ),
    MissionModel(
      id: 'mission_28',
      title: 'Serious',
      description: 'Getting serious now. 3800 taps!',
      target: 3800,
      reward: 900,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 76,
      order: 28,
    ),
    MissionModel(
      id: 'mission_29',
      title: 'Unstoppable',
      description: 'You\'re unstoppable! 4000 taps.',
      target: 4000,
      reward: 850,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 80,
      order: 29,
    ),
    MissionModel(
      id: 'mission_30',
      title: 'Ad Expert II',
      description: 'Continue your expertise. Watch 5 ads.',
      target: 5,
      reward: 350,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 30,
    ),
    MissionModel(
      id: 'mission_31',
      title: 'Champion',
      description: 'Rise to champion status. 4300 taps!',
      target: 4300,
      reward: 800,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 86,
      order: 31,
    ),
    MissionModel(
      id: 'mission_32',
      title: 'Elite',
      description: 'Join the elite. 4600 taps!',
      target: 4600,
      reward: 800,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 92,
      order: 32,
    ),
    MissionModel(
      id: 'mission_33',
      title: 'Ad Pro I',
      description: 'Pro level ads. Watch 5.',
      target: 5,
      reward: 350,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 33,
    ),
    MissionModel(
      id: 'mission_34',
      title: 'Legend',
      description: 'Become a legend. 4900 taps!',
      target: 4900,
      reward: 750,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 98,
      order: 34,
    ),
    MissionModel(
      id: 'mission_35',
      title: 'Veteran',
      description: 'Veteran status achieved! 5000 taps.',
      target: 5000,
      reward: 800,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 100,
      order: 35,
    ),
    MissionModel(
      id: 'mission_36',
      title: 'Ad Pro II',
      description: 'Keep watching. 5 more ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 36,
    ),
    MissionModel(
      id: 'mission_37',
      title: 'Ad Pro III',
      description: 'Almost there. 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 37,
    ),
    MissionModel(
      id: 'mission_38',
      title: 'Ad Pro IV',
      description: 'Final ad push. 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 38,
    ),
    MissionModel(
      id: 'mission_39',
      title: 'Ad Pro V',
      description: 'Last ad mission! 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 39,
    ),
    MissionModel(
      id: 'mission_40',
      title: 'Ad Challenge',
      description: 'Ad challenge complete! 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 40,
    ),
    MissionModel(
      id: 'mission_41',
      title: 'Extreme I',
      description: 'Extreme tapping begins. 6000 taps!',
      target: 6000,
      reward: 700,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 120,
      order: 41,
    ),
    MissionModel(
      id: 'mission_42',
      title: 'Extreme II',
      description: 'Keep pushing! 6500 taps.',
      target: 6500,
      reward: 700,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 130,
      order: 42,
    ),
    MissionModel(
      id: 'mission_43',
      title: 'Extreme III',
      description: 'No stopping now. 7000 taps!',
      target: 7000,
      reward: 650,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 140,
      order: 43,
    ),
    MissionModel(
      id: 'mission_44',
      title: 'Extreme IV',
      description: 'Push your limits. 7500 taps!',
      target: 7500,
      reward: 650,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 150,
      order: 44,
    ),
    MissionModel(
      id: 'mission_45',
      title: 'Extreme V',
      description: 'Final extreme! 8000 taps.',
      target: 8000,
      reward: 600,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 160,
      order: 45,
    ),
    MissionModel(
      id: 'mission_46',
      title: 'Final Ads I',
      description: 'First final ad push. 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 46,
    ),
    MissionModel(
      id: 'mission_47',
      title: 'Final Ads II',
      description: 'Second final ad push. 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 47,
    ),
    MissionModel(
      id: 'mission_48',
      title: 'Final Ads III',
      description: 'Third final ad push. 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 48,
    ),
    MissionModel(
      id: 'mission_49',
      title: 'Final Ads IV',
      description: 'Last ad mission ever! 5 ads.',
      target: 5,
      reward: 300,
      missionTypeIndex: 1,
      tierIndex: 1,
      adsTriggered: 5,
      order: 49,
    ),
    MissionModel(
      id: 'mission_50',
      title: 'Ultimate Miner',
      description: 'THE ULTIMATE CHALLENGE! 15000 taps to claim ₹100!',
      target: 15000,
      reward: 11500,
      missionTypeIndex: 0,
      tierIndex: 1,
      adsTriggered: 300,
      order: 50,
    ),
  ];

  /// Get mission by index (0-49)
  static MissionModel getMission(int index) {
    if (index < 0 || index >= all.length) {
      return all.last;
    }
    return all[index];
  }

  /// Get total coins from completing all missions
  static int get totalPossibleCoins {
    return all.fold(0, (sum, mission) => sum + mission.reward);
  }

  /// Get total ads user will watch to complete all missions
  static int get totalAdsToComplete {
    return all.fold(0, (sum, mission) => sum + mission.adsTriggered);
  }
}
