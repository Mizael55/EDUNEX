import 'dart:convert';
import 'dart:typed_data';

/// Modelo que representa un documento digital adjunto en el expediente escolar del alumno
class StudentDocument {
  final String id;
  final String tipo; // 'foto_2x2', 'acta_nacimiento', 'certificado_notas', 'carta_saldo_conducta', 'certificado_medico'
  final String nombre; // 'Acta de Nacimiento Legalizada'
  final String nombreArchivo; // 'acta_nacimiento_mateo.pdf'
  final String? urlArchivo;
  String? get url => urlArchivo;
  final DateTime fechaSubida;
  final int tamanoBytes;
  final bool verificado;

  const StudentDocument({
    required this.id,
    required this.tipo,
    String? nombre,
    required this.nombreArchivo,
    String? urlArchivo,
    String? url,
    required this.fechaSubida,
    this.tamanoBytes = 1048576, // 1 MB default simulado
    this.verificado = true,
  })  : nombre = nombre ?? tipo,
        urlArchivo = urlArchivo ?? url;

  String get tamanoFormateado {
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      nombreArchivo.toLowerCase().endsWith('.png') ||
      nombreArchivo.toLowerCase().endsWith('.jpg') ||
      nombreArchivo.toLowerCase().endsWith('.jpeg') ||
      nombreArchivo.toLowerCase().endsWith('.webp') ||
      tipo.toLowerCase().contains('foto') ||
      (urlArchivo != null && urlArchivo!.startsWith('data:image'));

  bool get isPdf =>
      nombreArchivo.toLowerCase().endsWith('.pdf') ||
      (urlArchivo != null && urlArchivo!.startsWith('data:application/pdf'));

  Uint8List? get memoryBytes {
    if (urlArchivo != null && urlArchivo!.startsWith('data:')) {
      try {
        final commaIdx = urlArchivo!.indexOf(',');
        if (commaIdx != -1) {
          final b64 = urlArchivo!.substring(commaIdx + 1);
          return base64Decode(b64);
        }
      } catch (_) {}
    }
    return null;
  }

  StudentDocument copyWith({
    String? id,
    String? tipo,
    String? nombre,
    String? nombreArchivo,
    String? urlArchivo,
    DateTime? fechaSubida,
    int? tamanoBytes,
    bool? verificado,
  }) {
    return StudentDocument(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      urlArchivo: urlArchivo ?? this.urlArchivo,
      fechaSubida: fechaSubida ?? this.fechaSubida,
      tamanoBytes: tamanoBytes ?? this.tamanoBytes,
      verificado: verificado ?? this.verificado,
    );
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
