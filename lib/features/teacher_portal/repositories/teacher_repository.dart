import '../models/teacher_class.dart';
import '../models/teacher_evaluation.dart';
import '../models/student_behavior_log.dart';
import '../../academics/repositories/academic_repository.dart';
import '../../attendance/repositories/attendance_repository.dart';
import '../../attendance/models/attendance_record.dart';

/// Repositorio del Portal del Docente en EDUNEX
/// Gestiona asignaturas asignadas, cuaderno digital de notas, asistencia y observador escolar
class TeacherRepository {
  final bool _useDemoFallback;

  TeacherRepository({bool useDemoFallback = false}) : _useDemoFallback = useDemoFallback;

  static final List<TeacherClass> _seedClasses = [
    TeacherClass(
      id: 'class-mat-1a',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      docenteId: 'docente-001',
      docenteNombre: 'Prof. María González',
      materia: 'Matemáticas',
      grado: '1ro de Primaria',
      seccion: 'Sección A',
      aula: 'Aula 101',
      horario: 'Lun y Mié 8:00 - 9:30 AM',
      colorHex: '#1E3A8A',
      estudiantes: const [
        ClassStudent(
          id: 'f0000000-0000-0000-0000-000000000001',
          matricula: 'EST-2026-01',
          nombres: 'Mateo',
          apellidos: 'Pérez González',
          tutorNombre: 'Ing. Roberto Pérez',
          tutorTelefono: '809-555-0150',
        ),
        ClassStudent(
          id: 'f0000000-0000-0000-0000-000000000002',
          matricula: 'EST-2026-02',
          nombres: 'Sofía',
          apellidos: 'Pérez González',
          tutorNombre: 'Ing. Roberto Pérez',
          tutorTelefono: '809-555-0150',
        ),
        ClassStudent(
          id: 'f0000000-0000-0000-0000-000000000003',
          matricula: 'EST-2026-03',
          nombres: 'Lucas',
          apellidos: 'Ramírez Méndez',
          tutorNombre: 'Laura Méndez',
          tutorTelefono: '809-555-0210',
        ),
      ],
    ),
    TeacherClass(
      id: 'class-len-1a',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      docenteId: 'docente-001',
      docenteNombre: 'Prof. María González',
      materia: 'Lengua Española',
      grado: '1ro de Primaria',
      seccion: 'Sección A',
      aula: 'Aula 101',
      horario: 'Mar y Jue 8:00 - 9:30 AM',
      colorHex: '#047857',
      estudiantes: const [
        ClassStudent(
          id: 'f0000000-0000-0000-0000-000000000001',
          matricula: 'EST-2026-01',
          nombres: 'Mateo',
          apellidos: 'Pérez González',
          tutorNombre: 'Ing. Roberto Pérez',
          tutorTelefono: '809-555-0150',
        ),
        ClassStudent(
          id: 'f0000000-0000-0000-0000-000000000002',
          matricula: 'EST-2026-02',
          nombres: 'Sofía',
          apellidos: 'Pérez González',
          tutorNombre: 'Ing. Roberto Pérez',
          tutorTelefono: '809-555-0150',
        ),
      ],
    ),
    TeacherClass(
      id: 'class-cie-2b',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      docenteId: 'docente-001',
      docenteNombre: 'Prof. María González',
      materia: 'Ciencias de la Naturaleza',
      grado: '2do de Primaria',
      seccion: 'Sección B',
      aula: 'Laboratorio de Ciencias',
      horario: 'Vie 10:00 - 11:30 AM',
      colorHex: '#D97706',
      estudiantes: const [
        ClassStudent(
          id: 'f0000000-0000-0000-0000-000000000003',
          matricula: 'EST-2026-03',
          nombres: 'Lucas',
          apellidos: 'Ramírez Méndez',
          tutorNombre: 'Laura Méndez',
          tutorTelefono: '809-555-0210',
        ),
      ],
    ),
  ];

  static final List<TeacherClass> _demoClasses = List.from(_seedClasses);

