library;

/// Estados de la solicitud de autorización de abono (Issue #17)
enum PaymentApprovalStatus {
  pendiente('Pendiente de Autorización'),
  aprobado('Autorizado por Administración'),
  rechazado('Rechazado');

  final String label;
  const PaymentApprovalStatus(this.label);
}

/// Modelo de Solicitud de Permiso / Autorización de Abono para Familias (Issue #17)
class PaymentApprovalRequest {
  final String id;
  final String familiaId;
  final String familiaNombre;
  final String codigoFamilia;
  final double balanceTotal;
  final double montoAbonoPropuesto;
  final String concepto;
  final String motivoAbono;
  final String solicitadoPor;
  final DateTime fechaSolicitud;
  final PaymentApprovalStatus estado;
  final String? aprobadoPor;
  final DateTime? fechaResolucion;
  final String? notasResolucion;

  const PaymentApprovalRequest({
    required this.id,
    required this.familiaId,
    required this.familiaNombre,
    required this.codigoFamilia,
    required this.balanceTotal,
    required this.montoAbonoPropuesto,
    required this.concepto,
    required this.motivoAbono,
    required this.solicitadoPor,
    required this.fechaSolicitud,
    this.estado = PaymentApprovalStatus.pendiente,
    this.aprobadoPor,
    this.fechaResolucion,
    this.notasResolucion,
  });

  PaymentApprovalRequest copyWith({
    String? id,
    String? familiaId,
    String? familiaNombre,
    String? codigoFamilia,
    double? balanceTotal,
    double? montoAbonoPropuesto,
    String? concepto,
    String? motivoAbono,
    String? solicitadoPor,
    DateTime? fechaSolicitud,
    PaymentApprovalStatus? estado,
    String? aprobadoPor,
    DateTime? fechaResolucion,
    String? notasResolucion,
  }) {
    return PaymentApprovalRequest(
      id: id ?? this.id,
      familiaId: familiaId ?? this.familiaId,
      familiaNombre: familiaNombre ?? this.familiaNombre,
      codigoFamilia: codigoFamilia ?? this.codigoFamilia,
      balanceTotal: balanceTotal ?? this.balanceTotal,
      montoAbonoPropuesto: montoAbonoPropuesto ?? this.montoAbonoPropuesto,
      concepto: concepto ?? this.concepto,
      motivoAbono: motivoAbono ?? this.motivoAbono,
      solicitadoPor: solicitadoPor ?? this.solicitadoPor,
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
      estado: estado ?? this.estado,
      aprobadoPor: aprobadoPor ?? this.aprobadoPor,
      fechaResolucion: fechaResolucion ?? this.fechaResolucion,
      notasResolucion: notasResolucion ?? this.notasResolucion,
    );
  }
}
