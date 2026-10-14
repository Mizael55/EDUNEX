/// Modelo de Evento o Actividad Escolar en EDUNEX
class SchoolEvent {
  final String id;
  final String colegioId;
  final String titulo;
  final String descripcion;
  final String tipo; // 'Excursión', 'Taller STEAM', 'Acto Institucional', 'Torneo Deportivo', 'Campamento'
  final DateTime fechaEvento;
  final DateTime fechaLimiteInscripcion;
  final String lugar;
  final double precio;
  final int cupoMaximo;
  final int cuposOcupados;
  final String estado; // 'Abierto', 'Cupo Lleno', 'Finalizado'
  final List<String> estudiantesInscritos;

  const SchoolEvent({
    required this.id,
    required this.colegioId,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.fechaEvento,
    required this.fechaLimiteInscripcion,
    required this.lugar,
    required this.precio,
    required this.cupoMaximo,
    this.cuposOcupados = 0,
    this.estado = 'Abierto',
    this.estudiantesInscritos = const [],
  });

  bool get tieneCupoDisponible => cuposOcupados < cupoMaximo;
  int get cuposRestantes => (cupoMaximo - cuposOcupados).clamp(0, cupoMaximo);
  bool get esGratuito => precio <= 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'colegio_id': colegioId,
    'titulo': titulo,
    'descripcion': descripcion,
    'tipo': tipo,
    'fecha_evento': fechaEvento.toIso8601String(),
    'fecha_limite_inscripcion': fechaLimiteInscripcion.toIso8601String(),
    'lugar': lugar,
    'precio': precio,
    'cupo_maximo': cupoMaximo,
    'cupos_ocupados': cuposOcupados,
    'estado': estado,
    'estudiantes_inscritos': estudiantesInscritos,
  };

  factory SchoolEvent.fromJson(Map<String, dynamic> json) => SchoolEvent(
    id: json['id'] as String,
    colegioId: json['colegio_id'] as String,
    titulo: json['titulo'] as String,
    descripcion: json['descripcion'] as String,
    tipo: json['tipo'] as String,
    fechaEvento: DateTime.parse(json['fecha_evento'] as String),
    fechaLimiteInscripcion: DateTime.parse(json['fecha_limite_inscripcion'] as String),
    lugar: json['lugar'] as String,
    precio: (json['precio'] as num).toDouble(),
    cupoMaximo: json['cupo_maximo'] as int,
    cuposOcupados: json['cupos_ocupados'] as int? ?? 0,
    estado: json['estado'] as String? ?? 'Abierto',
    estudiantesInscritos: (json['estudiantes_inscritos'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  SchoolEvent copyWith({
    String? id,
    String? colegioId,
    String? titulo,
    String? descripcion,
    String? tipo,
    DateTime? fechaEvento,
    DateTime? fechaLimiteInscripcion,
    String? lugar,
    double? precio,
    int? cupoMaximo,
    int? cuposOcupados,
    String? estado,
    List<String>? estudiantesInscritos,
  }) {
    return SchoolEvent(
      id: id ?? this.id,
      colegioId: colegioId ?? this.colegioId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      fechaLimiteInscripcion: fechaLimiteInscripcion ?? this.fechaLimiteInscripcion,
      lugar: lugar ?? this.lugar,
      precio: precio ?? this.precio,
      cupoMaximo: cupoMaximo ?? this.cupoMaximo,
      cuposOcupados: cuposOcupados ?? this.cuposOcupados,
      estado: estado ?? this.estado,
      estudiantesInscritos: estudiantesInscritos ?? this.estudiantesInscritos,
    );
  }
}
