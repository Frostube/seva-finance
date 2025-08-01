import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp

part 'notification.g.dart';

@HiveType(typeId: 6)
enum NotificationType {
  @HiveField(0)
  alert,
  @HiveField(1)
  goal,
  @HiveField(2)
  action
}

@HiveType(typeId: 7)
class AppNotification extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final NotificationType type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  bool isRead;

  @HiveField(6)
  final String? relatedId; // ID of related alert/goal/wallet

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    DateTime? timestamp,
    this.isRead = false,
    this.relatedId,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.action, // Default type if parsing fails
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      // Handle Firestore Timestamp or ISO8601 String for timestamp
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      relatedId: json['relatedId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(), // Store enum as string
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp), // Convert DateTime to Firestore Timestamp
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }

  factory AppNotification.fromAlert({
    required String alertId,
    required String title,
    required String message,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.alert,
      title: title,
      message: message,
      relatedId: alertId,
    );
  }

  factory AppNotification.fromGoal({
    required String goalId,
    required String title,
    required String message,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.goal,
      title: title,
      message: message,
      relatedId: goalId,
    );
  }

  factory AppNotification.fromAction({
    required String title,
    required String message,
    String? relatedId,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.action,
      title: title,
      message: message,
      relatedId: relatedId,
    );
  }
} 