import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final String? walletId;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.walletId,
  });

  // Create from JSON (for database operations)
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: json['amount'] as double,
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      walletId: json['walletId'] as String?,
    );
  }

  // Convert to JSON (for database operations)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'walletId': walletId,
    };
  }
} 