import '../models/grade_report.dart';

/// Repositorio de Gestión Académica y Boletines de Calificaciones
/// Alineado con los lineamientos del MINERD y el modelo de negocio EDUNEX
class AcademicRepository {
  static final List<StudentGradeReport> _reports = [
    StudentGradeReport(
      id: 'grade-rep-001',
      studentId: 'f0000000-0000-0000-0000-000000000001',
      studentName: 'Mateo Pérez González',
      matricula: 'EST-2026-01',
      grado: '1ro de Primaria',
      seccion: 'Sección A',
      anioEscolar: '2025-2026',
      calificacionConducta: 'A - Sobresaliente',
      observacionesDocente:
          'Mateo demuestra un excelente compromiso académico, liderazgo en proyectos colaborativos y destacada destreza en lectoescritura y razonamiento lógico-matemático.',
      materias: const [
        SubjectGrade(
          materia: 'Matemáticas',
          periodo1: 92,
          periodo2: 95,
          periodo3: 88,
          periodo4: 94,
          docente: 'Lic. Rosaura Peña',
        ),
        SubjectGrade(
          materia: 'Lengua Española',
          periodo1: 90,
          periodo2: 91,
          periodo3: 94,
          periodo4: 92,
          docente: 'Lic. Marcos Almonte',
        ),
        SubjectGrade(
          materia: 'Ciencias de la Naturaleza',
          periodo1: 88,
          periodo2: 89,
          periodo3: 90,
          periodo4: 91,
          docente: 'Dra. Elena Vásquez',
        ),
        SubjectGrade(
          materia: 'Ciencias Sociales',
          periodo1: 85,
          periodo2: 90,
          periodo3: 88,
          periodo4: 92,
          docente: 'Lic. Fernando Ruiz',
        ),
        SubjectGrade(
          materia: 'Inglés Técnico',
          periodo1: 96,
          periodo2: 98,
          periodo3: 95,
          periodo4: 97,
          docente: 'Lic. Sarah Jenkins',
        ),
        SubjectGrade(
          materia: 'Educación Artística',
          periodo1: 95,
          periodo2: 94,
          periodo3: 96,
          periodo4: 98,
          docente: 'Lic. David Batista',
        ),
        SubjectGrade(
          materia: 'Educación Física',
          periodo1: 90,
          periodo2: 92,
          periodo3: 94,
          periodo4: 95,
          docente: 'Lic. José Tavárez',
        ),
        SubjectGrade(
          materia: 'Formación Humana & Ética',
          periodo1: 95,
          periodo2: 96,
          periodo3: 98,
          periodo4: 96,
          docente: 'Lic. Rosaura Peña',
        ),
      ],
    ),
    StudentGradeReport(
      id: 'grade-rep-002',
      studentId: 'f0000000-0000-0000-0000-000000000002',
      studentName: 'Sofía Pérez González',
      matricula: 'EST-2026-02',
      grado: 'Kinder',
      seccion: 'Sección A',
      anioEscolar: '2025-2026',
      calificacionConducta: 'A - Sobresaliente',
      observacionesDocente:
          'Sofía se integra con alegría en todas las rutinas pedagógicas, manifiesta un alto nivel de empatía con sus compañeros y desarrolla con soltura sus habilidades motoras finas.',
      materias: const [
        SubjectGrade(
          materia: 'Dimensión Cognitiva & Lógica',
          periodo1: 95,
          periodo2: 98,
          periodo3: 96,
          periodo4: 97,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Expresión Corporal & Psicomotricidad',
          periodo1: 92,
          periodo2: 95,
          periodo3: 94,
          periodo4: 96,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Lenguaje & Comunicación Temprana',
          periodo1: 96,
          periodo2: 94,
          periodo3: 98,
          periodo4: 95,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Desarrollo Socioafectivo',
          periodo1: 98,
          periodo2: 96,
          periodo3: 97,
          periodo4: 99,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Sensibilidad Musical & Artística',
          periodo1: 94,
          periodo2: 97,
          periodo3: 95,
          periodo4: 98,
          docente: 'Prof. Lucas Ortiz',
        ),
      ],
    ),
    StudentGradeReport(
      id: 'grade-rep-003',
      studentId: 'f0000000-0000-0000-0000-000000000003',
      studentName: 'Lucas Ramírez Méndez',
      matricula: 'EST-2026-03',
      grado: '1ro de Primaria',
      seccion: 'Sección A',
      anioEscolar: '2025-2026',
      calificacionConducta: 'B+ - Muy Bueno',
      observacionesDocente:
          'Lucas muestra buen desempeño general. Se sugiere continuar reforzando la caligrafía y el hábito de lectura diaria en el hogar.',
      materias: const [
        SubjectGrade(
          materia: 'Matemáticas',
          periodo1: 84,
          periodo2: 86,
          periodo3: 82,
          periodo4: 85,
          docente: 'Lic. Rosaura Peña',
        ),
        SubjectGrade(
          materia: 'Lengua Española',
          periodo1: 78,
          periodo2: 80,
          periodo3: 82,
          periodo4: 84,
          docente: 'Lic. Marcos Almonte',
        ),
        SubjectGrade(
          materia: 'Ciencias de la Naturaleza',
          periodo1: 82,
          periodo2: 85,
          periodo3: 86,
          periodo4: 88,
          docente: 'Dra. Elena Vásquez',
        ),
        SubjectGrade(
          materia: 'Ciencias Sociales',
          periodo1: 80,
          periodo2: 82,
          periodo3: 84,
          periodo4: 83,
          docente: 'Lic. Fernando Ruiz',
        ),
        SubjectGrade(
          materia: 'Inglés Técnico',
          periodo1: 88,
          periodo2: 90,
          periodo3: 89,
          periodo4: 91,
          docente: 'Lic. Sarah Jenkins',
        ),
        SubjectGrade(
          materia: 'Educación Artística',
          periodo1: 86,
          periodo2: 88,
          periodo3: 89,
          periodo4: 90,
          docente: 'Lic. David Batista',
        ),
      ],
    ),
  ];

