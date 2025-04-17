class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
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
      'id': id,
      'name': name,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 