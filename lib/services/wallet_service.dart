import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/wallet.dart';
import 'notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService with ChangeNotifier {
  final Box<Wallet> _localBox;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Wallet> _wallets = [];
  bool _isLoading = false;
  final NotificationService _notificationService;
  Future<void>? _initialLoadFuture;

  WalletService(this._localBox, this._firestore, this._storage, this._notificationService) {
    _initialLoadFuture = _loadWallets();
  }

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  Future<void>? get initializationComplete => _initialLoadFuture;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadWallets() async {
    if (_isLoading) return;
    _isLoading = true;

    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint('WalletService: User not authenticated. Loading from local cache only.');
      _wallets = _localBox.values.toList();
      _isLoading = false;
    notifyListeners();
      return;
    }

    try {
      debugPrint('WalletService: User $currentUserId authenticated. Syncing wallets.');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wallets')
          .get();
      debugPrint('WalletService: Fetched ${snapshot.docs.length} wallets from Firestore for user $currentUserId.');
      
      final remoteWallets = snapshot.docs.map((doc) {
        final data = doc.data();
        return Wallet.fromJson({
          ...data,
          'id': doc.id
        });
      }).toList();

      Map<String, Wallet> localWalletsMap = { for (var w in _localBox.values) w.id : w };
      Set<String> remoteWalletIds = {};

      for (final remoteWallet in remoteWallets) {
        remoteWalletIds.add(remoteWallet.id);
        await _localBox.put(remoteWallet.id, remoteWallet);
        localWalletsMap[remoteWallet.id] = remoteWallet;
      }

      List<String> walletsToDeleteLocally = [];
      for (final localWalletId in localWalletsMap.keys) {
        if (!remoteWalletIds.contains(localWalletId)) {
          walletsToDeleteLocally.add(localWalletId);
        }
      }
      for (final walletIdToDelete in walletsToDeleteLocally) {
        await _localBox.delete(walletIdToDelete);
        localWalletsMap.remove(walletIdToDelete);
        debugPrint('WalletService: Deleted wallet $walletIdToDelete from local cache.');
      }
      
      _wallets = localWalletsMap.values.toList();
      debugPrint('WalletService: Synced ${_wallets.length} wallets.');

    } catch (e) {
      debugPrint('Error syncing wallets with Firestore: $e. Using local cache as fallback.');
      _wallets = _localBox.values.toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Wallet> getAllWallets() {
    return List.from(_wallets);
  }

  Wallet? getPrimaryWallet() {
    if (_wallets.isEmpty) return null;
    try {
      return _wallets.firstWhere((w) => w.isPrimary, orElse: () => _wallets.first);
    } catch (e) {
      return _wallets.isNotEmpty ? _wallets.first : null;
    }
  }

  Future<void> setPrimaryWallet(String walletIdToSetAsPrimary) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint("WalletService: User not logged in. Cannot set primary wallet.");
      return;
    }
    if (_wallets.isEmpty) return;

      _isLoading = true;
      notifyListeners();

    try {
      WriteBatch batch = _firestore.batch();

      for (final wallet in _wallets) {
        if (wallet.isPrimary && wallet.id != walletIdToSetAsPrimary) {
          final walletRef = _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('wallets')
              .doc(wallet.id);
          batch.update(walletRef, {'isPrimary': false});
          
          final updatedLocalWallet = wallet.copyWith(isPrimary: false);
          await _localBox.put(wallet.id, updatedLocalWallet);
        }
      }

      final primaryWalletRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wallets')
          .doc(walletIdToSetAsPrimary);
      batch.update(primaryWalletRef, {'isPrimary': true});
      await batch.commit();

      _wallets = _wallets.map((wallet) {
        final bool isNowPrimary = wallet.id == walletIdToSetAsPrimary;
        if (wallet.isPrimary != isNowPrimary) {
          final updatedWallet = wallet.copyWith(isPrimary: isNowPrimary);
          _localBox.put(updatedWallet.id, updatedWallet);
          return updatedWallet;
        }
        return wallet;
      }).toList();
      
      final newPrimary = _wallets.firstWhere((w) => w.id == walletIdToSetAsPrimary);
      _notificationService.addActionNotification(
        title: 'Primary Wallet Changed',
        message: '${newPrimary.name} is now your primary wallet',
        relatedId: newPrimary.id,
      );

    } catch (e) {
      debugPrint("Error setting primary wallet: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWallet(Wallet wallet) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();

    try {
      final walletRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wallets')
          .doc(wallet.id);
      
      Map<String, dynamic> walletData = wallet.toJson();
      walletData.remove('userId'); 

      await walletRef.set(walletData);
      debugPrint('WalletService: Wallet added to Firestore for user $currentUserId with ID: ${wallet.id}');

      await _localBox.put(wallet.id, wallet);
      _wallets.add(wallet);

      _notificationService.addActionNotification(
        title: 'New Wallet Created',
        message: '${wallet.name} has been added to your wallets',
        relatedId: wallet.id,
      );
    } catch (e) {
      debugPrint('WalletService: Error adding wallet: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> walletData = wallet.toJson();
      walletData.remove('userId');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wallets')
          .doc(wallet.id)
          .update(walletData);
      debugPrint('WalletService: Wallet updated in Firestore for user $currentUserId');

      await _localBox.put(wallet.id, wallet);
      final index = _wallets.indexWhere((w) => w.id == wallet.id);
      if (index != -1) {
        _wallets[index] = wallet;
      }

      _notificationService.addActionNotification(
        title: 'Wallet Updated',
        message: '${wallet.name} has been updated',
        relatedId: wallet.id,
      );
    } catch (e) {
      debugPrint('WalletService: Error updating wallet: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWallet(String walletId) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
      _isLoading = true;
      notifyListeners();

    try {
      final Wallet walletToDelete = _wallets.firstWhere((w) => w.id == walletId, orElse: () => Wallet.empty);
      String deletedWalletName = walletToDelete.name;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wallets')
          .doc(walletId)
          .delete();

      await _localBox.delete(walletId);
      _wallets.removeWhere((w) => w.id == walletId);

      if (walletToDelete.isPrimary && _wallets.isNotEmpty) {
        await setPrimaryWallet(_wallets.first.id);
      }

      _notificationService.addActionNotification(
        title: 'Wallet Deleted',
        message: '$deletedWalletName has been removed',
      );
    } catch (e) {
      debugPrint('WalletService: Error deleting wallet: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getWalletBudget(String walletId) {
    final wallet = _wallets.firstWhere((w) => w.id == walletId, orElse: () => Wallet.empty);
    return wallet.budget ?? 0.0;
  }

  Future<void> setWalletBudget(String walletId, double budget) async {
    final index = _wallets.indexWhere((w) => w.id == walletId);
    if (index != -1) {
      final updatedWallet = _wallets[index].copyWith(budget: budget);
      await updateWallet(updatedWallet);
    }
  }

  Future<void> setWalletBalance(String walletId, double balance) async {
    final index = _wallets.indexWhere((w) => w.id == walletId);
    if (index != -1) {
      final updatedWallet = _wallets[index].copyWith(balance: balance);
      await updateWallet(updatedWallet);
    }
  }

  double? getPrimaryWalletBudget() {
    return getPrimaryWallet()?.budget;
  }

  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint("WalletService: User not logged in. Cannot update balance.");
      return;
    }
      _isLoading = true;
      notifyListeners();
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wallets')
          .doc(walletId)
          .update({'balance': newBalance});

      final index = _wallets.indexWhere((w) => w.id == walletId);
      if (index != -1) {
        _wallets[index] = _wallets[index].copyWith(balance: newBalance);
        await _localBox.put(walletId, _wallets[index]);
      }
    } catch (e) {
      debugPrint("Error updating wallet balance directly: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 