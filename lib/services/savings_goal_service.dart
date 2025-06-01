import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/savings_goal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavingsGoalService with ChangeNotifier {
  final Box<SavingsGoal> _savingsGoalBox;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  SavingsGoalService(this._savingsGoalBox, this._firestore) {
    _initialLoadFuture = _loadGoals();
  }

  List<SavingsGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  Future<void>? get initializationComplete => _initialLoadFuture;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadGoals() async {
    if (_isLoading) return;
    _isLoading = true;

    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint('SavingsGoalService: User not authenticated. Loading goals from local cache only.');
      _goals = _savingsGoalBox.values.toList();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint('SavingsGoalService: User $currentUserId authenticated. Syncing savings goals.');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savingsGoals')
          .get();
      debugPrint('SavingsGoalService: Fetched ${snapshot.docs.length} goals from Firestore for user $currentUserId.');
      
      final remoteGoals = snapshot.docs.map((doc) {
        return SavingsGoal.fromJson(doc.data(), doc.id);
      }).toList();

      Map<String, SavingsGoal> localGoalsMap = { for (var g in _savingsGoalBox.values) g.id : g };
      Set<String> remoteGoalIds = {};

      for (final remoteGoal in remoteGoals) {
        remoteGoalIds.add(remoteGoal.id);
        await _savingsGoalBox.put(remoteGoal.id, remoteGoal);
        localGoalsMap[remoteGoal.id] = remoteGoal;
      }

      List<String> goalsToDeleteLocally = [];
      for (final localGoalId in localGoalsMap.keys) {
        if (!remoteGoalIds.contains(localGoalId)) {
          goalsToDeleteLocally.add(localGoalId);
        }
      }
      for (final goalIdToDelete in goalsToDeleteLocally) {
        await _savingsGoalBox.delete(goalIdToDelete);
        localGoalsMap.remove(goalIdToDelete);
        debugPrint('SavingsGoalService: Deleted goal $goalIdToDelete from local cache.');
      }
      
      _goals = localGoalsMap.values.toList();
      // Optional: sort goals if needed, e.g., by createdAt or targetDate
      // _goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      debugPrint('SavingsGoalService: Synced ${_goals.length} goals.');

    } catch (e) {
      debugPrint('Error syncing savings goals with Firestore: $e. Using local cache as fallback.');
      _goals = _savingsGoalBox.values.toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savingsGoals')
          .doc(goal.id); // Assuming goal.id is pre-generated

      await docRef.set(goal.toJson());
      debugPrint('SavingsGoalService: Goal ${goal.id} added to Firestore for user $currentUserId.');

      _goals.add(goal);
      await _savingsGoalBox.put(goal.id, goal);
      // Consider re-sorting if order matters
    } catch (e) {
      debugPrint('Error adding savings goal: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savingsGoals')
          .doc(goal.id)
          .update(goal.toJson());
      debugPrint('SavingsGoalService: Goal ${goal.id} updated in Firestore for user $currentUserId.');

      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        await _savingsGoalBox.put(goal.id, goal);
        // Consider re-sorting if relevant fields changed
      }
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('savingsGoals')
          .doc(id)
          .delete();
      debugPrint('SavingsGoalService: Goal $id deleted from Firestore for user $currentUserId.');

      _goals.removeWhere((g) => g.id == id);
      await _savingsGoalBox.delete(id);
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 