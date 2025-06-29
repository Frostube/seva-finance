import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/analytics.dart';
import 'analytics_service.dart';
import 'expense_service.dart';
import 'category_budget_service.dart';

enum CoachTipType {
  budgetAlert,
  savingOpportunity,
  spendingPattern,
  budgetRebalance,
  goalProgress,
  general,
}

enum CoachTipPriority {
  critical,
  high,
  medium,
  low,
}

class CoachTip {
  final String id;
  final String userId;
  final CoachTipType type;
  final CoachTipPriority priority;
  final String title;
  final String message;
  final String? actionText;
  final String? actionUrl;
  final String? value;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  CoachTip({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.actionText,
    this.actionUrl,
    this.value,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'title': title,
        'message': message,
        'actionText': actionText,
        'actionUrl': actionUrl,
        'value': value,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'isDismissed': isDismissed,
      };

  factory CoachTip.fromJson(Map<String, dynamic> json) => CoachTip(
        id: json['id'],
        userId: json['userId'],
        type: CoachTipType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => CoachTipType.general,
        ),
        priority: CoachTipPriority.values.firstWhere(
          (e) => e.toString().split('.').last == json['priority'],
          orElse: () => CoachTipPriority.low,
        ),
        title: json['title'],
        message: json['message'],
        actionText: json['actionText'],
        actionUrl: json['actionUrl'],
        value: json['value'],
        createdAt: DateTime.parse(json['createdAt']),
        isRead: json['isRead'] ?? false,
        isDismissed: json['isDismissed'] ?? false,
      );

  CoachTip copyWith({
    bool? isRead,
    bool? isDismissed,
  }) =>
      CoachTip(
        id: id,
        userId: userId,
        type: type,
        priority: priority,
        title: title,
        message: message,
        actionText: actionText,
        actionUrl: actionUrl,
        value: value,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        isDismissed: isDismissed ?? this.isDismissed,
      );
}

