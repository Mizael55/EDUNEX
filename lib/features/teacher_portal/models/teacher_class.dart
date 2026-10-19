/// Modelos de Clases y Asignaturas para el Portal del Docente en EDUNEX
/// Sección 4.1 y 5 del Modelo de Negocio

class ClassStudent {
  final String id;
  final String matricula;
  final String nombres;
  final String apellidos;
  final String tutorNombre;
  final String tutorTelefono;
  final String? fotoUrl;

  const ClassStudent({
    required this.id,
    required this.matricula,
    required this.nombres,
    required this.apellidos,
    required this.tutorNombre,
    required this.tutorTelefono,
    this.fotoUrl,
  });

  String get nombreCompleto => '$nombres $apellidos';

  Map<String, dynamic> toJson() => {
        'id': id,
        'matricula': matricula,
        'nombres': nombres,
        'apellidos': apellidos,
        'tutorNombre': tutorNombre,
        'tutorTelefono': tutorTelefono,
        'fotoUrl': fotoUrl,
      };

  factory ClassStudent.fromJson(Map<String, dynamic> json) => ClassStudent(
        id: json['id'] as String,
        matricula: json['matricula'] as String,
        nombres: json['nombres'] as String,
        apellidos: json['apellidos'] as String,
        tutorNombre: json['tutorNombre'] as String? ?? 'Tutor Principal',
        tutorTelefono: json['tutorTelefono'] as String? ?? '809-555-0100',
        fotoUrl: json['fotoUrl'] as String?,
      );
}

class TeacherClass {
  final String id;
  final String colegioId;
  final String docenteId;
  final String docenteNombre;
  final String materia;
  final String grado;
  final String seccion;
  final String aula;
  final String horario;
  final String colorHex;
  final List<ClassStudent> estudiantes;

  const TeacherClass({
    required this.id,
    required this.colegioId,
    required this.docenteId,
    required this.docenteNombre,
    required this.materia,
    required this.grado,
    required this.seccion,
    required this.aula,
    required this.horario,
    this.colorHex = '#1E3A8A',
    required this.estudiantes,
  });

  int get totalEstudiantes => estudiantes.length;

  String get identificadorCompleto => '$materia - $grado ($seccion)';

  TeacherClass copyWith({
    String? id,
    String? colegioId,
    String? docenteId,
    String? docenteNombre,
    String? materia,
    String? grado,
    String? seccion,
    String? aula,
    String? horario,
    String? colorHex,
    List<ClassStudent>? estudiantes,
  }) {
    return TeacherClass(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      docenteId: docenteId ?? this.docenteId,
      docenteNombre: docenteNombre ?? this.docenteNombre,
      materia: materia ?? this.materia,
      grado: grado ?? this.grado,
      seccion: seccion ?? this.seccion,
      aula: aula ?? this.aula,
      horario: horario ?? this.horario,
      colorHex: colorHex ?? this.colorHex,
      estudiantes: estudiantes ?? this.estudiantes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegioId': colegioId,
        'docenteId': docenteId,
        'docenteNombre': docenteNombre,
        'materia': materia,
        'grado': grado,
        'seccion': seccion,
        'aula': aula,
        'horario': horario,
        'colorHex': colorHex,
        'estudiantes': estudiantes.map((e) => e.toJson()).toList(),
      };

  factory TeacherClass.fromJson(Map<String, dynamic> json) => TeacherClass(
        id: json['id'] as String,
        colegioId: json['colegioId'] as String? ?? 'a0000000-0000-0000-0000-000000000001',
        docenteId: json['docenteId'] as String? ?? 'docente-001',
        docenteNombre: json['docenteNombre'] as String? ?? 'Prof. María González',
        materia: json['materia'] as String,
        grado: json['grado'] as String,
        seccion: json['seccion'] as String,
        aula: json['aula'] as String? ?? 'Aula Principal',
        horario: json['horario'] as String? ?? 'Lun a Vie',
        colorHex: json['colorHex'] as String? ?? '#1E3A8A',
        estudiantes: (json['estudiantes'] as List<dynamic>?)
                ?.map((e) => ClassStudent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
