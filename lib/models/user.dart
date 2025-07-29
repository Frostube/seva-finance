import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

part 'user.g.dart';

@HiveType(typeId: 20)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? username;

  @HiveField(4)
  final DateTime? createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  // ProPlan fields
  @HiveField(6)
  final DateTime? trialStart;

  @HiveField(7)
  final bool isPro;

  @HiveField(8)
  final bool hasPaid;

  @HiveField(9)
  final int scanCountThisMonth;

  @HiveField(10)
  final String? stripeCustomerId;

  @HiveField(11)
  final String? stripeSubscriptionId;

  @HiveField(12)
  final DateTime? subscriptionStart;

  @HiveField(13)
  final DateTime? subscriptionEnd;

  @HiveField(14)
  final String? subscriptionStatus; // active, canceled, past_due, etc.

  @HiveField(15)
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.createdAt,
    this.updatedAt,
    this.trialStart,
    this.isPro = false,
    this.hasPaid = false,
    this.scanCountThisMonth = 0,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.subscriptionStatus,
    this.phone,
  });

  // Helper methods
  bool get isTrialActive {
    if (trialStart == null) return false;
    final now = DateTime.now();
    final trialEnd = trialStart!.add(const Duration(days: 14));
    return now.isBefore(trialEnd) && !hasPaid;
  }

  int get trialDaysRemaining {
    if (trialStart == null) return 0;
    final now = DateTime.now();
    final trialEnd = trialStart!.add(const Duration(days: 14));
    if (now.isAfter(trialEnd)) return 0;
    return trialEnd.difference(now).inDays;
  }

  bool get isTrialExpired {
    if (trialStart == null) return false;
    final now = DateTime.now();
    final trialEnd = trialStart!.add(const Duration(days: 14));
    return now.isAfter(trialEnd) && !hasPaid;
  }

  bool get hasActiveSubscription {
    return isPro && (isTrialActive || hasPaid);
  }

  String get planStatus {
    if (isPro && hasPaid) return 'Pro';
    if (isPro && isTrialActive) return 'Pro Trial';
    if (isPro && isTrialExpired) return 'Trial Expired';
    return 'Free';
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'trialStart': trialStart?.toIso8601String(),
      'isPro': isPro,
      'hasPaid': hasPaid,
      'scanCountThisMonth': scanCountThisMonth,
      'stripeCustomerId': stripeCustomerId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'subscriptionStart': subscriptionStart?.toIso8601String(),
      'subscriptionEnd': subscriptionEnd?.toIso8601String(),
      'subscriptionStatus': subscriptionStatus,
      'phone': phone,
    };
  }

  // Create from Firestore Map
  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      trialStart:
          map['trialStart'] != null ? DateTime.parse(map['trialStart']) : null,
      isPro: map['isPro'] ?? false,
      hasPaid: map['hasPaid'] ?? false,
      scanCountThisMonth: map['scanCountThisMonth'] ?? 0,
      stripeCustomerId: map['stripeCustomerId'],
      stripeSubscriptionId: map['stripeSubscriptionId'],
      subscriptionStart: map['subscriptionStart'] != null
          ? DateTime.parse(map['subscriptionStart'])
          : null,
      subscriptionEnd: map['subscriptionEnd'] != null
          ? DateTime.parse(map['subscriptionEnd'])
          : null,
      subscriptionStatus: map['subscriptionStatus'],
      phone: map['phone'],
    );
  }

  // Create from Firebase Auth User
  factory User.fromFirebaseUser(
    firebase_auth.User firebaseUser, {
    DateTime? trialStart,
    bool isPro = false,
    bool hasPaid = false,
    int scanCountThisMonth = 0,
  }) {
    return User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      createdAt: firebaseUser.metadata.creationTime,
      trialStart: trialStart,
      isPro: isPro,
      hasPaid: hasPaid,
      scanCountThisMonth: scanCountThisMonth,
    );
  }

  // Copy with method for updates
  User copyWith({
    String? name,
    String? email,
    String? username,
    DateTime? updatedAt,
    DateTime? trialStart,
    bool? isPro,
    bool? hasPaid,
    int? scanCountThisMonth,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    String? subscriptionStatus,
    String? phone,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trialStart: trialStart ?? this.trialStart,
      isPro: isPro ?? this.isPro,
      hasPaid: hasPaid ?? this.hasPaid,
      scanCountThisMonth: scanCountThisMonth ?? this.scanCountThisMonth,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isPro: $isPro, planStatus: $planStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
