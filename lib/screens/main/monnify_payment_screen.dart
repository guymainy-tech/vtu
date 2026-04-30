// lib/screens/main/monnify_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../utils/logger.dart';
import '../../widgets/custom_button.dart';

typedef PaymentConfirmedCallback = void Function(bool verified);

class MonnifyPaymentScreen extends StatefulWidget {
  final double amount;
  final String transactionRef;
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String bankName;
  final PaymentConfirmedCallback? onPaymentConfirmed;

  const MonnifyPaymentScreen({
    Key? key,
    required this.amount,
    required this.transactionRef,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.bankName,
    this.onPaymentConfirmed,
  }) : super(key: key);

  @override
  State<MonnifyPaymentScreen> createState() => _MonnifyPaymentScreenState();
}

class _MonnifyPaymentScreenState extends State<MonnifyPaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount to Transfer',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Virtual Account Details
            const Text(
              'Transfer to Virtual Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Bank Name
            _buildDetailCard(
              icon: Icons.account_balance,
              label: 'Bank',
              value: widget.bankName,
            ),
            const SizedBox(height: 12),

            // Account Number
            _buildDetailCard(
              icon: Icons.account_balance,
              label: 'Account Number',
              value: widget.accountNumber,
              copyable: true,
            ),
            const SizedBox(height: 12),

            // Account Name
            _buildDetailCard(
              icon: Icons.person,
              label: 'Account Name',
              value: widget.accountName,
              copyable: true,
            ),
            const SizedBox(height: 12),

            // Reference
            _buildDetailCard(
              icon: Icons.receipt,
              label: 'Reference',
              value: widget.transactionRef,
              copyable: true,
            ),
            const SizedBox(height: 32),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem('1. Use your bank app or ATM'),
                  _buildInstructionItem(
                      '2. Transfer exactly ₦${widget.amount.toStringAsFixed(2)}'),
                  _buildInstructionItem(
                      '3. Use reference as description/narration'),
                  _buildInstructionItem(
                      '4. Your account will be credited instantly'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Countdown Timer
            _buildCountdown(),
            const SizedBox(height: 24),

            // Action Buttons
            CustomButton(
              onPressed: _confirmPayment,
              text: 'I\'ve Completed Payment',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(milliseconds: 800),
                  ),
                );
              },
              child: const Icon(Icons.copy, color: Colors.blue, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final now = DateTime.now();
    final expiryTime = now.add(const Duration(minutes: 30));
    final formatter = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Expires',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Complete payment by ${formatter.format(expiryTime)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayment() {
    try {
      // In a real implementation, you would verify the payment with Monnify API here
      // For now, we assume payment was successful if the user clicked this button

      widget.onPaymentConfirmed?.call(true);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Payment confirmed. Your wallet will be updated shortly.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('Error confirming payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error confirming payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
