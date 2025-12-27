// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      uid: fields[0] as String,
      email: fields[1] as String,
      deviceId: fields[2] as String,
      totalCoins: fields[3] as int,
      lifetimeCoins: fields[4] as int,
      totalTaps: fields[5] as int,
      sessionTaps: fields[6] as int,
      lastSyncTime: fields[7] as DateTime?,
      referralCode: fields[8] as String,
      referredBy: fields[9] as String?,
      completedMissionIds: (fields[10] as List?)?.cast<String>(),
      currentMissionIndex: fields[11] as int,
      currentMissionProgress: fields[12] as int,
      lastWithdrawalDate: fields[13] as DateTime?,
      withdrawalStatus: fields[14] as String?,
      upiId: fields[15] as String?,
      createdAt: fields[16] as DateTime?,
      hapticEnabled: fields[17] as bool,
      adsWatchedToday: fields[18] as int,
      lastAdWatchDate: fields[19] as DateTime?,
      pendingWithdrawalAmount: fields[20] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.deviceId)
      ..writeByte(3)
      ..write(obj.totalCoins)
      ..writeByte(4)
      ..write(obj.lifetimeCoins)
      ..writeByte(5)
      ..write(obj.totalTaps)
      ..writeByte(6)
      ..write(obj.sessionTaps)
      ..writeByte(7)
      ..write(obj.lastSyncTime)
      ..writeByte(8)
      ..write(obj.referralCode)
      ..writeByte(9)
      ..write(obj.referredBy)
      ..writeByte(10)
      ..write(obj.completedMissionIds)
      ..writeByte(11)
      ..write(obj.currentMissionIndex)
      ..writeByte(12)
      ..write(obj.currentMissionProgress)
      ..writeByte(13)
      ..write(obj.lastWithdrawalDate)
      ..writeByte(14)
      ..write(obj.withdrawalStatus)
      ..writeByte(15)
      ..write(obj.upiId)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.hapticEnabled)
      ..writeByte(18)
      ..write(obj.adsWatchedToday)
      ..writeByte(19)
      ..write(obj.lastAdWatchDate)
      ..writeByte(20)
      ..write(obj.pendingWithdrawalAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
