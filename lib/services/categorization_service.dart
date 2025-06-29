import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_category.dart';
import '../models/expense.dart';
import 'category_service.dart';
import 'expense_service.dart';

class CategorySuggestion {
  final String categoryId;
  final String categoryName;
  final List<String> suggestedTags;
  final double confidence;

  CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.suggestedTags,
    required this.confidence,
  });
}

class CategorizationService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CategoryService _categoryService;
  final ExpenseService _expenseService;

  // Cache for user's historical patterns
  Map<String, Map<String, int>> _userPatterns = {};
  bool _patternsLoaded = false;

  CategorizationService(
    this._firestore,
    this._auth,
    this._categoryService,
    this._expenseService,
  );

  Future<void> _loadUserPatterns() async {
    if (_patternsLoaded) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Load user's expense history to build patterns
      final expenses = _expenseService.getExpensesByDateRange(
        DateTime.now().subtract(const Duration(days: 90)), // Last 3 months
        DateTime.now(),
      );

      _userPatterns.clear();

      for (final expense in expenses) {
        if (expense.note != null && expense.note!.isNotEmpty) {
          final words = _extractKeywords(expense.note!.toLowerCase());
          final categoryId = expense.categoryId;

          for (final word in words) {
            _userPatterns[word] ??= {};
            _userPatterns[word]![categoryId] =
                (_userPatterns[word]![categoryId] ?? 0) + 1;
          }
        }
      }

      _patternsLoaded = true;
    } catch (e) {
      debugPrint('Error loading user patterns: $e');
    }
  }

  List<String> _extractKeywords(String text) {
    // Remove common words and extract meaningful keywords
    final commonWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'up',
      'about',
      'into',
      'over',
      'after'
    };

    return text
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(' ')
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .toList();
  }

  Future<List<CategorySuggestion>> predictCategory(String description) async {
    if (description.trim().isEmpty) return [];

    await _loadUserPatterns();

    final suggestions = <CategorySuggestion>[];
    final categories = _categoryService.categories;
    final keywords = _extractKeywords(description.toLowerCase());

    // Rule-based suggestions with keyword matching
    final ruleSuggestions =
        _getRuleBasedSuggestions(description.toLowerCase(), categories);
    suggestions.addAll(ruleSuggestions);

    // User pattern-based suggestions
    final patternSuggestions =
        _getPatternBasedSuggestions(keywords, categories);
    suggestions.addAll(patternSuggestions);

    // Remove duplicates and sort by confidence
    final uniqueSuggestions = <String, CategorySuggestion>{};
    for (final suggestion in suggestions) {
      final existing = uniqueSuggestions[suggestion.categoryId];
      if (existing == null || existing.confidence < suggestion.confidence) {
        uniqueSuggestions[suggestion.categoryId] = suggestion;
      }
    }

    final result = uniqueSuggestions.values.toList();
    result.sort((a, b) => b.confidence.compareTo(a.confidence));

    return result.take(3).toList(); // Return top 3 suggestions
  }

  List<CategorySuggestion> _getRuleBasedSuggestions(
      String description, List<ExpenseCategory> categories) {
    final suggestions = <CategorySuggestion>[];

    // Define keyword patterns for common categories
    final patterns = {
      'food': [
        'restaurant',
        'pizza',
        'burger',
        'food',
        'eat',
        'lunch',
        'dinner',
        'breakfast',
        'cafe',
        'coffee',
        'starbucks',
        'mcdonalds',
        'kfc',
        'subway',
        'dominos',
        'sushi',
        'chinese',
        'italian',
        'mexican'
      ],
      'transport': [
        'uber',
        'lyft',
        'taxi',
        'bus',
        'train',
        'metro',
        'gas',
        'fuel',
        'parking',
        'toll',
        'flight',
        'airline',
        'car',
        'vehicle'
      ],
      'shopping': [
        'amazon',
        'walmart',
        'target',
        'ebay',
        'shop',
        'store',
        'mall',
        'clothes',
        'clothing',
        'shirt',
        'shoes',
        'electronics'
      ],
      'entertainment': [
        'movie',
        'cinema',
        'netflix',
        'spotify',
        'game',
        'concert',
        'theater',
        'bar',
        'club',
        'party',
        'gym',
        'fitness'
      ],
      'utilities': [
        'electric',
        'water',
        'internet',
        'phone',
        'cable',
        'utility',
        'rent',
        'mortgage',
        'insurance'
      ],
      'healthcare': [
        'doctor',
        'hospital',
        'pharmacy',
        'medicine',
        'dentist',
        'medical',
        'health',
        'clinic'
      ],
      'education': [
        'school',
        'university',
        'book',
        'course',
        'tuition',
        'education',
        'training',
        'certification'
      ]
    };

    for (final category in categories) {
      final categoryKey = category.name.toLowerCase();
      final keywords = patterns[categoryKey] ?? [categoryKey];

      double confidence = 0.0;
      final matchedKeywords = <String>[];

      for (final keyword in keywords) {
        if (description.contains(keyword)) {
          confidence += keyword.length > 4
              ? 0.8
              : 0.6; // Longer keywords get higher confidence
          matchedKeywords.add(keyword);
        }
      }

      if (confidence > 0) {
        suggestions.add(CategorySuggestion(
          categoryId: category.id,
          categoryName: category.name,
          suggestedTags: matchedKeywords,
          confidence: confidence.clamp(0.0, 1.0),
        ));
      }
    }

    return suggestions;
  }

  List<CategorySuggestion> _getPatternBasedSuggestions(
      List<String> keywords, List<ExpenseCategory> categories) {
    final suggestions = <CategorySuggestion>[];

    if (keywords.isEmpty || _userPatterns.isEmpty) return suggestions;

    final categoryScores = <String, double>{};

    for (final keyword in keywords) {
      final pattern = _userPatterns[keyword];
      if (pattern != null) {
        final totalCount = pattern.values.fold(0, (sum, count) => sum + count);

        for (final entry in pattern.entries) {
          final categoryId = entry.key;
          final count = entry.value;
          final score = count / totalCount; // Normalized score

          categoryScores[categoryId] =
              (categoryScores[categoryId] ?? 0) + score;
        }
      }
    }

    for (final entry in categoryScores.entries) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );

      suggestions.add(CategorySuggestion(
        categoryId: entry.key,
        categoryName: category.name,
        suggestedTags: keywords,
        confidence: (entry.value / keywords.length).clamp(0.0, 1.0),
      ));
    }

    return suggestions;
  }

  Future<void> recordUserChoice(String description, String selectedCategoryId,
      List<CategorySuggestion> suggestions) async {
    // Record user's choice to improve future suggestions
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('categorization_feedback')
          .doc(user.uid)
          .collection('choices')
          .add({
        'description': description,
        'selectedCategoryId': selectedCategoryId,
        'suggestions': suggestions
            .map((s) => {
                  'categoryId': s.categoryId,
                  'confidence': s.confidence,
                })
            .toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update local patterns immediately
      final keywords = _extractKeywords(description.toLowerCase());
      for (final keyword in keywords) {
        _userPatterns[keyword] ??= {};
        _userPatterns[keyword]![selectedCategoryId] =
            (_userPatterns[keyword]![selectedCategoryId] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('Error recording user choice: $e');
    }
  }

  void clearPatterns() {
    _userPatterns.clear();
    _patternsLoaded = false;
  }
}
