// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnalyticsAdapter extends TypeAdapter<Analytics> {
  @override
  final int typeId = 20;

  @override
  Analytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Analytics(
      userId: fields[0] as String,
      mtdTotal: fields[1] as double,
      mtdByCategory: (fields[2] as Map).cast<String, double>(),
      avg7d: fields[3] as double,
      avg30d: fields[4] as double,
      lastPeriodByCategory: (fields[5] as Map).cast<String, double>(),
      lastUpdated: fields[6] as DateTime,
      currentBalance: fields[7] as double,
      daysInMonth: fields[8] as int,
      daysPassed: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Analytics obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.mtdTotal)
      ..writeByte(2)
      ..write(obj.mtdByCategory)
      ..writeByte(3)
      ..write(obj.avg7d)
      ..writeByte(4)
      ..write(obj.avg30d)
      ..writeByte(5)
      ..write(obj.lastPeriodByCategory)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.currentBalance)
      ..writeByte(8)
      ..write(obj.daysInMonth)
      ..writeByte(9)
      ..write(obj.daysPassed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
