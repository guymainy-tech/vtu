// lib/bloc/wallet/wallet_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/wallet_service.dart';
import '../../utils/logger.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletService _walletService = WalletService();

  late String _userId;

  WalletBloc() : super(const WalletInitial()) {
    on<LoadWalletEvent>(_onLoadWallet);
    on<TopUpWalletEvent>(_onTopUpWallet);
    on<WithdrawFromWalletEvent>(_onWithdraw);
    on<RefreshWalletEvent>(_onRefreshWallet);
  }

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<void> _onLoadWallet(
      LoadWalletEvent event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());

    try {
      final wallet = await _walletService.getWallet(event.userId);

      if (wallet != null) {
        emit(WalletLoaded(wallet));
      } else {
        // Create wallet if doesn't exist
        await _walletService.createWallet(event.userId);
        final newWallet = await _walletService.getWallet(event.userId);
        emit(WalletLoaded(newWallet!));
      }
    } catch (e) {
      AppLogger.error('Load wallet error: $e');
      emit(WalletError('Failed to load wallet: ${e.toString()}'));
    }
  }

  Future<void> _onTopUpWallet(
      TopUpWalletEvent event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());

    try {
      // TODO: Call payment gateway API
      // This should be integrated with a payment provider (Paystack, Flutterwave, etc.)

      await _walletService.creditWallet(userId: _userId, amount: event.amount);

      final updatedWallet = await _walletService.getWallet(_userId);

      emit(TopUpSuccess(
        message: 'Wallet topped up successfully',
        newBalance: updatedWallet?.balance ?? 0.0,
      ));
    } catch (e) {
      AppLogger.error('Top up wallet error: $e');
      emit(WalletError('Failed to top up wallet: ${e.toString()}'));
    }
  }

  Future<void> _onWithdraw(
      WithdrawFromWalletEvent event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());

    try {
      final currentBalance = await _walletService.getBalance(_userId);

      if (currentBalance < event.amount) {
        emit(InsufficientBalance(
          message: 'Insufficient balance for withdrawal',
          currentBalance: currentBalance,
        ));
        return;
      }

      final success = await _walletService.withdrawFromWallet(
        userId: _userId,
        amount: event.amount,
        bankAccount: event.bankAccount,
        bankName: event.bankName,
      );

      if (success) {
        final updatedWallet = await _walletService.getWallet(_userId);
        emit(WithdrawalSuccess(
          message: 'Withdrawal initiated successfully',
          newBalance: updatedWallet?.balance ?? 0.0,
        ));
      } else {
        emit(const WalletError('Withdrawal failed'));
      }
    } catch (e) {
      AppLogger.error('Withdraw error: $e');
      emit(WalletError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshWallet(
      RefreshWalletEvent event, Emitter<WalletState> emit) async {
    try {
      final wallet = await _walletService.getWallet(_userId);

      if (wallet != null) {
        emit(WalletLoaded(wallet));
      }
    } catch (e) {
      AppLogger.error('Refresh wallet error: $e');
      emit(WalletError('Failed to refresh wallet: ${e.toString()}'));
    }
  }
}
