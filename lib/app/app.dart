// lib/app/app.dart
import 'package:flutter/material.dart';
import '../routes/routes.dart';
import 'theme.dart';

class VTUApp extends StatelessWidget {
  final String initialRoute;

  const VTUApp({
    Key? key,
    this.initialRoute = '/splash',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VTU App',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
