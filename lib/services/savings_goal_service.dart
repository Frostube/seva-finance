import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/savings_goal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalService with ChangeNotifier {
  final Box<SavingsGoal> _savingsGoalBox;
  final FirebaseFirestore _firestore;

  SavingsGoalService(this._savingsGoalBox, this._firestore);

  List<SavingsGoal> get goals => _savingsGoalBox.values.toList();

  Future<void> addGoal(SavingsGoal goal) async {
    await _savingsGoalBox.put(goal.id, goal);
    notifyListeners();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await _savingsGoalBox.put(goal.id, goal);
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await _savingsGoalBox.delete(id);
    notifyListeners();
  }
} 