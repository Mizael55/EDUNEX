/// Modelo de Observador del Alumno y Registro de Convivencia Escolar
/// Permite al docente asentar méritos, llamados de atención y remisiones a psicología con notificación

class StudentBehaviorLog {
  final String id;
  final String classId;
  final String studentId;
  final String studentName;
  final String grado;
  final String docenteId;
  final String docenteNombre;
  final String tipo; // 'Mérito / Felicitación', 'Llamado de Atención Leve', 'Falta Grave de Convivencia', 'Remisión a Psicología'
  final String categoria; // 'Académico', 'Conductual', 'Uniforme / Puntualidad', 'Convivencia'
  final String descripcion;
  final DateTime fecha;
  final bool notificadoTutor;
  final bool notificadoPsicologia;

  const StudentBehaviorLog({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.grado,
    required this.docenteId,
    required this.docenteNombre,
    required this.tipo,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    this.notificadoTutor = true,
    this.notificadoPsicologia = false,
  });

  bool get esPositivo => tipo.contains('Mérito') || tipo.contains('Felicitación');
  bool get esPsicologia => tipo.contains('Psicología') || notificadoPsicologia;

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'studentId': studentId,
        'studentName': studentName,
        'grado': grado,
        'docenteId': docenteId,
        'docenteNombre': docenteNombre,
        'tipo': tipo,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
        'notificadoTutor': notificadoTutor,
        'notificadoPsicologia': notificadoPsicologia,
      };

  factory StudentBehaviorLog.fromJson(Map<String, dynamic> json) => StudentBehaviorLog(
        id: json['id'] as String,
        classId: json['classId'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        grado: json['grado'] as String? ?? 'General',
        docenteId: json['docenteId'] as String? ?? 'docente-001',
        docenteNombre: json['docenteNombre'] as String? ?? 'Docente',
        tipo: json['tipo'] as String? ?? 'Observación Pedagógica',
        categoria: json['categoria'] as String? ?? 'Conductual',
        descripcion: json['descripcion'] as String,
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
        notificadoTutor: json['notificadoTutor'] as bool? ?? true,
        notificadoPsicologia: json['notificadoPsicologia'] as bool? ?? false,
      );
}
