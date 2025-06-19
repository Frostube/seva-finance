import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'services/storage_service.dart';
import 'services/wallet_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense.dart';
import 'models/wallet.dart';
import 'models/savings_goal.dart';
import 'models/spending_alert.dart';
import 'models/notification.dart';
import 'models/expense_category.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'firebase_options.dart';
import 'services/budget_service.dart';
import 'services/savings_goal_service.dart';
import 'services/spending_alert_service.dart';
import 'services/category_service.dart';
import 'services/ocr_settings_service.dart';
import 'services/onboarding_service.dart';
import 'models/ocr_settings.dart';
import 'models/user_onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Crashlytics (skip for web)
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters with duplicate protection
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(WalletAdapter());
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SavingsGoalAdapter());
  if (!Hive.isAdapterRegistered(4))
    Hive.registerAdapter(SpendingAlertAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(AlertTypeAdapter());
  if (!Hive.isAdapterRegistered(7))
    Hive.registerAdapter(AppNotificationAdapter());
  if (!Hive.isAdapterRegistered(6))
    Hive.registerAdapter(NotificationTypeAdapter());
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(ExpenseCategoryAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(OcrSettingsAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(OcrModeAdapter());
  if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(DateFallbackAdapter());
  if (!Hive.isAdapterRegistered(11))
    Hive.registerAdapter(UserOnboardingAdapter());

  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<double>('budget');
  await Hive.openBox<SavingsGoal>('savings_goals');
  await Hive.openBox<SpendingAlert>('spending_alerts');
  await Hive.openBox<AppNotification>('notifications');
  await Hive.openBox<ExpenseCategory>('expense_categories');
  await Hive.openBox<OcrSettings>('ocr_settings_box');
  await Hive.openBox<UserOnboarding>('user_onboarding');

  runApp(const MyApp());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase Services
        Provider<FirebaseAuth>(
          create: (_) => FirebaseAuth.instance,
        ),
        Provider<FirebaseFirestore>(
          create: (_) => FirebaseFirestore.instance,
        ),
        Provider<FirebaseStorage>(
          create: (_) => FirebaseStorage.instance,
        ),
        Provider<FirebaseMessaging>(
          create: (_) => FirebaseMessaging.instance,
        ),
        Provider<FirebaseAnalytics>(
          create: (_) => FirebaseAnalytics.instance,
        ),
        Provider<FirebaseRemoteConfig>(
          create: (_) => FirebaseRemoteConfig.instance,
        ),

        // App Services
        ChangeNotifierProvider(
          create: (_) => StorageService(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationService(
            Hive.box<AppNotification>('notifications'),
            Provider.of<FirebaseFirestore>(context, listen: false),
            Provider.of<FirebaseMessaging>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthService(
            Provider.of<FirebaseAuth>(context, listen: false),
            Provider.of<FirebaseFirestore>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CategoryService(
            Hive.box<ExpenseCategory>('expense_categories'),
            Provider.of<FirebaseFirestore>(context, listen: false),
            Hive.box<Expense>('expenses'),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => WalletService(
            Hive.box<Wallet>('wallets'),
            Provider.of<FirebaseFirestore>(context, listen: false),
            Provider.of<NotificationService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ExpenseService(
            Hive.box<Expense>('expenses'),
            Provider.of<WalletService>(context, listen: false),
            Provider.of<NotificationService>(context, listen: false),
            Provider.of<FirebaseFirestore>(context, listen: false),
            Provider.of<CategoryService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<SpendingAlertService>(
          create: (context) => SpendingAlertService(
            Hive.box<SpendingAlert>('spending_alerts'),
            Provider.of<FirebaseFirestore>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetService(
            Hive.box<double>('budget'),
          ),
        ),
        ChangeNotifierProvider<SavingsGoalService>(
          create: (context) => SavingsGoalService(
            Hive.box<SavingsGoal>('savings_goals'),
            Provider.of<FirebaseFirestore>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<OcrSettingsService>(
          create: (context) => OcrSettingsService(),
        ),
        ChangeNotifierProvider<OnboardingService>(
          create: (context) => OnboardingService(
            Hive.box<UserOnboarding>('user_onboarding'),
            Provider.of<FirebaseFirestore>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Seva Finance',
        theme: AppTheme.theme,
        home: const AuthWrapper(),
      ),
    );
  }
}
