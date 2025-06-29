import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/insight.dart';
import '../models/analytics.dart';
import 'analytics_service.dart';
import 'expense_service.dart';
import 'category_budget_service.dart';

/// Enhanced insights service focused on actionable insights with meaningful baselines
/// Addresses the core issue: manual entry users don't need data regurgitation, they need actionable analysis
class InsightsService extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  final ExpenseService _expenseService;
  final CategoryBudgetService _categoryBudgetService;
  final Uuid _uuid = const Uuid();

  Box<Insight>? _insightsBox;
  List<Insight> _insights = [];
  bool _isLoading = false;

  InsightsService(
    this._analyticsService,
    this._expenseService,
    this._categoryBudgetService,
  );

  List<Insight> get insights => _insights;
  List<Insight> get unreadInsights =>
      _insights.where((i) => !i.isRead).toList();
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      _insightsBox = await Hive.openBox<Insight>('insights');
      await _loadInsights();
      await removeDuplicateInsights(); // Clean up on startup
    } catch (e) {
      debugPrint('Error initializing InsightsService: $e');
    }
  }

  Future<void> _loadInsights() async {
    if (_insightsBox == null) return;

    try {
      _insights = _insightsBox!.values.toList();
      _sortInsights();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading insights: $e');
    }
  }

  void _sortInsights() {
    _insights.sort((a, b) {
      // Sort by priority first, then by date
      final priorityComparison = _getPriorityValue(b.priority)
          .compareTo(_getPriorityValue(a.priority));
      if (priorityComparison != 0) return priorityComparison;
      return b.generatedAt.compareTo(a.generatedAt);
    });
  }

  int _getPriorityValue(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.critical:
        return 4;
      case InsightPriority.high:
        return 3;
      case InsightPriority.medium:
        return 2;
      case InsightPriority.low:
        return 1;
    }
  }

  Future<void> refreshInsights() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _analyticsService.refreshAnalytics();
      final analytics = _analyticsService.currentAnalytics;

      if (analytics != null) {
        await _generateActionableInsights(analytics);
      }
    } catch (e) {
      debugPrint('Error refreshing insights: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate insights that show both current and baseline with actionable next steps
  /// This addresses the core critique: show comparisons and provide clear actions
  Future<void> _generateActionableInsights(Analytics analytics) async {
    final newInsights = <Insight>[];

    // Generate insights that show both current and baseline with actionable next steps
    final balanceInsight = _generateBalanceForecastWithBaseline(analytics);
    if (balanceInsight != null) newInsights.add(balanceInsight);

    final spendingPaceInsight = _generateSpendingPaceComparison(analytics);
    if (spendingPaceInsight != null) newInsights.add(spendingPaceInsight);

    final topCategoryInsight = _generateTopCategoryWithAction(analytics);
    if (topCategoryInsight != null) newInsights.add(topCategoryInsight);

    final budgetSuggestionInsight = _generateBudgetSuggestion(analytics);
    if (budgetSuggestionInsight != null)
      newInsights.add(budgetSuggestionInsight);

    // Save new insights
    for (final insight in newInsights) {
      await _saveInsight(insight);
    }

    await _loadInsights();
    await removeDuplicateInsights();

    // Trigger notifications for high-priority insights
    _triggerNotificationsForHighPriorityInsights(newInsights);
  }

  /// Show both current and projected balance with clear comparison and next steps
  Insight? _generateBalanceForecastWithBaseline(Analytics analytics) {
    final forecastedBalance = _analyticsService.getForecastedBalance();
    final currentBalance = analytics.currentBalance;
    final difference = forecastedBalance - currentBalance;

    if (forecastedBalance == 0 || currentBalance == 0) return null;

    final percentChange = (difference / currentBalance * 100);

    // Show both current and projected with clear comparison
    String message;
    InsightPriority priority;

    if (difference < -100) {
      message =
          "Balance: \$${currentBalance.toStringAsFixed(2)} → \$${forecastedBalance.toStringAsFixed(2)} "
          "(${percentChange.toStringAsFixed(0)}% drop). Set spending alerts to avoid overdraft.";
      priority = InsightPriority.critical;
    } else if (difference < 0) {
      message =
          "Balance: \$${currentBalance.toStringAsFixed(2)} → \$${forecastedBalance.toStringAsFixed(2)} "
          "(${percentChange.toStringAsFixed(0)}% drop). Consider reducing discretionary spending.";
      priority = InsightPriority.medium;
    } else {
      message =
          "Balance: \$${currentBalance.toStringAsFixed(2)} → \$${forecastedBalance.toStringAsFixed(2)} "
          "(+${percentChange.toStringAsFixed(0)}%). You're on track for a positive month!";
      priority = InsightPriority.low;
    }

    return Insight(
      id: _uuid.v4(),
      userId: analytics.userId,
      type: InsightType.forecastBalance,
      text: message,
      value: forecastedBalance.toDouble(),
      generatedAt: DateTime.now(),
      priority: priority,
    );
  }

  /// Compare current daily spending with 30-day baseline - exactly what the user suggested
  Insight? _generateSpendingPaceComparison(Analytics analytics) {
    final currentDailyAvg = analytics.daysPassed > 0
        ? analytics.mtdTotal / analytics.daysPassed
        : 0;
    final baseline30DayAvg = analytics.avg30d;

    if (currentDailyAvg == 0 || baseline30DayAvg == 0) return null;

    final difference = currentDailyAvg - baseline30DayAvg;
    final percentDiff = (difference / baseline30DayAvg * 100);

    String message;
    InsightPriority priority;

    if (percentDiff > 25) {
      message =
          "Daily spending: \$${currentDailyAvg.toStringAsFixed(2)} ↑ vs \$${baseline30DayAvg.toStringAsFixed(2)} baseline "
          "(+${percentDiff.toStringAsFixed(0)}%). Review recent transactions to identify increases.";
      priority = InsightPriority.high;
    } else if (percentDiff < -15) {
      message =
          "Daily spending: \$${currentDailyAvg.toStringAsFixed(2)} ↓ vs \$${baseline30DayAvg.toStringAsFixed(2)} baseline "
          "(-${percentDiff.abs().toStringAsFixed(0)}%). Great job reducing expenses!";
      priority = InsightPriority.low;
    } else {
      message =
          "Daily spending: \$${currentDailyAvg.toStringAsFixed(2)} ≈ \$${baseline30DayAvg.toStringAsFixed(2)} baseline. "
          "Consistent with your normal spending pattern.";
      priority = InsightPriority.low;
    }

    return Insight(
      id: _uuid.v4(),
      userId: analytics.userId,
      type: InsightType.monthlyComparison,
      text: message,
      value: currentDailyAvg.toDouble(),
      generatedAt: DateTime.now(),
      priority: priority,
    );
  }

  /// Analyze top category with actionable suggestions instead of just stating the obvious
  Insight? _generateTopCategoryWithAction(Analytics analytics) {
    if (analytics.mtdByCategory.isEmpty) return null;

    // Find top spending category
    final topCategory = analytics.mtdByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    final categoryName = topCategory.key; // Use category ID directly for now
    final categoryPercent = (topCategory.value / analytics.mtdTotal * 100);

    // Compare with last period if available
    final lastPeriodAmount =
        analytics.lastPeriodByCategory[topCategory.key] ?? 0;

    String message;
    InsightPriority priority;

    if (lastPeriodAmount > 0) {
      final change = topCategory.value - lastPeriodAmount;
      final changePercent = (change / lastPeriodAmount * 100);

      if (changePercent > 30) {
        message =
            "$categoryName: \$${topCategory.value.toStringAsFixed(2)} ↑ vs \$${lastPeriodAmount.toStringAsFixed(2)} last period "
            "(+${changePercent.toStringAsFixed(0)}%). Set a category budget to track this.";
        priority = InsightPriority.medium;
      } else {
        message =
            "$categoryName: \$${topCategory.value.toStringAsFixed(2)} (${categoryPercent.toStringAsFixed(0)}% of spending). "
            "Similar to last period - spending is consistent.";
        priority = InsightPriority.low;
      }
    } else {
      message =
          "$categoryName: \$${topCategory.value.toStringAsFixed(2)} (${categoryPercent.toStringAsFixed(0)}% of spending). "
          "Consider setting a budget for your top spending category.";
      priority = InsightPriority.medium;
    }

    return Insight(
      id: _uuid.v4(),
      userId: analytics.userId,
      type: InsightType.categoryTrend,
      text: message,
      value: topCategory.value,
      generatedAt: DateTime.now(),
      priority: priority,
      categoryId: topCategory.key,
    );
  }

  /// Suggest actionable budget creation instead of just showing projections
  Insight? _generateBudgetSuggestion(Analytics analytics) {
    final dailyAvg = analytics.daysPassed > 0
        ? analytics.mtdTotal / analytics.daysPassed
        : 0;
    final monthlyProjection = dailyAvg * 30;

    if (monthlyProjection < 100) return null; // Skip for very low spending

    // Check if user has any budgets set
    final hasBudgets = _categoryBudgetService.categoryBudgets.isNotEmpty;

    String message;
    if (hasBudgets) {
      message =
          "Monthly projection: \$${monthlyProjection.toStringAsFixed(2)} based on current pace. "
          "Review your category budgets to stay on track.";
    } else {
      message =
          "Monthly projection: \$${monthlyProjection.toStringAsFixed(2)} based on \$${dailyAvg.toStringAsFixed(2)}/day pace. "
          "Create category budgets to better control spending.";
    }

    return Insight(
      id: _uuid.v4(),
      userId: analytics.userId,
      type: InsightType.budgetAlert,
      text: message,
      value: monthlyProjection.toDouble(),
      generatedAt: DateTime.now(),
      priority: InsightPriority.medium,
    );
  }

  Future<void> _saveInsight(Insight insight) async {
    if (_insightsBox == null) return;

    try {
      await _insightsBox!.put(insight.id, insight);
    } catch (e) {
      debugPrint('Error saving insight: $e');
    }
  }

  Future<void> markInsightAsRead(String insightId) async {
    try {
      final insight = _insights.firstWhere((i) => i.id == insightId);
      final updatedInsight = insight.copyWith(isRead: true);

      // Update locally first
      final index = _insights.indexWhere((i) => i.id == insightId);
      if (index != -1) {
        _insights[index] = updatedInsight;
        notifyListeners();
      }

      // Update in Hive
      await _insightsBox?.put(insightId, updatedInsight);
    } catch (e) {
      debugPrint('Error marking insight as read: $e');
    }
  }

  Future<void> dismissInsight(String insightId) async {
    try {
      await _insightsBox?.delete(insightId);
      _insights.removeWhere((i) => i.id == insightId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error dismissing insight: $e');
    }
  }

  Future<void> deleteInsight(String insightId) async {
    // Alias for dismissInsight to maintain compatibility
    await dismissInsight(insightId);
  }

  Future<void> removeDuplicateInsights() async {
    if (_insights.isEmpty) return;

    final uniqueInsights = <Insight>[];
    final seen = <String>{};

    for (final insight in _insights) {
      final key = _generateInsightKey(insight);
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueInsights.add(insight);
      } else {
        // Remove duplicate from storage
        await _insightsBox?.delete(insight.id);
      }
    }

    if (uniqueInsights.length != _insights.length) {
      _insights = uniqueInsights;
      notifyListeners();
      debugPrint(
          'Removed ${_insights.length - uniqueInsights.length} duplicate insights');
    }
  }

  String _generateInsightKey(Insight insight) {
    // Create a key that identifies similar insights
    final dateKey =
        '${insight.generatedAt.year}-${insight.generatedAt.month}-${insight.generatedAt.day}';
    return '${insight.type.toString()}_${dateKey}_${insight.text.substring(0, 20)}';
  }

  Future<void> forceDuplicateCleanup() async {
    await removeDuplicateInsights();
  }

  Future<void> clearAllInsights() async {
    try {
      await _insightsBox?.clear();
      _insights.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing insights: $e');
      rethrow;
    }
  }

  List<Insight> getInsightsByType(InsightType type) {
    return _insights.where((insight) => insight.type == type).toList();
  }

  List<Insight> getInsightsByPriority(InsightPriority priority) {
    return _insights.where((insight) => insight.priority == priority).toList();
  }

  /// Trigger notifications for high-priority insights
  void _triggerNotificationsForHighPriorityInsights(List<Insight> insights) {
    // This is a simple approach - in a real app you'd inject the notification service
    // For now, we'll just print the insights that would trigger notifications
    final highPriorityInsights = insights
        .where((insight) =>
            insight.priority == InsightPriority.critical ||
            insight.priority == InsightPriority.high)
        .toList();

    for (final insight in highPriorityInsights) {
      debugPrint('High priority insight generated: ${insight.text}');
      // The InsightNotificationService listener will pick this up automatically
    }
  }

  void dispose() {
    _insightsBox?.close();
    super.dispose();
  }
}
