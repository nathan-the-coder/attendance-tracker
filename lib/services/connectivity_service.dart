import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that monitors network connectivity
/// and notifies listeners when connection state changes
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingSyncCount = 0;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _pendingSyncCount;
  bool get hasPendingSync => _pendingSyncCount > 0;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final wasOffline = !_isOnline;
    _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);

    if (wasOffline && _isOnline) {
      // Just came back online - notify to trigger sync
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// Call this when an action is performed offline
  /// to track pending syncs
  void markPendingSync() {
    _pendingSyncCount++;
    notifyListeners();
  }

  /// Call this when syncing starts
  void startSync() {
    _isSyncing = true;
    notifyListeners();
  }

  /// Call this when syncing completes
  void endSync() {
    _isSyncing = false;
    _pendingSyncCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
