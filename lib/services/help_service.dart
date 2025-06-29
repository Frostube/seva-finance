import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FAQ {
  final String id;
  final String topic;
  final String question;
  final String answer;

  FAQ({
    required this.id,
    required this.topic,
    required this.question,
    required this.answer,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] as String,
      topic: json['topic'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}

class HelpService {
  static final HelpService _instance = HelpService._internal();
  factory HelpService() => _instance;
  HelpService._internal();

  Map<String, String> _tooltips = {};
  List<FAQ> _faqs = [];
  bool _isLoaded = false;

  // Load help content from JSON
  Future<void> loadHelpContent() async {
    if (_isLoaded) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/help/faqs.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Load tooltips
      if (jsonData.containsKey('tooltips')) {
        _tooltips = Map<String, String>.from(jsonData['tooltips']);
      }

      // Load FAQs
      if (jsonData.containsKey('faqs')) {
        final List<dynamic> faqsList = jsonData['faqs'];
        _faqs = faqsList.map((faq) => FAQ.fromJson(faq)).toList();
      }

      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading help content: $e');
      // Set default content if loading fails
      _setDefaultContent();
      _isLoaded = true;
    }
  }

  // Get tooltip text by key
  String? getTooltip(String key) {
    if (!_isLoaded) return null;
    return _tooltips[key];
  }

  // Get all FAQs
  List<FAQ> getAllFAQs() {
    if (!_isLoaded) return [];
    return List.from(_faqs);
  }

  // Get FAQs by topic
  List<FAQ> getFAQsByTopic(String topic) {
    if (!_isLoaded) return [];
    return _faqs.where((faq) => faq.topic == topic).toList();
  }

  // Search FAQs
  List<FAQ> searchFAQs(String query) {
    if (!_isLoaded || query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _faqs.where((faq) {
      return faq.question.toLowerCase().contains(lowercaseQuery) ||
          faq.answer.toLowerCase().contains(lowercaseQuery) ||
          faq.topic.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get unique topics
  List<String> getTopics() {
    if (!_isLoaded) return [];
    final topics = _faqs.map((faq) => faq.topic).toSet().toList();
    topics.sort();
    return topics;
  }

  // Find FAQ by ID
  FAQ? getFAQById(String id) {
    if (!_isLoaded) return null;
    try {
      return _faqs.firstWhere((faq) => faq.id == id);
    } catch (e) {
      return null;
    }
  }

  // Set default content if JSON loading fails
  void _setDefaultContent() {
    _tooltips = {
      'category': 'A bucket you assign expenses to—e.g. Food, Rent.',
      'budget': 'The maximum amount you plan to spend in a category.',
      'recurring': 'Mark this expense to repeat automatically.',
      'wallet': 'Your current available balance.',
      'savings_goal': 'A target amount you want to save.',
      'spending_alert': 'Get notified when approaching budget limits.',
    };

    _faqs = [
      FAQ(
        id: 'default_1',
        topic: 'Getting Started',
        question: 'How do I get started?',
        answer:
            'Welcome! Start by adding your first expense or setting up a budget.',
      ),
    ];
  }

  // Check if service is loaded
  bool get isLoaded => _isLoaded;
}
