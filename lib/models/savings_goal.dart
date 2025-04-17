import 'package:hive/hive.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 3)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String walletId;

  @HiveField(2)
  String? name;

  @HiveField(3)
  double targetAmount;

  @HiveField(4)
  DateTime targetDate;

  @HiveField(5)
  DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.walletId,
    this.name,
    required this.targetAmount,
    required this.targetDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double getProgress(double currentBalance) {
    return (currentBalance / targetAmount).clamp(0.0, 1.0);
  }

  bool isCompleted(double currentBalance) {
    return currentBalance >= targetAmount;
  }

  bool isExpired() {
    return DateTime.now().isAfter(targetDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'name': name,
      'targetAmount': targetAmount,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 