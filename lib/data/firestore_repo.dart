import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/receipt.dart';

/// Repository to handle Firestore CRUD operations for receipts
class FirestoreRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Collection reference for receipts
  CollectionReference<Map<String, dynamic>> receiptsCollection(String userId) {
    return _firestore.collection('users/$userId/receipts');
  }
  
  /// Add a new receipt to Firestore
  Future<String> addReceipt(Receipt receipt) async {
    try {
      final docRef = await receiptsCollection(receipt.userId).add(receipt.toJson());
      return docRef.id;
    } catch (e) {
      print('Error adding receipt: $e');
      rethrow;
    }
  }
  
  /// Get a stream of all receipts for a user
  Stream<List<Receipt>> getReceiptsStream(String userId) {
    return receiptsCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Receipt.fromJson(data);
      }).toList();
    });
  }
  
  /// Get a single receipt by ID
  Future<Receipt?> getReceiptById(String userId, String receiptId) async {
    try {
      final doc = await receiptsCollection(userId).doc(receiptId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Receipt.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting receipt: $e');
      rethrow;
    }
  }
  
  /// Update an existing receipt
  Future<void> updateReceipt(Receipt receipt) async {
    try {
      await receiptsCollection(receipt.userId).doc(receipt.id).update(receipt.toJson());
    } catch (e) {
      print('Error updating receipt: $e');
      rethrow;
    }
  }
  
  /// Delete a receipt
  Future<void> deleteReceipt(String userId, String receiptId) async {
    try {
      await receiptsCollection(userId).doc(receiptId).delete();
    } catch (e) {
      print('Error deleting receipt: $e');
      rethrow;
    }
  }
  
  /// Get receipts by date range
  Future<List<Receipt>> getReceiptsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await receiptsCollection(userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Receipt.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting receipts by date range: $e');
      rethrow;
    }
  }
  
  /// Get receipts by vendor
  Future<List<Receipt>> getReceiptsByVendor(String userId, String vendorName) async {
    try {
      final snapshot = await receiptsCollection(userId)
          .where('vendorName', isEqualTo: vendorName)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Receipt.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting receipts by vendor: $e');
      rethrow;
    }
  }
} 