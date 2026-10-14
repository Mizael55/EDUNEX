/// Modelo de Consulta o Pregunta enviada por el Tutor al Centro Educativo
class ParentQuestion {
  final String id;
  final String familiaId;
  final String tutorNombre;
  final String departamento; // 'Dirección Académica', 'Caja y Facturación', 'Psicología y Orientación', 'Secretaría Escolar'
  final String asunto;
  final String mensaje;
  final DateTime fechaEnvio;
  final String estado; // 'Respondida', 'En trámite'
  final String? respuestaCentro;
  final DateTime? fechaRespuesta;
  final String? respondidoPor;

  const ParentQuestion({
    required this.id,
    required this.familiaId,
    required this.tutorNombre,
    required this.departamento,
    required this.asunto,
    required this.mensaje,
    required this.fechaEnvio,
    this.estado = 'En trámite',
    this.respuestaCentro,
    this.fechaRespuesta,
    this.respondidoPor,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'familia_id': familiaId,
    'tutor_nombre': tutorNombre,
    'departamento': departamento,
    'asunto': asunto,
    'mensaje': mensaje,
    'fecha_envio': fechaEnvio.toIso8601String(),
    'estado': estado,
    'respuesta_centro': respuestaCentro,
    'fecha_respuesta': fechaRespuesta?.toIso8601String(),
    'respondido_por': respondidoPor,
  };

  factory ParentQuestion.fromJson(Map<String, dynamic> json) => ParentQuestion(
    id: json['id'] as String,
    familiaId: json['familia_id'] as String,
    tutorNombre: json['tutor_nombre'] as String,
    departamento: json['departamento'] as String,
    asunto: json['asunto'] as String,
    mensaje: json['mensaje'] as String,
    fechaEnvio: DateTime.parse(json['fecha_envio'] as String),
    estado: json['estado'] as String? ?? 'En trámite',
    respuestaCentro: json['respuesta_centro'] as String?,
    fechaRespuesta: json['fecha_respuesta'] != null ? DateTime.parse(json['fecha_respuesta'] as String) : null,
    respondidoPor: json['respondido_por'] as String?,
  );
}
