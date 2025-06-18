import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService with ChangeNotifier {
  final Box<AppNotification> _localBox;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  NotificationService(this._localBox, this._firestore, this._messaging) {
    _initialLoadFuture = _loadNotifications();
    _setupFirebaseMessaging();
  }

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasUnreadNotifications => _notifications.any((n) => !n.isRead);
  Future<void>? get initializationComplete => _initialLoadFuture;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _setupFirebaseMessaging() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _messaging.getToken();
        if (token != null && _userId != null) {
          await _firestore.collection('users').doc(_userId).set({
            'fcmTokens': FieldValue.arrayUnion([token]),
          }, SetOptions(merge: true));
          debugPrint("NotificationService: FCM token $token saved for user $_userId");
        } else if (_userId == null) {
          debugPrint("NotificationService: User not logged in, FCM token not saved.");
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleNotification(message, _userId);
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotification(message, _userId);
        });
      }
    } catch (e) {
      debugPrint('Error setting up Firebase Messaging: $e');
    }
  }

  void _handleNotification(RemoteMessage message, String? userId) {
    if (userId == null) {
      debugPrint("NotificationService: Received notification but user not logged in. Ignoring.");
      return;
    }
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
    debugPrint("NotificationService: Handled foreground/opened app notification ${notification.id}");
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
    if (_isLoading) return;
    _isLoading = true;

    final String? currentUserId = _userId;

    if (currentUserId == null) {
      debugPrint('NotificationService: User not authenticated. Loading notifications from local cache only.');
      _notifications = _localBox.values.toList();
      _isLoading = false;
    notifyListeners();
      return;
    }

    try {
      debugPrint('NotificationService: User $currentUserId authenticated. Starting Firestore sync for notifications.');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();
      debugPrint('NotificationService: Fetched ${snapshot.docs.length} notifications from Firestore for user $currentUserId.');
      
      final remoteNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification.fromJson({
          ...data, 
          'id': doc.id
        });
      }).toList();

      Map<String, AppNotification> localNotificationsMap = { for (var n in _localBox.values) n.id : n };
      Set<String> remoteNotificationIds = {};

      for (final remoteNotification in remoteNotifications) {
        remoteNotificationIds.add(remoteNotification.id);
        await _localBox.put(remoteNotification.id, remoteNotification);
        localNotificationsMap[remoteNotification.id] = remoteNotification;
      }

      List<String> notificationsToDeleteLocally = [];
      for (final localNotificationId in localNotificationsMap.keys) {
        if (!remoteNotificationIds.contains(localNotificationId)) {
          notificationsToDeleteLocally.add(localNotificationId);
        }
      }
      for (final notificationIdToDelete in notificationsToDeleteLocally) {
        await _localBox.delete(notificationIdToDelete);
        localNotificationsMap.remove(notificationIdToDelete);
        debugPrint('NotificationService: Deleted notification $notificationIdToDelete from local cache.');
      }
      
      _notifications = localNotificationsMap.values.toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      debugPrint('NotificationService: Synced ${_notifications.length} notifications. In-memory list updated and sorted.');

    } catch (e) {
      debugPrint('Error syncing notifications with Firestore: $e. Using local cache as fallback.');
      _notifications = _localBox.values.toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addActionNotification({
    required String title,
    required String message,
    String? relatedId,
  }) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint("NotificationService: User not logged in. Cannot add action notification.");
      return;
    }
      _isLoading = true;
      notifyListeners();

    try {
      final notification = AppNotification.fromAction(
        title: title,
        message: message,
        relatedId: relatedId,
      );

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());

      await _localBox.put(notification.id, notification);
      _notifications.insert(0, notification);
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    } catch (e) {
      debugPrint("Error adding action notification: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAlertNotification({
    required String alertId,
    required String title,
    required String message,
  }) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint("NotificationService: User not logged in. Cannot add alert notification.");
      return;
    }
      _isLoading = true;
      notifyListeners();

    try {
      final notification = AppNotification.fromAlert(
        alertId: alertId,
        title: title,
        message: message,
      );

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());

      await _localBox.put(notification.id, notification);
      _notifications.insert(0, notification);
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    } catch (e) {
      debugPrint("Error adding alert notification: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint("NotificationService: User not logged in. Cannot mark notification as read.");
      return;
    }
    _isLoading = true;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'timestamp': FieldValue.serverTimestamp()});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index].isRead = true;
        await _localBox.put(notificationId, _notifications[index]);
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint("NotificationService: User not logged in. Cannot delete notification.");
      return;
    }
    _isLoading = true;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      await _localBox.delete(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);

    } catch (e) {
      debugPrint("Error deleting notification: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 