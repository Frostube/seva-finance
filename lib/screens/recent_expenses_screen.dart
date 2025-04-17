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

class RecentExpensesScreen extends StatefulWidget {
  final ExpenseService expenseService;

  const RecentExpensesScreen({
    Key? key,
    required this.expenseService,
  }) : super(key: key);

  @override
  State<RecentExpensesScreen> createState() => _RecentExpensesScreenState();
}

class _RecentExpensesScreenState extends State<RecentExpensesScreen> {
  late final ExpenseService _expenseService;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  String _searchQuery = '';
  String? _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _expenseService = ExpenseService(
      Provider.of<StorageService>(context, listen: false),
      Hive.box<double>('budget'),
      Hive.box<Expense>('expenses'),
      Provider.of<WalletService>(context, listen: false),
      Provider.of<NotificationService>(context, listen: false),
    );
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _expenseService.getAllExpenses();
    setState(() {
      _expenses = expenses;
    });
  }

  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        // Search in category, note, and amount
        final matchesSearch = _searchQuery.isEmpty || 
            expense.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (expense.note?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
            expense.amount.toString().contains(_searchQuery);
            
        // Category filter
        final matchesCategory = _selectedCategory == 'All' || expense.category == _selectedCategory;
        
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
                _getCategoryIcon(expense.category),
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
                    expense.category,
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
    final groupedExpenses = _selectedCategory == 'All' 
        ? _groupExpensesByTimeline()
        : {'': _filteredExpenses};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Recent Expenses',
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
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(category),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                        _filterExpenses();
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: const Color(0xFFE9F1EC),
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? const Color(0xFF1B4332) : Colors.black87,
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
                    'No expenses found',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView(
                  children: _selectedCategory == 'All'
                    ? [
                        _buildTimelineSection('Today', groupedExpenses['Today']!),
                        _buildTimelineSection('This Week', groupedExpenses['This Week']!),
                        _buildTimelineSection('Earlier', groupedExpenses['Earlier']!),
                        const SizedBox(height: 24), // Bottom padding
                      ]
                    : [
                        const SizedBox(height: 8),
                        ...groupedExpenses['']!.map((expense) => _buildExpenseItem(expense)).toList(),
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