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
  // Caso 2: Tarifario Escolar & Criterio Sujeto a Mejora de Pago
  final double precioInicial;
  final double precioPrimaria;
  final double precioSecundaria;
  final double precioMatricula;
  final bool sujetoAMejoraPago;
  final double descuentoProntoPagoAnualPct;
  final double descuentoProntoPagoSemestralPct;
  final double descuentoProntoPagoTrimestralPct;
  final double descuentoHermanosPct;
  // Issue #18: Datos del Director / Responsable del Colegio
  final String? directorNombre;
  final String? directorEmail;
  final String? directorCedula;
  final String? directorTelefono;

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
    this.precioInicial = 6500.0,
    this.precioPrimaria = 8000.0,
    this.precioSecundaria = 9500.0,
    this.precioMatricula = 12000.0,
    this.sujetoAMejoraPago = true,
    this.descuentoProntoPagoAnualPct = 10.0,
    this.descuentoProntoPagoSemestralPct = 5.0,
    this.descuentoProntoPagoTrimestralPct = 3.0,
    this.descuentoHermanosPct = 10.0,
    this.directorNombre,
    this.directorEmail,
    this.directorCedula,
    this.directorTelefono,
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

    double parseDouble(dynamic v, double defaultVal) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? defaultVal;
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
      precioInicial: parseDouble(json['precio_inicial'], 6500.0),
      precioPrimaria: parseDouble(json['precio_primaria'], 8000.0),
      precioSecundaria: parseDouble(json['precio_secundaria'], 9500.0),
      precioMatricula: parseDouble(json['precio_matricula'], 12000.0),
      sujetoAMejoraPago: json['sujeto_a_mejora_pago'] as bool? ?? true,
      descuentoProntoPagoAnualPct: parseDouble(json['descuento_anual_pct'], 10.0),
      descuentoProntoPagoSemestralPct: parseDouble(json['descuento_semestral_pct'], 5.0),
      descuentoProntoPagoTrimestralPct: parseDouble(json['descuento_trimestral_pct'], 3.0),
      descuentoHermanosPct: parseDouble(json['descuento_hermanos_pct'], 10.0),
      directorNombre: json['director_nombre']?.toString(),
      directorEmail: json['director_email']?.toString(),
      directorCedula: json['director_cedula']?.toString(),
      directorTelefono: json['director_telefono']?.toString(),
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
      'precio_inicial': precioInicial,
      'precio_primaria': precioPrimaria,
      'precio_secundaria': precioSecundaria,
      'precio_matricula': precioMatricula,
      'sujeto_a_mejora_pago': sujetoAMejoraPago,
      'descuento_anual_pct': descuentoProntoPagoAnualPct,
      'descuento_semestral_pct': descuentoProntoPagoSemestralPct,
      'descuento_trimestral_pct': descuentoProntoPagoTrimestralPct,
      'descuento_hermanos_pct': descuentoHermanosPct,
      'director_nombre': directorNombre,
      'director_email': directorEmail,
      'director_cedula': directorCedula,
      'director_telefono': directorTelefono,
    };
  }
}
