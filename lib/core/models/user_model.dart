import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for Firestore - optimized for free tier (minimal reads/writes)
class UserModel {
  final String uid;
  final String email;
  final int appCoins;
  final int totalTaps;
  final int energy;
  final int maxEnergy;
  final DateTime lastEnergyUpdate;
  final int currentStreak;
  final DateTime? lastLoginDate;
  final int totalAdsWatched;
  final int missionsCompleted;
  final int daysActive;
  final List<String> unlockedTiers;
  final Map<String, dynamic> activePasses;
  final String? upiId;
  final bool panVerified;
  final DateTime createdAt;
  final DateTime lastSyncAt;

  // Referral system
  final String referralCode;
  final String? referredBy;
  final int referralCount;

  // Withdrawal state
  final DateTime? lastWithdrawalDate;

  // Auto-clicker state
  final bool autoClickerActive;
  final int autoClickerSpeed;
  final DateTime? autoClickerRentalExpiry;
  final String autoClickerTier; // 'free', 'bronze', 'silver', 'gold'

  final DateTime? missionCooldownEnd;
  final DateTime? adCooldownEnd;
  final String hapticSetting; // 'strong', 'eco', 'off'

  UserModel({
    required this.uid,
    required this.email,
    this.appCoins = 0,
    this.totalTaps = 0,
    this.energy = 100,
    this.maxEnergy = 100,
    required this.lastEnergyUpdate,
    this.currentStreak = 0,
    this.lastLoginDate,
    this.totalAdsWatched = 0,
    this.missionsCompleted = 0,
    this.daysActive = 1,
    this.unlockedTiers = const ['tier1'],
    this.activePasses = const {},
    this.upiId,
    this.panVerified = false,
    required this.createdAt,
    required this.lastSyncAt,
    required this.referralCode,
    this.referredBy,
    this.referralCount = 0,
    this.lastWithdrawalDate,
    this.autoClickerActive = false,
    this.autoClickerSpeed = 5,
    this.autoClickerRentalExpiry,
    this.autoClickerTier = 'free',
    this.missionCooldownEnd,
    this.adCooldownEnd,
    this.hapticSetting = 'eco',
  });

