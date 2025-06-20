import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_transaction.dart';
import '../models/expense.dart';

class RecurringTransactionService {
  static const String _boxName = 'recurring_transactions';
  static const String _collectionName = 'recurringTransactions';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Box<RecurringTransaction>? _box;

  // Initialize Hive box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<RecurringTransaction>(_boxName);
    } else {
      _box = Hive.box<RecurringTransaction>(_boxName);
    }
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Create a new recurring transaction
  Future<RecurringTransaction> createRecurringTransaction(
      RecurringTransaction recurringTransaction) async {
    await init();

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Save to Firestore
      final docRef =
          _firestore.collection(_collectionName).doc(recurringTransaction.id);
      final data = recurringTransaction.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['nextOccurrence'] =
          Timestamp.fromDate(recurringTransaction.nextOccurrence);
      data['startDate'] = Timestamp.fromDate(recurringTransaction.startDate);
      if (recurringTransaction.endDate != null) {
        data['endDate'] = Timestamp.fromDate(recurringTransaction.endDate!);
      }

      await docRef.set(data);

      // Save to local Hive
      await _box!.put(recurringTransaction.id, recurringTransaction);

      return recurringTransaction;
    } catch (e) {
      throw Exception('Failed to create recurring transaction: $e');
    }
  }

  // Get all recurring transactions for current user
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    await init();

    if (_currentUserId == null) {
      return [];
    }

    try {
      // Try to get from Firestore first
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('createdBy', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final transactions = <RecurringTransaction>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Convert Firestore timestamps to DateTime
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['nextOccurrence'] is Timestamp) {
          data['nextOccurrence'] =
              (data['nextOccurrence'] as Timestamp).toDate().toIso8601String();
        }
        if (data['startDate'] is Timestamp) {
          data['startDate'] =
              (data['startDate'] as Timestamp).toDate().toIso8601String();
        }
        if (data['endDate'] is Timestamp) {
          data['endDate'] =
              (data['endDate'] as Timestamp).toDate().toIso8601String();
        }

        final transaction = RecurringTransaction.fromJson(data);
        transactions.add(transaction);

        // Update local cache
        await _box!.put(transaction.id, transaction);
      }

      return transactions;
    } catch (e) {
      // Fallback to local data
      print('Failed to fetch from Firestore, using local data: $e');
      return _box!.values.where((t) => t.createdBy == _currentUserId).toList();
    }
  }

  // Get active recurring transactions that are due for processing
  Future<List<RecurringTransaction>> getDueRecurringTransactions() async {
    final allTransactions = await getRecurringTransactions();
    return allTransactions.where((transaction) => transaction.isDue()).toList();
  }

  // Update a recurring transaction
  Future<RecurringTransaction> updateRecurringTransaction(
      RecurringTransaction recurringTransaction) async {
    await init();

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Update in Firestore
      final docRef =
          _firestore.collection(_collectionName).doc(recurringTransaction.id);
      final data = recurringTransaction.toJson();
      data['nextOccurrence'] =
          Timestamp.fromDate(recurringTransaction.nextOccurrence);
      data['startDate'] = Timestamp.fromDate(recurringTransaction.startDate);
      if (recurringTransaction.endDate != null) {
        data['endDate'] = Timestamp.fromDate(recurringTransaction.endDate!);
      }

      await docRef.update(data);

      // Update local cache
      await _box!.put(recurringTransaction.id, recurringTransaction);

      return recurringTransaction;
    } catch (e) {
      throw Exception('Failed to update recurring transaction: $e');
    }
  }

  // Delete a recurring transaction
  Future<void> deleteRecurringTransaction(String id) async {
    await init();

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Delete from Firestore
      await _firestore.collection(_collectionName).doc(id).delete();

      // Delete from local cache
      await _box!.delete(id);
    } catch (e) {
      throw Exception('Failed to delete recurring transaction: $e');
    }
  }

  // Pause/Resume a recurring transaction
  Future<RecurringTransaction> toggleRecurringTransaction(String id) async {
    await init();

    final transaction = _box!.get(id);
    if (transaction == null) {
      throw Exception('Recurring transaction not found');
    }

    final updatedTransaction =
        transaction.copyWith(isActive: !transaction.isActive);
    return await updateRecurringTransaction(updatedTransaction);
  }

  // Process due recurring transactions (this would typically be called by a Cloud Function)
  Future<List<Expense>> processRecurringTransactions() async {
    final dueTransactions = await getDueRecurringTransactions();
    final processedExpenses = <Expense>[];

    for (final recurringTransaction in dueTransactions) {
      try {
        // Create a regular expense from the recurring transaction
        final expense = Expense(
          id: 'recurring_${recurringTransaction.id}_${DateTime.now().millisecondsSinceEpoch}',
          amount: recurringTransaction.amount,
          categoryId: recurringTransaction.categoryId,
          date: recurringTransaction.nextOccurrence,
          note: 'Recurring: ${recurringTransaction.name}',
          walletId: recurringTransaction.walletId,
        );

        // Save the expense to Firestore
        if (_currentUserId != null) {
          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('expenses')
              .doc(expense.id)
              .set(expense.toJson());
        }
        processedExpenses.add(expense);

        // Update the next occurrence
        final nextOccurrence = recurringTransaction.calculateNextOccurrence();
        final updatedRecurring = recurringTransaction.copyWith(
          nextOccurrence: nextOccurrence,
        );

        await updateRecurringTransaction(updatedRecurring);

        print('Processed recurring transaction: ${recurringTransaction.name}');
      } catch (e) {
        print(
            'Failed to process recurring transaction ${recurringTransaction.id}: $e');
      }
    }

    return processedExpenses;
  }

  // Get recurring transaction by ID
  Future<RecurringTransaction?> getRecurringTransactionById(String id) async {
    await init();

    // Try local first
    final localTransaction = _box!.get(id);
    if (localTransaction != null) {
      return localTransaction;
    }

    // Try Firestore
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;

        // Convert Firestore timestamps
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['nextOccurrence'] is Timestamp) {
          data['nextOccurrence'] =
              (data['nextOccurrence'] as Timestamp).toDate().toIso8601String();
        }
        if (data['startDate'] is Timestamp) {
          data['startDate'] =
              (data['startDate'] as Timestamp).toDate().toIso8601String();
        }
        if (data['endDate'] is Timestamp) {
          data['endDate'] =
              (data['endDate'] as Timestamp).toDate().toIso8601String();
        }

        final transaction = RecurringTransaction.fromJson(data);

        // Cache locally
        await _box!.put(id, transaction);

        return transaction;
      }
    } catch (e) {
      print('Failed to fetch recurring transaction from Firestore: $e');
    }

    return null;
  }

  // Clear all local data (useful for logout)
  Future<void> clearLocalData() async {
    await init();
    await _box!.clear();
  }

  // Sync local data with Firestore
  Future<void> syncWithFirestore() async {
    if (_currentUserId == null) return;

    try {
      await getRecurringTransactions(); // This will sync data
    } catch (e) {
      print('Failed to sync recurring transactions: $e');
    }
  }
}
