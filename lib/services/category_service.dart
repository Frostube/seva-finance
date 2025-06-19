import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for Colors
import 'package:hive/hive.dart';
import '../models/expense_category.dart';
import '../models/expense.dart'; // Added for Expense model

class CategoryService with ChangeNotifier {
  final Box<ExpenseCategory> _categoryBox;
  final FirebaseFirestore _firestore;
  final Box<Expense> _expenseBox; // Added
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  static const String uncategorizedId = 'uncategorized';
  static const String uncategorizedName = 'Uncategorized';
  // Using a placeholder icon name string, actual IconData conversion happens in UI
  static const String uncategorizedIconName = 'help_outline'; 

  CategoryService(this._categoryBox, this._firestore, this._expenseBox) { // Modified constructor
    _initialLoadFuture = _loadCategories();
  }

  List<ExpenseCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  Future<void>? get initializationComplete => _initialLoadFuture;
  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadCategories() async {
    if (_isLoading) return;
    _isLoading = true;
    
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('CategoryService: User not authenticated. Loading categories from local cache only.');
      _categories = _categoryBox.values.toList();
      await getOrCreateUncategorizedCategory(); // Ensure it exists locally too
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint('CategoryService: User $userId authenticated. Starting Firestore sync.');
      final snapshot = await _firestore.collection('users').doc(userId).collection('expenseCategories').get();
      debugPrint('CategoryService: Fetched ${snapshot.docs.length} categories from Firestore for user $userId.');
      
      final remoteCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExpenseCategory.fromJson(data); 
      }).toList();

      Map<String, ExpenseCategory> localCategoriesMap = { for (var cat in _categoryBox.values) cat.id : cat };
      Set<String> remoteCategoryIds = {};

      for (final remoteCategory in remoteCategories) {
        remoteCategoryIds.add(remoteCategory.id);
        await _categoryBox.put(remoteCategory.id, remoteCategory);
        localCategoriesMap[remoteCategory.id] = remoteCategory;
      }

      List<String> categoriesToDeleteLocally = [];
      for (final localCategoryId in localCategoriesMap.keys) {
        if (!remoteCategoryIds.contains(localCategoryId)) {
          categoriesToDeleteLocally.add(localCategoryId);
        }
      }
      for (final categoryIdToDelete in categoriesToDeleteLocally) {
        await _categoryBox.delete(categoryIdToDelete);
        localCategoriesMap.remove(categoryIdToDelete);
        debugPrint('CategoryService: Deleted category $categoryIdToDelete from local cache.');
      }
      
      _categories = localCategoriesMap.values.toList();
      debugPrint('CategoryService: Synced ${_categories.length} categories.');

    } catch (e) {
      debugPrint('Error syncing categories with Firestore: $e. Using local cache.');
      _categories = _categoryBox.values.toList();
    }
    
    await getOrCreateUncategorizedCategory(); // Ensure "Uncategorized" category exists after sync/load
    _isLoading = false;
    notifyListeners(); 
  }
  
  Future<ExpenseCategory> getOrCreateUncategorizedCategory() async {
    // Check in-memory list first
    var uncategorized = _categories.firstWhere((cat) => cat.id == uncategorizedId, orElse: () => ExpenseCategory(id: 'temp', name: 'temp', icon: 'temp')); // temp non-null for check
    if (uncategorized.id != 'temp') return uncategorized;

    // Check Hive next
    uncategorized = _categoryBox.get(uncategorizedId) ?? ExpenseCategory(id: 'temp', name: 'temp', icon: 'temp');
    if (uncategorized.id != 'temp') {
        if (!_categories.any((cat) => cat.id == uncategorizedId)) _categories.add(uncategorized);
        return uncategorized;
    }

    // Create new "Uncategorized" category
    final newUncategorized = ExpenseCategory(
        id: uncategorizedId,
        name: uncategorizedName,
        icon: uncategorizedIconName, // Store icon name string
        // colorValue: Colors.grey.value, // Removed: ExpenseCategory does not store color
    );

    try {
      if (_userId != null) {
        await _firestore.collection('users').doc(_userId).collection('expenseCategories').doc(newUncategorized.id).set(newUncategorized.toJson());
      }
      await _categoryBox.put(newUncategorized.id, newUncategorized);
      if (!_categories.any((cat) => cat.id == newUncategorized.id)) _categories.add(newUncategorized);
       debugPrint('CategoryService: Created and saved "Uncategorized" category.');
    } catch (e) {
      debugPrint('Error creating "Uncategorized" category: $e');
      // Fallback to just using the newUncategorized object locally if Firebase/Hive fails
    }
    return newUncategorized;
  }


  ExpenseCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null; 
    }
  }

  Future<void> addCategory(ExpenseCategory category) async {
    if (_userId == null) throw Exception('User not authenticated to add category');
    if (category.id == uncategorizedId) throw Exception('Cannot add a category with the reserved ID "uncategorized"');
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(_userId).collection('expenseCategories').doc(category.id).set(category.toJson());
      debugPrint('CategoryService: Added category ${category.id} to Firestore.');
      
      if (!_categories.any((c) => c.id == category.id)) {
        _categories.add(category);
      } else {
        final index = _categories.indexWhere((c) => c.id == category.id);
        _categories[index] = category;
      }
      await _categoryBox.put(category.id, category);
      
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    if (_userId == null) throw Exception('User not authenticated to update category');
    if (category.id == uncategorizedId && category.name != uncategorizedName) {
      // Allow updating icon/color of Uncategorized, but not its ID or fundamental name
      debugPrint("CategoryService: Attempting to update Uncategorized category. Only icon/color changes are typically allowed.");
    }

    _isLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic> categoryData = category.toJson();
      await _firestore.collection('users').doc(_userId).collection('expenseCategories').doc(category.id).update(categoryData);
      debugPrint('CategoryService: Updated category ${category.id} in Firestore.');
      
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      } else {
         _categories.add(category); // Should not happen if update is for existing
      }
      await _categoryBox.put(category.id, category);
      
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_userId == null) throw Exception('User not authenticated to delete category');
    if (categoryId == uncategorizedId) {
      debugPrint('CategoryService: Cannot delete the default "Uncategorized" category.');
      return; 
    }

    _isLoading = true;
    notifyListeners();

    try {
      final ExpenseCategory uncategorized = await getOrCreateUncategorizedCategory();

      // Update expenses in Firestore
      final expenseQuerySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in expenseQuerySnapshot.docs) {
        batch.update(doc.reference, {'categoryId': uncategorized.id});
      }
      await batch.commit();
      debugPrint('CategoryService: Updated ${expenseQuerySnapshot.docs.length} expenses in Firestore to category "${uncategorized.name}".');

      // Update expenses in Hive
      final List<String> keysToUpdate = [];
      final List<Expense> valuesToUpdate = [];
      for (var key in _expenseBox.keys) {
          final expense = _expenseBox.get(key);
          if (expense != null && expense.categoryId == categoryId) {
              keysToUpdate.add(key as String);
              valuesToUpdate.add(Expense(
                  id: expense.id,
                  amount: expense.amount,
                  categoryId: uncategorized.id,
                  date: expense.date,
                  note: expense.note,
              ));
          }
      }
      for (int i = 0; i < keysToUpdate.length; i++) {
          await _expenseBox.put(keysToUpdate[i], valuesToUpdate[i]);
      }
      debugPrint('CategoryService: Updated ${keysToUpdate.length} expenses in Hive to category "${uncategorized.name}".');


      // Delete the category itself
      await _firestore.collection('users').doc(_userId).collection('expenseCategories').doc(categoryId).delete();
      debugPrint('CategoryService: Deleted category $categoryId from Firestore.');
      
      _categories.removeWhere((c) => c.id == categoryId);
      await _categoryBox.delete(categoryId);
      debugPrint('CategoryService: Deleted category $categoryId from local stores.');

    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getCategoryNameById(String categoryId, {String defaultName = 'Unknown'}) {
    final category = getCategoryById(categoryId);
    return category?.name ?? (categoryId == uncategorizedId ? uncategorizedName : defaultName);
  }

  String getCategoryIconStringById(String categoryId, {String defaultIcon = 'help_outline'}) {
    final category = getCategoryById(categoryId);
    return category?.icon ?? (categoryId == uncategorizedId ? uncategorizedIconName : defaultIcon);
  }
} 