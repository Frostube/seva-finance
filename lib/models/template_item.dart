import 'package:hive/hive.dart';

part 'template_item.g.dart';

@HiveType(typeId: 13)
class TemplateItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String templateId;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final double defaultAmount;

  @HiveField(4)
  final int order;

  @HiveField(5)
  final DateTime createdAt;

  TemplateItem({
    required this.id,
    required this.templateId,
    required this.categoryId,
    required this.defaultAmount,
    required this.order,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TemplateItem.fromJson(Map<String, dynamic> json, String docId) {
    return TemplateItem(
      id: docId,
      templateId: json['templateId'] as String,
      categoryId: json['categoryId'] as String,
      defaultAmount: (json['defaultAmount'] as num).toDouble(),
      order: json['order'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'categoryId': categoryId,
      'defaultAmount': defaultAmount,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TemplateItem{id: $id, templateId: $templateId, categoryId: $categoryId, defaultAmount: $defaultAmount, order: $order}';
  }
}
 