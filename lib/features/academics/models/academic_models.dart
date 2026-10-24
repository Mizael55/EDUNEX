import 'dart:convert';

/// Modelo de Curso / Grado Académico (Issue #20)
class AcademicCourse {
  final String id;
  final String colegioId;
  final String nombre; // Ej. "1ro de Primaria", "2do de Secundaria", "Kinder"
  final String nivel; // "Inicial", "Primaria", "Secundaria"
  final String anioEscolar; // Ej. "2025-2026"
  final List<String> materiasIds;
  final int orden;

  const AcademicCourse({
    required this.id,
    required this.colegioId,
    required this.nombre,
    required this.nivel,
    required this.anioEscolar,
    this.materiasIds = const [],
    this.orden = 1,
  });

  AcademicCourse copyWith({
    String? id,
    String? colegioId,
    String? nombre,
    String? nivel,
    String? anioEscolar,
    List<String>? materiasIds,
    int? orden,
  }) {
    return AcademicCourse(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      nombre: nombre ?? this.nombre,
      nivel: nivel ?? this.nivel,
      anioEscolar: anioEscolar ?? this.anioEscolar,
      materiasIds: materiasIds ?? this.materiasIds,
      orden: orden ?? this.orden,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'nombre': nombre,
        'nivel': nivel,
        'anio_escolar': anioEscolar,
        'materias_ids': materiasIds,
        'orden': orden,
      };

  factory AcademicCourse.fromJson(Map<String, dynamic> json) => AcademicCourse(
        id: json['id'] as String,
        colegioId: (json['colegio_id'] ?? json['colegioId']) as String? ?? 'col-1',
        nombre: json['nombre'] as String? ?? 'Curso',
        nivel: json['nivel'] as String? ?? 'Primaria',
        anioEscolar: (json['anio_escolar'] ?? json['anioEscolar']) as String? ?? '2025-2026',
        materiasIds: (json['materias_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        orden: (json['orden'] as num?)?.toInt() ?? 1,
      );
}

/// Modelo de Sección por Curso (Issue #20)
class AcademicSection {
  final String id;
  final String colegioId;
  final String cursoId;
  final String cursoNombre;
  final String nombre; // Ej. "Sección A", "Sección B"
  final String anioEscolar; // Ej. "2025-2026"
  final int capacidadEstudiantes; // Ej. 30
  final String? aula; // Ej. "Aula 101", "Edificio B - 2do Piso"
  final String? profesorTitularId;
  final String? profesorTitularNombre;
  final bool activa;

  const AcademicSection({
    required this.id,
    required this.colegioId,
    required this.cursoId,
    required this.cursoNombre,
    required this.nombre,
    required this.anioEscolar,
    this.capacidadEstudiantes = 30,
    this.aula,
    this.profesorTitularId,
    this.profesorTitularNombre,
    this.activa = true,
  });

  AcademicSection copyWith({
    String? id,
    String? colegioId,
    String? cursoId,
    String? cursoNombre,
    String? nombre,
    String? anioEscolar,
    int? capacidadEstudiantes,
    String? aula,
    String? profesorTitularId,
    String? profesorTitularNombre,
    bool? activa,
  }) {
    return AcademicSection(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      cursoId: cursoId ?? this.cursoId,
      cursoNombre: cursoNombre ?? this.cursoNombre,
      nombre: nombre ?? this.nombre,
      anioEscolar: anioEscolar ?? this.anioEscolar,
      capacidadEstudiantes: capacidadEstudiantes ?? this.capacidadEstudiantes,
      aula: aula ?? this.aula,
      profesorTitularId: profesorTitularId ?? this.profesorTitularId,
      profesorTitularNombre: profesorTitularNombre ?? this.profesorTitularNombre,
      activa: activa ?? this.activa,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'curso_id': cursoId,
        'curso_nombre': cursoNombre,
        'nombre': nombre,
        'anio_escolar': anioEscolar,
        'capacidad_estudiantes': capacidadEstudiantes,
        'aula': aula,
        'profesor_titular_id': profesorTitularId,
        'profesor_titular_nombre': profesorTitularNombre,
        'activa': activa,
      };

  factory AcademicSection.fromJson(Map<String, dynamic> json) => AcademicSection(
        id: json['id'] as String,
        colegioId: (json['colegio_id'] ?? json['colegioId']) as String? ?? 'col-1',
        cursoId: (json['curso_id'] ?? json['cursoId']) as String? ?? '',
        cursoNombre: (json['curso_nombre'] ?? json['cursoNombre']) as String? ?? '',
        nombre: json['nombre'] as String? ?? 'Sección A',
        anioEscolar: (json['anio_escolar'] ?? json['anioEscolar']) as String? ?? '2025-2026',
        capacidadEstudiantes: (json['capacidad_estudiantes'] ?? json['capacidadEstudiantes'] as num?)?.toInt() ?? 30,
        aula: json['aula'] as String?,
        profesorTitularId: (json['profesor_titular_id'] ?? json['profesorTitularId']) as String?,
        profesorTitularNombre: (json['profesor_titular_nombre'] ?? json['profesorTitularNombre']) as String?,
        activa: json['activa'] as bool? ?? true,
      );
}

/// Modelo de Materia Curricular (Issue #20)
class AcademicSubject {
  final String id;
  final String colegioId;
  final String nombre; // Ej. "Matemáticas", "Lengua Española"
  final String codigo; // Ej. "MAT-101", "ESP-101"
  final int horasSemanales;
  final String? descripcion;
  final List<String> cursosIds; // Cursos a los que aplica esta materia
  final String colorHex;

  const AcademicSubject({
    required this.id,
    required this.colegioId,
    required this.nombre,
    required this.codigo,
    this.horasSemanales = 4,
    this.descripcion,
    this.cursosIds = const [],
    this.colorHex = '#1E3A8A',
  });

  AcademicSubject copyWith({
    String? id,
    String? colegioId,
    String? nombre,
    String? codigo,
    int? horasSemanales,
    String? descripcion,
    List<String>? cursosIds,
    String? colorHex,
  }) {
    return AcademicSubject(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      horasSemanales: horasSemanales ?? this.horasSemanales,
      descripcion: descripcion ?? this.descripcion,
      cursosIds: cursosIds ?? this.cursosIds,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'nombre': nombre,
        'codigo': codigo,
        'horas_semanales': horasSemanales,
        'descripcion': descripcion,
        'cursos_ids': cursosIds,
        'color_hex': colorHex,
      };

  factory AcademicSubject.fromJson(Map<String, dynamic> json) => AcademicSubject(
        id: json['id'] as String,
        colegioId: (json['colegio_id'] ?? json['colegioId']) as String? ?? 'col-1',
        nombre: json['nombre'] as String? ?? 'Materia',
        codigo: json['codigo'] as String? ?? 'MAT-00',
        horasSemanales: (json['horas_semanales'] ?? json['horasSemanales'] as num?)?.toInt() ?? 4,
        descripcion: json['descripcion'] as String?,
        cursosIds: (json['cursos_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        colorHex: json['color_hex'] as String? ?? '#1E3A8A',
      );
}

/// Registro de Evaluación de Desempeño Docente por la Dirección (Issue #21)
class TeacherEvaluationRecord {
  final String id;
  final DateTime fecha;
  final String directorNombre;
  final double puntaje; // 1.0 a 5.0
  final String criterio; // Ej. 'Pedagogía y Gestión de Aula', 'Puntualidad y Planificación'
  final String comentario;

  const TeacherEvaluationRecord({
    required this.id,
    required this.fecha,
    required this.directorNombre,
    required this.puntaje,
    required this.criterio,
    required this.comentario,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'director_nombre': directorNombre,
        'puntaje': puntaje,
        'criterio': criterio,
        'comentario': comentario,
      };

  factory TeacherEvaluationRecord.fromJson(Map<String, dynamic> json) => TeacherEvaluationRecord(
        id: json['id'] as String? ?? 'eval-${DateTime.now().millisecondsSinceEpoch}',
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
        directorNombre: (json['director_nombre'] ?? json['directorNombre']) as String? ?? 'Dirección Académica',
        puntaje: (json['puntaje'] as num?)?.toDouble() ?? 5.0,
        criterio: json['criterio'] as String? ?? 'General',
        comentario: json['comentario'] as String? ?? '',
      );
}

/// Modelo de Perfil de Profesor (Issue #20, Issue #21)
class AcademicTeacher {
  final String id;
  final String colegioId;
  final String nombreCompleto;
  final String cedula;
  final String email;
  final String telefono;
  final String especialidad;
  final String estado; // "Activo", "Inactivo", "Licencia"
  final List<String> materiasQuePuedeImpartir;
  final String? fotoUrl;

  // Nuevos campos del perfil docente (Issue #21)
  final String estudios; // Ej. "Licenciatura en Educación mención Matemáticas (UASD)"
  final String? maestria; // Ej. "Maestría en Gestión y Liderazgo de Centros Educativos (INTEC)"
  final String experiencia; // Ej. "8 años de docencia activa en nivel secundario"
  final String referencias; // Ej. "Colegio Montesino (Tel: 809-555-0199), Lic. Rafael Peña"
  final bool tieneCartaBuenaConducta;
  final String? cartaBuenaConductaUrl;
  final List<String> materiasQueImparte;
  final double calificacionDesempeno; // 1.0 a 5.0
  final List<String> diasDisponibles; // ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes']
  final List<String> bloquesDisponibles; // ['08:00 - 09:30', '09:30 - 11:00', '11:15 - 12:45', '13:30 - 15:00']
  final String usuarioAcceso; // Usuario generado automáticamente
  final String claveTemporal; // Clave de acceso temporal
  final bool debeCambiarClave;
  final List<TeacherEvaluationRecord> evaluacionesDirector;

  const AcademicTeacher({
    required this.id,
    required this.colegioId,
    required this.nombreCompleto,
    required this.cedula,
    required this.email,
    required this.telefono,
    required this.especialidad,
    this.estado = 'Activo',
    this.materiasQuePuedeImpartir = const [],
    this.fotoUrl,
    this.estudios = 'Licenciatura en Educación',
    this.maestria,
    this.experiencia = '5 años de experiencia en docencia académica',
    this.referencias = 'Colegio San Judas Tadeo - Lic. Marcos Díaz (809-555-1234)',
    this.tieneCartaBuenaConducta = true,
    this.cartaBuenaConductaUrl,
    this.materiasQueImparte = const [],
    this.calificacionDesempeno = 4.8,
    this.diasDisponibles = const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
    this.bloquesDisponibles = const ['08:00 - 09:30', '09:30 - 11:00', '11:15 - 12:45', '13:30 - 15:00'],
    this.usuarioAcceso = '',
    this.claveTemporal = 'Docente2026!',
    this.debeCambiarClave = true,
    this.evaluacionesDirector = const [],
  });

  AcademicTeacher copyWith({
    String? id,
    String? colegioId,
    String? nombreCompleto,
    String? cedula,
    String? email,
    String? telefono,
    String? especialidad,
    String? estado,
    List<String>? materiasQuePuedeImpartir,
    String? fotoUrl,
    String? estudios,
    String? maestria,
    String? experiencia,
    String? referencias,
    bool? tieneCartaBuenaConducta,
    String? cartaBuenaConductaUrl,
    List<String>? materiasQueImparte,
    double? calificacionDesempeno,
    List<String>? diasDisponibles,
    List<String>? bloquesDisponibles,
    String? usuarioAcceso,
    String? claveTemporal,
    bool? debeCambiarClave,
    List<TeacherEvaluationRecord>? evaluacionesDirector,
  }) {
    return AcademicTeacher(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      cedula: cedula ?? this.cedula,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      especialidad: especialidad ?? this.especialidad,
      estado: estado ?? this.estado,
      materiasQuePuedeImpartir: materiasQuePuedeImpartir ?? this.materiasQuePuedeImpartir,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      estudios: estudios ?? this.estudios,
      maestria: maestria ?? this.maestria,
      experiencia: experiencia ?? this.experiencia,
      referencias: referencias ?? this.referencias,
      tieneCartaBuenaConducta: tieneCartaBuenaConducta ?? this.tieneCartaBuenaConducta,
      cartaBuenaConductaUrl: cartaBuenaConductaUrl ?? this.cartaBuenaConductaUrl,
      materiasQueImparte: materiasQueImparte ?? this.materiasQueImparte,
      calificacionDesempeno: calificacionDesempeno ?? this.calificacionDesempeno,
      diasDisponibles: diasDisponibles ?? this.diasDisponibles,
      bloquesDisponibles: bloquesDisponibles ?? this.bloquesDisponibles,
      usuarioAcceso: usuarioAcceso ?? this.usuarioAcceso,
      claveTemporal: claveTemporal ?? this.claveTemporal,
      debeCambiarClave: debeCambiarClave ?? this.debeCambiarClave,
      evaluacionesDirector: evaluacionesDirector ?? this.evaluacionesDirector,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'nombre_completo': nombreCompleto,
        'cedula': cedula,
        'email': email,
        'telefono': telefono,
        'especialidad': especialidad,
        'estado': estado,
        'materias_que_puede_impartir': materiasQuePuedeImpartir,
        'foto_url': fotoUrl,
        'estudios': estudios,
        'maestria': maestria,
        'experiencia': experiencia,
        'referencias': referencias,
        'tiene_carta_buena_conducta': tieneCartaBuenaConducta,
        'carta_buena_conducta_url': cartaBuenaConductaUrl,
        'materias_que_imparte': materiasQueImparte,
        'calificacion_desempeno': calificacionDesempeno,
        'dias_disponibles': diasDisponibles,
        'bloques_disponibles': bloquesDisponibles,
        'usuario_acceso': usuarioAcceso,
        'clave_temporal': claveTemporal,
        'debe_cambiar_clave': debeCambiarClave,
        'evaluaciones_director': evaluacionesDirector.map((e) => e.toJson()).toList(),
      };

  factory AcademicTeacher.fromJson(Map<String, dynamic> json) => AcademicTeacher(
        id: json['id'] as String,
        colegioId: (json['colegio_id'] ?? json['colegioId']) as String? ?? 'col-1',
        nombreCompleto: (json['nombre_completo'] ?? json['nombreCompleto']) as String? ?? '',
        cedula: json['cedula'] as String? ?? '',
        email: json['email'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        especialidad: json['especialidad'] as String? ?? 'General',
        estado: json['estado'] as String? ?? 'Activo',
        materiasQuePuedeImpartir: (json['materias_que_puede_impartir'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        fotoUrl: json['foto_url'] as String?,
        estudios: json['estudios'] as String? ?? 'Licenciatura en Educación',
        maestria: json['maestria'] as String?,
        experiencia: json['experiencia'] as String? ?? '5 años de experiencia docente',
        referencias: json['referencias'] as String? ?? 'Colegio San Judas Tadeo - Lic. Marcos Díaz',
        tieneCartaBuenaConducta: json['tiene_carta_buena_conducta'] as bool? ?? true,
        cartaBuenaConductaUrl: json['carta_buena_conducta_url'] as String?,
        materiasQueImparte: (json['materias_que_imparte'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        calificacionDesempeno: (json['calificacion_desempeno'] as num?)?.toDouble() ?? 4.8,
        diasDisponibles: (json['dias_disponibles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
        bloquesDisponibles: (json['bloques_disponibles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const ['08:00 - 09:30', '09:30 - 11:00', '11:15 - 12:45', '13:30 - 15:00'],
        usuarioAcceso: json['usuario_acceso'] as String? ?? '',
        claveTemporal: json['clave_temporal'] as String? ?? 'Docente2026!',
        debeCambiarClave: json['debe_cambiar_clave'] as bool? ?? true,
        evaluacionesDirector: (json['evaluaciones_director'] as List<dynamic>?)
                ?.map((e) => TeacherEvaluationRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// Asignación Académica de Profesor a Materia, Curso y Sección con Horarios (Issue #20, Issue #21)
class TeacherAcademicAssignment {
  final String id;
  final String colegioId;
  final String profesorId;
  final String profesorNombre;
  final String materiaId;
  final String materiaNombre;
  final String cursoId;
  final String cursoNombre;
  final String seccionId;
  final String seccionNombre;
  final String anioEscolar;
  final String? horarioSemanal;
  final String? diaSemana; // Ej. 'Lunes y Miércoles', 'Martes y Jueves'
  final String? bloqueHorario; // Ej. '08:00 - 09:30'
  final String? aula; // Aula donde se imparte

  const TeacherAcademicAssignment({
    required this.id,
    required this.colegioId,
    required this.profesorId,
    required this.profesorNombre,
    required this.materiaId,
    required this.materiaNombre,
    required this.cursoId,
    required this.cursoNombre,
    required this.seccionId,
    required this.seccionNombre,
    required this.anioEscolar,
    this.horarioSemanal,
    this.diaSemana,
    this.bloqueHorario,
    this.aula,
  });

  TeacherAcademicAssignment copyWith({
    String? id,
    String? colegioId,
    String? profesorId,
    String? profesorNombre,
    String? materiaId,
    String? materiaNombre,
    String? cursoId,
    String? cursoNombre,
    String? seccionId,
    String? seccionNombre,
    String? anioEscolar,
    String? horarioSemanal,
    String? diaSemana,
    String? bloqueHorario,
    String? aula,
  }) {
    return TeacherAcademicAssignment(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      profesorId: profesorId ?? this.profesorId,
      profesorNombre: profesorNombre ?? this.profesorNombre,
      materiaId: materiaId ?? this.materiaId,
      materiaNombre: materiaNombre ?? this.materiaNombre,
      cursoId: cursoId ?? this.cursoId,
      cursoNombre: cursoNombre ?? this.cursoNombre,
      seccionId: seccionId ?? this.seccionId,
      seccionNombre: seccionNombre ?? this.seccionNombre,
      anioEscolar: anioEscolar ?? this.anioEscolar,
      horarioSemanal: horarioSemanal ?? this.horarioSemanal,
      diaSemana: diaSemana ?? this.diaSemana,
      bloqueHorario: bloqueHorario ?? this.bloqueHorario,
      aula: aula ?? this.aula,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'profesor_id': profesorId,
        'profesor_nombre': profesorNombre,
        'materia_id': materiaId,
        'materia_nombre': materiaNombre,
        'curso_id': cursoId,
        'curso_nombre': cursoNombre,
        'seccion_id': seccionId,
        'seccion_nombre': seccionNombre,
        'anio_escolar': anioEscolar,
        'horario_semanal': horarioSemanal,
        'dia_semana': diaSemana,
        'bloque_horario': bloqueHorario,
        'aula': aula,
      };

  factory TeacherAcademicAssignment.fromJson(Map<String, dynamic> json) => TeacherAcademicAssignment(
        id: json['id'] as String,
        colegioId: (json['colegio_id'] ?? json['colegioId']) as String? ?? 'col-1',
        profesorId: (json['profesor_id'] ?? json['profesorId']) as String? ?? '',
        profesorNombre: (json['profesor_nombre'] ?? json['profesorNombre']) as String? ?? '',
        materiaId: (json['materia_id'] ?? json['materiaId']) as String? ?? '',
        materiaNombre: (json['materia_nombre'] ?? json['materiaNombre']) as String? ?? '',
        cursoId: (json['curso_id'] ?? json['cursoId']) as String? ?? '',
        cursoNombre: (json['curso_nombre'] ?? json['cursoNombre']) as String? ?? '',
        seccionId: (json['seccion_id'] ?? json['seccionId']) as String? ?? '',
        seccionNombre: (json['seccion_nombre'] ?? json['seccionNombre']) as String? ?? '',
        anioEscolar: (json['anio_escolar'] ?? json['anioEscolar']) as String? ?? '2025-2026',
        horarioSemanal: (json['horario_semanal'] ?? json['horarioSemanal']) as String?,
        diaSemana: (json['dia_semana'] ?? json['diaSemana']) as String? ?? 'Lunes y Miércoles',
        bloqueHorario: (json['bloque_horario'] ?? json['bloqueHorario']) as String? ?? '08:00 - 09:30',
        aula: json['aula'] as String?,
      );
}

/// Registro de Traslado de Sección de un Estudiante (Issue #20)
class StudentTransferRecord {
  final DateTime fecha;
  final String seccionAnterior;
  final String seccionNueva;
  final String motivo;
  final String? usuarioResponsable;

  const StudentTransferRecord({
    required this.fecha,
    required this.seccionAnterior,
    required this.seccionNueva,
    required this.motivo,
    this.usuarioResponsable,
  });

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'seccion_anterior': seccionAnterior,
        'seccion_nueva': seccionNueva,
        'motivo': motivo,
        'usuario_responsable': usuarioResponsable,
      };

  factory StudentTransferRecord.fromJson(Map<String, dynamic> json) => StudentTransferRecord(
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
        seccionAnterior: (json['seccion_anterior'] ?? json['seccionAnterior']) as String? ?? '',
        seccionNueva: (json['seccion_nueva'] ?? json['seccionNueva']) as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        usuarioResponsable: (json['usuario_responsable'] ?? json['usuarioResponsable']) as String?,
      );
}

/// Evento o Evaluación Académica Programada por el Profesor en el Aula (Issue #21 - Caso 4)
class ClassroomEvent {
  final String id;
  final String colegioId;
  final String cursoId;
  final String seccionId;
  final String titulo; // Ej. 'Examen Parcial de Matemáticas'
  final String tipo; // 'Examen', 'Proyecto', 'Actividad', 'Excursión'
  final DateTime fecha;
  final String profesorNombre;
  final String materiaNombre;
  final String descripcion;

  const ClassroomEvent({
    required this.id,
    required this.colegioId,
    required this.cursoId,
    required this.seccionId,
    required this.titulo,
    required this.tipo,
    required this.fecha,
    required this.profesorNombre,
    required this.materiaNombre,
    required this.descripcion,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'curso_id': cursoId,
        'seccion_id': seccionId,
        'titulo': titulo,
        'tipo': tipo,
        'fecha': fecha.toIso8601String(),
        'profesor_nombre': profesorNombre,
        'materia_nombre': materiaNombre,
        'descripcion': descripcion,
      };

  factory ClassroomEvent.fromJson(Map<String, dynamic> json) => ClassroomEvent(
        id: json['id'] as String,
        colegioId: (json['colegio_id'] ?? json['colegioId']) as String? ?? 'col-1',
        cursoId: (json['curso_id'] ?? json['cursoId']) as String? ?? '',
        seccionId: (json['seccion_id'] ?? json['seccionId']) as String? ?? '',
        titulo: json['titulo'] as String? ?? 'Evento de Aula',
        tipo: json['tipo'] as String? ?? 'Actividad',
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
        profesorNombre: (json['profesor_nombre'] ?? json['profesorNombre']) as String? ?? '',
        materiaNombre: (json['materia_nombre'] ?? json['materiaNombre']) as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
      );
}

/// Matrícula y Asignación de Estudiante a Curso y Sección (Issue #20, Issue #21)
class StudentEnrollment {
  final String id;
  final String colegioId;
  final String estudianteId;
  final String estudianteNombre;
  final String matricula;
  final String cursoId;
  final String cursoNombre;
  final String seccionId;
  final String seccionNombre;
  final String anioEscolar;
  final String estado; // "Activo", "Trasladado", "Retirado"
  final DateTime fechaAsignacion;
  final List<StudentTransferRecord> historialTraslados;
  final String aula;
  final String usuarioAcceso;
  final String claveTemporal;

  const StudentEnrollment({
    required this.id,
    required this.colegioId,
    required this.estudianteId,
    required this.estudianteNombre,
    required this.matricula,
    required this.cursoId,
    required this.cursoNombre,
    required this.seccionId,
    required this.seccionNombre,
    required this.anioEscolar,
    this.estado = 'Activo',
    required this.fechaAsignacion,
    this.historialTraslados = const [],
    this.aula = '',
    this.usuarioAcceso = '',
    this.claveTemporal = 'Estudiante2026!',
  });

  StudentEnrollment copyWith({
    String? id,
    String? colegioId,
    String? estudianteId,
    String? estudianteNombre,
    String? matricula,
    String? cursoId,
    String? cursoNombre,
    String? seccionId,
    String? seccionNombre,
    String? anioEscolar,
    String? estado,
    DateTime? fechaAsignacion,
    List<StudentTransferRecord>? historialTraslados,
    String? aula,
    String? usuarioAcceso,
    String? claveTemporal,
  }) {
    return StudentEnrollment(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      estudianteId: estudianteId ?? this.estudianteId,
      estudianteNombre: estudianteNombre ?? this.estudianteNombre,
      matricula: matricula ?? this.matricula,
      cursoId: cursoId ?? this.cursoId,
      cursoNombre: cursoNombre ?? this.cursoNombre,
      seccionId: seccionId ?? this.seccionId,
      seccionNombre: seccionNombre ?? this.seccionNombre,
      anioEscolar: anioEscolar ?? this.anioEscolar,
      estado: estado ?? this.estado,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      historialTraslados: historialTraslados ?? this.historialTraslados,
      aula: aula ?? this.aula,
      usuarioAcceso: usuarioAcceso ?? this.usuarioAcceso,
      claveTemporal: claveTemporal ?? this.claveTemporal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'estudiante_id': estudianteId,
        'estudiante_nombre': estudianteNombre,
        'matricula': matricula,
        'curso_id': cursoId,
        'curso_nombre': cursoNombre,
        'seccion_id': seccionId,
        'seccion_nombre': seccionNombre,
        'anio_escolar': anioEscolar,
        'estado': estado,
        'fecha_asignacion': fechaAsignacion.toIso8601String(),
        'historial_traslados': historialTraslados.map((t) => t.toJson()).toList(),
        'aula': aula,
        'usuario_acceso': usuarioAcceso,
        'clave_temporal': claveTemporal,
      };

  factory StudentEnrollment.fromJson(Map<String, dynamic> json) => StudentEnrollment(
        id: json['id'] as String,
        colegioId: (json['colegio_id'] ?? json['colegioId']) as String? ?? 'col-1',
        estudianteId: (json['estudiante_id'] ?? json['estudianteId']) as String? ?? '',
        estudianteNombre: (json['estudiante_nombre'] ?? json['estudianteNombre']) as String? ?? '',
        matricula: json['matricula'] as String? ?? '',
        cursoId: (json['curso_id'] ?? json['cursoId']) as String? ?? '',
        cursoNombre: (json['curso_nombre'] ?? json['cursoNombre']) as String? ?? '',
        seccionId: (json['seccion_id'] ?? json['seccionId']) as String? ?? '',
        seccionNombre: (json['seccion_nombre'] ?? json['seccionNombre']) as String? ?? '',
        anioEscolar: (json['anio_escolar'] ?? json['anioEscolar']) as String? ?? '2025-2026',
        estado: json['estado'] as String? ?? 'Activo',
        fechaAsignacion: json['fecha_asignacion'] != null
            ? DateTime.parse(json['fecha_asignacion'] as String)
            : DateTime.now(),
        historialTraslados: (json['historial_traslados'] as List<dynamic>?)
                ?.map((e) => StudentTransferRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        aula: json['aula'] as String? ?? '',
        usuarioAcceso: json['usuario_acceso'] as String? ?? '',
        claveTemporal: json['clave_temporal'] as String? ?? 'Estudiante2026!',
      );
}

/// Métricas del Panel de Control Académico (Issue #20)
class AcademicDashboardMetrics {
  final int totalCursos;
  final int totalSecciones;
  final int totalEstudiantesMatriculados;
  final int totalProfesores;
  final int totalMaterias;
  final double promedioEstudiantesPorAula;
  final Map<String, int> estudiantesPorCurso;
  final Map<String, int> capacidadPorCurso;

  const AcademicDashboardMetrics({
    required this.totalCursos,
    required this.totalSecciones,
    required this.totalEstudiantesMatriculados,
    required this.totalProfesores,
    required this.totalMaterias,
    required this.promedioEstudiantesPorAula,
    required this.estudiantesPorCurso,
    required this.capacidadPorCurso,
  });
}
