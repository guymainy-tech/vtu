// lib/screens/main/transaction_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../services/receipt_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late TransactionModel transaction;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _buildStatusCard(),
              const SizedBox(height: 32),

              // Transaction Details
              _buildDetailSection(),
              const SizedBox(height: 32),

              // Recipient/Service Details
              if (transaction.recipientPhone != null) _buildRecipientSection(),
              if (transaction.serviceProvider != null) _buildServiceSection(),

              const SizedBox(height: 32),

              // Additional Info
              if (transaction.metadata != null) _buildMetadataSection(),

              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = transaction.status == TransactionStatus.completed
        ? Colors.green
        : transaction.status == TransactionStatus.failed
            ? Colors.red
            : Colors.orange;

    final statusText = transaction.status.toString().split('.').last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            transaction.status == TransactionStatus.completed
                ? Icons.check_circle
                : transaction.status == TransactionStatus.failed
                    ? Icons.cancel
                    : Icons.schedule,
            color: statusColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₦${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          'Transaction ID',
          transaction.id,
        ),
        _buildDetailRow(
          'Type',
          transaction.type.toString().split('.').last.toUpperCase(),
        ),
        _buildDetailRow(
          'Date & Time',
          _formatDateTime(transaction.date),
        ),
        if (transaction.transactionReference != null)
          _buildDetailRow(
            'Reference',
            transaction.transactionReference!,
          ),
      ],
    );
  }

  Widget _buildRecipientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recipient Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Phone Number', transaction.recipientPhone!),
        if (transaction.recipientName != null)
          _buildDetailRow('Name', transaction.recipientName!),
      ],
    );
  }

  Widget _buildServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Provider',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Provider', transaction.serviceProvider!),
        if (transaction.description != null)
          _buildDetailRow('Description', transaction.description!),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...transaction.metadata!.entries.map((entry) {
          return _buildDetailRow(entry.key, entry.value.toString());
        }).toList(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Share Receipt Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _shareReceipt,
            icon: const Icon(Icons.share),
            label: Text(_isGenerating ? 'Generating...' : 'Share Receipt'),
          ),
        ),
        const SizedBox(height: 12),

        // Download Receipt Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _downloadReceipt,
            icon: const Icon(Icons.download),
            label: const Text('Download Receipt'),
          ),
        ),
        const SizedBox(height: 12),

        // View Summary Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showReceiptSummary,
            icon: const Icon(Icons.info_outline),
            label: const Text('View Summary'),
          ),
        ),
      ],
    );
  }

  Future<void> _shareReceipt() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      final userName = user?['full_name'] ?? 'User';
      final userPhone = user?['phone'] ?? '';
      final receiptService = ReceiptService();

      final receiptFile = await receiptService.generateReceiptPDF(
        transaction,
        userName,
        userPhone,
      );

      if (receiptFile != null) {
        await receiptService.shareReceipt(receiptFile, transaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt shared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error sharing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing receipt')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadReceipt() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      final userName = user?['full_name'] ?? 'User';
      final userPhone = user?['phone'] ?? '';
      final receiptService = ReceiptService();

      final receiptFile = await receiptService.generateReceiptPDF(
        transaction,
        userName,
        userPhone,
      );

      if (receiptFile != null) {
        final downloaded = await receiptService.downloadReceipt(receiptFile);
        if (downloaded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error downloading receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error downloading receipt')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showReceiptSummary() {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      final userName = user?['full_name'] ?? 'User';
      final userPhone = user?['phone'] ?? '';
      final receiptService = ReceiptService();

      final summary = receiptService.generateReceiptSummary(
        transaction,
        userName,
        userPhone,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Receipt Summary'),
          content: SingleChildScrollView(
            child: Text(summary,
                style: const TextStyle(fontSize: 12, height: 1.6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('Error showing receipt summary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading receipt summary')),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
