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
          CupertinoIcons.delete,
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
                      _getInsightIcon(),
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
                        icon: Icon(_getPrimaryActionIcon(), size: 16),
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
                          CupertinoIcons.checkmark_circle,
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
                        CupertinoIcons.ellipsis,
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
        return const Color(0xFFE53E3E); // SevaFinance red
      case InsightPriority.high:
        return const Color(0xFFFF8A00); // SevaFinance orange
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

  IconData _getInsightIcon() {
    switch (insight.type) {
      case InsightType.overspend:
        return CupertinoIcons.exclamationmark_triangle;
      case InsightType.forecastBalance:
        return CupertinoIcons.graph_circle;
      case InsightType.categoryTrend:
        return CupertinoIcons.chart_bar;
      case InsightType.budgetAlert:
        return CupertinoIcons.bell;
      case InsightType.savingOpportunity:
        return CupertinoIcons.money_dollar_circle;
      case InsightType.unusualSpending:
        return CupertinoIcons.eye;
      case InsightType.monthlyComparison:
        return CupertinoIcons.calendar;
      case InsightType.general:
        return CupertinoIcons.info_circle;
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

  String _getPrimaryActionLabel() {
    switch (insight.type) {
      case InsightType.overspend:
      case InsightType.categoryTrend:
        return 'Set Budget';
      case InsightType.budgetAlert:
        return 'Create Budget';
      case InsightType.forecastBalance:
        return 'Set Alert';
      case InsightType.monthlyComparison:
        return 'Review Spending';
      case InsightType.savingOpportunity:
        return 'Set Alert';
      default:
        return 'Take Action';
    }
  }

  IconData _getPrimaryActionIcon() {
    switch (insight.type) {
      case InsightType.overspend:
      case InsightType.categoryTrend:
        return CupertinoIcons.slider_horizontal_3;
      case InsightType.budgetAlert:
        return CupertinoIcons.plus_circle;
      case InsightType.forecastBalance:
        return CupertinoIcons.bell;
      case InsightType.monthlyComparison:
        return CupertinoIcons.list_bullet;
      case InsightType.savingOpportunity:
        return CupertinoIcons.bell;
      default:
        return CupertinoIcons.arrow_right;
    }
  }
}
