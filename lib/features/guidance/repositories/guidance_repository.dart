import '../models/guidance_case.dart';
import '../../teacher_portal/models/student_behavior_log.dart';

/// Repositorio para la Gestión de Psicología, Orientación Escolar y Convivencia
class GuidanceRepository {
  final bool _useDemoFallback;

  GuidanceRepository({bool useDemoFallback = false}) : _useDemoFallback = useDemoFallback;

  static final List<GuidanceCase> _seedCases = [
    GuidanceCase(
      id: 'case-001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      studentId: 'f0000000-0000-0000-0000-000000000001',
      studentName: 'Mateo Pérez González',
      matricula: 'EST-2026-01',
      grado: '1ro de Primaria',
      seccion: 'Sección A',
      remitidoPor: 'Prof. María González (Matemáticas)',
      motivoRemision: 'Dificultades notorias de concentración en actividades prolongadas y frustración ante cálculos complejos.',
      fechaRemision: DateTime(2026, 3, 10),
      estado: 'En Intervención',
      nivelUrgencia: 'Media',
      diagnosticoSugerido: 'Rasgos de déficit atencional leve; requiere refuerzo en pausas activas.',
      sesiones: [
        GuidanceSession(
          id: 'ses-001',
          fecha: DateTime(2026, 3, 12, 10, 30),
          tipo: 'Individual con Alumno',
          notasConfidenciales: 'Mateo muestra excelente disposición verbal. Se distrae con facilidad ante estímulos auditivos del pasillo.',
          acuerdos: 'Implementar técnica del reloj visual para tareas de 15 minutos en aula.',
          profesionalACargo: 'Lic. Laura Medina (Psicóloga Escolar)',
        ),
        GuidanceSession(
          id: 'ses-002',
          fecha: DateTime(2026, 3, 18, 9, 0),
          tipo: 'Observación Áulica',
          notasConfidenciales: 'Ubicación en primera fila mejoró su contacto visual con la docente y disminuyó la dispersión.',
          acuerdos: 'Mantener pupitre en zona de baja distracción y validar instrucciones de forma personal.',
          profesionalACargo: 'Lic. Laura Medina (Psicóloga Escolar)',
        ),
      ],
      citasPadres: [
        ParentInterview(
          id: 'cita-001',
          fecha: DateTime(2026, 3, 22),
          hora: '03:30 PM',
          modalidad: 'Presencial',
          motivo: 'Entrevista de socialización de acuerdos psicopedagógicos y hábitos de estudio en el hogar.',
          estado: 'Programada',
          conclusiones: null,
        ),
      ],
      compromisos: [
        ConvivenciaAgreement(
          id: 'comp-001',
          fecha: DateTime(2026, 3, 12),
          descripcion: 'Ubicación preferencial en primera fila cerca de la pizarra',
          responsable: 'Docente',
          cumplido: true,
        ),
        ConvivenciaAgreement(
          id: 'comp-002',
          fecha: DateTime(2026, 3, 12),
          descripcion: 'Pausas sensoriales de 2 minutos tras bloques de cálculo',
          responsable: 'Colegio',
          cumplido: true,
        ),
        ConvivenciaAgreement(
          id: 'comp-003',
          fecha: DateTime(2026, 3, 15),
          descripcion: 'Establecer horario fijo de lectura de 20 min en casa sin pantallas',
          responsable: 'Padres / Tutores',
          cumplido: false,
        ),
      ],
    ),
    GuidanceCase(
      id: 'case-002',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      studentId: 'f0000000-0000-0000-0000-000000000003',
      studentName: 'Lucas Gómez',
      matricula: 'EST-2026-03',
      grado: '2do de Primaria',
      seccion: 'Sección B',
      remitidoPor: 'Prof. Carlos Ramírez (Ciencias)',
      motivoRemision: 'Altercado físico durante el recreo y conducta desafiante recurrente con pares en el patio.',
      fechaRemision: DateTime(2026, 3, 14),
      estado: 'Citación a Tutores',
      nivelUrgencia: 'Alta',
      diagnosticoSugerido: 'Dificultad en autorregulación emocional y resolución asertiva de conflictos.',
      sesiones: [
        GuidanceSession(
          id: 'ses-003',
          fecha: DateTime(2026, 3, 15, 11, 0),
          tipo: 'Individual con Alumno',
          notasConfidenciales: 'Lucas relata sentirse abrumado ante juegos competitivos. Reconoce el error y pide disculpas.',
          acuerdos: 'Técnicas de respiración y mediación guiada con el compañero.',
          profesionalACargo: 'Lic. Laura Medina (Psicóloga Escolar)',
        ),
      ],
      citasPadres: [
        ParentInterview(
          id: 'cita-002',
          fecha: DateTime(2026, 3, 21),
          hora: '08:00 AM',
          modalidad: 'Presencial',
          motivo: 'Firma de Acta de Convivencia Escolar y protocolo de seguimiento conductual.',
          estado: 'Programada',
          conclusiones: null,
        ),
      ],
      compromisos: [
        ConvivenciaAgreement(
          id: 'comp-004',
          fecha: DateTime(2026, 3, 15),
          descripcion: 'Participación en taller de habilidades socioemocionales de recreo',
          responsable: 'Estudiante',
          cumplido: false,
        ),
        ConvivenciaAgreement(
          id: 'comp-005',
          fecha: DateTime(2026, 3, 15),
          descripcion: 'Acompañamiento psicológico externo si los episodios persisten',
          responsable: 'Padres / Tutores',
          cumplido: false,
        ),
      ],
    ),
  ];

