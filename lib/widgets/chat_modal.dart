import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import 'chat_bubble.dart';

class ChatModal extends StatefulWidget {
  const ChatModal({super.key});

  @override
  State<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<ChatModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _chatService.loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _chatService.sendMessage(message);
    _messageController.clear();

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask Seva AI',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Your financial assistant',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Messages Area
            Expanded(
              child: Consumer<ChatService>(
                builder: (context, chatService, child) {
                  if (chatService.messages.isEmpty) {
                    return _buildWelcomeMessage();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatService.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatService.messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatBubble(message: message),
                      );
                    },
                  );
                },
              ),
            ),

            // Loading indicator
            Consumer<ChatService>(
              builder: (context, chatService, child) {
                if (!chatService.isLoading) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.paleGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.darkGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thinking...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.paleGreen.withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.paleGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText:
                            'Ask about your spending, balance, or budgets...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.secondaryTextColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatService>(
                    builder: (context, chatService, child) {
                      return IconButton(
                        onPressed: chatService.isLoading ? null : _sendMessage,
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: chatService.isLoading
                                ? Colors.grey.shade300
                                : AppTheme.darkGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            CupertinoIcons.arrow_up,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightGreen.withOpacity(0.3),
                  AppTheme.paleGreen.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              CupertinoIcons.sparkles,
              size: 36,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hi! I\'m Seva AI',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal financial assistant. Ask me anything about your spending, budgets, or financial goals!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.secondaryTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestedQuery('What\'s my balance?'),
              _buildSuggestedQuery('How much did I spend this month?'),
              _buildSuggestedQuery('Coffee spending'),
              _buildSuggestedQuery('Budget analysis'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuery(String query) {
    return GestureDetector(
      onTap: () {
        _messageController.text = query;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.lightGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.darkGreen.withOpacity(0.3),
          ),
        ),
        child: Text(
          query,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.darkGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
