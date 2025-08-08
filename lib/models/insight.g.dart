// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InsightAdapter extends TypeAdapter<Insight> {
  @override
  final int typeId = 21;

  @override
  Insight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Insight(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as InsightType,
      text: fields[3] as String,
      value: fields[4] as double?,
      generatedAt: fields[5] as DateTime,
      categoryId: fields[6] as String?,
      priority: fields[7] as InsightPriority,
      isRead: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Insight obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.text)
      ..writeByte(4)
      ..write(obj.value)
      ..writeByte(5)
      ..write(obj.generatedAt)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InsightTypeAdapter extends TypeAdapter<InsightType> {
  @override
  final int typeId = 22;

  @override
  InsightType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InsightType.overspend;
      case 1:
        return InsightType.forecastBalance;
      case 2:
        return InsightType.categoryTrend;
      case 3:
        return InsightType.budgetAlert;
      case 4:
        return InsightType.savingOpportunity;
      case 5:
        return InsightType.unusualSpending;
      case 6:
        return InsightType.monthlyComparison;
      case 7:
        return InsightType.general;
      case 8:
        return InsightType.largeExpense;
      default:
        return InsightType.overspend;
    }
  }

  @override
  void write(BinaryWriter writer, InsightType obj) {
    switch (obj) {
      case InsightType.overspend:
        writer.writeByte(0);
        break;
      case InsightType.forecastBalance:
        writer.writeByte(1);
        break;
      case InsightType.categoryTrend:
        writer.writeByte(2);
        break;
      case InsightType.budgetAlert:
        writer.writeByte(3);
        break;
      case InsightType.savingOpportunity:
        writer.writeByte(4);
        break;
      case InsightType.unusualSpending:
        writer.writeByte(5);
        break;
      case InsightType.monthlyComparison:
        writer.writeByte(6);
        break;
      case InsightType.general:
        writer.writeByte(7);
        break;
      case InsightType.largeExpense:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InsightPriorityAdapter extends TypeAdapter<InsightPriority> {
  @override
  final int typeId = 23;

  @override
  InsightPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InsightPriority.low;
      case 1:
        return InsightPriority.medium;
      case 2:
        return InsightPriority.high;
      case 3:
        return InsightPriority.critical;
      default:
        return InsightPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, InsightPriority obj) {
    switch (obj) {
      case InsightPriority.low:
        writer.writeByte(0);
        break;
      case InsightPriority.medium:
        writer.writeByte(1);
        break;
      case InsightPriority.high:
        writer.writeByte(2);
        break;
      case InsightPriority.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
