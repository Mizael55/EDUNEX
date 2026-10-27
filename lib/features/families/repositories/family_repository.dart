import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../models/student_document.dart';
import '../models/tutor.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/user_role.dart';
import '../../parent_portal/models/payment_receipt.dart';
import '../../parent_portal/models/payment_agreement_request.dart';
import '../../parent_portal/models/parent_question.dart';
import '../../finances/models/billing_models.dart';
import '../../finances/models/payment_approval_request.dart';

/// Repositorio de Cuentas Familiares y Estudiantes en EDUNEX
class FamilyRepository {
  static const String _storageKeyCustomFamilies = 'edunex_custom_families_v1';

  static SupabaseClient? _resolveClient() {
    try {
      if (SupabaseConfig.isConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  final SupabaseClient? _supabaseClient;
  final bool _useDemoFallback;

  FamilyRepository({
    SupabaseClient? supabaseClient,
    this._useDemoFallback = false,
  }) : _supabaseClient = supabaseClient ?? _resolveClient();

  /// Persistencia local en SharedPreferences para garantizar cero pérdida de datos en QA
  static bool _prefsLoaded = false;

  static Future<void> _persistCustomFamilies() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 500));
      final listJson = jsonEncode(_customFamilies.map((f) => f.toJson()).toList());
      await prefs.setString(_storageKeyCustomFamilies, listJson);
    } catch (e) {
      debugPrint('Aviso: No se pudo persistir familias localmente: $e');
    }
  }

  static Future<void> _loadPersistedCustomFamilies() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 500));
      _prefsLoaded = true;
      final listJson = prefs.getString(_storageKeyCustomFamilies);
      if (listJson != null && listJson.isNotEmpty) {
        final List decoded = jsonDecode(listJson) as List;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final f = Family.fromJson(item);
            if (!_customFamilies.any((existing) => existing.id == f.id)) {
              _customFamilies.add(f);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso: Error cargando familias de SharedPreferences: $e');
    }
  }

  /// Lista de familias de demostración para fallback fuera de línea y tests
  static final List<Family> _demoFamilies = List.from(_seedFamilies);

  /// Limpia todas las familias y solicitudes en memoria y almacenamiento para QA
  static void clearAllData() {
    _demoFamilies.clear();
    _customFamilies.clear();
    _abonoApprovalRequests.clear();
    _receipts.clear();
    _agreements.clear();
    _questions.clear();
    _billingRuns.clear();
    _prefsLoaded = false;
    try {
      SharedPreferences.getInstance()
          .then((prefs) => prefs.remove(_storageKeyCustomFamilies))
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {}
  }

  /// Restaura las familias piloto para pruebas y modo demo
  static void restoreSeedData() {
    _demoFamilies.clear();
    _demoFamilies.addAll(_seedFamilies);
    _customFamilies.clear();
    _prefsLoaded = false;
  }

  static final List<Family> _seedFamilies = [
    Family(
      id: 'e0000000-0000-0000-0000-000000000001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      codigoFamilia: 'FAM-2026-001',
      nombreFamilia: 'Familia Pérez González',
      balancePendiente: 7500.00,
      telefonoPrincipal: '809-555-0150',
      emailPrincipal: 'familia@edunex.edu',
      direccion: 'Calle Los Prados #12, Ensanche Naco, Santo Domingo',
      activo: true,
      tutores: const [
        Tutor(
          id: 'tutor-1',
          familiaId: 'e0000000-0000-0000-0000-000000000001',
          nombres: 'Roberto',
          apellidos: 'Pérez',
          parentesco: 'Padre',
          cedulaOPasaporte: '001-1234567-8',
          telefono: '809-555-0150',
          email: 'familia@edunex.edu',
          esContactoPrincipal: true,
          autorizadoRecoger: true,
        ),
        Tutor(
          id: 'tutor-2',
          familiaId: 'e0000000-0000-0000-0000-000000000001',
          nombres: 'Carmen',
          apellidos: 'González de Pérez',
          parentesco: 'Madre',
          cedulaOPasaporte: '001-8765432-1',
          telefono: '809-555-0151',
          email: 'carmen.gonzalez@gmail.com',
          esContactoPrincipal: false,
          autorizadoRecoger: true,
        ),
      ],
      estudiantes: [
        Student(
          id: 'f0000000-0000-0000-0000-000000000001',
          colegioId: 'a0000000-0000-0000-0000-000000000001',
          familiaId: 'e0000000-0000-0000-0000-000000000001',
          matricula: 'EST-2026-01',
          nombres: 'Mateo',
          apellidos: 'Pérez González',
          fechaNacimiento: DateTime(2019, 5, 14),
          genero: 'Masculino',
          gradoNombre: '1ro de Primaria',
          seccionNombre: 'Sección A',
          serviciosActivos: const ['Cuido Tarde (3:00-6:00 PM)', 'Ruta 1 Naco-Piantini'],
        ),
        Student(
          id: 'f0000000-0000-0000-0000-000000000002',
          colegioId: 'a0000000-0000-0000-0000-000000000001',
          familiaId: 'e0000000-0000-0000-0000-000000000001',
          matricula: 'EST-2026-02',
          nombres: 'Sofía',
          apellidos: 'Pérez González',
          fechaNacimiento: DateTime(2021, 8, 20),
          genero: 'Femenino',
          gradoNombre: 'Kinder',
          seccionNombre: 'Sección A',
          serviciosActivos: const ['Cuido Tarde (3:00-6:00 PM)'],
        ),
      ],
    ),
    Family(
      id: 'e0000000-0000-0000-0000-000000000002',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      codigoFamilia: 'FAM-2026-002',
      nombreFamilia: 'Familia Ramírez Méndez',
      balancePendiente: 0.00,
      telefonoPrincipal: '809-555-0210',
      emailPrincipal: 'ramirez.mendez@outlook.com',
      direccion: 'Av. Sarasota #45, Bella Vista, Santo Domingo',
      activo: true,
      tutores: const [
        Tutor(
          id: 'tutor-3',
          familiaId: 'e0000000-0000-0000-0000-000000000002',
          nombres: 'Laura',
          apellidos: 'Méndez',
          parentesco: 'Madre',
          cedulaOPasaporte: '001-3456789-0',
          telefono: '809-555-0210',
          email: 'ramirez.mendez@outlook.com',
          esContactoPrincipal: true,
          autorizadoRecoger: true,
        ),
      ],
      estudiantes: [
        Student(
          id: 'f0000000-0000-0000-0000-000000000003',
          colegioId: 'a0000000-0000-0000-0000-000000000001',
          familiaId: 'e0000000-0000-0000-0000-000000000002',
          matricula: 'EST-2026-03',
          nombres: 'Diego',
          apellidos: 'Ramírez Méndez',
          fechaNacimiento: DateTime(2018, 2, 10),
          genero: 'Masculino',
          gradoNombre: '2do de Primaria',
          seccionNombre: 'Sección B',
          serviciosActivos: const ['Ruta 2 Bella Vista'],
        ),
      ],
    ),
    Family(
      id: 'e0000000-0000-0000-0000-000000000003',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      codigoFamilia: 'FAM-2026-003',
      nombreFamilia: 'Familia Castillo Almonte',
      balancePendiente: 12400.00,
      telefonoPrincipal: '829-555-0344',
      emailPrincipal: 'castillo.almonte@gmail.com',
      direccion: 'C/ Federico Geraldino #88, Piantini, Santo Domingo',
      activo: true,
      tutores: const [
        Tutor(
          id: 'tutor-4',
          familiaId: 'e0000000-0000-0000-0000-000000000003',
          nombres: 'Carlos',
          apellidos: 'Castillo',
          parentesco: 'Padre',
          cedulaOPasaporte: '402-1122334-5',
          telefono: '829-555-0344',
          email: 'castillo.almonte@gmail.com',
          esContactoPrincipal: true,
          autorizadoRecoger: true,
        ),
      ],
      estudiantes: [
        Student(
          id: 'f0000000-0000-0000-0000-000000000004',
          colegioId: 'a0000000-0000-0000-0000-000000000001',
          familiaId: 'e0000000-0000-0000-0000-000000000003',
          matricula: 'EST-2026-04',
          nombres: 'Camila',
          apellidos: 'Castillo Almonte',
          fechaNacimiento: DateTime(2020, 11, 05),
          genero: 'Femenino',
          gradoNombre: 'Maternal',
          seccionNombre: 'Sección A',
          serviciosActivos: const ['Cuido Mañana (7:00-8:00 AM)', 'Cuido Extendido (3:00-7:00 PM)'],
        ),
      ],
    ),
  ];

  /// Obtiene la lista de familias aplicando filtros opcionales de búsqueda, balance y colegio
  Future<List<Family>> getFamilies({
    String? searchQuery,
    bool onlyWithDebt = false,
    String? colegioId,
  }) async {
    await _loadPersistedCustomFamilies();
    List<Family> families = [];

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        var query = _supabaseClient
            .from('familias')
            .select('''
              *,
              tutores (*),
              estudiantes (
                *,
                documentos_estudiante (*),
                secciones (
                  nombre,
                  grados (nombre)
                )
              )
            ''');
        if (colegioId != null && colegioId.isNotEmpty) {
          query = query.eq('colegio_id', colegioId);
        }
        final response = await query.order('nombre_familia', ascending: true);

        families = (response as List)
            .map((item) => Family.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Aviso: Usando datos de respaldo para familias: $e');
        families = _useDemoFallback ? List<Family>.from(_demoFamilies) : [];
      }
    } else {
      families = _useDemoFallback ? List<Family>.from(_demoFamilies) : [];
    }

    if (_customFamilies.isNotEmpty) {
      for (final cf in _customFamilies) {
        final existingIdx = families.indexWhere((f) => f.id == cf.id);
        if (existingIdx != -1) {
          families[existingIdx] = cf;
        } else {
          families.insert(0, cf);
        }
      }
    }

    // Filtrar por colegio si se especificó (Issue #16)
    if (colegioId != null && colegioId.isNotEmpty) {
      families = families.where((f) => f.colegioId == colegioId).toList();
    }

    // Filtrar según query
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      families = families.where((f) {
        final matchFamily = f.nombreFamilia.toLowerCase().contains(q) ||
            f.codigoFamilia.toLowerCase().contains(q) ||
            (f.telefonoPrincipal?.contains(q) ?? false);
        final matchTutor = f.tutores.any(
            (t) => t.nombreCompleto.toLowerCase().contains(q) || (t.telefono?.contains(q) ?? false));
        final matchEstudiante = f.estudiantes.any(
            (e) => e.nombreCompleto.toLowerCase().contains(q) || e.matricula.toLowerCase().contains(q));
        return matchFamily || matchTutor || matchEstudiante;
      }).toList();
    }

    // Filtrar sólo con balance pendiente si se especifica
    if (onlyWithDebt) {
      families = families.where((f) => !f.estaAlDia).toList();
    }

    return families;
  }

  /// Genera familias y estudiantes iniciales para un colegio nuevo (Issue #16)
  /// asegurando que la parte de administración del centro cuente de inmediato con comunidad escolar
  static Future<void> seedInitialFamiliesForSchool({
    required String schoolId,
    required String schoolName,
  }) async {
    await _loadPersistedCustomFamilies();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 9000) + 1000;

    final fam1 = Family(
      id: 'fam-$schoolId-01',
      colegioId: schoolId,
      codigoFamilia: 'FAM-2026-$randomSuffix',
      nombreFamilia: 'Familia Morales Peña',
      balancePendiente: 6500.0,
      telefonoPrincipal: '809-555-4321',
      emailPrincipal: 'morales.pena@ejemplo.edu.do',
      direccion: 'Av. Las Palmas #45, Ensanche Naco',
      activo: true,
      tutores: [
        Tutor(
          id: 'tut-$schoolId-01',
          familiaId: 'fam-$schoolId-01',
          nombres: 'Eduardo',
          apellidos: 'Morales',
          parentesco: 'Padre',
          cedulaOPasaporte: '001-0987654-3',
          telefono: '809-555-4321',
          email: 'morales.pena@ejemplo.edu.do',
          esContactoPrincipal: true,
          autorizadoRecoger: true,
        ),
      ],
      estudiantes: [
        Student(
          id: 'est-$schoolId-01',
          colegioId: schoolId,
          familiaId: 'fam-$schoolId-01',
          matricula: 'EST-2026-${randomSuffix + 1}',
          nombres: 'Lucas',
          apellidos: 'Morales Peña',
          fechaNacimiento: DateTime(2019, 4, 12),
          gradoNombre: '1ro de Primaria',
          seccionNombre: 'Sección A',
          tipoSangre: 'O+',
          seguroMedico: 'ARS Universal',
          serviciosActivos: const ['Transporte Escolar'],
          documentosExpediente: [
            StudentDocument(
              id: 'doc-$schoolId-01',
              tipo: 'Acta de Nacimiento',
              nombreArchivo: 'acta_nacimiento_lucas.pdf',
              tamanoBytes: 1024 * 720,
              fechaSubida: DateTime.now(),
              verificado: true,
            ),
          ],
        ),
      ],
    );

    final fam2 = Family(
      id: 'fam-$schoolId-02',
      colegioId: schoolId,
      codigoFamilia: 'FAM-2026-${randomSuffix + 10}',
      nombreFamilia: 'Familia Castillo Almonte',
      balancePendiente: 0.0,
      telefonoPrincipal: '809-555-8765',
      emailPrincipal: 'castillo.almonte@ejemplo.edu.do',
      direccion: 'Calle Sol Poniente #12',
      activo: true,
      tutores: [
        Tutor(
          id: 'tut-$schoolId-02',
          familiaId: 'fam-$schoolId-02',
          nombres: 'Patricia',
          apellidos: 'Almonte',
          parentesco: 'Madre',
          cedulaOPasaporte: '001-1122334-5',
          telefono: '809-555-8765',
          email: 'castillo.almonte@ejemplo.edu.do',
          esContactoPrincipal: true,
          autorizadoRecoger: true,
        ),
      ],
      estudiantes: [
        Student(
          id: 'est-$schoolId-02',
          colegioId: schoolId,
          familiaId: 'fam-$schoolId-02',
          matricula: 'EST-2026-${randomSuffix + 11}',
          nombres: 'Sofía',
          apellidos: 'Castillo Almonte',
          fechaNacimiento: DateTime(2021, 6, 20),
          gradoNombre: 'Kinder',
          seccionNombre: 'Sección B',
          tipoSangre: 'A+',
          serviciosActivos: const ['Cuido Vespertino'],
        ),
      ],
    );

    for (final f in [fam1, fam2]) {
      final idx = _customFamilies.indexWhere((existing) => existing.id == f.id);
      if (idx != -1) {
        _customFamilies[idx] = f;
      } else {
        _customFamilies.add(f);
      }
    }
    await _persistCustomFamilies();
  }

  /// Retorna una familia por su ID
  Future<Family?> getFamilyById(String id) async {
    final list = await getFamilies();
    try {
      return list.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retorna todos los estudiantes registrados en las familias del centro educativo (Issue #21 - Caso 2 y 3)
  Future<List<Student>> getAllRegisteredStudents({String? colegioId}) async {
    final families = await getFamilies(colegioId: colegioId);
    final List<Student> students = [];
    for (final fam in families) {
      if (fam.activo) {
        students.addAll(fam.estudiantes);
      }
    }
    if (students.isEmpty && _useDemoFallback) {
      for (final fam in _seedFamilies) {
        if (fam.activo) {
          students.addAll(fam.estudiantes);
        }
      }
    }
    return students;
  }

  /// Retorna la familia asociada al usuario autenticado (para portal de padres)
  Future<Family?> getFamilyForCurrentUser({String? email, String? colegioId}) async {
    final list = await getFamilies();
    final cleanEmail = email?.trim().toLowerCase();

    // 1. Buscar coincidencia exacta por correo del tutor o correo principal (Issue #16)
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      try {
        return list.firstWhere(
          (f) =>
              (f.emailPrincipal?.toLowerCase() == cleanEmail ||
                  f.tutores.any((t) => t.email?.toLowerCase() == cleanEmail)) &&
              (colegioId == null || f.colegioId == colegioId),
        );
      } catch (_) {}

      try {
        return list.firstWhere(
          (f) =>
              f.emailPrincipal?.toLowerCase() == cleanEmail ||
              f.tutores.any((t) => t.email?.toLowerCase() == cleanEmail),
        );
      } catch (_) {}

      // Si el tutor tiene un correo específico pero no está enrolado en este centro, no mostrar familias ajenas
      return null;
    }

    // 2. Solo si no se especificó correo (modo demo o pruebas), retornar primera familia del centro
    if (list.isNotEmpty) {
      if (colegioId != null) {
        try {
          return list.firstWhere((f) => f.colegioId == colegioId);
        } catch (_) {}
      }
      return list.first;
    }

    return null;
  }

  /// Lista en memoria para familias creadas durante la sesión
  static final List<Family> _customFamilies = [];

  /// Comprobantes de pago oficiales registrados
  static final List<PaymentReceipt> _receipts = [
    PaymentReceipt(
      id: 'rec-001',
      numeroComprobante: 'REC-2026-0089',
      ncf: 'B0200000142',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      nombreFamilia: 'Familia Pérez González',
      fechaEmision: DateTime(2026, 2, 5, 10, 30),
      concepto: 'Colegiatura Febrero 2026 & Servicios Escolares',
      monto: 18500.00,
      metodoPago: 'Tarjeta de Crédito / CardNET',
      referencia: 'AUTH-982341',
      estado: 'Válido / Pagado',
      estudiantes: const ['Mateo Pérez', 'Sofía Pérez'],
    ),
    PaymentReceipt(
      id: 'rec-002',
      numeroComprobante: 'REC-2026-0045',
      ncf: 'B0200000098',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      nombreFamilia: 'Familia Pérez González',
      fechaEmision: DateTime(2026, 1, 10, 15, 12),
      concepto: 'Colegiatura Enero 2026 & Matrícula Anual',
      monto: 25000.00,
      metodoPago: 'Transferencia Bancaria BHD',
      referencia: 'TRF-458129',
      estado: 'Válido / Pagado',
      estudiantes: const ['Mateo Pérez', 'Sofía Pérez'],
    ),
  ];

  /// Solicitudes de acuerdos o convenios de pago
  static final List<PaymentAgreementRequest> _agreements = [
    PaymentAgreementRequest(
      id: 'agr-001',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      nombreFamilia: 'Familia Pérez González',
      tipoAcuerdo: 'Fraccionamiento de Cuota de Colegiatura',
      propuestaCuota: 3750.00,
      justificacion: 'Solicitud de división en 2 quincenas para la colegiatura mensual por reestructuración de ingresos.',
      fechaSolicitud: DateTime(2026, 2, 1, 9, 0),
      estado: 'Aprobado',
      respuestaCentro: 'Aprobado por el Consejo Directivo. Cuotas de RD\$ 3,750 los días 15 y 30 de cada mes.',
      fechaRespuesta: DateTime(2026, 2, 3, 14, 20),
    ),
    PaymentAgreementRequest(
      id: 'agr-002',
      familiaId: 'e0000000-0000-0000-0000-000000000003',
      nombreFamilia: 'Familia Castillo Almonte',
      tipoAcuerdo: 'Prórroga de Colegiatura & Servicios',
      propuestaCuota: 6200.00,
      justificacion: 'Solicitud de prórroga para pagar el saldo acumulado en dos cuotas iguales a fin de mes.',
      fechaSolicitud: DateTime(2026, 2, 14, 11, 40),
      estado: 'En revisión por Dirección',
    ),
  ];

  /// Preguntas y consultas directas de tutores
  static final List<ParentQuestion> _questions = [
    ParentQuestion(
      id: 'qst-001',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      tutorNombre: 'Roberto Pérez',
      departamento: 'Dirección Académica',
      asunto: 'Horario extendido de evaluaciones bimestrales',
      mensaje: 'Buenas tardes, quisiéramos confirmar si las pruebas del segundo bimestre tendrán salida temprana o continuará el horario habitual de cuido.',
      fechaEnvio: DateTime(2026, 2, 10, 11, 20),
      estado: 'Respondida',
      respuestaCentro: 'Estimado Roberto, las evaluaciones se impartirán en el horario regular matutino. El servicio de cuido vespertino operará con normalidad hasta las 6:00 PM.',
      fechaRespuesta: DateTime(2026, 2, 10, 16, 45),
      respondidoPor: 'Lic. Carmen Morales (Coord. Académica)',
    ),
    ParentQuestion(
      id: 'qst-002',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      tutorNombre: 'Roberto Pérez',
      departamento: 'Caja y Facturación',
      asunto: 'Comprobante fiscal con valor crediticio',
      mensaje: 'Saludos, por favor requerimos que la próxima factura sea emitida con comprobante fiscal gubernamental para nuestra empresa.',
      fechaEnvio: DateTime(2026, 2, 12, 14, 05),
      estado: 'En trámite',
    ),
    ParentQuestion(
      id: 'qst-003',
      familiaId: 'e0000000-0000-0000-0000-000000000003',
      tutorNombre: 'Carlos Castillo',
      departamento: 'Psicología y Orientación',
      asunto: 'Cita de seguimiento psicopedagógico para Camila',
      mensaje: 'Hola cordiales. Deseamos coordinar una reunión presencial con la psicóloga escolar para revisar los avances de adaptación de Camila en Maternal.',
      fechaEnvio: DateTime(2026, 2, 14, 9, 30),
      estado: 'En trámite',
    ),
    ParentQuestion(
      id: 'qst-004',
      familiaId: 'e0000000-0000-0000-0000-000000000002',
      tutorNombre: 'Laura Méndez',
      departamento: 'Secretaría Escolar',
      asunto: 'Solicitud de récord de notas y constancia de matrícula',
      mensaje: 'Buenos días, necesito una constancia de inscripción oficial timbrada para el trámite de seguro médico familiar de Diego.',
      fechaEnvio: DateTime(2026, 2, 15, 10, 15),
      estado: 'Respondida',
      respuestaCentro: 'Estimada Laura, el documento timbrado está listo para retiro en recepción o puede descargarlo firmado digitalmente en el portal.',
      fechaRespuesta: DateTime(2026, 2, 15, 15, 00),
      respondidoPor: 'Secretaría General EDUNEX',
    ),
  ];

  /// Registra una nueva familia con su tutor, documentos físicos, múltiples alumnos y acuerdos de pago
  Future<Family> createFamily({
    required String colegioId,
    required String nombreFamilia,
    required String tutorNombres,
    required String tutorApellidos,
    required String tutorEmail,
    required String tutorTelefono,
    String? parentesco,
    String? cedula,
    String? direccion,
    String? ocupacion,
    String? lugarTrabajo,
    String? telefonoTrabajo,
    String? ingresosAproximados,
    bool cartaTrabajoAdjunta = false,
    bool estadosFinancierosAdjuntos = false,
    bool copiaCedulaAdjunta = false,
    List<String> otrosDocumentos = const [],
    List<StudentDocument>? tutorDocumentos,
    double balanceInicial = 0.0,
    String? estudianteNombres,
    String? estudianteApellidos,
    String? gradoNombre,
    List<Student>? multipleStudents,
    List<Tutor>? additionalTutors,
    String modalidadPago = 'mensual',
    double descuentoAcordadoPct = 0.0,
    String? notaAcuerdoPago,
    List<String> criteriosCentroAdicionales = const [],
  }) async {
    final now = DateTime.now();
    final uniqueSuffix = now.millisecondsSinceEpoch.toString().substring(8);
    final codigoFamilia = 'FAM-${now.year}-$uniqueSuffix';
    final familyId = 'fam-${now.millisecondsSinceEpoch}';
    final tutorId = 'tut-${now.millisecondsSinceEpoch}';

    final newTutor = Tutor(
      id: tutorId,
      familiaId: familyId,
      nombres: tutorNombres,
      apellidos: tutorApellidos,
      parentesco: parentesco ?? 'Tutor Legal',
      cedulaOPasaporte: cedula,
      telefono: tutorTelefono,
      email: tutorEmail,
      esContactoPrincipal: true,
      autorizadoRecoger: true,
      ocupacion: ocupacion,
      lugarTrabajo: lugarTrabajo,
      telefonoTrabajo: telefonoTrabajo,
      ingresosAproximados: ingresosAproximados,
      cartaTrabajoAdjunta: cartaTrabajoAdjunta,
      estadosFinancierosAdjuntos: estadosFinancierosAdjuntos,
      copiaCedulaAdjunta: copiaCedulaAdjunta,
      otrosDocumentos: otrosDocumentos,
      documentosExpediente: tutorDocumentos ?? [],
    );

    List<Student> students = [];
    if (multipleStudents != null && multipleStudents.isNotEmpty) {
      students = List<Student>.from(multipleStudents);
    } else if (estudianteNombres != null && estudianteNombres.trim().isNotEmpty) {
      final studentId = 'est-${now.millisecondsSinceEpoch}';
      students.add(
        Student(
          id: studentId,
          colegioId: colegioId,
          familiaId: familyId,
          matricula: 'EST-${now.year}-$uniqueSuffix',
          nombres: estudianteNombres.trim(),
          apellidos: (estudianteApellidos != null && estudianteApellidos.trim().isNotEmpty)
              ? estudianteApellidos.trim()
              : tutorApellidos,
          fechaNacimiento: DateTime(now.year - 8, 1, 1),
          genero: 'No especificado',
          gradoNombre: gradoNombre ?? '1ro de Primaria',
          seccionNombre: 'Sección A',
        ),
      );
    }

    final List<Tutor> allTutores = [newTutor, ...?additionalTutors];

    final newFamily = Family(
      id: familyId,
      colegioId: colegioId,
      codigoFamilia: codigoFamilia,
      nombreFamilia: nombreFamilia,
      balancePendiente: balanceInicial,
      telefonoPrincipal: tutorTelefono,
      emailPrincipal: tutorEmail,
      direccion: direccion,
      activo: true,
      tutores: allTutores,
      estudiantes: students,
      modalidadPago: modalidadPago,
      descuentoAcordadoPct: descuentoAcordadoPct,
      notaAcuerdoPago: notaAcuerdoPago,
      criteriosCentroAdicionales: criteriosCentroAdicionales,
    );

    // Registrar credenciales para que el tutor pueda acceder de inmediato al sistema
    AuthRepository().registerUser(
      email: tutorEmail,
      nombres: tutorNombres,
      apellidos: tutorApellidos,
      rol: UserRole.tutorFamiliar,
      colegioId: colegioId,
      telefono: tutorTelefono,
      cedula: cedula,
    );

    if (additionalTutors != null) {
      for (final at in additionalTutors) {
        if (at.email != null && at.email!.trim().isNotEmpty) {
          AuthRepository().registerUser(
            email: at.email!.trim(),
            nombres: at.nombres,
            apellidos: at.apellidos,
            rol: UserRole.tutorFamiliar,
            colegioId: colegioId,
            telefono: at.telefono,
            cedula: at.cedulaOPasaporte,
          );
        }
      }
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        final familyData = await _supabaseClient.from('familias').insert({
          'colegio_id': colegioId,
          'codigo_familia': codigoFamilia,
          'nombre_familia': nombreFamilia,
          'balance_pendiente': balanceInicial,
          'telefono_principal': tutorTelefono,
          'email_principal': tutorEmail,
          'direccion': direccion,
          'activo': true,
        }).select().single();

        final createdFamilyId = familyData['id'] as String;

        await _supabaseClient.from('tutores').insert({
          'familia_id': createdFamilyId,
          'nombres': tutorNombres,
          'apellidos': tutorApellidos,
          'parentesco': parentesco ?? 'Tutor Legal',
          'cedula_o_pasaporte': cedula,
          'telefono': tutorTelefono,
          'email': tutorEmail,
          'es_contacto_principal': true,
          'autorizado_recoger': true,
        });

        // Insertar tutores adicionales en Supabase
        if (additionalTutors != null) {
          for (final at in additionalTutors) {
            try {
              await _supabaseClient.from('tutores').insert({
                'familia_id': createdFamilyId,
                'nombres': at.nombres,
                'apellidos': at.apellidos,
                'parentesco': at.parentesco,
                'cedula_o_pasaporte': at.cedulaOPasaporte,
                'telefono': at.telefono,
                'email': at.email,
                'es_contacto_principal': false,
                'autorizado_recoger': at.autorizadoRecoger,
              });
            } catch (e) {
              debugPrint('Aviso inserting extra tutor in Supabase: $e');
            }
          }
        }

        for (final st in students) {
          Map<String, dynamic>? studentInsert;
          final extraData = {
            'grado_nombre': st.gradoNombre,
            'seccion_nombre': st.seccionNombre,
            'tipo_sangre': st.tipoSangre,
            'alergias': st.alergias,
            'seguro_medico': st.seguroMedico,
            'numero_poliza': st.numeroPoliza,
            'pediatra_contacto': st.pediatraContacto,
            'criterios_evaluados': st.criteriosEvaluados,
          };
          try {
            studentInsert = await _supabaseClient.from('estudiantes').insert({
              'colegio_id': colegioId,
              'familia_id': createdFamilyId,
              'matricula': st.matricula,
              'nombres': st.nombres,
              'apellidos': st.apellidos,
              'fecha_nacimiento': st.fechaNacimiento.toIso8601String().split('T').first,
              'genero': st.genero ?? 'No especificado',
              'foto_url': st.fotoUrl,
              'condiciones_medicas': jsonEncode(extraData),
              'activo': true,
            }).select().maybeSingle();
          } catch (e) {
            debugPrint('Aviso inserting student in Supabase: $e');
          }

          final createdStudentId = studentInsert != null ? studentInsert['id'] as String? : null;

          // Insertar documentos en la tabla documentos_estudiante
          for (final doc in st.documentosExpediente) {
            try {
              await _supabaseClient.from('documentos_estudiante').insert({
                'estudiante_id': createdStudentId ?? st.id,
                'tipo': doc.tipo,
                'archivo_url': doc.url ?? 'https://storage.edunex.edu.do/expedientes/${doc.nombreArchivo}',
                'aprobado': doc.verificado,
                'observaciones': '${doc.nombreArchivo} (${doc.tamanoFormateado})',
              });
            } catch (e) {
              debugPrint('Aviso inserting documento_estudiante in Supabase: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Aviso: Guardando familia localmente tras error Supabase: $e');
      }
    }

    _customFamilies.insert(0, newFamily);
    await _persistCustomFamilies();
    return newFamily;
  }

  /// Agrega un nuevo tutor o persona autorizada a una familia existente (Issue #19)
  Future<void> addTutorToFamily(String familyId, Tutor tutor) async {
    bool updated = false;
    for (int i = 0; i < _customFamilies.length; i++) {
      if (_customFamilies[i].id == familyId) {
        final f = _customFamilies[i];
        final updatedTutores = List<Tutor>.from(f.tutores)..add(tutor);
        _customFamilies[i] = f.copyWith(tutores: updatedTutores);
        updated = true;
        break;
      }
    }

    if (!updated) {
      for (int i = 0; i < _demoFamilies.length; i++) {
        if (_demoFamilies[i].id == familyId) {
          final f = _demoFamilies[i];
          final updatedTutores = List<Tutor>.from(f.tutores)..add(tutor);
          final updatedFamily = f.copyWith(tutores: updatedTutores);
          _demoFamilies[i] = updatedFamily;
          _customFamilies.insert(0, updatedFamily);
          break;
        }
      }
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        await _supabaseClient.from('tutores').insert({
          'familia_id': familyId,
          'nombres': tutor.nombres,
          'apellidos': tutor.apellidos,
          'parentesco': tutor.parentesco,
          'cedula_o_pasaporte': tutor.cedulaOPasaporte,
          'telefono': tutor.telefono,
          'email': tutor.email,
          'es_contacto_principal': tutor.esContactoPrincipal,
          'autorizado_recoger': tutor.autorizadoRecoger,
        });
      } catch (e) {
        debugPrint('Aviso: Tutor agregado localmente tras error Supabase: $e');
      }
    }

    if (tutor.email != null && tutor.email!.trim().isNotEmpty) {
      AuthRepository().registerUser(
        email: tutor.email!.trim(),
        nombres: tutor.nombres,
        apellidos: tutor.apellidos,
        rol: UserRole.tutorFamiliar,
        telefono: tutor.telefono,
        cedula: tutor.cedulaOPasaporte,
      );
    }

    await _persistCustomFamilies();
  }

  /// Issue #19: Adjunta y persiste un documento oficial en el expediente digital de un estudiante
  Future<void> addDocumentToStudent({
    required String studentId,
    required StudentDocument document,
  }) async {
    bool updated = false;
    for (int i = 0; i < _customFamilies.length; i++) {
      final f = _customFamilies[i];
      final sIndex = f.estudiantes.indexWhere((s) => s.id == studentId);
      if (sIndex != -1) {
        final currentStudent = f.estudiantes[sIndex];
        final updatedDocs = List<StudentDocument>.from(currentStudent.documentosExpediente)..add(document);
        final updatedStudent = currentStudent.copyWith(
          documentosExpediente: updatedDocs,
          fotoAdjunta: currentStudent.fotoAdjunta || document.tipo.toLowerCase().contains('foto'),
          actaNacimientoAdjunta: currentStudent.actaNacimientoAdjunta || document.tipo.toLowerCase().contains('acta'),
          certificadoNotasAdjunto: currentStudent.certificadoNotasAdjunto || document.tipo.toLowerCase().contains('nota') || document.tipo.toLowerCase().contains('calificac'),
          cartaSaldoConductaAdjunta: currentStudent.cartaSaldoConductaAdjunta || document.tipo.toLowerCase().contains('conducta') || document.tipo.toLowerCase().contains('saldo'),
        );
        final updatedStudents = List<Student>.from(f.estudiantes);
        updatedStudents[sIndex] = updatedStudent;
        _customFamilies[i] = f.copyWith(estudiantes: updatedStudents);
        updated = true;
        break;
      }
    }

    if (!updated) {
      for (int i = 0; i < _demoFamilies.length; i++) {
        final f = _demoFamilies[i];
        final sIndex = f.estudiantes.indexWhere((s) => s.id == studentId);
        if (sIndex != -1) {
          final currentStudent = f.estudiantes[sIndex];
          final updatedDocs = List<StudentDocument>.from(currentStudent.documentosExpediente)..add(document);
          final updatedStudent = currentStudent.copyWith(
            documentosExpediente: updatedDocs,
            fotoAdjunta: currentStudent.fotoAdjunta || document.tipo.toLowerCase().contains('foto'),
            actaNacimientoAdjunta: currentStudent.actaNacimientoAdjunta || document.tipo.toLowerCase().contains('acta'),
            certificadoNotasAdjunto: currentStudent.certificadoNotasAdjunto || document.tipo.toLowerCase().contains('nota') || document.tipo.toLowerCase().contains('calificac'),
            cartaSaldoConductaAdjunta: currentStudent.cartaSaldoConductaAdjunta || document.tipo.toLowerCase().contains('conducta') || document.tipo.toLowerCase().contains('saldo'),
          );
          final updatedStudents = List<Student>.from(f.estudiantes);
          updatedStudents[sIndex] = updatedStudent;
          final updatedFamily = f.copyWith(estudiantes: updatedStudents);
          _demoFamilies[i] = updatedFamily;
          _customFamilies.insert(0, updatedFamily);
          break;
        }
      }
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        await _supabaseClient.from('documentos_estudiante').insert({
          'estudiante_id': studentId,
          'tipo': document.tipo,
          'archivo_url': document.url ?? 'https://storage.edunex.edu.do/expedientes/${document.nombreArchivo}',
          'aprobado': document.verificado,
          'observaciones': '${document.nombreArchivo} (${document.tamanoFormateado})',
        });
      } catch (e) {
        debugPrint('Aviso inserting documento_estudiante in Supabase: $e');
      }
    }

    await _persistCustomFamilies();
  }

  /// Elimina un documento del expediente de un estudiante y persiste los cambios
  Future<void> removeDocumentFromStudent({
    required String studentId,
    required String documentId,
  }) async {
    for (int i = 0; i < _customFamilies.length; i++) {
      final f = _customFamilies[i];
      final sIndex = f.estudiantes.indexWhere((s) => s.id == studentId);
      if (sIndex != -1) {
        final currentStudent = f.estudiantes[sIndex];
        final updatedDocs = currentStudent.documentosExpediente.where((d) => d.id != documentId).toList();
        final updatedStudent = currentStudent.copyWith(
          documentosExpediente: updatedDocs,
          fotoAdjunta: updatedDocs.any((d) => d.tipo.toLowerCase().contains('foto')),
          actaNacimientoAdjunta: updatedDocs.any((d) => d.tipo.toLowerCase().contains('acta')),
          certificadoNotasAdjunto: updatedDocs.any((d) => d.tipo.toLowerCase().contains('nota') || d.tipo.toLowerCase().contains('calificac')),
          cartaSaldoConductaAdjunta: updatedDocs.any((d) => d.tipo.toLowerCase().contains('conducta') || d.tipo.toLowerCase().contains('saldo')),
        );
        final updatedStudents = List<Student>.from(f.estudiantes);
        updatedStudents[sIndex] = updatedStudent;
        _customFamilies[i] = f.copyWith(estudiantes: updatedStudents);
        break;
      }
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        await _supabaseClient.from('documentos_estudiante').delete().eq('id', documentId);
      } catch (e) {
        debugPrint('Aviso deleting documento_estudiante in Supabase: $e');
      }
    }

    await _persistCustomFamilies();
  }

  /// Agrega un nuevo documento digital al expediente de un tutor/padre (Issue #19)
  Future<void> addDocumentToTutor({
    required String familyId,
    required String tutorId,
    required StudentDocument document,
  }) async {
    for (int i = 0; i < _customFamilies.length; i++) {
      final f = _customFamilies[i];
      if (f.id == familyId) {
        final tIndex = f.tutores.indexWhere((t) => t.id == tutorId);
        if (tIndex != -1) {
          final currentTutor = f.tutores[tIndex];
          final updatedDocs = List<StudentDocument>.from(currentTutor.documentosExpediente)..add(document);
          final updatedTutor = currentTutor.copyWith(
            documentosExpediente: updatedDocs,
            copiaCedulaAdjunta: currentTutor.copiaCedulaAdjunta || document.tipo.toLowerCase().contains('cedula') || document.tipo.toLowerCase().contains('cédula'),
            cartaTrabajoAdjunta: currentTutor.cartaTrabajoAdjunta || document.tipo.toLowerCase().contains('trabajo') || document.tipo.toLowerCase().contains('laboral'),
            estadosFinancierosAdjuntos: currentTutor.estadosFinancierosAdjuntos || document.tipo.toLowerCase().contains('financiero') || document.tipo.toLowerCase().contains('ingreso'),
          );
          final updatedTutores = List<Tutor>.from(f.tutores);
          updatedTutores[tIndex] = updatedTutor;
          _customFamilies[i] = f.copyWith(tutores: updatedTutores);
          break;
        }
      }
    }

    for (int i = 0; i < _demoFamilies.length; i++) {
      final f = _demoFamilies[i];
      if (f.id == familyId) {
        final tIndex = f.tutores.indexWhere((t) => t.id == tutorId);
        if (tIndex != -1) {
          final currentTutor = f.tutores[tIndex];
          final updatedDocs = List<StudentDocument>.from(currentTutor.documentosExpediente)..add(document);
          final updatedTutor = currentTutor.copyWith(
            documentosExpediente: updatedDocs,
            copiaCedulaAdjunta: currentTutor.copiaCedulaAdjunta || document.tipo.toLowerCase().contains('cedula') || document.tipo.toLowerCase().contains('cédula'),
            cartaTrabajoAdjunta: currentTutor.cartaTrabajoAdjunta || document.tipo.toLowerCase().contains('trabajo') || document.tipo.toLowerCase().contains('laboral'),
            estadosFinancierosAdjuntos: currentTutor.estadosFinancierosAdjuntos || document.tipo.toLowerCase().contains('financiero') || document.tipo.toLowerCase().contains('ingreso'),
          );
          final updatedTutores = List<Tutor>.from(f.tutores);
          updatedTutores[tIndex] = updatedTutor;
          final updatedFamily = f.copyWith(tutores: updatedTutores);
          _demoFamilies[i] = updatedFamily;
          _customFamilies.insert(0, updatedFamily);
          break;
        }
      }
    }

    await _persistCustomFamilies();
  }

  /// Elimina un documento digital del expediente de un tutor/padre (Issue #19)
  Future<void> removeDocumentFromTutor({
    required String familyId,
    required String tutorId,
    required String documentId,
  }) async {
    for (int i = 0; i < _customFamilies.length; i++) {
      final f = _customFamilies[i];
      if (f.id == familyId) {
        final tIndex = f.tutores.indexWhere((t) => t.id == tutorId);
        if (tIndex != -1) {
          final currentTutor = f.tutores[tIndex];
          final updatedDocs = currentTutor.documentosExpediente.where((d) => d.id != documentId).toList();
          final updatedTutor = currentTutor.copyWith(
            documentosExpediente: updatedDocs,
            copiaCedulaAdjunta: updatedDocs.any((d) => d.tipo.toLowerCase().contains('cedula') || d.tipo.toLowerCase().contains('cédula')),
            cartaTrabajoAdjunta: updatedDocs.any((d) => d.tipo.toLowerCase().contains('trabajo') || d.tipo.toLowerCase().contains('laboral')),
            estadosFinancierosAdjuntos: updatedDocs.any((d) => d.tipo.toLowerCase().contains('financiero') || d.tipo.toLowerCase().contains('ingreso')),
          );
          final updatedTutores = List<Tutor>.from(f.tutores);
          updatedTutores[tIndex] = updatedTutor;
          _customFamilies[i] = f.copyWith(tutores: updatedTutores);
          break;
        }
      }
    }

    await _persistCustomFamilies();
  }

  /// Registra un abono o pago a una familia y emite su comprobante fiscal oficial
  Future<PaymentReceipt> recordPayment({
    required String familiaId,
    required double monto,
    required String concepto,
    required String metodo,
    String? referencia,
  }) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        await _supabaseClient.from('pagos').insert({
          'familia_id': familiaId,
          'monto_total': monto,
          'metodo': metodo.toLowerCase(),
          'referencia': referencia ?? 'REC-${DateTime.now().millisecondsSinceEpoch}',
          'estado': 'aprobado',
          'notas': concepto,
        });
      } catch (e) {
        debugPrint('Aviso: Pago registrado localmente: $e');
      }
    }

    String familyName = 'Familia';
    List<String> studentNames = [];

    // Actualizar balance en memoria
    bool foundInCustom = false;
    for (int i = 0; i < _customFamilies.length; i++) {
      if (_customFamilies[i].id == familiaId) {
        final f = _customFamilies[i];
        familyName = f.nombreFamilia;
        studentNames = f.estudiantes.map((s) => s.nombreCompleto).toList();
        final newBal = (f.balancePendiente - monto).clamp(0.0, double.infinity);
        _customFamilies[i] = Family(
          id: f.id,
          colegioId: f.colegioId,
          codigoFamilia: f.codigoFamilia,
          nombreFamilia: f.nombreFamilia,
          balancePendiente: newBal,
          telefonoPrincipal: f.telefonoPrincipal,
          emailPrincipal: f.emailPrincipal,
          direccion: f.direccion,
          activo: f.activo,
          tutores: f.tutores,
          estudiantes: f.estudiantes,
        );
        foundInCustom = true;
        break;
      }
    }

    if (!foundInCustom) {
      for (final df in _demoFamilies) {
        if (df.id == familiaId) {
          familyName = df.nombreFamilia;
          studentNames = df.estudiantes.map((s) => s.nombreCompleto).toList();
          final newBal = (df.balancePendiente - monto).clamp(0.0, double.infinity);
          _customFamilies.insert(0, Family(
            id: df.id,
            colegioId: df.colegioId,
            codigoFamilia: df.codigoFamilia,
            nombreFamilia: df.nombreFamilia,
            balancePendiente: newBal,
            telefonoPrincipal: df.telefonoPrincipal,
            emailPrincipal: df.emailPrincipal,
            direccion: df.direccion,
            activo: df.activo,
            tutores: df.tutores,
            estudiantes: df.estudiantes,
          ));
          break;
        }
      }
    }

    final now = DateTime.now();
    final receiptNum = 'REC-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final ncfCode = 'B02${now.millisecondsSinceEpoch.toString().substring(5)}';
    final ref = referencia ?? 'AUTH-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final receipt = PaymentReceipt(
      id: 'rec-${now.millisecondsSinceEpoch}',
      numeroComprobante: receiptNum,
      ncf: ncfCode,
      familiaId: familiaId,
      nombreFamilia: familyName,
      fechaEmision: now,
      concepto: concepto,
      monto: monto,
      metodoPago: metodo,
      referencia: ref,
      estado: 'Válido / Pagado',
      estudiantes: studentNames,
    );

    _receipts.insert(0, receipt);
    return receipt;
  }

  /// Obtiene todos los comprobantes de pago emitidos para una familia
  Future<List<PaymentReceipt>> getReceiptsForFamily(String familiaId) async {
    final list = _useDemoFallback ? _receipts : _receipts.where((r) => !r.id.startsWith('rec-00')).toList();
    return list.where((r) => r.familiaId == familiaId).toList();
  }

  /// Obtiene los acuerdos y convenios de pago solicitados por la familia
  Future<List<PaymentAgreementRequest>> getAgreementsForFamily(String familiaId) async {
    final list = _useDemoFallback ? _agreements : _agreements.where((a) => !a.id.startsWith('agr-00')).toList();
    return list.where((a) => a.familiaId == familiaId).toList();
  }

  /// Registra una nueva solicitud de acuerdo de pago o mejora de cuota
  Future<PaymentAgreementRequest> submitAgreementRequest({
    required String familiaId,
    required String nombreFamilia,
    required String tipoAcuerdo,
    required double propuestaCuota,
    required String justificacion,
  }) async {
    final agreement = PaymentAgreementRequest(
      id: 'agr-${DateTime.now().millisecondsSinceEpoch}',
      familiaId: familiaId,
      nombreFamilia: nombreFamilia,
      tipoAcuerdo: tipoAcuerdo,
      propuestaCuota: propuestaCuota,
      justificacion: justificacion,
      fechaSolicitud: DateTime.now(),
      estado: 'En revisión por Dirección',
    );
    _agreements.insert(0, agreement);
    return agreement;
  }

  /// Obtiene todas las preguntas y consultas formuladas por familias al centro escolar
  Future<List<ParentQuestion>> getAllQuestions({String? colegioId}) async {
    final list = _useDemoFallback ? _questions : _questions.where((q) => !q.id.startsWith('qst-00')).toList();
    return List<ParentQuestion>.from(list);
  }

  /// Obtiene las preguntas y consultas formuladas por la familia
  Future<List<ParentQuestion>> getQuestionsForFamily(String familiaId) async {
    final list = _useDemoFallback ? _questions : _questions.where((q) => !q.id.startsWith('qst-00')).toList();
    return list.where((q) => q.familiaId == familiaId).toList();
  }

  /// Responde oficialmente a una consulta familiar desde la administración
  Future<ParentQuestion> answerQuestion({
    required String questionId,
    required String respuesta,
    required String respondidoPor,
  }) async {
    final idx = _questions.indexWhere((q) => q.id == questionId);
    if (idx != -1) {
      final old = _questions[idx];
      final updated = ParentQuestion(
        id: old.id,
        familiaId: old.familiaId,
        tutorNombre: old.tutorNombre,
        departamento: old.departamento,
        asunto: old.asunto,
        mensaje: old.mensaje,
        fechaEnvio: old.fechaEnvio,
        estado: 'Respondida',
        respuestaCentro: respuesta.trim(),
        fechaRespuesta: DateTime.now(),
        respondidoPor: respondidoPor.trim(),
      );
      _questions[idx] = updated;
      return updated;
    }
    throw Exception('Consulta no encontrada');
  }

  /// Obtiene todos los acuerdos o convenios de pago para revisión administrativa
  Future<List<PaymentAgreementRequest>> getAllAgreements({String? colegioId}) async {
    return List<PaymentAgreementRequest>.from(_agreements);
  }

  /// Revisa, aprueba o rechaza una solicitud de acuerdo de pago
  Future<PaymentAgreementRequest> reviewAgreement({
    required String agreementId,
    required bool approve,
    required String respuestaCentro,
  }) async {
    final idx = _agreements.indexWhere((a) => a.id == agreementId);
    if (idx != -1) {
      final old = _agreements[idx];
      final updated = PaymentAgreementRequest(
        id: old.id,
        familiaId: old.familiaId,
        nombreFamilia: old.nombreFamilia,
        tipoAcuerdo: old.tipoAcuerdo,
        propuestaCuota: old.propuestaCuota,
        justificacion: old.justificacion,
        fechaSolicitud: old.fechaSolicitud,
        estado: approve ? 'Aprobado' : 'Rechazado',
        respuestaCentro: respuestaCentro.trim(),
        fechaRespuesta: DateTime.now(),
      );
      _agreements[idx] = updated;
      return updated;
    }
    throw Exception('Solicitud de acuerdo no encontrada');
  }

  /// Envía una nueva consulta o pregunta al centro escolar
  Future<ParentQuestion> submitQuestion({
    required String familiaId,
    required String tutorNombre,
    required String departamento,
    required String asunto,
    required String mensaje,
  }) async {
    final question = ParentQuestion(
      id: 'qst-${DateTime.now().millisecondsSinceEpoch}',
      familiaId: familiaId,
      tutorNombre: tutorNombre,
      departamento: departamento,
      asunto: asunto,
      mensaje: mensaje,
      fechaEnvio: DateTime.now(),
      estado: 'En trámite',
    );
    _questions.insert(0, question);
    return question;
  }

  /// Modifica el estado de un servicio escolar contratado para un alumno
  Future<void> toggleStudentService({
    required String familiaId,
    required String studentId,
    required String servicio,
    required bool activar,
  }) async {
    // Si la familia aún no está en _customFamilies, copiarla desde _demoFamilies
    if (!_customFamilies.any((f) => f.id == familiaId)) {
      final df = _demoFamilies.where((f) => f.id == familiaId).toList();
      if (df.isNotEmpty) {
        _customFamilies.insert(0, df.first);
      }
    }

    for (int i = 0; i < _customFamilies.length; i++) {
      if (_customFamilies[i].id == familiaId) {
        final f = _customFamilies[i];
        final updatedStudents = f.estudiantes.map((st) {
          if (st.id == studentId) {
            final currentServices = List<String>.from(st.serviciosActivos);
            if (activar) {
              if (!currentServices.contains(servicio)) currentServices.add(servicio);
            } else {
              currentServices.remove(servicio);
            }
            return Student(
              id: st.id,
              colegioId: st.colegioId,
              familiaId: st.familiaId,
              matricula: st.matricula,
              nombres: st.nombres,
              apellidos: st.apellidos,
              fechaNacimiento: st.fechaNacimiento,
              genero: st.genero,
              gradoNombre: st.gradoNombre,
              seccionNombre: st.seccionNombre,
              fotoUrl: st.fotoUrl,
              serviciosActivos: currentServices,
            );
          }
          return st;
        }).toList();

        _customFamilies[i] = Family(
          id: f.id,
          colegioId: f.colegioId,
          codigoFamilia: f.codigoFamilia,
          nombreFamilia: f.nombreFamilia,
          balancePendiente: f.balancePendiente,
          telefonoPrincipal: f.telefonoPrincipal,
          emailPrincipal: f.emailPrincipal,
          direccion: f.direccion,
          activo: f.activo,
          tutores: f.tutores,
          estudiantes: updatedStudents,
        );
        break;
      }
    }
  }

  /// Matricula un nuevo alumno en una familia (Issue #19: incluye expediente de documentos y tutores)
  Future<Student> enrollStudent({
    required String familiaId,
    required String colegioId,
    required String nombres,
    required String apellidos,
    required String gradoNombre,
    String? seccionNombre,
    DateTime? fechaNacimiento,
    String? genero,
    List<String> servicios = const [],
    List<StudentDocument> documentos = const [],
    List<Tutor> additionalTutors = const [],
  }) async {
    final now = DateTime.now();
    final uniqueSuffix = now.millisecondsSinceEpoch.toString().substring(8);
    final matricula = 'EST-${now.year}-$uniqueSuffix';
    final studentId = 'est-${now.millisecondsSinceEpoch}';

    final student = Student(
      id: studentId,
      colegioId: colegioId,
      familiaId: familiaId,
      matricula: matricula,
      nombres: nombres,
      apellidos: apellidos,
      fechaNacimiento: fechaNacimiento ?? DateTime(now.year - 7, 1, 1),
      genero: genero ?? 'No especificado',
      gradoNombre: gradoNombre,
      seccionNombre: seccionNombre ?? 'Sección A',
      serviciosActivos: servicios,
      documentosExpediente: documentos,
      fotoAdjunta: documentos.any((d) => d.tipo.toLowerCase().contains('foto')),
      actaNacimientoAdjunta: documentos.any((d) => d.tipo.toLowerCase().contains('acta')),
      certificadoNotasAdjunto: documentos.any((d) => d.tipo.toLowerCase().contains('nota')),
      cartaSaldoConductaAdjunta: documentos.any((d) => d.tipo.toLowerCase().contains('conducta') || d.tipo.toLowerCase().contains('saldo')),
    );

    // Issue #19: Registrar tutores adicionales o personas autorizadas vinculadas a esta matrícula
    for (final tutor in additionalTutors) {
      await addTutorToFamily(familiaId, tutor);
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        final extraData = {
          'grado_nombre': gradoNombre,
          'seccion_nombre': seccionNombre ?? 'Sección A',
        };
        final studentInsert = await _supabaseClient.from('estudiantes').insert({
          'colegio_id': colegioId,
          'familia_id': familiaId,
          'matricula': matricula,
          'nombres': nombres,
          'apellidos': apellidos,
          'fecha_nacimiento': (fechaNacimiento ?? DateTime(now.year - 7, 1, 1)).toIso8601String().split('T').first,
          'genero': genero ?? 'No especificado',
          'condiciones_medicas': jsonEncode(extraData),
          'activo': true,
        }).select().maybeSingle();

        final createdStudentId = studentInsert != null ? studentInsert['id'] as String? : null;

        for (final doc in documentos) {
          try {
            await _supabaseClient.from('documentos_estudiante').insert({
              'estudiante_id': createdStudentId ?? studentId,
              'tipo': doc.tipo,
              'archivo_url': doc.url ?? 'https://storage.edunex.edu.do/expedientes/${doc.nombreArchivo}',
              'aprobado': doc.verificado,
              'observaciones': '${doc.nombreArchivo} (${doc.tamanoFormateado})',
            });
          } catch (e) {
            debugPrint('Aviso inserting documento_estudiante in Supabase: $e');
          }
        }
      } catch (e) {
        debugPrint('Aviso: Estudiante guardado localmente tras error Supabase: $e');
      }
    }

    // Actualizar familia en memoria
    bool enrolledInCustom = false;
    for (int i = 0; i < _customFamilies.length; i++) {
      if (_customFamilies[i].id == familiaId) {
        final f = _customFamilies[i];
        _customFamilies[i] = f.copyWith(estudiantes: [...f.estudiantes, student]);
        enrolledInCustom = true;
        break;
      }
    }

    if (!enrolledInCustom) {
      for (int i = 0; i < _demoFamilies.length; i++) {
        if (_demoFamilies[i].id == familiaId) {
          final f = _demoFamilies[i];
          _demoFamilies[i] = f.copyWith(estudiantes: [...f.estudiantes, student]);
          break;
        }
      }
    }

    return student;
  }

  // =========================================================================
  // AUTOMATIZACIÓN DE FACTURACIÓN RECURRENTE & AGING DE CARTERA (Sección 4.3 y 8)
  // =========================================================================

  static final List<BillingRunResult> _billingRuns = [];
  static final Map<String, DateTime> _recordatoriosEnviados = {};

  /// Ejecuta el corte masivo mensual de colegiaturas y servicios activos
  Future<BillingRunResult> executeMonthlyBillingRun({
    required String mesConcepto,
    double cuotaColegiaturaBase = 8500.0,
    bool incluirServicios = true,
  }) async {
    final families = await getFamilies();
    final List<BillingItemDetail> detalles = [];

    int totalEstudiantes = 0;
    double sumaColegiaturas = 0.0;
    double sumaServicios = 0.0;

    for (final fam in families) {
      if (!fam.activo || fam.estudiantes.isEmpty) continue;

      final countEst = fam.estudiantes.length;
      totalEstudiantes += countEst;

      final colegiaturaFam = cuotaColegiaturaBase * countEst;
      sumaColegiaturas += colegiaturaFam;

      double serviciosFam = 0.0;
      if (incluirServicios) {
        for (final est in fam.estudiantes) {
          for (final serv in est.serviciosActivos) {
            final sLow = serv.toLowerCase();
            if (sLow.contains('cuido') || sLow.contains('tarde')) {
              serviciosFam += 3500.0;
            } else if (sLow.contains('ruta') || sLow.contains('transporte')) {
              serviciosFam += 4500.0;
            } else {
              serviciosFam += 2000.0;
            }
          }
        }
      }
      sumaServicios += serviciosFam;

      final cargoTotal = colegiaturaFam + serviciosFam;
      final nuevoBalance = fam.balancePendiente + cargoTotal;

      // Actualizar balance de la familia en memoria
      final index = _customFamilies.indexWhere((f) => f.id == fam.id);
      if (index != -1) {
        final current = _customFamilies[index];
        _customFamilies[index] = Family(
          id: current.id,
          colegioId: current.colegioId,
          codigoFamilia: current.codigoFamilia,
          nombreFamilia: current.nombreFamilia,
          balancePendiente: nuevoBalance,
          telefonoPrincipal: current.telefonoPrincipal,
          emailPrincipal: current.emailPrincipal,
          direccion: current.direccion,
          activo: current.activo,
          tutores: current.tutores,
          estudiantes: current.estudiantes,
        );
      }

      detalles.add(
        BillingItemDetail(
          familiaId: fam.id,
          codigoFamilia: fam.codigoFamilia,
          nombreFamilia: fam.nombreFamilia,
          cantidadEstudiantes: countEst,
          colegiatura: colegiaturaFam,
          servicios: serviciosFam,
          totalCargo: cargoTotal,
          nuevoBalance: nuevoBalance,
        ),
      );
    }

    final totalFacturado = sumaColegiaturas + sumaServicios;
    final runResult = BillingRunResult(
      id: 'CORTE-${DateTime.now().year}-${_billingRuns.length + 101}',
      mesConcepto: mesConcepto,
      fechaEjecucion: DateTime.now(),
      familiasProcesadas: detalles.length,
      estudiantesFacturados: totalEstudiantes,
      montoColegiaturas: sumaColegiaturas,
      montoServiciosAdicionales: sumaServicios,
      montoTotalFacturado: totalFacturado,
      detalles: detalles,
    );

    _billingRuns.insert(0, runResult);
    return runResult;
  }

  /// Retorna el historial de cortes de facturación
  Future<List<BillingRunResult>> getBillingRuns() async {
    return List.unmodifiable(_billingRuns);
  }

  /// Genera el reporte de antigüedad de saldos / Cartera Vencida (Aging Report)
  Future<DebtAgingSummary> getDebtAgingReport() async {
    final families = await getFamilies();
    final List<DelinquentFamily> enMora = [];

    double corriente = 0.0;
    double d30a60 = 0.0;
    double d60a90 = 0.0;
    double mas90 = 0.0;

    for (int i = 0; i < families.length; i++) {
      final f = families[i];
      if (f.balancePendiente <= 0) continue;

      // Calcular días de mora basados en el historial o distribución simulada
      int dias = 20;
      DelinquencyRisk riesgo = DelinquencyRisk.bajo;

      if (f.codigoFamilia == 'FAM-2026-001') {
        dias = 45;
        riesgo = DelinquencyRisk.medio;
      } else if (f.codigoFamilia == 'FAM-2026-003') {
        dias = 85;
        riesgo = DelinquencyRisk.alto;
      } else if (f.codigoFamilia == 'FAM-2026-004') {
        dias = 110;
        riesgo = DelinquencyRisk.critico;
      } else {
        dias = (i * 18) % 95 + 10;
        if (dias > 90) {
          riesgo = DelinquencyRisk.critico;
        } else if (dias > 60) {
          riesgo = DelinquencyRisk.alto;
        } else if (dias > 30) {
          riesgo = DelinquencyRisk.medio;
        }
      }

      if (dias <= 30) {
        corriente += f.balancePendiente;
      } else if (dias <= 60) {
        d30a60 += f.balancePendiente;
      } else if (dias <= 90) {
        d60a90 += f.balancePendiente;
      } else {
        mas90 += f.balancePendiente;
      }

      enMora.add(
        DelinquentFamily(
          familiaId: f.id,
          codigoFamilia: f.codigoFamilia,
          nombreFamilia: f.nombreFamilia,
          telefonoPrincipal: f.telefonoPrincipal ?? 'Sin teléfono',
          emailPrincipal: f.emailPrincipal ?? 'Sin correo',
          balancePendiente: f.balancePendiente,
          diasMora: dias,
          riesgo: riesgo,
          ultimoRecordatorio: _recordatoriosEnviados[f.id],
        ),
      );
    }

    // Ordenar por días de mora descendente
    enMora.sort((a, b) => b.diasMora.compareTo(a.diasMora));

    final totalVencida = d30a60 + d60a90 + mas90;

    return DebtAgingSummary(
      totalCorriente: corriente,
      total30a60: d30a60,
      total60a90: d60a90,
      totalMas90: mas90,
      totalCarteraVencida: totalVencida,
      familiasEnMora: enMora,
    );
  }

  /// Dispara recordatorios masivos o individuales de cobro a familias en mora
  Future<int> sendDelinquencyReminders({List<String>? familyIds}) async {
    final now = DateTime.now();
    int count = 0;

    if (familyIds != null && familyIds.isNotEmpty) {
      for (final id in familyIds) {
        _recordatoriosEnviados[id] = now;
        count++;
      }
    } else {
      final report = await getDebtAgingReport();
      for (final fam in report.familiasEnMora) {
        _recordatoriosEnviados[fam.familiaId] = now;
        count++;
      }
    }

    return count;
  }

  // =========================================================================
  // GESTIÓN DE AUTORIZACIÓN DE ABONOS (Issue #17)
  // =========================================================================

  static final List<PaymentApprovalRequest> _abonoApprovalRequests = [
    PaymentApprovalRequest(
      id: 'req-abono-demo-1',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      familiaNombre: 'Familia Pérez González',
      codigoFamilia: 'FAM-2026-001',
      balanceTotal: 7500.00,
      montoAbonoPropuesto: 3500.00,
      concepto: 'Mensualidad Febrero 2026',
      motivoAbono: 'Dificultad temporal de liquidez por gastos médicos imprevistos',
      solicitadoPor: 'Cajero / Recepción (Lic. Gómez)',
      fechaSolicitud: DateTime.now().subtract(const Duration(hours: 3)),
      estado: PaymentApprovalStatus.pendiente,
    ),
  ];

  /// Obtener solicitudes de aprobación de abono (Issue #17)
  Future<List<PaymentApprovalRequest>> getAbonoApprovalRequests({
    String? familiaId,
    PaymentApprovalStatus? status,
  }) async {
    var list = _useDemoFallback
        ? List<PaymentApprovalRequest>.from(_abonoApprovalRequests)
        : _abonoApprovalRequests.where((r) => !r.id.startsWith('apr-00')).toList();
    if (familiaId != null) {
      list = list.where((r) => r.familiaId == familiaId).toList();
    }
    if (status != null) {
      list = list.where((r) => r.estado == status).toList();
    }
    list.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
    return list;
  }

  /// Crear una nueva solicitud de abono para aprobación de administración/contabilidad (Issue #17)
  Future<PaymentApprovalRequest> createAbonoApprovalRequest({
    required String familiaId,
    required double montoAbono,
    required String motivo,
    String? concepto,
    String? solicitadoPor,
  }) async {
    final family = await getFamilyById(familiaId);
    final req = PaymentApprovalRequest(
      id: 'req-abono-${DateTime.now().millisecondsSinceEpoch}',
      familiaId: familiaId,
      familiaNombre: family?.nombreFamilia ?? 'Familia no identificada',
      codigoFamilia: family?.codigoFamilia ?? 'FAM-N/A',
      balanceTotal: family?.balancePendiente ?? 0.0,
      montoAbonoPropuesto: montoAbono,
      concepto: concepto ?? 'Abono a balance adeudado',
      motivoAbono: motivo,
      solicitadoPor: solicitadoPor ?? 'Caja / Recepción',
      fechaSolicitud: DateTime.now(),
      estado: PaymentApprovalStatus.pendiente,
    );
    _abonoApprovalRequests.insert(0, req);
    return req;
  }

  /// Resolver (aprobar o rechazar) una solicitud de abono (Issue #17)
  Future<bool> resolveAbonoApprovalRequest({
    required String requestId,
    required bool approve,
    required String revisorNombre,
    String? notas,
  }) async {
    final index = _abonoApprovalRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final current = _abonoApprovalRequests[index];
    _abonoApprovalRequests[index] = current.copyWith(
      estado: approve ? PaymentApprovalStatus.aprobado : PaymentApprovalStatus.rechazado,
      aprobadoPor: revisorNombre,
      fechaResolucion: DateTime.now(),
      notasResolucion: notas,
    );
    return true;
  }

  /// Obtener solicitud de abono aprobada y vigente para una familia (Issue #17)
  Future<PaymentApprovalRequest?> getApprovedAbonoForFamily(String familiaId) async {
    final requests = await getAbonoApprovalRequests(
      familiaId: familiaId,
      status: PaymentApprovalStatus.aprobado,
    );
    return requests.isNotEmpty ? requests.first : null;
  }
}
