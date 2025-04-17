import 'package:hive/hive.dart';

part 'spending_alert.g.dart';

@HiveType(typeId: 4)
enum AlertType {
  @HiveField(0)
  percentage,
  @HiveField(1)
  fixedAmount
}

@HiveType(typeId: 5)
class SpendingAlert extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String walletId;

  @HiveField(2)
  AlertType type;

  @HiveField(3)
  double threshold;

  @HiveField(4)
  bool notificationsEnabled;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? lastTriggered;

  SpendingAlert({
    required this.id,
    required this.walletId,
    required this.type,
    required this.threshold,
    this.notificationsEnabled = true,
    DateTime? createdAt,
    this.lastTriggered,
  }) : createdAt = createdAt ?? DateTime.now();

  bool shouldTrigger(double currentSpending, double budget) {
    if (lastTriggered?.month == DateTime.now().month) {
      return false; // Already triggered this month
    }

    double thresholdAmount = type == AlertType.percentage
        ? budget * (threshold / 100)
        : threshold;

    return currentSpending >= thresholdAmount;
  }

  String getDisplayThreshold() {
    return type == AlertType.percentage
        ? '${threshold.toStringAsFixed(0)}%'
        : '\$${threshold.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'type': type.toString(),
      'threshold': threshold,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }
} 