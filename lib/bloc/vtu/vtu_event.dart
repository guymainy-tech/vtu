// lib/bloc/vtu/vtu_event.dart
import 'package:equatable/equatable.dart';
import '../../models/data_plan_model.dart';

abstract class VTUEvent extends Equatable {
  const VTUEvent();

  @override
  List<Object?> get props => [];
}

// Airtime Events
class BuyAirtimeEvent extends VTUEvent {
  final String phoneNumber;
  final double amount;
  final String networkOperator;
  final String pin;

  const BuyAirtimeEvent({
    required this.phoneNumber,
    required this.amount,
    required this.networkOperator,
    required this.pin,
  });

  @override
  List<Object?> get props => [phoneNumber, amount, networkOperator, pin];
}

// Data Events
class BuyDataEvent extends VTUEvent {
  final String phoneNumber;
  final DataPlanModel plan;
  final String networkOperator;
  final String pin;

  const BuyDataEvent({
    required this.phoneNumber,
    required this.plan,
    required this.networkOperator,
    required this.pin,
  });

  @override
  List<Object?> get props => [phoneNumber, plan, networkOperator, pin];
}

// Transfer Events
class TransferFundsEvent extends VTUEvent {
  final String recipientPhone;
  final String recipientName;
  final double amount;
  final String pin;
  final String? description;

  const TransferFundsEvent({
    required this.recipientPhone,
    required this.recipientName,
    required this.amount,
    required this.pin,
    this.description,
  });

  @override
  List<Object?> get props =>
      [recipientPhone, recipientName, amount, pin, description];
}

// Utility Payment Events
class PayUtilityEvent extends VTUEvent {
  final String serviceType;
  final String serviceProvider;
  final double amount;
  final String customerReference;
  final String pin;

  const PayUtilityEvent({
    required this.serviceType,
    required this.serviceProvider,
    required this.amount,
    required this.customerReference,
    required this.pin,
  });

  @override
  List<Object?> get props =>
      [serviceType, serviceProvider, amount, customerReference, pin];
}

// Load Transactions Event
class LoadTransactionsEvent extends VTUEvent {
  const LoadTransactionsEvent();

  @override
  List<Object?> get props => [];
}

// Get Transaction Details Event
class GetTransactionDetailsEvent extends VTUEvent {
  final String transactionId;

  const GetTransactionDetailsEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
