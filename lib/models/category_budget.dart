import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'category_budget.g.dart';

@HiveType(typeId: 14)
class CategoryBudget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String walletId;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final String categoryName;

  @HiveField(4)
  final double budgetAmount;

  @HiveField(5)
  final DateTime month; // Which month this budget is for

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String? templateId; // Which template this came from (if any)

  @HiveField(8)
  final bool alertsEnabled; // Whether to show alerts for this category

  @HiveField(9)
  final double
      alertThreshold; // Alert when spending reaches this % (default 80%)

  CategoryBudget({
    required this.id,
    required this.walletId,
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.month,
    DateTime? createdAt,
    this.templateId,
    this.alertsEnabled = true,
    this.alertThreshold = 0.8, // 80% default
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate spending progress as a percentage (0.0 to 1.0+)
  double getSpendingProgress(double currentSpending) {
    if (budgetAmount <= 0) return 0.0;
    return currentSpending / budgetAmount;
  }

  /// Get remaining budget amount
  double getRemainingBudget(double currentSpending) {
    return budgetAmount - currentSpending;
  }

  /// Check if this category is over budget
  bool isOverBudget(double currentSpending) {
    return currentSpending > budgetAmount;
  }

  /// Check if this category should trigger an alert
  bool shouldTriggerAlert(double currentSpending) {
    if (!alertsEnabled) return false;
    return currentSpending >= (budgetAmount * alertThreshold);
  }

  /// Get a color indicating budget status
  BudgetStatus getBudgetStatus(double currentSpending) {
    final progress = getSpendingProgress(currentSpending);

    if (progress >= 1.0) return BudgetStatus.overBudget;
    if (progress >= alertThreshold) return BudgetStatus.warning;
    if (progress >= 0.5) return BudgetStatus.onTrack;
    return BudgetStatus.underSpent;
  }

  /// Get display text for remaining budget
  String getRemainingBudgetText(double currentSpending) {
    final remaining = getRemainingBudget(currentSpending);
    if (remaining > 0) {
      return '\$${remaining.toStringAsFixed(0)} left';
    } else {
      return '\$${(-remaining).toStringAsFixed(0)} over budget';
    }
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json, String docId) {
    return CategoryBudget(
      id: docId,
      walletId: json['walletId'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      month: json['month'] is Timestamp
          ? (json['month'] as Timestamp).toDate()
          : DateTime.parse(json['month'] as String),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      templateId: json['templateId'] as String?,
      alertsEnabled: json['alertsEnabled'] as bool? ?? true,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletId': walletId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'budgetAmount': budgetAmount,
      'month': month.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'templateId': templateId,
      'alertsEnabled': alertsEnabled,
      'alertThreshold': alertThreshold,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudget &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CategoryBudget{id: $id, categoryName: $categoryName, budgetAmount: $budgetAmount, month: $month}';
  }
}

@HiveType(typeId: 15)
enum BudgetStatus {
  @HiveField(0)
  underSpent, // < 50% spent
  @HiveField(1)
  onTrack, // 50-80% spent
  @HiveField(2)
  warning, // 80-100% spent
  @HiveField(3)
  overBudget, // > 100% spent
}
