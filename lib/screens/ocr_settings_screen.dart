import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ocr_settings.dart';
import '../services/ocr_settings_service.dart';

class OcrSettingsScreen extends StatefulWidget {
  const OcrSettingsScreen({super.key});

  @override
  State<OcrSettingsScreen> createState() => _OcrSettingsScreenState();
}

class _OcrSettingsScreenState extends State<OcrSettingsScreen> {
  late OcrSettingsService _settingsService;
  late OcrSettings _tempSettings;
  bool _isLoading = true;

  // Define your list of document types here
  final List<String> _documentTypes = [
    'Other', 'Groceries', 'Restaurant', 'Pharmacy', 'Travel', 'Utilities'
  ];

  @override
  void initState() {
    super.initState();
    _settingsService = Provider.of<OcrSettingsService>(context, listen: false);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.ensureInitialized(); // Make sure service box is open
    setState(() {
      _tempSettings = _settingsService.settings.copyWith(); // Work on a copy
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settingsService.updateSettings(_tempSettings);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OCR Settings Saved', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1B4332),
        ),
      );
    }
  }

  Future<void> _restoreDefaults() async {
    setState(() {
      _tempSettings.resetToDefaults();
    });
    // Optionally, immediately save after reset or let user press Done
    // await _settingsService.resetToDefaultSettings(); 
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('OCR Settings', style: GoogleFonts.inter())),
        body: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for the settings screen
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: Text('OCR Settings', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                color: const Color(0xFF1B4332),
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildSectionTitle('General'),
          _buildSettingsCard([
            _buildDropdownSetting(
              title: 'Document Type',
              value: _tempSettings.documentType,
              items: _documentTypes,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _tempSettings.documentType = newValue;
                  });
                }
              },
              summary: 'Helps categorize expenses. May improve OCR accuracy.',
            ),
            _buildSwitchSetting(
              title: 'Auto-Crop Receipt',
              value: _tempSettings.autoCrop,
              onChanged: (bool value) {
                setState(() {
                  _tempSettings.autoCrop = value;
                });
              },
              summary: 'Automatically detect receipt edges. Manual crop coming soon if disabled.',
            ),
            _buildSegmentedControlSetting<OcrMode>(
              title: 'OCR Mode',
              groupValue: _tempSettings.ocrMode,
              children: const {
                OcrMode.preview: Text('Preview First', style: TextStyle(fontSize: 13)),
                OcrMode.autoSubmit: Text('Auto-Save', style: TextStyle(fontSize: 13)),
              },
              onValueChanged: (OcrMode? value) {
                if (value != null) {
                  setState(() {
                    _tempSettings.ocrMode = value;
                  });
                }
              },
              summary: 'Review details before saving, or save automatically after scan.',
            ),
            _buildSegmentedControlSetting<DateFallback>(
              title: 'Date Fallback (if OCR fails)',
              groupValue: _tempSettings.dateFallback,
              children: const {
                DateFallback.today: Text('Use Today', style: TextStyle(fontSize: 13)),
                DateFallback.askUser: Text('Ask Me', style: TextStyle(fontSize: 13)),
              },
              onValueChanged: (DateFallback? value) {
                if (value != null) {
                  setState(() {
                    _tempSettings.dateFallback = value;
                  });
                }
              },
              summary: 'Action if receipt date is unreadable.',
            ),
          ]),
          _buildSectionTitle('Advanced Image Processing'),
          _buildSettingsCard([
            _buildSliderSetting(
              title: 'Grayscale Threshold',
              value: _tempSettings.grayscaleThreshold.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: _tempSettings.grayscaleThreshold.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _tempSettings.grayscaleThreshold = value.round();
                });
              },
              summary: 'Adjust for better text on faded receipts (0-100).',
            ),
            _buildSliderSetting(
              title: 'Brightness/Contrast',
              value: _tempSettings.brightnessContrast.toDouble(),
              min: -50,
              max: 50,
              divisions: 100,
              label: _tempSettings.brightnessContrast.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _tempSettings.brightnessContrast = value.round();
                });
              },
              summary: 'Adjust image brightness and contrast (-50 to +50).',
            ),
          ]),
          const SizedBox(height: 30),
          CupertinoButton(
            color: CupertinoColors.destructiveRed,
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (dialogContext) => CupertinoAlertDialog(
                  title: const Text('Restore Defaults?'),
                  content: const Text(
                      'This will reset all OCR settings to their original values.'),
                  actions: <Widget>[
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Restore'),
                      onPressed: () {
                        _restoreDefaults();
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
              );
            },
            child: Text('Restore Default Settings', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget widget = entry.value;
          return Column(
            children: [
              widget,
              if (idx < children.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String summary,
  }) {
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(fontSize: 16)),
      subtitle: Text(summary, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: GoogleFonts.inter(fontSize: 15)),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(), // Hide default underline
        style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary)
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String summary,
  }) {
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(fontSize: 16)),
      subtitle: Text(summary, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1B4332),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildSegmentedControlSetting<T extends Object>({
    required String title,
    required T groupValue,
    required Map<T, Widget> children,
    required ValueChanged<T?> onValueChanged,
    required String summary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16)),
          const SizedBox(height: 4),
          Text(summary, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<T>(
              groupValue: groupValue,
              children: children,
              onValueChanged: onValueChanged,
              thumbColor: const Color(0xFF1B4332),
              backgroundColor: Colors.grey[200]!,
              padding: const EdgeInsets.all(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required String summary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16)),
          const SizedBox(height: 4),
          Text(summary, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          Slider.adaptive(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
            activeColor: const Color(0xFF1B4332),
            inactiveColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
} 