library;

/// Modelos para Automatización de Facturación Recurrente y Reporte de Antigüedad de Deuda (Aging)
/// Cumplimiento Secciones 4.3 y 8 del Modelo de Negocio de EDUNEX

class BillingRunResult {
  final String id;
  final String mesConcepto;
  final DateTime fechaEjecucion;
  final int familiasProcesadas;
  final int estudiantesFacturados;
  final double montoColegiaturas;
  final double montoServiciosAdicionales;
  final double montoTotalFacturado;
  final List<BillingItemDetail> detalles;

  const BillingRunResult({
    required this.id,
    required this.mesConcepto,
    required this.fechaEjecucion,
    required this.familiasProcesadas,
    required this.estudiantesFacturados,
    required this.montoColegiaturas,
    required this.montoServiciosAdicionales,
    required this.montoTotalFacturado,
    required this.detalles,
  });
}

class BillingItemDetail {
  final String familiaId;
  final String codigoFamilia;
  final String nombreFamilia;
  final int cantidadEstudiantes;
  final double colegiatura;
  final double servicios;
  final double totalCargo;
  final double nuevoBalance;

  const BillingItemDetail({
    required this.familiaId,
    required this.codigoFamilia,
    required this.nombreFamilia,
    required this.cantidadEstudiantes,
    required this.colegiatura,
    required this.servicios,
    required this.totalCargo,
    required this.nuevoBalance,
  });
}

enum DelinquencyRisk {
  bajo,
  medio,
  alto,
  critico,
}

class DelinquentFamily {
  final String familiaId;
  final String codigoFamilia;
  final String nombreFamilia;
  final String telefonoPrincipal;
  final String emailPrincipal;
  final double balancePendiente;
  final int diasMora;
  final DelinquencyRisk riesgo;
  final DateTime? ultimoRecordatorio;

  const DelinquentFamily({
    required this.familiaId,
    required this.codigoFamilia,
    required this.nombreFamilia,
    required this.telefonoPrincipal,
    required this.emailPrincipal,
    required this.balancePendiente,
    required this.diasMora,
    required this.riesgo,
    this.ultimoRecordatorio,
  });

  String get bucketAntiguedad {
    if (diasMora <= 30) return 'Corriente (0-30d)';
    if (diasMora <= 60) return 'Vencido (31-60d)';
    if (diasMora <= 90) return 'Vencido (61-90d)';
    return 'Mora Crítica (>90d)';
  }

  DelinquentFamily copyWith({
    DateTime? ultimoRecordatorio,
  }) {
    return DelinquentFamily(
      familiaId: familiaId,
      codigoFamilia: codigoFamilia,
      nombreFamilia: nombreFamilia,
      telefonoPrincipal: telefonoPrincipal,
      emailPrincipal: emailPrincipal,
      balancePendiente: balancePendiente,
      diasMora: diasMora,
      riesgo: riesgo,
      ultimoRecordatorio: ultimoRecordatorio ?? this.ultimoRecordatorio,
    );
  }
}

class DebtAgingSummary {
  final double totalCorriente; // 0-30 días
  final double total30a60; // 31-60 días
  final double total60a90; // 61-90 días
  final double totalMas90; // >90 días
  final double totalCarteraVencida;
  final List<DelinquentFamily> familiasEnMora;

  const DebtAgingSummary({
    required this.totalCorriente,
    required this.total30a60,
    required this.total60a90,
    required this.totalMas90,
    required this.totalCarteraVencida,
    required this.familiasEnMora,
  });
}
