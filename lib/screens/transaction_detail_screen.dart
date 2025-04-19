import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'package:uuid/uuid.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Expense expense;
  final ExpenseService expenseService;
  final VoidCallback onExpenseUpdated;
  
  const TransactionDetailScreen({
    Key? key,
    required this.expense,
    required this.expenseService,
    required this.onExpenseUpdated,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Expense _expense;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
    _noteController.text = _expense.note ?? '';
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
                    onPressed: () {
                      Navigator.pop(context);
                      _saveChanges();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _expense.date,
                onDateTimeChanged: (date) {
                  setState(() {
                    _expense = Expense(
                      id: _expense.id,
                      amount: _expense.amount,
                      category: _expense.category,
                      date: date,
                      note: _expense.note,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                            _expense = Expense(
                              id: _expense.id,
                              amount: _expense.amount,
                              category: categories[index],
                              date: _expense.date,
                              note: _expense.note,
                            );
                          });
                          Navigator.pop(context);
                          _saveChanges();
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          categories[index],
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: _expense.category == categories[index] 
                                ? const Color(0xFF1B4332)
                                : Colors.black,
                            fontWeight: _expense.category == categories[index] 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: _expense.category == categories[index]
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
                          _expense = Expense(
                            id: _expense.id,
                            amount: _expense.amount,
                            category: categoryController.text,
                            date: _expense.date,
                            note: _expense.note,
                          );
                        });
                        Navigator.pop(context);
                        _saveChanges();
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

  void _showAmountEditor() {
    final TextEditingController amountController = TextEditingController();
    amountController.text = NumberFormat.currency(symbol: '\$').format(_expense.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Amount',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  color: const Color(0xFF1B4332),
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  String numbers = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (numbers.isEmpty) numbers = '0';
                  double amount = int.parse(numbers) / 100;
                  amountController.text = NumberFormat.currency(symbol: '\$').format(amount);
                  amountController.selection = TextSelection.fromPosition(
                    TextPosition(offset: amountController.text.length),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        String text = amountController.text;
                        text = text.replaceAll(RegExp(r'[^\d.]'), '');
                        final amount = double.tryParse(text) ?? 0.0;
                        setState(() {
                          _expense = Expense(
                            id: _expense.id,
                            amount: amount,
                            category: _expense.category,
                            date: _expense.date,
                            note: _expense.note,
                          );
                        });
                        Navigator.pop(context);
                        _saveChanges();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    // Update the expense with the current note
    _expense = Expense(
      id: _expense.id,
      amount: _expense.amount,
      category: _expense.category,
      date: _expense.date,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    try {
      await widget.expenseService.updateExpense(_expense);
      widget.onExpenseUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save changes. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.expenseService.deleteExpense(_expense.id);
      widget.onExpenseUpdated();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildDetailRow(String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 17,
                color: Colors.grey[600],
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    color: Colors.black,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.xmark,
            color: Colors.black,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Expense',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          CupertinoButton(
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: const Color(0xFF1B4332),
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              _saveChanges();
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          // Amount
          GestureDetector(
            onTap: _showAmountEditor,
            child: Column(
              children: [
                Text(
                  formatter.format(_expense.amount),
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 8),
                // Category
                Text(
                  _expense.category,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Details Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'Date',
                  DateFormat('MMM d, y').format(_expense.date),
                  _showDatePicker,
                ),
                _buildDetailRow(
                  'Category',
                  _expense.category,
                  _showCategoryPicker,
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Add a note...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 17,
                            color: Colors.grey[400],
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onEditingComplete: _saveChanges,
                        onSubmitted: (_) => _saveChanges(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Delete Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: _deleteExpense,
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
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }
} 