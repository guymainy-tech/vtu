// lib/screens/main/buy_airtime_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../bloc/vtu/vtu_bloc.dart';
import '../../bloc/vtu/vtu_event.dart';
import '../../bloc/vtu/vtu_state.dart';
import '../../providers/auth_provider.dart';
import '../../models/network_operator_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BuyAirtimeScreen extends StatefulWidget {
  const BuyAirtimeScreen({Key? key}) : super(key: key);

  @override
  State<BuyAirtimeScreen> createState() => _BuyAirtimeScreenState();
}

class _BuyAirtimeScreenState extends State<BuyAirtimeScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  NetworkOperatorModel? _selectedOperator;
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
        title: const Text('Buy Airtime'),
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
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
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
                  // Network Operator Selection
                  const Text(
                    'Select Network',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildOperatorSelection(),
                  const SizedBox(height: 32),

                  // Phone Number Input
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter phone number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // Amount Input
                  CustomTextField(
                    controller: _amountController,
                    label: 'Amount (₦)',
                    hint: 'Enter amount',
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  // Quick Amount Selection
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

                  // Buy Button
                  if (state is VTULoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    CustomButton(
                      onPressed: _handleBuyAirtime,
                      text: 'Buy Airtime',
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

  Widget _buildOperatorSelection() {
    final operators = NetworkOperatorModel.getAll();
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: operators.length,
        itemBuilder: (context, index) {
          final operator = operators[index];
          final isSelected = _selectedOperator == operator;
          return GestureDetector(
            onTap: () => setState(() => _selectedOperator = operator),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    operator.displayName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
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
    final amounts = [100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0];
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

  void _handleBuyAirtime() {
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a network operator')),
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
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
          BuyAirtimeEvent(
            phoneNumber: _phoneController.text,
            amount: double.parse(_amountController.text),
            networkOperator: _selectedOperator!.displayName,
            pin: _pinController.text,
          ),
        );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
