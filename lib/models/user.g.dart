// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 20;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      username: fields[3] as String?,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      trialStart: fields[6] as DateTime?,
      isPro: fields[7] as bool,
      hasPaid: fields[8] as bool,
      scanCountThisMonth: fields[9] as int,
      stripeCustomerId: fields[10] as String?,
      stripeSubscriptionId: fields[11] as String?,
      subscriptionStart: fields[12] as DateTime?,
      subscriptionEnd: fields[13] as DateTime?,
      subscriptionStatus: fields[14] as String?,
      phone: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.trialStart)
      ..writeByte(7)
      ..write(obj.isPro)
      ..writeByte(8)
      ..write(obj.hasPaid)
      ..writeByte(9)
      ..write(obj.scanCountThisMonth)
      ..writeByte(10)
      ..write(obj.stripeCustomerId)
      ..writeByte(11)
      ..write(obj.stripeSubscriptionId)
      ..writeByte(12)
      ..write(obj.subscriptionStart)
      ..writeByte(13)
      ..write(obj.subscriptionEnd)
      ..writeByte(14)
      ..write(obj.subscriptionStatus)
      ..writeByte(15)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
