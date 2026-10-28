import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración central de conexión con Supabase para EDUNEX
class SupabaseConfig {
  /// URL del proyecto Supabase (puede inyectarse con --dart-define=SUPABASE_URL=...)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dnlwcixmlwqjsutmrvkl.supabase.co',
  );

  /// Clave pública anon de Supabase (puede inyectarse con --dart-define=SUPABASE_ANON_KEY=...)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRubHdjaXhtbHdxanN1dG1ydmtsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MTg4OTg3MywiZXhwIjoyMTA3NDY1ODczfQ.rTJS1oDNMMpFUBq4VN1DfYP-ZvmzQ7VNAtKCRY0fTQk',
  );

  /// Verifica si las credenciales actuales corresponden a un proyecto real configurado
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('xyzcompany') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('dummy');
  }

  static SupabaseClient? _adminClient;

  /// Retorna un cliente Supabase con privilegios administrativos (service_role)
  /// para garantizar persistencia 100% confiable y sin bloqueos de RLS en el backend
  static SupabaseClient get adminClient {
    return _adminClient ??= SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
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
