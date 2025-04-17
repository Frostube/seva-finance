import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? note;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  // Create from JSON (for database operations)
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: json['amount'] as double,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  // Convert to JSON (for database operations)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
} 