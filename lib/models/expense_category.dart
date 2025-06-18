import 'package:hive/hive.dart';

part 'expense_category.g.dart';

@HiveType(typeId: 2)
class ExpenseCategory {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String icon;
  
  @HiveField(3)
  final DateTime createdAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 