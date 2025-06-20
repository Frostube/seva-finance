import 'package:hive/hive.dart';

part 'budget_template.g.dart';

@HiveType(typeId: 16)
enum BudgetTimeline {
  @HiveField(0)
  monthly,
  @HiveField(1)
  yearly,
  @HiveField(2)
  undefined,
}

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

  @HiveField(6)
  final BudgetTimeline timeline;

  @HiveField(7)
  final DateTime? endDate;

  BudgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    this.createdBy,
    DateTime? createdAt,
    this.timeline = BudgetTimeline.monthly,
    this.endDate,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if this template is still active (not expired)
  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  /// Get display text for timeline
  String get timelineDisplayText {
    switch (timeline) {
      case BudgetTimeline.monthly:
        return 'Monthly';
      case BudgetTimeline.yearly:
        return 'Yearly';
      case BudgetTimeline.undefined:
        return 'One-time';
    }
  }

  /// Get display text for end date
  String? get endDateDisplayText {
    if (endDate == null) return null;
    return '${endDate!.day}/${endDate!.month}/${endDate!.year}';
  }

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
      timeline: json['timeline'] != null
          ? BudgetTimeline.values[json['timeline'] as int]
          : BudgetTimeline.monthly,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'isSystem': isSystem,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'timeline': timeline.index,
      'endDate': endDate?.toIso8601String(),
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
    return 'BudgetTemplate{id: $id, name: $name, description: $description, isSystem: $isSystem, timeline: $timeline, endDate: $endDate}';
  }
}
 