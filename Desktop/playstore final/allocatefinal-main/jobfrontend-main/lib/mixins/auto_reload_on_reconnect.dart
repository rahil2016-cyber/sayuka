import 'package:flutter/widgets.dart';

import '../services/connectivity_service.dart';

/// Auto-calls [onNetworkRestored] when connectivity comes back (or user taps
/// Try again on the offline gate after a successful probe).
///
/// Use on screens that show a Retry error state after a failed API load.
mixin AutoReloadOnReconnect<T extends StatefulWidget> on State<T> {
  int _seenReconnectGeneration = 0;

  /// Override to reload data (typically your existing `_load()`).
  void onNetworkRestored();

  /// When true (default), only reload if the screen is in an error / empty-failed state.
  /// Override [shouldReloadOnReconnect] for custom logic.
  bool shouldReloadOnReconnect() => true;

  @override
  void initState() {
    super.initState();
    _seenReconnectGeneration = ConnectivityService.instance.reconnectGeneration;
    ConnectivityService.instance.addListener(_handleConnectivityChange);
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_handleConnectivityChange);
    super.dispose();
  }

  void _handleConnectivityChange() {
    if (!mounted) return;
    final gen = ConnectivityService.instance.reconnectGeneration;
    if (gen == _seenReconnectGeneration) return;
    if (!ConnectivityService.instance.isOnline) {
      _seenReconnectGeneration = gen;
      return;
    }
    _seenReconnectGeneration = gen;
    if (shouldReloadOnReconnect()) {
      onNetworkRestored();
    }
  }
}
