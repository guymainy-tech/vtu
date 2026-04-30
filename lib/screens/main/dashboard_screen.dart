// lib/screens/main/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hideBalance = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = _firebaseService.getUserId();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ================= HEADER =================
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryColor,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        (authProvider.user?['full_name'] ?? 'U')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hi, ${authProvider.user?['full_name'] ?? 'User'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ),

              // ================= BALANCE CARD =================
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _hideBalance
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _hideBalance = !_hideBalance;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 🔥 REAL-TIME BALANCE
                    userId == null
                        ? const Text(
                            '₦ 0.00',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : StreamBuilder(
                            stream: _firebaseService.getUserStream(userId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text(
                                  '₦ 0.00',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }

                              final data = snapshot.data;

                              final balance =
                                  (data?['balance'] ?? 0).toDouble();

                              return Text(
                                _hideBalance
                                    ? '₦ ****'
                                    : '₦ ${balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _actionButton(
                          Icons.add,
                          'Fund',
                          () => context.push('/dashboard/wallet-topup'),
                        ),
                        _actionButton(
                          Icons.send,
                          'Transfer',
                          () => context.push('/dashboard/transfer-funds'),
                        ),
                        _actionButton(
                          Icons.account_balance,
                          'Withdraw',
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Withdraw feature coming soon')),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // ================= VIRTUAL ACCOUNT STATUS =================
              userId == null
                  ? const SizedBox.shrink()
                  : StreamBuilder(
                      stream: _firebaseService.getUserStream(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final userData = snapshot.data;
                        final hasVirtualAccount =
                            userData?['has_virtual_account'] ?? false;
                        final virtualAccountNumber =
                            userData?['virtual_account_number'];

                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasVirtualAccount
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasVirtualAccount
                                  ? Colors.green.shade300
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hasVirtualAccount
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: hasVirtualAccount
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hasVirtualAccount
                                              ? 'Virtual Account Active'
                                              : 'Generate Virtual Account',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: hasVirtualAccount
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hasVirtualAccount
                                              ? 'Account: $virtualAccountNumber'
                                              : 'Create a virtual account to fund your wallet',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (!hasVirtualAccount) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        context.push('/dashboard/wallet-topup'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                    child: const Text(
                                      'Generate Account',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),

              // ================= SERVICES =================
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _serviceItem(
                      Icons.phone_android,
                      'Airtime',
                      () => context.push('/dashboard/buy-airtime'),
                    ),
                    _serviceItem(
                      Icons.wifi,
                      'Data',
                      () => context.push('/dashboard/buy-data'),
                    ),
                    _serviceItem(
                      Icons.lightbulb_outline,
                      'Electricity',
                      () => context.push('/dashboard/utility-payment'),
                    ),
                    _serviceItem(
                      Icons.tv,
                      'Cable',
                      () => context.push('/dashboard/utility-payment'),
                    ),
                    _serviceItem(
                      Icons.receipt,
                      'Bills',
                      () => context.push('/dashboard/utility-payment'),
                    ),
                    _serviceItem(
                      Icons.send,
                      'Transfer',
                      () => context.push('/dashboard/transfer-funds'),
                    ),
                    _serviceItem(
                      Icons.account_balance,
                      'Top-up',
                      () => context.push('/dashboard/wallet-topup'),
                    ),
                    _serviceItem(
                      Icons.more_horiz,
                      'More',
                      () => context.push('/dashboard/services'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= TRANSACTIONS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _transactionItem('Airtime Purchase', '-₦500', Colors.red),
              _transactionItem('Wallet Funding', '+₦2000', Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ACTION BUTTON =================
  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ================= SERVICE ITEM =================
  Widget _serviceItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ================= TRANSACTION =================
  Widget _transactionItem(String title, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(Icons.swap_horiz, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          )
        ],
      ),
    );
  }

  // ================= LOGOUT =================
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.logout();

    if (mounted) {
      context.go('/login');
    }
  }
}
