import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          _buildAvatarIcon(),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.darkGreen
                  : AppTheme.paleGreen.withOpacity(0.3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isUser ? Colors.white : AppTheme.textColor,
                    height: 1.4,
                  ),
                ),
                if (message.metadata != null) ...[
                  const SizedBox(height: 8),
                  _buildMetadataWidget(message.metadata!, isUser),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          _buildUserAvatar(),
        ],
      ],
    );
  }

  Widget _buildAvatarIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightGreen.withOpacity(0.3),
            AppTheme.paleGreen.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        CupertinoIcons.sparkles,
        size: 16,
        color: AppTheme.darkGreen,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.darkGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        size: 16,
        color: AppTheme.darkGreen,
      ),
    );
  }

  Widget _buildMetadataWidget(Map<String, dynamic> metadata, bool isUser) {
    final type = metadata['type'] as String?;

    switch (type) {
      case 'balance':
        return _buildBalanceCard(metadata['value'] as double, isUser);
      case 'spending':
        return _buildSpendingCard(metadata, isUser);
      case 'category_spending':
        return _buildCategorySpendingCard(metadata, isUser);
      case 'savings_potential':
        return _buildSavingsCard(metadata['value'] as double, isUser);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBalanceCard(double balance, bool isUser) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withOpacity(0.1)
            : AppTheme.lightGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.money_dollar_circle_fill,
            size: 20,
            color: isUser ? Colors.white : AppTheme.darkGreen,
          ),
          const SizedBox(width: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isUser ? Colors.white : AppTheme.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingCard(Map<String, dynamic> metadata, bool isUser) {
    final value = metadata['value'] as double;
    final period = metadata['period'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withOpacity(0.1)
            : AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.chart_bar_fill,
            size: 20,
            color: isUser ? Colors.white : AppTheme.primaryGreen,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${value.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isUser ? Colors.white : AppTheme.primaryGreen,
                ),
              ),
              if (period != null)
                Text(
                  'This $period',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.orange.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySpendingCard(
      Map<String, dynamic> metadata, bool isUser) {
    final value = metadata['value'] as double;
    final category = metadata['category'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.tag_fill,
            size: 20,
            color: isUser ? Colors.white : Colors.green,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${value.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isUser ? Colors.white : Colors.green,
                ),
              ),
              if (category != null)
                Text(
                  category.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.green.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(double savings, bool isUser) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.arrow_up_circle_fill,
            size: 20,
            color: isUser ? Colors.white : Colors.blue,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${savings.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isUser ? Colors.white : Colors.blue,
                ),
              ),
              Text(
                'Potential savings',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isUser
                      ? Colors.white.withOpacity(0.7)
                      : Colors.blue.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
