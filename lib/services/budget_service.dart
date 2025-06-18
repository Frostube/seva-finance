import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class BudgetService with ChangeNotifier {
  static const String _budgetKey = 'monthly_budget';
  static const double _defaultBudget = 0.0;
  final Box<double> _budgetBox;

  BudgetService(this._budgetBox);

  Future<double> getMonthlyBudget() async {
    return _budgetBox.get(_budgetKey) ?? _defaultBudget;
  }

  Future<void> setMonthlyBudget(double amount) async {
    await _budgetBox.put(_budgetKey, amount);
    notifyListeners();
  }
} 