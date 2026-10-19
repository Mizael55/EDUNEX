/// Modelo que representa un documento digital adjunto en el expediente escolar del alumno
class StudentDocument {
  final String id;
  final String tipo; // 'foto_2x2', 'acta_nacimiento', 'certificado_notas', 'carta_saldo_conducta', 'certificado_medico'
  final String nombre; // 'Acta de Nacimiento Legalizada'
  final String nombreArchivo; // 'acta_nacimiento_mateo.pdf'
  final String? urlArchivo;
  final DateTime fechaSubida;
  final int tamanoBytes;
  final bool verificado;

  const StudentDocument({
    required this.id,
    required this.tipo,
    String? nombre,
    required this.nombreArchivo,
    this.urlArchivo,
    required this.fechaSubida,
    this.tamanoBytes = 1048576, // 1 MB default simulado
    this.verificado = true,
  }) : nombre = nombre ?? tipo;

  String get tamanoFormateado {
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['fecha_subida'] as String? ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return StudentDocument(
      id: json['id'] as String? ?? 'doc-${DateTime.now().millisecondsSinceEpoch}',
      tipo: json['tipo'] as String? ?? 'general',
      nombre: json['nombre'] as String? ?? 'Documento Escolar',
      nombreArchivo: json['nombre_archivo'] as String? ?? 'documento.pdf',
      urlArchivo: json['url_archivo'] as String?,
      fechaSubida: parsedDate,
      tamanoBytes: json['tamano_bytes'] as int? ?? 1048576,
      verificado: json['verificado'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'nombre': nombre,
      'nombre_archivo': nombreArchivo,
      'url_archivo': urlArchivo,
      'fecha_subida': fechaSubida.toIso8601String(),
      'tamano_bytes': tamanoBytes,
      'verificado': verificado,
    };
  }
}
