/// Configuración corporativa de la empresa dueña del software SaaS (EDUNEX)
class SaaSCompanyConfig {
  final String rnc;
  final String razonSocial;
  final String nombreComercial;
  final String emailSoporte;
  final String emailFacturacion;
  final String telefono;
  final String direccion;
  final String sitioWeb;
  final int secuenciaNCFB01;
  final int secuenciaNCFB02;
  final int diasGraciaSuspension;
  final double tasaItbis;
  final bool modoMantenimiento;
  final bool exigir2FA;
  final int minPasswordLength;

  const SaaSCompanyConfig({
    this.rnc = '1-32-45678-9',
    this.razonSocial = 'EDUNEX Dominicana SAS',
    this.nombreComercial = 'EDUNEX - Plataforma SaaS Educativa',
    this.emailSoporte = 'soporte@edunex.edu.do',
    this.emailFacturacion = 'facturacion@edunex.edu.do',
    this.telefono = '809-555-0199',
    this.direccion = 'Av. Winston Churchill #1099, Torre Empresarial, D.N.',
    this.sitioWeb = 'https://edunex.edu.do',
    this.secuenciaNCFB01 = 105,
    this.secuenciaNCFB02 = 230,
    this.diasGraciaSuspension = 15,
    this.tasaItbis = 0.18,
    this.modoMantenimiento = false,
    this.exigir2FA = false,
    this.minPasswordLength = 8,
  });

  SaaSCompanyConfig copyWith({
    String? rnc,
    String? razonSocial,
    String? nombreComercial,
    String? emailSoporte,
    String? emailFacturacion,
    String? telefono,
    String? direccion,
    String? sitioWeb,
    int? secuenciaNCFB01,
    int? secuenciaNCFB02,
    int? diasGraciaSuspension,
    double? tasaItbis,
    bool? modoMantenimiento,
    bool? exigir2FA,
    int? minPasswordLength,
  }) {
    return SaaSCompanyConfig(
      rnc: rnc ?? this.rnc,
      razonSocial: razonSocial ?? this.razonSocial,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      emailSoporte: emailSoporte ?? this.emailSoporte,
      emailFacturacion: emailFacturacion ?? this.emailFacturacion,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      sitioWeb: sitioWeb ?? this.sitioWeb,
      secuenciaNCFB01: secuenciaNCFB01 ?? this.secuenciaNCFB01,
      secuenciaNCFB02: secuenciaNCFB02 ?? this.secuenciaNCFB02,
      diasGraciaSuspension: diasGraciaSuspension ?? this.diasGraciaSuspension,
      tasaItbis: tasaItbis ?? this.tasaItbis,
      modoMantenimiento: modoMantenimiento ?? this.modoMantenimiento,
      exigir2FA: exigir2FA ?? this.exigir2FA,
      minPasswordLength: minPasswordLength ?? this.minPasswordLength,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rnc': rnc,
      'razon_social': razonSocial,
      'nombre_comercial': nombreComercial,
      'email_soporte': emailSoporte,
      'email_facturacion': emailFacturacion,
      'telefono': telefono,
      'direccion': direccion,
      'sitio_web': sitioWeb,
      'secuencia_ncf_b01': secuenciaNCFB01,
      'secuencia_ncf_b02': secuenciaNCFB02,
      'dias_gracia_suspension': diasGraciaSuspension,
      'tasa_itbis': tasaItbis,
      'modo_mantenimiento': modoMantenimiento,
      'exigir_2fa': exigir2FA,
      'min_password_length': minPasswordLength,
    };
  }

  factory SaaSCompanyConfig.fromJson(Map<String, dynamic> json) {
    return SaaSCompanyConfig(
      rnc: json['rnc'] as String? ?? '1-32-45678-9',
      razonSocial: json['razon_social'] as String? ?? 'EDUNEX Dominicana SAS',
      nombreComercial: json['nombre_comercial'] as String? ?? 'EDUNEX - Plataforma SaaS Educativa',
      emailSoporte: json['email_soporte'] as String? ?? 'soporte@edunex.edu.do',
      emailFacturacion: json['email_facturacion'] as String? ?? 'facturacion@edunex.edu.do',
      telefono: json['telefono'] as String? ?? '809-555-0199',
      direccion: json['direccion'] as String? ?? 'Av. Winston Churchill #1099, Torre Empresarial, D.N.',
      sitioWeb: json['sitio_web'] as String? ?? 'https://edunex.edu.do',
      secuenciaNCFB01: json['secuencia_ncf_b01'] as int? ?? 105,
      secuenciaNCFB02: json['secuencia_ncf_b02'] as int? ?? 230,
      diasGraciaSuspension: json['dias_gracia_suspension'] as int? ?? 15,
      tasaItbis: (json['tasa_itbis'] as num?)?.toDouble() ?? 0.18,
      modoMantenimiento: json['modo_mantenimiento'] as bool? ?? false,
      exigir2FA: json['exigir_2fa'] as bool? ?? false,
      minPasswordLength: json['min_password_length'] as int? ?? 8,
    );
  }
}
