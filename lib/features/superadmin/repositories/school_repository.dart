import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/school.dart';

/// Repositorio de Colegios y Clientes para el Dueño del Software (Superadmin)
class SchoolRepository {
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

  SchoolRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? _resolveClient();

  /// Lista de colegios de demostración para pruebas fuera de línea
  static final List<School> _demoSchools = [
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

        schools = (response as List)
            .map((item) => School.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Aviso: Error consultando colegios en Supabase: $e');
        schools = [];
      }
    } else {
      // Modo desconectado o pruebas unitarias sin Supabase configurado
      schools = List<School>.from(_demoSchools);
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
    required String estadoSuscripcion,
    required int maxEstudiantes,
    required String directorEmail,
    required String directorPassword,
    required String directorNombres,
    String? directorApellidos,
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
        final school = School.fromJson(colegioMap);
        return {
          'school': school,
          'director': res['director'] as Map<String, dynamic>,
        };
      } catch (e) {
        debugPrint('Error creando colegio con director en Supabase RPC: $e');
        rethrow;
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
      estadoSuscripcion: estadoSuscripcion,
      maxEstudiantes: maxEstudiantes,
      createdAt: DateTime.now(),
    );
    _demoSchools.insert(0, fallbackSchool);
    return {
      'school': fallbackSchool,
      'director': {
        'email': directorEmail,
        'nombres': directorNombres,
        'apellidos': directorApellidos ?? '',
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
  }

  /// Retorna las métricas ejecutivas globales del negocio SaaS
  Future<Map<String, dynamic>> getSaaSMasterKpis() async {
    final list = await getSchools();
    final totalSchools = list.length;
    final activeSchools = list.where((s) => s.isActive).length;
    final trialSchools = list.where((s) => s.isTrial).length;
    final totalStudents = list.fold<int>(0, (sum, s) => sum + s.totalEstudiantes);

    // Estimación de MRR (RD$): Asumiendo RD$ 40,000 promedio mensual por colegio suscrito
    final estimatedMRR = activeSchools * 45000.0;

    return {
      'totalSchools': totalSchools,
      'activeSchools': activeSchools,
      'trialSchools': trialSchools,
      'totalStudents': totalStudents,
      'estimatedMRR': estimatedMRR,
    };
  }
}
