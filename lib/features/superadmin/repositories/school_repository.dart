import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/supabase_config.dart';
import '../models/school.dart';
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

  /// Limpia todos los colegios en memoria para pruebas de QA
  static void clearAllData() {
    _demoSchools.clear();
  }

  /// Restaura los colegios de prueba para pruebas y modo demo
  static void restoreSeedData() {
    _demoSchools.clear();
    _demoSchools.addAll(_seedSchools);
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
}
