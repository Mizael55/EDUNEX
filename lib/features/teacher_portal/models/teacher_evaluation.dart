/// Modelo de Componentes de Evaluación y Cuaderno de Calificaciones del Docente

class TeacherEvaluationItem {
  final String id;
  final String classId;
  final String periodo; // 'P1', 'P2', 'P3', 'P4'
  final String titulo;
  final String tipo; // 'Tarea', 'Quiz', 'Proyecto', 'Examen', 'Participación'
  final double porcentaje; // e.g. 20.0
  final DateTime fecha;
  final Map<String, double> calificaciones; // studentId -> nota (0 a 100)

  const TeacherEvaluationItem({
    required this.id,
    required this.classId,
    required this.periodo,
    required this.titulo,
    required this.tipo,
    required this.porcentaje,
    required this.fecha,
    this.calificaciones = const {},
  });

  TeacherEvaluationItem copyWith({
    String? id,
    String? classId,
    String? periodo,
    String? titulo,
    String? tipo,
    double? porcentaje,
    DateTime? fecha,
    Map<String, double>? calificaciones,
  }) {
    return TeacherEvaluationItem(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      periodo: periodo ?? this.periodo,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      porcentaje: porcentaje ?? this.porcentaje,
      fecha: fecha ?? this.fecha,
      calificaciones: calificaciones ?? this.calificaciones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'periodo': periodo,
        'titulo': titulo,
        'tipo': tipo,
        'porcentaje': porcentaje,
        'fecha': fecha.toIso8601String(),
        'calificaciones': calificaciones,
      };

  factory TeacherEvaluationItem.fromJson(Map<String, dynamic> json) => TeacherEvaluationItem(
        id: json['id'] as String,
        classId: json['classId'] as String,
        periodo: json['periodo'] as String? ?? 'P1',
        titulo: json['titulo'] as String,
        tipo: json['tipo'] as String? ?? 'Tarea',
        porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 20.0,
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
        calificaciones: (json['calificaciones'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            const {},
      );
}
