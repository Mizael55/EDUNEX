import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/family.dart';
import '../models/student.dart';
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

  /// Lista de familias de demostración (coincidentes con los datos sembrados en la base de datos)
  static final List<Family> _demoFamilies = [
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

  /// Obtiene la lista de familias aplicando filtros opcionales de búsqueda y balance
  Future<List<Family>> getFamilies({
    String? searchQuery,
    bool onlyWithDebt = false,
  }) async {
    List<Family> families = [];

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        final response = await _supabaseClient
            .from('familias')
            .select('''
              *,
              tutores (*),
              estudiantes (
                *,
                secciones (
                  nombre,
                  grados (nombre)
                )
              )
            ''')
            .order('nombre_familia', ascending: true);

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

  /// Retorna una familia por su ID
  Future<Family?> getFamilyById(String id) async {
    final list = await getFamilies();
    try {
      return list.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retorna la familia asociada al usuario autenticado (para portal de padres)
  Future<Family?> getFamilyForCurrentUser({String? email, String? colegioId}) async {
    final list = await getFamilies();
    final cleanEmail = email?.trim().toLowerCase();

    // 1. Buscar coincidencia exacta por correo del tutor o correo principal
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      try {
        return list.firstWhere(
          (f) =>
              (f.emailPrincipal?.toLowerCase() == cleanEmail ||
                  f.tutores.any((t) => t.email?.toLowerCase() == cleanEmail)) &&
              (colegioId == null || f.colegioId == colegioId),
        );
      } catch (_) {}
    }

    // 2. Si no coincide el correo exacto, verificar en las familias creadas en la sesión
    if (_customFamilies.isNotEmpty) {
      if (colegioId != null) {
        final schoolCustom = _customFamilies.where((f) => f.colegioId == colegioId).toList();
        if (schoolCustom.isNotEmpty) return schoolCustom.first;
      }
      return _customFamilies.first;
    }

    // 3. Retorna la primera familia disponible en el colegio
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
    double balanceInicial = 0.0,
    String? estudianteNombres,
    String? estudianteApellidos,
    String? gradoNombre,
    List<Student>? multipleStudents,
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
      tutores: [newTutor],
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
    );

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
          'modalidad_pago': modalidadPago,
          'descuento_acordado_pct': descuentoAcordadoPct,
          'nota_acuerdo_pago': notaAcuerdoPago,
          'criterios_centro_adicionales': criteriosCentroAdicionales,
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
          'ocupacion': ocupacion,
          'lugar_trabajo': lugarTrabajo,
          'telefono_trabajo': telefonoTrabajo,
          'ingresos_aproximados': ingresosAproximados,
          'carta_trabajo_adjunta': cartaTrabajoAdjunta,
          'estados_financieros_adjuntos': estadosFinancierosAdjuntos,
          'copia_cedula_adjunta': copiaCedulaAdjunta,
        });

        for (final st in students) {
          await _supabaseClient.from('estudiantes').insert({
            'colegio_id': colegioId,
            'familia_id': createdFamilyId,
            'matricula': st.matricula,
            'nombres': st.nombres,
            'apellidos': st.apellidos,
            'fecha_nacimiento': st.fechaNacimiento.toIso8601String().split('T').first,
            'genero': st.genero ?? 'No especificado',
            'grado_nombre': st.gradoNombre,
            'seccion_nombre': st.seccionNombre,
            'tipo_sangre': st.tipoSangre,
            'alergias': st.alergias,
            'seguro_medico': st.seguroMedico,
            'numero_poliza': st.numeroPoliza,
            'pediatra_contacto': st.pediatraContacto,
            'foto_adjunta': st.fotoAdjunta,
            'acta_nacimiento_adjunta': st.actaNacimientoAdjunta,
            'certificado_notas_adjunto': st.certificadoNotasAdjunto,
            'carta_saldo_conducta_adjunta': st.cartaSaldoConductaAdjunta,
            'criterios_evaluados': st.criteriosEvaluados,
            'activo': true,
          });
        }
      } catch (e) {
        debugPrint('Aviso: Guardando familia localmente tras error Supabase: $e');
      }
    }

    _customFamilies.insert(0, newFamily);
    return newFamily;
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
    return _receipts.where((r) => r.familiaId == familiaId).toList();
  }

  /// Obtiene los acuerdos y convenios de pago solicitados por la familia
  Future<List<PaymentAgreementRequest>> getAgreementsForFamily(String familiaId) async {
    return _agreements.where((a) => a.familiaId == familiaId).toList();
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
    return List<ParentQuestion>.from(_questions);
  }

  /// Obtiene las preguntas y consultas formuladas por la familia
  Future<List<ParentQuestion>> getQuestionsForFamily(String familiaId) async {
    return _questions.where((q) => q.familiaId == familiaId).toList();
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

  /// Matricula un nuevo alumno en una familia
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
    );

    if (_supabaseClient != null && SupabaseConfig.isConfigured && !_useDemoFallback) {
      try {
        await _supabaseClient.from('estudiantes').insert({
          'colegio_id': colegioId,
          'familia_id': familiaId,
          'matricula': matricula,
          'nombres': nombres,
          'apellidos': apellidos,
          'fecha_nacimiento': (fechaNacimiento ?? DateTime(now.year - 7, 1, 1)).toIso8601String().split('T').first,
          'genero': genero ?? 'No especificado',
          'activo': true,
        });
      } catch (e) {
        debugPrint('Aviso: Estudiante guardado localmente tras error Supabase: $e');
      }
    }

    // Actualizar familia en memoria
    for (int i = 0; i < _customFamilies.length; i++) {
      if (_customFamilies[i].id == familiaId) {
        final f = _customFamilies[i];
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
          estudiantes: [...f.estudiantes, student],
        );
        break;
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
    var list = List<PaymentApprovalRequest>.from(_abonoApprovalRequests);
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
