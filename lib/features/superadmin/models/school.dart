import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Modelo de Colegio / Institución Educativa en EDUNEX para el Dueño del SaaS
class School {
  final String id;
  final String nombre;
  final String? rnc;
  final String? siglas;
  final String? telefono;
  final String? emailContacto;
  final String? direccion;
  final String? logoUrl;
  final String estadoSuscripcion; // 'active', 'trial', 'past_due', 'suspended'
  final int maxEstudiantes;
  final DateTime? createdAt;
  final int totalEstudiantes;
  final int totalFamilias;

  const School({
    required this.id,
    required this.nombre,
    this.rnc,
    this.siglas,
    this.telefono,
    this.emailContacto,
    this.direccion,
    this.logoUrl,
    required this.estadoSuscripcion,
    this.maxEstudiantes = 500,
    this.createdAt,
    this.totalEstudiantes = 0,
    this.totalFamilias = 0,
  });

  bool get isActive => estadoSuscripcion == 'active';
  bool get isTrial => estadoSuscripcion == 'trial';
  bool get isSuspended => estadoSuscripcion == 'suspended';

  String get statusDisplayName {
    switch (estadoSuscripcion) {
      case 'active':
        return 'Suscripción Activa';
      case 'trial':
        return 'Período de Prueba';
      case 'past_due':
        return 'Pago Pendiente';
      case 'suspended':
        return 'Servicio Suspendido';
      default:
        return 'Desconocido';
    }
  }

  Color get statusColor {
    switch (estadoSuscripcion) {
      case 'active':
        return AppColors.accentGreen;
      case 'trial':
        return AppColors.electricBlue;
      case 'past_due':
        return AppColors.amberAccent;
      case 'suspended':
        return Colors.red.shade700;
      default:
        return AppColors.textSecondary;
    }
  }

  String get planName {
    if (maxEstudiantes <= 250) return 'Plan Básico (Hasta 250 alumnos)';
    if (maxEstudiantes <= 500) return 'Plan Profesional (Hasta 500 alumnos)';
    return 'Plan Enterprise (Hasta $maxEstudiantes alumnos)';
  }

  factory School.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    return School(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      rnc: json['rnc']?.toString(),
      siglas: json['siglas']?.toString(),
      telefono: json['telefono']?.toString(),
      emailContacto: json['email_contacto']?.toString(),
      direccion: json['direccion']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      estadoSuscripcion: json['estado_suscripcion']?.toString() ?? 'trial',
      maxEstudiantes: json['max_estudiantes'] is int
          ? json['max_estudiantes'] as int
          : int.tryParse(json['max_estudiantes']?.toString() ?? '500') ?? 500,
      createdAt: parsedCreatedAt,
      totalEstudiantes: json['total_estudiantes'] is int
          ? json['total_estudiantes'] as int
          : int.tryParse(json['total_estudiantes']?.toString() ?? '0') ?? 0,
      totalFamilias: json['total_familias'] is int
          ? json['total_familias'] as int
          : int.tryParse(json['total_familias']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'rnc': rnc,
      'siglas': siglas,
      'telefono': telefono,
      'email_contacto': emailContacto,
      'direccion': direccion,
      'logo_url': logoUrl,
      'estado_suscripcion': estadoSuscripcion,
      'max_estudiantes': maxEstudiantes,
    };
  }
}
