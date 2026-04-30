// lib/services/vtu_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/data_plan_model.dart';
import '../utils/logger.dart';

class VTUService {
  static final VTUService _instance = VTUService._internal();
  late FirebaseFirestore _firestore;

  factory VTUService() => _instance;

  VTUService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  // ================= AIRTIME PURCHASE =================
  Future<bool> buyAirtime({
    required String userId,
    required String phoneNumber,
    required double amount,
    required String networkOperator,
    required String pin,
  }) async {
    try {
      const uuid = Uuid();
      final transactionId = uuid.v4();

      final transaction = {
        'transaction_id': transactionId,
        'user_id': userId,
        'type': 'airtime',
        'status': 'pending',
        'amount': amount,
        'recipient_phone': phoneNumber,
        'service_provider': networkOperator,
        'date': FieldValue.serverTimestamp(),
        'description': 'Airtime purchase - $networkOperator',
      };

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .set(transaction);

      // TODO: Call backend API to process airtime
      // final result = await _apiService.buyAirtime(...);

      // Update transaction status
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'completed',
      });

      AppLogger.log('Airtime purchase successful: $transactionId');
      return true;
    } catch (e) {
      AppLogger.error('Airtime purchase error: $e');
      return false;
    }
  }

  // ================= DATA PURCHASE =================
  Future<bool> buyData({
    required String userId,
    required String phoneNumber,
    required DataPlanModel plan,
    required String networkOperator,
    required String pin,
  }) async {
    try {
      const uuid = Uuid();
      final transactionId = uuid.v4();

      final transaction = {
        'transaction_id': transactionId,
        'user_id': userId,
        'type': 'data',
        'status': 'pending',
        'amount': plan.price,
        'recipient_phone': phoneNumber,
        'service_provider': networkOperator,
        'metadata': {
          'plan_id': plan.planId,
          'plan_name': plan.name,
          'plan_size': plan.size,
          'validity': plan.validity,
        },
        'date': FieldValue.serverTimestamp(),
        'description': 'Data purchase - ${plan.name} on $networkOperator',
      };

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .set(transaction);

      // TODO: Call backend API to process data purchase
      // final result = await _apiService.buyData(...);

      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'completed',
      });

      AppLogger.log('Data purchase successful: $transactionId');
      return true;
    } catch (e) {
      AppLogger.error('Data purchase error: $e');
      return false;
    }
  }

  // ================= FUND TRANSFER =================
  Future<bool> transferFund({
    required String userId,
    required String recipientPhone,
    required String recipientName,
    required double amount,
    required String pin,
    required String? description,
  }) async {
    try {
      const uuid = Uuid();
      final transactionId = uuid.v4();

      final transaction = {
        'transaction_id': transactionId,
        'user_id': userId,
        'type': 'transfer',
        'status': 'pending',
        'amount': amount,
        'recipient_phone': recipientPhone,
        'recipient_name': recipientName,
        'date': FieldValue.serverTimestamp(),
        'description': description ?? 'Fund transfer',
      };

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .set(transaction);

      // TODO: Call backend API to process transfer
      // final result = await _apiService.transferFund(...);

      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'completed',
      });

      AppLogger.log('Fund transfer successful: $transactionId');
      return true;
    } catch (e) {
      AppLogger.error('Fund transfer error: $e');
      return false;
    }
  }

  // ================= UTILITY PAYMENT =================
  Future<bool> payUtility({
    required String userId,
    required String serviceType, // electricity, water, internet, etc.
    required String serviceProvider,
    required double amount,
    required String customerReference,
    required String pin,
  }) async {
    try {
      const uuid = Uuid();
      final transactionId = uuid.v4();

      final transaction = {
        'transaction_id': transactionId,
        'user_id': userId,
        'type': 'utility',
        'status': 'pending',
        'amount': amount,
        'service_provider': serviceProvider,
        'metadata': {
          'service_type': serviceType,
          'customer_reference': customerReference,
        },
        'date': FieldValue.serverTimestamp(),
        'description': '$serviceType payment via $serviceProvider',
      };

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .set(transaction);

      // TODO: Call backend API to process utility payment
      // final result = await _apiService.payUtility(...);

      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'completed',
      });

      AppLogger.log('Utility payment successful: $transactionId');
      return true;
    } catch (e) {
      AppLogger.error('Utility payment error: $e');
      return false;
    }
  }

  // ================= GET TRANSACTIONS =================
  Future<List<TransactionModel>> getUserTransactions(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Get transactions error: $e');
      return [];
    }
  }

  // ================= GET TRANSACTION DETAILS =================
  Future<TransactionModel?> getTransactionDetails(String transactionId) async {
    try {
      final doc =
          await _firestore.collection('transactions').doc(transactionId).get();

      if (doc.exists) {
        return TransactionModel.fromMap(doc.data() ?? {}, doc.id);
      }
      return null;
    } catch (e) {
      AppLogger.error('Get transaction details error: $e');
      return null;
    }
  }

  // ================= LISTEN TO TRANSACTIONS =================
  Stream<List<TransactionModel>> getUserTransactionsStream(String userId) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
