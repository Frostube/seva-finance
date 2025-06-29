import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/analytics.dart';
import '../models/expense.dart';
import 'analytics_service.dart';
import 'expense_service.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
        metadata: json['metadata'],
      );
}

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AnalyticsService _analyticsService;
  final ExpenseService _expenseService;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  ChatService(
    this._firestore,
    this._auth,
    this._analyticsService,
    this._expenseService,
  );

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> loadChatHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('chat_history')
          .doc(user.uid)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(50)
          .get();

      _messages =
          snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> sendMessage(String userMessage) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Add user message
    final userChatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userChatMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // Save user message to Firestore
      await _firestore
          .collection('chat_history')
          .doc(user.uid)
          .collection('messages')
          .doc(userChatMessage.id)
          .set(userChatMessage.toJson());

      // Call the AI service to get response
      final aiResponse = await _callAskSevaFunction(userMessage, user.uid);

      // Add AI response
      final aiChatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: aiResponse['text'] ?? 'Sorry, I couldn\'t process that request.',
        isUser: false,
        timestamp: DateTime.now(),
        metadata: aiResponse['metadata'],
      );

      _messages.add(aiChatMessage);

      // Save AI response to Firestore
      await _firestore
          .collection('chat_history')
          .doc(user.uid)
          .collection('messages')
          .doc(aiChatMessage.id)
          .set(aiChatMessage.toJson());
    } catch (e) {
      debugPrint('Error sending message: $e');

      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Sorry, I\'m having trouble processing your request right now. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _callAskSevaFunction(
      String query, String userId) async {
    // For now, we'll implement a simple local response system
    // In production, this would call a Cloud Function with OpenAI/Cohere integration

    final analytics = _analyticsService.currentAnalytics;
    final recentExpenses = _expenseService.getExpensesByDateRange(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    return _generateLocalResponse(
        query.toLowerCase(), analytics, recentExpenses);
  }

  Map<String, dynamic> _generateLocalResponse(
      String query, Analytics? analytics, List<Expense> recentExpenses) {
    // Simple pattern matching for common queries
    if (query.contains('balance') || query.contains('money left')) {
      final balance = analytics?.currentBalance ?? 0;
      return {
        'text': 'Your current balance is \$${balance.toStringAsFixed(2)}.',
        'metadata': {'type': 'balance', 'value': balance}
      };
    }

    if (query.contains('spent') && query.contains('month')) {
      final monthTotal = analytics?.mtdTotal ?? 0;
      return {
        'text':
            'You\'ve spent \$${monthTotal.toStringAsFixed(2)} this month so far.',
        'metadata': {'type': 'spending', 'period': 'month', 'value': monthTotal}
      };
    }

    if (query.contains('coffee') || query.contains('food')) {
      final foodExpenses = recentExpenses
          .where((e) =>
              e.note?.toLowerCase().contains('coffee') == true ||
              e.note?.toLowerCase().contains('food') == true ||
              e.note?.toLowerCase().contains('restaurant') == true)
          .toList();

      final total = foodExpenses.fold<double>(0, (sum, e) => sum + e.amount);

      return {
        'text':
            'You\'ve spent \$${total.toStringAsFixed(2)} on food and coffee in the last 30 days across ${foodExpenses.length} transactions.',
        'metadata': {
          'type': 'category_spending',
          'category': 'food',
          'value': total
        }
      };
    }

    if (query.contains('budget') || query.contains('overspend')) {
      return {
        'text':
            'Based on your current spending, you\'re on track to stay within your overall budget this month. I can help you set category-specific budgets if needed.',
        'metadata': {'type': 'budget_analysis'}
      };
    }

    if (query.contains('save') || query.contains('saving')) {
      final balance = analytics?.currentBalance ?? 0;
      final avgSpending = analytics?.avg30d ?? 0;
      final potentialSavings =
          balance - (avgSpending * 7); // Week ahead estimate

      return {
        'text':
            'Based on your spending pattern, you could potentially save \$${potentialSavings.toStringAsFixed(2)} this week if you maintain your current pace.',
        'metadata': {'type': 'savings_potential', 'value': potentialSavings}
      };
    }

    // Default response
    return {
      'text':
          'I can help you with questions about your spending, balance, budgets, and savings. Try asking things like "How much did I spend this month?" or "What\'s my current balance?"',
      'metadata': {'type': 'help'}
    };
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
