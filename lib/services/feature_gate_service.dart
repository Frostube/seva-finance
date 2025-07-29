import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/feature_flag.dart';
import '../models/user.dart';
import 'user_service.dart';

class FeatureGateService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final UserService _userService;
  final Box<FeatureFlag> _featureFlagBox;
  final Box<Map<String, dynamic>> _usageBox;

  List<FeatureFlag> _featureFlags = [];
  Map<String, int> _currentUsage = {};
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  FeatureGateService(this._firestore, this._userService, this._featureFlagBox,
      this._usageBox) {
    _initialLoadFuture = _initialize();

    // Listen to user changes
    _userService.addListener(_onUserChanged);
  }

  List<FeatureFlag> get featureFlags => _featureFlags;
  Map<String, int> get currentUsage => _currentUsage;
  bool get isLoading => _isLoading;
  Future<void>? get initializationComplete => _initialLoadFuture;

  void _onUserChanged() {
    // Reload usage data when user changes
    _loadUsageData();
  }

  Future<void> _initialize() async {
    await _loadFeatureFlags();
    await _loadUsageData();
  }

  Future<void> _loadFeatureFlags() async {
    try {
      debugPrint('FeatureGateService: Loading feature flags');

      // Try to load from Firestore first
      final snapshot = await _firestore.collection('featureFlags').get();

      if (snapshot.docs.isNotEmpty) {
        _featureFlags = snapshot.docs.map((doc) {
          return FeatureFlag.fromMap(doc.data());
        }).toList();

        // Cache locally
        await _featureFlagBox.clear();
        for (final flag in _featureFlags) {
          await _featureFlagBox.put(flag.key, flag);
        }

        debugPrint(
            'FeatureGateService: Loaded ${_featureFlags.length} feature flags from Firestore');
      } else {
        // Use default feature flags if none exist in Firestore
        _featureFlags = FeatureFlags.getDefaultFeatureFlags();

        // Save defaults to Firestore
        for (final flag in _featureFlags) {
          await _firestore
              .collection('featureFlags')
              .doc(flag.key)
              .set(flag.toMap());
          await _featureFlagBox.put(flag.key, flag);
        }

        debugPrint('FeatureGateService: Created default feature flags');
      }
    } catch (e) {
      debugPrint('FeatureGateService: Error loading feature flags: $e');

      // Fallback to local cache
      _featureFlags = _featureFlagBox.values.toList();

      // If no local cache, use defaults
      if (_featureFlags.isEmpty) {
        _featureFlags = FeatureFlags.getDefaultFeatureFlags();
      }
    }
  }

  Future<void> _loadUsageData() async {
    try {
      final user = _userService.currentUser;
      if (user == null) return;

      debugPrint('FeatureGateService: Loading usage data for user ${user.id}');

      // Try to load from Firestore first
      final doc = await _firestore
          .collection('users')
          .doc(user.id)
          .collection('usage')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _currentUsage = Map<String, int>.from(data);

        // Cache locally
        await _usageBox.put('current_usage', _currentUsage);

        debugPrint('FeatureGateService: Loaded usage data from Firestore');
      } else {
        // Initialize empty usage
        _currentUsage = {};
        await _saveUsageData();
      }
    } catch (e) {
      debugPrint('FeatureGateService: Error loading usage data: $e');

      // Fallback to local cache
      final cachedUsage = _usageBox.get('current_usage');
      if (cachedUsage != null) {
        _currentUsage = Map<String, int>.from(cachedUsage);
      } else {
        _currentUsage = {};
      }
    }

    // Notify listeners so UI (e.g., ProGate) can rebuild with the latest
    // user information once usage and auth state are available.
    notifyListeners();
  }

  Future<void> _saveUsageData() async {
    try {
      final user = _userService.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('usage')
          .doc('current')
          .set(_currentUsage);

      await _usageBox.put('current_usage', _currentUsage);

      debugPrint('FeatureGateService: Usage data saved');
    } catch (e) {
      debugPrint('FeatureGateService: Error saving usage data: $e');
    }
  }

  // Main method to check if a feature is accessible
  FeatureAccessResult checkFeatureAccess(String featureKey) {
    final user = _userService.currentUser;
    if (user == null) {
      return FeatureAccessResult(
        hasAccess: false,
        reason: 'User not authenticated',
      );
    }

    final featureFlag = _featureFlags.firstWhere(
      (flag) => flag.key == featureKey,
      orElse: () => FeatureFlag(
        key: featureKey,
        name: featureKey,
        description: 'Unknown feature',
        proOnly: false,
      ),
    );

    // Check if feature is disabled globally
    if (!featureFlag.isEnabled) {
      return FeatureAccessResult(
        hasAccess: false,
        reason: 'Feature is currently disabled',
      );
    }

    // Check if feature is Pro-only
    if (featureFlag.proOnly && !user.hasActiveSubscription) {
      return FeatureAccessResult(
        hasAccess: false,
        reason: 'This feature requires a Pro subscription',
        isProOnly: true,
        featureFlag: featureFlag,
      );
    }

    // Check usage limits for free users
    if (!user.hasActiveSubscription && featureFlag.freeLimit != null) {
      final currentUsageCount = _currentUsage[featureKey] ?? 0;

      if (currentUsageCount >= featureFlag.freeLimit!) {
        return FeatureAccessResult(
          hasAccess: false,
          reason: 'You have reached the free limit for this feature',
          isLimitExceeded: true,
          featureFlag: featureFlag,
          currentUsage: currentUsageCount,
          limit: featureFlag.freeLimit!,
        );
      }
    }

    // Access granted
    return FeatureAccessResult(
      hasAccess: true,
      featureFlag: featureFlag,
      currentUsage: _currentUsage[featureKey] ?? 0,
      limit: featureFlag.freeLimit,
    );
  }

  // Method to increment usage for a feature
  Future<void> incrementUsage(String featureKey) async {
    final currentCount = _currentUsage[featureKey] ?? 0;
    _currentUsage[featureKey] = currentCount + 1;

    await _saveUsageData();
    notifyListeners();

    debugPrint(
        'FeatureGateService: Incremented usage for $featureKey to ${_currentUsage[featureKey]}');
  }

  // Method to reset usage (typically called monthly)
  Future<void> resetUsage({String? resetPeriod}) async {
    final user = _userService.currentUser;
    if (user == null) return;

    debugPrint('FeatureGateService: Resetting usage for period: $resetPeriod');

    // Reset usage for features with matching reset period
    final featuresToReset = _featureFlags
        .where((flag) {
          if (resetPeriod == null) return true;
          return flag.resetPeriod == resetPeriod;
        })
        .map((flag) => flag.key)
        .toList();

    for (final featureKey in featuresToReset) {
      _currentUsage[featureKey] = 0;
    }

    await _saveUsageData();
    notifyListeners();

    debugPrint(
        'FeatureGateService: Reset usage for ${featuresToReset.length} features');
  }

  // Helper method to get usage stats
  Map<String, FeatureUsageStats> getUsageStats() {
    final user = _userService.currentUser;
    if (user == null) return {};

    final stats = <String, FeatureUsageStats>{};

    for (final flag in _featureFlags) {
      final currentUsage = _currentUsage[flag.key] ?? 0;
      final limit = flag.freeLimit;

      stats[flag.key] = FeatureUsageStats(
        featureKey: flag.key,
        featureName: flag.name,
        currentUsage: currentUsage,
        limit: limit,
        isUnlimited: user.hasActiveSubscription || limit == null,
        resetPeriod: flag.resetPeriod,
      );
    }

    return stats;
  }

  // Method to get features that are about to hit their limit
  List<String> getFeaturesNearLimit({double threshold = 0.8}) {
    final user = _userService.currentUser;
    if (user == null || user.hasActiveSubscription) return [];

    final nearLimit = <String>[];

    for (final flag in _featureFlags) {
      if (flag.freeLimit != null) {
        final currentUsage = _currentUsage[flag.key] ?? 0;
        final usagePercent = currentUsage / flag.freeLimit!;

        if (usagePercent >= threshold) {
          nearLimit.add(flag.key);
        }
      }
    }

    return nearLimit;
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserChanged);
    super.dispose();
  }
}

