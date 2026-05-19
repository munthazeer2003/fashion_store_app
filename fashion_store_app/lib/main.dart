import 'package:flutter/material.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';

void main() {
  runApp(const MFashionApp());
}

class MFashionApp extends StatelessWidget {
  const MFashionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MFashion - by Munthazeer',
      theme: AppTheme.lightTheme,

      // Start flow
      initialRoute: AppRoutes.onboarding,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}