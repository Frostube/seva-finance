import 'package:hive/hive.dart';

part 'analytics.g.dart';

@HiveType(typeId: 20) // Using unique typeId
class Analytics extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final double mtdTotal; // Month-to-date total spending

  @HiveField(2)
  final Map<String, double> mtdByCategory; // Month-to-date spending by category

  @HiveField(3)
  final double avg7d; // 7-day rolling average

  @HiveField(4)
  final double avg30d; // 30-day rolling average

  @HiveField(5)
  final Map<String, double> lastPeriodByCategory; // Previous period by category

  @HiveField(6)
  final DateTime lastUpdated;

  @HiveField(7)
  final double currentBalance; // Current wallet balance

  @HiveField(8)
  final int daysInMonth; // Days in current month

  @HiveField(9)
  final int daysPassed; // Days passed in current month

  Analytics({
    required this.userId,
    required this.mtdTotal,
    required this.mtdByCategory,
    required this.avg7d,
    required this.avg30d,
    required this.lastPeriodByCategory,
    required this.lastUpdated,
    required this.currentBalance,
    required this.daysInMonth,
    required this.daysPassed,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      userId: json['userId'] as String,
      mtdTotal: (json['mtdTotal'] as num).toDouble(),
      mtdByCategory: Map<String, double>.from(json['mtdByCategory'] ?? {}),
      avg7d: (json['avg7d'] as num).toDouble(),
      avg30d: (json['avg30d'] as num).toDouble(),
      lastPeriodByCategory:
          Map<String, double>.from(json['lastPeriodByCategory'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      daysInMonth: json['daysInMonth'] as int,
      daysPassed: json['daysPassed'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mtdTotal': mtdTotal,
      'mtdByCategory': mtdByCategory,
      'avg7d': avg7d,
      'avg30d': avg30d,
      'lastPeriodByCategory': lastPeriodByCategory,
      'lastUpdated': lastUpdated.toIso8601String(),
      'currentBalance': currentBalance,
      'daysInMonth': daysInMonth,
      'daysPassed': daysPassed,
    };
  }

  Analytics copyWith({
    String? userId,
    double? mtdTotal,
    Map<String, double>? mtdByCategory,
    double? avg7d,
    double? avg30d,
    Map<String, double>? lastPeriodByCategory,
    DateTime? lastUpdated,
    double? currentBalance,
    int? daysInMonth,
    int? daysPassed,
  }) {
    return Analytics(
      userId: userId ?? this.userId,
      mtdTotal: mtdTotal ?? this.mtdTotal,
      mtdByCategory: mtdByCategory ?? this.mtdByCategory,
      avg7d: avg7d ?? this.avg7d,
      avg30d: avg30d ?? this.avg30d,
      lastPeriodByCategory: lastPeriodByCategory ?? this.lastPeriodByCategory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentBalance: currentBalance ?? this.currentBalance,
      daysInMonth: daysInMonth ?? this.daysInMonth,
      daysPassed: daysPassed ?? this.daysPassed,
    );
  }
}
