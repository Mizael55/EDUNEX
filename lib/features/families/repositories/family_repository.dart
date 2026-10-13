import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../models/tutor.dart';

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

  FamilyRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? _resolveClient();

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

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
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
        families = List<Family>.from(_demoFamilies);
      }
    } else {
      families = List<Family>.from(_demoFamilies);
    }

    if (_customFamilies.isNotEmpty) {
      // Evitar duplicados por ID
      final existingIds = families.map((f) => f.id).toSet();
      for (final cf in _customFamilies) {
        if (!existingIds.contains(cf.id)) {
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
  Future<Family?> getFamilyForCurrentUser({String? email}) async {
    final list = await getFamilies();
    if (list.isEmpty) return null;
    if (email != null && email.isNotEmpty) {
      try {
        return list.firstWhere(
          (f) => f.emailPrincipal?.toLowerCase() == email.toLowerCase() ||
              f.tutores.any((t) => t.email?.toLowerCase() == email.toLowerCase()),
        );
      } catch (_) {}
    }
    // Retorna la primera familia disponible
    return list.first;
  }

  /// Lista en memoria para familias creadas durante la sesión
  static final List<Family> _customFamilies = [];

  /// Registra una nueva familia con su tutor y estudiante inicial
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
    double balanceInicial = 0.0,
    String? estudianteNombres,
    String? estudianteApellidos,
    String? gradoNombre,
  }) async {
    final now = DateTime.now();
    final uniqueSuffix = now.millisecondsSinceEpoch.toString().substring(8);
    final codigoFamilia = 'FAM-${now.year}-$uniqueSuffix';
    final familyId = 'fam-${now.millisecondsSinceEpoch}';
    final tutorId = 'tut-${now.millisecondsSinceEpoch}';
    final studentId = 'est-${now.millisecondsSinceEpoch}';

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
    );

    List<Student> students = [];
    if (estudianteNombres != null && estudianteNombres.trim().isNotEmpty) {
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
    );

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
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

        if (students.isNotEmpty) {
          await _supabaseClient.from('estudiantes').insert({
            'colegio_id': colegioId,
            'familia_id': createdFamilyId,
            'matricula': 'EST-${now.year}-$uniqueSuffix',
            'nombres': estudianteNombres!.trim(),
            'apellidos': (estudianteApellidos != null && estudianteApellidos.trim().isNotEmpty)
                ? estudianteApellidos.trim()
                : tutorApellidos,
            'fecha_nacimiento': DateTime(now.year - 8, 1, 1).toIso8601String().split('T').first,
            'genero': 'No especificado',
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

  /// Registra un abono o pago a una familia
  Future<void> recordPayment({
    required String familiaId,
    required double monto,
    required String concepto,
    required String metodo,
    String? referencia,
  }) async {
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
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

    // Actualizar balance en memoria
    for (int i = 0; i < _customFamilies.length; i++) {
      if (_customFamilies[i].id == familiaId) {
        final f = _customFamilies[i];
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

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
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
}
