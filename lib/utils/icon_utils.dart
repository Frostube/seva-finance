import 'package:flutter/cupertino.dart';

class IconUtils {
  /// Convert icon name string to CupertinoIcons IconData
  static IconData getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'house_fill':
        return CupertinoIcons.house_fill;
      case 'cart_fill':
        return CupertinoIcons.cart_fill;
      case 'car_fill':
        return CupertinoIcons.car_fill;
      case 'film_fill':
        return CupertinoIcons.film_fill;
      case 'bag_fill':
        return CupertinoIcons.bag_fill;
      case 'money_dollar_circle_fill':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'book_fill':
        return CupertinoIcons.book_fill;
      case 'heart_fill':
        return CupertinoIcons.heart_fill;
      case 'briefcase_fill':
        return CupertinoIcons.briefcase_fill;
      case 'shield_fill':
        return CupertinoIcons.shield_fill;
      case 'doc_text_fill':
        return CupertinoIcons.doc_text_fill;
      case 'airplane':
        return CupertinoIcons.airplane;
      case 'money_dollar_circle':
        return CupertinoIcons.money_dollar_circle;
      case 'circle_fill':
        return CupertinoIcons.circle_fill;
      case 'help_outline':
        return CupertinoIcons.question_circle;
      // Add more mappings as needed
      default:
        return CupertinoIcons.circle_fill;
    }
  }

  /// Get a nice color for category icons
  static Color getCategoryIconColor(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'housing':
        return const Color(0xFF1B4332);
      case 'food':
        return const Color(0xFFE67E22);
      case 'transportation':
        return const Color(0xFF3498DB);
      case 'entertainment':
        return const Color(0xFF9B59B6);
      case 'shopping':
        return const Color(0xFFE91E63);
      case 'savings':
        return const Color(0xFF27AE60);
      case 'education':
        return const Color(0xFFF39C12);
      case 'personal_care':
        return const Color(0xFFFF69B4);
      case 'business':
        return const Color(0xFF34495E);
      case 'emergency_fund':
        return const Color(0xFFE74C3C);
      case 'taxes':
        return const Color(0xFF8E44AD);
      case 'travel_savings':
        return const Color(0xFF16A085);
      case 'general_savings':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFF1B4332);
    }
  }
}
