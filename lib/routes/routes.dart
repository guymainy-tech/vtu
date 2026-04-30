// lib/routes/router.dart
import 'package:go_router/go_router.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/login_screen.dart';
import '../screens/onboarding/register_screen.dart';
import '../screens/onboarding/otp_verification_screen.dart';
import '../screens/onboarding/create_pin_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/main/dashboard_screen.dart';
import '../screens/main/transactions_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/main/services_screen.dart';
import '../screens/main/buy_airtime_screen.dart';
import '../screens/main/buy_data_screen.dart';
import '../screens/main/transfer_funds_screen.dart';
import '../screens/main/utility_payment_screen.dart';
import '../screens/main/wallet_topup_screen.dart';
import '../screens/main/transaction_details_screen.dart';
import '../models/transaction_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OTPScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/create-pin',
        name: 'create-pin',
        builder: (context, state) {
          final data = state.extra as Map<String, String>? ?? {};
          return CreatePinScreen(
            phoneNumber: data['phone'] ?? '',
          );
        },
      ),

      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'services',
                    name: 'services',
                    builder: (context, state) => const ServicesScreen(),
                  ),
                  GoRoute(
                    path: 'buy-airtime',
                    name: 'buy-airtime',
                    builder: (context, state) => const BuyAirtimeScreen(),
                  ),
                  GoRoute(
                    path: 'buy-data',
                    name: 'buy-data',
                    builder: (context, state) => const BuyDataScreen(),
                  ),
                  GoRoute(
                    path: 'transfer-funds',
                    name: 'transfer-funds',
                    builder: (context, state) => const TransferFundsScreen(),
                  ),
                  GoRoute(
                    path: 'utility-payment',
                    name: 'utility-payment',
                    builder: (context, state) => const UtilityPaymentScreen(),
                  ),
                  GoRoute(
                    path: 'wallet-topup',
                    name: 'wallet-topup',
                    builder: (context, state) => const WalletTopupScreen(),
                  ),
                  GoRoute(
                    path: 'transaction-details/:id',
                    name: 'transaction-details',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      // In a real app, you would fetch the transaction here
                      // For now, we're passing it as extra
                      final transaction = state.extra as TransactionModel?;
                      return TransactionDetailsScreen(
                        transaction: transaction ??
                            TransactionModel(
                              id: id,
                              userId: '',
                              type: TransactionType.airtime,
                              status: TransactionStatus.pending,
                              amount: 0,
                              date: DateTime.now(),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Transactions Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                name: 'transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          // Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
