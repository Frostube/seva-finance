import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'services/savings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
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
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(SavingsGoalAdapter());
  Hive.registerAdapter(SpendingAlertAdapter());
  Hive.registerAdapter(AlertTypeAdapter());
  Hive.registerAdapter(AppNotificationAdapter());
  Hive.registerAdapter(NotificationTypeAdapter());
  
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<double>('budget');
  await Hive.openBox<SavingsGoal>('savings_goals');
  await Hive.openBox<SpendingAlert>('spending_alerts');
  await Hive.openBox<AppNotification>('notifications');
  
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
          create: (_) => NotificationService(
            Hive.box<AppNotification>('notifications'),
            Provider.of<FirebaseFirestore>(_, listen: false),
            Provider.of<FirebaseMessaging>(_, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletService(
            Hive.box<Wallet>('wallets'),
            Provider.of<FirebaseFirestore>(_, listen: false),
            Provider.of<FirebaseStorage>(_, listen: false),
            Provider.of<NotificationService>(_, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseService(
            Provider.of<StorageService>(_, listen: false),
            Hive.box<double>('budget'),
            Hive.box<Expense>('expenses'),
            Provider.of<WalletService>(_, listen: false),
            Provider.of<NotificationService>(_, listen: false),
            Provider.of<FirebaseFirestore>(_, listen: false),
            Provider.of<FirebaseStorage>(_, listen: false),
          ),
        ), 
        Provider(
          create: (_) => SavingsService(
            Hive.box<SavingsGoal>('savings_goals'),
            Hive.box<SpendingAlert>('spending_alerts'),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetService(
            Hive.box<double>('budget'),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SavingsGoalService(
            Hive.box<SavingsGoal>('savings_goals'),
            Provider.of<FirebaseFirestore>(_, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthService(
            Provider.of<FirebaseAuth>(_, listen: false),
            Provider.of<FirebaseFirestore>(_, listen: false),
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
