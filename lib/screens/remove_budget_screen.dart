import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import 'package:provider/provider.dart';

class RemoveBudgetScreen extends StatefulWidget {
  final double currentBudget;
  final Function() onBudgetUpdated;

  const RemoveBudgetScreen({
    super.key,
    required this.currentBudget,
    required this.onBudgetUpdated,
  });

  @override
  State<RemoveBudgetScreen> createState() => _RemoveBudgetScreenState();
}

class _RemoveBudgetScreenState extends State<RemoveBudgetScreen> {
  late TextEditingController _budgetController;
  late WalletService _walletService;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController();
    _walletService = Provider.of<WalletService>(context, listen: false);
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _formatBudget(String value) {
    if (value.isEmpty) {
      _budgetController.text = '\$0';
      return;
    }

    // Remove all non-digit characters
    value = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Convert to double and format as currency
    double amount = double.parse(value) / 100;
    String formatted = NumberFormat.currency(symbol: '\$').format(amount);
    
    _budgetController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _removeBudget() async {
    if (_budgetController.text.isEmpty) return;

    // Parse the amount from the controller
    String value = _budgetController.text.replaceAll(RegExp(r'[^\d]'), '');
    double amount = double.parse(value) / 100;

    if (amount <= 0 || amount > widget.currentBudget) {
      // Show error if amount is invalid
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              amount <= 0 
                ? 'Please enter a valid amount' 
                : 'Cannot remove more than current budget (\$${widget.currentBudget})',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get primary wallet
      final primaryWallet = _walletService.getPrimaryWallet();
      if (primaryWallet == null) return;

      // Update wallet with reduced budget
      await _walletService.updateWallet(
        primaryWallet.copyWith(
          budget: primaryWallet.budget! - amount,
        ),
      );

      widget.onBudgetUpdated();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully removed \$${amount.toStringAsFixed(2)} from budget',
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
              'Failed to remove budget. Please try again.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Remove Budget',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                  'Current Budget',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.currency(symbol: '\$').format(widget.currentBudget),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Amount to Remove',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  onChanged: _formatBudget,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '\$0',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
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
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _removeBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Remove Budget',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 