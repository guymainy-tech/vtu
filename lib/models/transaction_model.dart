import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  airtime,
  data,
  utility,
  transfer,
  topup,
  withdrawal,
  refund,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String? description;
  final String? recipientPhone;
  final String? recipientName;
  final String? serviceProvider;
  final Map<String, dynamic>? metadata;
  final DateTime date;
  final String? failureReason;
  final String? transactionReference;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amount,
    this.description,
    this.recipientPhone,
    this.recipientName,
    this.serviceProvider,
    this.metadata,
    required this.date,
    this.failureReason,
    this.transactionReference,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate;
    final rawDate = data['date'];

    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    TransactionType typeFromString(String type) {
      return TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == type,
        orElse: () => TransactionType.topup,
      );
    }

    TransactionStatus statusFromString(String status) {
      return TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => TransactionStatus.pending,
      );
    }

    return TransactionModel(
      id: id,
      userId: data['user_id'] as String? ?? '',
      type: typeFromString(data['type'] as String? ?? 'topup'),
      status: statusFromString(data['status'] as String? ?? 'pending'),
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] as String?,
      recipientPhone: data['recipient_phone'] as String?,
      recipientName: data['recipient_name'] as String?,
      serviceProvider: data['service_provider'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      date: parsedDate,
      failureReason: data['failure_reason'] as String?,
      transactionReference: data['transaction_reference'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amount': amount,
      'description': description,
      'recipient_phone': recipientPhone,
      'recipient_name': recipientName,
      'service_provider': serviceProvider,
      'metadata': metadata,
      'date': Timestamp.fromDate(date),
      'failure_reason': failureReason,
      'transaction_reference': transactionReference,
    };
  }
}
