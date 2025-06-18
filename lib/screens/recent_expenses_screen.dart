import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'transaction_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../services/storage_service.dart';
import '../services/wallet_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/category_service.dart';

class RecentExpensesScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final String? categoryForMonthFilter;
  final DateTime? monthForCategoryFilter;

  const RecentExpensesScreen({
    Key? key,
    required this.expenseService,
    this.categoryForMonthFilter,
    this.monthForCategoryFilter,
  }) : super(key: key);

  @override
  State<RecentExpensesScreen> createState() => _RecentExpensesScreenState();
}

class _RecentExpensesScreenState extends State<RecentExpensesScreen> {
  late final ExpenseService _expenseService;
  late final CategoryService _categoryService;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  String _searchQuery = '';
  String? _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _initializeAsyncDependencies();
  }

  Future<void> _initializeAsyncDependencies() async {
    _categoryService = Provider.of<CategoryService>(context, listen: false);
    if (_categoryService.initializationComplete != null) {
      print('RecentExpensesScreen: Awaiting CategoryService initialization...');
      await _categoryService.initializationComplete;
      print('RecentExpensesScreen: CategoryService initialization COMPLETE');
    }

    _expenseService = ExpenseService(
      Hive.box<Expense>('expenses'),
      Provider.of<WalletService>(context, listen: false),
      Provider.of<NotificationService>(context, listen: false),
      Provider.of<FirebaseFirestore>(context, listen: false),
      _categoryService,
    );

    if (_expenseService.initializationComplete != null) {
      print('RecentExpensesScreen: Awaiting ExpenseService initialization...');
      await _expenseService.initializationComplete;
      print('RecentExpensesScreen: ExpenseService initialization COMPLETE');
    }
    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _expenseService.getAllExpenses();
    setState(() {
      _expenses = expenses;
      _filterExpenses();
    });
  }

  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        // Category and Month filter (if provided)
        if (widget.categoryForMonthFilter != null && widget.monthForCategoryFilter != null) {
          bool matchesCategoryAndMonth = expense.categoryId == widget.categoryForMonthFilter &&
              expense.date.year == widget.monthForCategoryFilter!.year &&
              expense.date.month == widget.monthForCategoryFilter!.month;
          if (!matchesCategoryAndMonth) return false;
        }

        // Search in categoryId, note, and amount
        final matchesSearch = _searchQuery.isEmpty || 
            expense.categoryId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (expense.note?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
            expense.amount.toString().contains(_searchQuery);
            
        // Category filter
        final matchesCategory = _selectedCategory == 'All' || expense.categoryId == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
      
      // Sort by date (most recent first)
      _filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Map<String, List<Expense>> _groupExpensesByTimeline() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final groupedExpenses = {
      'Today': <Expense>[],
      'This Week': <Expense>[],
      'Earlier': <Expense>[],
    };

    for (var expense in _filteredExpenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (expenseDate == today) {
        groupedExpenses['Today']!.add(expense);
      } else if (expenseDate.isAfter(startOfWeek)) {
        groupedExpenses['This Week']!.add(expense);
      } else {
        groupedExpenses['Earlier']!.add(expense);
      }
    }

    return groupedExpenses;
  }

  Widget _buildExpenseItem(Expense expense) {
    final formatter = NumberFormat.currency(symbol: '\$');
    final categoryNameToDisplay = _categoryService.getCategoryNameById(expense.categoryId, defaultName: expense.categoryId); 
    final iconData = _getCategoryIcon(categoryNameToDisplay);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              expense: expense,
              expenseService: _expenseService,
              onExpenseUpdated: _loadExpenses,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color: const Color(0xFF1B4332),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryNameToDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        expense.note!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(expense.amount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  DateFormat('MMM d, y').format(expense.date),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(String title, List<Expense> expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...expenses.map((expense) => _buildExpenseItem(expense)).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedExpenses = _selectedCategory == 'All'  && widget.categoryForMonthFilter == null
        ? _groupExpensesByTimeline()
        : {'': _filteredExpenses};

    // If filtering by a specific category and month, don't show timeline groups
    final shouldShowTimeline = widget.categoryForMonthFilter == null && _selectedCategory == 'All';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.categoryForMonthFilter != null 
              ? '${widget.categoryForMonthFilter} Expenses (${DateFormat('MMMM yyyy').format(widget.monthForCategoryFilter!)})' 
              : 'Recent Expenses',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterExpenses();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by category, note, or amount...',
                prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF1B4332)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFE9F1EC).withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                'All',
                'Rent',
                'Groceries',
                'Transport',
                'Shopping',
                'Entertainment',
                'Other'
              ].map((category) {
                final isSelected = _selectedCategory == category;
                // Disable category filter chips if a specific category is already passed as a filter
                final bool isChipDisabled = widget.categoryForMonthFilter != null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(category),
                    onSelected: isChipDisabled ? null : (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All'; // Default to 'All' if deselected
                        _filterExpenses();
                      });
                    },
                    backgroundColor: isChipDisabled ? Colors.grey[300] : Colors.grey[100],
                    selectedColor: const Color(0xFFE9F1EC),
                    labelStyle: GoogleFonts.inter(
                      color: isChipDisabled ? Colors.grey[500] : (isSelected ? const Color(0xFF1B4332) : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredExpenses.isEmpty
              ? Center(
                  child: Text(
                    widget.categoryForMonthFilter != null && _searchQuery.isEmpty
                        ? 'No expenses for ${widget.categoryForMonthFilter} in ${DateFormat('MMMM yyyy').format(widget.monthForCategoryFilter!)}'
                        : 'No expenses found',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView(
                  children: shouldShowTimeline
                    ? [
                        _buildTimelineSection('Today', groupedExpenses['Today']!),
                        _buildTimelineSection('This Week', groupedExpenses['This Week']!),
                        _buildTimelineSection('Earlier', groupedExpenses['Earlier']!),
                        const SizedBox(height: 24), // Bottom padding
                      ]
                    : [
                        const SizedBox(height: 8),
                        ..._filteredExpenses.map((expense) => _buildExpenseItem(expense)).toList(),
                        const SizedBox(height: 24), // Bottom padding
                      ],
                ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return CupertinoIcons.house_fill;
      case 'groceries':
        return CupertinoIcons.cart_fill;
      case 'transport':
        return CupertinoIcons.car_fill;
      case 'shopping':
        return CupertinoIcons.bag_fill;
      case 'entertainment':
        return CupertinoIcons.film_fill;
      case 'bills':
        return CupertinoIcons.doc_text_fill;
      case 'health':
        return CupertinoIcons.heart_fill;
      default:
        return CupertinoIcons.money_dollar_circle_fill;
    }
  }
} 