import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// App-wide connectivity. [isOnline] is false when there is no usable network.
///
/// When the device goes from offline → online (or [refresh] succeeds after being
/// offline), [reconnectGeneration] increments so screens can auto-reload.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;
  bool _started = false;
  int _reconnectGeneration = 0;
  bool _probing = false;

  bool get isOnline => _online;

  /// Bumps whenever connectivity is restored. Screens listen and call `_load()`.
  int get reconnectGeneration => _reconnectGeneration;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final initial = await _connectivity.checkConnectivity();
      if (_hasLink(initial)) {
        final ok = await _probeReachability();
        _applyOnline(ok, announceReconnect: false);
      } else {
        _applyOnline(false, announceReconnect: false);
      }
    } catch (e) {
      debugPrint('[Connectivity] check failed: $e');
      _applyOnline(true, announceReconnect: false);
    }
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      if (!_hasLink(results)) {
        _applyOnline(false, announceReconnect: false);
        return;
      }
      // Link is up — confirm DNS/internet before dismissing the offline gate.
      final ok = await _probeReachability();
      _applyOnline(ok, announceReconnect: true);
    });
  }

  /// Re-check link + reachability. Returns whether we are online.
  Future<bool> refresh() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!_hasLink(results)) {
        _applyOnline(false, announceReconnect: false);
        return false;
      }
      final ok = await _probeReachability();
      _applyOnline(ok, announceReconnect: true);
      return ok;
    } catch (_) {
      return _online;
    }
  }

  bool _hasLink(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    if (results.every((r) => r == ConnectivityResult.none)) return false;
    return true;
  }

  /// Wi‑Fi/cellular can be "connected" while DNS still fails briefly.
  Future<bool> _probeReachability() async {
    if (_probing) return _online;
    _probing = true;
    try {
      final result = await InternetAddress.lookup('joballocate.tech')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      // Lookup unavailable (e.g. some platforms) — trust the link flag.
      return true;
    } finally {
      _probing = false;
    }
  }

  void _applyOnline(bool value, {required bool announceReconnect}) {
    final wasOnline = _online;
    if (_online == value) {
      // Manual "Try again" while already online: still nudge screens to reload.
      if (value && announceReconnect) {
        _reconnectGeneration++;
        notifyListeners();
      }
      return;
    }
    _online = value;
    if (!wasOnline && value && announceReconnect) {
      _reconnectGeneration++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
