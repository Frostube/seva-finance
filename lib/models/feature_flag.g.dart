// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeatureFlagAdapter extends TypeAdapter<FeatureFlag> {
  @override
  final int typeId = 21;

  @override
  FeatureFlag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeatureFlag(
      key: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      proOnly: fields[3] as bool,
      freeLimit: fields[4] as int?,
      resetPeriod: fields[5] as String?,
      isEnabled: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FeatureFlag obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.proOnly)
      ..writeByte(4)
      ..write(obj.freeLimit)
      ..writeByte(5)
      ..write(obj.resetPeriod)
      ..writeByte(6)
      ..write(obj.isEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureFlagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
