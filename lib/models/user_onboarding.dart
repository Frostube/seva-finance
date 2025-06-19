import 'package:hive/hive.dart';

part 'user_onboarding.g.dart';

@HiveType(
    typeId:
        11) // Changed to 11 to avoid conflict with AppNotification (typeId 7)
class UserOnboarding extends HiveObject {
  @HiveField(0)
  bool onboardingCompleted;

  @HiveField(1)
  DateTime? onboardingStartedAt;

  @HiveField(2)
  DateTime? onboardingCompletedAt;

  @HiveField(3)
  int currentStep;

  @HiveField(4)
  List<String> completedSteps;

  UserOnboarding({
    this.onboardingCompleted = false,
    this.onboardingStartedAt,
    this.onboardingCompletedAt,
    this.currentStep = 0,
    this.completedSteps = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'onboardingCompleted': onboardingCompleted,
      'onboardingStartedAt': onboardingStartedAt?.toIso8601String(),
      'onboardingCompletedAt': onboardingCompletedAt?.toIso8601String(),
      'currentStep': currentStep,
      'completedSteps': completedSteps,
    };
  }

  // Create from Firestore Map
  factory UserOnboarding.fromMap(Map<String, dynamic> map) {
    return UserOnboarding(
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      onboardingStartedAt: map['onboardingStartedAt'] != null
          ? DateTime.parse(map['onboardingStartedAt'])
          : null,
      onboardingCompletedAt: map['onboardingCompletedAt'] != null
          ? DateTime.parse(map['onboardingCompletedAt'])
          : null,
      currentStep: map['currentStep'] ?? 0,
      completedSteps: List<String>.from(map['completedSteps'] ?? []),
    );
  }
}
