import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/insight.dart';
import '../services/insights_service.dart';
import '../services/notification_service.dart';

class InsightNotificationService {
  final InsightsService _insightsService;
  final NotificationService _notificationService;
  final FirebaseMessaging _messaging;

  InsightNotificationService(
    this._insightsService,
    this._notificationService,
    this._messaging,
  );

  /// Check for critical insights and trigger notifications
  Future<void> checkAndSendCriticalAlerts() async {
    try {
      final insights = _insightsService.insights;
      debugPrint(
          'InsightNotificationService: Checking ${insights.length} insights for critical alerts');

      final criticalInsights = insights
          .where((insight) =>
              !insight.isRead &&
              (insight.priority == InsightPriority.critical ||
                  insight.priority == InsightPriority.high))
          .toList();

      debugPrint(
          'InsightNotificationService: Found ${criticalInsights.length} critical/high priority insights');

      for (final insight in criticalInsights) {
        debugPrint(
            'InsightNotificationService: Sending notification for insight: ${insight.text}');
        await _sendInsightNotification(insight);
      }
    } catch (e) {
      debugPrint('Error checking critical insights: $e');
    }
  }

  /// Send notification for a specific insight
  Future<void> _sendInsightNotification(Insight insight) async {
    String title;
    String body;

    switch (insight.type) {
      case InsightType.budgetAlert:
        title = 'Budget Alert 📊';
        body = insight.text;
        break;
      case InsightType.forecastBalance:
        if (insight.value != null && insight.value! < 0) {
          title = 'Balance Warning ⚠️';
          body = 'Your balance may go negative by month-end';
        } else {
          return; // Don't notify for positive forecasts
        }
        break;
      case InsightType.overspend:
        title = 'Overspending Alert 💸';
        body = insight.text;
        break;
      default:
        title = 'Financial Insight 💡';
        body = insight.text;
    }

    // Send in-app notification
    await _notificationService.addActionNotification(
      title: title,
      message: body,
      relatedId: insight.id,
    );

    // For critical alerts, also consider FCM push notification
    if (insight.priority == InsightPriority.critical) {
      await _sendPushNotification(title, body);
    }
  }

  /// Send push notification for critical alerts
  Future<void> _sendPushNotification(String title, String body) async {
    try {
      // Note: In production, this would typically be handled by your backend
      // This is a placeholder for FCM integration
      debugPrint('Would send push notification: $title - $body');

      // For local notifications, you could use flutter_local_notifications
      // await _localNotifications.show(
      //   0,
      //   title,
      //   body,
      //   notificationDetails,
      // );
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  /// Check for low balance forecast and send immediate alert
  Future<void> checkLowBalanceForecast(double threshold) async {
    try {
      final insights = _insightsService.insights
          .where((insight) =>
              insight.type == InsightType.forecastBalance &&
              insight.value != null &&
              insight.value! < threshold &&
              !insight.isRead)
          .toList();

      for (final insight in insights) {
        await _sendUrgentBalanceAlert(insight);
      }
    } catch (e) {
      debugPrint('Error checking low balance forecast: $e');
    }
  }

  /// Send urgent balance alert
  Future<void> _sendUrgentBalanceAlert(Insight insight) async {
    await _notificationService.addActionNotification(
      title: 'Urgent: Low Balance Warning',
      message:
          'Your projected balance (\$${insight.value!.toStringAsFixed(2)}) is critically low!',
      relatedId: insight.id,
    );
  }

  /// Initialize notification listeners
  void initializeListeners() {
    // Listen to new insights
    _insightsService.addListener(_onInsightsUpdated);
  }

  /// Handle insights updates
  void _onInsightsUpdated() {
    debugPrint(
        'InsightNotificationService: Insights updated, checking for critical alerts...');
    // Auto-check for critical alerts when insights are updated
    checkAndSendCriticalAlerts();
  }

  /// Dispose listeners
  void dispose() {
    _insightsService.removeListener(_onInsightsUpdated);
  }
}
