import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'services/storage_service.dart';
import 'services/wallet_service.dart';
import 'services/savings_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense.dart';
import 'models/wallet.dart';
import 'models/savings_goal.dart';
import 'models/spending_alert.dart';
import 'models/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(SavingsGoalAdapter());
  Hive.registerAdapter(SpendingAlertAdapter());
  Hive.registerAdapter(AlertTypeAdapter());
  Hive.registerAdapter(NotificationTypeAdapter());
  Hive.registerAdapter(AppNotificationAdapter());

  // Open Hive boxes
  await Hive.openBox<double>('budget');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<SavingsGoal>('savings_goals');
  await Hive.openBox<SpendingAlert>('spending_alerts');
  await Hive.openBox<bool>('notifications');
  await Hive.openBox<AppNotification>('app_notifications');

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>(
          create: (_) => StorageService(),
          lazy: false,
        ),
        ChangeNotifierProvider<WalletService>(
          create: (_) => WalletService(
            Hive.box<Wallet>('wallets'),
            Provider.of<NotificationService>(_, listen: false),
          ),
          lazy: false,
        ),
        Provider<SavingsService>(
          create: (_) => SavingsService(
            Hive.box<SavingsGoal>('savings_goals'),
            Hive.box<SpendingAlert>('spending_alerts'),
          ),
          lazy: false,
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(
            Hive.box<bool>('notifications'),
            Hive.box<AppNotification>('app_notifications'),
          ),
          lazy: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seva Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const WelcomeScreen(),
    );
  }
}
