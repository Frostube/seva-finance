import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FeatureFlagService with ChangeNotifier {
  final Box<bool> _featureFlagBox;
  static const String _aiFeatureKey = 'ai_features_enabled';

  FeatureFlagService(this._featureFlagBox) {
    // Ensure the key exists with a default value if not already set
    if (!_featureFlagBox.containsKey(_aiFeatureKey)) {
      _featureFlagBox.put(
          _aiFeatureKey, true); // AI features enabled by default
    }
  }

  bool get isAiFeaturesEnabled =>
      _featureFlagBox.get(_aiFeatureKey, defaultValue: true)!;

  void toggleAiFeatures(bool? newValue) {
    final bool enabled = newValue ?? !isAiFeaturesEnabled;
    _featureFlagBox.put(_aiFeatureKey, enabled);
    notifyListeners();
  }
}
