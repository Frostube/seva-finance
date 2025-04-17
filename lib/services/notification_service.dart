import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  final Box<bool> _notificationBox;
  final Box<AppNotification> _notificationsBox;
  bool _hasUnreadNotifications = false;
  List<AppNotification> _notifications = [];

  NotificationService(this._notificationBox, this._notificationsBox) {
    _loadUnreadStatus();
    _loadNotifications();
  }

  bool get hasUnreadNotifications => _hasUnreadNotifications;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void _loadUnreadStatus() {
    _hasUnreadNotifications = _notificationBox.get('hasUnread', defaultValue: false) ?? false;
  }

  void _loadNotifications() {
    _notifications = _notificationsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addNotification(AppNotification notification) async {
    await _notificationsBox.put(notification.id, notification);
    _notifications.insert(0, notification);
    await markAsUnread();
    notifyListeners();
  }

  Future<void> markAsRead() async {
    await _notificationBox.put('hasUnread', false);
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  Future<void> markAsUnread() async {
    await _notificationBox.put('hasUnread', true);
    _hasUnreadNotifications = true;
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final notification = _notificationsBox.get(notificationId);
    if (notification != null) {
      notification.isRead = true;
      await notification.save();
      _loadNotifications();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationsBox.delete(notificationId);
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  // Helper methods for different notification types
  Future<void> addAlertNotification({
    required String alertId,
    required String title,
    required String message,
  }) async {
    final notification = AppNotification.fromAlert(
      alertId: alertId,
      title: title,
      message: message,
    );
    await addNotification(notification);
  }

  Future<void> addGoalNotification({
    required String goalId,
    required String title,
    required String message,
  }) async {
    final notification = AppNotification.fromGoal(
      goalId: goalId,
      title: title,
      message: message,
    );
    await addNotification(notification);
  }

  Future<void> addActionNotification({
    required String title,
    required String message,
    String? relatedId,
  }) async {
    final notification = AppNotification.fromAction(
      title: title,
      message: message,
      relatedId: relatedId,
    );
    await addNotification(notification);
  }
} 