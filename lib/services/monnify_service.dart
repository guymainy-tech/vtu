// lib/services/monnify_service.dart
/// Monnify API Service for creating virtual accounts and handling transactions
///
/// IMPORTANT - WEB PLATFORM CORS LIMITATION:
/// When running on the web platform (Flutter for Web), browsers enforce CORS
/// (Cross-Origin Resource Sharing) by default. Direct requests to external
/// APIs like Monnify may be blocked unless:
///
/// SOLUTION 1: Use a Backend Proxy (RECOMMENDED)
/// - Create a backend API (Node.js, Python, etc.) that proxies requests to Monnify
/// - Call your backend from the Flutter web app instead of calling Monnify directly
/// - This also improves security by hiding API credentials
///
/// SOLUTION 2: Configure CORS on Monnify
/// - Contact Monnify support to enable CORS for your domain
/// - Add your app's URL to their CORS whitelist
///
/// SOLUTION 3: Use Firebase Cloud Functions
/// - Use Firebase Cloud Functions as a backend proxy
/// - Avoids exposing API credentials in client code
///
/// For native platforms (Android/iOS), this service works without issues
/// since native apps don't have browser CORS restrictions.

import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

class MonnifyService {
  static const String _baseUrl = 'https://sandbox.monnify.com';
  static const String _apiKey =
      'MK_TEST_R284ZF2W8Y'; // Replace with actual API key
  static const String _apiSecret =
      '8E4TK6XZ41UVDJ3705PPHGSDLQK7PS07'; // Add your API Secret here
  static const String _contractCode =
      '9529108403'; // Replace with actual contract code

  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 3);

  late Dio _dio;
  final ConnectivityService _connectivityService = ConnectivityService();

  MonnifyService() {
    // Create Basic Auth header (base64 encoded credentials)
    final credentials = '$_apiKey:$_apiSecret';
    final encodedCredentials = base64Encode(utf8.encode(credentials));

    // Build headers with CORS support for web platform
    final headers = {
      'Authorization': 'Basic $encodedCredentials',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add web-specific headers if running on web
    if (kIsWeb) {
      headers.addAll({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
      AppLogger.log(
          '⚠️ Running on WEB platform - May require backend proxy for CORS');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: headers,
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    // Add error and request interceptor for better debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.log('🔵 [Monnify Request] ${options.method} ${options.path}');
        if (kIsWeb) {
          AppLogger.log('   Platform: Web');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        _logConnectionError(error);
        return handler.next(error);
      },
      onResponse: (response, handler) {
        AppLogger.log(
            '✅ [Monnify Response] ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
    ));
  }

  /// Check network connectivity before making requests
  Future<bool> _checkConnectivity() async {
    final hasConnection = await _connectivityService.hasNetworkConnection();
    if (!hasConnection) {
      AppLogger.error('❌ No network connection available');
    }
    return hasConnection;
  }

  void _logConnectionError(DioException error) {
    String errorMessage = '';
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Connection timeout (60s). Check your network speed.';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Server response timeout (60s). API may be slow.';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Request send timeout (60s). Check your network.';
        break;
      case DioExceptionType.connectionError:
        if (kIsWeb) {
          errorMessage =
              'CORS Error (Web): The browser blocked the request. This usually means:\n'
              '  1. Monnify API doesn\'t allow requests from this origin\n'
              '  2. You need to use a backend proxy to call the API\n'
              '  3. Or configure CORS on Monnify side\n'
              '  Original error: ${error.message}';
        } else {
          errorMessage = 'Network connection error. Verify internet access.';
        }
        break;
      case DioExceptionType.badResponse:
        errorMessage =
            'Bad response: ${error.response?.statusCode} - ${error.response?.statusMessage}';
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      default:
        errorMessage = 'Error: ${error.message}';
    }
    AppLogger.error('❌ Monnify Error: $errorMessage');
  }

  /// Retry with exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    int attempts = 0;
    Duration delay = _retryDelay;

    while (attempts < _maxRetries) {
      try {
        // Check connectivity before attempt
        if (!await _checkConnectivity()) {
          throw Exception('No internet connection');
        }

        AppLogger.log(
            '⏳ $operationName - Attempt ${attempts + 1}/$_maxRetries');
        return await operation();
      } on DioException catch (e) {
        attempts++;
        _logConnectionError(e);

        // Determine if error is retryable
        bool isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;

        if (isRetryable && attempts < _maxRetries) {
          AppLogger.log('🔄 Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
          continue;
        }

        AppLogger.error('❌ $operationName failed after $attempts attempts');
        rethrow;
      } catch (e) {
        AppLogger.error('❌ Unexpected error in $operationName: $e');
        rethrow;
      }
    }

    throw Exception('$operationName failed after $_maxRetries attempts');
  }

  /// Create a virtual account for the user
  /// BVN or NIN is required for CBN KYC compliance (mandatory as of Sept 16, 2024)
  Future<Map<String, dynamic>?> createVirtualAccount({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? bvn,
    String? nin,
  }) async {
    // Validate that at least BVN or NIN is provided
    if ((bvn == null || bvn.isEmpty) && (nin == null || nin.isEmpty)) {
      AppLogger.error(
          '❌ BVN or NIN is required for account creation (CBN KYC requirement)');
      return null;
    }

    try {
      return await _retryWithBackoff(
        () async {
          final requestData = {
            'contractCode': _contractCode,
            'accountReference': userId,
            'accountName': '$firstName $lastName',
            'currencyCode': 'NGN',
            'customerEmail': email,
            'customerName': '$firstName $lastName',
            'incomeSplitConfig': [],
            'allocationRules': [],
          };

          // Add BVN or NIN for KYC compliance
          if (bvn != null && bvn.isNotEmpty) {
            requestData['bvn'] = bvn;
            AppLogger.log(
                '📝 Creating account with BVN: ${bvn.replaceRange(0, 8, '********')}');
          }
          if (nin != null && nin.isNotEmpty) {
            requestData['nin'] = nin;
            AppLogger.log(
                '📝 Creating account with NIN: ${nin.replaceRange(0, 8, '********')}');
          }

          final response = await _dio.post(
            '/api/v2/bank-transfer/reserved-accounts',
            data: requestData,
          );

          final statusCode = response.statusCode ?? 500;
          if (statusCode == 200 || statusCode == 201) {
            AppLogger.log(
                '✅ Virtual account created successfully with KYC verification');
            return response.data as Map<String, dynamic>;
          } else if (statusCode == 400) {
            // Check if error is related to BVN/NIN validation
            final errorMessage = response.data['message'] ?? 'Invalid request';
            if (errorMessage.toString().toLowerCase().contains('bvn') ||
                errorMessage.toString().toLowerCase().contains('nin')) {
              throw Exception('❌ Invalid BVN/NIN. Please verify the details.');
            }
            throw Exception('❌ Client error: $errorMessage');
          } else if (statusCode == 401 || statusCode == 403) {
            throw Exception('❌ Authentication failed. Check API credentials.');
          } else if (statusCode >= 400 && statusCode < 500) {
            throw Exception(
                '❌ Client error: $statusCode - ${response.statusMessage}');
          } else if (statusCode >= 500) {
            throw Exception('❌ Server error: $statusCode. Retrying...');
          }

          return null;
        },
        'Create Virtual Account',
      );
    } catch (e) {
      AppLogger.error('❌ Final error creating virtual account: $e');
      return null;
    }
  }

  /// Get virtual account details
  Future<Map<String, dynamic>?> getVirtualAccount({
    required String accountReference,
  }) async {
    try {
      return await _retryWithBackoff(
        () async {
          final response = await _dio.get(
            '/api/v2/accounts/reserved/$accountReference',
            queryParameters: {
              'contractCode': _contractCode,
            },
          );

          final statusCode = response.statusCode ?? 500;
          if (statusCode == 200) {
            AppLogger.log('✅ Virtual account retrieved successfully');
            return response.data as Map<String, dynamic>;
          } else if (statusCode == 401 || statusCode == 403) {
            throw Exception('❌ Authentication failed.');
          } else if (statusCode >= 500) {
            throw Exception('❌ Server error: $statusCode. Retrying...');
          }

          return null;
        },
        'Get Virtual Account',
      );
    } catch (e) {
      AppLogger.error('❌ Final error getting virtual account: $e');
      return null;
    }
  }

  /// Transfer from virtual account to wallet
  Future<bool> transferFromVirtualAccount({
    required String fromAccount,
    required String toAccount,
    required double amount,
    required String reference,
    String? description,
  }) async {
    try {
      final result = await _retryWithBackoff(
        () async {
          final response = await _dio.post(
            '/api/v2/transactions/transfer',
            data: {
              'sourceAccountNumber': fromAccount,
              'destinationAccountNumber': toAccount,
              'amount': amount,
              'transactionReference': reference,
              'narration': description ?? 'Wallet top-up',
            },
          );

          final statusCode = response.statusCode ?? 500;
          if (statusCode == 200 || statusCode == 201) {
            AppLogger.log('✅ Transfer successful');
            return true;
          } else if (statusCode == 401 || statusCode == 403) {
            throw Exception('❌ Authentication failed.');
          } else if (statusCode >= 500) {
            throw Exception('❌ Server error: $statusCode. Retrying...');
          }

          return false;
        },
        'Transfer from Virtual Account',
      );
      return result;
    } catch (e) {
      AppLogger.error('❌ Final error during transfer: $e');
      return false;
    }
  }

  /// Verify transaction
  Future<Map<String, dynamic>?> verifyTransaction({
    required String transactionReference,
  }) async {
    try {
      return await _retryWithBackoff(
        () async {
          final response = await _dio.get(
            '/api/v2/transactions/query',
            queryParameters: {
              'transactionReference': transactionReference,
            },
          );

          final statusCode = response.statusCode ?? 500;
          if (statusCode == 200) {
            AppLogger.log('✅ Transaction verified successfully');
            return response.data as Map<String, dynamic>;
          } else if (statusCode == 401 || statusCode == 403) {
            throw Exception('❌ Authentication failed.');
          } else if (statusCode >= 500) {
            throw Exception('❌ Server error: $statusCode. Retrying...');
          }

          return null;
        },
        'Verify Transaction',
      );
    } catch (e) {
      AppLogger.error('❌ Final error verifying transaction: $e');
      return null;
    }
  }

  /// Get transaction history
  Future<List<dynamic>?> getTransactionHistory({
    required String accountNumber,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final result = await _retryWithBackoff(
        () async {
          final response = await _dio.get(
            '/api/v2/transactions/accounts/$accountNumber',
            queryParameters: {
              'limit': limit,
              'offset': offset,
            },
          );

          final statusCode = response.statusCode ?? 500;
          if (statusCode == 200) {
            AppLogger.log('✅ Transaction history retrieved successfully');
            return response.data['content'] as List<dynamic>;
          } else if (statusCode == 401 || statusCode == 403) {
            throw Exception('❌ Authentication failed.');
          } else if (statusCode >= 500) {
            throw Exception('❌ Server error: $statusCode. Retrying...');
          }

          return null;
        },
        'Get Transaction History',
      );
      return result;
    } catch (e) {
      AppLogger.error('❌ Final error getting transaction history: $e');
      return null;
    }
  }
}
