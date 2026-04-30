// lib/services/monnify_firebase_service.dart
/// Firebase Cloud Functions Service for Monnify
///
/// This service proxies all Monnify API calls through Firebase Cloud Functions.
/// This approach:
/// 1. Solves CORS issues on Flutter Web (no direct browser requests to external APIs)
/// 2. Keeps API credentials secure on the backend
/// 3. Provides better error handling and logging
/// 4. Enables rate limiting and security rules
///
/// Architecture:
/// Flutter App → Firebase Cloud Functions → Monnify API
///
/// The Firebase Cloud Functions handle:
/// - Authentication (requires Firebase user to be logged in)
/// - Getting Monnify access tokens
/// - Creating virtual accounts
/// - Validating user input
/// - Storing account details in Firestore

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class MonnifyFirebaseService {
  /// Singleton instance
  static final MonnifyFirebaseService _instance =
      MonnifyFirebaseService._internal();

  factory MonnifyFirebaseService() {
    return _instance;
  }

  MonnifyFirebaseService._internal();

  /// Firebase Cloud Functions instance
  FirebaseFunctions? _functions;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize the service
  void init({String? region}) {
    if (region != null) {
      _functions = FirebaseFunctions.instanceFor(region: region);
    } else {
      _functions = FirebaseFunctions.instance;
    }

    AppLogger.log('✅ Monnify Firebase Service initialized');
  }

  /// Get or initialize functions instance
  FirebaseFunctions get functions {
    if (_functions == null) {
      _functions = FirebaseFunctions.instance;
      AppLogger.log('⚠️  Auto-initializing Monnify Firebase Service');
    }
    return _functions!;
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
  /// - FirebaseFunctionsException if call fails
  /// - "unauthenticated" if user is not logged in
  /// - "invalid-argument" if required fields are missing
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

    AppLogger.log('🔄 Creating virtual account for user: ${user.uid}');
    AppLogger.log('📝 Name: $firstName $lastName');
    AppLogger.log(
        '📝 Email: $email | Phone: $phone | KYC: ${bvn != null ? 'BVN' : 'NIN'}');

    try {
      // Call Firebase Cloud Function
      final callable = functions.httpsCallable('createVirtualAccount');

      final response = await callable.call(<String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        if (bvn != null && bvn.isNotEmpty) 'bvn': bvn,
        if (nin != null && nin.isNotEmpty) 'nin': nin,
      });

      AppLogger.log('✅ Virtual account created successfully');

      // Extract account details from response
      final data = response.data as Map<String, dynamic>;
      final account = data['account'] as Map<String, dynamic>;

      AppLogger.log('📋 Account Number: ${account['accountNumber']}');
      AppLogger.log('📋 Account Name: ${account['accountName']}');
      AppLogger.log('📋 Bank: ${account['bankName']}');

      return account;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error(
          '❌ Firebase Function Error [${e.code}]: ${e.message}\nDetails: ${e.details}');

      // Provide user-friendly error messages
      final errorMessage = _getUserFriendlyError(e);
      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error('❌ Unexpected error creating virtual account: $e');
      throw Exception('Failed to create virtual account: $e');
    }
  }

  /// ========================================================================
  /// Get Virtual Account Details
  /// ========================================================================
  /// Retrieves virtual account details from Monnify
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
      final callable = functions.httpsCallable('getVirtualAccount');

      final response = await callable.call(<String, dynamic>{
        'accountReference': accountReference,
      });

      final data = response.data as Map<String, dynamic>;
      final account = data['account'] as Map<String, dynamic>;

      AppLogger.log('✅ Virtual account retrieved successfully');
      return account;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ Error fetching account [${e.code}]: ${e.message}');
      throw Exception('Failed to retrieve virtual account: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Unexpected error: $e');
      rethrow;
    }
  }

  /// ========================================================================
  /// Verify Transaction
  /// ========================================================================
  /// Verifies a transaction with Monnify
  ///
  /// Parameters:
  /// - transactionReference: Transaction reference to verify
  ///
  /// Returns:
  /// - Transaction details with status
  Future<Map<String, dynamic>> verifyTransaction(
    String transactionReference,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    AppLogger.log('🔄 Verifying transaction: $transactionReference');

    try {
      final callable = functions.httpsCallable('verifyTransaction');

      final response = await callable.call(<String, dynamic>{
        'transactionReference': transactionReference,
      });

      final data = response.data as Map<String, dynamic>;
      final transaction = data['transaction'] as Map<String, dynamic>;

      AppLogger.log('✅ Transaction verified successfully');
      return transaction;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error(
          '❌ Error verifying transaction [${e.code}]: ${e.message}');
      throw Exception('Failed to verify transaction: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Unexpected error: $e');
      rethrow;
    }
  }

  /// ========================================================================
  /// Helper: Convert Firebase Function errors to user-friendly messages
  /// ========================================================================
  String _getUserFriendlyError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please log in to create a virtual account';

      case 'invalid-argument':
        // Extract specific field error from message
        if (e.message!.contains('firstName')) {
          return 'First name is required';
        } else if (e.message!.contains('lastName')) {
          return 'Last name is required';
        } else if (e.message!.contains('email')) {
          return 'Valid email is required';
        } else if (e.message!.contains('phone')) {
          return 'Phone number is required';
        } else if (e.message!.contains('BVN') || e.message!.contains('NIN')) {
          return 'Either BVN or NIN is required (CBN KYC regulation)';
        } else if (e.message!.contains('must be 11 digits')) {
          return e.message ?? 'BVN/NIN must be exactly 11 digits';
        }
        return e.message ?? 'Invalid input. Please check your details';

      case 'permission-denied':
        return 'You do not have permission to access this resource';

      case 'internal':
        if (e.message!.contains('Monnify')) {
          return 'Monnify service error: ${e.message}';
        }
        return 'An error occurred. Please try again.';

      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';

      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';

      default:
        return 'Error: ${e.message ?? 'Unknown error'}';
    }
  }

  /// ========================================================================
  /// Helper: Check if user is authenticated
  /// ========================================================================
  bool get isUserAuthenticated => _auth.currentUser != null;

  /// ========================================================================
  /// Helper: Get current user ID
  /// ========================================================================
  String? get currentUserId => _auth.currentUser?.uid;

  /// ========================================================================
  /// Helper: Get current user email
  /// ========================================================================
  String? get currentUserEmail => _auth.currentUser?.email;
}

/// Convenience singleton accessor
final monnifyService = MonnifyFirebaseService();
