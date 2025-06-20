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
    );
  }

  @override
  void write(BinaryWriter writer, BudgetTemplate obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.createdAt);
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
