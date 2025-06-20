// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryBudgetAdapter extends TypeAdapter<CategoryBudget> {
  @override
  final int typeId = 14;

  @override
  CategoryBudget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryBudget(
      id: fields[0] as String,
      walletId: fields[1] as String,
      categoryId: fields[2] as String,
      categoryName: fields[3] as String,
      budgetAmount: fields[4] as double,
      month: fields[5] as DateTime,
      createdAt: fields[6] as DateTime?,
      templateId: fields[7] as String?,
      alertsEnabled: fields[8] as bool,
      alertThreshold: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryBudget obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.walletId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.categoryName)
      ..writeByte(4)
      ..write(obj.budgetAmount)
      ..writeByte(5)
      ..write(obj.month)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.templateId)
      ..writeByte(8)
      ..write(obj.alertsEnabled)
      ..writeByte(9)
      ..write(obj.alertThreshold);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetStatusAdapter extends TypeAdapter<BudgetStatus> {
  @override
  final int typeId = 15;

  @override
  BudgetStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetStatus.underSpent;
      case 1:
        return BudgetStatus.onTrack;
      case 2:
        return BudgetStatus.warning;
      case 3:
        return BudgetStatus.overBudget;
      default:
        return BudgetStatus.underSpent;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetStatus obj) {
    switch (obj) {
      case BudgetStatus.underSpent:
        writer.writeByte(0);
        break;
      case BudgetStatus.onTrack:
        writer.writeByte(1);
        break;
      case BudgetStatus.warning:
        writer.writeByte(2);
        break;
      case BudgetStatus.overBudget:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
