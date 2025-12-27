// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissionModelAdapter extends TypeAdapter<MissionModel> {
  @override
  final int typeId = 1;

  @override
  MissionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MissionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      target: fields[3] as int,
      reward: fields[4] as int,
      missionTypeIndex: fields[5] as int,
      tierIndex: fields[6] as int,
      adsTriggered: fields[7] as int,
      order: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MissionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.target)
      ..writeByte(4)
      ..write(obj.reward)
      ..writeByte(5)
      ..write(obj.missionTypeIndex)
      ..writeByte(6)
      ..write(obj.tierIndex)
      ..writeByte(7)
      ..write(obj.adsTriggered)
      ..writeByte(8)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
