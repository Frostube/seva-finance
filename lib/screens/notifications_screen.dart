import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all unread notifications as read when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      for (final notification in notificationService.notifications) {
        if (!notification.isRead) {
          notificationService.markAsRead(notification.id);
        }
      }
    });
  }

  Map<String, List<AppNotification>> _groupNotifications(List<AppNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final grouped = {
      'Today': <AppNotification>[],
      'This Week': <AppNotification>[],
      'Earlier': <AppNotification>[],
    };

    for (var notification in notifications) {
      final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      if (notificationDate == today) {
        grouped['Today']!.add(notification);
      } else if (notificationDate.isAfter(startOfWeek)) {
        grouped['This Week']!.add(notification);
      } else {
        grouped['Earlier']!.add(notification);
      }
    }

    return grouped;
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return CupertinoIcons.bell_fill;
      case NotificationType.goal:
        return CupertinoIcons.flag_fill;
      case NotificationType.action:
        return CupertinoIcons.info_circle_fill;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return const Color(0xFFE74C3C);
      case NotificationType.goal:
        return const Color(0xFF2ECC71);
      case NotificationType.action:
        return const Color(0xFF3498DB);
    }
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM d, h:mm a').format(notification.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(String title, List<AppNotification> notifications) {
    if (notifications.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...notifications.map((notification) => _buildNotificationItem(notification)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final notifications = notificationService.notifications;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.bell,
                      size: 48,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your notifications will appear here',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedNotifications = _groupNotifications(notifications);

          return ListView(
            children: [
              _buildNotificationSection('Today', groupedNotifications['Today']!),
              _buildNotificationSection('This Week', groupedNotifications['This Week']!),
              _buildNotificationSection('Earlier', groupedNotifications['Earlier']!),
            ],
          );
        },
      ),
    );
  }
} 