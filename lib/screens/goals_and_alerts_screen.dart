import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/savings_goal.dart';
import '../models/spending_alert.dart';
import '../services/spending_alert_service.dart';
import '../services/savings_goal_service.dart';
import 'set_savings_goal_sheet.dart';
import 'set_spending_alert_sheet.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class GoalsAndAlertsScreen extends StatefulWidget {
  final String walletId;
  final SpendingAlertService spendingAlertService;
  final SavingsGoalService savingsGoalService;

  const GoalsAndAlertsScreen({
    super.key,
    required this.walletId,
    required this.spendingAlertService,
    required this.savingsGoalService,
  });

  @override
  State<GoalsAndAlertsScreen> createState() => _GoalsAndAlertsScreenState();
}

class _GoalsAndAlertsScreenState extends State<GoalsAndAlertsScreen> {
  List<SavingsGoal> _goals = [];
  List<SpendingAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _goals = widget.savingsGoalService.goals.where((goal) => goal.walletId == widget.walletId).toList();
      _alerts = widget.spendingAlertService.alerts.where((alert) => alert.walletId == widget.walletId).toList();
    });
  }

  void _showAddGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetSavingsGoalSheet(
        walletId: widget.walletId,
        savingsService: widget.savingsGoalService,
        onGoalAdded: _loadData,
      ),
    );
  }

  void _showAddAlertSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetSpendingAlertSheet(
        walletId: widget.walletId,
        savingsService: widget.spendingAlertService,
        onAlertAdded: _loadData,
      ),
    );
  }

  Future<void> _deleteGoal(String goalId) async {
    await widget.savingsGoalService.deleteGoal(goalId);
    _loadData();
  }

  Future<void> _deleteAlert(String alertId) async {
    await widget.spendingAlertService.deleteSpendingAlert(alertId);
    _loadData();
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.name ?? 'Unnamed Goal',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  onPressed: () => _deleteGoal(goal.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Target: \$${NumberFormat.decimalPattern().format(goal.targetAmount)}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Due: ${DateFormat('MMM d, yyyy').format(goal.targetDate)}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.getProgress(Provider.of<WalletService>(context, listen: false).getAllWallets().firstWhere((w) => w.id == widget.walletId).balance),
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B4332)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SpendingAlert alert) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending Alert',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  onPressed: () => _deleteAlert(alert.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${alert.type == AlertType.percentage ? 'Percentage' : 'Fixed Amount'}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Threshold: ${alert.getDisplayThreshold()}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
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
      appBar: AppBar(
        title: Text(
          'Goals & Alerts',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Savings Goals',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_goals.isEmpty)
              Center(
                child: Text(
                  'No savings goals yet',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              ..._goals.map(_buildGoalCard),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddGoalSheet,
              icon: const Icon(CupertinoIcons.plus),
              label: const Text('Add Savings Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Spending Alerts',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_alerts.isEmpty)
              Center(
                child: Text(
                  'No spending alerts yet',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              ..._alerts.map(_buildAlertCard),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddAlertSheet,
              icon: const Icon(CupertinoIcons.plus),
              label: const Text('Add Spending Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 