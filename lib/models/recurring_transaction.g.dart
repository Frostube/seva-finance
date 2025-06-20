// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionAdapter extends TypeAdapter<RecurringTransaction> {
  @override
  final int typeId = 17;

  @override
  RecurringTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransaction(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      categoryId: fields[3] as String,
      isExpense: fields[4] as bool,
      frequency: fields[5] as String,
      interval: fields[6] as int,
      dayOfMonth: fields[7] as int?,
      dayOfWeek: fields[8] as String?,
      startDate: fields[9] as DateTime,
      endDate: fields[10] as DateTime?,
      nextOccurrence: fields[11] as DateTime,
      createdBy: fields[12] as String,
      createdAt: fields[13] as DateTime,
      isActive: fields[14] as bool,
      walletId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransaction obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.isExpense)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.interval)
      ..writeByte(7)
      ..write(obj.dayOfMonth)
      ..writeByte(8)
      ..write(obj.dayOfWeek)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(11)
      ..write(obj.nextOccurrence)
      ..writeByte(12)
      ..write(obj.createdBy)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.walletId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
