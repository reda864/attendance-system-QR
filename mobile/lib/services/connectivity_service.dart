import 'dart:async';
import 'dart:io' hide TimeoutException;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// A service that monitors and checks network connectivity.
///
/// Usage:
///   final service = ConnectivityService();
///   bool online = await service.isConnected();
///   service.onConnectivityChanged.listen((isConnected) { ... });
///   service.dispose(); // call when done
class ConnectivityService {
  static ConnectivityService? _instance;

  final Connectivity _connectivity;
  late final StreamController<bool> _controller;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _lastKnownStatus = true;

  ConnectivityService._internal({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _controller = StreamController<bool>.broadcast();
    _startListening();
  }

  factory ConnectivityService({Connectivity? connectivity}) {
    _instance ??= ConnectivityService._internal(connectivity: connectivity);
    return _instance!;
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// A broadcast stream that emits `true` when the device comes online and
  /// `false` when it goes offline.
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// The last known connectivity status (updated whenever the stream emits).
  bool get lastKnownStatus => _lastKnownStatus;

  /// Performs an active connectivity check.
  ///
  /// First checks for a network interface via [ConnectivityResult], then
  /// attempts a real DNS lookup to verify actual internet access.
  /// Returns `true` if internet is reachable, `false` otherwise.
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (_isOfflineResult(results)) {
        _lastKnownStatus = false;
        return false;
      }

      // Even if the OS reports a connection, verify real internet access
      final hasInternet = await _verifyInternetAccess();
      _lastKnownStatus = hasInternet;
      return hasInternet;
    } catch (_) {
      _lastKnownStatus = false;
      return false;
    }
  }

  /// Returns `true` if the device has **no** network connection at all
  /// (no Wi-Fi, no mobile data, etc.), without doing a DNS check.
  Future<bool> isDisconnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOfflineResult(results);
    } catch (_) {
      return true;
    }
  }

  /// Returns the current [ConnectivityResult] list from the OS.
  Future<List<ConnectivityResult>> getConnectivityResults() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (_) {
      return [ConnectivityResult.none];
    }
  }

  /// Returns a human-readable description of the current connection type.
  Future<String> getConnectionType() async {
    final results = await getConnectivityResults();
    if (results.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (results.contains(ConnectivityResult.mobile)) return 'Mobile Data';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (results.contains(ConnectivityResult.vpn)) return 'VPN';
    if (results.contains(ConnectivityResult.bluetooth)) return 'Bluetooth';
    return 'No Connection';
  }

  /// Disposes the stream controller and cancels the connectivity subscription.
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _instance = null;
  }

  /// Resets the singleton (useful in tests).
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) async {
        if (_isOfflineResult(results)) {
          _lastKnownStatus = false;
          _safeEmit(false);
        } else {
          // Debounce: wait a moment for the network to stabilise
          await Future<void>.delayed(const Duration(milliseconds: 800));
          final hasInternet = await _verifyInternetAccess();
          _lastKnownStatus = hasInternet;
          _safeEmit(hasInternet);
        }
      },
      onError: (_) {
        _lastKnownStatus = false;
        _safeEmit(false);
      },
    );
  }

  void _safeEmit(bool value) {
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  bool _isOfflineResult(List<ConnectivityResult> results) {
    return results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
  }

  /// Attempts a real DNS lookup to confirm actual internet access.
  /// Falls back to `true` on non-mobile platforms in debug mode to avoid
  /// blocking emulator development.
  Future<bool> _verifyInternetAccess() async {
    // On web, skip the socket check — always assume connected if OS says so
    if (kIsWeb) return true;

    // Debug / profile: LAN-only dev (API on your PC) should not require public DNS.
    if (kDebugMode || kProfileMode) return true;

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// A lightweight snapshot of the current network state, suitable for use
/// in UI widgets via [ConnectivityService.isConnected].
class ConnectivityStatus {
  final bool isConnected;
  final String connectionType;

  const ConnectivityStatus({
    required this.isConnected,
    required this.connectionType,
  });

  const ConnectivityStatus.online(this.connectionType) : isConnected = true;
  const ConnectivityStatus.offline()
      : isConnected = false,
        connectionType = 'No Connection';

  @override
  String toString() =>
      'ConnectivityStatus(isConnected: $isConnected, type: $connectionType)';
}
