import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  ConnectivityHelper() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      var status = await _connectivity.checkConnectivity();
      _updateConnectionStatus(status);
    } catch (e) {
      _connectionStatusController.add(false);
      _isConnected = false;
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      _connectionStatusController.add(false);
      _isConnected = false;
    } else {
      _connectionStatusController.add(true);
      _isConnected = true;
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
} 