// Data classes for feature access results
class FeatureAccessResult {
  final bool hasAccess;
  final String reason;
  final bool isProOnly;
  final bool isLimitExceeded;
  final FeatureFlag? featureFlag;
  final int currentUsage;
  final int? limit;

  FeatureAccessResult({
    required this.hasAccess,
    this.reason = '',
    this.isProOnly = false,
    this.isLimitExceeded = false,
    this.featureFlag,
    this.currentUsage = 0,
    this.limit,
  });

  String get statusMessage {
    if (hasAccess) {
      if (limit != null) {
        return 'Usage: $currentUsage/$limit';
      }
      return 'Available';
    } else if (isProOnly) {
      return 'Requires Pro subscription';
    } else if (isLimitExceeded) {
      return 'Limit reached ($currentUsage/$limit)';
    }
    return reason;
  }
}

class FeatureUsageStats {
  final String featureKey;
  final String featureName;
  final int currentUsage;
  final int? limit;
  final bool isUnlimited;
  final String? resetPeriod;

  FeatureUsageStats({
    required this.featureKey,
    required this.featureName,
    required this.currentUsage,
    this.limit,
    required this.isUnlimited,
    this.resetPeriod,
  });

  double get usagePercent {
    if (limit == null || isUnlimited) return 0.0;
    return (currentUsage / limit!).clamp(0.0, 1.0);
  }

  bool get isNearLimit => usagePercent >= 0.8;
  bool get isAtLimit => limit != null && currentUsage >= limit!;
}
