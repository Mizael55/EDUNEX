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
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory Tutor.fromJson(Map<String, dynamic> json) {
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
    };
  }
}
