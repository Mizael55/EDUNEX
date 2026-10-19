import 'user_role.dart';

/// Modelo de datos que representa el perfil del usuario autenticado en EDUNEX
class UserProfile {
  final String id;
  final String? colegioId;
  final String? sucursalId;
  final String email;
  final String nombres;
  final String apellidos;
  final String? telefono;
  final String? cedula;
  final UserRole rol;
  final String? avatarUrl;
  final bool activo;
  final String? colegioNombre;

  const UserProfile({
    required this.id,
    this.colegioId,
    this.sucursalId,
    required this.email,
    required this.nombres,
    required this.apellidos,
    this.telefono,
    this.cedula,
    this.rol = UserRole.tutorFamiliar,
    this.avatarUrl,
    this.activo = true,
    this.colegioNombre,
  });

  /// Nombre completo formateado del usuario
  String get nombreCompleto => '$nombres $apellidos'.trim();

  /// Iniciales del usuario para mostrar en avatares
  String get iniciales {
    final n = nombres.isNotEmpty ? nombres[0].toUpperCase() : '';
    final a = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$n$a';
  }

  /// Construye un UserProfile a partir de un Map retornado por Supabase
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      colegioId: map['colegio_id'] as String?,
      sucursalId: map['sucursal_id'] as String?,
      email: (map['email'] as String?) ?? '',
      nombres: (map['nombres'] as String?) ?? 'Usuario',
      apellidos: (map['apellidos'] as String?) ?? 'EDUNEX',
      telefono: map['telefono'] as String?,
      cedula: map['cedula'] as String?,
      rol: UserRole.fromString(map['rol'] as String?),
      avatarUrl: map['avatar_url'] as String?,
      activo: (map['activo'] as bool?) ?? true,
      colegioNombre: map['colegios'] != null
          ? (map['colegios']['nombre'] as String?)
          : null,
    );
  }

  /// Convierte el perfil a Map para inserciones o actualizaciones en Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (colegioId != null) 'colegio_id': colegioId,
      if (sucursalId != null) 'sucursal_id': sucursalId,
      'email': email,
      'nombres': nombres,
      'apellidos': apellidos,
      if (telefono != null) 'telefono': telefono,
      if (cedula != null) 'cedula': cedula,
      'rol': rol.toDbString(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'activo': activo,
    };
  }

  /// Crea una copia del perfil con campos modificados
  UserProfile copyWith({
    String? id,
    String? colegioId,
    String? sucursalId,
    String? email,
    String? nombres,
    String? apellidos,
    String? telefono,
    String? cedula,
    UserRole? rol,
    String? avatarUrl,
    bool? activo,
    String? colegioNombre,
  }) {
    return UserProfile(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      sucursalId: sucursalId ?? this.sucursalId,
      email: email ?? this.email,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      cedula: cedula ?? this.cedula,
      rol: rol ?? this.rol,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      activo: activo ?? this.activo,
      colegioNombre: colegioNombre ?? this.colegioNombre,
    );
  }
}
