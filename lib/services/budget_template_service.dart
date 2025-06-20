import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/budget_template.dart';
import '../models/template_item.dart';
import '../models/expense_category.dart';

import 'auth_service.dart';

class BudgetTemplateService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final Box<BudgetTemplate> _templatesBox;
  final Box<TemplateItem> _templateItemsBox;
  final AuthService _authService;

  List<BudgetTemplate> _templates = [];
  List<TemplateItem> _templateItems = [];
  bool _isLoading = false;
  bool _hasSeededSystemTemplates = false;

  BudgetTemplateService(
    this._firestore,
    this._templatesBox,
    this._templateItemsBox,
    this._authService,
  ) {
    // Listen to auth state changes
    _authService.addListener(_onAuthStateChanged);
    _initializeService();
  }

  void _onAuthStateChanged() {
    print(
        'BudgetTemplateService: Auth state changed, user: ${_authService.user?.uid}');
    // Re-initialize when auth state changes
    if (_authService.isAuthenticated && !_hasSeededSystemTemplates) {
      _initializeService();
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  // Getters
  List<BudgetTemplate> get templates {
    // Create a map to track seen template names and keep only the first occurrence
    final Map<String, BudgetTemplate> uniqueTemplates = {};

    for (final template in _templates) {
      final key =
          '${template.name}_${template.isSystem}'; // Use name + isSystem as key
      if (!uniqueTemplates.containsKey(key)) {
        uniqueTemplates[key] = template;
      }
    }

    final deduplicatedList = uniqueTemplates.values.toList();

    // Log deduplication if needed
    if (_templates.length != deduplicatedList.length) {
      print(
          'BudgetTemplateService: Deduplicated templates from ${_templates.length} to ${deduplicatedList.length}');
    }

    return deduplicatedList;
  }

  List<BudgetTemplate> get systemTemplates =>
      templates.where((template) => template.isSystem).toList();
  List<BudgetTemplate> get userTemplates => _templates
      .where((template) =>
          !template.isSystem && template.createdBy == _authService.user?.uid)
      .toList();
  List<TemplateItem> get templateItems => _templateItems;
  bool get isLoading => _isLoading;

  Future<void> _initializeService() async {
    print('BudgetTemplateService: _initializeService START');
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local cache first
      print('BudgetTemplateService: Loading from cache...');
      _loadFromCache();
      print(
          'BudgetTemplateService: Loaded ${_templates.length} templates from cache');

      // Sync with Firestore if authenticated
      if (_authService.isAuthenticated) {
        print(
            'BudgetTemplateService: User is authenticated, syncing with Firestore...');
        await _syncWithFirestore();
        print(
            'BudgetTemplateService: Sync complete, now have ${_templates.length} templates');

        // Always seed system templates to ensure categories exist
        print('BudgetTemplateService: Ensuring template categories exist...');

        // First, always ensure categories exist
        final systemTemplatesData = _getSystemTemplatesData();
        await _ensureTemplateCategoriesExist(systemTemplatesData);

        // Force CategoryService to refresh after updating icons
        print('BudgetTemplateService: Requesting CategoryService refresh...');
        // We can't directly access CategoryService here, but the changes will be picked up on next sync

        // Then handle template seeding
        await _seedSystemTemplates();
        _hasSeededSystemTemplates = true;
        print(
            'BudgetTemplateService: After seeding, now have ${_templates.length} templates');
      } else {
        print(
            'BudgetTemplateService: User not authenticated, skipping Firestore sync');
      }
    } catch (e) {
      print('Error initializing budget template service: $e');
    } finally {
      _isLoading = false;
      print(
          'BudgetTemplateService: _initializeService END, isLoading: $_isLoading, templates: ${_templates.length}');
      notifyListeners();
    }
  }

  void _loadFromCache() {
    try {
      _templates = _templatesBox.values.toList();
      _templateItems = _templateItemsBox.values.toList();
      print(
          'BudgetTemplateService: Successfully loaded ${_templates.length} templates from cache');
    } catch (e) {
      print(
          'BudgetTemplateService: Error loading from cache (likely schema mismatch): $e');
      print('BudgetTemplateService: Clearing cache and forcing fresh sync...');
      // Clear cache if there's a schema mismatch
      _templatesBox.clear();
      _templateItemsBox.clear();
      _templates = [];
      _templateItems = [];
    }
  }

  Future<void> _syncWithFirestore() async {
    try {
      // Fetch system templates
      final systemTemplatesQuery = await _firestore
          .collection('budgetTemplates')
          .where('isSystem', isEqualTo: true)
          .get();

      // Fetch user templates
      QuerySnapshot? userTemplatesQuery;
      if (_authService.user != null) {
        userTemplatesQuery = await _firestore
            .collection('budgetTemplates')
            .where('createdBy', isEqualTo: _authService.user!.uid)
            .get();
      }

      // Process system templates
      final fetchedTemplates = <BudgetTemplate>[];
      for (final doc in systemTemplatesQuery.docs) {
        final template = BudgetTemplate.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        fetchedTemplates.add(template);
        await _templatesBox.put(template.id, template);

        // Fetch template items
        await _fetchTemplateItems(template.id);
      }

      // Process user templates
      if (userTemplatesQuery != null) {
        for (final doc in userTemplatesQuery.docs) {
          final template = BudgetTemplate.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          fetchedTemplates.add(template);
          await _templatesBox.put(template.id, template);

          // Fetch template items
          await _fetchTemplateItems(template.id);
        }
      }

      _templates = fetchedTemplates;
      _templateItems = _templateItemsBox.values.toList();
    } catch (e) {
      print('Error syncing with Firestore: $e');
    }
  }

  Future<void> _fetchTemplateItems(String templateId) async {
    try {
      final itemsQuery = await _firestore
          .collection('budgetTemplates')
          .doc(templateId)
          .collection('items')
          .orderBy('order')
          .get();

      for (final doc in itemsQuery.docs) {
        final data = doc.data();
        // Ensure templateId is set correctly
        data['templateId'] = templateId;

        final item = TemplateItem.fromJson(data, doc.id);
        await _templateItemsBox.put(item.id, item);
      }
    } catch (e) {
      print('Error fetching template items for $templateId: $e');
    }
  }

  Future<void> _seedSystemTemplates() async {
    try {
      final systemTemplatesData = _getSystemTemplatesData();

      // Get all existing system templates (including duplicates)
      final existingSystemTemplates = await _firestore
          .collection('budgetTemplates')
          .where('isSystem', isEqualTo: true)
          .get();

      print(
          'BudgetTemplateService: Found ${existingSystemTemplates.docs.length} existing system templates');

      // Create a map of existing template names to avoid duplicates
      final existingTemplateNames = <String, List<String>>{};
      final templatesToUpdate = <String>[];

      for (final doc in existingSystemTemplates.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String;
        existingTemplateNames.putIfAbsent(name, () => []).add(doc.id);

        // Check if template needs timeline/endDate fields added
        if (!data.containsKey('timeline') || !data.containsKey('endDate')) {
          templatesToUpdate.add(doc.id);
          print(
              'BudgetTemplateService: Template "$name" (ID: ${doc.id}) needs timeline fields update');
        }

        print(
            'BudgetTemplateService: Existing template: "$name" (ID: ${doc.id})');
      }

      // Update existing templates that are missing new fields
      for (final templateId in templatesToUpdate) {
        try {
          await _firestore
              .collection('budgetTemplates')
              .doc(templateId)
              .update({
            'timeline': BudgetTimeline.monthly.index,
            'endDate': null,
          });
          print(
              'BudgetTemplateService: Updated template $templateId with timeline fields');
        } catch (e) {
          print(
              'BudgetTemplateService: Error updating template $templateId: $e');
        }
      }

      // Show duplicates
      for (final entry in existingTemplateNames.entries) {
        if (entry.value.length > 1) {
          print(
              'BudgetTemplateService: DUPLICATE template "${entry.key}" found ${entry.value.length} times: ${entry.value}');
        }
      }

      // Create missing templates and update outdated ones
      int createdCount = 0;
      int updatedCount = 0;

      for (final templateData in systemTemplatesData) {
        final templateName = templateData['template']['name'] as String;
        final expectedItems =
            templateData['items'] as List<Map<String, dynamic>>;

        if (!existingTemplateNames.containsKey(templateName)) {
          print(
              'BudgetTemplateService: Creating missing template: $templateName');

          try {
            // Create template document
            final templateRef = await _firestore
                .collection('budgetTemplates')
                .add(templateData['template'] as Map<String, dynamic>);

            // Add template items
            for (int i = 0; i < expectedItems.length; i++) {
              final item = expectedItems[i];
              item['order'] = i;
              item['templateId'] = templateRef.id;
              await templateRef.collection('items').add(item);
            }

            createdCount++;
            print(
                'BudgetTemplateService: Successfully created template: $templateName');
          } catch (e) {
            print(
                'BudgetTemplateService: Error creating template $templateName: $e');
          }
        } else {
          // Check if existing template needs updating (has outdated values)
          final templateIds = existingTemplateNames[templateName]!;
          final primaryTemplateId =
              templateIds.first; // Use first one if duplicates exist

          final needsUpdate = await _checkIfTemplateNeedsUpdate(
              primaryTemplateId, expectedItems);

          if (needsUpdate) {
            print(
                'BudgetTemplateService: Updating outdated template: $templateName');
            try {
              await _updateTemplateItems(primaryTemplateId, expectedItems);
              updatedCount++;
              print(
                  'BudgetTemplateService: Successfully updated template: $templateName');
            } catch (e) {
              print(
                  'BudgetTemplateService: Error updating template $templateName: $e');
            }
          } else {
            print(
                'BudgetTemplateService: Template "$templateName" is up to date');
          }
        }
      }

      if (createdCount > 0 || updatedCount > 0) {
        print(
            'BudgetTemplateService: Created $createdCount new templates, updated $updatedCount templates');
        // Refresh templates after seeding/updating
        await _syncWithFirestore();
      } else {
        print('BudgetTemplateService: No template changes needed');
      }
    } catch (e) {
      print('Error seeding system templates: $e');
    }
  }

  // Check if a template needs updating by comparing existing items with expected items
  Future<bool> _checkIfTemplateNeedsUpdate(
      String templateId, List<Map<String, dynamic>> expectedItems) async {
    try {
      // Get existing template items from Firestore
      final existingItemsQuery = await _firestore
          .collection('budgetTemplates')
          .doc(templateId)
          .collection('items')
          .get();

      final existingItems = existingItemsQuery.docs;

      // If counts don't match, needs update
      if (existingItems.length != expectedItems.length) {
        print(
            'BudgetTemplateService: Template needs update - item count mismatch (${existingItems.length} vs ${expectedItems.length})');
        return true;
      }

      // Check if any amounts are $0 (indicating old template)
      for (final doc in existingItems) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['defaultAmount'] as num?)?.toDouble() ?? 0.0;
        if (amount == 0.0) {
          print(
              'BudgetTemplateService: Template needs update - found \$0 amount');
          return true;
        }
      }

      // Check if expected amounts differ from existing ones
      for (final expectedItem in expectedItems) {
        final categoryId = expectedItem['categoryId'] as String;
        final expectedAmount = expectedItem['defaultAmount'] as double;

        final existingItem = existingItems.firstWhere(
          (doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['categoryId'] == categoryId;
          },
          orElse: () => throw StateError('Not found'),
        );

        try {
          final data = existingItem.data() as Map<String, dynamic>;
          final existingAmount =
              (data['defaultAmount'] as num?)?.toDouble() ?? 0.0;

          // If amount is significantly different, needs update
          if (existingAmount != expectedAmount) {
            print(
                'BudgetTemplateService: Template needs update - amount mismatch for $categoryId ($existingAmount vs $expectedAmount)');
            return true;
          }
        } catch (e) {
          // Category doesn't exist, needs update
          print(
              'BudgetTemplateService: Template needs update - missing category $categoryId');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('BudgetTemplateService: Error checking template update status: $e');
      return true; // Assume needs update if we can't check
    }
  }

  // Update template items with new enhanced values
  Future<void> _updateTemplateItems(
      String templateId, List<Map<String, dynamic>> newItems) async {
    try {
      // Delete all existing template items
      final existingItemsQuery = await _firestore
          .collection('budgetTemplates')
          .doc(templateId)
          .collection('items')
          .get();

      for (final doc in existingItemsQuery.docs) {
        await doc.reference.delete();
      }

      // Create new template items with enhanced values
      for (int i = 0; i < newItems.length; i++) {
        final item = Map<String, dynamic>.from(newItems[i]);
        item['order'] = i;
        item['templateId'] = templateId;

        await _firestore
            .collection('budgetTemplates')
            .doc(templateId)
            .collection('items')
            .add(item);
      }

      print(
          'BudgetTemplateService: Successfully updated template items for $templateId');
    } catch (e) {
      print(
          'BudgetTemplateService: Error updating template items for $templateId: $e');
      rethrow;
    }
  }

  Future<void> _ensureTemplateCategoriesExist(
      List<Map<String, dynamic>> templatesData) async {
    if (_authService.user == null) {
      print(
          'BudgetTemplateService: No authenticated user, skipping category creation');
      return;
    }

    final userId = _authService.user!.uid;
    final Set<String> requiredCategoryIds = {};
    final Map<String, Map<String, String>> categoryInfo = {};

    print(
        'BudgetTemplateService: Collecting required categories from templates...');

    // Collect all category IDs and their info from templates
    for (final templateData in templatesData) {
      final items = templateData['items'] as List<Map<String, dynamic>>;
      for (final item in items) {
        final categoryId = item['categoryId'] as String;
        requiredCategoryIds.add(categoryId);
        categoryInfo[categoryId] = {
          'name': item['categoryName'] as String,
          'icon': item['categoryIcon'] as String,
        };
      }
    }

    print(
        'BudgetTemplateService: Found ${requiredCategoryIds.length} required categories: ${requiredCategoryIds.join(', ')}');

    // Check which categories already exist
    final existingCategoriesQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenseCategories')
        .get();

    final existingCategoryIds =
        existingCategoriesQuery.docs.map((doc) => doc.id).toSet();

    print(
        'BudgetTemplateService: Found ${existingCategoryIds.length} existing categories: ${existingCategoryIds.join(', ')}');

    // Create missing categories and update existing ones with correct icons
    int createdCount = 0;
    int updatedCount = 0;

    for (final categoryId in requiredCategoryIds) {
      final categoryData = categoryInfo[categoryId]!;
      final correctIconName = _getCategoryIconName(categoryId);

      if (existingCategoryIds.contains(categoryId)) {
        // Update existing category with correct icon
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('expenseCategories')
              .doc(categoryId)
              .update({
            'icon': correctIconName,
          });
          print(
              'BudgetTemplateService: Updated category icon: ${categoryData['name']} (${categoryId}) -> $correctIconName');
          updatedCount++;
        } catch (e) {
          print(
              'BudgetTemplateService: Error updating category $categoryId: $e');
        }
      } else {
        // Create new category
        final category = ExpenseCategory(
          id: categoryId,
          name: categoryData['name']!,
          icon: correctIconName,
        );

        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('expenseCategories')
              .doc(categoryId)
              .set(category.toJson());

          print(
              'BudgetTemplateService: Created category: ${category.name} (${categoryId}) -> $correctIconName');
          createdCount++;
        } catch (e) {
          print(
              'BudgetTemplateService: Error creating category $categoryId: $e');
        }
      }
    }

    print(
        'BudgetTemplateService: Category update complete. Created $createdCount new categories, updated $updatedCount existing categories.');
  }

  /// Get the appropriate icon name for a category
  String _getCategoryIconName(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'housing':
        return 'house_fill';
      case 'food':
        return 'cart_fill';
      case 'transportation':
        return 'car_fill';
      case 'entertainment':
        return 'film_fill';
      case 'shopping':
        return 'bag_fill';
      case 'savings':
        return 'money_dollar_circle_fill';
      case 'education':
        return 'book_fill';
      case 'personal_care':
        return 'heart_fill';
      case 'business':
        return 'briefcase_fill';
      case 'emergency_fund':
        return 'shield_fill';
      case 'taxes':
        return 'doc_text_fill';
      case 'travel_savings':
        return 'airplane';
      case 'general_savings':
        return 'money_dollar_circle';
      default:
        return 'circle_fill';
    }
  }

  List<Map<String, dynamic>> _getSystemTemplatesData() {
    return [
      {
        'template': {
          'name': '50/30/20 Rule',
          'description':
              'Classic budgeting rule: 50% needs, 30% wants, 20% savings',
          'isSystem': true,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'timeline': BudgetTimeline.monthly.index,
          'endDate': null,
        },
        'items': [
          // 50% Needs (2500 total)
          {
            'categoryId': 'housing',
            'categoryName': 'Housing',
            'categoryIcon': _getCategoryIconName('housing'),
            'defaultAmount': 1500.0, // Rent/Mortgage
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Food & Dining',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 500.0, // Groceries + dining
            'templateId': '',
          },
          {
            'categoryId': 'transportation',
            'categoryName': 'Transportation',
            'categoryIcon': _getCategoryIconName('transportation'),
            'defaultAmount': 300.0, // Car payment/gas/public transport
            'templateId': '',
          },
          {
            'categoryId': 'personal_care',
            'categoryName': 'Personal Care',
            'categoryIcon': _getCategoryIconName('personal_care'),
            'defaultAmount': 200.0, // Healthcare, hygiene, etc.
            'templateId': '',
          },
          // 30% Wants (1500 total)
          {
            'categoryId': 'entertainment',
            'categoryName': 'Entertainment',
            'categoryIcon': _getCategoryIconName('entertainment'),
            'defaultAmount': 400.0, // Movies, streaming, hobbies
            'templateId': '',
          },
          {
            'categoryId': 'shopping',
            'categoryName': 'Shopping',
            'categoryIcon': _getCategoryIconName('shopping'),
            'defaultAmount': 600.0, // Clothes, gadgets, misc
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Dining Out',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 300.0, // Restaurant meals
            'templateId': '',
          },
          {
            'categoryId': 'travel_savings',
            'categoryName': 'Travel & Vacation',
            'categoryIcon': _getCategoryIconName('travel_savings'),
            'defaultAmount': 200.0, // Weekend trips, vacations
            'templateId': '',
          },
          // 20% Savings (1000 total)
          {
            'categoryId': 'emergency_fund',
            'categoryName': 'Emergency Fund',
            'categoryIcon': _getCategoryIconName('emergency_fund'),
            'defaultAmount': 400.0, // 3-6 months expenses
            'templateId': '',
          },
          {
            'categoryId': 'savings',
            'categoryName': 'General Savings',
            'categoryIcon': _getCategoryIconName('savings'),
            'defaultAmount': 400.0, // Long-term goals
            'templateId': '',
          },
          {
            'categoryId': 'general_savings',
            'categoryName': 'Investment Fund',
            'categoryIcon': _getCategoryIconName('general_savings'),
            'defaultAmount': 200.0, // Stock market, retirement
            'templateId': '',
          },
        ],
      },
      {
        'template': {
          'name': 'Student Budget',
          'description': 'Budget template designed for students',
          'isSystem': true,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'timeline': BudgetTimeline.monthly.index,
          'endDate': null,
        },
        'items': [
          {
            'categoryId': 'education',
            'categoryName': 'Education',
            'categoryIcon': _getCategoryIconName('education'),
            'defaultAmount': 600.0, // Tuition, books, supplies
            'templateId': '',
          },
          {
            'categoryId': 'housing',
            'categoryName': 'Housing',
            'categoryIcon': _getCategoryIconName('housing'),
            'defaultAmount': 800.0, // Dorm/apartment rent
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Food & Dining',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 400.0, // Meal plan + groceries
            'templateId': '',
          },
          {
            'categoryId': 'transportation',
            'categoryName': 'Transportation',
            'categoryIcon': _getCategoryIconName('transportation'),
            'defaultAmount': 150.0, // Bus pass, gas, bike maintenance
            'templateId': '',
          },
          {
            'categoryId': 'entertainment',
            'categoryName': 'Entertainment',
            'categoryIcon': _getCategoryIconName('entertainment'),
            'defaultAmount': 200.0, // Movies, games, social activities
            'templateId': '',
          },
          {
            'categoryId': 'personal_care',
            'categoryName': 'Personal Care',
            'categoryIcon': _getCategoryIconName('personal_care'),
            'defaultAmount': 100.0, // Hygiene, healthcare, gym
            'templateId': '',
          },
          {
            'categoryId': 'shopping',
            'categoryName': 'Shopping',
            'categoryIcon': _getCategoryIconName('shopping'),
            'defaultAmount': 150.0, // Clothes, electronics, misc
            'templateId': '',
          },
          {
            'categoryId': 'emergency_fund',
            'categoryName': 'Emergency Fund',
            'categoryIcon': _getCategoryIconName('emergency_fund'),
            'defaultAmount': 100.0, // Small emergency savings
            'templateId': '',
          },
        ],
      },
      {
        'template': {
          'name': 'Business Owner',
          'description': 'Budget template for small business owners',
          'isSystem': true,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'timeline': BudgetTimeline.monthly.index,
          'endDate': null,
        },
        'items': [
          {
            'categoryId': 'business',
            'categoryName': 'Business Expenses',
            'categoryIcon': _getCategoryIconName('business'),
            'defaultAmount': 1500.0, // Office, equipment, software
            'templateId': '',
          },
          {
            'categoryId': 'taxes',
            'categoryName': 'Taxes',
            'categoryIcon': _getCategoryIconName('taxes'),
            'defaultAmount': 800.0, // Quarterly tax savings
            'templateId': '',
          },
          {
            'categoryId': 'housing',
            'categoryName': 'Housing',
            'categoryIcon': _getCategoryIconName('housing'),
            'defaultAmount': 1400.0, // Mortgage/rent
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Food & Dining',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 600.0, // Groceries + business meals
            'templateId': '',
          },
          {
            'categoryId': 'transportation',
            'categoryName': 'Transportation',
            'categoryIcon': _getCategoryIconName('transportation'),
            'defaultAmount': 400.0, // Car payment, gas, business travel
            'templateId': '',
          },
          {
            'categoryId': 'personal_care',
            'categoryName': 'Personal Care',
            'categoryIcon': _getCategoryIconName('personal_care'),
            'defaultAmount': 250.0, // Healthcare, professional appearance
            'templateId': '',
          },
          {
            'categoryId': 'emergency_fund',
            'categoryName': 'Emergency Fund',
            'categoryIcon': _getCategoryIconName('emergency_fund'),
            'defaultAmount': 500.0, // Business + personal emergencies
            'templateId': '',
          },
          {
            'categoryId': 'savings',
            'categoryName': 'Business Savings',
            'categoryIcon': _getCategoryIconName('savings'),
            'defaultAmount': 400.0, // Equipment upgrades, expansion
            'templateId': '',
          },
          {
            'categoryId': 'entertainment',
            'categoryName': 'Entertainment',
            'categoryIcon': _getCategoryIconName('entertainment'),
            'defaultAmount': 300.0, // Networking, leisure
            'templateId': '',
          },
        ],
      },
      {
        'template': {
          'name': 'Savings Focused',
          'description': 'Template for aggressive savers',
          'isSystem': true,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'timeline': BudgetTimeline.monthly.index,
          'endDate': null,
        },
        'items': [
          {
            'categoryId': 'housing',
            'categoryName': 'Housing',
            'categoryIcon': _getCategoryIconName('housing'),
            'defaultAmount': 1000.0, // Minimal housing costs
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Food & Dining',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 300.0, // Budget-conscious grocery shopping
            'templateId': '',
          },
          {
            'categoryId': 'transportation',
            'categoryName': 'Transportation',
            'categoryIcon': _getCategoryIconName('transportation'),
            'defaultAmount': 250.0, // Public transport, bike, efficient car
            'templateId': '',
          },
          {
            'categoryId': 'personal_care',
            'categoryName': 'Personal Care',
            'categoryIcon': _getCategoryIconName('personal_care'),
            'defaultAmount': 150.0, // Essential healthcare and hygiene
            'templateId': '',
          },
          {
            'categoryId': 'entertainment',
            'categoryName': 'Entertainment',
            'categoryIcon': _getCategoryIconName('entertainment'),
            'defaultAmount': 200.0, // Free/low-cost activities
            'templateId': '',
          },
          {
            'categoryId': 'emergency_fund',
            'categoryName': 'Emergency Fund',
            'categoryIcon': _getCategoryIconName('emergency_fund'),
            'defaultAmount': 600.0, // 6+ months expenses
            'templateId': '',
          },
          {
            'categoryId': 'travel_savings',
            'categoryName': 'Travel Savings',
            'categoryIcon': _getCategoryIconName('travel_savings'),
            'defaultAmount': 400.0, // Dream vacation fund
            'templateId': '',
          },
          {
            'categoryId': 'general_savings',
            'categoryName': 'Investment Fund',
            'categoryIcon': _getCategoryIconName('general_savings'),
            'defaultAmount': 500.0, // Stock market, retirement
            'templateId': '',
          },
          {
            'categoryId': 'savings',
            'categoryName': 'House Down Payment',
            'categoryIcon': _getCategoryIconName('savings'),
            'defaultAmount': 800.0, // Major purchase savings
            'templateId': '',
          },
        ],
      },
      {
        'template': {
          'name': 'Young Professional',
          'description': 'Budget for early career professionals',
          'isSystem': true,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'timeline': BudgetTimeline.monthly.index,
          'endDate': null,
        },
        'items': [
          {
            'categoryId': 'housing',
            'categoryName': 'Housing',
            'categoryIcon': _getCategoryIconName('housing'),
            'defaultAmount': 1200.0, // Apartment rent
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Food & Dining',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 500.0, // Groceries + frequent dining out
            'templateId': '',
          },
          {
            'categoryId': 'transportation',
            'categoryName': 'Transportation',
            'categoryIcon': _getCategoryIconName('transportation'),
            'defaultAmount': 350.0, // Car payment, insurance, gas
            'templateId': '',
          },
          {
            'categoryId': 'personal_care',
            'categoryName': 'Personal Care',
            'categoryIcon': _getCategoryIconName('personal_care'),
            'defaultAmount': 200.0, // Gym, healthcare, grooming
            'templateId': '',
          },
          {
            'categoryId': 'entertainment',
            'categoryName': 'Entertainment',
            'categoryIcon': _getCategoryIconName('entertainment'),
            'defaultAmount': 400.0, // Social life, hobbies, streaming
            'templateId': '',
          },
          {
            'categoryId': 'shopping',
            'categoryName': 'Shopping',
            'categoryIcon': _getCategoryIconName('shopping'),
            'defaultAmount': 300.0, // Professional clothes, gadgets
            'templateId': '',
          },
          {
            'categoryId': 'education',
            'categoryName': 'Education',
            'categoryIcon': _getCategoryIconName('education'),
            'defaultAmount': 150.0, // Courses, certifications, books
            'templateId': '',
          },
          {
            'categoryId': 'emergency_fund',
            'categoryName': 'Emergency Fund',
            'categoryIcon': _getCategoryIconName('emergency_fund'),
            'defaultAmount': 300.0, // Building up emergency savings
            'templateId': '',
          },
          {
            'categoryId': 'savings',
            'categoryName': 'General Savings',
            'categoryIcon': _getCategoryIconName('savings'),
            'defaultAmount': 400.0, // Future goals
            'templateId': '',
          },
        ],
      },
      {
        'template': {
          'name': 'Vacation Saver',
          'description': 'Special budget for vacation planning',
          'isSystem': true,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'timeline': BudgetTimeline.yearly.index,
          'endDate':
              DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        },
        'items': [
          {
            'categoryId': 'travel_savings',
            'categoryName': 'Flight Tickets',
            'categoryIcon': _getCategoryIconName('travel_savings'),
            'defaultAmount': 1200.0, // Round-trip international flights
            'templateId': '',
          },
          {
            'categoryId': 'travel_savings',
            'categoryName': 'Accommodation',
            'categoryIcon': _getCategoryIconName('travel_savings'),
            'defaultAmount': 1500.0, // Hotels for 2 weeks
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Food & Dining',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 800.0, // Restaurant meals during vacation
            'templateId': '',
          },
          {
            'categoryId': 'entertainment',
            'categoryName': 'Activities & Tours',
            'categoryIcon': _getCategoryIconName('entertainment'),
            'defaultAmount': 600.0, // Sightseeing, tours, experiences
            'templateId': '',
          },
          {
            'categoryId': 'transportation',
            'categoryName': 'Local Transport',
            'categoryIcon': _getCategoryIconName('transportation'),
            'defaultAmount': 300.0, // Taxis, trains, car rental
            'templateId': '',
          },
          {
            'categoryId': 'shopping',
            'categoryName': 'Shopping & Souvenirs',
            'categoryIcon': _getCategoryIconName('shopping'),
            'defaultAmount': 400.0, // Gifts, souvenirs, shopping
            'templateId': '',
          },
          {
            'categoryId': 'emergency_fund',
            'categoryName': 'Travel Emergency',
            'categoryIcon': _getCategoryIconName('emergency_fund'),
            'defaultAmount': 200.0, // Unexpected travel expenses
            'templateId': '',
          },
        ],
      },
      {
        'template': {
          'name': 'Freelancer Cash-Flow',
          'description': 'Budget for freelancers with irregular income',
          'isSystem': true,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'timeline': BudgetTimeline.monthly.index,
          'endDate': null,
        },
        'items': [
          {
            'categoryId': 'housing',
            'categoryName': 'Housing',
            'categoryIcon': _getCategoryIconName('housing'),
            'defaultAmount': 1100.0, // Conservative rent estimate
            'templateId': '',
          },
          {
            'categoryId': 'business',
            'categoryName': 'Business Expenses',
            'categoryIcon': _getCategoryIconName('business'),
            'defaultAmount': 400.0, // Software, equipment, internet
            'templateId': '',
          },
          {
            'categoryId': 'food',
            'categoryName': 'Food & Dining',
            'categoryIcon': _getCategoryIconName('food'),
            'defaultAmount': 350.0, // Budget-conscious grocery shopping
            'templateId': '',
          },
          {
            'categoryId': 'transportation',
            'categoryName': 'Transportation',
            'categoryIcon': _getCategoryIconName('transportation'),
            'defaultAmount': 200.0, // Public transport, minimal car use
            'templateId': '',
          },
          {
            'categoryId': 'personal_care',
            'categoryName': 'Personal Care',
            'categoryIcon': _getCategoryIconName('personal_care'),
            'defaultAmount': 150.0, // Healthcare, basic grooming
            'templateId': '',
          },
          {
            'categoryId': 'entertainment',
            'categoryName': 'Entertainment',
            'categoryIcon': _getCategoryIconName('entertainment'),
            'defaultAmount': 250.0, // Modest entertainment budget
            'templateId': '',
          },
          {
            'categoryId': 'emergency_fund',
            'categoryName': 'Emergency Fund',
            'categoryIcon': _getCategoryIconName('emergency_fund'),
            'defaultAmount': 600.0, // Critical for irregular income
            'templateId': '',
          },
          {
            'categoryId': 'taxes',
            'categoryName': 'Tax Savings',
            'categoryIcon': _getCategoryIconName('taxes'),
            'defaultAmount': 500.0, // Quarterly tax obligations
            'templateId': '',
          },
          {
            'categoryId': 'savings',
            'categoryName': 'Income Buffer',
            'categoryIcon': _getCategoryIconName('savings'),
            'defaultAmount': 400.0, // Smooth out income variations
            'templateId': '',
          },
        ],
      },
    ];
  }

  // Get template items for a specific template
  List<TemplateItem> getTemplateItems(String templateId) {
    return _templateItems
        .where((item) => item.templateId == templateId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // Create a new custom template
  Future<BudgetTemplate?> createTemplate({
    required String name,
    required String description,
    required List<TemplateItem> items,
  }) async {
    return createTemplateWithTimeline(
      name: name,
      description: description,
      items: items,
      timeline: BudgetTimeline.monthly,
      endDate: null,
    );
  }

  // Create a new custom template with timeline and end date support
  Future<BudgetTemplate?> createTemplateWithTimeline({
    required String name,
    required String description,
    required List<TemplateItem> items,
    BudgetTimeline timeline = BudgetTimeline.monthly,
    DateTime? endDate,
  }) async {
    try {
      if (_authService.user == null) {
        throw Exception('User must be authenticated to create templates');
      }

      final template = BudgetTemplate(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        isSystem: false,
        createdBy: _authService.user!.uid,
        timeline: timeline,
        endDate: endDate,
      );

      // Create template in Firestore
      final templateRef =
          await _firestore.collection('budgetTemplates').add(template.toJson());

      // Create template with proper ID
      final createdTemplate = BudgetTemplate(
        id: templateRef.id,
        name: name,
        description: description,
        isSystem: false,
        createdBy: _authService.user!.uid,
        timeline: timeline,
        endDate: endDate,
      );

      // Add template items
      for (int i = 0; i < items.length; i++) {
        final item = TemplateItem(
          id: '', // Will be set by Firestore
          templateId: templateRef.id,
          categoryId: items[i].categoryId,
          defaultAmount: items[i].defaultAmount,
          order: i,
        );

        await templateRef.collection('items').add(item.toJson());
      }

      // Update local cache
      await _templatesBox.put(createdTemplate.id, createdTemplate);
      _templates.add(createdTemplate);

      // Refresh template items
      await _fetchTemplateItems(createdTemplate.id);
      _templateItems = _templateItemsBox.values.toList();

      notifyListeners();
      return createdTemplate;
    } catch (e) {
      print('Error creating template: $e');
      return null;
    }
  }

  // Delete a user template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      final template = _templates.firstWhere((t) => t.id == templateId);

      // Can only delete user templates
      if (template.isSystem) {
        throw Exception('Cannot delete system templates');
      }

      if (template.createdBy != _authService.user?.uid) {
        throw Exception('Can only delete own templates');
      }

      // Delete from Firestore
      await _firestore.collection('budgetTemplates').doc(templateId).delete();

      // Remove from local cache
      await _templatesBox.delete(templateId);
      _templates.removeWhere((t) => t.id == templateId);

      // Remove template items
      final itemsToRemove = _templateItems
          .where((item) => item.templateId == templateId)
          .toList();

      for (final item in itemsToRemove) {
        await _templateItemsBox.delete(item.id);
      }

      _templateItems.removeWhere((item) => item.templateId == templateId);

      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting template: $e');
      return false;
    }
  }

  // Force refresh from Firestore
  Future<void> refresh() async {
    print('BudgetTemplateService: Force refresh requested');
    // Clear cache to force fresh data
    await _templatesBox.clear();
    await _templateItemsBox.clear();
    _templates = [];
    _templateItems = [];

    // Re-initialize everything
    await _initializeService();
  }
}
