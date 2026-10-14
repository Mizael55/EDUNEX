/// Modelo de Solicitud de Acuerdo o Convenio de Pago por parte del Tutor
class PaymentAgreementRequest {
  final String id;
  final String familiaId;
  final String nombreFamilia;
  final String tipoAcuerdo;
  final double propuestaCuota;
  final String justificacion;
  final DateTime fechaSolicitud;
  final String estado; // 'Aprobado', 'En revisión por Dirección', 'Rechazado'
  final String? respuestaCentro;
  final DateTime? fechaRespuesta;

  const PaymentAgreementRequest({
    required this.id,
    required this.familiaId,
    required this.nombreFamilia,
    required this.tipoAcuerdo,
    required this.propuestaCuota,
    required this.justificacion,
    required this.fechaSolicitud,
    this.estado = 'En revisión por Dirección',
    this.respuestaCentro,
    this.fechaRespuesta,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'familia_id': familiaId,
    'nombre_familia': nombreFamilia,
    'tipo_acuerdo': tipoAcuerdo,
    'propuesta_cuota': propuestaCuota,
    'justificacion': justificacion,
    'fecha_solicitud': fechaSolicitud.toIso8601String(),
    'estado': estado,
    'respuesta_centro': respuestaCentro,
    'fecha_respuesta': fechaRespuesta?.toIso8601String(),
  };

  factory PaymentAgreementRequest.fromJson(Map<String, dynamic> json) => PaymentAgreementRequest(
    id: json['id'] as String,
    familiaId: json['familia_id'] as String,
    nombreFamilia: json['nombre_familia'] as String,
    tipoAcuerdo: json['tipo_acuerdo'] as String,
    propuestaCuota: (json['propuesta_cuota'] as num).toDouble(),
    justificacion: json['justificacion'] as String,
    fechaSolicitud: DateTime.parse(json['fecha_solicitud'] as String),
    estado: json['estado'] as String? ?? 'En revisión por Dirección',
    respuestaCentro: json['respuesta_centro'] as String?,
    fechaRespuesta: json['fecha_respuesta'] != null ? DateTime.parse(json['fecha_respuesta'] as String) : null,
  );
}
