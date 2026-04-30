// lib/bloc/vtu/vtu_state.dart
import 'package:equatable/equatable.dart';
import '../../models/transaction_model.dart';

abstract class VTUState extends Equatable {
  const VTUState();

  @override
  List<Object?> get props => [];
}

class VTUInitial extends VTUState {
  const VTUInitial();
}

class VTULoading extends VTUState {
  final String message;

  const VTULoading(this.message);

  @override
  List<Object?> get props => [message];
}

class VTUSuccess extends VTUState {
  final String message;
  final TransactionModel? transaction;

  const VTUSuccess(this.message, {this.transaction});

  @override
  List<Object?> get props => [message, transaction];
}

class VTUError extends VTUState {
  final String message;

  const VTUError(this.message);

  @override
  List<Object?> get props => [message];
}

// Transaction loaded state
class TransactionsLoaded extends VTUState {
  final List<TransactionModel> transactions;

  const TransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

// Transaction details state
class TransactionDetailsLoaded extends VTUState {
  final TransactionModel transaction;

  const TransactionDetailsLoaded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

// Insufficient balance
class InsufficientBalance extends VTUState {
  final String message;
  final double currentBalance;
  final double requiredAmount;

  const InsufficientBalance({
    required this.message,
    required this.currentBalance,
    required this.requiredAmount,
  });

  @override
  List<Object?> get props => [message, currentBalance, requiredAmount];
}
