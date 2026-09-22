import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/pending_sync_service.dart';
import '../utils/logger.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  bool _isOnline = true;
  bool _wasOffline = false;
  bool _showRestoredBanner = false;
  Timer? _bannerDismissTimer;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get wasOffline => _wasOffline;
  bool get showRestoredBanner => _showRestoredBanner;
  int get pendingSyncCount => PendingSyncService.getPendingQueue().length;
  String get lastSyncFormatted => PendingSyncService.getLastSyncTimeFormatted();

  ConnectivityProvider(this._service) {
    _init();
  }

  void _init() async {
    _isOnline = await _service.checkIsOnline();
    notifyListeners();

    _subscription = _service.onConnectivityChanged.listen((online) {
      if (_isOnline != online) {
        if (!online) {
          _wasOffline = true;
          _showRestoredBanner = false;
          _bannerDismissTimer?.cancel();
          SecureLogger.logInfo('ConnectivityProvider: Device went OFFLINE');
        } else if (_wasOffline) {
          _showRestoredBanner = true;
          SecureLogger.logInfo('ConnectivityProvider: Device restored ONLINE');
          _triggerPendingSync();
          _bannerDismissTimer?.cancel();
          _bannerDismissTimer = Timer(const Duration(seconds: 4), () {
            _showRestoredBanner = false;
            notifyListeners();
          });
        }
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  Future<void> checkConnectivity() async {
    final online = await _service.checkIsOnline();
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  Future<void> _triggerPendingSync() async {
    final count = await PendingSyncService.syncPendingQueue();
    if (count > 0) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bannerDismissTimer?.cancel();
    super.dispose();
  }
}
