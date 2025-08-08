import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/add_expense_screen.dart';
import '../screens/ocr_screen.dart'; // Corrected import
import 'package:provider/provider.dart';

class AddOptionsBottomSheet extends StatelessWidget {
  const AddOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Semantics(
        container: true,
        label: 'Add new options',
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24.0),
              _buildOption(
                  context, Icons.account_balance_wallet_outlined, 'Add Expense',
                  () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddExpenseScreen(
                              expenseService:
                                  Provider.of(context, listen: false),
                              onExpenseAdded: () {},
                            )));
              }),
              const SizedBox(height: 16.0),
              _buildOption(context, Icons.camera_alt, 'Scan Receipt', () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const OcrScreen())); // Corrected class name
              }),
              const SizedBox(height: 24.0),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkDarkGreen
              : AppTheme.lightGreen.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28.0),
            const SizedBox(width: 16.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: Theme.of(context).textTheme.headlineMedium?.color,
                size: 24.0),
          ],
        ),
      ),
    );
  }
}
