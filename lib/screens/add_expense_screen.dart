import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';
import 'package:uuid/uuid.dart';

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
  String _selectedCategory = 'Groceries';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      _amountController.text = NumberFormat.currency(symbol: '\$').format(widget.initialExpense!.amount);
      _selectedCategory = widget.initialExpense!.categoryId;
      _selectedDate = widget.initialExpense!.date;
      _noteController.text = widget.initialExpense!.note ?? '';
    } else {
      _formatAmount('0');
    }
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

    final newExpense = Expense(
      id: widget.initialExpense?.id ?? _uuid.v4(),
      amount: amount,
      categoryId: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );
    print('AddExpenseScreen: Expense object created. ID: ${newExpense.id}, CategoryID: ${newExpense.categoryId}, Amount: ${newExpense.amount}'); // LOG

    try {
    if (widget.initialExpense != null) {
        print('AddExpenseScreen: BEFORE calling expenseService.updateExpense'); // LOG
        await widget.expenseService.updateExpense(newExpense); // Changed from addExpense to updateExpense for existing
        print('AddExpenseScreen: AFTER calling expenseService.updateExpense'); // LOG
    } else {
        print('AddExpenseScreen: BEFORE calling expenseService.addExpense'); // LOG
        await widget.expenseService.addExpense(newExpense);
        print('AddExpenseScreen: AFTER calling expenseService.addExpense'); // LOG
    }
    
      print('AddExpenseScreen: BEFORE calling onExpenseAdded callback.'); // LOG
    widget.onExpenseAdded();
      print('AddExpenseScreen: AFTER onExpenseAdded callback.'); // LOG
      
    Navigator.pop(context, true);
      print('AddExpenseScreen: Popped context.'); // LOG
    } catch (e) {
      print('AddExpenseScreen: Error saving expense: $e'); // LOG
      // Optionally, show a SnackBar or dialog for the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving expense: $e')),
      );
    }
  }

  void _showCategoryPicker() {
    final categories = ['Groceries', 'Transportation', 'Shopping', 'Entertainment', 'Bills', 'Health', 'Other'];

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
                itemCount: categories.length + 2, // +2 for separator and create new
                itemBuilder: (context, index) {
                  if (index < categories.length) {
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedCategory = categories[index];
                          });
                          Navigator.pop(context);
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          categories[index],
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: _selectedCategory == categories[index] 
                                ? const Color(0xFF1B4332)
                                : Colors.black,
                            fontWeight: _selectedCategory == categories[index] 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: _selectedCategory == categories[index]
                            ? const Icon(
                                CupertinoIcons.checkmark,
                                color: Color(0xFF1B4332),
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  } else if (index == categories.length) {
                    return const Divider(height: 1);
                  } else {
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () {
                          // First close the current sheet
                          Navigator.pop(context);
                          // Then show the create category dialog
                          _showCreateCategoryDialog();
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F1EC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.plus,
                            size: 18,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        title: Text(
                          'Create New Category',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: const Color(0xFF1B4332),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          0, 0, 0, MediaQuery.of(context).viewInsets.bottom
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                    'New Category',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      if (categoryController.text.isNotEmpty) {
                        setState(() {
                          _selectedCategory = categoryController.text;
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 17,
                ),
                decoration: InputDecoration(
                  hintText: 'Category Name',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 17,
                    color: Colors.grey[400],
                  ),
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
              ),
              const SizedBox(height: 16),
            ],
          ),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  value: _selectedCategory,
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
                    'Save Expense',
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
} 