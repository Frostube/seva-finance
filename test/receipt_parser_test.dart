import 'package:flutter_test/flutter_test.dart';
import 'package:seva_finance/models/receipt.dart';
import 'package:seva_finance/services/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    final receiptParser = ReceiptParser();
    final mockUserId = 'test_user_123';

    test('parseVeryfiData should correctly parse dairy items', () {
      // Mock Veryfi OCR data with a dairy item (milk)
      final mockOcrData = {
        'vendor': {
          'name': 'Test Supermarket',
          'address': '123 Main St',
          'city': 'Test City',
          'state': 'TS'
        },
        'date': '2023-05-15',
        'line_items': [
          {
            'description': 'LECHE ENTERA 1L',  // Spanish for "whole milk 1L"
            'unit_price': '0.75',
            'quantity': '3',
            'total': '2.25'
          }
        ],
        'subtotal': '2.25',
        'tax': '0.20',
        'total': '2.45'
      };
      
      // Parse the mock data
      final receipt = receiptParser.parseVeryfiData(mockOcrData, mockUserId);
      
      // Verify the receipt general data
      expect(receipt.vendorName, 'Test Supermarket');
      expect(receipt.location, '123 Main St');
      expect(receipt.date.year, 2023);
      expect(receipt.date.month, 5);
      expect(receipt.date.day, 15);
      expect(receipt.subtotal, 2.25);
      expect(receipt.tax, 0.2);
      expect(receipt.total, 2.45);
      
      // Verify the items array has the correct item
      expect(receipt.items.length, 1);
      
      // Verify the specific item (milk) is categorized as dairy
      final milkItem = receipt.items[0];
      expect(milkItem.name, 'LECHE ENTERA 1L');
      expect(milkItem.unitPrice, 0.75);
      expect(milkItem.quantity, 3);
      expect(milkItem.totalPrice, 2.25);
      expect(milkItem.category, ItemCategory.dairy);
    });

    test('parseVeryfiData should handle empty line items', () {
      // Mock Veryfi OCR data with no items
      final mockOcrData = {
        'vendor': {
          'name': 'Test Shop',
        },
        'date': '2023-06-10',
        'subtotal': '0.00',
        'tax': '0.00',
        'total': '0.00'
      };
      
      // Parse the mock data
      final receipt = receiptParser.parseVeryfiData(mockOcrData, mockUserId);
      
      // Verify the receipt has no items
      expect(receipt.items.length, 0);
    });
  });
} 