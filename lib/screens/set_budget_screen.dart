import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/wallet_service.dart';
import 'package:provider/provider.dart';

class SetBudgetScreen extends StatefulWidget {
  final double currentBudget;
  final Function onBudgetUpdated;

  const SetBudgetScreen({
    super.key,
    required this.currentBudget,
    required this.onBudgetUpdated,
  });

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
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

  Future<void> _saveBudget() async {
    if (_budgetController.text.isNotEmpty) {
      final additionalBudget = double.tryParse(_budgetController.text.replaceAll(',', ''));
      if (additionalBudget != null) {
        final primaryWallet = _walletService.getPrimaryWallet();
        if (primaryWallet != null) {
          final newBudget = (primaryWallet.budget ?? 0.0) + additionalBudget;
          await _walletService.setWalletBudget(primaryWallet.id, newBudget);
          widget.onBudgetUpdated();
        }
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add to Budget',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveBudget,
            child: Text(
              'Add',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B4332),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to your monthly budget',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current budget: \$${widget.currentBudget.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
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
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle,
                    color: Color(0xFF1B4332),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This amount will be added to your current budget',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 