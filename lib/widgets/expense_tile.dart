import 'package:flutter/material.dart';
import 'package:seva_finance/models/expense.dart';
import 'package:seva_finance/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/category_service.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;

  const ExpenseTile({
    super.key,
    required this.expense,
  });

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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: expense.amount.truncateToDouble() == expense.amount ? 0 : 2,
    );
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final categoryName = categoryService.getCategoryNameById(expense.categoryId, defaultName: expense.categoryId);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getCategoryIcon(categoryName),
          color: AppColors.primary,
        ),
      ),
      title: Text(
        categoryName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        expense.note ?? '',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Text(
        currencyFormat.format(expense.amount),
        style: TextStyle(
          color: expense.amount < 0 ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
} 