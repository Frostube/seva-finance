import 'package:hive/hive.dart';

part 'feature_flag.g.dart';

@HiveType(typeId: 21)
class FeatureFlag extends HiveObject {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool proOnly;

  @HiveField(4)
  final int? freeLimit;

  @HiveField(5)
  final String? resetPeriod; // 'monthly', 'weekly', 'daily', null (no reset)

  @HiveField(6)
  final bool isEnabled;

  FeatureFlag({
    required this.key,
    required this.name,
    required this.description,
    this.proOnly = false,
    this.freeLimit,
    this.resetPeriod,
    this.isEnabled = true,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'name': name,
      'description': description,
      'proOnly': proOnly,
      'freeLimit': freeLimit,
      'resetPeriod': resetPeriod,
      'isEnabled': isEnabled,
    };
  }

  // Create from Firestore Map
  factory FeatureFlag.fromMap(Map<String, dynamic> map) {
    return FeatureFlag(
      key: map['key'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      proOnly: map['proOnly'] ?? false,
      freeLimit: map['freeLimit'],
      resetPeriod: map['resetPeriod'],
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  @override
  String toString() {
    return 'FeatureFlag(key: $key, proOnly: $proOnly, freeLimit: $freeLimit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeatureFlag && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

// Predefined feature flags
class FeatureFlags {
  static const String receiptScan = 'receipt_scan';
  static const String aiInsights = 'ai_insights';
  static const String advancedAnalytics = 'advanced_analytics';
  static const String csvExport = 'csv_export';
  static const String budgetTemplates = 'budget_templates';
  static const String recurringTransactions = 'recurring_transactions';
  static const String savingsGoals = 'savings_goals';
  static const String spendingAlerts = 'spending_alerts';
  static const String emailNotifications = 'email_notifications';
  static const String dataBackup = 'data_backup';

  static List<FeatureFlag> getDefaultFeatureFlags() {
    return [
      FeatureFlag(
        key: receiptScan,
        name: 'Receipt Scanning',
        description: 'Scan receipts using OCR technology',
        proOnly: false,
        freeLimit: 3,
        resetPeriod: 'monthly',
      ),
      FeatureFlag(
        key: aiInsights,
        name: 'AI Insights',
        description: 'Get personalized financial insights powered by AI',
        proOnly: true,
      ),
      FeatureFlag(
        key: advancedAnalytics,
        name: 'Advanced Analytics',
        description: 'Detailed spending analysis and reports',
        proOnly: true,
      ),
      FeatureFlag(
        key: csvExport,
        name: 'CSV Export',
        description: 'Export your data to CSV format',
        proOnly: false,
        freeLimit: 1,
        resetPeriod: 'monthly',
      ),
      FeatureFlag(
        key: budgetTemplates,
        name: 'Budget Templates',
        description: 'Create and use custom budget templates',
        proOnly: true,
      ),
      FeatureFlag(
        key: recurringTransactions,
        name: 'Recurring Transactions',
        description: 'Set up automatic recurring transactions',
        proOnly: true,
      ),
      FeatureFlag(
        key: savingsGoals,
        name: 'Savings Goals',
        description: 'Set and track multiple savings goals',
        proOnly: false,
        freeLimit: 2,
        resetPeriod: null,
      ),
      FeatureFlag(
        key: spendingAlerts,
        name: 'Spending Alerts',
        description: 'Get notified when you exceed budget limits',
        proOnly: true,
      ),
      FeatureFlag(
        key: emailNotifications,
        name: 'Email Notifications',
        description: 'Receive notifications via email',
        proOnly: true,
      ),
      FeatureFlag(
        key: dataBackup,
        name: 'Data Backup',
        description: 'Automatic cloud backup of your data',
        proOnly: true,
      ),
    ];
  }
}
