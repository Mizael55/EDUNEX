import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Roles del personal interno de la empresa dueña del software SaaS
enum SaaSRole {
  superadmin,
  admin,
  contable,
  secretaria,
  soporte;

  String get displayName {
    switch (this) {
      case SaaSRole.superadmin:
        return 'Superadmin';
      case SaaSRole.admin:
        return 'Administrador SaaS';
      case SaaSRole.contable:
        return 'Contable / Facturación';
      case SaaSRole.secretaria:
        return 'Secretaría / Operaciones';
      case SaaSRole.soporte:
        return 'Soporte Técnico';
    }
  }

  String get description {
    switch (this) {
      case SaaSRole.superadmin:
        return 'Acceso total a la infraestructura, bases de datos y finanzas globales.';
      case SaaSRole.admin:
        return 'Gestión de colegios clientes, activación de licencias y operaciones.';
      case SaaSRole.contable:
        return 'Emisión de facturas con NCF DGII, control de cobros y conciliación bancaria.';
      case SaaSRole.secretaria:
        return 'Atención administrativa, comunicados globales y asistencia a directores.';
      case SaaSRole.soporte:
        return 'Inspección técnica de colegios, diagnóstico de incidencias y auditoría.';
    }
  }

  Color get color {
    switch (this) {
      case SaaSRole.superadmin:
        return const Color(0xFFDC2626); // Rojo fuerte / Seguridad máxima
      case SaaSRole.admin:
        return AppColors.navyPrimary; // Azul marino institucional
      case SaaSRole.contable:
        return const Color(0xFF0284C7); // Azul cielo / Facturación
      case SaaSRole.secretaria:
        return const Color(0xFFD97706); // Ámbar / Operaciones
      case SaaSRole.soporte:
        return const Color(0xFF16A34A); // Verde esmeralda / Técnico
    }
  }

  IconData get icon {
    switch (this) {
      case SaaSRole.superadmin:
        return Icons.security_rounded;
      case SaaSRole.admin:
        return Icons.admin_panel_settings_rounded;
      case SaaSRole.contable:
        return Icons.receipt_long_rounded;
      case SaaSRole.secretaria:
        return Icons.support_agent_rounded;
      case SaaSRole.soporte:
        return Icons.build_circle_rounded;
    }
  }
}

/// Usuario interno que forma parte del equipo del dueño del SaaS
class SaaSUser {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final SaaSRole rol;
  final bool activo;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? notas;

  const SaaSUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    required this.rol,
    this.activo = true,
    required this.createdAt,
    this.lastLogin,
    this.notas,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  String get initials {
    final first = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final second = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$first$second';
  }

  SaaSUser copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    SaaSRole? rol,
    bool? activo,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? notas,
  }) {
    return SaaSUser(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      notas: notas ?? this.notas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'rol': rol.name,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'notas': notas,
    };
  }

  factory SaaSUser.fromJson(Map<String, dynamic> json) {
    return SaaSUser(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefono: json['telefono'] as String?,
      rol: SaaSRole.values.firstWhere(
        (r) => r.name == json['rol'],
        orElse: () => SaaSRole.admin,
      ),
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'] as String)
          : null,
      notas: json['notas'] as String?,
    );
  }
}
