import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_onboarding.dart';
import 'auth_service.dart';

class OnboardingService with ChangeNotifier {
  final Box<UserOnboarding> _onboardingBox;
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  UserOnboarding? _userOnboarding;
  bool _isLoading = false;

  OnboardingService(this._onboardingBox, this._firestore, this._authService) {
    _initializeOnboarding();
  }

  UserOnboarding? get userOnboarding => _userOnboarding;
  bool get isLoading => _isLoading;
  bool get shouldShowOnboarding =>
      _userOnboarding?.onboardingCompleted != true && _shouldShowForUser();

  // Only show onboarding to new users (those who haven't completed it AND haven't explicitly skipped it)
  bool _shouldShowForUser() {
    if (_userOnboarding == null) {
      // New user with no onboarding data - check if account is actually new
      return _isLikelyNewUser();
    }

    // Don't show if already completed
    if (_userOnboarding!.onboardingCompleted) return false;

    // If user has explicitly reset onboarding (all fields are default), allow showing
    if (_userOnboarding!.onboardingStartedAt == null &&
        _userOnboarding!.onboardingCompletedAt == null &&
        _userOnboarding!.completedSteps.isEmpty &&
        _userOnboarding!.currentStep == 0) {
      // This is either a new user or someone who reset onboarding
      // Allow showing for debug/reset purposes regardless of account age
      return true;
    }

    // Don't show if user has been using the app for a while without onboarding
    // (indicates they're an existing user from before onboarding was added)
    if (_userOnboarding!.onboardingStartedAt == null) {
      return _isLikelyNewUser();
    }

    return true; // User started onboarding but didn't complete it
  }

  bool _isLikelyNewUser() {
    try {
      if (!_authService.isAuthenticated || _authService.user == null) {
        return false;
      }

      final user = _authService.user!;
      final creationTime = user.metadata.creationTime;

      if (creationTime != null) {
        final now = DateTime.now();
        final daysSinceCreation = now.difference(creationTime).inDays;

        // Consider user "new" if account was created within the last 3 days
        return daysSinceCreation <= 3;
      }

      // If we can't determine creation time, only show for users with no onboarding data
      return _userOnboarding == null;
    } catch (e) {
      print('Error checking if user is likely new: $e');
      // Conservative fallback: only show for users with no onboarding data
      return _userOnboarding == null;
    }
  }

  Future<void> _initializeOnboarding() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to load from local storage first
      _userOnboarding = _onboardingBox.get('onboarding');

      // If user is authenticated, sync with Firestore
      if (_authService.isAuthenticated && _authService.user != null) {
        await _syncWithFirestore();
      }

