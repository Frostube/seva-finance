import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/budget_template.dart';
import '../services/budget_template_service.dart';
import '../services/category_service.dart';
import '../utils/icon_utils.dart';
import 'budget_creation_screen.dart';

class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() =>
      _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  late BudgetTemplateService _templateService;
  late CategoryService _categoryService;

  @override
  void initState() {
    super.initState();
    _templateService =
        Provider.of<BudgetTemplateService>(context, listen: false);
    _categoryService = Provider.of<CategoryService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Templates',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<BudgetTemplateService>(
        builder: (context, templateService, child) {
          final userTemplates = templateService.templates
              .where((template) => !template.isSystem)
              .toList();

          if (userTemplates.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userTemplates.length,
            itemBuilder: (context, index) {
              final template = userTemplates[index];
              return _buildTemplateCard(template);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Custom Templates',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create budget templates to reuse\nyour favorite budget configurations',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BudgetTemplate template) {
    final templateItems = _templateService.getTemplateItems(template.id);
    final totalBudget =
        templateItems.fold(0.0, (sum, item) => sum + item.defaultAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header with template info
          Padding(
            padding: const EdgeInsets.all(16),
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
                            template.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            template.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: Colors.grey[600],
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editTemplate(template, templateItems);
                            break;
                          case 'delete':
                            _showDeleteConfirmation(template);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.pencil, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Edit Template',
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.trash,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Delete Template',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Template metadata
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4332).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        template.timelineDisplayText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1B4332),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (template.endDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Expires ${DateFormat('MMM dd').format(template.endDate!)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                          .format(totalBudget),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Template items preview
          if (templateItems.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories (${templateItems.length})',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...templateItems.take(3).map((item) {
                    final category =
                        _categoryService.getCategoryById(item.categoryId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: IconUtils.getCategoryIconColor(
                                      item.categoryId)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconUtils.getIconFromName(
                                  category?.icon ?? 'money_dollar_circle'),
                              color: IconUtils.getCategoryIconColor(
                                  item.categoryId),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category?.name ?? 'Unknown Category',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                                    symbol: '\$', decimalDigits: 0)
                                .format(item.defaultAmount),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (templateItems.length > 3) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+ ${templateItems.length - 3} more categories',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editTemplate(BudgetTemplate template, List<dynamic> templateItems) {
    // Navigate to budget creation screen in edit mode
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetCreationScreen(
          walletId: '', // Not needed for template editing
          selectedTemplate: template,
          templateItems: templateItems.cast(),
          isEditingTemplate: true,
          onBudgetCreated: () {
            // Refresh the template list
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BudgetTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Template',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${template.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTemplate(template);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(BudgetTemplate template) async {
    try {
      final success = await _templateService.deleteTemplate(template.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template "${template.name}" deleted successfully',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete template',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
 