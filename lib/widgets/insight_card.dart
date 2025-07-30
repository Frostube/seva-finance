import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/insight.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showActions;

  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(insight.id),
      direction:
          showActions ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: onDismiss != null ? (_) => onDismiss!() : null,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: insight.isRead ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(),
              width: insight.isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.04), // Subtle SevaFinance shadow
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                        12), // SevaFinance standard padding
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          12), // SevaFinance standard radius
                    ),
                    child: Icon(
                      _getIconForInsightType(insight.type),
                      color: _getPriorityColor(),
                      size: 24, // SevaFinance standard icon size
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getInsightTypeTitle(),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(
                                      0xFF1A1A1A), // SevaFinance text color
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (insight.value != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          _getPriorityColor().withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getValueDisplay(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _getPriorityColor(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (!insight.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(
                                          0xFF1B4332), // SevaFinance primary
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • h:mm a')
                              .format(insight.generatedAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(
                                0xFF757575), // SevaFinance secondary text color
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getSimplifiedMessage(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: insight.isRead
                      ? const Color(0xFF757575)
                      : const Color(0xFF1A1A1A), // SevaFinance colors
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Value badge moved to header, removed from body
              if (showActions) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Primary action button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: Icon(
                            _getIconForInsightAction(_getPrimaryActionLabel()),
                            size: 16),
                        label: Text(
                          _getPrimaryActionLabel(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                              0xFF1B4332), // SevaFinance primary button color
                          foregroundColor: Colors.white,
                          elevation: 2, // SevaFinance subtle elevation
                          padding: const EdgeInsets.symmetric(
                              vertical: 14), // SevaFinance button height
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                24), // SevaFinance rounded buttons
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Secondary actions
                    if (!insight.isRead)
                      IconButton(
                        onPressed: onTap,
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: const Color(
                              0xFF757575), // SevaFinance secondary color
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                              0xFFF5F5F5), // SevaFinance light background
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                12), // SevaFinance standard radius
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: onDismiss,
                      icon: Icon(
                        Icons.more_vert,
                        color: const Color(
                            0xFF757575), // SevaFinance secondary color
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                            0xFFF5F5F5), // SevaFinance light background
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              12), // SevaFinance standard radius
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (insight.priority) {
      case InsightPriority.critical:
        return Colors.red;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.medium:
        return const Color(0xFF1B4332); // SevaFinance primary green
      case InsightPriority.low:
        return const Color(0xFF1B4332); // SevaFinance primary green
    }
  }

  Color _getBorderColor() {
    if (insight.isRead) return Colors.grey[300]!;
    return _getPriorityColor().withOpacity(0.3);
  }

  IconData _getIconForInsightType(InsightType type) {
    switch (type) {
      case InsightType.overspend:
        return Icons.warning_amber_outlined;
      case InsightType.forecastBalance:
        return Icons.insights_outlined;
      case InsightType.categoryTrend:
        return Icons.bar_chart;
      case InsightType.budgetAlert:
        return Icons.notifications_active_outlined;
      case InsightType.savingOpportunity:
        return Icons.savings_outlined;
      case InsightType.unusualSpending:
        return Icons.trending_up;
      case InsightType.monthlyComparison:
        return Icons.calendar_today_outlined;
      case InsightType.overspend: // Corrected from largeExpense to overspend
        return Icons.money_off_csred_outlined;
      case InsightType.general:
      default:
        return Icons.info_outline;
    }
  }

  String _getPrimaryActionLabel() {
    // Removed check for insight.actionText as it's not part of the Insight model
    switch (insight.type) {
      case InsightType.overspend:
      case InsightType.categoryTrend:
        return 'Review Budget';
      case InsightType.budgetAlert:
        return 'Set Alert';
      case InsightType.forecastBalance:
        return 'View Details';
      case InsightType.monthlyComparison:
        return 'View Report';
      case InsightType.savingOpportunity:
        return 'Set Goal';
      case InsightType.unusualSpending:
        return 'View Transactions';
      case InsightType.overspend: // Corrected from largeExpense to overspend
        return 'View Expense';
      default:
        return 'Learn More';
    }
  }

  IconData _getIconForInsightAction(String action) {
    switch (action) {
      case 'Review Budget':
        return Icons.tune;
      case 'Set Alert':
        return Icons.notifications_none;
      case 'View Details':
        return Icons.list_alt;
      case 'View Report':
        return Icons.bar_chart;
      case 'Set Goal':
        return Icons.add_circle_outline;
      case 'View Transactions':
        return Icons.search;
      case 'View Expense':
        return Icons.receipt_long;
      case 'Learn More':
        return Icons.arrow_forward;
      default:
        return Icons.info_outline;
    }
  }

  String _getInsightTypeTitle() {
    switch (insight.type) {
      case InsightType.overspend:
        return 'Overspending Alert';
      case InsightType.forecastBalance:
        return 'Balance Forecast';
      case InsightType.categoryTrend:
        return 'Category Trend';
      case InsightType.budgetAlert:
        return 'Budget Alert';
      case InsightType.savingOpportunity:
        return 'Saving Opportunity';
      case InsightType.unusualSpending:
        return 'Unusual Spending';
      case InsightType.monthlyComparison:
        return 'Monthly Comparison';
      case InsightType.general:
        return 'Insight';
    }
  }

  String _getValueDisplay() {
    if (insight.value == null) return '';

    switch (insight.type) {
      case InsightType.forecastBalance:
        return '\$${insight.value!.toStringAsFixed(2)}';
      case InsightType.overspend:
      case InsightType.categoryTrend:
      case InsightType.monthlyComparison:
        return '${insight.value!.toStringAsFixed(1)}%';
      case InsightType.budgetAlert:
        if (insight.value! > 100) {
          return '\$${(insight.value! - 100).toStringAsFixed(2)} over';
        } else {
          return '${insight.value!.toStringAsFixed(1)}% used';
        }
      case InsightType.savingOpportunity:
        return '\$${insight.value!.toStringAsFixed(2)} saved';
      case InsightType.unusualSpending:
        return '\$${insight.value!.toStringAsFixed(2)}/day';
      case InsightType.general:
        return insight.value!.toStringAsFixed(2);
    }
  }

  String _getSimplifiedMessage() {
    switch (insight.type) {
      case InsightType.overspend:
        return 'Spending up ${insight.value?.toStringAsFixed(1)}% vs last month';
      case InsightType.forecastBalance:
        return 'Projected month-end: \$${insight.value?.toStringAsFixed(2)}';
      case InsightType.categoryTrend:
        final categoryName = insight.categoryId?.split(' ').first ?? 'Category';
        return '$categoryName spending: \$${insight.value?.toStringAsFixed(2)}';
      case InsightType.budgetAlert:
        return 'Budget ${insight.value?.toStringAsFixed(1)}% used';
      case InsightType.savingOpportunity:
        return 'Saved \$${insight.value?.toStringAsFixed(2)} vs last month';
      case InsightType.unusualSpending:
        return 'Daily spend above 30-day average';
      default:
        return insight.text.length > 50
            ? '${insight.text.substring(0, 50)}...'
            : insight.text;
    }
  }
}
