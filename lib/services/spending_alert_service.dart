import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spending_alert.dart';

class SpendingAlertService with ChangeNotifier {
  final Box<SpendingAlert> _alertsBox;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<SpendingAlert> _alerts = [];
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  SpendingAlertService(this._alertsBox, this._firestore) {
    _initialLoadFuture = _loadAlerts();
  }

  List<SpendingAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  Future<void>? get initializationComplete => _initialLoadFuture;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadAlerts() async {
    if (_isLoading) return;
    _isLoading = true;

    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint('SpendingAlertService: User not authenticated. Loading alerts from local cache only.');
      _alerts = _alertsBox.values.toList();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint('SpendingAlertService: User $currentUserId authenticated. Syncing spending alerts.');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('spendingAlerts')
          .get();
      debugPrint('SpendingAlertService: Fetched ${snapshot.docs.length} alerts from Firestore.');
      
      final remoteAlerts = snapshot.docs.map((doc) {
        return SpendingAlert.fromJson(doc.data(), doc.id);
      }).toList();

      Map<String, SpendingAlert> localAlertsMap = { for (var a in _alertsBox.values) a.id : a };
      Set<String> remoteAlertIds = {};

      for (final remoteAlert in remoteAlerts) {
        remoteAlertIds.add(remoteAlert.id);
        await _alertsBox.put(remoteAlert.id, remoteAlert);
        localAlertsMap[remoteAlert.id] = remoteAlert;
      }

      List<String> alertsToDeleteLocally = [];
      for (final localAlertId in localAlertsMap.keys) {
        if (!remoteAlertIds.contains(localAlertId)) {
          alertsToDeleteLocally.add(localAlertId);
        }
      }
      for (final alertIdToDelete in alertsToDeleteLocally) {
        await _alertsBox.delete(alertIdToDelete);
        localAlertsMap.remove(alertIdToDelete);
        debugPrint('SpendingAlertService: Deleted alert $alertIdToDelete from local cache.');
      }
      
      _alerts = localAlertsMap.values.toList();
      debugPrint('SpendingAlertService: Synced ${_alerts.length} alerts.');

    } catch (e) {
      debugPrint('Error syncing spending alerts: $e. Using local cache as fallback.');
      _alerts = _alertsBox.values.toList();
    }

    _isLoading = false;
    notifyListeners();
  }
  
  List<SpendingAlert> getSpendingAlertsForWallet(String walletId) {
    return _alerts.where((alert) => alert.walletId == walletId).toList();
  }

  Future<void> addSpendingAlert(SpendingAlert alert) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('spendingAlerts')
          .doc(alert.id);

      await docRef.set(alert.toJson());
      _alerts.add(alert);
      await _alertsBox.put(alert.id, alert);
    } catch (e) {
      debugPrint('Error adding spending alert: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSpendingAlert(SpendingAlert alert) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('spendingAlerts')
          .doc(alert.id)
          .update(alert.toJson());

      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _alerts[index] = alert;
        await _alertsBox.put(alert.id, alert);
      }
    } catch (e) {
      debugPrint('Error updating spending alert: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSpendingAlert(String alertId) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('spendingAlerts')
          .doc(alertId)
          .delete();

      _alerts.removeWhere((a) => a.id == alertId);
      await _alertsBox.delete(alertId);
    } catch (e) {
      debugPrint('Error deleting spending alert: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 