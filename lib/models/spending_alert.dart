import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory SpendingAlert.fromJson(Map<String, dynamic> json, String id) {
    return SpendingAlert(
      id: id,
      walletId: json['walletId'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AlertType.fixedAmount, // Default if parsing fails
      ),
      threshold: (json['threshold'] as num).toDouble(),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      lastTriggered: json['lastTriggered'] != null
          ? (json['lastTriggered'] is Timestamp
              ? (json['lastTriggered'] as Timestamp).toDate()
              : DateTime.parse(json['lastTriggered'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // ID is the document ID
      'walletId': walletId,
      'type': type.toString(),
      'threshold': threshold,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }
} 