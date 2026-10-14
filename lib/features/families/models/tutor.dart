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
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory Tutor.fromJson(Map<String, dynamic> json) {
    List<String> docs = [];
    if (json['otros_documentos'] is List) {
      docs = (json['otros_documentos'] as List).map((e) => e.toString()).toList();
    }

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
      cartaTrabajoAdjunta: json['carta_trabajo_adjunta'] as bool? ?? false,
      estadosFinancierosAdjuntos: json['estados_financieros_adjuntos'] as bool? ?? false,
      copiaCedulaAdjunta: json['copia_cedula_adjunta'] as bool? ?? false,
      otrosDocumentos: docs,
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
    };
  }
}
