/// Modelos de Gestión Académica, Récord de Notas y Boletín Oficial de Calificaciones
/// Alineado con el Currículo Nacional Dominicano (MINERD) y Secciones 4.1 y 5 del Modelo de Negocio

class SubjectGrade {
  final String materia;
  final int? periodo1; // P1 (0 - 100)
  final int? periodo2; // P2 (0 - 100)
  final int? periodo3; // P3 (0 - 100)
  final int? periodo4; // P4 (0 - 100)
  final String docente;

  const SubjectGrade({
    required this.materia,
    this.periodo1,
    this.periodo2,
    this.periodo3,
    this.periodo4,
    required this.docente,
  });

  /// Promedio ponderado de los períodos evaluados hasta la fecha
  double get promedio {
    final list = [periodo1, periodo2, periodo3, periodo4].whereType<int>().toList();
    if (list.isEmpty) return 0.0;
    final sum = list.fold<int>(0, (prev, elem) => prev + elem);
    return sum / list.length;
  }

  String get estado {
    final p = promedio;
    if (p == 0) return 'Sin Evaluar';
    if (p >= 90) return 'Sobresaliente';
    if (p >= 70) return 'Aprobado';
    return 'En Recuperación';
  }

  SubjectGrade copyWith({
    int? periodo1,
    int? periodo2,
    int? periodo3,
    int? periodo4,
    String? docente,
  }) {
    return SubjectGrade(
      materia: materia,
      periodo1: periodo1 ?? this.periodo1,
      periodo2: periodo2 ?? this.periodo2,
      periodo3: periodo3 ?? this.periodo3,
      periodo4: periodo4 ?? this.periodo4,
      docente: docente ?? this.docente,
    );
  }

  Map<String, dynamic> toJson() => {
        'materia': materia,
        'periodo1': periodo1,
        'periodo2': periodo2,
        'periodo3': periodo3,
        'periodo4': periodo4,
        'docente': docente,
      };

  factory SubjectGrade.fromJson(Map<String, dynamic> json) => SubjectGrade(
        materia: json['materia'] as String,
        periodo1: json['periodo1'] as int?,
        periodo2: json['periodo2'] as int?,
        periodo3: json['periodo3'] as int?,
        periodo4: json['periodo4'] as int?,
        docente: json['docente'] as String? ?? 'Docente Titular',
      );
}

class StudentGradeReport {
  final String id;
  final String? colegioId;
  final String studentId;
  final String studentName;
  final String matricula;
  final String grado;
  final String seccion;
  final String anioEscolar;
  final String calificacionConducta;
  final String observacionesDocente;
  final List<SubjectGrade> materias;

  const StudentGradeReport({
    required this.id,
    this.colegioId,
    required this.studentId,
    required this.studentName,
    required this.matricula,
    required this.grado,
    required this.seccion,
    required this.anioEscolar,
    required this.calificacionConducta,
    required this.observacionesDocente,
    required this.materias,
  });

  double get promedioGeneral {
    if (materias.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final m in materias) {
      final p = m.promedio;
      if (p > 0) {
        sum += p;
        count++;
      }
    }
    return count == 0 ? 0.0 : (sum / count);
  }

  bool get honorRoll => promedioGeneral >= 90.0;

  String get estatusFinal {
    final p = promedioGeneral;
    if (p == 0) return 'En Curso';
    if (p >= 70) return 'Promovido / Aprobado';
    return 'Requiere Reforzamiento';
  }

  StudentGradeReport copyWith({
    String? colegioId,
    String? calificacionConducta,
    String? observacionesDocente,
    List<SubjectGrade>? materias,
  }) {
    return StudentGradeReport(
      id: id,
      colegioId: colegioId ?? this.colegioId,
      studentId: studentId,
      studentName: studentName,
      matricula: matricula,
      grado: grado,
      seccion: seccion,
      anioEscolar: anioEscolar,
      calificacionConducta: calificacionConducta ?? this.calificacionConducta,
      observacionesDocente: observacionesDocente ?? this.observacionesDocente,
      materias: materias ?? this.materias,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegioId': colegioId,
        'studentId': studentId,
        'studentName': studentName,
        'matricula': matricula,
        'grado': grado,
        'seccion': seccion,
        'anioEscolar': anioEscolar,
        'calificacionConducta': calificacionConducta,
        'observacionesDocente': observacionesDocente,
        'materias': materias.map((m) => m.toJson()).toList(),
      };

  factory StudentGradeReport.fromJson(Map<String, dynamic> json) => StudentGradeReport(
        id: json['id'] as String,
        colegioId: json['colegioId'] as String?,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        matricula: json['matricula'] as String,
        grado: json['grado'] as String,
        seccion: json['seccion'] as String,
        anioEscolar: json['anioEscolar'] as String,
        calificacionConducta: json['calificacionConducta'] as String? ?? 'A - Sobresaliente',
        observacionesDocente: json['observacionesDocente'] as String? ?? '',
        materias: (json['materias'] as List<dynamic>?)
                ?.map((m) => SubjectGrade.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
