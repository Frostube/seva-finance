import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';

class StorageService extends ChangeNotifier {
  static const String expensesBox = 'expenses';
  static const String categoriesBox = 'categories';

  // Initialize Hive and register adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // Note: Adapters are now registered in main.dart to avoid duplicates

    // Open boxes
    await Hive.openBox<Expense>(expensesBox);
    await Hive.openBox<String>(categoriesBox);
  }

  // Expenses operations
  Future<void> saveExpense(Expense expense) async {
    final box = Hive.box<Expense>(expensesBox);
    await box.put(expense.id, expense);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    final box = Hive.box<Expense>(expensesBox);
    await box.delete(id);
    notifyListeners();
  }

  Future<List<Expense>> getAllExpenses() async {
    final box = Hive.box<Expense>(expensesBox);
    return box.values.toList();
  }

  Future<void> updateExpense(Expense expense) async {
    await saveExpense(expense); // In Hive, put() handles both insert and update
    notifyListeners();
  }

  // Categories operations
  Future<void> saveCategory(String category) async {
    final box = Hive.box<String>(categoriesBox);
    if (!await hasCategory(category)) {
      await box.add(category);
      notifyListeners();
    }
  }

  Future<bool> hasCategory(String category) async {
    final box = Hive.box<String>(categoriesBox);
    return box.values.contains(category);
  }

  Future<List<String>> getAllCategories() async {
    final box = Hive.box<String>(categoriesBox);
    return box.values.toList();
  }

  // Initialize default categories if none exist
  Future<void> initializeDefaultCategories() async {
    final defaultCategories = [
      'Groceries',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills',
      'Health',
      'Other'
    ];

    final box = Hive.box<String>(categoriesBox);
    if (box.isEmpty) {
      for (final category in defaultCategories) {
        await saveCategory(category);
      }
    }
  }
}
