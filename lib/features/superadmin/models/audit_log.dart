import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Modelo de Registro de Auditoría para Trazabilidad y Seguridad SaaS
class AuditLog {
  final String id;
  final DateTime timestamp;
  final String accion;
  final String descripcion;
  final String usuario;
  final String rol;
  final String? colegioId;
  final String? colegioNombre;
  final String modulo;
  final String nivel; // 'INFO', 'WARNING', 'CRITICAL', 'SUCCESS'
  final String? ipAddress;
  final String? estadoAnterior;
  final String? nuevoEstado;

  const AuditLog({
    required this.id,
    required this.timestamp,
    required this.accion,
    required this.descripcion,
    required this.usuario,
    required this.rol,
    this.colegioId,
    this.colegioNombre,
    required this.modulo,
    this.nivel = 'INFO',
    this.ipAddress,
    this.estadoAnterior,
    this.nuevoEstado,
  });

  Color get nivelColor {
    switch (nivel.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'WARNING':
        return const Color(0xFFD97706);
      case 'SUCCESS':
        return const Color(0xFF16A34A);
      default:
        return AppColors.navyPrimary;
    }
  }

  IconData get icon {
    switch (modulo.toLowerCase()) {
      case 'seguridad':
      case 'autenticación':
        return Icons.security_rounded;
      case 'saas / superadmin':
        return Icons.hub_rounded;
      case 'finanzas':
        return Icons.account_balance_wallet_rounded;
      case 'académico':
        return Icons.school_rounded;
      case 'institucional':
        return Icons.domain_rounded;
      default:
        return Icons.fact_check_rounded;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'accion': accion,
    'descripcion': descripcion,
    'usuario': usuario,
    'rol': rol,
    'colegio_id': colegioId,
    'colegio_nombre': colegioNombre,
    'modulo': modulo,
    'nivel': nivel,
    'ip_address': ipAddress,
    if (estadoAnterior != null) 'estado_anterior': estadoAnterior,
    if (nuevoEstado != null) 'nuevo_estado': nuevoEstado,
  };

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String? ?? UniqueKey().toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      accion: json['accion'] as String? ?? 'OPERACION',
      descripcion: json['descripcion'] as String? ?? '',
      usuario: json['usuario'] as String? ?? 'Sistema',
      rol: json['rol'] as String? ?? 'SuperAdmin',
      colegioId: json['colegio_id'] as String?,
      colegioNombre: json['colegio_nombre'] as String?,
      modulo: json['modulo'] as String? ?? 'Sistema',
      nivel: json['nivel'] as String? ?? 'INFO',
      ipAddress: json['ip_address'] as String?,
      estadoAnterior: json['estado_anterior'] as String?,
      nuevoEstado: json['nuevo_estado'] as String?,
    );
  }
}
