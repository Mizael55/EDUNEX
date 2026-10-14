import 'package:flutter/foundation.dart';

/// Firma y consentimiento digital de un tutor para una circular
class CircularSignature {
  final String id;
  final String tutorId;
  final String tutorNombre;
  final String tutorCedula;
  final String estudianteId;
  final String estudianteNombre;
  final DateTime fechaFirma;
  final bool autorizado;
  final String? comentario;

  const CircularSignature({
    required this.id,
    required this.tutorId,
    required this.tutorNombre,
    required this.tutorCedula,
    required this.estudianteId,
    required this.estudianteNombre,
    required this.fechaFirma,
    this.autorizado = true,
    this.comentario,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tutor_id': tutorId,
        'tutor_nombre': tutorNombre,
        'tutor_cedula': tutorCedula,
        'estudiante_id': estudianteId,
        'estudiante_nombre': estudianteNombre,
        'fecha_firma': fechaFirma.toIso8601String(),
        'autorizado': autorizado,
        'comentario': comentario,
      };

  factory CircularSignature.fromJson(Map<String, dynamic> json) => CircularSignature(
        id: json['id'] as String,
        tutorId: json['tutor_id'] as String,
        tutorNombre: json['tutor_nombre'] as String,
        tutorCedula: json['tutor_cedula'] as String? ?? '',
        estudianteId: json['estudiante_id'] as String,
        estudianteNombre: json['estudiante_nombre'] as String,
        fechaFirma: DateTime.parse(json['fecha_firma'] as String),
        autorizado: json['autorizado'] as bool? ?? true,
        comentario: json['comentario'] as String?,
      );
}

/// Modelo de Circular o Comunicado Oficial del Colegio
class CircularItem {
  final String id;
  final String colegioId;
  final String titulo;
  final String contenido;
  final String categoria; // 'Institucional', 'Académica', 'Feriado / Calendario', 'Autorización Requerida'
  final DateTime fechaPublicacion;
  final DateTime? fechaLimite;
  final String segmentacion; // 'Todo el Colegio', '1ro de Primaria', 'Kinder', 'Secundaria'
  final bool requiereFirma;
  final String remitenteCargo; // 'Dirección General', 'Coordinación Académica', etc.
  final List<CircularSignature> firmas;
  final List<String> leidoPorTutores; // IDs o emails de tutores que han abierto la circular
  final String estado; // 'Publicada', 'Borrador', 'Archivada'

  const CircularItem({
    required this.id,
    required this.colegioId,
    required this.titulo,
    required this.contenido,
    required this.categoria,
    required this.fechaPublicacion,
    this.fechaLimite,
    required this.segmentacion,
    this.requiereFirma = false,
    this.remitenteCargo = 'Dirección General',
    this.firmas = const [],
    this.leidoPorTutores = const [],
    this.estado = 'Publicada',
  });

  int get totalFirmas => firmas.length;
  int get totalLecturas => leidoPorTutores.length;

  bool haFirmado(String estudianteId, String tutorId) {
    return firmas.any((f) => f.estudianteId == estudianteId || f.tutorId == tutorId);
  }

  bool haLeido(String tutorIdentifier) {
    return leidoPorTutores.contains(tutorIdentifier);
  }

  CircularItem copyWith({
    String? titulo,
    String? contenido,
    String? categoria,
    DateTime? fechaLimite,
    String? segmentacion,
    bool? requiereFirma,
    String? remitenteCargo,
    List<CircularSignature>? firmas,
    List<String>? leidoPorTutores,
    String? estado,
  }) {
    return CircularItem(
      id: id,
      colegioId: colegioId,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      categoria: categoria ?? this.categoria,
      fechaPublicacion: fechaPublicacion,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      segmentacion: segmentacion ?? this.segmentacion,
      requiereFirma: requiereFirma ?? this.requiereFirma,
      remitenteCargo: remitenteCargo ?? this.remitenteCargo,
      firmas: firmas ?? this.firmas,
      leidoPorTutores: leidoPorTutores ?? this.leidoPorTutores,
      estado: estado ?? this.estado,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'titulo': titulo,
        'contenido': contenido,
        'categoria': categoria,
        'fecha_publicacion': fechaPublicacion.toIso8601String(),
        'fecha_limite': fechaLimite?.toIso8601String(),
        'segmentacion': segmentacion,
        'requiere_firma': requiereFirma,
        'remitente_cargo': remitenteCargo,
        'firmas': firmas.map((f) => f.toJson()).toList(),
        'leido_por_tutores': leidoPorTutores,
        'estado': estado,
      };

  factory CircularItem.fromJson(Map<String, dynamic> json) => CircularItem(
        id: json['id'] as String,
        colegioId: json['colegio_id'] as String,
        titulo: json['titulo'] as String,
        contenido: json['contenido'] as String,
        categoria: json['categoria'] as String? ?? 'Institucional',
        fechaPublicacion: DateTime.parse(json['fecha_publicacion'] as String),
        fechaLimite: json['fecha_limite'] != null ? DateTime.parse(json['fecha_limite'] as String) : null,
        segmentacion: json['segmentacion'] as String? ?? 'Todo el Colegio',
        requiereFirma: json['requiere_firma'] as bool? ?? false,
        remitenteCargo: json['remitente_cargo'] as String? ?? 'Dirección General',
        firmas: (json['firmas'] as List<dynamic>?)
                ?.map((e) => CircularSignature.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        leidoPorTutores: (json['leido_por_tutores'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        estado: json['estado'] as String? ?? 'Publicada',
      );
}