class CoachService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AnalyticsService _analyticsService;
  final ExpenseService _expenseService;
  final CategoryBudgetService _categoryBudgetService;
  final Uuid _uuid = const Uuid();

  List<CoachTip> _tips = [];
  bool _isLoading = false;
  DateTime? _lastGenerationTime;

  CoachService(
    this._firestore,
    this._auth,
    this._analyticsService,
    this._expenseService,
    this._categoryBudgetService,
  );

  List<CoachTip> get tips => _tips.where((tip) => !tip.isDismissed).toList();
  List<CoachTip> get unreadTips => tips.where((tip) => !tip.isRead).toList();
  bool get isLoading => _isLoading;

  Future<void> loadCoachTips() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('CoachService: Cannot load tips - no authenticated user');
      return;
    }

    try {
      debugPrint('CoachService: Loading tips for user ${user.uid}');

      QuerySnapshot snapshot;
      try {
        // Try the optimized query with composite index first
        snapshot = await _firestore
            .collection('coach_tips')
            .doc(user.uid)
            .collection('tips')
            .where('isDismissed', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
      } catch (indexError) {
        debugPrint(
            'CoachService: Composite index not ready, using fallback query: $indexError');
        // Fallback: Get all tips and filter/sort in memory
        snapshot = await _firestore
            .collection('coach_tips')
            .doc(user.uid)
            .collection('tips')
            .get();
      }

      List<CoachTip> allTips = snapshot.docs
          .map((doc) => CoachTip.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter and sort in memory if using fallback
      _tips = allTips.where((tip) => !tip.isDismissed).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Limit to 5 most recent
      if (_tips.length > 5) {
        _tips = _tips.take(5).toList();
      }

      debugPrint('CoachService: Loaded ${_tips.length} tips');
      notifyListeners();
    } catch (e) {
      debugPrint('CoachService: Error loading coach tips: $e');
      // Initialize with empty list if loading fails
      if (_tips.isEmpty) {
        _tips = [];
        notifyListeners();
      }
    }
  }

  Future<void> generateCoachTips() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
          'CoachService: No authenticated user, skipping tip generation');
      return;
    }

    if (_isLoading) {
      debugPrint('CoachService: Already generating tips, skipping');
      return;
    }

    // Cooldown: don't generate tips more than once every 30 seconds (for testing)
    if (_lastGenerationTime != null) {
      final timeSinceLastGeneration =
          DateTime.now().difference(_lastGenerationTime!);
      if (timeSinceLastGeneration.inSeconds < 30) {
        debugPrint(
            'CoachService: Too soon since last generation (${timeSinceLastGeneration.inSeconds} seconds), skipping');
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Check if analytics are already fresh to avoid unnecessary refreshes
      final analytics = _analyticsService.currentAnalytics;
      if (analytics == null) {
        debugPrint('CoachService: No analytics available, attempting refresh');
        try {
          await _analyticsService.refreshAnalytics();
        } catch (e) {
          debugPrint('CoachService: Analytics refresh failed: $e');
        }
      }

      final currentAnalytics = _analyticsService.currentAnalytics;
      List<CoachTip> newTips = [];

      if (currentAnalytics != null) {
        newTips = await _generateTipsFromAnalytics(currentAnalytics);
      } else {
        debugPrint(
            'CoachService: Analytics still not available, generating basic tips');
        newTips = [_generateWelcomeTip(user.uid)];
      }

      // Only save tips if we have new ones
      if (newTips.isNotEmpty) {
        debugPrint('CoachService: Generated ${newTips.length} new tips');

        // Try to save tips to Firestore
        bool savedSuccessfully = true;
        for (final tip in newTips) {
          try {
            await _saveTip(tip);
          } catch (e) {
            debugPrint('CoachService: Failed to save tip ${tip.id}: $e');
            savedSuccessfully = false;
          }
        }

        // If saving to Firestore failed, at least show tips locally
        if (!savedSuccessfully) {
          debugPrint(
              'CoachService: Some tips failed to save, showing locally only');
          _tips.addAll(newTips);
          _tips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          // Keep only the most recent 5 tips
          if (_tips.length > 5) {
            _tips = _tips.take(5).toList();
          }
          notifyListeners();
        } else {
          // Reload from Firestore if saving was successful
          await loadCoachTips();
        }
      } else {
        debugPrint('CoachService: No new tips generated');
      }

      _lastGenerationTime = DateTime.now();
    } catch (e) {
      debugPrint('Error generating coach tips: $e');
      // Don't rethrow - let the UI continue working
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<CoachTip>> _generateTipsFromAnalytics(Analytics analytics) async {
    final tips = <CoachTip>[];
    final user = _auth.currentUser!;

    try {
      // 1. Budget Alert Tips
      final budgetTip = _generateBudgetAlertTip(analytics, user.uid);
      if (budgetTip != null) tips.add(budgetTip);

      // 2. Saving Opportunity Tips
      final savingTip = _generateSavingOpportunityTip(analytics, user.uid);
      if (savingTip != null) tips.add(savingTip);

      // 3. Spending Pattern Tips
      final spendingTip = _generateSpendingPatternTip(analytics, user.uid);
      if (spendingTip != null) tips.add(spendingTip);

      // 4. Goal Progress Tips
      final goalTip = _generateGoalProgressTip(analytics, user.uid);
      if (goalTip != null) tips.add(goalTip);

      // 5. Fallback welcome tip if no other tips were generated
      if (tips.isEmpty) {
        tips.add(_generateWelcomeTip(user.uid));
      }

      debugPrint('CoachService: Generated ${tips.length} tips from analytics');
    } catch (e) {
      debugPrint('Error generating specific tips: $e');
      // Always provide at least a welcome tip
      tips.add(_generateWelcomeTip(user.uid));
    }

    return tips;
  }

  CoachTip? _generateBudgetAlertTip(Analytics analytics, String userId) {
    final forecastedBalance = _analyticsService.getForecastedBalance();
    final currentBalance = analytics.currentBalance;
    final difference = forecastedBalance - currentBalance;

    if (difference < -100) {
      return CoachTip(
        id: _uuid.v4(),
        userId: userId,
        type: CoachTipType.budgetAlert,
        priority: CoachTipPriority.critical,
        title: 'Budget Alert',
        message:
            'Your spending is on track to exceed your budget by \$${(-difference).toStringAsFixed(2)} this month. Consider reducing discretionary expenses.',
        actionText: 'Review Budget',
        actionUrl: '/budget',
        value: '\$${(-difference).toStringAsFixed(2)} over budget',
        createdAt: DateTime.now(),
      );
    } else if (difference < -50) {
      return CoachTip(
        id: _uuid.v4(),
        userId: userId,
        type: CoachTipType.budgetAlert,
        priority: CoachTipPriority.high,
        title: 'Spending Watch',
        message:
            'You\'re approaching your budget limit. You might exceed by \$${(-difference).toStringAsFixed(2)} if spending continues at current pace.',
        actionText: 'Track Expenses',
        actionUrl: '/expenses',
        value: '\$${(-difference).toStringAsFixed(2)} potential overspend',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  CoachTip? _generateSavingOpportunityTip(Analytics analytics, String userId) {
    final currentBalance = analytics.currentBalance;
    final avgSpending = analytics.avg30d;
    final potentialSavings =
        currentBalance - (avgSpending * 7); // Week ahead estimate

    if (potentialSavings > 50) {
      return CoachTip(
        id: _uuid.v4(),
        userId: userId,
        type: CoachTipType.savingOpportunity,
        priority: CoachTipPriority.medium,
        title: 'Saving Opportunity',
        message:
            'You\'re spending less than usual! You could potentially save \$${potentialSavings.toStringAsFixed(2)} this week.',
        actionText: 'Set Savings Goal',
        actionUrl: '/savings',
        value: '\$${potentialSavings.toStringAsFixed(2)} potential savings',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  CoachTip? _generateSpendingPatternTip(Analytics analytics, String userId) {
    final currentDailyAvg = analytics.daysPassed > 0
        ? analytics.mtdTotal / analytics.daysPassed
        : 0;
    final baseline30DayAvg = analytics.avg30d;

    if (currentDailyAvg > 0 && baseline30DayAvg > 0) {
      final percentDiff =
          ((currentDailyAvg - baseline30DayAvg) / baseline30DayAvg * 100);

      if (percentDiff > 25) {
        return CoachTip(
          id: _uuid.v4(),
          userId: userId,
          type: CoachTipType.spendingPattern,
          priority: CoachTipPriority.high,
          title: 'Spending Increase Detected',
          message:
              'Your daily spending is ${percentDiff.toStringAsFixed(0)}% higher than your 30-day average. Review recent transactions to identify the cause.',
          actionText: 'View Expenses',
          actionUrl: '/expenses',
          value: '+${percentDiff.toStringAsFixed(0)}% vs baseline',
          createdAt: DateTime.now(),
        );
      } else if (percentDiff < -15) {
        return CoachTip(
          id: _uuid.v4(),
          userId: userId,
          type: CoachTipType.spendingPattern,
          priority: CoachTipPriority.low,
          title: 'Great Job!',
          message:
              'You\'ve reduced your daily spending by ${percentDiff.abs().toStringAsFixed(0)}% compared to your baseline. Keep up the good work!',
          actionText: 'View Progress',
          actionUrl: '/analytics',
          value: '-${percentDiff.abs().toStringAsFixed(0)}% vs baseline',
          createdAt: DateTime.now(),
        );
      }
    }

    return null;
  }

  CoachTip? _generateGoalProgressTip(Analytics analytics, String userId) {
    // This would typically integrate with savings goals service
    // For now, we'll create a generic goal tip
    final currentBalance = analytics.currentBalance;

    if (currentBalance > 1000) {
      return CoachTip(
        id: _uuid.v4(),
        userId: userId,
        type: CoachTipType.goalProgress,
        priority: CoachTipPriority.low,
        title: 'Goal Setting',
        message:
            'With your current balance, you could set up an emergency fund or savings goal. Financial experts recommend 3-6 months of expenses.',
        actionText: 'Set Goals',
        actionUrl: '/goals',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  CoachTip _generateWelcomeTip(String userId) {
    return CoachTip(
      id: _uuid.v4(),
      userId: userId,
      type: CoachTipType.general,
      priority: CoachTipPriority.low,
      title: 'Welcome to Seva Coach!',
      message:
          'I\'m here to help you make smarter financial decisions. I\'ll analyze your spending patterns and provide personalized tips to help you save money and reach your goals.',
      actionText: 'Learn More',
      actionUrl: '/help',
      createdAt: DateTime.now(),
    );
  }

  Future<void> _saveTip(CoachTip tip) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('CoachService: Cannot save tip - no authenticated user');
      return;
    }

    if (user.uid != tip.userId) {
      debugPrint(
          'CoachService: Cannot save tip - user ID mismatch (${user.uid} != ${tip.userId})');
      return;
    }

    try {
      debugPrint('CoachService: Saving tip ${tip.id} for user ${tip.userId}');
      await _firestore
          .collection('coach_tips')
          .doc(tip.userId)
          .collection('tips')
          .doc(tip.id)
          .set(tip.toJson());
      debugPrint('CoachService: Successfully saved tip ${tip.id}');
    } catch (e) {
      debugPrint('CoachService: Error saving coach tip ${tip.id}: $e');
      rethrow; // Let the caller handle the error
    }
  }

  Future<void> markTipAsRead(String tipId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
          'CoachService: Cannot mark tip as read - no authenticated user');
      return;
    }

    try {
      debugPrint(
          'CoachService: Marking tip $tipId as read for user ${user.uid}');
      await _firestore
          .collection('coach_tips')
          .doc(user.uid)
          .collection('tips')
          .doc(tipId)
          .update({'isRead': true});

      // Update local state
      final index = _tips.indexWhere((tip) => tip.id == tipId);
      if (index != -1) {
        _tips[index] = _tips[index].copyWith(isRead: true);
        notifyListeners();
        debugPrint('CoachService: Successfully marked tip $tipId as read');
      }
    } catch (e) {
      debugPrint('CoachService: Error marking tip $tipId as read: $e');
    }
  }

  Future<void> dismissTip(String tipId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('CoachService: Cannot dismiss tip - no authenticated user');
      return;
    }

    try {
      debugPrint('CoachService: Dismissing tip $tipId for user ${user.uid}');
      await _firestore
          .collection('coach_tips')
          .doc(user.uid)
          .collection('tips')
          .doc(tipId)
          .update({'isDismissed': true});

      // Update local state
      final index = _tips.indexWhere((tip) => tip.id == tipId);
      if (index != -1) {
        _tips[index] = _tips[index].copyWith(isDismissed: true);
        notifyListeners();
        debugPrint('CoachService: Successfully dismissed tip $tipId');
      }
    } catch (e) {
      debugPrint('CoachService: Error dismissing tip $tipId: $e');
    }
  }

  void clearTips() {
    _tips.clear();
    notifyListeners();
  }

  // Force generate tips for testing (bypasses cooldown)
  Future<void> forceGenerateTips() async {
    _lastGenerationTime = null; // Reset cooldown
    await generateCoachTips();
  }
}
