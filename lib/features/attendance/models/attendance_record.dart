/// Estado de asistencia de un estudiante
enum AttendanceStatus {
  presente('Presente', 'P'),
  tardanza('Tardanza', 'T'),
  ausente('Ausente', 'A'),
  justificado('Justificado', 'J');

  final String label;
  final String shortCode;
  const AttendanceStatus(this.label, this.shortCode);

  static AttendanceStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'tardanza':
      case 't':
        return AttendanceStatus.tardanza;
      case 'ausente':
      case 'a':
        return AttendanceStatus.ausente;
      case 'justificado':
      case 'j':
        return AttendanceStatus.justificado;
      case 'presente':
      case 'p':
      default:
        return AttendanceStatus.presente;
    }
  }
}

/// Registro oficial de asistencia diaria escolar por estudiante en EDUNEX
class AttendanceRecord {
  final String id;
  final String estudianteId;
  final String estudianteNombre;
  final String matricula;
  final String familiaId;
  final String colegioId;
  final String gradoNombre;
  final String seccionNombre;
  final DateTime fecha;
  final String estado; // 'Presente', 'Tardanza', 'Ausente', 'Justificado'
  final String? horaLlegada;
  final String? observacion;
  final String? justificacionTutor;
  final bool notificadoATutor;

  const AttendanceRecord({
    required this.id,
    required this.estudianteId,
    required this.estudianteNombre,
    required this.matricula,
    required this.familiaId,
    required this.colegioId,
    required this.gradoNombre,
    required this.seccionNombre,
    required this.fecha,
    required this.estado,
    this.horaLlegada,
    this.observacion,
    this.justificacionTutor,
    this.notificadoATutor = true,
  });

  bool get esPresente => estado == AttendanceStatus.presente.label;
  bool get esTardanza => estado == AttendanceStatus.tardanza.label;
  bool get esAusente => estado == AttendanceStatus.ausente.label;
  bool get esJustificado => estado == AttendanceStatus.justificado.label;

  AttendanceRecord copyWith({
    String? id,
    String? estudianteId,
    String? estudianteNombre,
    String? matricula,
    String? familiaId,
    String? colegioId,
    String? gradoNombre,
    String? seccionNombre,
    DateTime? fecha,
    String? estado,
    String? horaLlegada,
    String? observacion,
    String? justificacionTutor,
    bool? notificadoATutor,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      estudianteId: estudianteId ?? this.estudianteId,
      estudianteNombre: estudianteNombre ?? this.estudianteNombre,
      matricula: matricula ?? this.matricula,
      familiaId: familiaId ?? this.familiaId,
      colegioId: colegioId ?? this.colegioId,
      gradoNombre: gradoNombre ?? this.gradoNombre,
      seccionNombre: seccionNombre ?? this.seccionNombre,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      horaLlegada: horaLlegada ?? this.horaLlegada,
      observacion: observacion ?? this.observacion,
      justificacionTutor: justificacionTutor ?? this.justificacionTutor,
      notificadoATutor: notificadoATutor ?? this.notificadoATutor,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'estudiante_id': estudianteId,
    'estudiante_nombre': estudianteNombre,
    'matricula': matricula,
    'familia_id': familiaId,
    'colegio_id': colegioId,
    'grado_nombre': gradoNombre,
    'seccion_nombre': seccionNombre,
    'fecha': fecha.toIso8601String(),
    'estado': estado,
    'hora_llegada': horaLlegada,
    'observacion': observacion,
    'justificacion_tutor': justificacionTutor,
    'notificado_a_tutor': notificadoATutor,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    id: json['id'] as String,
    estudianteId: json['estudiante_id'] as String,
    estudianteNombre: json['estudiante_nombre'] as String,
    matricula: json['matricula'] as String,
    familiaId: json['familia_id'] as String,
    colegioId: json['colegio_id'] as String,
    gradoNombre: json['grado_nombre'] as String,
    seccionNombre: json['seccion_nombre'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    estado: json['estado'] as String,
    horaLlegada: json['hora_llegada'] as String?,
    observacion: json['observacion'] as String?,
    justificacionTutor: json['justificacion_tutor'] as String?,
    notificadoATutor: json['notificado_a_tutor'] as bool? ?? true,
  );
}