  /// Obtiene los reportes filtrados opcionalmente por grado y sección
  Future<List<StudentGradeReport>> getReports({String? grado, String? seccion}) async {
    return _reports.where((r) {
      if (grado != null && grado.isNotEmpty && r.grado != grado) return false;
      if (seccion != null && seccion.isNotEmpty && r.seccion != seccion) return false;
      return true;
    }).toList();
  }

  /// Obtiene el reporte de un estudiante por su ID
  Future<StudentGradeReport?> getReportForStudent(String studentId) async {
    try {
      return _reports.firstWhere((r) => r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  /// Actualiza la calificación de una materia en un período específico
  Future<void> updateSubjectGrade({
    required String reportId,
    required String materia,
    required int periodo, // 1, 2, 3 o 4
    required int nota,
  }) async {
    final reportIndex = _reports.indexWhere((r) => r.id == reportId);
    if (reportIndex == -1) return;

    final current = _reports[reportIndex];
    final updatedMaterias = current.materias.map((m) {
      if (m.materia != materia) return m;
      switch (periodo) {
        case 1:
          return m.copyWith(periodo1: nota);
        case 2:
          return m.copyWith(periodo2: nota);
        case 3:
          return m.copyWith(periodo3: nota);
        case 4:
          return m.copyWith(periodo4: nota);
        default:
          return m;
      }
    }).toList();

    _reports[reportIndex] = current.copyWith(materias: updatedMaterias);
  }

  /// Estadísticas académicas consolidadas del centro
  Map<String, dynamic> getAcademicMetrics() {
    if (_reports.isEmpty) {
      return {
        'promedioGeneral': 0.0,
        'tasaAprobacion': 100.0,
        'cuadroHonorCount': 0,
        'reforzamientoCount': 0,
        'totalEvaluados': 0,
      };
    }

    double sumaPromedios = 0.0;
    int honorCount = 0;
    int reforzamientoCount = 0;

    for (final r in _reports) {
      final p = r.promedioGeneral;
      sumaPromedios += p;
      if (r.honorRoll) honorCount++;
      if (p < 70 && p > 0) reforzamientoCount++;
    }

    final promGeneral = sumaPromedios / _reports.length;
    final aprobados = _reports.where((r) => r.promedioGeneral >= 70).length;
    final tasaAprob = (aprobados / _reports.length) * 100.0;

    return {
      'promedioGeneral': promGeneral,
      'tasaAprobacion': tasaAprob,
      'cuadroHonorCount': honorCount,
      'reforzamientoCount': reforzamientoCount,
      'totalEvaluados': _reports.length,
    };
  }
}
