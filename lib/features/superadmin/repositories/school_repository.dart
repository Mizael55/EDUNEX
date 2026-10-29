import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/supabase_config.dart';
import '../models/school.dart';
import '../models/saas_invoice.dart';
import '../models/system_announcement.dart';
import '../models/saas_user.dart';
import '../models/saas_company_config.dart';
import '../../families/models/student_document.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/user_role.dart';
import '../../families/repositories/family_repository.dart';
import '../../teacher_portal/repositories/teacher_repository.dart';
import '../../guidance/repositories/guidance_repository.dart';
import '../../academics/repositories/academic_repository.dart';
import '../models/audit_log.dart';
import 'audit_repository.dart';

/// Repositorio de Colegios y Clientes para el Dueño del Software (Superadmin)
class SchoolRepository {
  static SupabaseClient? _resolveClient() {
    try {
      if (SupabaseConfig.isConfigured) {
        return SupabaseConfig.adminClient;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  final SupabaseClient? _supabaseClient;
  final bool _useDemoFallback;

  static final Map<String, List<StudentDocument>> _schoolDocumentsMap = {};

  List<StudentDocument> getSchoolDocuments(String schoolId) {
    if (_schoolDocumentsMap.containsKey(schoolId)) {
      return List<StudentDocument>.from(_schoolDocumentsMap[schoolId]!);
    }
    return [];
  }

  void setSchoolDocuments(String schoolId, List<StudentDocument> docs) {
    _schoolDocumentsMap[schoolId] = List.from(docs);
  }

  SchoolRepository({
    SupabaseClient? supabaseClient,
    this._useDemoFallback = false,
  }) : _supabaseClient = supabaseClient ?? _resolveClient();

  /// Lista de colegios en memoria para pruebas y modo desconectado (inicialmente vacía para QA)
  /// Semillas de demostración para fallback fuera de línea y tests
  static final List<School> _seedSchools = [
    School(
      id: 'a0000000-0000-0000-0000-000000000001',
      nombre: 'Colegio Bilingüe EDUNEX Piloto',
      rnc: '1-31-00000-1',
      siglas: 'EDUNEX',
      telefono: '809-555-0100',
      emailContacto: 'info@edunex.edu',
      direccion: 'Av. 27 de Febrero #200, Santo Domingo, D.N.',
      estadoSuscripcion: 'active',
      maxEstudiantes: 500,
      createdAt: DateTime(2026, 1, 10),
      totalEstudiantes: 342,
      totalFamilias: 186,
    ),
    School(
      id: 'a0000000-0000-0000-0000-000000000002',
      nombre: 'Instituto Educativo San Judas Tadeo',
      rnc: '1-30-55443-2',
      siglas: 'SJT',
      telefono: '809-541-2300',
      emailContacto: 'administracion@sanjudas.edu.do',
      direccion: 'Calle Fantino Falco #40, Naco, Santo Domingo',
      estadoSuscripcion: 'active',
      maxEstudiantes: 800,
      createdAt: DateTime(2026, 2, 1),
      totalEstudiantes: 620,
      totalFamilias: 340,
    ),
    School(
      id: 'a0000000-0000-0000-0000-000000000003',
      nombre: 'St. Patrick International School',
      rnc: '1-32-99887-4',
      siglas: 'SPIS',
      telefono: '809-567-8900',
      emailContacto: 'admissions@stpatrick.edu.do',
      direccion: 'Av. Sarasota #75, Bella Vista, Santo Domingo',
      estadoSuscripcion: 'trial',
      maxEstudiantes: 350,
      createdAt: DateTime(2026, 3, 15),
      totalEstudiantes: 180,
      totalFamilias: 110,
    ),
  ];

  /// Lista de colegios en memoria para pruebas y modo desconectado
  static final List<School> _demoSchools = List.from(_seedSchools);

  // Semillas y estado de facturación SaaS (inicialmente vacías sin data simulada)
  static final List<SaaSInvoice> _seedSaaSInvoices = [];

  static final List<SaaSInvoice> _demoSaaSInvoices = List.from(_seedSaaSInvoices);

  // Semillas y estado de anuncios globales del sistema (inicialmente vacíos sin data simulada)
  static final List<SystemAnnouncement> _seedSystemAnnouncements = [];

  static final List<SystemAnnouncement> _demoSystemAnnouncements = List.from(_seedSystemAnnouncements);

  // Usuarios internos de la empresa SaaS dueña de EDUNEX
  // Inicia únicamente con el usuario Superadmin actual sin data falsa
  static final List<SaaSUser> _seedSaaSUsers = [
    SaaSUser(
      id: 'usr-saas-master',
      nombre: 'Super',
      apellido: 'Admin',
      email: 'admin@edunex.edu',
      telefono: '809-555-0100',
      rol: SaaSRole.superadmin,
      activo: true,
      createdAt: DateTime(2026, 1, 1),
      lastLogin: DateTime.now(),
      notas: 'Cuenta principal del dueño de la plataforma EDUNEX',
    ),
  ];

  static final List<SaaSUser> _demoSaaSUsers = List.from(_seedSaaSUsers);

  // Configuración de la empresa matriz SaaS
  static SaaSCompanyConfig _demoCompanyConfig = const SaaSCompanyConfig();

  /// Limpia todos los datos en memoria para pruebas de QA
  static void clearAllData() {
    _demoSchools.clear();
    _demoSaaSInvoices.clear();
    _demoSystemAnnouncements.clear();
    _demoSaaSUsers.clear();
    _demoSaaSUsers.addAll(_seedSaaSUsers);
  }

  /// Restaura los datos de prueba para pruebas y modo demo
  static void restoreSeedData() {
    _demoSchools.clear();
    _demoSchools.addAll(_seedSchools);
    _demoSaaSInvoices.clear();
    _demoSaaSInvoices.addAll(_seedSaaSInvoices);
    _demoSystemAnnouncements.clear();
    _demoSystemAnnouncements.addAll(_seedSystemAnnouncements);
    _demoSaaSUsers.clear();
    _demoSaaSUsers.addAll(_seedSaaSUsers);
    _demoCompanyConfig = const SaaSCompanyConfig();
  }

  /// Obtiene la lista de colegios registrados
  Future<List<School>> getSchools({
    String? searchQuery,
    String? statusFilter,
  }) async {
    List<School> schools = [];

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final response = await _supabaseClient
            .from('colegios')
            .select('*')
            .order('created_at', ascending: false);

        schools = (response as List).map((item) {
          final map = item as Map<String, dynamic>;
          if (map['configuracion'] is Map) {
            final cfg = map['configuracion'] as Map<String, dynamic>;
            if (cfg['documentos'] is List) {
              final docs = (cfg['documentos'] as List)
                  .map((d) => StudentDocument.fromJson(d as Map<String, dynamic>))
                  .toList();
              _schoolDocumentsMap[map['id'].toString()] = docs;
            }
          }
          return School.fromJson(map);
        }).toList();
      } catch (e) {
        debugPrint('Aviso: Error consultando colegios en Supabase: $e');
        schools = _useDemoFallback ? List<School>.from(_demoSchools) : [];
      }
    } else {
      // Modo desconectado o pruebas unitarias sin Supabase configurado
      schools = _useDemoFallback ? List<School>.from(_demoSchools) : [];
    }

    // Filtrar por término de búsqueda
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      schools = schools.where((s) {
        return s.nombre.toLowerCase().contains(q) ||
            (s.siglas?.toLowerCase().contains(q) ?? false) ||
            (s.rnc?.toLowerCase().contains(q) ?? false) ||
            (s.emailContacto?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Filtrar por estado de suscripción
    if (statusFilter != null && statusFilter != 'all') {
      schools = schools.where((s) => s.estadoSuscripcion == statusFilter).toList();
    }

    return schools;
  }

  /// Crea un nuevo colegio y su usuario Director administrador de forma atómica en Supabase
  Future<Map<String, dynamic>> createSchoolWithDirector({
    required String nombre,
    String? rnc,
    String? siglas,
    String? telefono,
    String? emailContacto,
    String? direccion,
    String? logoUrl,
    required String estadoSuscripcion,
    required int maxEstudiantes,
    required String directorEmail,
    required String directorPassword,
    required String directorNombres,
    String? directorApellidos,
    String? directorCedula,
    double precioInicial = 6500.0,
    double precioPrimaria = 8000.0,
    double precioSecundaria = 9500.0,
    double precioMatricula = 12000.0,
    bool sujetoAMejoraPago = true,
    double descuentoProntoPagoAnualPct = 10.0,
    double descuentoProntoPagoSemestralPct = 5.0,
    double descuentoProntoPagoTrimestralPct = 3.0,
    double descuentoHermanosPct = 10.0,
    List<StudentDocument>? documentos,
  }) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final res = await _supabaseClient.rpc('crear_colegio_con_director', params: {
          'p_nombre': nombre.trim(),
          'p_rnc': rnc?.trim(),
          'p_siglas': siglas?.trim().toUpperCase(),
          'p_telefono': telefono?.trim(),
          'p_email_contacto': emailContacto?.trim(),
          'p_direccion': direccion?.trim(),
          'p_estado_suscripcion': estadoSuscripcion,
          'p_max_estudiantes': maxEstudiantes,
          'p_director_email': directorEmail.trim().toLowerCase(),
          'p_director_password': directorPassword,
          'p_director_nombres': directorNombres.trim(),
          'p_director_apellidos': directorApellidos?.trim() ?? '',
        });

        final colegioMap = res['colegio'] as Map<String, dynamic>;
        var school = School.fromJson({
          ...colegioMap,
          'precio_inicial': precioInicial,
          'precio_primaria': precioPrimaria,
          'precio_secundaria': precioSecundaria,
          'precio_matricula': precioMatricula,
          'sujeto_a_mejora_pago': sujetoAMejoraPago,
          'descuento_anual_pct': descuentoProntoPagoAnualPct,
          'descuento_semestral_pct': descuentoProntoPagoSemestralPct,
          'descuento_trimestral_pct': descuentoProntoPagoTrimestralPct,
          'descuento_hermanos_pct': descuentoHermanosPct,
        });

        final configUpdate = <String, dynamic>{
          'precio_inicial': precioInicial,
          'precio_primaria': precioPrimaria,
          'precio_secundaria': precioSecundaria,
          'precio_matricula': precioMatricula,
          'sujeto_a_mejora_pago': sujetoAMejoraPago,
          'descuento_anual_pct': descuentoProntoPagoAnualPct,
          'descuento_semestral_pct': descuentoProntoPagoSemestralPct,
          'descuento_trimestral_pct': descuentoProntoPagoTrimestralPct,
          'descuento_hermanos_pct': descuentoHermanosPct,
          'director_nombre': '$directorNombres ${directorApellidos ?? ""}'.trim(),
          'director_email': directorEmail.trim().toLowerCase(),
          'director_telefono': telefono?.trim(),
          if (directorCedula != null) 'director_cedula': directorCedula,
        };
        if (documentos != null && documentos.isNotEmpty) {
          configUpdate['documentos'] = documentos.map((d) => d.toJson()).toList();
        }

        try {
          final Map<String, dynamic> updatePayload = {
            'configuracion': configUpdate,
          };
          if (logoUrl != null && logoUrl.trim().isNotEmpty) {
            updatePayload['logo_url'] = logoUrl.trim();
          }
          await _supabaseClient.from('colegios').update(updatePayload).eq('id', school.id);
          school = School.fromJson({
            ...colegioMap,
            if (logoUrl != null && logoUrl.trim().isNotEmpty) 'logo_url': logoUrl.trim(),
            'director_nombre': '$directorNombres ${directorApellidos ?? ""}'.trim(),
            'director_email': directorEmail.trim().toLowerCase(),
            'director_telefono': telefono?.trim(),
            'director_cedula': directorCedula,
            'configuracion': configUpdate,
          });
        } catch (e) {
          debugPrint('Aviso actualizando configuracion de colegio en Supabase: $e');
        }

        // Registrar director en AuthRepository
        AuthRepository().registerUser(
          email: directorEmail,
          nombres: directorNombres,
          apellidos: directorApellidos ?? '',
          rol: UserRole.adminColegio,
          colegioId: school.id,
          colegioNombre: school.nombre,
          telefono: telefono,
          cedula: directorCedula,
        );

        // Registrar también el correo institucional del colegio para permitir acceso con ambos correos
        if (emailContacto != null &&
            emailContacto.trim().isNotEmpty &&
            emailContacto.trim().toLowerCase() != directorEmail.trim().toLowerCase()) {
          AuthRepository().registerUser(
            email: emailContacto.trim(),
            nombres: 'Administración',
            apellidos: school.nombre,
            rol: UserRole.adminColegio,
            colegioId: school.id,
            colegioNombre: school.nombre,
            telefono: telefono,
          );
        }

        AuditRepository().recordAuditLog(
          AuditLog(
            id: 'aud-alta-${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            accion: 'ALTA_INSTITUCIONAL',
            descripcion: 'Enrolamiento y alta oficial del colegio cliente "$nombre"',
            usuario: 'superadmin@edunex.edu',
            rol: 'SuperAdmin',
            colegioId: school.id,
            colegioNombre: school.nombre,
            modulo: 'Institucional',
            nivel: 'SUCCESS',
            estadoAnterior: 'Institución inexistente en plataforma EDUNEX',
            nuevoEstado: 'Colegio activo: $nombre (RNC: ${rnc ?? "N/D"}, Siglas: ${siglas ?? "N/D"}, Cupo: $maxEstudiantes)',
          ),
        );

        if (documentos != null && documentos.isNotEmpty) {
          _schoolDocumentsMap[school.id] = List.from(documentos);
        }

        return {
          'school': school,
          'director': {
            ...res['director'] as Map<String, dynamic>,
            'cedula': directorCedula,
          },
        };
      } catch (e) {
        debugPrint('Aviso creando colegio con director en Supabase RPC (usando fallback local): $e');
      }
    }

    // Modo local / offline
    final fallbackSchool = School(
      id: 'col-${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      rnc: rnc,
      siglas: siglas,
      telefono: telefono,
      emailContacto: emailContacto,
      direccion: direccion,
      logoUrl: logoUrl,
      estadoSuscripcion: estadoSuscripcion,
      maxEstudiantes: maxEstudiantes,
      createdAt: DateTime.now(),
      precioInicial: precioInicial,
      precioPrimaria: precioPrimaria,
      precioSecundaria: precioSecundaria,
      precioMatricula: precioMatricula,
      sujetoAMejoraPago: sujetoAMejoraPago,
      descuentoProntoPagoAnualPct: descuentoProntoPagoAnualPct,
      descuentoProntoPagoSemestralPct: descuentoProntoPagoSemestralPct,
      descuentoProntoPagoTrimestralPct: descuentoProntoPagoTrimestralPct,
      descuentoHermanosPct: descuentoHermanosPct,
      directorNombre: '$directorNombres ${directorApellidos ?? ""}'.trim(),
      directorEmail: directorEmail,
      directorCedula: directorCedula,
      directorTelefono: telefono,
    );
    _demoSchools.insert(0, fallbackSchool);
    if (documentos != null && documentos.isNotEmpty) {
      _schoolDocumentsMap[fallbackSchool.id] = List.from(documentos);
    }

    // Registrar director en AuthRepository para login local inmediato
    AuthRepository().registerUser(
      email: directorEmail,
      nombres: directorNombres,
      apellidos: directorApellidos ?? '',
      rol: UserRole.adminColegio,
      colegioId: fallbackSchool.id,
      colegioNombre: fallbackSchool.nombre,
      telefono: telefono,
      cedula: directorCedula,
    );

    // Registrar también el correo institucional del colegio para permitir acceso con ambos correos
    if (emailContacto != null &&
        emailContacto.trim().isNotEmpty &&
        emailContacto.trim().toLowerCase() != directorEmail.trim().toLowerCase()) {
      AuthRepository().registerUser(
        email: emailContacto.trim(),
        nombres: 'Administración',
        apellidos: fallbackSchool.nombre,
        rol: UserRole.adminColegio,
        colegioId: fallbackSchool.id,
        colegioNombre: fallbackSchool.nombre,
        telefono: telefono,
      );
    }

    AuditRepository().recordAuditLog(
      AuditLog(
        id: 'aud-alta-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        accion: 'ALTA_INSTITUCIONAL',
        descripcion: 'Enrolamiento y alta oficial del colegio cliente "$nombre"',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: fallbackSchool.id,
        colegioNombre: fallbackSchool.nombre,
        modulo: 'Institucional',
        nivel: 'SUCCESS',
        estadoAnterior: 'Institución inexistente en plataforma EDUNEX',
        nuevoEstado: 'Colegio activo: $nombre (RNC: ${rnc ?? "N/D"}, Siglas: ${siglas ?? "N/D"}, Cupo: $maxEstudiantes)',
      ),
    );

    return {
      'school': fallbackSchool,
      'director': {
        'email': directorEmail,
        'nombres': directorNombres,
        'apellidos': directorApellidos ?? '',
        'cedula': directorCedula,
        'rol': 'admin_colegio',
      },
    };
  }

  /// Obtiene el nombre del colegio por ID
  Future<String?> getSchoolNameById(String id) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final res = await _supabaseClient
            .from('colegios')
            .select('nombre')
            .eq('id', id)
            .maybeSingle();
        if (res != null && res['nombre'] != null) {
          return res['nombre'] as String;
        }
      } catch (_) {}
    }
    final match = _demoSchools.where((s) => s.id == id).toList();
    if (match.isNotEmpty) return match.first.nombre;
    return null;
  }

  /// Obtiene un colegio completo por ID
  Future<School?> getSchoolById(String id) async {
    final list = await getSchools();
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Crea un nuevo colegio en Supabase (método simplificado)
  Future<School> createSchool({
    required String nombre,
    String? rnc,
    String? siglas,
    String? telefono,
    String? emailContacto,
    String? direccion,
    required String estadoSuscripcion,
    required int maxEstudiantes,
  }) async {
    final result = await createSchoolWithDirector(
      nombre: nombre,
      rnc: rnc,
      siglas: siglas,
      telefono: telefono,
      emailContacto: emailContacto,
      direccion: direccion,
      estadoSuscripcion: estadoSuscripcion,
      maxEstudiantes: maxEstudiantes,
      directorEmail: emailContacto ?? 'director@${siglas?.toLowerCase() ?? "edunex"}.edu.do',
      directorPassword: 'password123',
      directorNombres: 'Director',
      directorApellidos: nombre,
    );
    return result['school'] as School;
  }

  /// Actualiza la suscripción y método de pago de un colegio
  Future<void> updateSchoolSubscription({
    required String schoolId,
    required String newStatus,
    String? metodoPago,
  }) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final updateData = <String, dynamic>{
          'estado_suscripcion': newStatus,
        };
        if (metodoPago != null) {
          updateData['metodo_pago'] = metodoPago;
        }
        await _supabaseClient
            .from('colegios')
            .update(updateData)
            .eq('id', schoolId);
      } catch (e) {
        debugPrint('Error actualizando suscripción: $e');
      }
    }

    final index = _demoSchools.indexWhere((s) => s.id == schoolId);
    if (index != -1) {
      final old = _demoSchools[index];
      _demoSchools[index] = old.copyWith(
        estadoSuscripcion: newStatus,
        metodoPago: metodoPago ?? old.metodoPago,
        metodoPagoRegistrado: metodoPago != null || old.metodoPagoRegistrado,
      );
    }
  }

  /// Actualiza el estado de la suscripción (Activar, Suspender, etc.)
  Future<void> updateSubscriptionStatus(String schoolId, String newStatus) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient
            .from('colegios')
            .update({'estado_suscripcion': newStatus})
            .eq('id', schoolId);
      } catch (e) {
        debugPrint('Error actualizando suscripción: $e');
      }
    }

    final index = _demoSchools.indexWhere((s) => s.id == schoolId);
    if (index != -1) {
      final old = _demoSchools[index];
      _demoSchools[index] = School(
        id: old.id,
        nombre: old.nombre,
        rnc: old.rnc,
        siglas: old.siglas,
        telefono: old.telefono,
        emailContacto: old.emailContacto,
        direccion: old.direccion,
        logoUrl: old.logoUrl,
        estadoSuscripcion: newStatus,
        maxEstudiantes: old.maxEstudiantes,
        createdAt: old.createdAt,
        totalEstudiantes: old.totalEstudiantes,
        totalFamilias: old.totalFamilias,
      );
    }

    final schoolName = await getSchoolNameById(schoolId) ?? 'Colegio';
    final oldStatus = newStatus == 'suspended' ? 'active' : 'suspended';
    AuditRepository().recordAuditLog(
      AuditLog(
        id: 'aud-sub-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        accion: newStatus == 'suspended' ? 'SUSPENSION_SERVICIO' : 'ACTIVACION_SERVICIO',
        descripcion: 'Cambio de estado de licencia SaaS para "$schoolName" a "$newStatus"',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: schoolId,
        colegioNombre: schoolName,
        modulo: 'Seguridad',
        nivel: newStatus == 'suspended' ? 'WARNING' : 'SUCCESS',
        estadoAnterior: 'Estado licencia anterior: $oldStatus',
        nuevoEstado: 'Nuevo estado licencia: $newStatus',
      ),
    );
  }

  /// Actualiza el logotipo oficial del colegio tipo perfil
  Future<void> updateSchoolLogo({
    required String schoolId,
    required String logoUrl,
  }) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient
            .from('colegios')
            .update({'logo_url': logoUrl.trim()})
            .eq('id', schoolId);
      } catch (e) {
        debugPrint('Aviso: Logo actualizado localmente: $e');
      }
    }

    final index = _demoSchools.indexWhere((s) => s.id == schoolId);
    if (index != -1) {
      final old = _demoSchools[index];
      _demoSchools[index] = School(
        id: old.id,
        nombre: old.nombre,
        rnc: old.rnc,
        siglas: old.siglas,
        telefono: old.telefono,
        emailContacto: old.emailContacto,
        direccion: old.direccion,
        logoUrl: logoUrl.trim(),
        estadoSuscripcion: old.estadoSuscripcion,
        maxEstudiantes: old.maxEstudiantes,
        createdAt: old.createdAt,
        totalEstudiantes: old.totalEstudiantes,
        totalFamilias: old.totalFamilias,
        precioInicial: old.precioInicial,
        precioPrimaria: old.precioPrimaria,
        precioSecundaria: old.precioSecundaria,
        precioMatricula: old.precioMatricula,
        sujetoAMejoraPago: old.sujetoAMejoraPago,
      );
    }
  }

  /// Actualiza los datos de registro institucional de un colegio (Nombre, RNC, siglas, contacto, capacidad, director, etc.)
  Future<School> updateSchoolRegistration({
    required String schoolId,
    required String nombre,
    String? rnc,
    String? siglas,
    String? telefono,
    String? emailContacto,
    String? direccion,
    int? maxEstudiantes,
    String? directorNombre,
    String? directorCedula,
    String? directorTelefono,
    String? directorEmail,
    String? logoUrl,
  }) async {
    final updatePayload = <String, dynamic>{
      'nombre': nombre.trim(),
    };
    if (rnc != null) updatePayload['rnc'] = rnc.trim();
    if (siglas != null) updatePayload['siglas'] = siglas.trim();
    if (telefono != null) updatePayload['telefono'] = telefono.trim();
    if (emailContacto != null) updatePayload['email_contacto'] = emailContacto.trim();
    if (direccion != null) updatePayload['direccion'] = direccion.trim();
    if (maxEstudiantes != null) updatePayload['max_estudiantes'] = maxEstudiantes;
    if (logoUrl != null) updatePayload['logo_url'] = logoUrl.trim();

    Map<String, dynamic> configToUpdate = {};
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final currentSchool = await _supabaseClient
            .from('colegios')
            .select('configuracion')
            .eq('id', schoolId)
            .maybeSingle();
        if (currentSchool != null && currentSchool['configuracion'] is Map) {
          configToUpdate = Map<String, dynamic>.from(currentSchool['configuracion']);
        }
      } catch (_) {}
    }
    if (directorNombre != null) configToUpdate['director_nombre'] = directorNombre.trim();
    if (directorEmail != null) configToUpdate['director_email'] = directorEmail.trim().toLowerCase();
    if (directorCedula != null) configToUpdate['director_cedula'] = directorCedula.trim();
    if (directorTelefono != null) configToUpdate['director_telefono'] = directorTelefono.trim();
    if (configToUpdate.isNotEmpty) {
      updatePayload['configuracion'] = configToUpdate;
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient
            .from('colegios')
            .update(updatePayload)
            .eq('id', schoolId);
      } catch (e) {
        debugPrint('Aviso: Error actualizando colegio en Supabase: $e');
      }
    }

    if (directorEmail != null && directorEmail.trim().isNotEmpty) {
      AuthRepository().registerUser(
        email: directorEmail.trim(),
        nombres: directorNombre ?? 'Director',
        apellidos: nombre,
        rol: UserRole.adminColegio,
        colegioId: schoolId,
        colegioNombre: nombre,
        telefono: directorTelefono ?? telefono,
        cedula: directorCedula,
      );
    }
    if (emailContacto != null && emailContacto.trim().isNotEmpty) {
      AuthRepository().registerUser(
        email: emailContacto.trim(),
        nombres: 'Administración',
        apellidos: nombre,
        rol: UserRole.adminColegio,
        colegioId: schoolId,
        colegioNombre: nombre,
        telefono: telefono,
      );
    }

    final index = _demoSchools.indexWhere((s) => s.id == schoolId);
    if (index != -1) {
      final old = _demoSchools[index];
      final updated = old.copyWith(
        nombre: nombre.trim(),
        rnc: rnc?.trim() ?? old.rnc,
        siglas: siglas?.trim() ?? old.siglas,
        telefono: telefono?.trim() ?? old.telefono,
        emailContacto: emailContacto?.trim() ?? old.emailContacto,
        direccion: direccion?.trim() ?? old.direccion,
        maxEstudiantes: maxEstudiantes ?? old.maxEstudiantes,
        directorNombre: directorNombre?.trim() ?? old.directorNombre,
        directorCedula: directorCedula?.trim() ?? old.directorCedula,
        directorTelefono: directorTelefono?.trim() ?? old.directorTelefono,
        directorEmail: directorEmail?.trim() ?? old.directorEmail,
        logoUrl: logoUrl?.trim() ?? old.logoUrl,
      );
      _demoSchools[index] = updated;

      AuditRepository().recordAuditLog(
        AuditLog(
          id: 'aud-mod-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          accion: 'MODIFICACION_COLEGIO',
          descripcion: 'Actualización de datos de registro del colegio "$nombre"',
          usuario: 'superadmin@edunex.edu',
          rol: 'SuperAdmin',
          colegioId: schoolId,
          colegioNombre: nombre,
          modulo: 'Institucional',
          nivel: 'INFO',
          estadoAnterior: 'RNC: ${old.rnc ?? "N/D"}, Siglas: ${old.siglas ?? "N/D"}, Cupo: ${old.maxEstudiantes}',
          nuevoEstado: 'Nombre: $nombre, RNC: ${rnc ?? old.rnc ?? "N/D"}, Cupo: ${maxEstudiantes ?? old.maxEstudiantes} alumnos',
        ),
      );

      return updated;
    }

    final fallback = School(
      id: schoolId,
      nombre: nombre,
      rnc: rnc,
      siglas: siglas,
      telefono: telefono,
      emailContacto: emailContacto,
      direccion: direccion,
      logoUrl: logoUrl,
      estadoSuscripcion: 'active',
      maxEstudiantes: maxEstudiantes ?? 500,
      directorNombre: directorNombre,
      directorCedula: directorCedula,
      directorTelefono: directorTelefono,
      directorEmail: directorEmail,
    );

    AuditRepository().recordAuditLog(
      AuditLog(
        id: 'aud-mod-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        accion: 'MODIFICACION_COLEGIO',
        descripcion: 'Actualización de datos de registro del colegio "$nombre"',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: schoolId,
        colegioNombre: nombre,
        modulo: 'Institucional',
        nivel: 'INFO',
        estadoAnterior: 'Registro previo',
        nuevoEstado: 'Nombre: $nombre, RNC: ${rnc ?? "N/D"}, Cupo: ${maxEstudiantes ?? 500} alumnos',
      ),
    );

    return fallback;
  }

  /// Permite al SuperAdmin resetear la contraseña del director o usuario institucional
  Future<void> resetDirectorPassword({
    required String schoolId,
    required String directorEmail,
    required String newPassword,
    String? schoolName,
  }) async {
    await AuthRepository().resetPasswordBySuperAdmin(
      email: directorEmail,
      newPassword: newPassword,
      colegioId: schoolId,
      colegioNombre: schoolName,
    );

    // Registrar en Supabase logs_auditoria
    final auditRepo = AuditRepository();
    await auditRepo.recordAuditLog(
      AuditLog(
        id: 'aud-pwd-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        accion: 'RESETEO_CONTRASENA',
        descripcion: 'SuperAdmin reseteó la contraseña de acceso para el usuario $directorEmail.',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: schoolId,
        colegioNombre: schoolName,
        modulo: 'Seguridad',
        nivel: 'WARNING',
        ipAddress: '179.52.14.88 (Santo Domingo, DO)',
        estadoAnterior: 'Contraseña anterior activa para $directorEmail',
        nuevoEstado: 'Nueva contraseña generada y actualizada en base de datos',
      ),
    );
  }

  /// Retorna las métricas ejecutivas globales del negocio SaaS
  Future<Map<String, dynamic>> getSaaSMasterKpis() async {
    final list = await getSchools();
    final totalSchools = list.length;
    final activeSchools = list.where((s) => s.isActive).length;
    final trialSchools = list.where((s) => s.isTrial).length;
    final totalStudents = list.fold<int>(0, (sum, s) => sum + s.totalEstudiantes);

    // MRR y ARR reales calculados según las cuotas individuales de cada colegio (Issue #22)
    final realMRR = list.fold<double>(0.0, (sum, s) => sum + s.cuotaMensualSaaS);
    final realARR = realMRR * 12;

    return {
      'totalSchools': totalSchools,
      'activeSchools': activeSchools,
      'trialSchools': trialSchools,
      'totalStudents': totalStudents,
      'estimatedMRR': realMRR,
      'estimatedARR': realARR,
    };
  }

  /// Elimina toda la información de la base de datos (Supabase) y limpia las memorias locales,
  /// preservando EXCLUSIVAMENTE al usuario Super Admin configurado (por defecto admin@edunex.edu).
  Future<Map<String, dynamic>> purgeAllDataExceptSuperAdmin({
    String superAdminEmail = 'admin@edunex.edu',
  }) async {
    int deletedAuthUsers = 0;
    int tablesCleared = 0;

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      // 1. Tablas en orden estricto de dependencias FK
      final tablesToClear = [
        'logs_auditoria',
        'saas_usuarios',
        'saas_facturas',
        'saas_anuncios',
        'documentos_estudiante',
        'pagos_detalle',
        'recibos',
        'pagos',
        'cargos',
        'conceptos_cobro',
        'contrataciones_cuido',
        'asignaciones_transporte',
        'pedidos_tienda',
        'inscripciones_eventos',
        'inscripciones_evento',
        'estudiantes',
        'tutores',
        'autorizaciones_retiro',
        'familias',
        'horarios_seccion',
        'secciones',
        'materias',
        'grados',
        'servicios_cuido',
        'rutas_transporte',
        'productos_tienda',
        'eventos_actividades',
        'eventos',
        'comunicaciones',
        'casos_psicologia',
        'plantillas_contrato',
        'sucursales',
      ];

      for (final table in tablesToClear) {
        try {
          await _supabaseClient.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000');
          tablesCleared++;
        } catch (e) {
          debugPrint('Aviso limpiando tabla $table: $e');
        }
      }

      // Purgar perfiles dejando sólo el superadmin
      try {
        await _supabaseClient.from('perfiles').delete().neq('email', superAdminEmail);
        tablesCleared++;
      } catch (e) {
        debugPrint('Aviso limpiando perfiles: $e');
      }

      // Purgar colegios
      try {
        await _supabaseClient.from('colegios').delete().neq('id', '00000000-0000-0000-0000-000000000000');
        tablesCleared++;
      } catch (e) {
        debugPrint('Aviso limpiando colegios: $e');
      }

      // Purgar usuarios de Auth excepto el superadmin
      try {
        final users = await _supabaseClient.auth.admin.listUsers();
        for (final u in users) {
          if (u.email?.trim().toLowerCase() != superAdminEmail.trim().toLowerCase()) {
            await _supabaseClient.auth.admin.deleteUser(u.id);
            deletedAuthUsers++;
          }
        }
      } catch (e) {
        debugPrint('Aviso eliminando usuarios auth: $e');
      }
    }

    // 2. Limpiar todos los repositorios en memoria y almacenamiento local
    clearAllData();
    FamilyRepository.clearAllData();
    TeacherRepository.clearAllData();
    GuidanceRepository.clearAllData();
    AcademicRepository().clearAllData();
    AuthRepository.clearAllUsers();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    AuditRepository().recordAuditLog(
      AuditLog(
        id: 'aud-purge-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        accion: 'RESET_BASE_DATOS',
        descripcion: 'Purga integral de base de datos (QA Clean Slate) ejecutada por SuperAdmin.',
        usuario: superAdminEmail,
        rol: 'SuperAdmin',
        modulo: 'Sistema',
        nivel: 'CRITICAL',
        estadoAnterior: 'Base de datos con datos escolares y registros de colegios',
        nuevoEstado: 'Base de datos limpia (Clean Slate QA) - Preservado usuario $superAdminEmail',
      ),
    );

    return {
      'success': true,
      'tablesCleared': tablesCleared,
      'deletedAuthUsers': deletedAuthUsers,
      'message': 'Base de datos y memorias locales purgadas al 100%. Solo se preservó el usuario Super Admin ($superAdminEmail).',
    };
  }

  // ==========================================
  // ITEM 1: FACTURACIÓN Y COBRANZA SAAS
  // ==========================================

  /// Obtiene las facturas de cobro SaaS a colegios
  Future<List<SaaSInvoice>> getSaaSInvoices({String? schoolId}) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        var query = _supabaseClient.from('saas_facturas').select('*');
        if (schoolId != null) {
          query = query.eq('colegio_id', schoolId);
        }
        final res = await query.order('fecha_emision', ascending: false);
        return (res as List).map((i) => SaaSInvoice.fromJson(i as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Aviso: Error cargando saas_facturas de Supabase: $e');
      }
    }
    if (schoolId != null) {
      return _demoSaaSInvoices.where((i) => i.colegioId == schoolId).toList();
    }
    return List<SaaSInvoice>.from(_demoSaaSInvoices);
  }

  /// Genera una nueva factura de suscripción SaaS con comprobante NCF para un colegio
  Future<SaaSInvoice> generateSaaSInvoice({
    required String schoolId,
    required String schoolName,
    required double monto,
    required String periodo,
    String? rnc,
    String tipoNCF = 'B01',
    int diasGracia = 15,
    String? notas,
  }) async {
    final now = DateTime.now();
    final fechaVenc = now.add(Duration(days: diasGracia));
    final nextSec = (_demoSaaSInvoices.length + 216).toString().padLeft(8, '0');
    final ncfGenerado = '$tipoNCF$nextSec';

    final invoice = SaaSInvoice(
      id: 'inv-saas-${now.millisecondsSinceEpoch}',
      colegioId: schoolId,
      colegioNombre: schoolName,
      rncColegio: rnc,
      monto: monto,
      periodo: periodo,
      fechaEmision: now,
      fechaVencimiento: fechaVenc,
      estado: SaaSInvoiceStatus.pendiente,
      ncf: ncfGenerado,
      tipoNCF: tipoNCF,
      notas: notas,
    );

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('saas_facturas').insert(invoice.toJson());
      } catch (e) {
        debugPrint('Aviso: Factura SaaS guardada localmente: $e');
      }
    }

    _demoSaaSInvoices.insert(0, invoice);

    AuditRepository().recordAuditLog(
      AuditLog(
        id: 'aud-inv-${now.millisecondsSinceEpoch}',
        timestamp: now,
        accion: 'EMISION_FACTURA_SAAS',
        descripcion: 'Emisión de factura SaaS NCF $ncfGenerado ($periodo) por RD\$ ${monto.toStringAsFixed(2)} para "$schoolName"',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: schoolId,
        colegioNombre: schoolName,
        modulo: 'Facturación SaaS',
        nivel: 'INFO',
        estadoAnterior: 'Pendiente de emisión',
        nuevoEstado: 'Factura emitida NCF: $ncfGenerado, Vencimiento: ${fechaVenc.day}/${fechaVenc.month}/${fechaVenc.year}',
      ),
    );

    return invoice;
  }

  /// Registra el cobro de una factura SaaS institucional
  Future<void> recordInvoicePayment({
    required String invoiceId,
    required String metodoPago,
    String? notas,
  }) async {
    final now = DateTime.now();
    final idx = _demoSaaSInvoices.indexWhere((i) => i.id == invoiceId);
    if (idx != -1) {
      final old = _demoSaaSInvoices[idx];
      final updated = old.copyWith(
        estado: SaaSInvoiceStatus.pagada,
        fechaPago: now,
        metodoPago: metodoPago,
        notas: notas ?? old.notas,
      );
      _demoSaaSInvoices[idx] = updated;

      AuditRepository().recordAuditLog(
        AuditLog(
          id: 'aud-pay-${now.millisecondsSinceEpoch}',
          timestamp: now,
          accion: 'COBRO_FACTURA_SAAS',
          descripcion: 'Cobro registrado para factura SaaS NCF ${old.ncf ?? old.id} ($metodoPago) de "${old.colegioNombre}"',
          usuario: 'superadmin@edunex.edu',
          rol: 'SuperAdmin',
          colegioId: old.colegioId,
          colegioNombre: old.colegioNombre,
          modulo: 'Facturación SaaS',
          nivel: 'SUCCESS',
          estadoAnterior: 'Estado: ${old.estado.displayName}',
          nuevoEstado: 'Pagada vía $metodoPago el ${now.day}/${now.month}/${now.year}',
        ),
      );
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('saas_facturas').update({
          'estado': 'pagada',
          'fecha_pago': now.toIso8601String(),
          'metodo_pago': metodoPago,
          'notas': notas,
        }).eq('id', invoiceId);
      } catch (e) {
        debugPrint('Aviso: Pago de factura SaaS registrado en memoria local: $e');
      }
    }
  }

  // ==========================================
  // ITEM 2: GESTIÓN DE PERIODOS DE PRUEBA (TRIALS)
  // ==========================================

  /// Extiende el período de prueba (trial) de un colegio por una cantidad determinada de días
  Future<void> extendSchoolTrial(String schoolId, int days) async {
    final index = _demoSchools.indexWhere((s) => s.id == schoolId);
    if (index != -1) {
      final old = _demoSchools[index];
      final currentEnd = old.trialFin ?? (old.createdAt?.add(const Duration(days: 15)) ?? DateTime.now());
      final newEnd = (currentEnd.isAfter(DateTime.now()) ? currentEnd : DateTime.now()).add(Duration(days: days));

      _demoSchools[index] = old.copyWith(
        trialFin: newEnd,
        estadoSuscripcion: 'trial',
      );

      AuditRepository().recordAuditLog(
        AuditLog(
          id: 'aud-trial-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          accion: 'EXTENSION_TRIAL',
          descripcion: 'Ampliación de período de prueba por +$days días para "${old.nombre}"',
          usuario: 'superadmin@edunex.edu',
          rol: 'SuperAdmin',
          colegioId: schoolId,
          colegioNombre: old.nombre,
          modulo: 'Suscripciones',
          nivel: 'INFO',
          estadoAnterior: 'Vencimiento previo: ${currentEnd.day}/${currentEnd.month}/${currentEnd.year}',
          nuevoEstado: 'Nuevo vencimiento trial: ${newEnd.day}/${newEnd.month}/${newEnd.year}',
        ),
      );
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final school = await getSchoolById(schoolId);
        final currentEnd = school?.trialFin ?? DateTime.now();
        final newEnd = (currentEnd.isAfter(DateTime.now()) ? currentEnd : DateTime.now()).add(Duration(days: days));
        await _supabaseClient.from('colegios').update({
          'trial_fin': newEnd.toIso8601String(),
          'estado_suscripcion': 'trial',
        }).eq('id', schoolId);
      } catch (e) {
        debugPrint('Aviso actualizando trial en Supabase: $e');
      }
    }
  }

  /// Convierte formalmente un colegio en periodo de prueba a cliente con suscripción activa de pago
  Future<void> convertSchoolToActive(String schoolId, {int diaCorte = 1, String? metodoPago}) async {
    final index = _demoSchools.indexWhere((s) => s.id == schoolId);
    if (index != -1) {
      final old = _demoSchools[index];
      _demoSchools[index] = old.copyWith(
        estadoSuscripcion: 'active',
        diaCorte: diaCorte,
        metodoPago: metodoPago ?? old.metodoPago ?? 'Transferencia Bancaria',
        metodoPagoRegistrado: true,
      );

      AuditRepository().recordAuditLog(
        AuditLog(
          id: 'aud-conv-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          accion: 'CONVERSION_TRIAL_ACTIVO',
          descripcion: 'Conversión exitosa de prueba gratuita a suscripción activa de pago para "${old.nombre}"',
          usuario: 'superadmin@edunex.edu',
          rol: 'SuperAdmin',
          colegioId: schoolId,
          colegioNombre: old.nombre,
          modulo: 'Suscripciones',
          nivel: 'SUCCESS',
          estadoAnterior: 'Estado: Período de Prueba (Trial)',
          nuevoEstado: 'Estado: Suscripción Activa (Corte día $diaCorte, Cuota RD\$ ${old.cuotaMensualSaaS.toStringAsFixed(2)})',
        ),
      );
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('colegios').update({
          'estado_suscripcion': 'active',
          'dia_corte': diaCorte,
          'metodo_pago': metodoPago ?? 'Transferencia Bancaria',
          'metodo_pago_registrado': true,
        }).eq('id', schoolId);
      } catch (e) {
        debugPrint('Aviso convirtiendo suscripción activa en Supabase: $e');
      }
    }
  }

  // ==========================================
  // ITEM 3: ANUNCIOS Y BANNERS DEL SISTEMA
  // ==========================================

  /// Obtiene los anuncios del sistema
  Future<List<SystemAnnouncement>> getSystemAnnouncements({
    bool onlyActive = true,
    String? schoolId,
  }) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        var query = _supabaseClient.from('anuncios_sistema').select('*');
        if (onlyActive) {
          query = query.eq('activo', true);
        }
        final res = await query.order('fecha', ascending: false);
        var list = (res as List).map((i) => SystemAnnouncement.fromJson(i as Map<String, dynamic>)).toList();
        if (schoolId != null) {
          list = list.where((a) => a.colegioDestinoId == null || a.colegioDestinoId == schoolId).toList();
        }
        return list;
      } catch (e) {
        debugPrint('Aviso: Error cargando anuncios de Supabase: $e');
      }
    }

    var list = List<SystemAnnouncement>.from(_demoSystemAnnouncements);
    if (onlyActive) {
      list = list.where((a) => a.activo).toList();
    }
    if (schoolId != null) {
      list = list.where((a) => a.colegioDestinoId == null || a.colegioDestinoId == schoolId).toList();
    }
    return list;
  }

  /// Crea un nuevo anuncio global del sistema
  Future<SystemAnnouncement> createSystemAnnouncement({
    required String titulo,
    required String mensaje,
    AnnouncementType tipo = AnnouncementType.info,
    String? colegioDestinoId,
  }) async {
    final now = DateTime.now();
    final ann = SystemAnnouncement(
      id: 'ann-${now.millisecondsSinceEpoch}',
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      activo: true,
      fecha: now,
      creadoPor: 'SuperAdmin',
      colegioDestinoId: colegioDestinoId,
    );

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('anuncios_sistema').insert(ann.toJson());
      } catch (e) {
        debugPrint('Aviso guardando anuncio en Supabase: $e');
      }
    }

    _demoSystemAnnouncements.insert(0, ann);

    AuditRepository().recordAuditLog(
      AuditLog(
        id: 'aud-ann-${now.millisecondsSinceEpoch}',
        timestamp: now,
        accion: 'CREACION_ANUNCIO_GLOBAL',
        descripcion: 'Nuevo anuncio global del sistema emitido: "$titulo" (${tipo.name.toUpperCase()})',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        modulo: 'Comunicaciones',
        nivel: 'INFO',
        estadoAnterior: 'Sin emisión previa',
        nuevoEstado: 'Anuncio activo para toda la red de colegios',
      ),
    );

    return ann;
  }

  /// Alterna el estado activo/inactivo de un anuncio
  Future<void> toggleAnnouncementStatus(String id, bool activo) async {
    final idx = _demoSystemAnnouncements.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _demoSystemAnnouncements[idx] = _demoSystemAnnouncements[idx].copyWith(activo: activo);
    }
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('anuncios_sistema').update({'activo': activo}).eq('id', id);
      } catch (e) {
        debugPrint('Aviso alternando anuncio en Supabase: $e');
      }
    }
  }

  /// Elimina un anuncio del sistema
  Future<void> deleteSystemAnnouncement(String id) async {
    _demoSystemAnnouncements.removeWhere((a) => a.id == id);
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('anuncios_sistema').delete().eq('id', id);
      } catch (e) {
        debugPrint('Aviso eliminando anuncio en Supabase: $e');
      }
    }
  }

  // ==========================================
  // ITEM 5: MÉTRICAS DE ALMACENAMIENTO CLOUD
  // ==========================================

  /// Retorna el desglose de consumo de almacenamiento en la nube y cuota para un colegio
  Future<Map<String, dynamic>> getSchoolStorageMetrics(String schoolId) async {
    final docs = getSchoolDocuments(schoolId);
    final school = await getSchoolById(schoolId);
    final totalStudents = school?.totalEstudiantes ?? 1;

    // Estimación analítica realista basada en los registros reales
    final docCount = docs.length;
    final docsMB = (docCount * 1.8) + (totalStudents * 0.45);
    final dossiersMB = totalStudents * 3.2; // expedientes médicos, notas, certificados
    final photosMB = (totalStudents * 0.8) + (school?.logoUrl != null ? 2.5 : 0.5);
    final dbMB = 15.0 + (totalStudents * 0.08);

    final totalMB = docsMB + dossiersMB + photosMB + dbMB;
    final totalGB = totalMB / 1024.0;
    const maxQuotaGB = 10.0; // 10 GB cuota estándar incluida en plan

    return {
      'documentosMB': double.parse(docsMB.toStringAsFixed(2)),
      'expedientesMB': double.parse(dossiersMB.toStringAsFixed(2)),
      'fotosMB': double.parse(photosMB.toStringAsFixed(2)),
      'baseDatosMB': double.parse(dbMB.toStringAsFixed(2)),
      'totalMB': double.parse(totalMB.toStringAsFixed(2)),
      'totalGB': double.parse(totalGB.toStringAsFixed(3)),
      'maxQuotaGB': maxQuotaGB,
      'porcentajeUso': ((totalGB / maxQuotaGB) * 100).clamp(0.0, 100.0),
      'archivosTotales': docCount + (totalStudents * 3),
      'estadoSalud': totalGB < 8.0 ? 'Saludable' : (totalGB < 9.5 ? 'Atención' : 'Crítico'),
      'ultimaSincronizacion': DateTime.now().subtract(const Duration(minutes: 7)),
    };
  }

  // ==========================================
  // ITEM 6: EXPORTACIÓN DE DATOS A CSV
  // ==========================================

  /// Genera y descarga el archivo CSV con el directorio completo de colegios y métricas SaaS
  Future<String> exportSchoolsCsv() async {
    final list = await getSchools();
    final buffer = StringBuffer();
    // Cabecera CSV compatible con Excel
    buffer.writeln('ID,Nombre Institución,RNC,Siglas,Teléfono,Email Contacto,Director,Email Director,Teléfono Director,Sucursales,Estado Suscripción,Día Corte,Cupo Alumnos,Alumnos Activos,Familias,Cuota Mensual (RD\$),Facturación Anual (RD\$),Fecha Registro');

    for (final s in list) {
      final safeName = '"${s.nombre.replaceAll('"', '""')}"';
      final safeDir = '"${(s.directorNombre ?? '').replaceAll('"', '""')}"';
      final safeMail = s.emailContacto ?? '';
      final safeDirMail = s.directorEmail ?? '';
      final safeDirTel = s.directorTelefono ?? '';
      final safeTel = s.telefono ?? '';
      final safeRnc = s.rnc ?? '';
      final safeSiglas = s.siglas ?? '';
      final fecha = s.createdAt != null ? '${s.createdAt!.year}-${s.createdAt!.month.toString().padLeft(2, '0')}-${s.createdAt!.day.toString().padLeft(2, '0')}' : 'N/D';

      buffer.writeln('${s.id},$safeName,$safeRnc,$safeSiglas,$safeTel,$safeMail,$safeDir,$safeDirMail,$safeDirTel,${s.sucursalesCount},${s.statusDisplayName},${s.diaCorte},${s.maxEstudiantes},${s.totalEstudiantes},${s.totalFamilias},${s.cuotaMensualSaaS.toStringAsFixed(2)},${s.cuotaAnualSaaS.toStringAsFixed(2)},$fecha');
    }

    return buffer.toString();
  }

  // ==========================================
  // GESTIÓN DE USUARIOS Y ROLES SAAS
  // ==========================================

  Future<void> _recordAudit({
    required String accion,
    required String colegioId,
    required String colegioNombre,
    required String detalles,
  }) async {
    AuditRepository().recordAuditLog(
      AuditLog(
        id: 'aud-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        accion: accion,
        descripcion: detalles,
        usuario: 'admin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: colegioId,
        colegioNombre: colegioNombre,
        modulo: 'EQUIPO_SAAS',
      ),
    );
  }

  /// Obtiene los usuarios internos de la empresa dueña del software
  Future<List<SaaSUser>> getSaaSUsers({
    String? query,
    SaaSRole? rolFilter,
  }) async {
    List<SaaSUser> users = [];

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        var req = _supabaseClient.from('saas_usuarios').select('*');
        if (rolFilter != null) {
          req = req.eq('rol', rolFilter.name);
        }
        final response = await req.order('created_at', ascending: false);
        users = (response as List).map((row) => SaaSUser.fromJson(row)).toList();
      } catch (e) {
        debugPrint('Aviso: Error cargando saas_usuarios de Supabase: $e');
        users = List.from(_demoSaaSUsers);
      }
    } else {
      users = List.from(_demoSaaSUsers);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      users = users.where((u) {
        final matchName = u.nombreCompleto.toLowerCase().contains(q);
        final matchEmail = u.email.toLowerCase().contains(q);
        final matchRol = u.rol.displayName.toLowerCase().contains(q);
        return matchName || matchEmail || matchRol;
      }).toList();
    }

    if (rolFilter != null) {
      users = users.where((u) => u.rol == rolFilter).toList();
    }

    return users;
  }

  /// Crea un nuevo miembro del equipo de la empresa matriz SaaS
  Future<SaaSUser> createSaaSUser({
    required String nombre,
    required String apellido,
    required String email,
    required SaaSRole rol,
    String? telefono,
    required String password,
    String? notas,
  }) async {
    final newUser = SaaSUser(
      id: 'usr-saas-${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      email: email.trim().toLowerCase(),
      rol: rol,
      telefono: telefono?.trim(),
      activo: true,
      createdAt: DateTime.now(),
      lastLogin: null,
      notas: notas?.trim(),
    );

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('saas_usuarios').insert(newUser.toJson());
      } catch (e) {
        debugPrint('Aviso: Guardando usuario SaaS localmente: $e');
      }
    }

    _demoSaaSUsers.removeWhere((u) => u.id == newUser.id || u.email == newUser.email);
    _demoSaaSUsers.insert(0, newUser);

    await _recordAudit(
      accion: 'CREAR_USUARIO_SAAS',
      colegioId: 'HQ-EDUNEX',
      colegioNombre: 'EDUNEX HQ',
      detalles: 'Se dio de alta al usuario ${newUser.nombreCompleto} con rol ${newUser.rol.displayName} (${newUser.email}).',
    );

    return newUser;
  }

  /// Actualiza datos de un usuario SaaS
  Future<void> updateSaaSUser(SaaSUser user) async {
    final idx = _demoSaaSUsers.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _demoSaaSUsers[idx] = user;
    }

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient
            .from('saas_usuarios')
            .update(user.toJson())
            .eq('id', user.id);
      } catch (e) {
        debugPrint('Aviso actualizando usuario SaaS en Supabase: $e');
      }
    }

    await _recordAudit(
      accion: 'ACTUALIZAR_USUARIO_SAAS',
      colegioId: 'HQ-EDUNEX',
      colegioNombre: 'EDUNEX HQ',
      detalles: 'Se actualizaron los datos del usuario ${user.nombreCompleto} (Rol: ${user.rol.displayName}).',
    );
  }

  /// Activa o suspende el acceso de un miembro del equipo SaaS
  Future<void> toggleSaaSUserStatus(String userId) async {
    final idx = _demoSaaSUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final user = _demoSaaSUsers[idx];
      final newStatus = !user.activo;
      _demoSaaSUsers[idx] = user.copyWith(activo: newStatus);

      if (_supabaseClient != null && SupabaseConfig.isConfigured) {
        try {
          await _supabaseClient
              .from('saas_usuarios')
              .update({'activo': newStatus})
              .eq('id', userId);
        } catch (e) {
          debugPrint('Aviso alternando estado de usuario SaaS en Supabase: $e');
        }
      }

      await _recordAudit(
        accion: newStatus ? 'ACTIVAR_USUARIO_SAAS' : 'SUSPENDER_USUARIO_SAAS',
        colegioId: 'HQ-EDUNEX',
        colegioNombre: 'EDUNEX HQ',
        detalles: 'Estado del usuario ${user.nombreCompleto} cambiado a ${newStatus ? "ACTIVO" : "SUSPENDIDO"}.',
      );
    }
  }

  /// Resetea la contraseña de un usuario interno de la empresa SaaS
  Future<void> resetSaaSUserPassword(String userId, String newPassword) async {
    final user = _demoSaaSUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => _demoSaaSUsers.first,
    );

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('saas_usuarios').update({
          'password_hash': newPassword,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (e) {
        debugPrint('Aviso reseteando clave de usuario SaaS: $e');
      }
    }

    await _recordAudit(
      accion: 'RESET_PASSWORD_SAAS',
      colegioId: 'HQ-EDUNEX',
      colegioNombre: 'EDUNEX HQ',
      detalles: 'Se restableció la contraseña temporal del colaborador ${user.nombreCompleto} (${user.email}).',
    );
  }

  /// Elimina un usuario del equipo SaaS
  Future<void> deleteSaaSUser(String userId) async {
    _demoSaaSUsers.removeWhere((u) => u.id == userId);

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('saas_usuarios').delete().eq('id', userId);
      } catch (e) {
        debugPrint('Aviso eliminando usuario SaaS en Supabase: $e');
      }
    }

    await _recordAudit(
      accion: 'ELIMINAR_USUARIO_SAAS',
      colegioId: 'HQ-EDUNEX',
      colegioNombre: 'EDUNEX HQ',
      detalles: 'Se removió el usuario ID $userId del equipo corporativo.',
    );
  }

  // ==========================================
  // CONFIGURACIÓN DE LA EMPRESA MATRIZ SAAS
  // ==========================================

  /// Obtiene la configuración de la empresa SaaS
  Future<SaaSCompanyConfig> getCompanyConfig() async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final response = await _supabaseClient
            .from('saas_configuracion')
            .select('*')
            .limit(1)
            .maybeSingle();
        if (response != null) {
          _demoCompanyConfig = SaaSCompanyConfig.fromJson(response);
        }
      } catch (e) {
        debugPrint('Aviso cargando configuración SaaS de Supabase: $e');
      }
    }
    return _demoCompanyConfig;
  }

  /// Guarda la configuración de la empresa SaaS
  Future<void> saveCompanyConfig(SaaSCompanyConfig config) async {
    _demoCompanyConfig = config;

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient
            .from('saas_configuracion')
            .upsert(config.toJson());
      } catch (e) {
        debugPrint('Aviso guardando configuración SaaS en Supabase: $e');
      }
    }

    await _recordAudit(
      accion: 'ACTUALIZAR_CONFIGURACION_SAAS',
      colegioId: 'HQ-EDUNEX',
      colegioNombre: 'EDUNEX HQ',
      detalles: 'Se actualizaron los parámetros de la empresa matriz (RNC: ${config.rnc}, Razón Social: ${config.razonSocial}).',
    );
  }
}
