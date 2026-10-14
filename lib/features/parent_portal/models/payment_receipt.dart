/// Modelo de Comprobante Oficial de Pago de EDUNEX
class PaymentReceipt {
  final String id;
  final String numeroComprobante;
  final String ncf;
  final String familiaId;
  final String nombreFamilia;
  final DateTime fechaEmision;
  final String concepto;
  final double monto;
  final String metodoPago;
  final String referencia;
  final String estado;
  final List<String> estudiantes;

  const PaymentReceipt({
    required this.id,
    required this.numeroComprobante,
    required this.ncf,
    required this.familiaId,
    required this.nombreFamilia,
    required this.fechaEmision,
    required this.concepto,
    required this.monto,
    required this.metodoPago,
    required this.referencia,
    this.estado = 'Válido / Pagado',
    this.estudiantes = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero_comprobante': numeroComprobante,
    'ncf': ncf,
    'familia_id': familiaId,
    'nombre_familia': nombreFamilia,
    'fecha_emision': fechaEmision.toIso8601String(),
    'concepto': concepto,
    'monto': monto,
    'metodo_pago': metodoPago,
    'referencia': referencia,
    'estado': estado,
    'estudiantes': estudiantes,
  };

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) => PaymentReceipt(
    id: json['id'] as String,
    numeroComprobante: json['numero_comprobante'] as String,
    ncf: json['ncf'] as String? ?? 'B0200000001',
    familiaId: json['familia_id'] as String,
    nombreFamilia: json['nombre_familia'] as String,
    fechaEmision: DateTime.parse(json['fecha_emision'] as String),
    concepto: json['concepto'] as String,
    monto: (json['monto'] as num).toDouble(),
    metodoPago: json['metodo_pago'] as String,
    referencia: json['referencia'] as String,
    estado: json['estado'] as String? ?? 'Válido / Pagado',
    estudiantes: (json['estudiantes'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}
