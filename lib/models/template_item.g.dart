// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemplateItemAdapter extends TypeAdapter<TemplateItem> {
  @override
  final int typeId = 13;

  @override
  TemplateItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateItem(
      id: fields[0] as String,
      templateId: fields[1] as String,
      categoryId: fields[2] as String,
      defaultAmount: fields[3] as double,
      order: fields[4] as int,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.defaultAmount)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
