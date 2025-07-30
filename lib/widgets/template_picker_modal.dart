import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/budget_template.dart';
import '../services/budget_template_service.dart';
import '../screens/budget_creation_screen.dart';
import '../screens/template_management_screen.dart';
import 'loading_widget.dart';

class TemplatePickerModal extends StatefulWidget {
  final String walletId;
  final VoidCallback onTemplateSelected;

  const TemplatePickerModal({
    super.key,
    required this.walletId,
    required this.onTemplateSelected,
  });

  @override
  State<TemplatePickerModal> createState() => _TemplatePickerModalState();
}

class _TemplatePickerModalState extends State<TemplatePickerModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose Budget Template',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TemplateManagementScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Manage',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1B4332),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer<BudgetTemplateService>(
              builder: (context, templateService, child) {
                if (templateService.isLoading) {
                  return const CenterLoadingWidget();
                }

                final templates = templateService.templates;

                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No templates available',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            templateService.refresh();
                          },
                          child: Text(
                            'Refresh',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1B4332),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return _buildTemplateCard(template, templateService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
      BudgetTemplate template, BudgetTemplateService templateService) {
    // Get template items for this template
    final templateItems = templateService.getTemplateItems(template.id);

    // Debug: Print template items and their amounts
    // Debug info for template selection
    debugPrint('Template: ${template.name} (${template.id})');
    debugPrint('Template items count: ${templateItems.length}');
    for (final item in templateItems) {
      debugPrint('  - ${item.categoryId}: \$${item.defaultAmount}');
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetCreationScreen(
              walletId: widget.walletId,
              selectedTemplate: template,
              templateItems: templateItems,
              onBudgetCreated: widget.onTemplateSelected,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (template.isSystem)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'System',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF1B4332),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template.timelineDisplayText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1B4332),
                    ),
                  ),
                ),
                if (template.endDateDisplayText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Until ${template.endDateDisplayText}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (templateItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${templateItems.length} categories • \$${templateItems.fold(0.0, (sum, item) => sum + item.defaultAmount).toStringAsFixed(0)} total',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap to use template',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF1B4332),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF1B4332),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
