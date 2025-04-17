import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/spending_alert.dart';
import '../services/savings_service.dart';

class SetSpendingAlertSheet extends StatefulWidget {
  final String walletId;
  final SavingsService savingsService;
  final Function() onAlertAdded;

  const SetSpendingAlertSheet({
    super.key,
    required this.walletId,
    required this.savingsService,
    required this.onAlertAdded,
  });

  @override
  State<SetSpendingAlertSheet> createState() => _SetSpendingAlertSheetState();
}

class _SetSpendingAlertSheetState extends State<SetSpendingAlertSheet> {
  final _thresholdController = TextEditingController();
  AlertType _selectedType = AlertType.percentage;
  bool _isLoading = false;

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveAlert() async {
    if (_thresholdController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final alert = SpendingAlert(
        id: DateTime.now().toString(),
        walletId: widget.walletId,
        type: _selectedType,
        threshold: double.parse(_thresholdController.text.replaceAll(',', '')),
      );

      await widget.savingsService.addSpendingAlert(alert);
      if (mounted) {
        widget.onAlertAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving alert: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set Spending Alert',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CupertinoSlidingSegmentedControl<AlertType>(
            groupValue: _selectedType,
            children: const {
              AlertType.percentage: Text('Percentage'),
              AlertType.fixedAmount: Text('Fixed Amount'),
            },
            onValueChanged: (type) => setState(() => _selectedType = type!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _selectedType == AlertType.percentage
                  ? 'Threshold Percentage'
                  : 'Threshold Amount',
              suffixText: _selectedType == AlertType.percentage ? '%' : '\$',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveAlert,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Save Alert',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 