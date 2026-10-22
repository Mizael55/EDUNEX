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

/// Modelo de Perfil de Profesor (Issue #20)
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
      );
}

/// Asignación Académica de Profesor a Materia, Curso y Sección (Issue #20)
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

/// Matrícula y Asignación de Estudiante a Curso y Sección (Issue #20)
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
