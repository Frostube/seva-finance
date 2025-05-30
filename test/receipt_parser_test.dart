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
    
    test('parseReceipt should detect and mark unknown formats for review', () {
      // Mock OCR data with unknown format
      final mockOcrData = {
        'text': 'Some random receipt text without known vendor',
        'total': '15.99',
      };
      
      // Parse with the generic method
      final receipt = receiptParser.parseReceipt(mockOcrData, mockUserId);
      
      // Verify it's marked for review
      expect(receipt.needsReview, true);
      expect(receipt.total, 15.99);
    });
    
    test('parseReceipt should properly handle Carrefour receipts', () {
      // Mock Carrefour receipt OCR data
      final mockOcrData = {
        'text': '''
CARREFOUR EXPRESS
Calle Gran Via, 54
Madrid 28013
CIF: A-12345678
Tel: 910 000 000
-----------------------
Ticket: 1234
Fecha: 12/05/2023 17:30
-----------------------
LECHE SEMI 1L     1,25€
PAN BARRA         0,75€
TOMATE FRITO      1,45€
QUESO FRESCO      2,35€
MANZANAS 1KG      1,99€
-----------------------
SUBTOTAL:         7,79€
IVA (10%):        0,78€
TOTAL:            8,57€
-----------------------
TARJETA:          8,57€
-----------------------
GRACIAS POR SU VISITA
        ''',
        'vendor': {'name': 'CARREFOUR EXPRESS'},
        'date': '2023-05-12',
        'total': '8.57',
      };
      
      // Parse with our receipt parser
      final receipt = receiptParser.parseReceipt(mockOcrData, mockUserId);
      
      // Verify basic receipt data
      expect(receipt.vendorName, 'CARREFOUR EXPRESS');
      expect(receipt.date.year, 2023);
      expect(receipt.date.month, 5);
      expect(receipt.date.day, 12);
      expect(receipt.total, 8.57);
      
      // This test should initially fail because we need to implement Carrefour-specific parsing
      // Verify items were parsed correctly
      expect(receipt.items.length, 5, reason: 'Should parse all 5 items from the Carrefour receipt');
      
      // Check specific items
      final milkItem = receipt.items.firstWhere((item) => item.name.contains('LECHE'));
      expect(milkItem.totalPrice, 1.25);
      expect(milkItem.category, ItemCategory.dairy);
      
      final breadItem = receipt.items.firstWhere((item) => item.name.contains('PAN'));
      expect(breadItem.totalPrice, 0.75);
      expect(breadItem.category, ItemCategory.bakery);
      
      final appleItem = receipt.items.firstWhere((item) => item.name.contains('MANZANAS'));
      expect(appleItem.totalPrice, 1.99);
      expect(appleItem.category, ItemCategory.produce);
    });
  });
} 