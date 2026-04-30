// lib/screens/main/utility_payment_screen.dart
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

class UtilityPaymentScreen extends StatefulWidget {
  const UtilityPaymentScreen({Key? key}) : super(key: key);

  @override
  State<UtilityPaymentScreen> createState() => _UtilityPaymentScreenState();
}

class _UtilityPaymentScreenState extends State<UtilityPaymentScreen> {
  final _customerRefController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  String? _selectedServiceType;
  String? _selectedProvider;
  bool _showPin = false;

  final List<String> serviceTypes = [
    'Electricity',
    'Water',
    'Internet',
    'Gas',
    'Cable TV',
  ];

  final Map<String, List<String>> providers = {
    'Electricity': ['EKEDC', 'IKEDC', 'PHCN', 'KEDCO'],
    'Water': ['Lagos Water', 'Rivers Water', 'Kaduna Water'],
    'Internet': ['Spectranet', 'Smile', 'Starcomms'],
    'Gas': ['Autogas', 'Total Gas'],
    'Cable TV': ['DSTV', 'GOtv', 'Startimes'],
  };

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
        title: const Text('Utility Payments'),
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
                    'Select Service Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Choose service...'),
                    value: _selectedServiceType,
                    items: serviceTypes.map((service) {
                      return DropdownMenuItem(
                        value: service,
                        child: Text(service),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceType = value;
                        _selectedProvider = null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_selectedServiceType != null) ...[
                    const Text(
                      'Select Provider',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Choose provider...'),
                      value: _selectedProvider,
                      items: providers[_selectedServiceType]?.map((provider) {
                            return DropdownMenuItem(
                              value: provider,
                              child: Text(provider),
                            );
                          }).toList() ??
                          [],
                      onChanged: (value) {
                        setState(() => _selectedProvider = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _customerRefController,
                      label: 'Customer Reference',
                      hint: 'Account number or meter number',
                      prefixIcon: Icons.badge,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _amountController,
                      label: 'Amount (₦)',
                      hint: 'Enter amount',
                      prefixIcon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
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
                        onPressed: _handlePayment,
                        text: 'Make Payment',
                        isLoading: state is VTULoading,
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

  void _handlePayment() {
    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }

    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a provider')),
      );
      return;
    }

    if (_customerRefController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer reference')),
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
          PayUtilityEvent(
            serviceType: _selectedServiceType!,
            serviceProvider: _selectedProvider!,
            amount: double.parse(_amountController.text),
            customerReference: _customerRefController.text,
            pin: _pinController.text,
          ),
        );
  }

  @override
  void dispose() {
    _customerRefController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
