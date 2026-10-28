import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../../superadmin/models/audit_log.dart';
import '../../superadmin/repositories/audit_repository.dart';

/// Repositorio central de autenticación y gestión de sesiones para EDUNEX
class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  UserProfile? _currentProfile;

  /// Registro dinámico de usuarios creados en la sesión (Directores, Tutores, Estudiantes)
  static final Map<String, UserProfile> _registeredUsers = {};

  /// Registra un nuevo perfil de usuario para permitir login inmediato
  void registerUser({
    required String email,
    required String nombres,
    required String apellidos,
    required UserRole rol,
    String? colegioId,
    String? colegioNombre,
    String? telefono,
    String? cedula,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final profile = UserProfile(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      email: cleanEmail,
      nombres: nombres,
      apellidos: apellidos,
      rol: rol,
      colegioNombre: colegioNombre ?? 'Colegio Cliente EDUNEX',
      telefono: telefono,
      cedula: cedula,
    );
    _registeredUsers[cleanEmail] = profile;
  }

  /// Limpia los usuarios registrados en memoria para pruebas de QA
  static void clearAllUsers() {
    _registeredUsers.clear();
  }

  /// Retorna usuarios registrados por rol para pruebas de QA
  static List<UserProfile> getRegisteredUsersByRole(UserRole role) {
    return _registeredUsers.values.where((u) => u.rol == role).toList();
  }

  /// Retorna el perfil en memoria del usuario actual
  UserProfile? get currentProfile => _currentProfile;

  /// Retorna el cliente de Supabase si está disponible
  SupabaseClient? get _supabaseClient {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Inicia sesión con correo electrónico y contraseña
  Future<UserProfile> signInWithPassword({
    required String email,
    required String password,
    UserRole? preferredRole,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final client = _supabaseClient;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        // Autenticación oficial contra Supabase Auth en la base de datos
        final authResponse = await client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );

        final user = authResponse.user;
        if (user == null) {
          throw Exception('No se pudo autenticar el usuario en Supabase.');
        }

        // Obtener el perfil extendido desde la tabla 'perfiles'
        final profileData = await client
            .from('perfiles')
            .select('*, colegios(nombre)')
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null) {
          _currentProfile = UserProfile.fromMap(profileData);

          // Registrar evento de auditoría en la base de datos
          AuditRepository().recordAuditLog(
            AuditLog(
              id: UniqueKey().toString(),
              timestamp: DateTime.now(),
              accion: 'INICIO_SESION',
              descripcion: 'Inicio de sesión exitoso: ${_currentProfile!.email} (${_currentProfile!.nombreCompleto})',
              usuario: _currentProfile!.email,
              rol: _currentProfile!.rol.displayName,
              colegioId: _currentProfile!.colegioId,
              colegioNombre: _currentProfile!.colegioNombre,
              modulo: 'Seguridad',
              nivel: 'SUCCESS',
              estadoAnterior: 'Sesión inactiva',
              nuevoEstado: 'Sesión activa (Rol: ${_currentProfile!.rol.displayName})',
            ),
          );

          return _currentProfile!;
        } else {
          throw Exception(
            'El usuario está autenticado pero no tiene un perfil configurado en la base de datos.',
          );
        }
      } on AuthException catch (e) {
        debugPrint('Error de autenticación en Supabase: ${e.message}');

        // Registrar intento fallido en auditoría
        AuditRepository().recordAuditLog(
          AuditLog(
            id: UniqueKey().toString(),
            timestamp: DateTime.now(),
            accion: 'INTENTO_LOGIN_FALLIDO',
            descripcion: 'Intento fallido de inicio de sesión para $cleanEmail: credenciales inválidas',
            usuario: cleanEmail,
            rol: 'Desconocido',
            modulo: 'Seguridad',
            nivel: 'WARNING',
            estadoAnterior: 'Intento de autenticación',
            nuevoEstado: 'Acceso rechazado por el sistema',
          ),
        );

        throw Exception(
          'Credenciales inválidas o usuario no registrado. Este usuario no existe en la base de datos; debe ser creado previamente por el administrador para poder acceder.',
        );
      } catch (e) {
        debugPrint('Error inesperado durante inicio de sesión: $e');
        rethrow;
      }
    } else {
      // Modo local/offline para pruebas sin conexión
      if (_registeredUsers.containsKey(cleanEmail)) {
        _currentProfile = _registeredUsers[cleanEmail];

        AuditRepository().recordAuditLog(
          AuditLog(
            id: UniqueKey().toString(),
            timestamp: DateTime.now(),
            accion: 'INICIO_SESION',
            descripcion: 'Inicio de sesión exitoso (modo local): ${_currentProfile!.email}',
            usuario: _currentProfile!.email,
            rol: _currentProfile!.rol.displayName,
            colegioId: _currentProfile!.colegioId,
            colegioNombre: _currentProfile!.colegioNombre,
            modulo: 'Seguridad',
            nivel: 'SUCCESS',
            estadoAnterior: 'Sesión inactiva',
            nuevoEstado: 'Sesión activa (Rol: ${_currentProfile!.rol.displayName})',
          ),
        );

        return _currentProfile!;
      }
      throw Exception(
        'Credenciales inválidas o usuario no registrado en el sistema local.',
      );
    }
  }

  /// Cierra la sesión activa
  Future<void> signOut() async {
    if (_currentProfile != null) {
      final userEmail = _currentProfile!.email;
      final userRole = _currentProfile!.rol.displayName;
      final colId = _currentProfile!.colegioId;
      final colName = _currentProfile!.colegioNombre;

      AuditRepository().recordAuditLog(
        AuditLog(
          id: UniqueKey().toString(),
          timestamp: DateTime.now(),
          accion: 'CIERRE_SESION',
          descripcion: 'Cierre de sesión del usuario $userEmail ($userRole)',
          usuario: userEmail,
          rol: userRole,
          colegioId: colId,
          colegioNombre: colName,
          modulo: 'Seguridad',
          nivel: 'INFO',
          estadoAnterior: 'Sesión activa (Rol: $userRole)',
          nuevoEstado: 'Sesión finalizada (Usuario desconectado)',
        ),
      );
    }
    final client = _supabaseClient;
    if (client != null) {
      await client.auth.signOut();
    }
    _currentProfile = null;
  }

  /// Resetea la contraseña de cualquier usuario del sistema (Director, Docente, Tutor) por el SuperAdmin
  Future<void> resetPasswordBySuperAdmin({
    required String email,
    required String newPassword,
    String? colegioId,
    String? colegioNombre,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (SupabaseConfig.isConfigured) {
      try {
        final client = SupabaseConfig.adminClient;
        // Buscar el usuario en la tabla perfiles para obtener su user_id
        final profileData = await client
            .from('perfiles')
            .select('id, nombres, apellidos, rol')
            .eq('email', cleanEmail)
            .maybeSingle();

        if (profileData != null && profileData['id'] != null) {
          final userId = profileData['id'] as String;
          await client.auth.admin.updateUserById(
            userId,
            attributes: AdminUserAttributes(password: newPassword),
          );
        }
      } catch (e) {
        debugPrint('Aviso actualizando contraseña en Supabase Auth: $e');
      }
    }

    // Actualizar registro en memoria/local
    if (_registeredUsers.containsKey(cleanEmail)) {
      final old = _registeredUsers[cleanEmail]!;
      _registeredUsers[cleanEmail] = old;
    }
  }

  /// Traduce los mensajes de error técnicos de Auth a español claro
  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos. Por favor verifica tus credenciales.';
    } else if (message.contains('Email not confirmed')) {
      return 'El correo electrónico aún no ha sido confirmado.';
    } else if (message.contains('User not found')) {
      return 'No existe ningún usuario registrado con este correo.';
    }
    return 'Error al iniciar sesión: $message';
  }
}
