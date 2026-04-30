// lib/screens/main/buy_data_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../bloc/vtu/vtu_bloc.dart';
import '../../bloc/vtu/vtu_event.dart';
import '../../bloc/vtu/vtu_state.dart';
import '../../providers/auth_provider.dart';
import '../../models/network_operator_model.dart';
import '../../models/data_plan_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BuyDataScreen extends StatefulWidget {
  const BuyDataScreen({Key? key}) : super(key: key);

  @override
  State<BuyDataScreen> createState() => _BuyDataScreenState();
}

class _BuyDataScreenState extends State<BuyDataScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  NetworkOperatorModel? _selectedOperator;
  DataPlanModel? _selectedPlan;
  bool _showPin = false;

  late Map<NetworkOperator, List<DataPlanModel>> plansByOperator;

  @override
  void initState() {
    super.initState();
    _initializePlans();

    final authProvider = context.read<AuthProvider>();
    final vtuBloc = context.read<VTUBloc>();

    // Initialize BLoC with userId
    if (authProvider.userId != null) {
      vtuBloc.setUserId(authProvider.userId!);
    }
  }

  void _initializePlans() {
    plansByOperator = {
      NetworkOperator.mtn: DataPlanModel.mtnPlans,
      NetworkOperator.airtel: DataPlanModel.airtelPlans,
      NetworkOperator.glo: DataPlanModel.gloPlans,
      NetworkOperator.nineMobile: DataPlanModel.nineMobilePlans,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Data'),
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
                  // Network Operator Selection
                  const Text(
                    'Select Network',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildOperatorSelection(),
                  const SizedBox(height: 32),

                  // Data Plans
                  if (_selectedOperator != null) ...[
                    const Text(
                      'Select Data Plan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildDataPlans(),
                    const SizedBox(height: 32),
                  ],

                  // Phone Number Input
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter phone number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
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
                    const Center(child: CircularProgressIndicator())
                  else
                    CustomButton(
                      onPressed: _handleBuyData,
                      text:
                          'Buy Data - ₦${_selectedPlan?.price.toStringAsFixed(0) ?? '0'}',
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
            onTap: () {
              setState(() {
                _selectedOperator = operator;
                _selectedPlan = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Colors.green.withOpacity(0.1)
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
                      color: isSelected ? Colors.green : Colors.black,
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

  Widget _buildDataPlans() {
    final plans = _selectedOperator != null
        ? plansByOperator[_selectedOperator!.operator]
        : [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans?.length ?? 0,
      itemBuilder: (context, index) {
        final plan = plans![index];
        final isSelected = _selectedPlan == plan;
        return GestureDetector(
          onTap: () => setState(() => _selectedPlan = plan),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Radio<DataPlanModel>(
                    value: plan,
                    groupValue: _selectedPlan,
                    onChanged: (value) => setState(() => _selectedPlan = value),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${plan.validity} • ${plan.description}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₦${plan.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBuyData() {
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a network operator')),
      );
      return;
    }

    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a data plan')),
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
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
          BuyDataEvent(
            phoneNumber: _phoneController.text,
            plan: _selectedPlan!,
            networkOperator: _selectedOperator!.displayName,
            pin: _pinController.text,
          ),
        );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
