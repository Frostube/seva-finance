import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService with ChangeNotifier {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool _isSupported = false;
  bool _hasPermission = false;
  bool _isEnabled = false;
  String? _currentToken;

  // VAPID Key for Web Push - Generated from Firebase Console
  // Go to Firebase Console → Project Settings → Cloud Messaging → Web configuration → Generate key pair
  static const String _vapidKey =
      'BOeoYZ8Yq-7NyQTlUSAgsHMFc1q4zCDtY6rXNvbHKx7uPpmShCWB9rKeNnuum19BAEkVk4ACOAckWD8yiIP70N0';

  PushNotificationService(this._messaging, this._firestore, this._auth) {
    _initialize();
  }

  // Getters
  bool get isSupported => _isSupported;
  bool get hasPermission => _hasPermission;
  bool get isEnabled => _isEnabled;
  String? get currentToken => _currentToken;
  String? get _userId => _auth.currentUser?.uid;

  Future<void> _initialize() async {
    if (kIsWeb) {
      _isSupported = true;
      await _loadSettings();
      await _checkPermissionStatus();

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _loadSettings();
        } else {
          _clearSettings();
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('push_notifications_enabled') ?? false;

    if (_isEnabled && _userId != null) {
      await _refreshToken();
    }

    notifyListeners();
  }

  Future<void> _clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('push_notifications_enabled');
    _isEnabled = false;
    _hasPermission = false;
    _currentToken = null;
    notifyListeners();
  }

  Future<void> _checkPermissionStatus() async {
    if (!kIsWeb || !_isSupported) return;

    try {
      final settings = await _messaging.getNotificationSettings();
      _hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking permission status: $e');
    }
  }

  /// Request push notification permission from user
  Future<bool> requestPermission() async {
    if (!kIsWeb || !_isSupported) return false;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      _hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      if (_hasPermission && _userId != null) {
        await _getAndSaveToken();
        await _enableNotifications();
      }

      notifyListeners();
      return _hasPermission;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Enable push notifications (saves token to Firestore)
  Future<bool> enableNotifications() async {
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return false;
    }

    return await _enableNotifications();
  }

  Future<bool> _enableNotifications() async {
    if (_userId == null) return false;

    try {
      await _getAndSaveToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications_enabled', true);

      _isEnabled = true;
      notifyListeners();

      debugPrint('Push notifications enabled successfully');
      return true;
    } catch (e) {
      debugPrint('Error enabling notifications: $e');
      return false;
    }
  }

  /// Disable push notifications (removes token from Firestore)
  Future<void> disableNotifications() async {
    if (_userId == null) return;

    try {
      if (_currentToken != null) {
        await _removeTokenFromFirestore();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications_enabled', false);

      _isEnabled = false;
      _currentToken = null;
      notifyListeners();

      debugPrint('Push notifications disabled successfully');
    } catch (e) {
      debugPrint('Error disabling notifications: $e');
    }
  }

  Future<void> _getAndSaveToken() async {
    if (_userId == null) return;

    // Check if VAPID key is properly configured
    if (_vapidKey.contains('REPLACE_WITH_YOUR_ACTUAL_VAPID_KEY')) {
      debugPrint(
          '❌ VAPID key not configured! Please update _vapidKey with your Firebase Console key.');
      debugPrint(
          '🔧 Go to Firebase Console → Project Settings → Cloud Messaging → Web configuration → Generate key pair');
      return;
    }

    try {
      final token = await _messaging.getToken(vapidKey: _vapidKey);
      if (token != null) {
        _currentToken = token;
        await _saveTokenToFirestore(token);
        debugPrint('✅ FCM token obtained and saved: $token');
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      if (e.toString().contains('applicationServerKey is not valid')) {
        debugPrint(
            '💡 The VAPID key appears to be invalid. Please check your Firebase Console for the correct key.');
      }
    }
  }

  Future<void> _refreshToken() async {
    if (_userId == null || !_isEnabled) return;

    try {
      await _getAndSaveToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((String newToken) {
        _currentToken = newToken;
        _saveTokenToFirestore(newToken);
        debugPrint('FCM token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).set({
        'pushToken': token,
        'pushEnabled': true,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'web',
      }, SetOptions(merge: true));

      debugPrint('Push token saved to Firestore for user $_userId');
    } catch (e) {
      debugPrint('Error saving token to Firestore: $e');
    }
  }

  Future<void> _removeTokenFromFirestore() async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).update({
        'pushToken': FieldValue.delete(),
        'pushEnabled': false,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Push token removed from Firestore for user $_userId');
    } catch (e) {
      debugPrint('Error removing token from Firestore: $e');
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences({
    double budgetThreshold = 0.8,
    bool billReminders = true,
    bool budgetAlerts = true,
    bool spendingAlerts = true,
  }) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).set({
        'notificationPreferences': {
          'budgetThreshold': budgetThreshold,
          'billReminders': billReminders,
          'budgetAlerts': budgetAlerts,
          'spendingAlerts': spendingAlerts,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      debugPrint('Notification preferences updated');
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  /// Get current notification preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    if (_userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['notificationPreferences'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
    }

    return null;
  }
}
