import '../models/receipt.dart';
import 'dart:math';

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
  
  /// Generic fallback parser for unknown receipt formats
  Receipt parseGenericReceipt(Map<String, dynamic> ocrData, String userId) {
    // Try to identify the vendor
    final vendorName = _extractVendorName(ocrData) ?? 'Unknown Vendor';
    
    // Extract location if possible
    final location = _extractLocation(ocrData) ?? 'Unknown Location';
    
    // Extract date if possible
    final date = _extractDate(ocrData) ?? DateTime.now();
    
    // Try to extract total amount
    final total = _extractTotal(ocrData);
    
    // Create a receipt with minimal information
    return Receipt(
      userId: userId,
      vendorName: vendorName,
      location: location,
      date: date,
      items: [], // No line items parsed
      subtotal: total * 0.9, // Estimate subtotal as 90% of total
      tax: total * 0.1, // Estimate tax as 10% of total
      total: total,
      rawOcrData: ocrData,
      notes: 'This receipt was processed using generic parsing. Please review for accuracy.',
    );
  }
  
  /// Detect receipt format and use appropriate parser
  Receipt parseReceipt(Map<String, dynamic> ocrData, String userId) {
    // Check if we can identify the store chain from text
    final fullText = _extractFullText(ocrData).toLowerCase();
    
    // Check for known store chains
    if (fullText.contains('mercadona')) {
      return parseVeryfiData(ocrData, userId); // For now using Veryfi parser
    } else if (fullText.contains('carrefour')) {
      return parseCarrefourReceipt(ocrData, userId);
    } else if (fullText.contains('alcampo')) {
      return parseVeryfiData(ocrData, userId); // For now using Veryfi parser
    }
    
    // If no known format is detected, use generic parser
    final receipt = parseGenericReceipt(ocrData, userId);
    
    // Mark for review
    final updatedJson = receipt.toJson();
    updatedJson['needsReview'] = true;
    
    return Receipt.fromJson(updatedJson);
  }
  
  /// Parse a Carrefour receipt format
  Receipt parseCarrefourReceipt(Map<String, dynamic> ocrData, String userId) {
    final fullText = _extractFullText(ocrData);
    final lines = fullText.split('\n');
    
    // Extract vendor details
    String vendorName = 'Carrefour';
    if (ocrData['vendor']?['name'] != null) {
      vendorName = ocrData['vendor']['name'];
    } else {
      // Try to find it in the first few lines
      for (int i = 0; i < min(3, lines.length); i++) {
        if (lines[i].toLowerCase().contains('carrefour')) {
          vendorName = lines[i].trim();
          break;
        }
      }
    }
    
    // Extract location
    String location = 'Unknown Location';
    final addressRegex = RegExp(r'(?:Calle|Av\.|Avenida|Plaza)\s+[\w\s,]+\d+', caseSensitive: false);
    for (final line in lines) {
      final match = addressRegex.firstMatch(line);
      if (match != null) {
        location = match.group(0)!;
        // Try to add city/zip if on the next line
        final index = lines.indexOf(line);
        if (index < lines.length - 1) {
          final nextLine = lines[index + 1].trim();
          if (RegExp(r'\d{5}').hasMatch(nextLine)) {
            location += ', $nextLine';
          }
        }
        break;
      }
    }
    
    // Extract date
    DateTime date = DateTime.now();
    if (ocrData['date'] != null) {
      try {
        date = DateTime.parse(ocrData['date']);
      } catch (_) {
        // Try to extract using regex from lines
        final dateRegex = RegExp(r'Fecha:?\s*(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})', caseSensitive: false);
        for (final line in lines) {
          final match = dateRegex.firstMatch(line);
          if (match != null) {
            try {
              final day = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              var year = int.parse(match.group(3)!);
              if (year < 100) year += 2000;
              date = DateTime(year, month, day);
              break;
            } catch (_) {}
          }
        }
      }
    }
    
    // Extract totals
    double subtotal = 0.0;
    double tax = 0.0;
    double total = 0.0;
    
    // For predefined values
    if (ocrData['subtotal'] != null) subtotal = _parseDouble(ocrData['subtotal']);
    if (ocrData['tax'] != null) tax = _parseDouble(ocrData['tax']);
    if (ocrData['total'] != null) total = _parseDouble(ocrData['total']);
    
    // Otherwise, extract from lines
    if (subtotal == 0.0) {
      final subtotalRegex = RegExp(r'SUBTOTAL:?\s*(\d+[,.]\d+)', caseSensitive: false);
      for (final line in lines) {
        final match = subtotalRegex.firstMatch(line);
        if (match != null) {
          subtotal = _parseDouble(match.group(1));
          break;
        }
      }
    }
    
    if (tax == 0.0) {
      final taxRegex = RegExp(r'IVA.*?:?\s*(\d+[,.]\d+)', caseSensitive: false);
      for (final line in lines) {
        final match = taxRegex.firstMatch(line);
        if (match != null) {
          tax = _parseDouble(match.group(1));
          break;
        }
      }
    }
    
    if (total == 0.0) {
      final totalRegex = RegExp(r'TOTAL:?\s*(\d+[,.]\d+)', caseSensitive: false);
      for (final line in lines) {
        final match = totalRegex.firstMatch(line);
        if (match != null) {
          total = _parseDouble(match.group(1));
          break;
        }
      }
    }
    
    // Extract line items
    final items = <ReceiptItem>[];
    
    // Skip header lines and footer lines
    bool processingItems = false;
    final itemRegex = RegExp(r'^(.*?)\s+(\d+[,.]\d+)€?$');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Skip empty lines
      if (trimmedLine.isEmpty) continue;
      
      // Skip separator lines
      if (trimmedLine.contains('-----')) {
        if (!processingItems) {
          processingItems = true; // Start processing items after first separator
        } else {
          processingItems = false; // Stop after second separator
        }
        continue;
      }
      
      // Skip header/total lines
      if (trimmedLine.contains('SUBTOTAL:') || 
          trimmedLine.contains('IVA') || 
          trimmedLine.contains('TOTAL:') ||
          trimmedLine.contains('TARJETA:') ||
          trimmedLine.contains('GRACIAS')) {
        continue;
      }
      
      if (processingItems) {
        final match = itemRegex.firstMatch(trimmedLine);
        if (match != null) {
          final name = match.group(1)!.trim();
          final priceStr = match.group(2)!;
          final price = _parseDouble(priceStr);
          
          // Default to quantity 1 (most Carrefour receipts don't show quantity directly)
          final quantity = 1;
          
          // Categorize the item
          final category = _categorizeItem(name);
          
          items.add(ReceiptItem(
            name: name,
            unitPrice: price,
            quantity: quantity,
            totalPrice: price,
            category: category,
          ));
        }
      }
    }
    
    return Receipt(
      userId: userId,
      vendorName: vendorName,
      location: location,
      date: date,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      rawOcrData: ocrData,
    );
  }
  
  /// Extract full text from OCR data (different for different OCR providers)
  String _extractFullText(Map<String, dynamic> ocrData) {
    // For Veryfi
    if (ocrData['text'] != null) {
      return ocrData['text'].toString();
    }
    
    // For Mindee
    if (ocrData['document']?['inference']?['prediction']?['raw_text']?['value'] != null) {
      return ocrData['document']['inference']['prediction']['raw_text']['value'].toString();
    }
    
    // Try to construct text from line items
    final buffer = StringBuffer();
    
    // For Veryfi line items
    if (ocrData['line_items'] != null) {
      for (final item in ocrData['line_items']) {
        if (item['description'] != null) {
          buffer.writeln(item['description']);
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// Extract vendor name from OCR data
  String? _extractVendorName(Map<String, dynamic> ocrData) {
    // For Veryfi
    if (ocrData['vendor']?['name'] != null) {
      return ocrData['vendor']['name'];
    }
    
    // For Mindee
    if (ocrData['document']?['inference']?['prediction']?['supplier']?['value'] != null) {
      return ocrData['document']['inference']['prediction']['supplier']['value'];
    }
    
    return null;
  }
  
  /// Extract location from OCR data
  String? _extractLocation(Map<String, dynamic> ocrData) {
    // Try Veryfi format
    try {
      return _extractLocationFromVeryfi(ocrData);
    } catch (_) {}
    
    // For Mindee or generic format
    final fullText = _extractFullText(ocrData);
    final addressRegex = RegExp(r'(?:calle|av\.|avenida|plaza)\s+[\w\s,]+\d+', caseSensitive: false);
    final match = addressRegex.firstMatch(fullText);
    
    if (match != null) {
      return match.group(0);
    }
    
    return null;
  }
  
  /// Extract date from OCR data
  DateTime? _extractDate(Map<String, dynamic> ocrData) {
    // For Veryfi
    if (ocrData['date'] != null) {
      try {
        return DateTime.parse(ocrData['date']);
      } catch (_) {}
    }
    
    // For Mindee
    if (ocrData['document']?['inference']?['prediction']?['date']?['value'] != null) {
      try {
        return DateTime.parse(ocrData['document']['inference']['prediction']['date']['value']);
      } catch (_) {}
    }
    
    // Try to extract from full text using regex
    final fullText = _extractFullText(ocrData);
    
    // Common date formats in Spain/LatAm receipts (DD/MM/YYYY or DD-MM-YYYY)
    final dateRegex = RegExp(r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})');
    final match = dateRegex.firstMatch(fullText);
    
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        var year = int.parse(match.group(3)!);
        
        // Handle 2-digit years
        if (year < 100) {
          year += 2000;
        }
        
        return DateTime(year, month, day);
      } catch (_) {}
    }
    
    return null;
  }
  
  /// Extract total amount from OCR data
  double _extractTotal(Map<String, dynamic> ocrData) {
    // For Veryfi
    if (ocrData['total'] != null) {
      return _parseDouble(ocrData['total']);
    }
    
    // For Mindee
    if (ocrData['document']?['inference']?['prediction']?['total_amount']?['value'] != null) {
      return _parseDouble(ocrData['document']['inference']['prediction']['total_amount']['value']);
    }
    
    // Try to extract from full text using regex
    final fullText = _extractFullText(ocrData);
    
    // Look for typical total patterns in Spanish receipts
    final totalRegex = RegExp(r'total:?\s*(\d+[.,]\d+)', caseSensitive: false);
    final match = totalRegex.firstMatch(fullText);
    
    if (match != null) {
      try {
        return _parseDouble(match.group(1));
      } catch (_) {}
    }
    
    return 0.0;
  }
} 