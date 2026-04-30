// lib/screens/main/wallet_topup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../bloc/wallet/wallet_bloc.dart';
import '../../bloc/wallet/wallet_event.dart';
import '../../bloc/wallet/wallet_state.dart';
import '../../providers/auth_provider.dart';
import '../../services/monnify_firebase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/logger.dart';
import 'monnify_payment_screen.dart';

class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({Key? key}) : super(key: key);

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final _amountController = TextEditingController();
  final _bvnController = TextEditingController();
  final _ninController = TextEditingController();
  String? _selectedPaymentMethod = 'Monnify Virtual Account';
  bool _isCreatingAccount = false;
  String? _accountCreationError;
  bool _showKycForm = false;

  final List<String> paymentMethods = [
    'Monnify Virtual Account',
  ];

  final MonnifyFirebaseService _monnifyService = MonnifyFirebaseService();
  Map<String, dynamic>? _virtualAccount;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final walletBloc = context.read<WalletBloc>();

    // Initialize BLoC with userId
    if (authProvider.userId != null) {
      walletBloc.setUserId(authProvider.userId!);

      // Check if virtual account already exists
      if (authProvider.user?['has_virtual_account'] == true) {
        setState(() {
          _virtualAccount = {
            'accountNumber': authProvider.user?['virtual_account_number'],
            'accountName': authProvider.user?['virtual_account_name'],
          };
        });
      } else {
        // Show KYC form for BVN/NIN collection
        setState(() => _showKycForm = true);
      }
    }
  }

  Future<void> _createVirtualAccount(AuthProvider authProvider) async {
    // Validate BVN or NIN is provided (CBN KYC requirement)
    if ((_bvnController.text.isEmpty) && (_ninController.text.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Please provide either BVN or NIN (CBN KYC requirement)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isCreatingAccount = true;
      _accountCreationError = null;
    });

    try {
      final user = authProvider.user;
      if (user == null) {
        setState(() {
          _accountCreationError = 'User information not available';
          _isCreatingAccount = false;
        });
        return;
      }

      AppLogger.log(
          '🔄 Starting virtual account creation via Firebase Cloud Functions...');

      // Call Firebase Cloud Function instead of direct Monnify API
      final accountDetails = await _monnifyService.createVirtualAccount(
        firstName: user['full_name']?.split(' ').first ?? 'User',
        lastName: user['full_name']?.split(' ').last ?? 'Account',
        email: user['email'] ?? 'user@example.com',
        phone: user['phone'] ?? '',
        bvn: _bvnController.text.isNotEmpty ? _bvnController.text : null,
        nin: _ninController.text.isNotEmpty ? _ninController.text : null,
      );

      setState(() {
        _virtualAccount = accountDetails;
        _isCreatingAccount = false;
        _showKycForm = false;
      });

      // Save virtual account details to Firestore
      await _updateUserVirtualAccount(authProvider, accountDetails);

      AppLogger.log(
          '✅ Virtual account created successfully via Firebase Cloud Functions');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Virtual account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error creating virtual account: $e');
      setState(() {
        _accountCreationError = e.toString();
        _isCreatingAccount = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserVirtualAccount(
    AuthProvider authProvider,
    Map<String, dynamic> accountDetails,
  ) async {
    try {
      // This would typically be done through your Firebase service
      // For now, we just update the local state
      AppLogger.log('💾 Saving virtual account to Firestore...');
    } catch (e) {
      AppLogger.error('Error saving virtual account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Top-up'),
        centerTitle: true,
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is TopUpSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
            Future.delayed(const Duration(seconds: 2), () => context.pop());
          } else if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================== KYC FORM SECTION (BVN/NIN) ===================
                  if ((_showKycForm ?? false) && _virtualAccount == null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'KYC Verification Required',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'CBN regulation requires BVN or NIN for account creation',
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
                            const SizedBox(height: 16),
                            const Text(
                              'Bank Verification Number (BVN)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _bvnController,
                              label: 'BVN',
                              hint: 'Enter your 11-digit BVN',
                              prefixIcon: Icons.badge,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'OR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'National Identification Number (NIN)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _ninController,
                              label: 'NIN',
                              hint: 'Enter your 11-digit NIN',
                              prefixIcon: Icons.card_membership,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_isCreatingAccount ?? false)
                                    ? null
                                    : () {
                                        final authProvider =
                                            context.read<AuthProvider>();
                                        _createVirtualAccount(authProvider);
                                      },
                                child: (_isCreatingAccount ?? false)
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_isCreatingAccount ?? false)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text(
                              'Creating Virtual Account...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This may take a few moments',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    )
                  else if (_accountCreationError != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error, color: Colors.red[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Account Creation Failed',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _accountCreationError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  final authProvider =
                                      context.read<AuthProvider>();
                                  _createVirtualAccount(authProvider);
                                },
                                child: const Text('Retry Account Creation'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_virtualAccount != null)
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green[700]),
                                const SizedBox(width: 12),
                                const Text(
                                  'Virtual Account Ready',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Account Number: ${_virtualAccount!['accountNumber'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Account Name: ${_virtualAccount!['accountName'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // =================== PAYMENT FORM (Only if account exists) ===================
                  if (_virtualAccount != null) ...[
                    const Text(
                      'Enter Amount',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _amountController,
                      label: 'Amount (₦)',
                      hint: 'How much do you want to top-up?',
                      prefixIcon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Quick Select',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickAmountButtons(),
                    const SizedBox(height: 40),
                    const Text(
                      'Payment Method',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethods(),
                    const SizedBox(height: 40),
                    if (state is WalletLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      CustomButton(
                        onPressed: _handleTopup,
                        text: 'Continue to Payment',
                        isLoading: state is WalletLoading,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('No need funding for now'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Your payment is secure and encrypted',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountButtons() {
    final amounts = [1000.0, 2500.0, 5000.0, 10000.0, 20000.0, 50000.0];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amounts.map((amount) {
        return OutlinedButton(
          onPressed: () => _amountController.text = amount.toStringAsFixed(0),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text('₦${amount.toStringAsFixed(0)}'),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethods() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paymentMethods.length,
      itemBuilder: (context, index) {
        final method = paymentMethods[index];
        final isSelected = _selectedPaymentMethod == method;
        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = method),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Radio<String>(
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) =>
                        setState(() => _selectedPaymentMethod = value),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTopup() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Monnify Virtual Account') {
      if (_virtualAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Virtual account not created. Please try again.')),
        );
        return;
      }

      // Route to Monnify payment screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MonnifyPaymentScreen(
            amount: double.parse(_amountController.text),
            transactionRef: _virtualAccount!['transactionReference'] ??
                'TRX_${DateTime.now().millisecondsSinceEpoch}',
            accountNumber: _virtualAccount!['accountNumber'] ?? '',
            accountName: _virtualAccount!['accountName'] ?? '',
            bankCode: _virtualAccount!['bankCode'] ?? '',
            bankName: _virtualAccount!['bankName'] ?? '',
            onPaymentConfirmed: (verified) {
              if (verified) {
                // Credit wallet after payment verification
                context.read<WalletBloc>().add(
                      TopUpWalletEvent(
                        amount: double.parse(_amountController.text),
                        paymentMethod: 'Monnify Virtual Account',
                      ),
                    );
              }
            },
          ),
        ),
      );
    } else {
      // Handle other payment methods
      context.read<WalletBloc>().add(
            TopUpWalletEvent(
              amount: double.parse(_amountController.text),
              paymentMethod: _selectedPaymentMethod!,
            ),
          );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
