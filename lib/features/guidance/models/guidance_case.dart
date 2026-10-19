/// Modelos para el Módulo de Psicología, Orientación Escolar y Convivencia
/// Gestiona la atención psicopedagógica, casos remitidos, sesiones de intervención y citaciones a tutores.

class GuidanceSession {
  final String id;
  final DateTime fecha;
  final String tipo; // 'Individual con Alumno', 'Observación Áulica', 'Evaluación Psicopedagógica', 'Seguimiento'
  final String notasConfidenciales;
  final String acuerdos;
  final String profesionalACargo;

  const GuidanceSession({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.notasConfidenciales,
    required this.acuerdos,
    required this.profesionalACargo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'tipo': tipo,
        'notasConfidenciales': notasConfidenciales,
        'acuerdos': acuerdos,
        'profesionalACargo': profesionalACargo,
      };

  factory GuidanceSession.fromJson(Map<String, dynamic> json) => GuidanceSession(
        id: json['id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        tipo: json['tipo'] as String,
        notasConfidenciales: json['notasConfidenciales'] as String,
        acuerdos: json['acuerdos'] as String,
        profesionalACargo: json['profesionalACargo'] as String,
      );
}

class ParentInterview {
  final String id;
  final DateTime fecha;
  final String hora;
  final String modalidad; // 'Presencial', 'Virtual (Meet/Zoom)'
  final String motivo;
  final String estado; // 'Programada', 'Realizada', 'Cancelada', 'Reprogramada'
  final String? conclusiones;

  const ParentInterview({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.modalidad,
    required this.motivo,
    required this.estado,
    this.conclusiones,
  });

  ParentInterview copyWith({
    DateTime? fecha,
    String? hora,
    String? modalidad,
    String? motivo,
    String? estado,
    String? conclusiones,
  }) {
    return ParentInterview(
      id: id,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      modalidad: modalidad ?? this.modalidad,
      motivo: motivo ?? this.motivo,
      estado: estado ?? this.estado,
      conclusiones: conclusiones ?? this.conclusiones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'hora': hora,
        'modalidad': modalidad,
        'motivo': motivo,
        'estado': estado,
        'conclusiones': conclusiones,
      };

  factory ParentInterview.fromJson(Map<String, dynamic> json) => ParentInterview(
        id: json['id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        hora: json['hora'] as String,
        modalidad: json['modalidad'] as String,
        motivo: json['motivo'] as String,
        estado: json['estado'] as String,
        conclusiones: json['conclusiones'] as String?,
      );
}

class ConvivenciaAgreement {
  final String id;
  final DateTime fecha;
  final String descripcion;
  final String responsable; // 'Estudiante', 'Padres / Tutores', 'Colegio', 'Docente'
  final bool cumplido;

  const ConvivenciaAgreement({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.responsable,
    this.cumplido = false,
  });

  ConvivenciaAgreement copyWith({
    DateTime? fecha,
    String? descripcion,
    String? responsable,
    bool? cumplido,
  }) {
    return ConvivenciaAgreement(
      id: id,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      responsable: responsable ?? this.responsable,
      cumplido: cumplido ?? this.cumplido,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'descripcion': descripcion,
        'responsable': responsable,
        'cumplido': cumplido,
      };

  factory ConvivenciaAgreement.fromJson(Map<String, dynamic> json) => ConvivenciaAgreement(
        id: json['id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        descripcion: json['descripcion'] as String,
        responsable: json['responsable'] as String,
        cumplido: json['cumplido'] as bool? ?? false,
      );
}

class GuidanceCase {
  final String id;
  final String colegioId;
  final String studentId;
  final String studentName;
  final String matricula;
  final String grado;
  final String seccion;
  final String remitidoPor; // 'Docente de Matemáticas', 'Dirección Académica', 'Solicitud Familiar'
  final String motivoRemision;
  final DateTime fechaRemision;
  final String estado; // 'En Evaluación', 'En Intervención', 'Citación a Tutores', 'Cerrado'
  final String nivelUrgencia; // 'Alta', 'Media', 'Baja'
  final String? diagnosticoSugerido; // Ej. 'TDAH con predominio de inatención', 'Dislexia evolutiva'
  final List<GuidanceSession> sesiones;
  final List<ParentInterview> citasPadres;
  final List<ConvivenciaAgreement> compromisos;

  const GuidanceCase({
    required this.id,
    required this.colegioId,
    required this.studentId,
    required this.studentName,
    required this.matricula,
    required this.grado,
    required this.seccion,
    required this.remitidoPor,
    required this.motivoRemision,
    required this.fechaRemision,
    this.estado = 'En Evaluación',
    this.nivelUrgencia = 'Media',
    this.diagnosticoSugerido,
    this.sesiones = const [],
    this.citasPadres = const [],
    this.compromisos = const [],
  });

  bool get esActivo => estado != 'Cerrado';
  bool get esUrgente => nivelUrgencia == 'Alta';

  GuidanceCase copyWith({
    String? estado,
    String? nivelUrgencia,
    String? motivoRemision,
    String? diagnosticoSugerido,
    List<GuidanceSession>? sesiones,
    List<ParentInterview>? citasPadres,
    List<ConvivenciaAgreement>? compromisos,
  }) {
    return GuidanceCase(
      id: id,
      colegioId: colegioId,
      studentId: studentId,
      studentName: studentName,
      matricula: matricula,
      grado: grado,
      seccion: seccion,
      remitidoPor: remitidoPor,
      motivoRemision: motivoRemision ?? this.motivoRemision,
      fechaRemision: fechaRemision,
      estado: estado ?? this.estado,
      nivelUrgencia: nivelUrgencia ?? this.nivelUrgencia,
      diagnosticoSugerido: diagnosticoSugerido ?? this.diagnosticoSugerido,
      sesiones: sesiones ?? this.sesiones,
      citasPadres: citasPadres ?? this.citasPadres,
      compromisos: compromisos ?? this.compromisos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegioId': colegioId,
        'studentId': studentId,
        'studentName': studentName,
        'matricula': matricula,
        'grado': grado,
        'seccion': seccion,
        'remitidoPor': remitidoPor,
        'motivoRemision': motivoRemision,
        'fechaRemision': fechaRemision.toIso8601String(),
        'estado': estado,
        'nivelUrgencia': nivelUrgencia,
        'diagnosticoSugerido': diagnosticoSugerido,
        'sesiones': sesiones.map((s) => s.toJson()).toList(),
        'citasPadres': citasPadres.map((c) => c.toJson()).toList(),
        'compromisos': compromisos.map((a) => a.toJson()).toList(),
      };

  factory GuidanceCase.fromJson(Map<String, dynamic> json) => GuidanceCase(
        id: json['id'] as String,
        colegioId: json['colegioId'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        matricula: json['matricula'] as String,
        grado: json['grado'] as String,
        seccion: json['seccion'] as String,
        remitidoPor: json['remitidoPor'] as String,
        motivoRemision: json['motivoRemision'] as String,
        fechaRemision: DateTime.parse(json['fechaRemision'] as String),
        estado: json['estado'] as String? ?? 'En Evaluación',
        nivelUrgencia: json['nivelUrgencia'] as String? ?? 'Media',
        diagnosticoSugerido: json['diagnosticoSugerido'] as String?,
        sesiones: (json['sesiones'] as List<dynamic>?)
                ?.map((s) => GuidanceSession.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        citasPadres: (json['citasPadres'] as List<dynamic>?)
                ?.map((c) => ParentInterview.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        compromisos: (json['compromisos'] as List<dynamic>?)
                ?.map((a) => ConvivenciaAgreement.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
