import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Category of an item in a receipt
enum ItemCategory {
  grocery,
  dairy,
  meat,
  produce,
  bakery,
  beverages,
  household,
  personalCare,
  electronics,
  clothing,
  dining,
  transportation,
  utilities,
  entertainment,
  other,
}

/// An item within a receipt
class ReceiptItem {
  final String id;
  final String name;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final ItemCategory category;
  
  ReceiptItem({
    String? id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.category,
  }) : id = id ?? const Uuid().v4();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'category': category.toString().split('.').last,
    };
  }
  
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'],
      name: json['name'],
      unitPrice: json['unitPrice'].toDouble(),
      quantity: json['quantity'],
      totalPrice: json['totalPrice'].toDouble(),
      category: _stringToCategory(json['category']),
    );
  }
  
  static ItemCategory _stringToCategory(String categoryStr) {
    try {
      return ItemCategory.values.firstWhere(
        (c) => c.toString().split('.').last == categoryStr,
      );
    } catch (_) {
      return ItemCategory.other;
    }
  }
}

/// A receipt from a store or vendor
class Receipt {
  final String id;
  final String userId;
  final String vendorName;
  final String location;
  final DateTime date;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String? imageUrl;
  final String? notes;
  final Map<String, dynamic>? rawOcrData;
  final bool needsReview;
  
  Receipt({
    String? id,
    required this.userId,
    required this.vendorName,
    required this.location,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.imageUrl,
    this.notes,
    this.rawOcrData,
    this.needsReview = false,
  }) : id = id ?? const Uuid().v4();
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'vendorName': vendorName,
      'location': location,
      'date': Timestamp.fromDate(date),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'imageUrl': imageUrl,
      'notes': notes,
      'rawOcrData': rawOcrData,
      'needsReview': needsReview,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
  
  factory Receipt.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((item) => ReceiptItem.fromJson(item))
        .toList();
    
    return Receipt(
      id: json['id'],
      userId: json['userId'],
      vendorName: json['vendorName'],
      location: json['location'],
      date: (json['date'] as Timestamp).toDate(),
      items: items,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
      notes: json['notes'],
      rawOcrData: json['rawOcrData'],
      needsReview: json['needsReview'] ?? false,
    );
  }
} 