  static final List<TeacherEvaluationItem> _seedEvaluations = [
    TeacherEvaluationItem(
      id: 'eval-001',
      classId: 'class-mat-1a',
      periodo: 'P1',
      titulo: 'Práctica #1: Conteo y Operaciones Básicas',
      tipo: 'Tarea',
      porcentaje: 25.0,
      fecha: DateTime(2026, 2, 10),
      calificaciones: {
        'f0000000-0000-0000-0000-000000000001': 95.0,
        'f0000000-0000-0000-0000-000000000002': 90.0,
        'f0000000-0000-0000-0000-000000000003': 88.0,
      },
    ),
    TeacherEvaluationItem(
      id: 'eval-002',
      classId: 'class-mat-1a',
      periodo: 'P1',
      titulo: 'Quiz #1: Razonamiento Lógico',
      tipo: 'Quiz',
      porcentaje: 25.0,
      fecha: DateTime(2026, 2, 24),
      calificaciones: {
        'f0000000-0000-0000-0000-000000000001': 92.0,
        'f0000000-0000-0000-0000-000000000002': 88.0,
        'f0000000-0000-0000-0000-000000000003': 90.0,
      },
    ),
    TeacherEvaluationItem(
      id: 'eval-003',
      classId: 'class-mat-1a',
      periodo: 'P1',
      titulo: 'Proyecto Escolar: Figuras Geométricas 3D',
      tipo: 'Proyecto',
      porcentaje: 25.0,
      fecha: DateTime(2026, 3, 5),
      calificaciones: {
        'f0000000-0000-0000-0000-000000000001': 98.0,
        'f0000000-0000-0000-0000-000000000002': 94.0,
        'f0000000-0000-0000-0000-000000000003': 85.0,
      },
    ),
    TeacherEvaluationItem(
      id: 'eval-004',
      classId: 'class-mat-1a',
      periodo: 'P1',
      titulo: 'Examen de Síntesis del Período 1',
      tipo: 'Examen',
      porcentaje: 25.0,
      fecha: DateTime(2026, 3, 18),
      calificaciones: {
        'f0000000-0000-0000-0000-000000000001': 90.0,
        'f0000000-0000-0000-0000-000000000002': 92.0,
        'f0000000-0000-0000-0000-000000000003': 87.0,
      },
    ),
  ];

  static final List<TeacherEvaluationItem> _demoEvaluations = List.from(_seedEvaluations);

  static final List<StudentBehaviorLog> _seedBehaviorLogs = [
    StudentBehaviorLog(
      id: 'log-001',
      classId: 'class-mat-1a',
      studentId: 'f0000000-0000-0000-0000-000000000001',
      studentName: 'Mateo Pérez González',
      grado: '1ro de Primaria',
      docenteId: 'docente-001',
      docenteNombre: 'Prof. María González',
      tipo: 'Mérito / Felicitación',
      categoria: 'Académico',
      descripcion: 'Destacada participación en el proyecto de geometría y apoyo solidario a sus compañeros.',
      fecha: DateTime(2026, 3, 10),
      notificadoTutor: true,
      notificadoPsicologia: false,
    ),
    StudentBehaviorLog(
      id: 'log-002',
      classId: 'class-mat-1a',
      studentId: 'f0000000-0000-0000-0000-000000000003',
      studentName: 'Lucas Ramírez Méndez',
      grado: '1ro de Primaria',
      docenteId: 'docente-001',
      docenteNombre: 'Prof. María González',
      tipo: 'Llamado de Atención Leve',
      categoria: 'Conductual',
      descripcion: 'Distracción recurrente con juegos de mesa durante la explicación de matemáticas.',
      fecha: DateTime(2026, 3, 14),
      notificadoTutor: true,
      notificadoPsicologia: false,
    ),
  ];

  static final List<StudentBehaviorLog> _demoBehaviorLogs = List.from(_seedBehaviorLogs);

  /// Limpia todo el repositorio para pruebas de QA
  static void clearAllData() {
    _demoClasses.clear();
    _demoEvaluations.clear();
    _demoBehaviorLogs.clear();
  }

  /// Restaura los datos semilla para pruebas
  static void restoreSeedData() {
    _demoClasses
      ..clear()
      ..addAll(_seedClasses);
    _demoEvaluations
      ..clear()
      ..addAll(_seedEvaluations);
    _demoBehaviorLogs
      ..clear()
      ..addAll(_seedBehaviorLogs);
  }

  /// Retorna las asignaturas asignadas al docente
  Future<List<TeacherClass>> getClasses({String? docenteId, String? colegioId}) async {
    final list = _useDemoFallback ? List<TeacherClass>.from(_demoClasses) : List<TeacherClass>.from(_demoClasses);
    if (docenteId != null) {
      return list.where((c) => c.docenteId == docenteId).toList();
    }
    return list;
  }

