import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/notification.dart';

class NotificationService with ChangeNotifier {
  final Box<AppNotification> _localBox;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  NotificationService(this._localBox, this._firestore, this._messaging) {
    _loadNotifications();
    _setupFirebaseMessaging();
  }

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasUnreadNotifications => _notifications.any((n) => !n.isRead);

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token only if permission is granted
        final token = await _messaging.getToken();
        if (token != null) {
          final userId = _auth.currentUser?.uid;
          if (userId != null) {
            await _firestore.collection('users').doc(userId).update({
              'fcmTokens': FieldValue.arrayUnion([token]),
            });
          }
        }

        // Handle incoming messages when app is in foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleNotification(message);
        });

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotification(message);
        });
      }
    } catch (e) {
      // Log error but don't throw - notifications are not critical for app function
      debugPrint('Error setting up Firebase Messaging: $e');
    }
  }

  void _handleNotification(RemoteMessage message) {
    final notification = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _getNotificationType(message.data['type'] as String?),
      title: message.notification?.title ?? 'New Notification',
      message: message.notification?.body ?? '',
      relatedId: message.data['relatedId'] as String?,
    );

    _notifications.insert(0, notification);
    _localBox.put(notification.id, notification);
    notifyListeners();
  }

  NotificationType _getNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'alert':
        return NotificationType.alert;
      case 'goal':
        return NotificationType.goal;
      default:
        return NotificationType.action;
    }
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local storage first
      _notifications = _localBox.values.toList();

      // Then sync with Firestore
      final snapshot = await _firestore.collection('notifications').get();
      final remoteNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          type: _getNotificationType(data['type'] as String?),
          title: data['title'] as String,
          message: data['message'] as String,
          relatedId: data['relatedId'] as String?,
          isRead: data['isRead'] as bool? ?? false,
        );
      }).toList();

      // Merge local and remote notifications
      for (final remoteNotification in remoteNotifications) {
        final localIndex = _notifications.indexWhere((n) => n.id == remoteNotification.id);
        if (localIndex >= 0) {
          _notifications[localIndex] = remoteNotification;
        } else {
          _notifications.add(remoteNotification);
        }
      }

      // Save merged notifications to local storage
      await _localBox.clear();
      for (final notification in _notifications) {
        await _localBox.put(notification.id, notification);
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addActionNotification({
    required String title,
    required String message,
    String? relatedId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final notification = AppNotification.fromAction(
        title: title,
        message: message,
        relatedId: relatedId,
      );

      // Add to Firestore
      await _firestore.collection('notifications').doc(notification.id).set({
        'type': 'action',
        'title': notification.title,
        'message': notification.message,
        'relatedId': notification.relatedId,
        'isRead': notification.isRead,
      });

      // Save to local storage
      await _localBox.put(notification.id, notification);
      _notifications.insert(0, notification);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addAlertNotification({
    required String alertId,
    required String title,
    required String message,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final notification = AppNotification.fromAlert(
        alertId: alertId,
        title: title,
        message: message,
      );

      // Add to Firestore
      await _firestore.collection('notifications').doc(notification.id).set({
        'type': 'alert',
        'title': notification.title,
        'message': notification.message,
        'relatedId': notification.relatedId,
        'isRead': notification.isRead,
      });

      // Save to local storage
      await _localBox.put(notification.id, notification);
      _notifications.insert(0, notification);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update in Firestore
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      // Update in local storage
      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      notification.isRead = true;
      await _localBox.put(notificationId, notification);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete from Firestore
      await _firestore.collection('notifications').doc(notificationId).delete();

      // Delete from local storage
      await _localBox.delete(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
} 