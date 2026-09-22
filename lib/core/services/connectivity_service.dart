import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _lastStatus = true;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = await checkIsOnline(results);
      if (isOnline != _lastStatus) {
        _lastStatus = isOnline;
        _controller.add(isOnline);
        SecureLogger.logInfo('ConnectivityService: Network state changed to ${isOnline ? "ONLINE" : "OFFLINE"}');
      }
    });
  }

  Future<bool> checkIsOnline([List<ConnectivityResult>? results]) async {
    try {
      final res = results ?? await _connectivity.checkConnectivity();
      if (res.contains(ConnectivityResult.none) || res.isEmpty) {
        return false;
      }
      // On Web, return true if network adapter is connected
      if (kIsWeb) return true;

      // On Mobile/Desktop, attempt a quick lightweight socket lookup to verify true internet reachability
      try {
        final lookup = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 3),
        );
        return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      } on TimeoutException catch (_) {
        return false;
      }
    } catch (e) {
      SecureLogger.logError('ConnectivityService check failed', e.toString());
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
