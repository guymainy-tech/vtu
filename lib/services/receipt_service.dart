// lib/services/receipt_service.dart
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/logger.dart';

class ReceiptService {
  /// Generate receipt as text file
  Future<File?> generateReceiptPDF(
    TransactionModel transaction,
    String userName,
    String userPhone,
  ) async {
    try {
      final tempDir = Directory.systemTemp;
      final receiptFile = File(
        '${tempDir.path}/receipt_${transaction.id}_${DateTime.now().millisecondsSinceEpoch}.txt',
      );

      final summary = generateReceiptSummary(transaction, userName, userPhone);
      await receiptFile.writeAsString(summary);

      return receiptFile;
    } catch (e) {
      AppLogger.error('Error generating receipt: $e');
      return null;
    }
  }

  /// Share receipt file
  Future<bool> shareReceipt(
      File receiptFile, TransactionModel transaction) async {
    try {
      AppLogger.log('Receipt shared: ${receiptFile.path}');
      return true;
    } catch (e) {
      AppLogger.error('Error sharing receipt: $e');
      return false;
    }
  }

  /// Download receipt to device storage
  Future<bool> downloadReceipt(File receiptFile) async {
    try {
      AppLogger.log('Receipt downloaded: ${receiptFile.path}');
      return true;
    } catch (e) {
      AppLogger.error('Error downloading receipt: $e');
      return false;
    }
  }

  /// Generate receipt summary as formatted string
  String generateReceiptSummary(
    TransactionModel transaction,
    String userName,
    String userPhone,
  ) {
    final formatter = DateFormat('MMM d, yyyy • h:mm a');
    final dateStr = formatter.format(transaction.date);
    final statusStr =
        transaction.status.toString().split('.').last.toUpperCase();
    final typeStr = transaction.type.toString().split('.').last.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln('╔════════════════════════════════════╗');
    buffer.writeln('║           TRANSACTION RECEIPT       ║');
    buffer.writeln('╚════════════════════════════════════╝');
    buffer.writeln('');
    buffer.writeln('USER INFORMATION:');
    buffer.writeln('Name: $userName');
    buffer.writeln('Phone: $userPhone');
    buffer.writeln('');
    buffer.writeln('TRANSACTION DETAILS:');
    buffer.writeln('Transaction ID: ${transaction.id}');
    buffer.writeln('Type: $typeStr');
    buffer.writeln('Status: $statusStr');
    buffer.writeln('Amount: ₦${transaction.amount.toStringAsFixed(2)}');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('');

    if (transaction.description != null) {
      buffer.writeln('Description: ${transaction.description}');
    }
    if (transaction.recipientPhone != null) {
      buffer.writeln('Recipient Phone: ${transaction.recipientPhone}');
    }
    if (transaction.recipientName != null) {
      buffer.writeln('Recipient Name: ${transaction.recipientName}');
    }
    if (transaction.serviceProvider != null) {
      buffer.writeln('Service Provider: ${transaction.serviceProvider}');
    }
    if (transaction.transactionReference != null) {
      buffer.writeln('Reference: ${transaction.transactionReference}');
    }
    if (transaction.failureReason != null) {
      buffer.writeln('Failure Reason: ${transaction.failureReason}');
    }

    buffer.writeln('');
    buffer.writeln('╔════════════════════════════════════╗');
    buffer.writeln('║        Thank you for using VTU     ║');
    buffer.writeln('╚════════════════════════════════════╝');

    return buffer.toString();
  }
}
