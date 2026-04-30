// lib/bloc/wallet/wallet_state.dart
import 'package:equatable/equatable.dart';
import '../../models/wallet_model.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final WalletModel wallet;

  const WalletLoaded(this.wallet);

  @override
  List<Object?> get props => [wallet];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}

class TopUpSuccess extends WalletState {
  final String message;
  final double newBalance;

  const TopUpSuccess({required this.message, required this.newBalance});

  @override
  List<Object?> get props => [message, newBalance];
}

class WithdrawalSuccess extends WalletState {
  final String message;
  final double newBalance;

  const WithdrawalSuccess({required this.message, required this.newBalance});

  @override
  List<Object?> get props => [message, newBalance];
}

class InsufficientBalance extends WalletState {
  final String message;
  final double currentBalance;

  const InsufficientBalance({
    required this.message,
    required this.currentBalance,
  });

  @override
  List<Object?> get props => [message, currentBalance];
}
