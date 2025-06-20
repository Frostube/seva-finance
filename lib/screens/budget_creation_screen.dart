import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/budget_template.dart';
import '../models/template_item.dart';
import '../models/expense_category.dart';
import '../services/budget_template_service.dart';
import '../services/category_service.dart';
import '../services/wallet_service.dart';
import '../services/category_budget_service.dart';
import '../utils/icon_utils.dart';
import '../widgets/loading_widget.dart';

class BudgetCreationScreen extends StatefulWidget {
  final String walletId;
  final BudgetTemplate? selectedTemplate;
  final List<TemplateItem>? templateItems;
  final VoidCallback? onBudgetCreated;
  final bool isEditingTemplate;

  const BudgetCreationScreen({
    Key? key,
    required this.walletId,
    this.selectedTemplate,
    this.templateItems,
    this.onBudgetCreated,
    this.isEditingTemplate = false,
  }) : super(key: key);

  @override
  State<BudgetCreationScreen> createState() => _BudgetCreationScreenState();
}

class _BudgetCreationScreenState extends State<BudgetCreationScreen> {
  final List<BudgetCategoryItem> _budgetItems = [];
  final TextEditingController _templateNameController = TextEditingController();
  bool _saveAsTemplate = false;
  bool _isLoading = false;

  // New timeline controls
  BudgetTimeline _selectedTimeline = BudgetTimeline.monthly;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    // Initialize timeline from template if available
    if (widget.selectedTemplate != null) {
      _selectedTimeline = widget.selectedTemplate!.timeline;
      _selectedEndDate = widget.selectedTemplate!.endDate;

      // If editing a template, pre-fill the template name
      if (widget.isEditingTemplate) {
        _templateNameController.text = widget.selectedTemplate!.name;
        _saveAsTemplate = true;
      }
    }
    _initializeBudgetItems();
  }

  void _initializeBudgetItems() {
    final categoryService =
        Provider.of<CategoryService>(context, listen: false);

    print('BudgetCreationScreen: _initializeBudgetItems called');
    print(
        'BudgetCreationScreen: templateItems count: ${widget.templateItems?.length ?? 0}');
    print(
        'BudgetCreationScreen: available categories count: ${categoryService.categories.length}');

    // Print all available category IDs for debugging
    final availableCategoryIds =
        categoryService.categories.map((c) => c.id).toList();
    print(
        'BudgetCreationScreen: available category IDs: $availableCategoryIds');

    if (widget.templateItems != null && widget.templateItems!.isNotEmpty) {
      // Initialize from template
      print('BudgetCreationScreen: Initializing from template items...');
      for (int i = 0; i < widget.templateItems!.length; i++) {
        final templateItem = widget.templateItems![i];
        print(
            'BudgetCreationScreen: Processing template item $i: categoryId=${templateItem.categoryId}, amount=${templateItem.defaultAmount}');

        final category =
            categoryService.getCategoryById(templateItem.categoryId);

        if (category != null) {
          print(
              'BudgetCreationScreen: Found category: ${category.name} (${category.id})');
          _budgetItems.add(BudgetCategoryItem(
            category: category,
            amount: templateItem.defaultAmount,
            controller: TextEditingController(
              text: templateItem.defaultAmount.toStringAsFixed(0),
            ),
          ));
        } else {
          print(
              'BudgetCreationScreen: Category NOT FOUND for ID: ${templateItem.categoryId}');
        }
      }
      print(
          'BudgetCreationScreen: Added ${_budgetItems.length} budget items from template');
    } else {
      // Initialize with default categories
      print(
          'BudgetCreationScreen: No template items, initializing with default categories');
      final defaultCategories = categoryService.categories;
      for (final category in defaultCategories.take(6)) {
        _budgetItems.add(BudgetCategoryItem(
          category: category,
          amount: 0.0,
          controller: TextEditingController(text: '0'),
        ));
      }
      print(
          'BudgetCreationScreen: Added ${_budgetItems.length} default budget items');
    }
  }

  double get _totalBudget {
    return _budgetItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _updateItemAmount(int index, String value) {
    final amount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    setState(() {
      _budgetItems[index].amount = amount;
    });
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF1B4332),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  String _getTemplateDescription() {
    String baseDescription = 'Custom budget template';
    String timelineText = '';

    switch (_selectedTimeline) {
      case BudgetTimeline.monthly:
        timelineText = ' (Monthly)';
        break;
      case BudgetTimeline.yearly:
        timelineText = ' (Yearly)';
        break;
      case BudgetTimeline.undefined:
        timelineText = ' (One-time)';
        break;
    }

    if (_selectedEndDate != null) {
      final endDateText = DateFormat('MMM dd, yyyy').format(_selectedEndDate!);
      return '$baseDescription$timelineText - Valid until $endDateText';
    }

    return '$baseDescription$timelineText';
  }

  void _addNewCategory() {
    final categoryService =
        Provider.of<CategoryService>(context, listen: false);
    final availableCategories = categoryService.categories
        .where((cat) => !_budgetItems.any((item) => item.category.id == cat.id))
        .toList();

    if (availableCategories.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildCategorySelector(availableCategories),
      );
    }
  }

  Widget _buildCategorySelector(List<ExpenseCategory> categories) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Add Category',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: IconUtils.getCategoryIconColor(category.id)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        IconUtils.getIconFromName(category.icon),
                        color: IconUtils.getCategoryIconColor(category.id),
                        size: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _budgetItems.add(BudgetCategoryItem(
                        category: category,
                        amount: 0.0,
                        controller: TextEditingController(text: '0'),
                      ));
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _removeCategory(int index) {
    setState(() {
      _budgetItems[index].dispose();
      _budgetItems.removeAt(index);
    });
  }

  Future<void> _saveBudget() async {
    if (_budgetItems.isEmpty || _totalBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add at least one category with a budget amount',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If we're editing a template, only save the template, don't create budget
      if (widget.isEditingTemplate) {
        await _saveTemplateOnly();
        return;
      }

      final walletService = Provider.of<WalletService>(context, listen: false);

      // Update wallet budget
      await walletService.setWalletBudget(widget.walletId, _totalBudget);

      // Create category budgets for tracking
      final categoryBudgetService =
          Provider.of<CategoryBudgetService>(context, listen: false);
      final templateItems = _budgetItems
          .map((item) => {
                'categoryId': item.category.id,
                'categoryName': item.displayName,
                'amount': item.amount,
              })
          .toList();

      await categoryBudgetService.createCategoryBudgetsFromTemplate(
        walletId: widget.walletId,
        templateItems: templateItems,
        month: DateTime.now(),
        templateId: widget.selectedTemplate?.id,
      );

      // Save as custom template if requested
      if (_saveAsTemplate && _templateNameController.text.isNotEmpty) {
        final templateService =
            Provider.of<BudgetTemplateService>(context, listen: false);

        final templateItems = _budgetItems
            .map((item) => TemplateItem(
                  id: '',
                  templateId: '',
                  categoryId: item.category.id,
                  defaultAmount: item.amount,
                  order: _budgetItems.indexOf(item),
                ))
            .toList();

        await templateService.createTemplateWithTimeline(
          name: _templateNameController.text,
          description: _getTemplateDescription(),
          items: templateItems,
          timeline: _selectedTimeline,
          endDate: _selectedEndDate,
        );
      }

      if (mounted) {
        widget.onBudgetCreated?.call();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget created successfully! Total: \$${_totalBudget.toStringAsFixed(0)}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF1B4332),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create budget. Please try again.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveTemplateOnly() async {
    if (!_saveAsTemplate || _templateNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a template name',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final templateService =
          Provider.of<BudgetTemplateService>(context, listen: false);

      final templateItems = _budgetItems
          .map((item) => TemplateItem(
                id: '',
                templateId: '',
                categoryId: item.category.id,
                defaultAmount: item.amount,
                order: _budgetItems.indexOf(item),
              ))
          .toList();

      if (widget.selectedTemplate != null && widget.isEditingTemplate) {
        // Update existing template
        // Note: This would require an updateTemplate method in the service
        // For now, we'll delete and recreate
        await templateService.deleteTemplate(widget.selectedTemplate!.id);
      }

      await templateService.createTemplateWithTimeline(
        name: _templateNameController.text,
        description: _getTemplateDescription(),
        items: templateItems,
        timeline: _selectedTimeline,
        endDate: _selectedEndDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditingTemplate
                ? 'Template updated successfully!'
                : 'Template saved successfully!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Call the callback if provided
      if (widget.onBudgetCreated != null) {
        widget.onBudgetCreated!();
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving template: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final item in _budgetItems) {
      item.dispose();
    }
    _templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.selectedTemplate?.name ?? 'Create Budget',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: LoadingWidget(),
              ),
            )
          else
            TextButton(
              onPressed: _saveBudget,
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B4332),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with total
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (widget.selectedTemplate != null) ...[
                  Text(
                    widget.selectedTemplate!.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Total Budget',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(_totalBudget),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B4332),
                  ),
                ),
              ],
            ),
          ),

          // Timeline and End Date Controls
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Settings',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Timeline Selector
                Text(
                  'Timeline',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BudgetTimeline>(
                      value: _selectedTimeline,
                      isExpanded: true,
                      items: BudgetTimeline.values.map((timeline) {
                        String displayText;
                        String subtitle;
                        switch (timeline) {
                          case BudgetTimeline.monthly:
                            displayText = 'Monthly';
                            subtitle = 'Budget resets every month';
                            break;
                          case BudgetTimeline.yearly:
                            displayText = 'Yearly';
                            subtitle = 'Budget resets every year';
                            break;
                          case BudgetTimeline.undefined:
                            displayText = 'One-time';
                            subtitle = 'Fixed budget amount';
                            break;
                        }
                        return DropdownMenuItem(
                          value: timeline,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayText,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTimeline = value!;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // End Date (Optional)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'End Date (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    if (_selectedEndDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedEndDate = null;
                          });
                        },
                        child: Text(
                          'Clear',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedEndDate != null
                                ? DateFormat('MMM dd, yyyy')
                                    .format(_selectedEndDate!)
                                : 'Select end date (optional)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: _selectedEndDate != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Budget items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _budgetItems.length + 1,
              itemBuilder: (context, index) {
                if (index == _budgetItems.length) {
                  return _buildAddCategoryButton();
                }
                return _buildBudgetItemCard(index);
              },
            ),
          ),

          // Save as template section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _saveAsTemplate,
                      onChanged: (value) {
                        setState(() {
                          _saveAsTemplate = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF1B4332),
                    ),
                    Expanded(
                      child: Text(
                        'Save as my template',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_saveAsTemplate) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _templateNameController,
                    decoration: InputDecoration(
                      hintText: 'Template name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1B4332)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItemCard(int index) {
    final item = _budgetItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon and name
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: IconUtils.getCategoryIconColor(item.category.id)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                IconUtils.getIconFromName(item.category.icon),
                color: IconUtils.getCategoryIconColor(item.category.id),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editable category name
                TextField(
                  controller: item.nameController,
                  onChanged: (value) {
                    setState(() {
                      item.displayName = value;
                    });
                  },
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                // Amount input
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: item.controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _updateItemAmount(index, value),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1B4332)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          if (_budgetItems.length > 1)
            IconButton(
              onPressed: () => _removeCategory(index),
              icon: const Icon(CupertinoIcons.minus_circle),
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return GestureDetector(
      onTap: _addNewCategory,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1B4332),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.add,
              color: Color(0xFF1B4332),
            ),
            const SizedBox(width: 8),
            Text(
              'Add Category',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B4332),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetCategoryItem {
  final ExpenseCategory category;
  double amount;
  final TextEditingController controller;
  final TextEditingController nameController;
  String displayName;

  BudgetCategoryItem({
    required this.category,
    required this.amount,
    required this.controller,
    String? customName,
  })  : displayName = customName ?? category.name,
        nameController =
            TextEditingController(text: customName ?? category.name);

  void dispose() {
    controller.dispose();
    nameController.dispose();
  }
}
 