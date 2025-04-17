import 'package:hive/hive.dart';

class BudgetService {
  static const String _budgetKey = 'monthly_budget';
  static const double _defaultBudget = 0.0;
  final Box<double> _budgetBox;

  BudgetService(this._budgetBox);

  Future<double> getMonthlyBudget() async {
    return _budgetBox.get(_budgetKey) ?? _defaultBudget;
  }

  Future<void> setMonthlyBudget(double amount) async {
    await _budgetBox.put(_budgetKey, amount);
  }
} 