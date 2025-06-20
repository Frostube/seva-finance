import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import '../services/recurring_transaction_service.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/recurring_transaction.dart';
import '../utils/icon_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final Function() onExpenseAdded;
  final Expense? initialExpense;

  const AddExpenseScreen({
    super.key,
    required this.expenseService,
    required this.onExpenseAdded,
    this.initialExpense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategoryId = '';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final _uuid = const Uuid();

  late CategoryService _categoryService;
  List<ExpenseCategory> _availableCategories = [];

  // Recurring transaction state
  bool _isRecurring = false;
  String _frequency = 'monthly';
  int _interval = 1;
  int? _dayOfMonth;
  String? _dayOfWeek;
  DateTime? _endDate;

  final List<String> _frequencies = ['daily', 'weekly', 'monthly', 'yearly'];
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _categoryService = Provider.of<CategoryService>(context, listen: false);
    _loadCategories();

    if (widget.initialExpense != null) {
      _amountController.text = NumberFormat.currency(symbol: '\$')
          .format(widget.initialExpense!.amount);
      _selectedCategoryId = widget.initialExpense!.categoryId;
      _selectedDate = widget.initialExpense!.date;
      _noteController.text = widget.initialExpense!.note ?? '';
      // Note: Existing expenses can't be made recurring in edit mode
      _isRecurring = false;
    } else {
      _formatAmount('0');
      _initializeRecurringDefaults();
    }
  }

  void _initializeRecurringDefaults() {
    // Set smart defaults based on selected date
    _dayOfMonth = _selectedDate.day;
    _dayOfWeek = _daysOfWeek[_selectedDate.weekday - 1];
  }

  void _loadCategories() {
    setState(() {
      _availableCategories = _categoryService.categories;
      if (_selectedCategoryId.isEmpty && _availableCategories.isNotEmpty) {
        _selectedCategoryId = _availableCategories.first.id;
      }
    });
  }

  void _formatAmount(String value) {
    // Remove any non-digit characters
    String numbers = value.replaceAll(RegExp(r'[^\d]'), '');

    if (numbers.isEmpty) numbers = '0';

    // Convert to decimal (divide by 100 for cents)
    double amount = int.parse(numbers) / 100;

    // Format with currency
    final formatter = NumberFormat.currency(symbol: '\$');
    _amountController.text = formatter.format(amount);

    // Maintain cursor position at the end
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
  }

  double _getAmountValue() {
    String text = _amountController.text;
    text = text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(text) ?? 0.0;
  }

  void _saveExpense() async {
    print('AddExpenseScreen: _saveExpense called.'); // LOG
    final amount = _getAmountValue();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    try {
      if (_isRecurring && widget.initialExpense == null) {
        // Create recurring transaction instead of one-time expense
        await _saveRecurringTransaction(amount);
      } else {
        // Create or update one-time expense
        final newExpense = Expense(
          id: widget.initialExpense?.id ?? _uuid.v4(),
          amount: amount,
          categoryId: _selectedCategoryId,
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
        print(
            'AddExpenseScreen: Expense object created. ID: ${newExpense.id}, CategoryID: ${newExpense.categoryId}, Amount: ${newExpense.amount}'); // LOG

        if (widget.initialExpense != null) {
          print(
              'AddExpenseScreen: BEFORE calling expenseService.updateExpense'); // LOG
          await widget.expenseService.updateExpense(newExpense);
          print(
              'AddExpenseScreen: AFTER calling expenseService.updateExpense'); // LOG
        } else {
          print(
              'AddExpenseScreen: BEFORE calling expenseService.addExpense'); // LOG
          await widget.expenseService.addExpense(newExpense);
          print(
              'AddExpenseScreen: AFTER calling expenseService.addExpense'); // LOG
        }
      }

      print('AddExpenseScreen: BEFORE calling onExpenseAdded callback.'); // LOG
      widget.onExpenseAdded();
      print('AddExpenseScreen: AFTER onExpenseAdded callback.'); // LOG

      Navigator.pop(context, true);
      print('AddExpenseScreen: Popped context.'); // LOG
    } catch (e) {
      print('AddExpenseScreen: Error saving expense: $e'); // LOG
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  Future<void> _saveRecurringTransaction(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Calculate next occurrence
    DateTime nextOccurrence = _selectedDate;

    final recurringTransaction = RecurringTransaction(
      id: _uuid.v4(),
      name: _noteController.text.isEmpty
          ? 'Recurring ${_categoryService.getCategoryNameById(_selectedCategoryId)}'
          : _noteController.text,
      amount: amount,
      categoryId: _selectedCategoryId,
      isExpense: true,
      frequency: _frequency,
      interval: _interval,
      dayOfMonth: _frequency == 'monthly' ? _dayOfMonth : null,
      dayOfWeek: _frequency == 'weekly' ? _dayOfWeek : null,
      startDate: _selectedDate,
      endDate: _endDate,
      nextOccurrence: nextOccurrence,
      createdBy: user.uid,
      createdAt: DateTime.now(),
    );

    final recurringService =
        Provider.of<RecurringTransactionService>(context, listen: false);
    await recurringService.createRecurringTransaction(recurringTransaction);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Recurring ${_frequency} expense created successfully!'),
          backgroundColor: const Color(0xFF40916C),
        ),
      );
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: Colors.grey[600],
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Select Category',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Category List
            Expanded(
              child: ListView.builder(
                itemCount: _availableCategories.length,
                itemBuilder: (context, index) {
                  final category = _availableCategories[index];
                  final isSelected = _selectedCategoryId == category.id;

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                        Navigator.pop(context);
                      },
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: IconUtils.getCategoryIconColor(category.id)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          IconUtils.getIconFromName(category.icon),
                          color: IconUtils.getCategoryIconColor(category.id),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: isSelected
                              ? const Color(0xFF1B4332)
                              : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              CupertinoIcons.checkmark,
                              color: Color(0xFF1B4332),
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Add Expense',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Amount Section
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                TextField(
                  controller: _amountController,
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B4332),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _formatAmount,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Interactive Sections
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Category
                _buildInteractiveField(
                  label: 'Category',
                  value: _getCategoryDisplayName(),
                  icon: CupertinoIcons.tag_fill,
                  onTap: _showCategoryPicker,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // Date
                _buildInteractiveField(
                  label: 'Date',
                  value: DateFormat('MMM d, y').format(_selectedDate),
                  icon: CupertinoIcons.calendar,
                  onTap: _showDatePicker,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Note Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Focus the text field when tapping anywhere in the container
                  FocusScope.of(context).requestFocus(_noteFocusNode);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F1EC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.pencil,
                              size: 20,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Note',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Add a note...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 17,
                            color: Colors.grey[400],
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Recurring Transaction Section (only for new expenses)
          if (widget.initialExpense == null) ...[
            const SizedBox(height: 16),
            _buildRecurringSection(),
          ],

          const SizedBox(height: 32),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Save Button
                ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isRecurring ? 'Create Recurring Expense' : 'Save Expense',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Delete Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInteractiveField({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    bool isTextField = false,
    TextEditingController? controller,
    String? hintText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F1EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF1B4332),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isTextField)
                      TextField(
                        controller: controller,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hintText,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 17,
                            color: Colors.grey[400],
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else
                      Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isTextField)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 20,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryDisplayName() {
    if (_selectedCategoryId.isEmpty) return 'Select Category';
    final category = _categoryService.getCategoryById(_selectedCategoryId);
    return category?.name ?? 'Unknown Category';
  }

  Widget _buildRecurringSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Recurring Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F1EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.repeat,
                    size: 20,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make this recurring',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Automatically create this expense on schedule',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                      if (value) {
                        _initializeRecurringDefaults();
                      }
                    });
                  },
                  activeColor: const Color(0xFF40916C),
                ),
              ],
            ),
          ),

          // Recurring Options (shown when toggle is on)
          if (_isRecurring) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Frequency
            _buildInteractiveField(
              label: 'Frequency',
              value: _getFrequencyDisplayText(),
              icon: CupertinoIcons.clock,
              onTap: _showFrequencyPicker,
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Interval
            _buildInteractiveField(
              label: 'Repeat every',
              value: '$_interval ${_getIntervalUnit()}',
              icon: CupertinoIcons.number,
              onTap: _showIntervalPicker,
            ),

            // Day selection (for weekly/monthly)
            if (_frequency == 'weekly') ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildInteractiveField(
                label: 'Day of week',
                value: _dayOfWeek ?? 'Select day',
                icon: CupertinoIcons.calendar_today,
                onTap: _showDayOfWeekPicker,
              ),
            ],

            if (_frequency == 'monthly') ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildInteractiveField(
                label: 'Day of month',
                value: _dayOfMonth != null ? 'Day $_dayOfMonth' : 'Select day',
                icon: CupertinoIcons.calendar_today,
                onTap: _showDayOfMonthPicker,
              ),
            ],

            const Divider(height: 1, indent: 16, endIndent: 16),

            // End Date (optional)
            _buildInteractiveField(
              label: 'End date (optional)',
              value: _endDate != null
                  ? DateFormat('MMM d, y').format(_endDate!)
                  : 'Never expires',
              icon: CupertinoIcons.calendar_badge_minus,
              onTap: _showEndDatePicker,
            ),
          ],
        ],
      ),
    );
  }

  String _getFrequencyDisplayText() {
    switch (_frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Monthly';
    }
  }

  String _getIntervalUnit() {
    switch (_frequency) {
      case 'daily':
        return _interval == 1 ? 'day' : 'days';
      case 'weekly':
        return _interval == 1 ? 'week' : 'weeks';
      case 'monthly':
        return _interval == 1 ? 'month' : 'months';
      case 'yearly':
        return _interval == 1 ? 'year' : 'years';
      default:
        return 'months';
    }
  }

  void _showFrequencyPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Frequency',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _frequency = _frequencies[index];
                    _initializeRecurringDefaults();
                  });
                },
                children: _frequencies
                    .map((freq) => Center(
                          child: Text(
                            _getFrequencyDisplayName(freq),
                            style: GoogleFonts.inter(fontSize: 17),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFrequencyDisplayName(String freq) {
    switch (freq) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Monthly';
    }
  }

  void _showIntervalPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Repeat Every',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController:
                    FixedExtentScrollController(initialItem: _interval - 1),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _interval = index + 1;
                  });
                },
                children: List.generate(
                    12,
                    (index) => Center(
                          child: Text(
                            '${index + 1} ${_getIntervalUnitForNumber(index + 1)}',
                            style: GoogleFonts.inter(fontSize: 17),
                          ),
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIntervalUnitForNumber(int number) {
    switch (_frequency) {
      case 'daily':
        return number == 1 ? 'day' : 'days';
      case 'weekly':
        return number == 1 ? 'week' : 'weeks';
      case 'monthly':
        return number == 1 ? 'month' : 'months';
      case 'yearly':
        return number == 1 ? 'year' : 'years';
      default:
        return number == 1 ? 'month' : 'months';
    }
  }

  void _showDayOfWeekPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Day of Week',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem:
                      _dayOfWeek != null ? _daysOfWeek.indexOf(_dayOfWeek!) : 0,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _dayOfWeek = _daysOfWeek[index];
                  });
                },
                children: _daysOfWeek
                    .map((day) => Center(
                          child: Text(
                            day,
                            style: GoogleFonts.inter(fontSize: 17),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayOfMonthPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Day of Month',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: (_dayOfMonth ?? 1) - 1,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _dayOfMonth = index + 1;
                  });
                },
                children: List.generate(
                    31,
                    (index) => Center(
                          child: Text(
                            'Day ${index + 1}',
                            style: GoogleFonts.inter(fontSize: 17),
                          ),
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'End Date',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  child: Text(
                    'Never',
                    style: GoogleFonts.inter(
                      color: _endDate == null
                          ? const Color(0xFF1B4332)
                          : Colors.grey[600],
                      fontWeight: _endDate == null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _endDate = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                CupertinoButton(
                  child: Text(
                    'Set Date',
                    style: GoogleFonts.inter(
                      color: _endDate != null
                          ? const Color(0xFF1B4332)
                          : Colors.grey[600],
                      fontWeight: _endDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  onPressed: () {
                    // Keep the modal open and show date picker below
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime:
                    _endDate ?? DateTime.now().add(const Duration(days: 365)),
                minimumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() {
                    _endDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
