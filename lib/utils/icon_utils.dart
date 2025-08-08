import 'package:flutter/material.dart';

class IconUtils {
  /// Convert icon name string to Material Icons IconData (unified set)
  static IconData getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'house_fill':
      case 'house':
        return Icons.home_filled;
      case 'cart_fill':
      case 'cart':
        return Icons.shopping_cart;
      case 'car_fill':
      case 'car':
        return Icons.directions_car_filled;
      case 'film_fill':
      case 'film':
        return Icons.movie;
      case 'bag_fill':
      case 'bag':
        return Icons.shopping_bag;
      case 'money_dollar_circle_fill':
      case 'money_dollar_circle':
      case 'money':
        return Icons.attach_money;
      case 'book_fill':
      case 'book':
        return Icons.menu_book;
      case 'heart_fill':
      case 'heart':
        return Icons.favorite;
      case 'briefcase_fill':
      case 'briefcase':
        return Icons.work;
      case 'shield_fill':
      case 'shield':
        return Icons.shield;
      case 'doc_text_fill':
      case 'doc_text':
      case 'doc':
        return Icons.description;
      case 'airplane':
        return Icons.flight;
      case 'circle_fill':
      case 'circle':
        return Icons.circle;
      case 'help_outline':
      case 'help':
        return Icons.help_outline;
      default:
        return Icons.circle;
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
