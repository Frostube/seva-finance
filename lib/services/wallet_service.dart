import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/wallet.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService with ChangeNotifier {
  final Box<Wallet> _localBox;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoading = false;
  final NotificationService _notificationService;

  WalletService(this._localBox, this._firestore, this._storage, this._notificationService) {
    _loadWallets();
  }

  List<Wallet> get wallets => _wallets;
  Wallet? get selectedWallet => _selectedWallet;
  bool get isLoading => _isLoading;

  Future<void> _loadWallets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load from local storage first
      _wallets = _localBox.values.toList();

      // Then sync with Firestore
      final snapshot = await _firestore.collection('wallets')
          .where('userId', isEqualTo: userId)
          .get();
      final remoteWallets = snapshot.docs.map((doc) {
        final data = doc.data();
        return Wallet(
          id: doc.id,
          name: data['name'] as String,
          balance: data['balance'] as double,
          isPrimary: data['isPrimary'] as bool,
          createdAt: data['createdAt'] as String,
          colorValue: data['colorValue'] as int,
          budget: data['budget'] as double?,
          type: data['type'] as String?,
          icon: IconData(
            data['iconData'] as int? ?? Wallet.defaultIcon.codePoint,
            fontFamily: Wallet.defaultIcon.fontFamily,
            fontPackage: Wallet.defaultIcon.fontPackage,
          ),
        );
      }).toList();

      // Merge local and remote wallets
      for (final remoteWallet in remoteWallets) {
        final localIndex = _wallets.indexWhere((w) => w.id == remoteWallet.id);
        if (localIndex >= 0) {
          _wallets[localIndex] = remoteWallet;
        } else {
          _wallets.add(remoteWallet);
        }
      }

      // Save merged wallets to local storage
      await _localBox.clear();
      for (final wallet in _wallets) {
        await _localBox.put(wallet.id, wallet);
      }

      // Initialize selected wallet if not already set
      _selectedWallet ??= getPrimaryWallet();
    } catch (e) {
      debugPrint('Error loading wallets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get all wallets
  List<Wallet> getAllWallets() {
    return _wallets;
  }

  // Get primary wallet
  Wallet? getPrimaryWallet() {
    if (_wallets.isEmpty) {
      return null;
    }
    try {
      return _wallets.firstWhere(
        (w) => w.isPrimary,
        orElse: () => _wallets.first,
      );
    } catch (e) {
      return _wallets.first;
    }
  }

  // Set the currently selected wallet (does not change primary)
  void setSelectedWallet(Wallet wallet) {
    _selectedWallet = wallet;
    notifyListeners();
  }

  // Set primary wallet
  Future<void> setPrimaryWallet(String walletId) async {
    if (_wallets.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Update all wallets to non-primary
      for (final wallet in _wallets) {
        if (wallet.isPrimary) {
          wallet.isPrimary = false;
          await _firestore.collection('wallets').doc(wallet.id).update({
            'isPrimary': false,
          });
          await _localBox.put(wallet.id, wallet);
        }
      }

      // Set new primary
      final newPrimary = _wallets.firstWhere((w) => w.id == walletId);
      newPrimary.isPrimary = true;
      await _firestore.collection('wallets').doc(walletId).update({
        'isPrimary': true,
      });
      await _localBox.put(walletId, newPrimary);

      _isLoading = false;
      notifyListeners();

      _notificationService.addActionNotification(
        title: 'Primary Wallet Changed',
        message: '${newPrimary.name} is now your primary wallet',
        relatedId: walletId,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Add new wallet
  Future<void> addWallet(Wallet wallet) async {
    try {
      _isLoading = true;
      notifyListeners();
      debugPrint('WalletService: Adding new wallet - ID: ${wallet.id}, Name: ${wallet.name}, Balance: ${wallet.balance}');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Add to Firestore
      final docRef = await _firestore.collection('wallets').add({
        'name': wallet.name,
        'balance': wallet.balance,
        'isPrimary': wallet.isPrimary,
        'createdAt': wallet.createdAt,
        'colorValue': wallet.colorValue,
        'budget': wallet.budget,
        'type': wallet.type,
        'iconData': wallet.iconData,
        'userId': userId,
      });
      debugPrint('WalletService: Wallet added to Firestore with ID: ${docRef.id}');

      // Update wallet with Firestore ID
      final updatedWallet = Wallet(
        id: docRef.id,
        name: wallet.name,
        balance: wallet.balance,
        isPrimary: wallet.isPrimary,
        createdAt: wallet.createdAt,
        colorValue: wallet.colorValue,
        budget: wallet.budget,
        type: wallet.type,
        icon: wallet.icon,
      );

      // Save to local storage
      await _localBox.put(updatedWallet.id, updatedWallet);
      _wallets.add(updatedWallet);
      debugPrint('WalletService: Wallet saved to local storage and added to wallets list');

      _isLoading = false;
      notifyListeners();

      _notificationService.addActionNotification(
        title: 'New Wallet Created',
        message: '${wallet.name} has been added to your wallets',
        relatedId: wallet.id,
      );
    } catch (e) {
      debugPrint('WalletService: Error adding wallet: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update wallet
  Future<void> updateWallet(Wallet wallet) async {
    try {
      _isLoading = true;
      notifyListeners();
      debugPrint('WalletService: Updating wallet - ID: ${wallet.id}, Name: ${wallet.name}, Balance: ${wallet.balance}');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update in Firestore
      debugPrint('WalletService: Attempting to update wallet in Firestore...');
      await _firestore.collection('wallets').doc(wallet.id).update({
        'name': wallet.name,
        'balance': wallet.balance,
        'isPrimary': wallet.isPrimary,
        'createdAt': wallet.createdAt,
        'colorValue': wallet.colorValue,
        'budget': wallet.budget,
        'type': wallet.type,
        'iconData': wallet.iconData,
        'userId': userId,
      });
      debugPrint('WalletService: Wallet updated in Firestore successfully');

      // Update in local storage
      await _localBox.put(wallet.id, wallet);
      final index = _wallets.indexWhere((w) => w.id == wallet.id);
      if (index >= 0) {
        _wallets[index] = wallet;
        debugPrint('WalletService: Wallet updated in local storage and wallets list');
      } else {
        debugPrint('WalletService: Warning - Wallet not found in wallets list for update');
      }

      _isLoading = false;
      notifyListeners();

      _notificationService.addActionNotification(
        title: 'Wallet Updated',
        message: '${wallet.name} has been updated',
        relatedId: wallet.id,
      );
    } catch (e) {
      debugPrint('WalletService: Error updating wallet: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete wallet
  Future<void> deleteWallet(String walletId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete from Firestore
      await _firestore.collection('wallets').doc(walletId).delete();

      // Delete from local storage
      await _localBox.delete(walletId);
      _wallets.removeWhere((w) => w.id == walletId);

      // If we deleted the primary wallet, make another one primary
      final remainingWallets = getAllWallets();
      if (remainingWallets.isNotEmpty) {
        final newPrimary = remainingWallets.first;
        newPrimary.isPrimary = true;
        await updateWallet(newPrimary);
      }

      _isLoading = false;
      notifyListeners();

      _notificationService.addActionNotification(
        title: 'Wallet Deleted',
        message: '${_localBox.get(walletId)?.name} has been removed',
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get wallet budget
  double getWalletBudget(String walletId) {
    final wallet = _wallets.firstWhere((w) => w.id == walletId);
    return wallet.budget ?? 0.0;
  }

  // Set wallet budget
  Future<void> setWalletBudget(String walletId, double budget) async {
    final wallet = _wallets.firstWhere((w) => w.id == walletId);
    wallet.budget = budget;
    await updateWallet(wallet);
    }

  // Set wallet balance
  Future<void> setWalletBalance(String walletId, double balance) async {
    final wallet = _wallets.firstWhere((w) => w.id == walletId);
    wallet.balance = balance;
    await updateWallet(wallet);
    }

  // Get primary wallet budget
  double? getPrimaryWalletBudget() {
    return getPrimaryWallet()?.budget;
  }

  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update in Firestore
      await _firestore.collection('wallets').doc(walletId).update({
        'balance': newBalance,
      });

      // Update in local storage
      final wallet = _wallets.firstWhere((w) => w.id == walletId);
      wallet.balance = newBalance;
      await _localBox.put(walletId, wallet);
      final index = _wallets.indexWhere((w) => w.id == walletId);
      if (index >= 0) {
        _wallets[index] = wallet;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
} 