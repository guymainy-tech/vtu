// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Connectivity _connectivity = Connectivity();

  // ✅ Backend base URL - Update this to your actual backend server
  static const String _backendUrl = 'https://your-backend-api.com/api';
  // For development: 'http://192.168.x.x:8000/api' (use your machine's local IP)

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        AppLogger.logRequest(options);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.logResponse(response);
        return handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.logError(error);
        return handler.next(error);
      },
    ));
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// ✅ Check network connectivity
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      AppLogger.error('Connectivity check error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    // Check connectivity first
    if (!await hasNetworkConnection()) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    }

    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'referral_code': referralCode,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    // Check connectivity first
    if (!await hasNetworkConnection()) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    }

    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'phone': phone,
          'otp': otp,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resendOTP(String phone) async {
    // Check connectivity first
    if (!await hasNetworkConnection()) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    }

    try {
      final response = await _dio.post(
        '/auth/resend-otp',
        data: {'phone': phone},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPin(String pin, String? authToken) async {
    // Check connectivity first
    if (!await hasNetworkConnection()) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    }

    try {
      if (authToken != null) {
        _dio.options.headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _dio.post(
        '/auth/create-pin',
        data: {'pin': pin},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    // Check connectivity first
    if (!await hasNetworkConnection()) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    }

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _handleError(DioException error) {
    String errorMessage = 'Network error. Please check your connection.';

    if (error.response != null) {
      // Server responded with an error
      return error.response!.data ??
          {
            'success': false,
            'message': 'Server error. Please try again.',
          };
    } else if (error.type == DioExceptionType.connectionTimeout) {
      errorMessage =
          'Connection timeout. Server is taking too long to respond.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Response timeout. Please check your network.';
    } else if (error.type == DioExceptionType.unknown) {
      // Check if it's due to no internet
      errorMessage = 'Network error. Please check your internet connection.';
    }

    AppLogger.error('API Error: $error');
    return {
      'success': false,
      'message': errorMessage,
    };
  }
}
