import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/ocr_settings.dart';

class OcrSettingsService with ChangeNotifier {
  static const String _boxName = 'ocr_settings_box';
  static const String _settingsKey = 'user_ocr_settings';

  late Box<OcrSettings> _box;
  OcrSettings _currentSettings = OcrSettings(); // Initialize with defaults

  OcrSettings get settings => _currentSettings;

  OcrSettingsService() {
    _init();
  }

  Future<void> _init() async {
    if (!Hive.isAdapterRegistered(OcrSettingsAdapter().typeId)) {
      Hive.registerAdapter(OcrSettingsAdapter());
    }
    _box = await Hive.openBox<OcrSettings>(_boxName);
    _loadSettings();
  }

  void _loadSettings() {
    final storedSettings = _box.get(_settingsKey);
    if (storedSettings != null) {
      _currentSettings = storedSettings;
    } else {
      // If no settings stored, save the default ones
      _box.put(_settingsKey, _currentSettings);
    }
    notifyListeners();
  }

  Future<void> updateSettings(OcrSettings newSettings) async {
    _currentSettings = newSettings;
    await _box.put(_settingsKey, _currentSettings);
    notifyListeners();
  }

  Future<void> resetToDefaultSettings() async {
    _currentSettings.resetToDefaults();
    await _box.put(_settingsKey, _currentSettings);
    notifyListeners();
  }

  // Helper to ensure service is initialized before use in UI if needed
  Future<void> ensureInitialized() async {
    if (!_box.isOpen) {
      await _init();
    }
  }
} 