import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/push_notification_service.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _budgetAlerts = true;
  bool _billReminders = true;
  bool _spendingAlerts = true;
  double _budgetThreshold = 0.8;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadPreferences();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final pushNotificationService =
        Provider.of<PushNotificationService>(context, listen: false);
    final prefs = await pushNotificationService.getPreferences();

    if (prefs != null && mounted) {
      setState(() {
        _budgetAlerts = prefs['budgetAlerts'] ?? true;
        _billReminders = prefs['billReminders'] ?? true;
        _spendingAlerts = prefs['spendingAlerts'] ?? true;
        _budgetThreshold = (prefs['budgetThreshold'] ?? 0.8).toDouble();
      });
    }
  }

  Future<void> _updatePreferences() async {
    setState(() => _isLoading = true);

    try {
      final pushNotificationService =
          Provider.of<PushNotificationService>(context, listen: false);
      await pushNotificationService.updatePreferences(
        budgetThreshold: _budgetThreshold,
        billReminders: _billReminders,
        budgetAlerts: _budgetAlerts,
        spendingAlerts: _spendingAlerts,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences updated'),
            backgroundColor: Color(0xFF1B4332),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preferences: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1B4332),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1B4332),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF1B4332),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    IconData? icon,
    String Function(double)? formatter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF1B4332),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatter?.call(value) ?? '${(value * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B4332),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF1B4332),
                inactiveTrackColor: const Color(0xFF1B4332).withOpacity(0.2),
                thumbColor: const Color(0xFF1B4332),
                overlayColor: const Color(0xFF1B4332).withOpacity(0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) / 0.1).round(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4332)),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Push Notifications Toggle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1B4332),
                      const Color(0xFF1B4332).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4332).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Consumer<PushNotificationService>(
                  builder: (context, pushService, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.bell_fill,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Push Notifications',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pushService.isEnabled
                                        ? 'Get notified about budget alerts and bills'
                                        : 'Enable to receive important financial alerts',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CupertinoSwitch(
                              value: pushService.isEnabled,
                              onChanged: (value) async {
                                if (value) {
                                  final success =
                                      await pushService.enableNotifications();
                                  if (!success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please allow notifications in your browser'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  await pushService.disableNotifications();
                                }
                              },
                              activeColor: Colors.white,
                              trackColor: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                        if (!pushService.isSupported) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.info_circle_fill,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Push notifications are not supported on this device',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Notification Types
              _buildSectionTitle('Notification Types'),
              _buildSettingTile(
                title: 'Budget Alerts',
                subtitle: 'Get notified when approaching budget limits',
                value: _budgetAlerts,
                onChanged: (value) {
                  setState(() => _budgetAlerts = value);
                  _updatePreferences();
                },
                icon: CupertinoIcons.chart_bar_alt_fill,
              ),
              _buildSettingTile(
                title: 'Bill Reminders',
                subtitle: 'Reminders for upcoming recurring transactions',
                value: _billReminders,
                onChanged: (value) {
                  setState(() => _billReminders = value);
                  _updatePreferences();
                },
                icon: CupertinoIcons.calendar_badge_plus,
              ),
              _buildSettingTile(
                title: 'Spending Alerts',
                subtitle: 'Alerts for unusual spending patterns',
                value: _spendingAlerts,
                onChanged: (value) {
                  setState(() => _spendingAlerts = value);
                  _updatePreferences();
                },
                icon: CupertinoIcons.exclamationmark_triangle_fill,
              ),

              // Threshold Settings
              _buildSectionTitle('Alert Thresholds'),
              _buildSliderTile(
                title: 'Budget Alert Threshold',
                subtitle:
                    'Send alert when spending reaches this percentage of budget',
                value: _budgetThreshold,
                min: 0.5,
                max: 0.95,
                onChanged: (value) {
                  setState(() => _budgetThreshold = value);
                  _updatePreferences();
                },
                icon: CupertinoIcons.percent,
                formatter: (value) => '${(value * 100).toInt()}%',
              ),

              // Test Notifications
              _buildSectionTitle('Testing'),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Consumer<PushNotificationService>(
                  builder: (context, pushService, child) {
                    return InkWell(
                      onTap: pushService.isEnabled
                          ? () => _sendTestNotification()
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: pushService.isEnabled
                                    ? const Color(0xFF1B4332).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.lab_flask,
                                color: pushService.isEnabled
                                    ? const Color(0xFF1B4332)
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Send Test Notification',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: pushService.isEnabled
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pushService.isEnabled
                                        ? 'Test your push notification settings'
                                        : 'Enable push notifications first',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: pushService.isEnabled
                                  ? Colors.grey[400]
                                  : Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);

      // Send an in-app notification as a test
      await notificationService.addActionNotification(
        title: 'Test Notification 🧪',
        message:
            'This is a test notification! Your push notifications are working correctly.',
        relatedId: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Test notification sent! Check your notifications screen.'),
            backgroundColor: Color(0xFF1B4332),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
}
