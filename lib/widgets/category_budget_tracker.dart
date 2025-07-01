import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/category_budget_service.dart';
import '../services/category_service.dart';
import '../models/category_budget.dart';
import '../utils/icon_utils.dart';
import 'loading_widget.dart';

class CategoryBudgetTracker extends StatefulWidget {
  final String walletId;
  final DateTime month;
  final Function(DateTime)? onMonthChanged;
  final VoidCallback? onChooseTemplate;
  final VoidCallback? onEditBudget;

  const CategoryBudgetTracker({
    Key? key,
    required this.walletId,
    required this.month,
    this.onMonthChanged,
    this.onChooseTemplate,
    this.onEditBudget,
  }) : super(key: key);

  @override
  State<CategoryBudgetTracker> createState() => _CategoryBudgetTrackerState();
}

class _CategoryBudgetTrackerState extends State<CategoryBudgetTracker>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false; // Collapsed by default

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryBudgetService>(
      builder: (context, categoryBudgetService, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: categoryBudgetService.getCategoryBudgetOverview(
            widget.walletId,
            widget.month,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CenterLoadingWidget();
            }

            if (!snapshot.hasData || snapshot.data!['budgetDetails'].isEmpty) {
              return _buildNoBudgetsCard();
            }

            final overview = snapshot.data!;
            final budgetDetails =
                overview['budgetDetails'] as List<Map<String, dynamic>>;

            return _buildOverviewCard(overview);
          },
        );
      },
    );
  }

  Widget _buildNoBudgetsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.chart_pie, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Category Budgets Set',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a budget from a template to track spending by category',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Template picker call-to-action
          GestureDetector(
            onTap: widget.onChooseTemplate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.chart_pie_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Choose Template',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> overview) {
    final totalBudget = overview['totalBudget'] as double;
    final totalSpent = overview['totalSpent'] as double;
    final categoriesOverBudget = overview['categoriesOverBudget'] as int;
    final progress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final remaining = totalBudget - totalSpent;

    return GestureDetector(
      onTap: () {
        print('Budget Overview tapped! Current expanded state: $_isExpanded');
        setState(() {
          _isExpanded = !_isExpanded;
          print('Budget Overview expanded state changed to: $_isExpanded');
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1B4332), const Color(0xFF2D5A3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4332).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Overview',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Month display (navigation arrows commented out - can be restored if needed)
                      Text(
                        DateFormat('MMMM yyyy').format(widget.month),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      /* COMMENTED OUT - Month navigation arrows (can be restored later if needed)
                      Row(
                        children: [
                          if (widget.onMonthChanged != null) ...[
                            GestureDetector(
                              onTap: () {
                                final previousMonth = DateTime(
                                    widget.month.year, widget.month.month - 1);
                                widget.onMonthChanged!(previousMonth);
                              },
                              child: Icon(
                                CupertinoIcons.chevron_left,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            DateFormat('MMMM yyyy').format(widget.month),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.onMonthChanged != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final nextMonth = DateTime(
                                    widget.month.year, widget.month.month + 1);
                                final now = DateTime.now();
                                // Only allow navigation to current month or earlier
                                if (nextMonth.isBefore(
                                    DateTime(now.year, now.month + 1))) {
                                  widget.onMonthChanged!(nextMonth);
                                }
                              },
                              child: Icon(
                                CupertinoIcons.chevron_right,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                      */
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (categoriesOverBudget > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '$categoriesOverBudget over budget',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[100],
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (popupContext) => PopupMenuButton<String>(
                        icon: Icon(
                          CupertinoIcons.ellipsis_vertical,
                          color: Colors.white,
                          size: 20,
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit_budget') {
                            widget.onEditBudget?.call();
                          } else if (value == 'clear_template') {
                            await _showClearTemplateDialog(popupContext);
                          }
                        },
                        itemBuilder: (context) => [
                          if (widget.onEditBudget != null)
                            PopupMenuItem<String>(
                              value: 'edit_budget',
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.pencil,
                                    color: const Color(0xFF1B4332),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Edit Budget',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF1B4332),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          PopupMenuItem<String>(
                            value: 'clear_template',
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.trash,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Clear Template',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Spent',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(totalSpent),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Budget',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(totalBudget),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getProgressColor(progress),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% of total budget used',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Row(
                  children: [
                    if (totalBudget > 0)
                      Text(
                        totalBudget > totalSpent
                            ? '${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(remaining)} left'
                            : '${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(-remaining)} over budget',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: totalBudget > totalSpent
                              ? Colors.white.withOpacity(0.9)
                              : Colors.red[200],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Show detailed breakdown with smooth animation
            AnimatedSize(
              duration: const Duration(
                milliseconds: 600,
              ), // Longer duration to be more noticeable
              curve: Curves.elasticOut, // More dramatic curve
              child: _isExpanded
                  ? AnimatedOpacity(
                      opacity: _isExpanded ? 1.0 : 0.0,
                      duration: const Duration(
                        milliseconds: 500,
                      ), // Longer fade
                      curve: Curves.easeInOut,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category Breakdown',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildCompactCategoryList(
                                  overview['budgetDetails']
                                      as List<Map<String, dynamic>>,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCategoryList(List<Map<String, dynamic>> budgetDetails) {
    return Column(
      children: budgetDetails.map((detail) {
        final categoryName = detail['categoryName'] as String;
        final categoryId = detail['categoryId'] as String;
        final budgetAmount = detail['budgetAmount'] as double;
        final currentSpending = detail['currentSpending'] as double;
        final progress = detail['progress'] as double;
        final status = detail['status'] as BudgetStatus;
        final percentageSpent = (progress * 100).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              // Category icon
              Consumer<CategoryService>(
                builder: (context, categoryService, child) {
                  final category = categoryService.getCategoryById(categoryId);
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        IconUtils.getIconFromName(
                          category?.icon ?? 'money_dollar_circle',
                        ),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category name and percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoryName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCompactStatusColor(
                                  status,
                                ).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$percentageSpent%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getCompactStatusColor(status),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              budgetAmount > currentSpending
                                  ? '\$${(budgetAmount - currentSpending).toStringAsFixed(0)} left'
                                  : '\$${(currentSpending - budgetAmount).toStringAsFixed(0)} over',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: budgetAmount > currentSpending
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.red[300],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Spending amount
                    Text(
                      '\$${currentSpending.toStringAsFixed(0)} out of \$${budgetAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getCompactStatusColor(status),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: _getCompactStatusColor(
                                  status,
                                ).withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCompactStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.underSpent:
        return Colors.green[300]!;
      case BudgetStatus.onTrack:
        return Colors.blue[300]!;
      case BudgetStatus.warning:
        return Colors.orange[300]!;
      case BudgetStatus.overBudget:
        return Colors.red[300]!;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.red;
    if (progress >= 0.8) return Colors.orange;
    if (progress >= 0.5) return Colors.blue;
    return Colors.green;
  }

  Future<void> _showClearTemplateDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Budget Template',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove all category budgets for this month. You can create a new budget from scratch or apply a different template.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Clear Template',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearCurrentTemplate(context);
    }
  }

  Future<void> _clearCurrentTemplate(BuildContext context) async {
    try {
      final categoryBudgetService = Provider.of<CategoryBudgetService>(
        context,
        listen: false,
      );

      // Clear all category budgets for this wallet and month
      await categoryBudgetService.clearCategoryBudgetsForMonth(
        widget.walletId,
        widget.month,
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget template cleared successfully',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to clear template: ${e.toString()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
