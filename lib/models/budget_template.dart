import 'package:hive/hive.dart';

part 'budget_template.g.dart';

@HiveType(typeId: 12)
class BudgetTemplate {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isSystem;

  @HiveField(4)
  final String? createdBy;

  @HiveField(5)
  final DateTime createdAt;

  BudgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BudgetTemplate.fromJson(Map<String, dynamic> json, String docId) {
    return BudgetTemplate(
      id: docId,
      name: json['name'] as String,
      description: json['description'] as String,
      isSystem: json['isSystem'] as bool,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'isSystem': isSystem,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BudgetTemplate{id: $id, name: $name, description: $description, isSystem: $isSystem}';
  }
}
