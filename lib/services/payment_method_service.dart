import 'package:flutter/material.dart';
import '../models/payment_method.dart';

class PaymentMethodService extends ChangeNotifier {
  final List<PaymentMethod> _paymentMethods = [];
  
  List<PaymentMethod> get paymentMethods => List.unmodifiable(_paymentMethods);

  // Add a new payment method
  Future<void> addPaymentMethod(PaymentMethod paymentMethod) async {
    _paymentMethods.add(paymentMethod);
    notifyListeners();
  }

  // Update an existing payment method
  Future<void> updatePaymentMethod(PaymentMethod updatedMethod) async {
    final index = _paymentMethods.indexWhere((method) => method.id == updatedMethod.id);
    if (index != -1) {
      _paymentMethods[index] = updatedMethod;
      notifyListeners();
    }
  }

  // Delete a payment method
  Future<void> deletePaymentMethod(String id) async {
    _paymentMethods.removeWhere((method) => method.id == id);
    notifyListeners();
  }

  // Get a payment method by ID
  PaymentMethod? getPaymentMethodById(String id) {
    try {
      return _paymentMethods.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }

  // Initialize with some default payment methods
  void initializeDefaultMethods() {
    if (_paymentMethods.isEmpty) {
      _paymentMethods.addAll([
        PaymentMethod(
          id: 'cash',
          name: 'Cash',
          icon: 'money',
        ),
        PaymentMethod(
          id: 'credit_card',
          name: 'Credit Card',
          icon: 'credit_card',
        ),
        PaymentMethod(
          id: 'debit_card',
          name: 'Debit Card',
          icon: 'card',
        ),
      ]);
      notifyListeners();
    }
  }
} 