import 'package:flutter/foundation.dart';

/// Configuración central de conexión con Supabase para EDUNEX
class SupabaseConfig {
  /// URL del proyecto Supabase (puede inyectarse con --dart-define=SUPABASE_URL=...)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  /// Clave pública anon de Supabase (puede inyectarse con --dart-define=SUPABASE_ANON_KEY=...)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy',
  );

  /// Verifica si las credenciales actuales corresponden a un proyecto real configurado
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('xyzcompany') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('dummy');
  }

  /// Imprime en consola el estado de la conexión en modo depuración
  static void printStatus() {
    if (kDebugMode) {
      if (isConfigured) {
        debugPrint('🚀 Supabase inicializado con: $supabaseUrl');
      } else {
        debugPrint(
          'ℹ️ Supabase en modo DEMO/LOCAL (Para conectar tu proyecto real, suministra SUPABASE_URL y SUPABASE_ANON_KEY)',
        );
      }
    }
  }
}
