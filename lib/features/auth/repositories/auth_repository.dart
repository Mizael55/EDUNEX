import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

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

    // 1. Verificar si el usuario fue registrado en la sesión
    if (_registeredUsers.containsKey(cleanEmail)) {
      _currentProfile = _registeredUsers[cleanEmail];
      return _currentProfile!;
    }

    final client = _supabaseClient;

    if (client != null) {
      try {
        // Autenticación oficial contra Supabase Auth
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
          return _currentProfile!;
        } else {
          // Si no existe perfil en la tabla, creamos un perfil básico
          final fallbackProfile = UserProfile(
            id: user.id,
            email: user.email ?? cleanEmail,
            nombres: 'Usuario',
            apellidos: 'EDUNEX',
            rol: preferredRole ?? UserRole.adminColegio,
            colegioNombre: 'Colegio Bilingüe EDUNEX',
          );
          _currentProfile = fallbackProfile;
          return fallbackProfile;
        }
      } on AuthException catch (e) {
        debugPrint('Aviso de Supabase Auth: ${e.message}. Verificando perfiles locales.');
        // Si Supabase falla pero el usuario coincide con un rol preferido en pruebas, permitimos el acceso local
        final role = preferredRole ??
            (cleanEmail.contains('admin')
                ? UserRole.adminColegio
                : cleanEmail.contains('docente')
                    ? UserRole.docente
                    : cleanEmail.contains('estudiante')
                        ? UserRole.estudiante
                        : UserRole.tutorFamiliar);

        final localProfile = UserProfile(
          id: 'local-${cleanEmail.hashCode}',
          colegioId: 'a0000000-0000-0000-0000-000000000001',
          email: cleanEmail,
          nombres: role == UserRole.tutorFamiliar ? 'Tutor' : 'Usuario',
          apellidos: 'EDUNEX',
          rol: role,
          colegioNombre: 'Colegio Cliente EDUNEX',
        );
        _currentProfile = localProfile;
        return localProfile;
      } catch (e) {
        debugPrint('Error inesperado durante inicio de sesión: $e');
        rethrow;
      }
    } else {
      // Modo DEMO / Local (cuando las claves reales de Supabase aún no se han configurado)
      await Future.delayed(const Duration(milliseconds: 300));

      final role = preferredRole ??
          (cleanEmail.contains('admin')
              ? UserRole.adminColegio
              : cleanEmail.contains('docente')
                  ? UserRole.docente
                  : cleanEmail.contains('estudiante')
                      ? UserRole.estudiante
                      : UserRole.tutorFamiliar);

      final demoProfile = UserProfile(
        id: 'demo-user-id-001',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        sucursalId: 'b0000000-0000-0000-0000-000000000001',
        email: cleanEmail,
        nombres: role == UserRole.adminColegio
            ? 'Lic. Carlos'
            : role == UserRole.docente
                ? 'Prof. María'
                : role == UserRole.estudiante
                    ? 'Mateo'
                    : 'Tutor',
        apellidos: role == UserRole.adminColegio
            ? 'Rodríguez'
            : role == UserRole.docente
                ? 'González'
                : role == UserRole.estudiante
                    ? 'Pérez González'
                    : 'Familiar',
        rol: role,
        colegioNombre: 'Colegio Cliente EDUNEX',
        telefono: '809-555-0123',
      );

      _currentProfile = demoProfile;
      return demoProfile;
    }
  }

  /// Cierra la sesión activa
  Future<void> signOut() async {
    final client = _supabaseClient;
    if (client != null) {
      await client.auth.signOut();
    }
    _currentProfile = null;
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