  /// Obtiene una clase por su ID
  Future<TeacherClass?> getClassById(String classId) async {
    try {
      return _demoClasses.firstWhere((c) => c.id == classId);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene las evaluaciones de una clase y período
  Future<List<TeacherEvaluationItem>> getEvaluations(String classId, {String? periodo}) async {
    return _demoEvaluations.where((e) {
      if (e.classId != classId) return false;
      if (periodo != null && e.periodo != periodo) return false;
      return true;
    }).toList();
  }

  /// Crea un nuevo componente de evaluación
  Future<TeacherEvaluationItem> createEvaluation({
    required String classId,
    required String periodo,
    required String titulo,
    required String tipo,
    required double porcentaje,
    required DateTime fecha,
  }) async {
    final item = TeacherEvaluationItem(
      id: 'eval-${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      periodo: periodo,
      titulo: titulo,
      tipo: tipo,
      porcentaje: porcentaje,
      fecha: fecha,
      calificaciones: {},
    );
    _demoEvaluations.add(item);
    return item;
  }

  /// Guarda las notas de los estudiantes en una evaluación
  Future<void> saveStudentScores(String evaluationId, Map<String, double> scores) async {
    final idx = _demoEvaluations.indexWhere((e) => e.id == evaluationId);
    if (idx != -1) {
      final current = _demoEvaluations[idx];
      final updated = Map<String, double>.from(current.calificaciones)..addAll(scores);
      _demoEvaluations[idx] = current.copyWith(calificaciones: updated);
    }
  }

  /// Calcula el promedio ponderado final del período para cada estudiante de la clase
  Future<Map<String, double>> calculatePeriodAverages(String classId, String periodo) async {
    final evals = await getEvaluations(classId, periodo: periodo);
    final teacherClass = await getClassById(classId);
    if (teacherClass == null || evals.isEmpty) return {};

    final Map<String, double> averages = {};
    for (final student in teacherClass.estudiantes) {
      double totalWeightedScore = 0.0;
      double totalWeight = 0.0;

      for (final ev in evals) {
        final score = ev.calificaciones[student.id];
        if (score != null) {
          totalWeightedScore += (score * (ev.porcentaje / 100.0));
          totalWeight += ev.porcentaje;
        }
      }

      if (totalWeight > 0) {
        // Normalizar a base 100 si los pesos no suman exactamente 100
        averages[student.id] = (totalWeightedScore / totalWeight) * 100.0;
      } else {
        averages[student.id] = 0.0;
      }
    }
    return averages;
  }

  /// Publica las calificaciones del período directamente en el módulo académico del colegio
  Future<void> publishPeriodGradesToAcademic({
    required String classId,
    required String periodo, // 'P1', 'P2', 'P3', 'P4'
    required AcademicRepository academicRepo,
  }) async {
    final teacherClass = await getClassById(classId);
    if (teacherClass == null) return;

    final averages = await calculatePeriodAverages(classId, periodo);
    final periodoNum = int.tryParse(periodo.replaceAll('P', '')) ?? 1;

    for (final entry in averages.entries) {
      final studentId = entry.key;
      final finalGrade = entry.value.round();

      final report = await academicRepo.getReportForStudent(studentId);
      if (report != null) {
        await academicRepo.updateSubjectGrade(
          reportId: report.id,
          materia: teacherClass.materia,
          periodo: periodoNum,
          nota: finalGrade,
        );
      }
    }
  }

  /// Obtiene los registros del observador escolar
  Future<List<StudentBehaviorLog>> getBehaviorLogs({String? classId, String? studentId}) async {
    final list = _demoBehaviorLogs.where((l) {
      if (classId != null && l.classId != classId) return false;
      if (studentId != null && l.studentId != studentId) return false;
      return true;
    }).toList();
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  /// Agrega un nuevo registro al observador escolar
  Future<StudentBehaviorLog> addBehaviorLog({
    required String classId,
    required String studentId,
    required String studentName,
    required String grado,
    required String docenteId,
    required String docenteNombre,
    required String tipo,
    required String categoria,
    required String descripcion,
    bool notificadoTutor = true,
    bool notificadoPsicologia = false,
  }) async {
    final log = StudentBehaviorLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      studentId: studentId,
      studentName: studentName,
      grado: grado,
      docenteId: docenteId,
      docenteNombre: docenteNombre,
      tipo: tipo,
      categoria: categoria,
      descripcion: descripcion,
      fecha: DateTime.now(),
      notificadoTutor: notificadoTutor,
      notificadoPsicologia: notificadoPsicologia,
    );
    _demoBehaviorLogs.insert(0, log);
    return log;
  }

  /// Registra asistencia de la clase para una fecha
  Future<void> recordClassAttendance({
    required String classId,
    required DateTime fecha,
    required Map<String, String> statuses, // studentId -> 'Presente', 'Ausente', 'Tardanza', 'Excusa'
    required AttendanceRepository attendanceRepo,
  }) async {
    final teacherClass = await getClassById(classId);
    if (teacherClass == null) return;

    for (final student in teacherClass.estudiantes) {
      final status = statuses[student.id] ?? 'Presente';
      final record = AttendanceRecord(
        id: 'att-${student.id}-${fecha.year}${fecha.month}${fecha.day}',
        estudianteId: student.id,
        estudianteNombre: student.nombreCompleto,
        matricula: student.matricula,
        familiaId: 'fam-${student.id}',
        colegioId: teacherClass.colegioId,
        gradoNombre: teacherClass.grado,
        seccionNombre: teacherClass.seccion,
        fecha: fecha,
        estado: status,
        horaLlegada: status == 'Tardanza' ? '08:20 AM' : (status == 'Presente' ? '07:50 AM' : null),
        observacion: 'Pase de lista en ${teacherClass.materia}',
        notificadoATutor: status != 'Presente',
      );
      await attendanceRepo.saveAttendanceRecords([record]);
    }
  }
}
