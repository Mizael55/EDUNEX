import 'package:flutter/material.dart';

enum AnnouncementType {
  info,
  mantenimiento,
  actualizacion,
  alerta;

  String get displayName {
    switch (this) {
      case AnnouncementType.info:
        return 'Informativo';
      case AnnouncementType.mantenimiento:
        return 'Mantenimiento';
      case AnnouncementType.actualizacion:
        return 'Actualización';
      case AnnouncementType.alerta:
        return 'Alerta Crítica';
    }
  }

  Color get color {
    switch (this) {
      case AnnouncementType.info:
        return const Color(0xFF0284C7);
      case AnnouncementType.mantenimiento:
        return const Color(0xFFD97706);
      case AnnouncementType.actualizacion:
        return const Color(0xFF059669);
      case AnnouncementType.alerta:
        return const Color(0xFFDC2626);
    }
  }

  IconData get icon {
    switch (this) {
      case AnnouncementType.info:
        return Icons.info_outline_rounded;
      case AnnouncementType.mantenimiento:
        return Icons.build_circle_outlined;
      case AnnouncementType.actualizacion:
        return Icons.auto_awesome_rounded;
      case AnnouncementType.alerta:
        return Icons.warning_amber_rounded;
    }
  }
}

class SystemAnnouncement {
  final String id;
  final String titulo;
  final String mensaje;
  final AnnouncementType tipo;
  final DateTime fecha;
  final bool activo;
  final String creadoPor;
  final String? colegioDestinoId;

  const SystemAnnouncement({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    required this.activo,
    required this.creadoPor,
    this.colegioDestinoId,
  });

  Color get color => tipo.color;
  IconData get icon => tipo.icon;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.name,
      'fecha': fecha.toIso8601String(),
      'activo': activo,
      'creado_por': creadoPor,
      'colegio_destino_id': colegioDestinoId,
    };
  }

  factory SystemAnnouncement.fromJson(Map<String, dynamic> json) {
    AnnouncementType parsedTipo;
    final tipoStr = json['tipo']?.toString().toLowerCase();
    if (tipoStr == 'mantenimiento') {
      parsedTipo = AnnouncementType.mantenimiento;
    } else if (tipoStr == 'actualizacion') {
      parsedTipo = AnnouncementType.actualizacion;
    } else if (tipoStr == 'alerta') {
      parsedTipo = AnnouncementType.alerta;
    } else {
      parsedTipo = AnnouncementType.info;
    }

    return SystemAnnouncement(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      tipo: parsedTipo,
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      activo: json['activo'] as bool? ?? true,
      creadoPor: json['creado_por']?.toString() ?? 'SuperAdmin',
      colegioDestinoId: json['colegio_destino_id']?.toString(),
    );
  }

  SystemAnnouncement copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    AnnouncementType? tipo,
    DateTime? fecha,
    bool? activo,
    String? creadoPor,
    String? colegioDestinoId,
  }) {
    return SystemAnnouncement(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      activo: activo ?? this.activo,
      creadoPor: creadoPor ?? this.creadoPor,
      colegioDestinoId: colegioDestinoId ?? this.colegioDestinoId,
    );
  }
}
