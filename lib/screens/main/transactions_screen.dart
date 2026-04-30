// lib/screens/main/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final List<TransactionModel> _transactions = [];
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _selectedFilter;
  List<TransactionModel> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();

    // ✅ TEMP DATA (remove when using Firebase)
    _transactions.addAll([
      TransactionModel(
        id: '1',
        userId: 'user_1',
        type: TransactionType.airtime,
        amount: 500,
        status: TransactionStatus.completed,
        date: DateTime.now(),
        description: 'MTN Airtime',
      ),
      TransactionModel(
        id: '2',
        userId: 'user_1',
        type: TransactionType.data,
        amount: 1000,
        status: TransactionStatus.pending,
        date: DateTime.now(),
        description: 'Glo Data',
      ),
      TransactionModel(
        id: '3',
        userId: 'user_1',
        type: TransactionType.topup,
        amount: 2000,
        status: TransactionStatus.completed,
        date: DateTime.now(),
        description: 'Wallet Funding',
      ),
    ]);

    _filteredTransactions = _transactions;
    _searchController.addListener(_filterTransactions);
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        final matchesSearch =
            transaction.description?.toLowerCase().contains(query) ??
                false ||
                    transaction.id.toLowerCase().contains(query) ||
                    transaction.amount.toString().contains(query);

        final matchesFilter =
            _selectedFilter == null || transaction.type == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTransactions,
            tooltip: 'Export Transactions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedFilter == null,
                        onSelected: (_) {
                          setState(() => _selectedFilter = null);
                          _filterTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Airtime'),
                        selected: _selectedFilter == TransactionType.airtime,
                        onSelected: (_) {
                          setState(
                              () => _selectedFilter = TransactionType.airtime);
                          _filterTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Data'),
                        selected: _selectedFilter == TransactionType.data,
                        onSelected: (_) {
                          setState(
                              () => _selectedFilter = TransactionType.data);
                          _filterTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Transfers'),
                        selected: _selectedFilter == TransactionType.transfer,
                        onSelected: (_) {
                          setState(
                              () => _selectedFilter = TransactionType.transfer);
                          _filterTransactions();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? _buildEmptyState(context)
                : _buildTransactionsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No Transactions Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(context, transaction);
      },
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final isCredit = transaction.type == TransactionType.topup ||
        transaction.type == TransactionType.transfer;
    final amountColor = isCredit ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: amountColor,
            ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Transaction',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.date), // ✅ FIXED
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Amount + Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'} NGN ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(transaction.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }

  Future<void> _exportTransactions() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Transaction History Export');
      buffer.writeln(
          'Generated: ${DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now())}');
      buffer.writeln('');
      buffer.writeln('Date,Type,Description,Amount,Status');

      for (final transaction in _filteredTransactions) {
        buffer.writeln(
          '${DateFormat('MMM d, yyyy').format(transaction.date)},'
          '${transaction.type.toString().split('.').last},'
          '${transaction.description ?? ''},'
          '₦${transaction.amount.toStringAsFixed(2)},'
          '${transaction.status.toString().split('.').last}',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transactions exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error exporting transactions')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
