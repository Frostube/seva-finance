import 'package:hive/hive.dart';
import '../models/savings_goal.dart';
import '../models/spending_alert.dart';

class SavingsService {
  final Box<SavingsGoal> _savingsBox;
  final Box<SpendingAlert> _alertsBox;

  SavingsService(this._savingsBox, this._alertsBox);

  // Savings Goals
  List<SavingsGoal> getSavingsGoals(String walletId) {
    return _savingsBox.values
        .where((goal) => goal.walletId == walletId)
        .toList();
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _savingsBox.put(goal.id, goal);
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await goal.save();
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    await _savingsBox.delete(goalId);
  }

  // Spending Alerts
  List<SpendingAlert> getSpendingAlerts(String walletId) {
    return _alertsBox.values
        .where((alert) => alert.walletId == walletId)
        .toList();
  }

  Future<void> addSpendingAlert(SpendingAlert alert) async {
    await _alertsBox.put(alert.id, alert);
  }

  Future<void> updateSpendingAlert(SpendingAlert alert) async {
    await alert.save();
  }

  Future<void> deleteSpendingAlert(String alertId) async {
    await _alertsBox.delete(alertId);
  }
} 