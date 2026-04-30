// lib/bloc/wallet/wallet_event.dart
import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadWalletEvent extends WalletEvent {
  final String userId;

  const LoadWalletEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class TopUpWalletEvent extends WalletEvent {
  final double amount;
  final String paymentMethod; // card, bank_transfer, etc.

  const TopUpWalletEvent({
    required this.amount,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [amount, paymentMethod];
}

class WithdrawFromWalletEvent extends WalletEvent {
  final double amount;
  final String bankAccount;
  final String bankName;

  const WithdrawFromWalletEvent({
    required this.amount,
    required this.bankAccount,
    required this.bankName,
  });

  @override
  List<Object?> get props => [amount, bankAccount, bankName];
}

class RefreshWalletEvent extends WalletEvent {
  const RefreshWalletEvent();

  @override
  List<Object?> get props => [];
}
