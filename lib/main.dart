import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'theme/app_colors.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase si las credenciales del proyecto están configuradas
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Error al inicializar Supabase: $e');
    }
  }

  SupabaseConfig.printStatus();

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
