import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// User model for TapMine app
/// Stored locally in Hive and synced to Firestore via Cloudflare Worker
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String deviceId;

  @HiveField(3)
  int totalCoins;

  @HiveField(4)
  int lifetimeCoins;

  @HiveField(5)
  int totalTaps;

  @HiveField(6)
  int sessionTaps; // Taps in current session (for ad trigger)

  @HiveField(7)
  DateTime? lastSyncTime;

  @HiveField(8)
  String referralCode; // User's own referral code

  @HiveField(9)
  String? referredBy; // Who referred this user

  @HiveField(10)
  List<String> completedMissionIds;

  @HiveField(11)
  int currentMissionIndex;

  @HiveField(12)
  int currentMissionProgress; // Taps/ads toward current mission

  @HiveField(13)
  DateTime? lastWithdrawalDate;

  @HiveField(14)
  String? withdrawalStatus; // pending, completed, rejected

  @HiveField(15)
  String? upiId;

  @HiveField(16)
  DateTime createdAt;

  @HiveField(17)
  bool hapticEnabled;

  @HiveField(18)
  int adsWatchedToday;

  @HiveField(19)
  DateTime? lastAdWatchDate;

  @HiveField(20)
  int pendingWithdrawalAmount;

  UserModel({
    required this.uid,
    required this.email,
    required this.deviceId,
    this.totalCoins = 0,
    this.lifetimeCoins = 0,
    this.totalTaps = 0,
    this.sessionTaps = 0,
    this.lastSyncTime,
    required this.referralCode,
    this.referredBy,
    List<String>? completedMissionIds,
    this.currentMissionIndex = 0,
    this.currentMissionProgress = 0,
    this.lastWithdrawalDate,
    this.withdrawalStatus,
    this.upiId,
    DateTime? createdAt,
    this.hapticEnabled = true,
    this.adsWatchedToday = 0,
    this.lastAdWatchDate,
    this.pendingWithdrawalAmount = 0,
  }) : completedMissionIds = completedMissionIds ?? [],
       createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON for Firestore/API
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'deviceId': deviceId,
      'totalCoins': totalCoins,
      'lifetimeCoins': lifetimeCoins,
      'totalTaps': totalTaps,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'referralCode': referralCode,
      'referredBy': referredBy,
      'completedMissionIds': completedMissionIds,
      'currentMissionIndex': currentMissionIndex,
      'currentMissionProgress': currentMissionProgress,
      'lastWithdrawalDate': lastWithdrawalDate?.toIso8601String(),
      'withdrawalStatus': withdrawalStatus,
      'upiId': upiId,
      'createdAt': createdAt.toIso8601String(),
      'hapticEnabled': hapticEnabled,
      'pendingWithdrawalAmount': pendingWithdrawalAmount,
    };
  }

  /// Create from Firestore JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      deviceId: json['deviceId'] as String,
      totalCoins: json['totalCoins'] as int? ?? 0,
      lifetimeCoins: json['lifetimeCoins'] as int? ?? 0,
      totalTaps: json['totalTaps'] as int? ?? 0,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      referralCode: json['referralCode'] as String? ?? '',
      referredBy: json['referredBy'] as String?,
      completedMissionIds:
          (json['completedMissionIds'] as List<dynamic>?)?.cast<String>() ?? [],
      currentMissionIndex: json['currentMissionIndex'] as int? ?? 0,
      currentMissionProgress: json['currentMissionProgress'] as int? ?? 0,
      lastWithdrawalDate: json['lastWithdrawalDate'] != null
          ? DateTime.parse(json['lastWithdrawalDate'] as String)
          : null,
      withdrawalStatus: json['withdrawalStatus'] as String?,
      upiId: json['upiId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      pendingWithdrawalAmount: json['pendingWithdrawalAmount'] as int? ?? 0,
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? deviceId,
    int? totalCoins,
    int? lifetimeCoins,
    int? totalTaps,
    int? sessionTaps,
    DateTime? lastSyncTime,
    String? referralCode,
    String? referredBy,
    List<String>? completedMissionIds,
    int? currentMissionIndex,
    int? currentMissionProgress,
    DateTime? lastWithdrawalDate,
    String? withdrawalStatus,
    String? upiId,
    DateTime? createdAt,
    bool? hapticEnabled,
    int? adsWatchedToday,
    DateTime? lastAdWatchDate,
    int? pendingWithdrawalAmount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      deviceId: deviceId ?? this.deviceId,
      totalCoins: totalCoins ?? this.totalCoins,
      lifetimeCoins: lifetimeCoins ?? this.lifetimeCoins,
      totalTaps: totalTaps ?? this.totalTaps,
      sessionTaps: sessionTaps ?? this.sessionTaps,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
      currentMissionIndex: currentMissionIndex ?? this.currentMissionIndex,
      currentMissionProgress:
          currentMissionProgress ?? this.currentMissionProgress,
      lastWithdrawalDate: lastWithdrawalDate ?? this.lastWithdrawalDate,
      withdrawalStatus: withdrawalStatus ?? this.withdrawalStatus,
      upiId: upiId ?? this.upiId,
      createdAt: createdAt ?? this.createdAt,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      lastAdWatchDate: lastAdWatchDate ?? this.lastAdWatchDate,
      pendingWithdrawalAmount:
          pendingWithdrawalAmount ?? this.pendingWithdrawalAmount,
    );
  }

  /// Check if user can withdraw (has minimum coins)
  bool get canWithdraw => totalCoins >= 100000;

  /// Convert coins to rupees
  double get coinsInRupees => totalCoins / 1000;

  /// Get current tier (easy or hard)
  bool get isInHardTier => currentMissionIndex >= 15;

  /// Reset mission progress (after withdrawal)
  void resetMissions() {
    completedMissionIds.clear();
    currentMissionIndex = 0;
    currentMissionProgress = 0;
  }
}
