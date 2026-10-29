enum SaaSInvoiceStatus {
  pagada,
  pendiente,
  enMora;

  String get displayName {
    switch (this) {
      case SaaSInvoiceStatus.pagada:
        return 'Pagada';
      case SaaSInvoiceStatus.pendiente:
        return 'Pendiente';
      case SaaSInvoiceStatus.enMora:
        return 'En Mora';
    }
  }
}

class SaaSInvoice {
  final String id;
  final String colegioId;
  final String colegioNombre;
  final String? rncColegio;
  final String periodo;
  final double monto;
  final String? ncf;
  final String tipoNCF;
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final DateTime? fechaPago;
  final SaaSInvoiceStatus estado;
  final String? metodoPago;
  final String? notas;

  const SaaSInvoice({
    required this.id,
    required this.colegioId,
    required this.colegioNombre,
    this.rncColegio,
    required this.periodo,
    required this.monto,
    this.ncf,
    this.tipoNCF = 'B01',
    required this.fechaEmision,
    required this.fechaVencimiento,
    this.fechaPago,
    required this.estado,
    this.metodoPago,
    this.notas,
  });

  bool get isPaid => estado == SaaSInvoiceStatus.pagada;
  bool get isOverdue =>
      !isPaid && DateTime.now().isAfter(fechaVencimiento);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colegio_id': colegioId,
      'colegio_nombre': colegioNombre,
      'rnc_colegio': rncColegio,
      'periodo': periodo,
      'monto': monto,
      'ncf': ncf,
      'tipo_ncf': tipoNCF,
      'fecha_emision': fechaEmision.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'fecha_pago': fechaPago?.toIso8601String(),
      'estado': estado.name,
      'metodo_pago': metodoPago,
      'notas': notas,
    };
  }

  factory SaaSInvoice.fromJson(Map<String, dynamic> json) {
    SaaSInvoiceStatus parsedStatus;
    final statusStr = json['estado']?.toString().toLowerCase();
    if (statusStr == 'pagada' || statusStr == 'paid') {
      parsedStatus = SaaSInvoiceStatus.pagada;
    } else if (statusStr == 'enmora' || statusStr == 'en_mora' || statusStr == 'overdue') {
      parsedStatus = SaaSInvoiceStatus.enMora;
    } else {
      parsedStatus = SaaSInvoiceStatus.pendiente;
    }

    return SaaSInvoice(
      id: json['id']?.toString() ?? '',
      colegioId: json['colegio_id']?.toString() ?? '',
      colegioNombre: json['colegio_nombre']?.toString() ?? 'Colegio',
      rncColegio: json['rnc_colegio']?.toString(),
      periodo: json['periodo']?.toString() ?? 'Mes en curso',
      monto: (json['monto'] is num) ? (json['monto'] as num).toDouble() : double.tryParse(json['monto']?.toString() ?? '0') ?? 0.0,
      ncf: json['ncf']?.toString(),
      tipoNCF: json['tipo_ncf']?.toString() ?? 'B01',
      fechaEmision: json['fecha_emision'] != null
          ? DateTime.tryParse(json['fecha_emision'].toString()) ?? DateTime.now()
          : DateTime.now(),
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.tryParse(json['fecha_vencimiento'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      fechaPago: json['fecha_pago'] != null
          ? DateTime.tryParse(json['fecha_pago'].toString())
          : null,
      estado: parsedStatus,
      metodoPago: json['metodo_pago']?.toString(),
      notas: json['notas']?.toString(),
    );
  }

  SaaSInvoice copyWith({
    String? id,
    String? colegioId,
    String? colegioNombre,
    String? rncColegio,
    String? periodo,
    double? monto,
    String? ncf,
    String? tipoNCF,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    DateTime? fechaPago,
    SaaSInvoiceStatus? estado,
    String? metodoPago,
    String? notas,
  }) {
    return SaaSInvoice(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      colegioNombre: colegioNombre ?? this.colegioNombre,
      rncColegio: rncColegio ?? this.rncColegio,
      periodo: periodo ?? this.periodo,
      monto: monto ?? this.monto,
      ncf: ncf ?? this.ncf,
      tipoNCF: tipoNCF ?? this.tipoNCF,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaPago: fechaPago ?? this.fechaPago,
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
      notas: notas ?? this.notas,
    );
  }
}
