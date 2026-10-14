import 'package:flutter/foundation.dart';

/// Parada autorizada dentro de una ruta escolar
class TransportStop {
  final String id;
  final String nombre;
  final String direccionReferencia;
  final String horaEstimadaManana;
  final String horaEstimadaTarde;
  final int orden;

  const TransportStop({
    required this.id,
    required this.nombre,
    required this.direccionReferencia,
    required this.horaEstimadaManana,
    required this.horaEstimadaTarde,
    required this.orden,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'direccion_referencia': direccionReferencia,
        'hora_estimada_manana': horaEstimadaManana,
        'hora_estimada_tarde': horaEstimadaTarde,
        'orden': orden,
      };

  factory TransportStop.fromJson(Map<String, dynamic> json) => TransportStop(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        direccionReferencia: json['direccion_referencia'] as String? ?? '',
        horaEstimadaManana: json['hora_estimada_manana'] as String? ?? '07:15 AM',
        horaEstimadaTarde: json['hora_estimada_tarde'] as String? ?? '03:30 PM',
        orden: json['orden'] as int? ?? 1,
      );
}

/// Estado de abordaje del estudiante en el recorrido
enum BoardingStatus {
  enEspera('En Espera en Parada'),
  abordo('Abordó Autobús'),
  entregado('Entregado en Destino'),
  noViaja('No Viaja Hoy');

  final String label;
  const BoardingStatus(this.label);
}

/// Alumno pasajero asignado a una ruta
class TransportPassenger {
  final String estudianteId;
  final String estudianteNombre;
  final String matricula;
  final String familiaId;
  final String gradoNombre;
  final String seccionNombre;
  final String paradaId;
  final String paradaNombre;
  final String tutorContacto;
  final String tutorTelefono;
  final String estadoAbordaje; // 'En Espera en Parada', 'Abordó Autobús', 'Entregado en Destino', 'No Viaja Hoy'
  final String? horaCheckIn;

  const TransportPassenger({
    required this.estudianteId,
    required this.estudianteNombre,
    required this.matricula,
    required this.familiaId,
    required this.gradoNombre,
    required this.seccionNombre,
    required this.paradaId,
    required this.paradaNombre,
    required this.tutorContacto,
    required this.tutorTelefono,
    this.estadoAbordaje = 'En Espera en Parada',
    this.horaCheckIn,
  });

  TransportPassenger copyWith({
    String? estadoAbordaje,
    String? horaCheckIn,
  }) {
    return TransportPassenger(
      estudianteId: estudianteId,
      estudianteNombre: estudianteNombre,
      matricula: matricula,
      familiaId: familiaId,
      gradoNombre: gradoNombre,
      seccionNombre: seccionNombre,
      paradaId: paradaId,
      paradaNombre: paradaNombre,
      tutorContacto: tutorContacto,
      tutorTelefono: tutorTelefono,
      estadoAbordaje: estadoAbordaje ?? this.estadoAbordaje,
      horaCheckIn: horaCheckIn ?? this.horaCheckIn,
    );
  }

  Map<String, dynamic> toJson() => {
        'estudiante_id': estudianteId,
        'estudiante_nombre': estudianteNombre,
        'matricula': matricula,
        'familia_id': familiaId,
        'grado_nombre': gradoNombre,
        'seccion_nombre': seccionNombre,
        'parada_id': paradaId,
        'parada_nombre': paradaNombre,
        'tutor_contacto': tutorContacto,
        'tutor_telefono': tutorTelefono,
        'estado_abordaje': estadoAbordaje,
        'hora_check_in': horaCheckIn,
      };

  factory TransportPassenger.fromJson(Map<String, dynamic> json) => TransportPassenger(
        estudianteId: json['estudiante_id'] as String,
        estudianteNombre: json['estudiante_nombre'] as String,
        matricula: json['matricula'] as String? ?? '',
        familiaId: json['familia_id'] as String? ?? '',
        gradoNombre: json['grado_nombre'] as String? ?? '',
        seccionNombre: json['seccion_nombre'] as String? ?? '',
        paradaId: json['parada_id'] as String? ?? '',
        paradaNombre: json['parada_nombre'] as String? ?? '',
        tutorContacto: json['tutor_contacto'] as String? ?? '',
        tutorTelefono: json['tutor_telefono'] as String? ?? '',
        estadoAbordaje: json['estado_abordaje'] as String? ?? 'En Espera en Parada',
        horaCheckIn: json['hora_check_in'] as String?,
      );
}

/// Modelo Principal de Ruta Escolar Oficial
class BusRoute {
  final String id;
  final String colegioId;
  final String nombre;
  final String codigo;
  final String turno; // 'Matutino', 'Vespertino', 'Completo'
  final String vehiculoPlaca;
  final String vehiculoModelo;
  final int capacidadAsientos;
  final String choferNombre;
  final String choferTelefono;
  final String choferLicencia;
  final String monitoraNombre;
  final String monitoraTelefono;
  final String estadoRuta; // 'En Espera', 'En Tránsito', 'Completada', 'Mantenimiento'
  final String zonaGeografica;
  final List<TransportStop> paradas;
  final List<TransportPassenger> pasajeros;

