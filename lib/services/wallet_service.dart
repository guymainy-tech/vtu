// lib/services/wallet_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../utils/logger.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  late FirebaseFirestore _firestore;

  factory WalletService() => _instance;

  WalletService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  // ================= CREATE WALLET =================
  Future<void> createWallet(String userId) async {
    try {
      await _firestore.collection('wallets').doc(userId).set({
        'wallet_id': userId,
        'user_id': userId,
        'balance': 0.0,
        'total_spent': 0.0,
        'total_received': 0.0,
        'last_updated': FieldValue.serverTimestamp(),
        'currency': '₦',
      });
      AppLogger.log('Wallet created for user: $userId');
    } catch (e) {
      AppLogger.error('Create wallet error: $e');
      rethrow;
    }
  }

  // ================= GET WALLET =================
  Future<WalletModel?> getWallet(String userId) async {
    try {
      final doc = await _firestore.collection('wallets').doc(userId).get();

      if (doc.exists) {
        return WalletModel.fromJson({...doc.data() ?? {}, 'wallet_id': userId});
      }
      return null;
    } catch (e) {
      AppLogger.error('Get wallet error: $e');
      return null;
    }
  }

  // ================= WATCH WALLET =================
  Stream<WalletModel?> watchWallet(String userId) {
    return _firestore.collection('wallets').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return WalletModel.fromJson({...doc.data() ?? {}, 'wallet_id': userId});
      }
      return null;
    });
  }

  // ================= CREDIT WALLET =================
  Future<void> creditWallet({
    required String userId,
    required double amount,
  }) async {
    try {
      final ref = _firestore.collection('wallets').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          // Create wallet if it doesn't exist
          transaction.set(ref, {
            'wallet_id': userId,
            'user_id': userId,
            'balance': amount,
            'total_spent': 0.0,
            'total_received': amount,
            'last_updated': FieldValue.serverTimestamp(),
            'currency': '₦',
          });
        } else {
          final currentBalance =
              (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
          final totalReceived =
              (snapshot.data()?['total_received'] as num?)?.toDouble() ?? 0.0;

          transaction.update(ref, {
            'balance': currentBalance + amount,
            'total_received': totalReceived + amount,
            'last_updated': FieldValue.serverTimestamp(),
          });
        }
      });

      AppLogger.log('Wallet credited: $userId, Amount: $amount');
    } catch (e) {
      AppLogger.error('Credit wallet error: $e');
      rethrow;
    }
  }

  // ================= DEBIT WALLET =================
  Future<bool> debitWallet({
    required String userId,
    required double amount,
  }) async {
    try {
      final ref = _firestore.collection('wallets').doc(userId);
      bool success = false;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('Wallet does not exist');
        }

        final currentBalance =
            (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        final totalSpent =
            (snapshot.data()?['total_spent'] as num?)?.toDouble() ?? 0.0;

        transaction.update(ref, {
          'balance': currentBalance - amount,
          'total_spent': totalSpent + amount,
          'last_updated': FieldValue.serverTimestamp(),
        });

        success = true;
      });

      AppLogger.log('Wallet debited: $userId, Amount: $amount');
      return success;
    } catch (e) {
      AppLogger.error('Debit wallet error: $e');
      return false;
    }
  }

  // ================= GET BALANCE =================
  Future<double> getBalance(String userId) async {
    try {
      final doc = await _firestore.collection('wallets').doc(userId).get();

      if (doc.exists) {
        return (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      AppLogger.error('Get balance error: $e');
      return 0.0;
    }
  }

  // ================= WITHDRAW FROM WALLET =================
  Future<bool> withdrawFromWallet({
    required String userId,
    required double amount,
    required String bankAccount,
    required String bankName,
  }) async {
    try {
      // Debit the wallet
      final debited = await debitWallet(userId: userId, amount: amount);

      if (!debited) {
        return false;
      }

      // Record withdrawal transaction (can be tracked separately)
      AppLogger.log(
          'Withdrawal initiated: $userId, Amount: $amount, Bank: $bankName');

      return true;
    } catch (e) {
      AppLogger.error('Withdrawal error: $e');
      return false;
    }
  }
}
