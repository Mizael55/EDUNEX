import 'student_document.dart';

/// Modelo de Tutor / Contacto Legal de la Familia en EDUNEX
class Tutor {
  final String id;
  final String familiaId;
  final String? usuarioId;
  final String nombres;
  final String apellidos;
  final String parentesco;
  final String? cedulaOPasaporte;
  final String? telefono;
  final String? email;
  final bool esContactoPrincipal;
  final bool autorizadoRecoger;

  final String? ocupacion;
  final String? lugarTrabajo;
  final String? telefonoTrabajo;
  final String? ingresosAproximados;
  final bool cartaTrabajoAdjunta;
  final bool estadosFinancierosAdjuntos;
  final bool copiaCedulaAdjunta;
  final List<String> otrosDocumentos;
  // Issue #19: Documentos digitales adjuntos del tutor / padre
  final List<StudentDocument> documentosExpediente;

  const Tutor({
    required this.id,
    required this.familiaId,
    this.usuarioId,
    required this.nombres,
    required this.apellidos,
    required this.parentesco,
    this.cedulaOPasaporte,
    this.telefono,
    this.email,
    this.esContactoPrincipal = false,
    this.autorizadoRecoger = true,
    this.ocupacion,
    this.lugarTrabajo,
    this.telefonoTrabajo,
    this.ingresosAproximados,
    this.cartaTrabajoAdjunta = false,
    this.estadosFinancierosAdjuntos = false,
    this.copiaCedulaAdjunta = false,
    this.otrosDocumentos = const [],
    this.documentosExpediente = const [],
  });

  List<StudentDocument> get documentos => documentosExpediente;

  String get nombreCompleto => '$nombres $apellidos'.trim();

  Tutor copyWith({
    String? id,
    String? familiaId,
    String? usuarioId,
    String? nombres,
    String? apellidos,
    String? parentesco,
    String? cedulaOPasaporte,
    String? telefono,
    String? email,
    bool? esContactoPrincipal,
    bool? autorizadoRecoger,
    String? ocupacion,
    String? lugarTrabajo,
    String? telefonoTrabajo,
    String? ingresosAproximados,
    bool? cartaTrabajoAdjunta,
    bool? estadosFinancierosAdjuntos,
    bool? copiaCedulaAdjunta,
    List<String>? otrosDocumentos,
    List<StudentDocument>? documentosExpediente,
  }) {
    return Tutor(
      id: id ?? this.id,
      familiaId: familiaId ?? this.familiaId,
      usuarioId: usuarioId ?? this.usuarioId,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      parentesco: parentesco ?? this.parentesco,
      cedulaOPasaporte: cedulaOPasaporte ?? this.cedulaOPasaporte,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      esContactoPrincipal: esContactoPrincipal ?? this.esContactoPrincipal,
      autorizadoRecoger: autorizadoRecoger ?? this.autorizadoRecoger,
      ocupacion: ocupacion ?? this.ocupacion,
      lugarTrabajo: lugarTrabajo ?? this.lugarTrabajo,
      telefonoTrabajo: telefonoTrabajo ?? this.telefonoTrabajo,
      ingresosAproximados: ingresosAproximados ?? this.ingresosAproximados,
      cartaTrabajoAdjunta: cartaTrabajoAdjunta ?? this.cartaTrabajoAdjunta,
      estadosFinancierosAdjuntos: estadosFinancierosAdjuntos ?? this.estadosFinancierosAdjuntos,
      copiaCedulaAdjunta: copiaCedulaAdjunta ?? this.copiaCedulaAdjunta,
      otrosDocumentos: otrosDocumentos ?? this.otrosDocumentos,
      documentosExpediente: documentosExpediente ?? this.documentosExpediente,
    );
  }

  factory Tutor.fromJson(Map<String, dynamic> json) {
    List<String> docs = [];
    if (json['otros_documentos'] is List) {
      docs = (json['otros_documentos'] as List).map((e) => e.toString()).toList();
    }

    List<StudentDocument> docList = [];
    if (json['documentos_expediente'] is List) {
      docList = (json['documentos_expediente'] as List)
          .map<StudentDocument>((d) => StudentDocument.fromJson(d as Map<String, dynamic>))
          .toList();
    } else if (json['documentos'] is List) {
      docList = (json['documentos'] as List)
          .map<StudentDocument>((d) => StudentDocument.fromJson(d as Map<String, dynamic>))
          .toList();
    }

    final bool copiaCedula = json['copia_cedula_adjunta'] as bool? ??
        docList.any((d) => d.tipo.toLowerCase().contains('cedula') || d.tipo.toLowerCase().contains('cédula'));
    final bool cartaTrabajo = json['carta_trabajo_adjunta'] as bool? ??
        docList.any((d) => d.tipo.toLowerCase().contains('trabajo') || d.tipo.toLowerCase().contains('laboral'));
    final bool estadosFinancieros = json['estados_financieros_adjuntos'] as bool? ??
        docList.any((d) => d.tipo.toLowerCase().contains('financiero') || d.tipo.toLowerCase().contains('ingreso'));

    return Tutor(
      id: json['id'] as String? ?? '',
      familiaId: json['familia_id'] as String? ?? '',
      usuarioId: json['usuario_id'] as String?,
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      parentesco: json['parentesco'] as String? ?? 'Tutor Legal',
      cedulaOPasaporte: json['cedula_o_pasaporte'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      esContactoPrincipal: json['es_contacto_principal'] as bool? ?? false,
      autorizadoRecoger: json['autorizado_recoger'] as bool? ?? true,
      ocupacion: json['ocupacion'] as String?,
      lugarTrabajo: json['lugar_trabajo'] as String?,
      telefonoTrabajo: json['telefono_trabajo'] as String?,
      ingresosAproximados: json['ingresos_aproximados'] as String?,
      cartaTrabajoAdjunta: cartaTrabajo,
      estadosFinancierosAdjuntos: estadosFinancieros,
      copiaCedulaAdjunta: copiaCedula,
      otrosDocumentos: docs,
      documentosExpediente: docList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familia_id': familiaId,
      'usuario_id': usuarioId,
      'nombres': nombres,
      'apellidos': apellidos,
      'parentesco': parentesco,
      'cedula_o_pasaporte': cedulaOPasaporte,
      'telefono': telefono,
      'email': email,
      'es_contacto_principal': esContactoPrincipal,
      'autorizado_recoger': autorizadoRecoger,
      'ocupacion': ocupacion,
      'lugar_trabajo': lugarTrabajo,
      'telefono_trabajo': telefonoTrabajo,
      'ingresos_aproximados': ingresosAproximados,
      'carta_trabajo_adjunta': cartaTrabajoAdjunta,
      'estados_financieros_adjuntos': estadosFinancierosAdjuntos,
      'copia_cedula_adjunta': copiaCedulaAdjunta,
      'otros_documentos': otrosDocumentos,
      'documentos_expediente': documentosExpediente.map((d) => d.toJson()).toList(),
    };
  }
}
