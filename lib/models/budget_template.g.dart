// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetTemplateAdapter extends TypeAdapter<BudgetTemplate> {
  @override
  final int typeId = 12;

  @override
  BudgetTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      isSystem: fields[3] as bool,
      createdBy: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      timeline: fields[6] as BudgetTimeline,
      endDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isSystem)
      ..writeByte(4)
      ..write(obj.createdBy)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.timeline)
      ..writeByte(7)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetTimelineAdapter extends TypeAdapter<BudgetTimeline> {
  @override
  final int typeId = 16;

  @override
  BudgetTimeline read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetTimeline.monthly;
      case 1:
        return BudgetTimeline.yearly;
      case 2:
        return BudgetTimeline.undefined;
      default:
        return BudgetTimeline.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetTimeline obj) {
    switch (obj) {
      case BudgetTimeline.monthly:
        writer.writeByte(0);
        break;
      case BudgetTimeline.yearly:
        writer.writeByte(1);
        break;
      case BudgetTimeline.undefined:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetTimelineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
