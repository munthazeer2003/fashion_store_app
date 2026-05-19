import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
