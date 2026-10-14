/// Modelo de Inscripción formal a un Evento Escolar
class EventRegistration {
  final String id;
  final String eventoId;
  final String eventoTitulo;
  final String familiaId;
  final String estudianteId;
  final String estudianteNombre;
  final DateTime fechaInscripcion;
  final double montoPagado;
  final String metodoPago;
  final String estadoPago; // 'Pagado', 'Cargado a Cuenta', 'Gratuito'

  const EventRegistration({
    required this.id,
    required this.eventoId,
    required this.eventoTitulo,
    required this.familiaId,
    required this.estudianteId,
    required this.estudianteNombre,
    required this.fechaInscripcion,
    required this.montoPagado,
    required this.metodoPago,
    this.estadoPago = 'Pagado',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'evento_id': eventoId,
    'evento_titulo': eventoTitulo,
    'familia_id': familiaId,
    'estudiante_id': estudianteId,
    'estudiante_nombre': estudianteNombre,
    'fecha_inscripcion': fechaInscripcion.toIso8601String(),
    'monto_pagado': montoPagado,
    'metodo_pago': metodoPago,
    'estado_pago': estadoPago,
  };

  factory EventRegistration.fromJson(Map<String, dynamic> json) => EventRegistration(
    id: json['id'] as String,
    eventoId: json['evento_id'] as String,
    eventoTitulo: json['evento_titulo'] as String,
    familiaId: json['familia_id'] as String,
    estudianteId: json['estudiante_id'] as String,
    estudianteNombre: json['estudiante_nombre'] as String,
    fechaInscripcion: DateTime.parse(json['fecha_inscripcion'] as String),
    montoPagado: (json['monto_pagado'] as num).toDouble(),
    metodoPago: json['metodo_pago'] as String,
    estadoPago: json['estado_pago'] as String? ?? 'Pagado',
  );
}