  static final List<GuidanceCase> _demoCases = List<GuidanceCase>.from(_seedCases);

  /// Limpia todos los registros para pruebas de QA Clean Slate
  static void clearAllData() {
    _demoCases.clear();
  }

  /// Restaura los datos semilla para QA y testing
  static void restoreSeedData() {
    _demoCases
      ..clear()
      ..addAll(_seedCases);
  }

  /// Consulta casos psicopedagógicos con filtros opcionales
  Future<List<GuidanceCase>> getCases({
    String? colegioId,
    String? estado,
    String? urgencia,
    String? searchQuery,
  }) async {
    if (!_useDemoFallback) return [];
    return _demoCases.where((c) {
      if (colegioId != null && c.colegioId != colegioId) return false;
      if (estado != null && estado != 'Todos' && c.estado != estado) return false;
      if (urgencia != null && urgencia != 'Todas' && c.nivelUrgencia != urgencia) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final match = c.studentName.toLowerCase().contains(q) ||
            c.matricula.toLowerCase().contains(q) ||
            c.grado.toLowerCase().contains(q) ||
            c.motivoRemision.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  /// Obtiene un caso por su ID
  Future<GuidanceCase?> getCaseById(String id) async {
    try {
      return _demoCases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Registra un nuevo caso directamente
  Future<GuidanceCase> createCase({
    required String colegioId,
    required String studentId,
    required String studentName,
    required String matricula,
    required String grado,
    required String seccion,
    required String remitidoPor,
    required String motivoRemision,
    String nivelUrgencia = 'Media',
    String? diagnosticoSugerido,
  }) async {
    final newCase = GuidanceCase(
      id: 'case-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      studentId: studentId,
      studentName: studentName,
      matricula: matricula,
      grado: grado,
      seccion: seccion,
      remitidoPor: remitidoPor,
      motivoRemision: motivoRemision,
      fechaRemision: DateTime.now(),
      estado: 'En Evaluación',
      nivelUrgencia: nivelUrgencia,
      diagnosticoSugerido: diagnosticoSugerido,
    );

    _demoCases.insert(0, newCase);
    return newCase;
  }

  /// Genera o vincula un caso de orientación a partir de un reporte de observador docente
  Future<GuidanceCase> createCaseFromTeacherLog({
    required StudentBehaviorLog log,
    required String colegioId,
    required String matricula,
    required String seccion,
    String nivelUrgencia = 'Alta',
  }) async {
    // Si ya existe un caso activo para este estudiante, lo reutilizamos
    final existingIdx = _demoCases.indexWhere((c) => c.studentId == log.studentId && c.esActivo);
    if (existingIdx != -1) {
      final existing = _demoCases[existingIdx];
      final updated = existing.copyWith(
        motivoRemision: '${existing.motivoRemision}\n[Remisión Adicional]: ${log.descripcion}',
        nivelUrgencia: nivelUrgencia == 'Alta' ? 'Alta' : existing.nivelUrgencia,
      );
      _demoCases[existingIdx] = updated;
      return updated;
    }

    return createCase(
      colegioId: colegioId,
      studentId: log.studentId,
      studentName: log.studentName,
      matricula: matricula,
      grado: log.grado,
      seccion: seccion,
      remitidoPor: '${log.docenteNombre} (Observador Docente)',
      motivoRemision: log.descripcion,
      nivelUrgencia: nivelUrgencia,
    );
  }

  /// Registra una sesión confidencial en el expediente
  Future<GuidanceCase> addSession(String caseId, GuidanceSession session) async {
    final idx = _demoCases.indexWhere((c) => c.id == caseId);
    if (idx == -1) throw Exception('Caso de orientación no encontrado');

    final current = _demoCases[idx];
    final updated = current.copyWith(
      sesiones: [session, ...current.sesiones],
      estado: current.estado == 'En Evaluación' ? 'En Intervención' : current.estado,
    );

    _demoCases[idx] = updated;
    return updated;
  }

  /// Agenda una entrevista / cita con los tutores
  Future<GuidanceCase> scheduleParentInterview(String caseId, ParentInterview interview) async {
    final idx = _demoCases.indexWhere((c) => c.id == caseId);
    if (idx == -1) throw Exception('Caso de orientación no encontrado');

    final current = _demoCases[idx];
    final updated = current.copyWith(
      citasPadres: [interview, ...current.citasPadres],
      estado: 'Citación a Tutores',
    );

    _demoCases[idx] = updated;
    return updated;
  }

  /// Actualiza el estado o conclusiones de una entrevista a padres
  Future<GuidanceCase> updateParentInterviewStatus(
    String caseId,
    String interviewId,
    String newStatus, {
    String? conclusiones,
  }) async {
    final idx = _demoCases.indexWhere((c) => c.id == caseId);
    if (idx == -1) throw Exception('Caso no encontrado');

    final current = _demoCases[idx];
    final updatedCitas = current.citasPadres.map((cita) {
      if (cita.id == interviewId) {
        return cita.copyWith(
          estado: newStatus,
          conclusiones: conclusiones ?? cita.conclusiones,
        );
      }
      return cita;
    }).toList();

    final updated = current.copyWith(citasPadres: updatedCitas);
    _demoCases[idx] = updated;
    return updated;
  }

  /// Agrega un compromiso al plan de convivencia
  Future<GuidanceCase> addAgreement(String caseId, ConvivenciaAgreement agreement) async {
    final idx = _demoCases.indexWhere((c) => c.id == caseId);
    if (idx == -1) throw Exception('Caso no encontrado');

    final current = _demoCases[idx];
    final updated = current.copyWith(
      compromisos: [...current.compromisos, agreement],
    );

    _demoCases[idx] = updated;
    return updated;
  }

  /// Alterna el estado de cumplimiento de un acuerdo
  Future<GuidanceCase> toggleAgreementStatus(String caseId, String agreementId) async {
    final idx = _demoCases.indexWhere((c) => c.id == caseId);
    if (idx == -1) throw Exception('Caso no encontrado');

    final current = _demoCases[idx];
    final updatedAgreements = current.compromisos.map((a) {
      if (a.id == agreementId) {
        return a.copyWith(cumplido: !a.cumplido);
      }
      return a;
    }).toList();

    final updated = current.copyWith(compromisos: updatedAgreements);
    _demoCases[idx] = updated;
    return updated;
  }

  /// Modifica el estado global del caso
  Future<GuidanceCase> updateCaseStatus(String caseId, String nuevoEstado) async {
    final idx = _demoCases.indexWhere((c) => c.id == caseId);
    if (idx == -1) throw Exception('Caso no encontrado');

    final current = _demoCases[idx];
    final updated = current.copyWith(estado: nuevoEstado);
    _demoCases[idx] = updated;
    return updated;
  }

  /// Estadísticas consolidadas para el Dashboard del Colegio
  Future<Map<String, dynamic>> getStats(String colegioId) async {
    final cases = await getCases(colegioId: colegioId);
    final total = cases.length;
    final activos = cases.where((c) => c.esActivo).length;
    final urgentes = cases.where((c) => c.esUrgente && c.esActivo).length;
    
    int totalCitas = 0;
    int citasPendientes = 0;
    int totalCompromisos = 0;
    int compromisosCumplidos = 0;

    for (final c in cases) {
      totalCitas += c.citasPadres.length;
      citasPendientes += c.citasPadres.where((ci) => ci.estado == 'Programada').length;
      totalCompromisos += c.compromisos.length;
      compromisosCumplidos += c.compromisos.where((co) => co.cumplido).length;
    }

    final tasaCumplimiento = totalCompromisos > 0
        ? (compromisosCumplidos / totalCompromisos) * 100
        : 100.0;

    return {
      'totalCasos': total,
      'casosActivos': activos,
      'casosUrgenciaAlta': urgentes,
      'citasPendientes': citasPendientes,
      'totalCitas': totalCitas,
      'tasaCumplimientoAcuerdos': tasaCumplimiento,
    };
  }
}
