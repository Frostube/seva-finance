import '../models/receipt.dart';

/// Service to parse OCR data into structured Receipt models
class ReceiptParser {
  /// Parse Veryfi OCR data into a Receipt object
  Receipt parseVeryfiData(Map<String, dynamic> ocrData, String userId) {
    final vendor = ocrData['vendor']?['name'] ?? 'Unknown Vendor';
    final location = _extractLocationFromVeryfi(ocrData);
    final date = _parseDate(ocrData['date']);
    
    final items = <ReceiptItem>[];
    if (ocrData['line_items'] != null) {
      for (final item in ocrData['line_items']) {
        try {
          final name = item['description'] ?? '';
          final unitPrice = _parseDouble(item['unit_price']);
          final quantity = _parseInt(item['quantity']);
          final totalPrice = _parseDouble(item['total']);
          final category = _categorizeItem(name);
          
          items.add(ReceiptItem(
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            totalPrice: totalPrice,
            category: category,
          ));
        } catch (e) {
          print('Error parsing line item: $e');
        }
      }
    }
    
    final subtotal = _parseDouble(ocrData['subtotal']);
    final tax = _parseDouble(ocrData['tax']);
    final total = _parseDouble(ocrData['total']);
    
    return Receipt(
      userId: userId,
      vendorName: vendor,
      location: location,
      date: date,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      rawOcrData: ocrData,
    );
  }
  
  /// Parse Mindee OCR data into a Receipt object
  Receipt parseMindeeData(Map<String, dynamic> ocrData, String userId) {
    final document = ocrData['document'] ?? {};
    final inference = document['inference'] ?? {};
    final prediction = inference['prediction'] ?? {};
    
    final vendor = prediction['supplier']?['value'] ?? 'Unknown Vendor';
    final location = _extractLocationFromMindee(prediction);
    final date = _parseDateFromMindee(prediction);
    
    final items = <ReceiptItem>[];
    if (prediction['line_items'] != null) {
      for (final item in prediction['line_items']) {
        try {
          final name = item['description']?['value'] ?? '';
          final unitPrice = _parseDouble(item['unit_price']?['value']);
          final quantity = _parseInt(item['quantity']?['value']);
          final totalPrice = _parseDouble(item['total_amount']?['value']);
          final category = _categorizeItem(name);
          
          items.add(ReceiptItem(
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            totalPrice: totalPrice,
            category: category,
          ));
        } catch (e) {
          print('Error parsing line item: $e');
        }
      }
    }
    
    final subtotal = _parseDouble(prediction['total_net']?['value']);
    final tax = _parseDouble(prediction['total_tax']?['value']);
    final total = _parseDouble(prediction['total_amount']?['value']);
    
    return Receipt(
      userId: userId,
      vendorName: vendor,
      location: location,
      date: date,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      rawOcrData: ocrData,
    );
  }
  
  /// Categorize an item based on its name
  ItemCategory _categorizeItem(String itemName) {
    final name = itemName.toLowerCase();
    
    // Common grocery items and their categories
    final categoryMap = {
      // Dairy
      'milk': ItemCategory.dairy,
      'cheese': ItemCategory.dairy,
      'yogurt': ItemCategory.dairy,
      'butter': ItemCategory.dairy,
      'cream': ItemCategory.dairy,
      'leche': ItemCategory.dairy, // Spanish for milk
      
      // Meat
      'beef': ItemCategory.meat,
      'chicken': ItemCategory.meat,
      'pork': ItemCategory.meat,
      'fish': ItemCategory.meat,
      'meat': ItemCategory.meat,
      'carne': ItemCategory.meat, // Spanish for meat
      
      // Produce
      'apple': ItemCategory.produce,
      'banana': ItemCategory.produce,
      'vegetable': ItemCategory.produce,
      'fruit': ItemCategory.produce,
      'tomato': ItemCategory.produce,
      'lettuce': ItemCategory.produce,
      'fruta': ItemCategory.produce, // Spanish for fruit
      'verdura': ItemCategory.produce, // Spanish for vegetable
      
      // Bakery
      'bread': ItemCategory.bakery,
      'cake': ItemCategory.bakery,
      'pastry': ItemCategory.bakery,
      'pan': ItemCategory.bakery, // Spanish for bread
      
      // Beverages
      'water': ItemCategory.beverages,
      'soda': ItemCategory.beverages,
      'juice': ItemCategory.beverages,
      'coffee': ItemCategory.beverages,
      'tea': ItemCategory.beverages,
      'wine': ItemCategory.beverages,
      'beer': ItemCategory.beverages,
      'agua': ItemCategory.beverages, // Spanish for water
      
      // Household
      'detergent': ItemCategory.household,
      'soap': ItemCategory.household,
      'cleaners': ItemCategory.household,
      'paper': ItemCategory.household,
      'towel': ItemCategory.household,
      
      // Personal Care
      'shampoo': ItemCategory.personalCare,
      'deodorant': ItemCategory.personalCare,
      'toothpaste': ItemCategory.personalCare,
    };
    
    // Check if the item name contains any of the keywords
    for (final entry in categoryMap.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default to grocery if no specific category is found
    return ItemCategory.grocery;
  }
  
  /// Helper method to extract location from Veryfi OCR data
  String _extractLocationFromVeryfi(Map<String, dynamic> ocrData) {
    final vendor = ocrData['vendor'] ?? {};
    final address = vendor['address'] ?? '';
    final city = vendor['city'] ?? '';
    final state = vendor['state'] ?? '';
    
    if (address.isNotEmpty) {
      return address;
    } else if (city.isNotEmpty || state.isNotEmpty) {
      return '$city, $state'.trim().replaceAll(RegExp(r'^,\s*|\s*,$'), '');
    }
    
    return 'Unknown Location';
  }
  
  /// Helper method to extract location from Mindee OCR data
  String _extractLocationFromMindee(Map<String, dynamic> prediction) {
    final supplier = prediction['supplier'] ?? {};
    final address = supplier['address']?['value'] ?? '';
    
    if (address.isNotEmpty) {
      return address;
    }
    
    return 'Unknown Location';
  }
  
  /// Helper method to parse date from OCR data
  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }
    
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  /// Helper method to parse date from Mindee OCR data
  DateTime _parseDateFromMindee(Map<String, dynamic> prediction) {
    final dateStr = prediction['date']?['value'];
    return _parseDate(dateStr);
  }
  
  /// Helper method to parse double values from OCR data
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(RegExp(r'[^\d.]'), ''));
      } catch (e) {
        return 0.0;
      }
    }
    
    return 0.0;
  }
  
  /// Helper method to parse int values from OCR data
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value.replaceAll(RegExp(r'[^\d]'), ''));
      } catch (e) {
        return 0;
      }
    }
    
    return 0;
  }
} 