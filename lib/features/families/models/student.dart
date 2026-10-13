/// Modelo de Estudiante en EDUNEX vinculado a la Cuenta Familiar
class Student {
  final String id;
  final String colegioId;
  final String familiaId;
  final String matricula;
  final String nombres;
  final String apellidos;
  final DateTime fechaNacimiento;
  final String? genero;
  final String? seccionId;
  final String? gradoNombre;
  final String? seccionNombre;
  final String? fotoUrl;
  final String? condicionesMedicas;
  final bool activo;
  final List<String> serviciosActivos;

  const Student({
    required this.id,
    required this.colegioId,
    required this.familiaId,
    required this.matricula,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    this.genero,
    this.seccionId,
    this.gradoNombre,
    this.seccionNombre,
    this.fotoUrl,
    this.condicionesMedicas,
    this.activo = true,
    this.serviciosActivos = const [],
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();
  String get gradoYSeccion => '${gradoNombre ?? "Sin grado"} ${seccionNombre ?? ""}'.trim();

  int get edad {
    final now = DateTime.now();
    int age = now.year - fechaNacimiento.year;
    if (now.month < fechaNacimiento.month ||
        (now.month == fechaNacimiento.month && now.day < fechaNacimiento.day)) {
      age--;
    }
    return age;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    DateTime parsedBirthDate;
    try {
      parsedBirthDate = DateTime.parse(
        json['fecha_nacimiento'] as String? ?? '2018-01-01',
      );
    } catch (_) {
      parsedBirthDate = DateTime(2018, 1, 1);
    }

    // Extracción de nombres de grado/sección desde joins o campos directos
    String? grado;
    String? seccion;
    if (json['secciones'] is Map) {
      final secMap = json['secciones'] as Map<String, dynamic>;
      seccion = secMap['nombre'] as String?;
      if (secMap['grados'] is Map) {
        grado = (secMap['grados'] as Map<String, dynamic>)['nombre'] as String?;
      }
    } else {
      grado = json['grado_nombre'] as String?;
      seccion = json['seccion_nombre'] as String?;
    }

    List<String> servicios = [];
    if (json['servicios_activos'] is List) {
      servicios = (json['servicios_activos'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return Student(
      id: json['id'] as String? ?? '',
      colegioId: json['colegio_id'] as String? ?? '',
      familiaId: json['familia_id'] as String? ?? '',
      matricula: json['matricula'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      fechaNacimiento: parsedBirthDate,
      genero: json['genero'] as String?,
      seccionId: json['seccion_id'] as String?,
      gradoNombre: grado,
      seccionNombre: seccion,
      fotoUrl: json['foto_url'] as String?,
      condicionesMedicas: json['condiciones_medicas'] as String?,
      activo: json['activo'] as bool? ?? true,
      serviciosActivos: servicios,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colegio_id': colegioId,
      'familia_id': familiaId,
      'matricula': matricula,
      'nombres': nombres,
      'apellidos': apellidos,
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'genero': genero,
      'seccion_id': seccionId,
      'grado_nombre': gradoNombre,
      'seccion_nombre': seccionNombre,
      'foto_url': fotoUrl,
      'condiciones_medicas': condicionesMedicas,
      'activo': activo,
      'servicios_activos': serviciosActivos,
    };
  }
}
