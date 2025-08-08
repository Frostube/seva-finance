import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/categorization_service.dart';
// import '../theme/app_theme.dart';

class SuggestionBar extends StatelessWidget {
  final List<CategorySuggestion> suggestions;
  final Function(CategorySuggestion) onSuggestionTap;
  final bool isLoading;

  const SuggestionBar({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Getting suggestions...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          'No suggestions right now.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'AI Suggestions',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return _buildSuggestionChip(context, suggestion);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, CategorySuggestion suggestion) {
    return GestureDetector(
      onTap: () => onSuggestionTap(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getConfidenceColor(suggestion.confidence),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              suggestion.categoryName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
             color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_right_alt,
              size: 14,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) {
      return Colors.green;
    } else if (confidence > 0.6) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
}

class ChipList extends StatelessWidget {
  final List<String> tags;
  final Function(String) onTagTap;

  const ChipList({
    super.key,
    required this.tags,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Tags',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return GestureDetector(
                onTap: () => onTagTap(tag),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
