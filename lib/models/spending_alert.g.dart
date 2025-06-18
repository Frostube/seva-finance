// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spending_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpendingAlertAdapter extends TypeAdapter<SpendingAlert> {
  @override
  final int typeId = 5;

  @override
  SpendingAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpendingAlert(
      id: fields[0] as String,
      walletId: fields[1] as String,
      type: fields[2] as AlertType,
      threshold: fields[3] as double,
      notificationsEnabled: fields[4] as bool,
      createdAt: fields[5] as DateTime?,
      lastTriggered: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SpendingAlert obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.walletId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.threshold)
      ..writeByte(4)
      ..write(obj.notificationsEnabled)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastTriggered);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlertTypeAdapter extends TypeAdapter<AlertType> {
  @override
  final int typeId = 4;

  @override
  AlertType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlertType.percentage;
      case 1:
        return AlertType.fixedAmount;
      default:
        return AlertType.percentage;
    }
  }

  @override
  void write(BinaryWriter writer, AlertType obj) {
    switch (obj) {
      case AlertType.percentage:
        writer.writeByte(0);
        break;
      case AlertType.fixedAmount:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
