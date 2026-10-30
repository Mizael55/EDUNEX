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
  // Issue #22 & #23: Sucursales, Tarificación SaaS y Método de Pago
  final int sucursalesCount;
  final String? metodoPago;
  final bool metodoPagoRegistrado;
  // Facturación SaaS y Control de Periodo de Prueba (Trial)
  final int diaCorte;
  final DateTime? trialFin;

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
    this.sucursalesCount = 0,
    this.metodoPago,
    this.metodoPagoRegistrado = false,
    this.diaCorte = 1,
    this.trialFin,
  });

  /// Determina si la institución está en periodo de prueba
  bool get isTrial => estadoSuscripcion == 'trial';

  /// Retorna los días restantes de prueba (por defecto 15 días tras registro)
  int get trialDiasRestantes {
    if (!isTrial) return 0;
    final end = trialFin ?? (createdAt?.add(const Duration(days: 15)) ?? DateTime.now().add(const Duration(days: 15)));
    final diff = end.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Cuota mensual SaaS según rango de alumnos y sucursales (Issue #22)
  /// - 100 a 250 alumnos: RD$ 4,000 / mes
  /// - 251 a 400 alumnos: RD$ 5,500 / mes
  /// - 450 en adelante: RD$ 7,000 / mes
  /// - +15% de costo adicional por cada sucursal extra
  double get cuotaMensualSaaS {
    double base;
    if (maxEstudiantes <= 250) {
      base = 4000.0;
    } else if (maxEstudiantes <= 400) {
      base = 5500.0;
    } else {
      base = 7000.0;
    }
    if (sucursalesCount > 0) {
      base += base * 0.15 * sucursalesCount;
    }
    return base;
  }

  /// Facturación anual del colegio (cuota mensual * 12)
  double get cuotaAnualSaaS => cuotaMensualSaaS * 12;

  /// Retorna si el colegio tiene método de pago registrado o suscripción activa (o período de prueba)
  bool get tieneMetodoPagoValido => metodoPagoRegistrado || (metodoPago != null && metodoPago!.isNotEmpty) || estadoSuscripcion == 'active' || isTrial;

  bool get isActive => estadoSuscripcion == 'active';
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

    final cfg = json['configuracion'] is Map ? json['configuracion'] as Map<String, dynamic> : null;

    double parseDouble(dynamic v, double defaultVal) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? defaultVal;
    }

    DateTime? parsedTrialFin;
    if (json['trial_fin'] != null || cfg?['trial_fin'] != null) {
      try {
        parsedTrialFin = DateTime.parse((json['trial_fin'] ?? cfg?['trial_fin']).toString());
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
      precioInicial: parseDouble(json['precio_inicial'] ?? cfg?['precio_inicial'], 6500.0),
      precioPrimaria: parseDouble(json['precio_primaria'] ?? cfg?['precio_primaria'], 8000.0),
      precioSecundaria: parseDouble(json['precio_secundaria'] ?? cfg?['precio_secundaria'], 9500.0),
      precioMatricula: parseDouble(json['precio_matricula'] ?? cfg?['precio_matricula'], 12000.0),
      sujetoAMejoraPago: (json['sujeto_a_mejora_pago'] ?? cfg?['sujeto_a_mejora_pago']) as bool? ?? true,
      descuentoProntoPagoAnualPct: parseDouble(json['descuento_anual_pct'] ?? cfg?['descuento_anual_pct'], 10.0),
      descuentoProntoPagoSemestralPct: parseDouble(json['descuento_semestral_pct'] ?? cfg?['descuento_semestral_pct'], 5.0),
      descuentoProntoPagoTrimestralPct: parseDouble(json['descuento_trimestral_pct'] ?? cfg?['descuento_trimestral_pct'], 3.0),
      descuentoHermanosPct: parseDouble(json['descuento_hermanos_pct'] ?? cfg?['descuento_hermanos_pct'], 10.0),
      directorNombre: json['director_nombre']?.toString() ?? cfg?['director_nombre']?.toString(),
      directorEmail: json['director_email']?.toString() ?? cfg?['director_email']?.toString(),
      directorCedula: json['director_cedula']?.toString() ?? cfg?['director_cedula']?.toString(),
      directorTelefono: json['director_telefono']?.toString() ?? cfg?['director_telefono']?.toString(),
      sucursalesCount: json['sucursales_count'] is int
          ? json['sucursales_count'] as int
          : int.tryParse(json['sucursales_count']?.toString() ?? '0') ?? 0,
      metodoPago: json['metodo_pago']?.toString(),
      metodoPagoRegistrado: json['metodo_pago_registrado'] as bool? ??
          (json['metodo_pago'] != null && json['metodo_pago'].toString().isNotEmpty),
      diaCorte: (json['dia_corte'] ?? cfg?['dia_corte']) is int
          ? (json['dia_corte'] ?? cfg?['dia_corte']) as int
          : int.tryParse((json['dia_corte'] ?? cfg?['dia_corte'])?.toString() ?? '1') ?? 1,
      trialFin: parsedTrialFin,
    );
  }

  School copyWith({
    String? id,
    String? nombre,
    String? rnc,
    String? siglas,
    String? telefono,
    String? emailContacto,
    String? direccion,
    String? logoUrl,
    String? estadoSuscripcion,
    int? maxEstudiantes,
    DateTime? createdAt,
    int? totalEstudiantes,
    int? totalFamilias,
    double? precioInicial,
    double? precioPrimaria,
    double? precioSecundaria,
    double? precioMatricula,
    bool? sujetoAMejoraPago,
    double? descuentoProntoPagoAnualPct,
    double? descuentoProntoPagoSemestralPct,
    double? descuentoProntoPagoTrimestralPct,
    double? descuentoHermanosPct,
    String? directorNombre,
    String? directorEmail,
    String? directorCedula,
    String? directorTelefono,
    int? sucursalesCount,
    String? metodoPago,
    bool? metodoPagoRegistrado,
    int? diaCorte,
    DateTime? trialFin,
  }) {
    return School(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      rnc: rnc ?? this.rnc,
      siglas: siglas ?? this.siglas,
      telefono: telefono ?? this.telefono,
      emailContacto: emailContacto ?? this.emailContacto,
      direccion: direccion ?? this.direccion,
      logoUrl: logoUrl ?? this.logoUrl,
      estadoSuscripcion: estadoSuscripcion ?? this.estadoSuscripcion,
      maxEstudiantes: maxEstudiantes ?? this.maxEstudiantes,
      createdAt: createdAt ?? this.createdAt,
      totalEstudiantes: totalEstudiantes ?? this.totalEstudiantes,
      totalFamilias: totalFamilias ?? this.totalFamilias,
      precioInicial: precioInicial ?? this.precioInicial,
      precioPrimaria: precioPrimaria ?? this.precioPrimaria,
      precioSecundaria: precioSecundaria ?? this.precioSecundaria,
      precioMatricula: precioMatricula ?? this.precioMatricula,
      sujetoAMejoraPago: sujetoAMejoraPago ?? this.sujetoAMejoraPago,
      descuentoProntoPagoAnualPct: descuentoProntoPagoAnualPct ?? this.descuentoProntoPagoAnualPct,
      descuentoProntoPagoSemestralPct: descuentoProntoPagoSemestralPct ?? this.descuentoProntoPagoSemestralPct,
      descuentoProntoPagoTrimestralPct: descuentoProntoPagoTrimestralPct ?? this.descuentoProntoPagoTrimestralPct,
      descuentoHermanosPct: descuentoHermanosPct ?? this.descuentoHermanosPct,
      directorNombre: directorNombre ?? this.directorNombre,
      directorEmail: directorEmail ?? this.directorEmail,
      directorCedula: directorCedula ?? this.directorCedula,
      directorTelefono: directorTelefono ?? this.directorTelefono,
      sucursalesCount: sucursalesCount ?? this.sucursalesCount,
      metodoPago: metodoPago ?? this.metodoPago,
      metodoPagoRegistrado: metodoPagoRegistrado ?? this.metodoPagoRegistrado,
      diaCorte: diaCorte ?? this.diaCorte,
      trialFin: trialFin ?? this.trialFin,
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
      'sucursales_count': sucursalesCount,
      'metodo_pago': metodoPago,
      'metodo_pago_registrado': metodoPagoRegistrado,
      'dia_corte': diaCorte,
      'trial_fin': trialFin?.toIso8601String(),
    };
  }
}
