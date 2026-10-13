import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EdunexApp());
}

class EdunexApp extends StatelessWidget {
  const EdunexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDUNEX - CRM Escolar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navyPrimary,
          primary: AppColors.navyPrimary,
          secondary: AppColors.electricBlue,
          tertiary: AppColors.accentGreen,
          surface: AppColors.surfaceWhite,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
      ),
      home: const LoginScreen(),
    );
  }
}
