// lib/bloc/vtu/vtu_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/vtu_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/logger.dart';
import 'vtu_event.dart';
import 'vtu_state.dart';

class VTUBloc extends Bloc<VTUEvent, VTUState> {
  final VTUService _vtuService = VTUService();
  final WalletService _walletService = WalletService();

  late String _userId;

  VTUBloc() : super(const VTUInitial()) {
    on<BuyAirtimeEvent>(_onBuyAirtime);
    on<BuyDataEvent>(_onBuyData);
    on<TransferFundsEvent>(_onTransferFunds);
    on<PayUtilityEvent>(_onPayUtility);
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<GetTransactionDetailsEvent>(_onGetTransactionDetails);
  }

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<void> _onBuyAirtime(
      BuyAirtimeEvent event, Emitter<VTUState> emit) async {
    emit(const VTULoading('Processing airtime purchase...'));

    try {
      // Check balance
      final balance = await _walletService.getBalance(_userId);
      if (balance < event.amount) {
        emit(InsufficientBalance(
          message: 'Insufficient balance for airtime purchase',
          currentBalance: balance,
          requiredAmount: event.amount,
        ));
        return;
      }

      // Debit wallet
      final debited = await _walletService.debitWallet(
        userId: _userId,
        amount: event.amount,
      );

      if (!debited) {
        emit(const VTUError('Failed to debit wallet'));
        return;
      }

      // Buy airtime
      final success = await _vtuService.buyAirtime(
        userId: _userId,
        phoneNumber: event.phoneNumber,
        amount: event.amount,
        networkOperator: event.networkOperator,
        pin: event.pin,
      );

      if (success) {
        emit(const VTUSuccess('Airtime purchased successfully'));
      } else {
        // Refund if purchase fails
        await _walletService.creditWallet(
            userId: _userId, amount: event.amount);
        emit(const VTUError('Airtime purchase failed. Balance refunded.'));
      }
    } catch (e) {
      AppLogger.error('Buy airtime error: $e');
      emit(VTUError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onBuyData(BuyDataEvent event, Emitter<VTUState> emit) async {
    emit(const VTULoading('Processing data purchase...'));

    try {
      final balance = await _walletService.getBalance(_userId);
      if (balance < event.plan.price) {
        emit(InsufficientBalance(
          message: 'Insufficient balance for data purchase',
          currentBalance: balance,
          requiredAmount: event.plan.price,
        ));
        return;
      }

      final debited = await _walletService.debitWallet(
        userId: _userId,
        amount: event.plan.price,
      );

      if (!debited) {
        emit(const VTUError('Failed to debit wallet'));
        return;
      }

      final success = await _vtuService.buyData(
        userId: _userId,
        phoneNumber: event.phoneNumber,
        plan: event.plan,
        networkOperator: event.networkOperator,
        pin: event.pin,
      );

      if (success) {
        emit(const VTUSuccess('Data purchased successfully'));
      } else {
        await _walletService.creditWallet(
            userId: _userId, amount: event.plan.price);
        emit(const VTUError('Data purchase failed. Balance refunded.'));
      }
    } catch (e) {
      AppLogger.error('Buy data error: $e');
      emit(VTUError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onTransferFunds(
      TransferFundsEvent event, Emitter<VTUState> emit) async {
    emit(const VTULoading('Processing fund transfer...'));

    try {
      final balance = await _walletService.getBalance(_userId);
      if (balance < event.amount) {
        emit(InsufficientBalance(
          message: 'Insufficient balance for transfer',
          currentBalance: balance,
          requiredAmount: event.amount,
        ));
        return;
      }

      final debited = await _walletService.debitWallet(
        userId: _userId,
        amount: event.amount,
      );

      if (!debited) {
        emit(const VTUError('Failed to debit wallet'));
        return;
      }

      final success = await _vtuService.transferFund(
        userId: _userId,
        recipientPhone: event.recipientPhone,
        recipientName: event.recipientName,
        amount: event.amount,
        pin: event.pin,
        description: event.description,
      );

      if (success) {
        emit(const VTUSuccess('Fund transferred successfully'));
      } else {
        await _walletService.creditWallet(
            userId: _userId, amount: event.amount);
        emit(const VTUError('Transfer failed. Balance refunded.'));
      }
    } catch (e) {
      AppLogger.error('Transfer funds error: $e');
      emit(VTUError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onPayUtility(
      PayUtilityEvent event, Emitter<VTUState> emit) async {
    emit(const VTULoading('Processing utility payment...'));

    try {
      final balance = await _walletService.getBalance(_userId);
      if (balance < event.amount) {
        emit(InsufficientBalance(
          message: 'Insufficient balance for payment',
          currentBalance: balance,
          requiredAmount: event.amount,
        ));
        return;
      }

      final debited = await _walletService.debitWallet(
        userId: _userId,
        amount: event.amount,
      );

      if (!debited) {
        emit(const VTUError('Failed to debit wallet'));
        return;
      }

      final success = await _vtuService.payUtility(
        userId: _userId,
        serviceType: event.serviceType,
        serviceProvider: event.serviceProvider,
        amount: event.amount,
        customerReference: event.customerReference,
        pin: event.pin,
      );

      if (success) {
        emit(const VTUSuccess('Payment successful'));
      } else {
        await _walletService.creditWallet(
            userId: _userId, amount: event.amount);
        emit(const VTUError('Payment failed. Balance refunded.'));
      }
    } catch (e) {
      AppLogger.error('Pay utility error: $e');
      emit(VTUError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTransactions(
      LoadTransactionsEvent event, Emitter<VTUState> emit) async {
    emit(const VTULoading('Loading transactions...'));

    try {
      final transactions = await _vtuService.getUserTransactions(_userId);
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      AppLogger.error('Load transactions error: $e');
      emit(VTUError('Error loading transactions: ${e.toString()}'));
    }
  }

  Future<void> _onGetTransactionDetails(
    GetTransactionDetailsEvent event,
    Emitter<VTUState> emit,
  ) async {
    try {
      final transaction =
          await _vtuService.getTransactionDetails(event.transactionId);
      if (transaction != null) {
        emit(TransactionDetailsLoaded(transaction));
      } else {
        emit(const VTUError('Transaction not found'));
      }
    } catch (e) {
      AppLogger.error('Get transaction details error: $e');
      emit(VTUError('Error: ${e.toString()}'));
    }
  }
}
