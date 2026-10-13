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
    final client = _supabaseClient;

    if (client != null) {
      try {
        // Autenticación oficial contra Supabase Auth
        final authResponse = await client.auth.signInWithPassword(
          email: email.trim(),
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
            email: user.email ?? email,
            nombres: 'Usuario',
            apellidos: 'EDUNEX',
            rol: preferredRole ?? UserRole.adminColegio,
            colegioNombre: 'Colegio Bilingüe EDUNEX',
          );
          _currentProfile = fallbackProfile;
          return fallbackProfile;
        }
      } on AuthException catch (e) {
        debugPrint('Error de Supabase Auth: ${e.message}');
        throw Exception(_mapAuthError(e.message));
      } catch (e) {
        debugPrint('Error inesperado durante inicio de sesión: $e');
        rethrow;
      }
    } else {
      // Modo DEMO / Local (cuando las claves reales de Supabase aún no se han configurado)
      await Future.delayed(const Duration(milliseconds: 800));

      final role = preferredRole ??
          (email.contains('admin')
              ? UserRole.adminColegio
              : email.contains('docente')
                  ? UserRole.docente
                  : UserRole.tutorFamiliar);

      final demoProfile = UserProfile(
        id: 'demo-user-id-001',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        sucursalId: 'b0000000-0000-0000-0000-000000000001',
        email: email,
        nombres: role == UserRole.adminColegio
            ? 'Lic. Carlos'
            : role == UserRole.docente
                ? 'Prof. María'
                : 'Ing. Roberto',
        apellidos: role == UserRole.adminColegio
            ? 'Rodríguez'
            : role == UserRole.docente
                ? 'González'
                : 'Pérez (Familia Pérez)',
        rol: role,
        colegioNombre: 'Colegio Bilingüe EDUNEX Piloto',
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
