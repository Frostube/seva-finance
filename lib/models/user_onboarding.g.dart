// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_onboarding.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserOnboardingAdapter extends TypeAdapter<UserOnboarding> {
  @override
  final int typeId = 11;

  @override
  UserOnboarding read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserOnboarding(
      onboardingCompleted: fields[0] as bool? ?? false,
      onboardingStartedAt: fields[1] as DateTime?,
      onboardingCompletedAt: fields[2] as DateTime?,
      currentStep: fields[3] as int? ?? 0,
      completedSteps: (fields[4] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, UserOnboarding obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.onboardingCompleted)
      ..writeByte(1)
      ..write(obj.onboardingStartedAt)
      ..writeByte(2)
      ..write(obj.onboardingCompletedAt)
      ..writeByte(3)
      ..write(obj.currentStep)
      ..writeByte(4)
      ..write(obj.completedSteps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserOnboardingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
