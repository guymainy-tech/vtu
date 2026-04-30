// lib/services/connectivity_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  /// Check if device has network connection
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Stream of connectivity status changes
  Stream<bool> get connectionStatusStream {
    return _connectivity.onConnectivityChanged
        .map((result) => result != ConnectivityResult.none);
  }
}