  /// Create new user with defaults
  factory UserModel.newUser({required String uid, required String email}) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      lastEnergyUpdate: now,
      lastLoginDate: now,
      createdAt: now,
      lastSyncAt: now,
      referralCode: uid.substring(0, 6).toUpperCase(),
    );
  }

  /// From Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      appCoins: data['appCoins'] ?? 0,
      totalTaps: data['totalTaps'] ?? 0,
      energy: data['energy'] ?? 100,
      maxEnergy: data['maxEnergy'] ?? 100,
      lastEnergyUpdate:
          (data['lastEnergyUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentStreak: data['currentStreak'] ?? 0,
      lastLoginDate: (data['lastLoginDate'] as Timestamp?)?.toDate(),
      totalAdsWatched: data['totalAdsWatched'] ?? 0,
      missionsCompleted: data['missionsCompleted'] ?? 0,
      daysActive: data['daysActive'] ?? 1,
      unlockedTiers: List<String>.from(data['unlockedTiers'] ?? ['tier1']),
      activePasses: Map<String, dynamic>.from(data['activePasses'] ?? {}),
      upiId: data['upiId'],
      panVerified: data['panVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSyncAt:
          (data['lastSyncAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autoClickerActive: data['autoClickerActive'] ?? false,
      autoClickerSpeed: data['autoClickerSpeed'] ?? 5,
      autoClickerRentalExpiry: (data['autoClickerRentalExpiry'] as Timestamp?)
          ?.toDate(),
      autoClickerTier: data['autoClickerTier'] ?? 'free',
      missionCooldownEnd: (data['missionCooldownEnd'] as Timestamp?)?.toDate(),
      adCooldownEnd: (data['adCooldownEnd'] as Timestamp?)?.toDate(),
      referralCode:
          data['referralCode'] ?? doc.id.substring(0, 6).toUpperCase(),
      referredBy: data['referredBy'],
      referralCount: data['referralCount'] ?? 0,
      lastWithdrawalDate: (data['lastWithdrawalDate'] as Timestamp?)?.toDate(),
      hapticSetting: data['hapticSetting'] ?? 'eco',
    );
  }

  /// To Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'appCoins': appCoins,
      'totalTaps': totalTaps,
      'energy': energy,
      'maxEnergy': maxEnergy,
      'lastEnergyUpdate': Timestamp.fromDate(lastEnergyUpdate),
      'currentStreak': currentStreak,
      'lastLoginDate': lastLoginDate != null
          ? Timestamp.fromDate(lastLoginDate!)
          : null,
      'totalAdsWatched': totalAdsWatched,
      'missionsCompleted': missionsCompleted,
      'daysActive': daysActive,
      'unlockedTiers': unlockedTiers,
      'activePasses': activePasses,
      'upiId': upiId,
      'panVerified': panVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSyncAt': Timestamp.fromDate(lastSyncAt),
      'autoClickerActive': autoClickerActive,
      'autoClickerSpeed': autoClickerSpeed,
      'autoClickerRentalExpiry': autoClickerRentalExpiry != null
          ? Timestamp.fromDate(autoClickerRentalExpiry!)
          : null,
      'autoClickerTier': autoClickerTier,
      'missionCooldownEnd': missionCooldownEnd != null
          ? Timestamp.fromDate(missionCooldownEnd!)
          : null,
      'adCooldownEnd': adCooldownEnd != null
          ? Timestamp.fromDate(adCooldownEnd!)
          : null,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'lastWithdrawalDate': lastWithdrawalDate != null
          ? Timestamp.fromDate(lastWithdrawalDate!)
          : null,
      'hapticSetting': hapticSetting,
    };
  }

  /// Copy with updated fields
  UserModel copyWith({
    int? appCoins,
    int? totalTaps,
    int? energy,
    int? maxEnergy,
    DateTime? lastEnergyUpdate,
    int? currentStreak,
    DateTime? lastLoginDate,
    int? totalAdsWatched,
    int? missionsCompleted,
    int? daysActive,
    List<String>? unlockedTiers,
    Map<String, dynamic>? activePasses,
    String? upiId,
    bool? panVerified,
    DateTime? lastSyncAt,
    bool? autoClickerActive,
    int? autoClickerSpeed,
    DateTime? autoClickerRentalExpiry,
    String? autoClickerTier,
    DateTime? missionCooldownEnd,
    DateTime? adCooldownEnd,
    String? referralCode,
    String? referredBy,
    int? referralCount,
    DateTime? lastWithdrawalDate,
    String? hapticSetting,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      appCoins: appCoins ?? this.appCoins,
      totalTaps: totalTaps ?? this.totalTaps,
      energy: energy ?? this.energy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      lastEnergyUpdate: lastEnergyUpdate ?? this.lastEnergyUpdate,
      currentStreak: currentStreak ?? this.currentStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      totalAdsWatched: totalAdsWatched ?? this.totalAdsWatched,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      daysActive: daysActive ?? this.daysActive,
      unlockedTiers: unlockedTiers ?? this.unlockedTiers,
      activePasses: activePasses ?? this.activePasses,
      upiId: upiId ?? this.upiId,
      panVerified: panVerified ?? this.panVerified,
      createdAt: createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      autoClickerActive: autoClickerActive ?? this.autoClickerActive,
      autoClickerSpeed: autoClickerSpeed ?? this.autoClickerSpeed,
      autoClickerRentalExpiry:
          autoClickerRentalExpiry ?? this.autoClickerRentalExpiry,
      autoClickerTier: autoClickerTier ?? this.autoClickerTier,
      missionCooldownEnd: missionCooldownEnd ?? this.missionCooldownEnd,
      adCooldownEnd: adCooldownEnd ?? this.adCooldownEnd,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referralCount: referralCount ?? this.referralCount,
      lastWithdrawalDate: lastWithdrawalDate ?? this.lastWithdrawalDate,
      hapticSetting: hapticSetting ?? this.hapticSetting,
    );
  }

  /// Calculate current energy with regeneration
  int getCurrentEnergy() {
    final now = DateTime.now();
    final minutesPassed = now.difference(lastEnergyUpdate).inMinutes;
    final regeneratedEnergy = minutesPassed; // 1 energy per minute
    return (energy + regeneratedEnergy).clamp(0, maxEnergy);
  }

  /// Check if in mission cooldown
  bool get isInMissionCooldown {
    if (missionCooldownEnd == null) return false;
    return DateTime.now().isBefore(missionCooldownEnd!);
  }

  /// Check if in ad cooldown
  bool get isInAdCooldown {
    if (adCooldownEnd == null) return false;
    return DateTime.now().isBefore(adCooldownEnd!);
  }

  /// Get remaining mission cooldown duration
  Duration get remainingMissionCooldown {
    if (!isInMissionCooldown) return Duration.zero;
    return missionCooldownEnd!.difference(DateTime.now());
  }

  /// Get remaining ad cooldown duration
  Duration get remainingAdCooldown {
    if (!isInAdCooldown) return Duration.zero;
    return adCooldownEnd!.difference(DateTime.now());
  }

  /// Check if premium auto-clicker is active
  bool get hasPremiumAutoClicker {
    if (autoClickerRentalExpiry == null) return false;
    return DateTime.now().isBefore(autoClickerRentalExpiry!) &&
        autoClickerTier != 'free';
  }

  /// Get withdrawal amount in INR
  double get withdrawableAmountInr => appCoins / 1000.0;

  /// Check if can withdraw
  bool get canWithdraw {
    if (appCoins < 100000) return false;
    if (lastWithdrawalDate != null) {
      final daysSinceLast = DateTime.now()
          .difference(lastWithdrawalDate!)
          .inDays;
      if (daysSinceLast < 15) return false;
    }
    return true;
  }
}