  const BusRoute({
    required this.id,
    required this.colegioId,
    required this.nombre,
    required this.codigo,
    required this.turno,
    required this.vehiculoPlaca,
    required this.vehiculoModelo,
    required this.capacidadAsientos,
    required this.choferNombre,
    required this.choferTelefono,
    required this.choferLicencia,
    required this.monitoraNombre,
    required this.monitoraTelefono,
    this.estadoRuta = 'En Espera',
    required this.zonaGeografica,
    this.paradas = const [],
    this.pasajeros = const [],
  });

  int get totalPasajeros => pasajeros.length;
  int get asientosDisponibles => capacidadAsientos - totalPasajeros;
  double get porcentajeOcupacion =>
      capacidadAsientos > 0 ? (totalPasajeros / capacidadAsientos) * 100 : 0.0;

  bool get estaLlena => totalPasajeros >= capacidadAsientos;
  bool get enTransito => estadoRuta == 'En Tránsito';
  bool get completada => estadoRuta == 'Completada';

  BusRoute copyWith({
    String? nombre,
    String? turno,
    String? vehiculoPlaca,
    String? vehiculoModelo,
    int? capacidadAsientos,
    String? choferNombre,
    String? choferTelefono,
    String? monitoraNombre,
    String? monitoraTelefono,
    String? estadoRuta,
    String? zonaGeografica,
    List<TransportStop>? paradas,
    List<TransportPassenger>? pasajeros,
  }) {
    return BusRoute(
      id: id,
      colegioId: colegioId,
      nombre: nombre ?? this.nombre,
      codigo: codigo,
      turno: turno ?? this.turno,
      vehiculoPlaca: vehiculoPlaca ?? this.vehiculoPlaca,
      vehiculoModelo: vehiculoModelo ?? this.vehiculoModelo,
      capacidadAsientos: capacidadAsientos ?? this.capacidadAsientos,
      choferNombre: choferNombre ?? this.choferNombre,
      choferTelefono: choferTelefono ?? this.choferTelefono,
      choferLicencia: choferLicencia,
      monitoraNombre: monitoraNombre ?? this.monitoraNombre,
      monitoraTelefono: monitoraTelefono ?? this.monitoraTelefono,
      estadoRuta: estadoRuta ?? this.estadoRuta,
      zonaGeografica: zonaGeografica ?? this.zonaGeografica,
      paradas: paradas ?? this.paradas,
      pasajeros: pasajeros ?? this.pasajeros,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colegio_id': colegioId,
        'nombre': nombre,
        'codigo': codigo,
        'turno': turno,
        'vehiculo_placa': vehiculoPlaca,
        'vehiculo_modelo': vehiculoModelo,
        'capacidad_asientos': capacidadAsientos,
        'chofer_nombre': choferNombre,
        'chofer_telefono': choferTelefono,
        'chofer_licencia': choferLicencia,
        'monitora_nombre': monitoraNombre,
        'monitora_telefono': monitoraTelefono,
        'estado_ruta': estadoRuta,
        'zona_geografica': zonaGeografica,
        'paradas': paradas.map((p) => p.toJson()).toList(),
        'pasajeros': pasajeros.map((p) => p.toJson()).toList(),
      };

  factory BusRoute.fromJson(Map<String, dynamic> json) => BusRoute(
        id: json['id'] as String,
        colegioId: json['colegio_id'] as String,
        nombre: json['nombre'] as String,
        codigo: json['codigo'] as String? ?? 'RUTA-01',
        turno: json['turno'] as String? ?? 'Completo',
        vehiculoPlaca: json['vehiculo_placa'] as String? ?? '',
        vehiculoModelo: json['vehiculo_modelo'] as String? ?? '',
        capacidadAsientos: json['capacidad_asientos'] as int? ?? 25,
        choferNombre: json['chofer_nombre'] as String? ?? '',
        choferTelefono: json['chofer_telefono'] as String? ?? '',
        choferLicencia: json['chofer_licencia'] as String? ?? '',
        monitoraNombre: json['monitora_nombre'] as String? ?? '',
        monitoraTelefono: json['monitora_telefono'] as String? ?? '',
        estadoRuta: json['estado_ruta'] as String? ?? 'En Espera',
        zonaGeografica: json['zona_geografica'] as String? ?? '',
        paradas: (json['paradas'] as List<dynamic>?)
                ?.map((e) => TransportStop.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        pasajeros: (json['pasajeros'] as List<dynamic>?)
                ?.map((e) => TransportPassenger.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
