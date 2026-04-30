import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'firebase_options.dart';
import 'app/app.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_service.dart';
import 'services/monnify_http_service.dart';
import 'bloc/vtu/vtu_bloc.dart';
import 'bloc/wallet/wallet_bloc.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Initialize Firebase (Web + Mobile)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    AppLogger.log('Firebase initialized successfully');

    // ✅ Initialize Monnify HTTP Service (Render backend)
    MonnifyHttpService().init(
      backendUrl: 'https://vtu-412l.onrender.com',
    );

    // ✅ Setup Firebase service (singleton)
    FirebaseService().setup();

    // ✅ Initialize storage
    const secureStorage = FlutterSecureStorage();

    final token = await secureStorage.read(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(),
          ),
          BlocProvider<VTUBloc>(
            create: (_) => VTUBloc(),
          ),
          BlocProvider<WalletBloc>(
            create: (_) => WalletBloc(),
          ),
        ],
        child: VTUApp(
          initialRoute: _getInitialRoute(isFirstLaunch, token),
        ),
      ),
    );
  } catch (e) {
    AppLogger.error('Initialization error: $e');
    rethrow;
  }
}

String _getInitialRoute(bool isFirstLaunch, String? token) {
  if (isFirstLaunch) return '/onboarding';
  if (token != null && token.isNotEmpty) return '/dashboard';
  return '/login';
}
