// lib/screens/main/transfer_funds_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../bloc/vtu/vtu_bloc.dart';
import '../../bloc/vtu/vtu_event.dart';
import '../../bloc/vtu/vtu_state.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class TransferFundsScreen extends StatefulWidget {
  const TransferFundsScreen({Key? key}) : super(key: key);

  @override
  State<TransferFundsScreen> createState() => _TransferFundsScreenState();
}

class _TransferFundsScreenState extends State<TransferFundsScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pinController = TextEditingController();

  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final vtuBloc = context.read<VTUBloc>();

    // Initialize BLoC with userId
    if (authProvider.userId != null) {
      vtuBloc.setUserId(authProvider.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Funds'),
        centerTitle: true,
      ),
      body: BlocConsumer<VTUBloc, VTUState>(
        listener: (context, state) {
          if (state is VTUSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
            Future.delayed(const Duration(seconds: 2), () => context.pop());
          } else if (state is VTUError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is InsufficientBalance) {
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
                  const Text(
                    'Recipient Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Recipient phone number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _nameController,
                    label: 'Recipient Name',
                    hint: 'Full name',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Transfer Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _amountController,
                    label: 'Amount (₦)',
                    hint: 'Enter amount',
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    hint: 'What is this transfer for?',
                    prefixIcon: Icons.description,
                  ),
                  const SizedBox(height: 32),

                  // Quick Amount Buttons
                  const Text(
                    'Quick Select',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  _buildQuickAmountButtons(),
                  const SizedBox(height: 32),

                  // PIN Input
                  if (_showPin)
                    Column(
                      children: [
                        CustomTextField(
                          controller: _pinController,
                          label: 'Transaction PIN',
                          hint: 'Enter PIN',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  if (state is VTULoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    CustomButton(
                      onPressed: _handleTransfer,
                      text: 'Transfer Fund',
                      isLoading: state is VTULoading,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountButtons() {
    final amounts = [1000.0, 2500.0, 5000.0, 10000.0];
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

  void _handleTransfer() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient phone number')),
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient name')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    setState(() => _showPin = true);

    if (!_showPin) return;

    if (_pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your PIN')),
      );
      return;
    }

    context.read<VTUBloc>().add(
          TransferFundsEvent(
            recipientPhone: _phoneController.text,
            recipientName: _nameController.text,
            amount: double.parse(_amountController.text),
            pin: _pinController.text,
            description: _descriptionController.text,
          ),
        );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
