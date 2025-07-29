import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hive/hive.dart';
import '../models/user.dart';

class UserService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final Box<User> _userBox;

  User? _currentUser;
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  UserService(this._firestore, this._auth, this._userBox) {
    _initialLoadFuture = _initialize();

    // Listen to auth state changes
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUser(firebaseUser.uid);
      } else {
        // User signed out - clear all data
        _handleUserSignOut();
      }
    });
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  Future<void>? get initializationComplete => _initialLoadFuture;

  String? get _userId => _auth.currentUser?.uid;

  void _handleUserSignOut() {
    debugPrint('UserService: User signed out, clearing all data');
    _currentUser = null;

    // Clear all user data asynchronously (don't await to avoid blocking UI)
    _clearUserSpecificBoxes().then((_) {
      debugPrint('UserService: User data cleared on sign out');
    }).catchError((e) {
      debugPrint('UserService: Error clearing data on sign out: $e');
    });

    notifyListeners();
  }

  Future<void> _initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUser(firebaseUser.uid);
    }
  }

  Future<void> _loadUser(String userId) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('UserService: Loading user data for $userId');

      // Try to load from Firestore first
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        _currentUser = User.fromMap(doc.data()!, userId);
        debugPrint(
            'UserService: User loaded from Firestore: ${_currentUser?.planStatus}');

        // Cache locally
        await _userBox.put(userId, _currentUser!);
      } else {
        // User doesn't exist in Firestore, create from Firebase Auth
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          await _createUserFromFirebaseAuth(firebaseUser);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('UserService: Error loading user: $e');

      // Only try to load from cache if the user ID matches current auth user
      // This prevents loading stale data after user switches
      if (_auth.currentUser?.uid == userId) {
        _currentUser = _userBox.get(userId);
        debugPrint('UserService: Loaded user from cache as fallback');
      } else {
        debugPrint('UserService: Not loading from cache - user ID mismatch');
        _currentUser = null;
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createUserFromFirebaseAuth(
      firebase_auth.User firebaseUser) async {
    try {
      debugPrint('UserService: Creating new user from Firebase Auth');

      // Auto-grant 14-day trial for new users
      final now = DateTime.now();

      // Create username from display name
      final username = (firebaseUser.displayName ?? firebaseUser.email ?? '')
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('@', '')
          .replaceAll('.', '')
          .trim();

      _currentUser = User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        createdAt: firebaseUser.metadata.creationTime,
        updatedAt: now,
        trialStart: now, // Auto-grant trial
        isPro: true, // Start with Pro access during trial
        hasPaid: false,
        scanCountThisMonth: 0,
      );

      // Save to Firestore with username for compatibility
      final userData = _currentUser!.toMap();
      userData['username'] = username;

      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      // Cache locally
      await _userBox.put(firebaseUser.uid, _currentUser!);

      debugPrint(
          'UserService: New user created with 14-day trial and username: $username');

      // Fire analytics event
      await _fireAnalyticsEvent('trial_granted', {
        'user_id': firebaseUser.uid,
        'trial_start': now.toIso8601String(),
        'trial_end': now.add(const Duration(days: 14)).toIso8601String(),
      });
    } catch (e) {
      debugPrint('UserService: Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(User updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userWithTimestamp = updatedUser.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _firestore.collection('users').doc(updatedUser.id).set(
            userWithTimestamp.toMap(),
            SetOptions(merge: true),
          );

      // Update local cache
      await _userBox.put(updatedUser.id, userWithTimestamp);

      _currentUser = userWithTimestamp;
      _isLoading = false;
      notifyListeners();

      debugPrint('UserService: User updated successfully');
    } catch (e) {
      debugPrint('UserService: Error updating user: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ProPlan specific methods
  Future<void> grantTrial() async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    final updatedUser = _currentUser!.copyWith(
      trialStart: now,
      isPro: true,
      hasPaid: false,
    );

    await updateUser(updatedUser);

    await _fireAnalyticsEvent('trial_granted', {
      'user_id': _currentUser!.id,
      'trial_start': now.toIso8601String(),
      'trial_end': now.add(const Duration(days: 14)).toIso8601String(),
    });
  }

  Future<void> activateProSubscription({
    required String stripeCustomerId,
    required String stripeSubscriptionId,
    required String subscriptionStatus,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
  }) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      isPro: true,
      hasPaid: true,
      stripeCustomerId: stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId,
      subscriptionStatus: subscriptionStatus,
      subscriptionStart: subscriptionStart ?? DateTime.now(),
      subscriptionEnd: subscriptionEnd,
    );

    await updateUser(updatedUser);

    await _fireAnalyticsEvent('subscription_activated', {
      'user_id': _currentUser!.id,
      'subscription_id': stripeSubscriptionId,
      'customer_id': stripeCustomerId,
      'status': subscriptionStatus,
    });
  }

  Future<void> deactivateProSubscription() async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      isPro: false,
      subscriptionStatus: 'canceled',
    );

    await updateUser(updatedUser);

    await _fireAnalyticsEvent('subscription_deactivated', {
      'user_id': _currentUser!.id,
      'subscription_id': _currentUser!.stripeSubscriptionId,
    });
  }

  Future<void> incrementScanCount() async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      scanCountThisMonth: _currentUser!.scanCountThisMonth + 1,
    );

    await updateUser(updatedUser);
  }

  Future<void> resetMonthlyScanCount() async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      scanCountThisMonth: 0,
    );

    await updateUser(updatedUser);
  }

  // Helper method to check if trial has expired for batch processing
  bool isTrialExpiredForUser(User user) {
    if (user.trialStart == null) return false;
    final now = DateTime.now();
    final trialEnd = user.trialStart!.add(const Duration(days: 14));
    return now.isAfter(trialEnd) && !user.hasPaid;
  }

  // Check and update trial status if needed
  Future<void> checkAndUpdateTrialStatus() async {
    if (_currentUser == null) return;

    if (isTrialExpiredForUser(_currentUser!) && _currentUser!.isPro) {
      final updatedUser = _currentUser!.copyWith(
        isPro: false,
      );

      await updateUser(updatedUser);

      await _fireAnalyticsEvent('trial_expired', {
        'user_id': _currentUser!.id,
        'trial_start': _currentUser!.trialStart?.toIso8601String(),
        'trial_end': _currentUser!.trialStart
            ?.add(const Duration(days: 14))
            .toIso8601String(),
      });

      debugPrint('UserService: Trial expired for user ${_currentUser!.id}');
    }
  }

  // Logout method to clear user data
  Future<void> logout() async {
    try {
      debugPrint('UserService: Clearing user data on logout');

      // Clear current user
      _currentUser = null;

      // Clear user-specific Hive boxes
      await _clearUserSpecificBoxes();

      // Notify listeners
      notifyListeners();

      debugPrint('UserService: User data cleared successfully');
    } catch (e) {
      debugPrint('UserService: Error clearing user data: $e');
    }
  }

  Future<void> _clearUserSpecificBoxes() async {
    // Clear user-specific data boxes (but preserve global settings)
    final boxesToClear = [
      'users', // User profiles
      'usage_tracking', // ProPlan usage tracking
      'wallets', // User wallets
      'expenses', // User expenses
      'budget', // User budget data
      'savings_goals', // User savings goals
      'spending_alerts', // User spending alerts
      'notifications', // User notifications
      'user_onboarding', // User onboarding state
      'budget_templates', // User budget templates
      'template_items', // User template items
      'category_budgets', // User category budgets
      'recurring_transactions', // User recurring transactions
      'analytics', // User analytics data
      'insights', // User AI insights
    ];

    // Preserve global settings:
    // - 'expense_categories' (global category definitions)
    // - 'ocr_settings_box' (global OCR preferences)
    // - 'feature_flags' (global feature flags, will be reloaded)

    for (final boxName in boxesToClear) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          debugPrint('UserService: Cleared box: $boxName');
        }
      } catch (e) {
        debugPrint('UserService: Error clearing box $boxName: $e');
      }
    }
  }

  Future<void> _fireAnalyticsEvent(
      String eventName, Map<String, dynamic> parameters) async {
    try {
      if (_userId != null) {
        await _firestore
            .collection('users')
            .doc(_userId!)
            .collection('analytics')
            .add({
          'event_name': eventName,
          'parameters': parameters,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('UserService: Error firing analytics event: $e');
      // Don't rethrow - analytics failures shouldn't affect core functionality
    }
  }
}
