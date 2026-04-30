// lib/services/monnify_http_service.dart
/// HTTP-based Monnify Service
///
/// This service calls your backend server (Render/Railway) instead of Firebase.
/// This allows you to deploy without upgrading Firebase to Blaze plan.
///
/// Architecture:
/// Flutter App → HTTP → Render/Railway Backend → Monnify API
///
/// Endpoints:
/// - POST /api/createVirtualAccount
/// - GET /api/getVirtualAccount
/// - POST /api/verifyTransaction

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class MonnifyHttpService {
  /// Singleton instance
  static final MonnifyHttpService _instance = MonnifyHttpService._internal();

  factory MonnifyHttpService() {
    return _instance;
  }

  MonnifyHttpService._internal();

  /// Backend URL (change to your Render/Railway URL)
  /// Example: 'https://vtu-app-backend.onrender.com'
  ///          'https://vtu-app-production.railway.app'
  String _backendUrl = 'https://vtu-app-backend.onrender.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize the service with backend URL
  void init({String? backendUrl}) {
    if (backendUrl != null) {
      _backendUrl = backendUrl;
    }
    AppLogger.log('✅ Monnify HTTP Service initialized with: $_backendUrl');
  }

  /// ========================================================================
  /// Create Virtual Account
  /// ========================================================================
  /// Creates a virtual account for the authenticated user
  ///
  /// Requirements:
  /// - User must be authenticated (Firebase Auth)
  /// - Either BVN or NIN must be provided (CBN KYC requirement)
  ///
  /// Parameters:
  /// - firstName: User's first name
  /// - lastName: User's last name
  /// - email: User's email address
  /// - phone: User's phone number
  /// - bvn: Bank Verification Number (11 digits) - optional
  /// - nin: National ID Number (11 digits) - optional
  ///
  /// Returns:
  /// - accountNumber: Virtual account number
  /// - accountName: Account name (firstName lastName)
  /// - bankName: Bank name where account was created
  /// - bankCode: Bank code
  /// - accountReference: Account reference (Firebase UID)
  ///
  /// Throws:
  /// - Exception if user is not authenticated
  /// - Exception if required fields are missing
  /// - Exception if API call fails
  Future<Map<String, dynamic>> createVirtualAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? bvn,
    String? nin,
  }) async {
    // Check if user is authenticated
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.error('❌ User is not authenticated');
      throw Exception('User must be authenticated to create virtual account');
    }

    AppLogger.log('🔄 Creating virtual account via HTTP backend...');
    AppLogger.log('🔄 Creating virtual account for user: ${user.uid}');
    AppLogger.log('📝 Name: $firstName $lastName');
    AppLogger.log(
        '📝 Email: $email | Phone: $phone | KYC: ${bvn != null ? 'BVN' : 'NIN'}');

    try {
      // Prepare request body
      final body = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'userId': user.uid,
      };

      // Add BVN or NIN if provided
      if (bvn != null && bvn.isNotEmpty) {
        body['bvn'] = bvn;
      }
      if (nin != null && nin.isNotEmpty) {
        body['nin'] = nin;
      }

      // Make HTTP request
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/createVirtualAccount'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timeout - backend not responding'),
          );

      AppLogger.log('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final account = data['account'] as Map<String, dynamic>;

          AppLogger.log('✅ Virtual account created successfully');
          AppLogger.log('📋 Account Number: ${account['accountNumber']}');
          AppLogger.log('📋 Account Name: ${account['accountName']}');
          AppLogger.log('📋 Bank: ${account['bankName']}');

          return account;
        } else {
          final errorMessage = data['error'] ?? 'Unknown error from backend';
          AppLogger.error('❌ Backend error: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        final errorBody = response.body;
        AppLogger.error('❌ HTTP ${response.statusCode} error: $errorBody');
        throw Exception(
            'Server error (${response.statusCode}): ${response.reasonPhrase}');
      }
    } catch (e) {
      AppLogger.error('❌ Unexpected error creating virtual account: $e');
      throw Exception('Failed to create virtual account: $e');
    }
  }

  /// ========================================================================
  /// Get Virtual Account Details
  /// ========================================================================
  /// Retrieves virtual account details from Monnify via backend
  ///
  /// Parameters:
  /// - accountReference: Account reference (typically Firebase UID)
  ///
  /// Returns:
  /// - accountNumber: Virtual account number
  /// - accountName: Account name
  /// - bankName: Bank name
  Future<Map<String, dynamic>> getVirtualAccount(
    String accountReference,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    AppLogger.log('🔄 Fetching virtual account details...');

    try {
      final response = await http.get(
        Uri.parse(
            '$_backendUrl/api/getVirtualAccount?accountReference=$accountReference'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
            throw Exception('Request timeout - backend not responding'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          AppLogger.log('✅ Retrieved virtual account details');
          return data['account'] as Map<String, dynamic>;
        } else {
          throw Exception(data['error'] ?? 'Failed to retrieve account');
        }
      } else {
        throw Exception(
            'Server error (${response.statusCode}): ${response.reasonPhrase}');
      }
    } catch (e) {
      AppLogger.error('❌ Error retrieving account: $e');
      throw Exception('Failed to retrieve account details: $e');
    }
  }

  /// ========================================================================
  /// Verify Transaction
  /// ========================================================================
  /// Verifies a transaction with Monnify via backend
  ///
  /// Parameters:
  /// - transactionReference: Transaction reference to verify
  ///
  /// Returns:
  /// - Transaction details including status
  Future<Map<String, dynamic>> verifyTransaction(
    String transactionReference,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    AppLogger.log('🔄 Verifying transaction: $transactionReference');

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/verifyTransaction'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'transactionReference': transactionReference}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timeout - backend not responding'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          AppLogger.log('✅ Transaction verified: $transactionReference');
          return data['transaction'] as Map<String, dynamic>;
        } else {
          throw Exception(data['error'] ?? 'Failed to verify transaction');
        }
      } else {
        throw Exception(
            'Server error (${response.statusCode}): ${response.reasonPhrase}');
      }
    } catch (e) {
      AppLogger.error('❌ Error verifying transaction: $e');
      throw Exception('Failed to verify transaction: $e');
    }
  }

  /// ========================================================================
  /// Helper Methods
  /// ========================================================================

  /// Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;
}
