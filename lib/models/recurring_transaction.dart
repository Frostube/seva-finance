import 'package:hive/hive.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 17)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  bool isExpense;

  @HiveField(5)
  String frequency; // 'daily'|'weekly'|'monthly'|'yearly'|'custom'

  @HiveField(6)
  int interval; // e.g. 1 (every), 2 (every 2 weeks)

  @HiveField(7)
  int? dayOfMonth; // for monthly (1-31)

  @HiveField(8)
  String? dayOfWeek; // for weekly ('Monday', 'Tuesday', etc.)

  @HiveField(9)
  DateTime startDate;

  @HiveField(10)
  DateTime? endDate;

  @HiveField(11)
  DateTime nextOccurrence;

  @HiveField(12)
  String createdBy; // userId

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  bool isActive; // for pause/resume functionality

  @HiveField(15)
  String? walletId; // which wallet this recurring transaction belongs to

  RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.isExpense,
    required this.frequency,
    this.interval = 1,
    this.dayOfMonth,
    this.dayOfWeek,
    required this.startDate,
    this.endDate,
    required this.nextOccurrence,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
    this.walletId,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      isExpense: json['isExpense'] as bool,
      frequency: json['frequency'] as String,
      interval: json['interval'] as int? ?? 1,
      dayOfMonth: json['dayOfMonth'] as int?,
      dayOfWeek: json['dayOfWeek'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      nextOccurrence: DateTime.parse(json['nextOccurrence'] as String),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      walletId: json['walletId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'isExpense': isExpense,
      'frequency': frequency,
      'interval': interval,
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextOccurrence': nextOccurrence.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'walletId': walletId,
    };
  }

  // Helper method to calculate next occurrence based on frequency
  DateTime calculateNextOccurrence() {
    switch (frequency) {
      case 'daily':
        return nextOccurrence.add(Duration(days: interval));
      case 'weekly':
        return nextOccurrence.add(Duration(days: 7 * interval));
      case 'monthly':
        return DateTime(
          nextOccurrence.year,
          nextOccurrence.month + interval,
          dayOfMonth ?? nextOccurrence.day,
        );
      case 'yearly':
        return DateTime(
          nextOccurrence.year + interval,
          nextOccurrence.month,
          nextOccurrence.day,
        );
      default:
        return nextOccurrence.add(Duration(days: interval));
    }
  }

  // Helper method to get frequency display text
  String get frequencyDisplayText {
    switch (frequency) {
      case 'daily':
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case 'weekly':
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case 'monthly':
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case 'yearly':
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      default:
        return 'Custom';
    }
  }

  // Helper method to check if this recurring transaction is due
  bool isDue() {
    final now = DateTime.now();
    return isActive &&
        nextOccurrence.isBefore(now) &&
        (endDate == null || endDate!.isAfter(now));
  }

  RecurringTransaction copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    bool? isExpense,
    String? frequency,
    int? interval,
    int? dayOfMonth,
    String? dayOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextOccurrence,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
    String? walletId,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      isExpense: isExpense ?? this.isExpense,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      walletId: walletId ?? this.walletId,
    );
  }
}
