import 'package:hive/hive.dart';
import '../models/wallet.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class WalletService extends ChangeNotifier {
  final Box<Wallet> _walletBox;
  final NotificationService _notificationService;

  WalletService(this._walletBox, this._notificationService);

  // Get all wallets
  List<Wallet> getAllWallets() {
    return _walletBox.values.toList();
  }

  // Get primary wallet
  Wallet? getPrimaryWallet() {
    if (_walletBox.isEmpty) {
      return null;
    }
    try {
      return _walletBox.values.firstWhere(
        (w) => w.isPrimary,
        orElse: () => _walletBox.values.first,
      );
    } catch (e) {
      print('WalletService: Error getting primary wallet: $e');
      return null;
    }
  }

  // Set primary wallet
  Future<void> setPrimaryWallet(String walletId) async {
    if (_walletBox.isEmpty) return;

    try {
      // First, unset current primary
      final currentPrimary = getPrimaryWallet();
      if (currentPrimary != null) {
        currentPrimary.isPrimary = false;
        await updateWallet(currentPrimary);
      }

      // Set new primary
      final newPrimary = _walletBox.get(walletId);
      if (newPrimary != null) {
        newPrimary.isPrimary = true;
        await updateWallet(newPrimary);
        _notificationService.addActionNotification(
          title: 'Primary Wallet Changed',
          message: '${newPrimary.name} is now your primary wallet',
          relatedId: walletId,
        );
      }
    } catch (e) {
      print('WalletService: Error setting primary wallet: $e');
    }
  }

  // Add new wallet
  Future<void> addWallet(Wallet wallet) async {
    await _walletBox.put(wallet.id, wallet);
    _notificationService.addActionNotification(
      title: 'New Wallet Created',
      message: '${wallet.name} has been added to your wallets',
      relatedId: wallet.id,
    );
    notifyListeners();
  }

  // Update wallet
  Future<void> updateWallet(Wallet wallet) async {
    await _walletBox.put(wallet.id, wallet);
    _notificationService.addActionNotification(
      title: 'Wallet Updated',
      message: '${wallet.name} has been updated',
      relatedId: wallet.id,
    );
    notifyListeners();
  }

  // Delete wallet
  Future<void> deleteWallet(String id) async {
    if (_walletBox.containsKey(id)) {
      await _walletBox.delete(id);
      // If we deleted the primary wallet, make another one primary
      final remainingWallets = getAllWallets();
      if (remainingWallets.isNotEmpty && !remainingWallets.any((w) => w.isPrimary)) {
        final newPrimary = remainingWallets.first;
        newPrimary.isPrimary = true;
        await updateWallet(newPrimary);
      }
      _notificationService.addActionNotification(
        title: 'Wallet Deleted',
        message: '${_walletBox.get(id)?.name} has been removed',
      );
      notifyListeners();
    }
  }

  // Get wallet budget
  double getWalletBudget(String walletId) {
    final wallet = _walletBox.get(walletId);
    return wallet?.budget ?? 0.0;
  }

  // Set wallet budget
  Future<void> setWalletBudget(String walletId, double budget) async {
    final wallet = _walletBox.get(walletId);
    if (wallet != null) {
      wallet.budget = budget;
      await updateWallet(wallet);
    }
  }

  // Set wallet balance
  Future<void> setWalletBalance(String walletId, double balance) async {
    final wallet = _walletBox.get(walletId);
    if (wallet != null) {
      wallet.balance = balance;
      await updateWallet(wallet);
    }
  }

  // Get primary wallet budget
  double? getPrimaryWalletBudget() {
    return getPrimaryWallet()?.budget;
  }
} 