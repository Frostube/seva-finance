import 'package:hive/hive.dart';

part 'insight.g.dart';

@HiveType(typeId: 21) // Using unique typeId
class Insight extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final InsightType type;

  @HiveField(3)
  final String text; // Human-readable insight text

  @HiveField(4)
  final double? value; // Optional numeric highlight

  @HiveField(5)
  final DateTime generatedAt;

  @HiveField(6)
  final String? categoryId; // Related category if applicable

  @HiveField(7)
  final InsightPriority priority;

  @HiveField(8)
  final bool isRead;

  Insight({
    required this.id,
    required this.userId,
    required this.type,
    required this.text,
    this.value,
    required this.generatedAt,
    this.categoryId,
    this.priority = InsightPriority.medium,
    this.isRead = false,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: InsightType.values.firstWhere(
        (e) => e.toString() == 'InsightType.${json['type']}',
        orElse: () => InsightType.general,
      ),
      text: json['text'] as String,
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      categoryId: json['categoryId'] as String?,
      priority: InsightPriority.values.firstWhere(
        (e) => e.toString() == 'InsightPriority.${json['priority']}',
        orElse: () => InsightPriority.medium,
      ),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'text': text,
      'value': value,
      'generatedAt': generatedAt.toIso8601String(),
      'categoryId': categoryId,
      'priority': priority.toString().split('.').last,
      'isRead': isRead,
    };
  }

  Insight copyWith({
    String? id,
    String? userId,
    InsightType? type,
    String? text,
    double? value,
    DateTime? generatedAt,
    String? categoryId,
    InsightPriority? priority,
    bool? isRead,
  }) {
    return Insight(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      text: text ?? this.text,
      value: value ?? this.value,
      generatedAt: generatedAt ?? this.generatedAt,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
    );
  }
}

@HiveType(typeId: 22)
enum InsightType {
  @HiveField(0)
  overspend,

  @HiveField(1)
  forecastBalance,

  @HiveField(2)
  categoryTrend,

  @HiveField(3)
  budgetAlert,

  @HiveField(4)
  savingOpportunity,

  @HiveField(5)
  unusualSpending,

  @HiveField(6)
  monthlyComparison,

  @HiveField(7)
  general,
}

@HiveType(typeId: 23)
enum InsightPriority {
  @HiveField(0)
  low,

  @HiveField(1)
  medium,

  @HiveField(2)
  high,

  @HiveField(3)
  critical,
}
