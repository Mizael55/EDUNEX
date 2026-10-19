import 'student_document.dart';

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
  final String? tipoSangre;
  final String? alergias;
  final String? seguroMedico;
  final String? numeroPoliza;
  final String? pediatraContacto;
  final bool fotoAdjunta;
  final bool actaNacimientoAdjunta;
  final bool certificadoNotasAdjunto;
  final bool cartaSaldoConductaAdjunta;
  final Map<String, String> criteriosEvaluados;
  final bool activo;
  final List<String> serviciosActivos;
  // Issue #19: Documentos cargados en el expediente digital del alumno
  final List<StudentDocument> documentosExpediente;

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
    this.tipoSangre,
    this.alergias,
    this.seguroMedico,
    this.numeroPoliza,
    this.pediatraContacto,
    this.fotoAdjunta = false,
    this.actaNacimientoAdjunta = false,
    this.certificadoNotasAdjunto = false,
    this.cartaSaldoConductaAdjunta = false,
    this.criteriosEvaluados = const {},
    this.activo = true,
    this.serviciosActivos = const [],
    this.documentosExpediente = const [],
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

  Student copyWith({
    String? id,
    String? colegioId,
    String? familiaId,
    String? matricula,
    String? nombres,
    String? apellidos,
    DateTime? fechaNacimiento,
    String? genero,
    String? seccionId,
    String? gradoNombre,
    String? seccionNombre,
    String? fotoUrl,
    String? condicionesMedicas,
    String? tipoSangre,
    String? alergias,
    String? seguroMedico,
    String? numeroPoliza,
    String? pediatraContacto,
    bool? fotoAdjunta,
    bool? actaNacimientoAdjunta,
    bool? certificadoNotasAdjunto,
    bool? cartaSaldoConductaAdjunta,
    Map<String, String>? criteriosEvaluados,
    bool? activo,
    List<String>? serviciosActivos,
    List<StudentDocument>? documentosExpediente,
  }) {
    return Student(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      familiaId: familiaId ?? this.familiaId,
      matricula: matricula ?? this.matricula,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      genero: genero ?? this.genero,
      seccionId: seccionId ?? this.seccionId,
      gradoNombre: gradoNombre ?? this.gradoNombre,
      seccionNombre: seccionNombre ?? this.seccionNombre,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      condicionesMedicas: condicionesMedicas ?? this.condicionesMedicas,
      tipoSangre: tipoSangre ?? this.tipoSangre,
      alergias: alergias ?? this.alergias,
      seguroMedico: seguroMedico ?? this.seguroMedico,
      numeroPoliza: numeroPoliza ?? this.numeroPoliza,
      pediatraContacto: pediatraContacto ?? this.pediatraContacto,
      fotoAdjunta: fotoAdjunta ?? this.fotoAdjunta,
      actaNacimientoAdjunta: actaNacimientoAdjunta ?? this.actaNacimientoAdjunta,
      certificadoNotasAdjunto: certificadoNotasAdjunto ?? this.certificadoNotasAdjunto,
      cartaSaldoConductaAdjunta: cartaSaldoConductaAdjunta ?? this.cartaSaldoConductaAdjunta,
      criteriosEvaluados: criteriosEvaluados ?? this.criteriosEvaluados,
      activo: activo ?? this.activo,
      serviciosActivos: serviciosActivos ?? this.serviciosActivos,
      documentosExpediente: documentosExpediente ?? this.documentosExpediente,
    );
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

    Map<String, String> criterios = {};
    if (json['criterios_evaluados'] is Map) {
      (json['criterios_evaluados'] as Map).forEach((k, v) {
        criterios[k.toString()] = v.toString();
      });
    }

    List<StudentDocument> docs = [];
    if (json['documentos_expediente'] is List) {
      docs = (json['documentos_expediente'] as List)
          .map((d) => StudentDocument.fromJson(d as Map<String, dynamic>))
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
      tipoSangre: json['tipo_sangre'] as String?,
      alergias: json['alergias'] as String?,
      seguroMedico: json['seguro_medico'] as String?,
      numeroPoliza: json['numero_poliza'] as String?,
      pediatraContacto: json['pediatra_contacto'] as String?,
      fotoAdjunta: json['foto_adjunta'] as bool? ?? false,
      actaNacimientoAdjunta: json['acta_nacimiento_adjunta'] as bool? ?? false,
      certificadoNotasAdjunto: json['certificado_notas_adjunto'] as bool? ?? false,
      cartaSaldoConductaAdjunta: json['carta_saldo_conducta_adjunta'] as bool? ?? false,
      criteriosEvaluados: criterios,
      activo: json['activo'] as bool? ?? true,
      serviciosActivos: servicios,
      documentosExpediente: docs,
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
      'tipo_sangre': tipoSangre,
      'alergias': alergias,
      'seguro_medico': seguroMedico,
      'numero_poliza': numeroPoliza,
      'pediatra_contacto': pediatraContacto,
      'foto_adjunta': fotoAdjunta,
      'acta_nacimiento_adjunta': actaNacimientoAdjunta,
      'certificado_notas_adjunto': certificadoNotasAdjunto,
      'carta_saldo_conducta_adjunta': cartaSaldoConductaAdjunta,
      'documentos_expediente': documentosExpediente.map((d) => d.toJson()).toList(),
      'criterios_evaluados': criteriosEvaluados,
      'activo': activo,
      'servicios_activos': serviciosActivos,
    };
  }
}