      // Create default onboarding state if none exists
      if (_userOnboarding == null) {
        _userOnboarding = UserOnboarding();

        // Auto-mark existing users (who have old accounts) as having completed onboarding
        if (!_isLikelyNewUser()) {
          print('Auto-marking existing user as having completed onboarding');
          _userOnboarding!.onboardingCompleted = true;
          _userOnboarding!.onboardingCompletedAt = DateTime.now();

          await _fireAnalyticsEvent('onboarding_auto_marked_existing_user', {
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        await _saveOnboardingState();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing onboarding: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncWithFirestore() async {
    try {
      final userId = _authService.user?.uid;
      if (userId == null) return;

      // Try to get onboarding data from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('onboarding')
          .get();

      if (doc.exists) {
        final firestoreOnboarding = UserOnboarding.fromMap(doc.data()!);

        // Use Firestore data if it's more recent or if local data doesn't exist
        if (_userOnboarding == null ||
            (firestoreOnboarding.onboardingCompletedAt != null &&
                (_userOnboarding!.onboardingCompletedAt == null ||
                    firestoreOnboarding.onboardingCompletedAt!
                        .isAfter(_userOnboarding!.onboardingCompletedAt!)))) {
          _userOnboarding = firestoreOnboarding;
          await _onboardingBox.put('onboarding', _userOnboarding!);
        }
      }
    } catch (e) {
      print('Error syncing onboarding with Firestore: $e');
      // Continue with local data if sync fails
    }
  }

  Future<void> startOnboarding() async {
    try {
      _userOnboarding ??= UserOnboarding();
      _userOnboarding!.onboardingStartedAt = DateTime.now();
      _userOnboarding!.currentStep = 0;

      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_started', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error starting onboarding: $e');
    }
  }

  Future<void> completeStep(String stepName) async {
    try {
      if (_userOnboarding == null) return;

      if (!_userOnboarding!.completedSteps.contains(stepName)) {
        _userOnboarding!.completedSteps = [
          ..._userOnboarding!.completedSteps,
          stepName
        ];
      }

      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_step_completed', {
        'step_name': stepName,
        'step_number': _userOnboarding!.currentStep,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error completing onboarding step: $e');
    }
  }

  Future<void> nextStep() async {
    try {
      if (_userOnboarding == null) return;

      _userOnboarding!.currentStep++;
      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_step_advanced', {
        'current_step': _userOnboarding!.currentStep,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error advancing onboarding step: $e');
    }
  }

  Future<void> previousStep() async {
    try {
      if (_userOnboarding == null || _userOnboarding!.currentStep <= 0) return;

      _userOnboarding!.currentStep--;
      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_step_back', {
        'current_step': _userOnboarding!.currentStep,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error going back onboarding step: $e');
    }
  }

  Future<void> completeOnboarding() async {
    try {
      _userOnboarding ??= UserOnboarding();
      _userOnboarding!.onboardingCompleted = true;
      _userOnboarding!.onboardingCompletedAt = DateTime.now();

      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_completed', {
        'completion_time': DateTime.now().toIso8601String(),
        'total_steps': _userOnboarding!.completedSteps.length,
        'duration_seconds': _userOnboarding!.onboardingStartedAt != null
            ? DateTime.now()
                .difference(_userOnboarding!.onboardingStartedAt!)
                .inSeconds
            : 0,
      });

      notifyListeners();
    } catch (e) {
      print('Error completing onboarding: $e');
    }
  }

  Future<void> skipOnboarding() async {
    try {
      _userOnboarding ??= UserOnboarding();
      _userOnboarding!.onboardingCompleted = true;
      _userOnboarding!.onboardingCompletedAt = DateTime.now();

      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_skipped', {
        'skipped_at_step': _userOnboarding!.currentStep,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error skipping onboarding: $e');
    }
  }

  Future<void> resetOnboarding() async {
    try {
      _userOnboarding = UserOnboarding();
      // For debug purposes, explicitly mark that onboarding should be shown
      _userOnboarding!.onboardingCompleted = false;
      _userOnboarding!.onboardingStartedAt = null;
      _userOnboarding!.onboardingCompletedAt = null;
      _userOnboarding!.currentStep = 0;
      _userOnboarding!.completedSteps = [];

      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_reset', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error resetting onboarding: $e');
    }
  }

  /// Mark existing user as having completed onboarding (for users who existed before onboarding was added)
  Future<void> markAsExistingUser() async {
    try {
      _userOnboarding ??= UserOnboarding();
      _userOnboarding!.onboardingCompleted = true;
      _userOnboarding!.onboardingCompletedAt = DateTime.now();

      await _saveOnboardingState();

      // Fire analytics event
      await _fireAnalyticsEvent('onboarding_marked_existing_user', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error marking user as existing: $e');
    }
  }

  /// Check if user should see onboarding based on account creation date
  Future<bool> isNewUser() async {
    try {
      if (!_authService.isAuthenticated || _authService.user == null) {
        return false;
      }

      final user = _authService.user!;
      final creationTime = user.metadata.creationTime;

      if (creationTime != null) {
        final now = DateTime.now();
        final daysSinceCreation = now.difference(creationTime).inDays;

        // Consider user "new" if account was created within the last 3 days
        // This accounts for users who might not immediately use the app after signing up
        return daysSinceCreation <= 3;
      }

      return false; // If we can't determine creation time, assume existing user
    } catch (e) {
      print('Error checking if user is new: $e');
      return false;
    }
  }

  Future<void> _saveOnboardingState() async {
    try {
      if (_userOnboarding == null) return;

      // Save to local storage
      await _onboardingBox.put('onboarding', _userOnboarding!);

      // Save to Firestore if authenticated
      if (_authService.isAuthenticated && _authService.user != null) {
        await _firestore
            .collection('users')
            .doc(_authService.user!.uid)
            .collection('settings')
            .doc('onboarding')
            .set(_userOnboarding!.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving onboarding state: $e');
    }
  }

  Future<void> _fireAnalyticsEvent(
      String eventName, Map<String, dynamic> parameters) async {
    try {
      // TODO: Integrate with your analytics service (Firebase Analytics, etc.)
      print('Analytics Event: $eventName - $parameters');

      // Store analytics events in user-specific subcollection
      if (_authService.isAuthenticated && _authService.user != null) {
        await _firestore
            .collection('users')
            .doc(_authService.user!.uid)
            .collection('analytics')
            .add({
          'event_name': eventName,
          'parameters': parameters,
          'timestamp': FieldValue.serverTimestamp(),
        }).timeout(
                const Duration(seconds: 5)); // Add timeout to prevent hanging
      }
    } catch (e) {
      // Silently handle analytics errors to not affect user experience
      print('Error firing analytics event: $e');
      // Don't rethrow - analytics should be silent and not affect core functionality
    }
  }
}
