import 'package:flutter/foundation.dart';
import '../models/bus_route.dart';
import '../../families/repositories/family_repository.dart';

/// Repositorio Operativo para la Gestión de Rutas, Unidades y Pasajeros de Transporte Escolar
class TransportRepository {
  final FamilyRepository? _familyRepository;
  final bool useDemoFallback;
  final List<BusRoute> _routes;

  TransportRepository({
    FamilyRepository? familyRepository,
    this.useDemoFallback = false,
  })  : _familyRepository = familyRepository,
        _routes = useDemoFallback ? List<BusRoute>.from(_defaultRoutes) : [];

  void clearAllData() {
    _routes.clear();
  }

  static final List<BusRoute> _defaultRoutes = [
    BusRoute(
      id: 'route-001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      codigo: 'RUTA-01',
      nombre: 'Ruta 1 - Naco / Piantini / Serrallés',
      turno: 'Completo',
      zonaGeografica: 'Distrito Nacional Centro (Polígono Central)',
      vehiculoPlaca: 'I-084921',
      vehiculoModelo: 'Toyota Coaster 2023 (AC, Cinturones, Botiquín)',
      capacidadAsientos: 28,
      choferNombre: 'Manuel Rosario',
      choferTelefono: '809-555-4411',
      choferLicencia: '001-9482710-1 (Cat. 4)',
      monitoraNombre: 'Ana Patricia Valdez',
      monitoraTelefono: '809-555-4412',
      estadoRuta: 'En Tránsito',
      paradas: const [
        TransportStop(
          id: 'stop-101',
          nombre: 'Parada Naco - Tiradentes',
          direccionReferencia: 'Av. Tiradentes esq. Roberto Pastoriza',
          horaEstimadaManana: '07:10 AM',
          horaEstimadaTarde: '03:15 PM',
          orden: 1,
        ),
        TransportStop(
          id: 'stop-102',
          nombre: 'Parada Piantini - David Ben Gurión',
          direccionReferencia: 'Calle David Ben Gurión #24',
          horaEstimadaManana: '07:22 AM',
          horaEstimadaTarde: '03:30 PM',
          orden: 2,
        ),
        TransportStop(
          id: 'stop-103',
          nombre: 'Parada Serrallés - Porfirio Herrera',
          direccionReferencia: 'Calle Porfirio Herrera #12',
          horaEstimadaManana: '07:35 AM',
          horaEstimadaTarde: '03:45 PM',
          orden: 3,
        ),
      ],
      pasajeros: [
        const TransportPassenger(
          estudianteId: 'f0000000-0000-0000-0000-000000000001',
          estudianteNombre: 'Mateo Pérez González',
          matricula: 'EST-2026-01',
          familiaId: 'e0000000-0000-0000-0000-000000000001',
          gradoNombre: '1ro de Primaria',
          seccionNombre: 'Sección A',
          paradaId: 'stop-101',
          paradaNombre: 'Parada Naco - Tiradentes',
          tutorContacto: 'Roberto Pérez',
          tutorTelefono: '809-555-0150',
          estadoAbordaje: 'Abordó Autobús',
          horaCheckIn: '07:12 AM',
        ),
        const TransportPassenger(
          estudianteId: 'f0000000-0000-0000-0000-000000000002',
          estudianteNombre: 'Sofía Pérez González',
          matricula: 'EST-2026-02',
          familiaId: 'e0000000-0000-0000-0000-000000000001',
          gradoNombre: 'Kinder',
          seccionNombre: 'Sección A',
          paradaId: 'stop-101',
          paradaNombre: 'Parada Naco - Tiradentes',
          tutorContacto: 'Roberto Pérez',
          tutorTelefono: '809-555-0150',
          estadoAbordaje: 'Abordó Autobús',
          horaCheckIn: '07:12 AM',
        ),
      ],
    ),
    BusRoute(
      id: 'route-002',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      codigo: 'RUTA-02',
      nombre: 'Ruta 2 - Bella Vista / Mirador Sur',
      turno: 'Completo',
      zonaGeografica: 'Santo Domingo Suroeste',
      vehiculoPlaca: 'I-091240',
      vehiculoModelo: 'Hyundai County 2024 (AC, Cámara Reversa, GPS)',
      capacidadAsientos: 24,
      choferNombre: 'Juan Carlos Guzmán',
      choferTelefono: '809-555-7733',
      choferLicencia: '001-3829104-5 (Cat. 4)',
      monitoraNombre: 'Elena Batista',
      monitoraTelefono: '809-555-7734',
      estadoRuta: 'En Espera',
      paradas: const [
        TransportStop(
          id: 'stop-201',
          nombre: 'Parada Bella Vista - Sarasota',
          direccionReferencia: 'Av. Sarasota esq. Núñez de Cáceres',
          horaEstimadaManana: '07:05 AM',
          horaEstimadaTarde: '03:10 PM',
          orden: 1,
        ),
        TransportStop(
          id: 'stop-202',
          nombre: 'Parada Mirador - Rómulo Betancourt',
          direccionReferencia: 'Av. Rómulo Betancourt #1420',
          horaEstimadaManana: '07:20 AM',
          horaEstimadaTarde: '03:25 PM',
          orden: 2,
        ),
        TransportStop(
          id: 'stop-203',
          nombre: 'Parada Enriquillo',
          direccionReferencia: 'Av. Enriquillo esq. Privada',
          horaEstimadaManana: '07:32 AM',
          horaEstimadaTarde: '03:40 PM',
          orden: 3,
        ),
      ],
      pasajeros: [
        const TransportPassenger(
          estudianteId: 'f0000000-0000-0000-0000-000000000003',
          estudianteNombre: 'Diego Ramírez Méndez',
          matricula: 'EST-2026-03',
          familiaId: 'e0000000-0000-0000-0000-000000000002',
          gradoNombre: '2do de Primaria',
          seccionNombre: 'Sección B',
          paradaId: 'stop-201',
          paradaNombre: 'Parada Bella Vista - Sarasota',
          tutorContacto: 'Laura Méndez',
          tutorTelefono: '809-555-0210',
          estadoAbordaje: 'En Espera en Parada',
        ),
      ],
    ),
    BusRoute(
      id: 'route-003',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      codigo: 'RUTA-03',
      nombre: 'Ruta 3 - Arroyo Hondo / Los Ríos',
      turno: 'Matutino',
      zonaGeografica: 'Santo Domingo Norte',
      vehiculoPlaca: 'I-075193',
      vehiculoModelo: 'Nissan Civilian 2022 (AC, Asientos Ergonómicos)',
      capacidadAsientos: 22,
      choferNombre: 'Rafael Santana',
      choferTelefono: '809-555-8822',
      choferLicencia: '001-5748291-3 (Cat. 4)',
      monitoraNombre: 'Yomaira Peña',
      monitoraTelefono: '809-555-8823',
      estadoRuta: 'En Espera',
      paradas: const [
        TransportStop(
          id: 'stop-301',
          nombre: 'Parada Camino Chiquito',
          direccionReferencia: 'Camino Chiquito esq. Héctor García Godoy',
          horaEstimadaManana: '07:00 AM',
          horaEstimadaTarde: '03:00 PM',
          orden: 1,
        ),
        TransportStop(
          id: 'stop-302',
          nombre: 'Parada Vega Real',
          direccionReferencia: 'Av. Vega Real #88',
          horaEstimadaManana: '07:18 AM',
          horaEstimadaTarde: '03:20 PM',
          orden: 2,
        ),
      ],
      pasajeros: [
        const TransportPassenger(
          estudianteId: 'f0000000-0000-0000-0000-000000000004',
          estudianteNombre: 'Camila Castillo',
          matricula: 'EST-2026-04',
          familiaId: 'e0000000-0000-0000-0000-000000000003',
          gradoNombre: '1ro de Primaria',
          seccionNombre: 'Sección A',
          paradaId: 'stop-301',
          paradaNombre: 'Parada Camino Chiquito',
          tutorContacto: 'Patricia Castillo',
          tutorTelefono: '809-555-0315',
          estadoAbordaje: 'En Espera en Parada',
        ),
      ],
    ),
  ];

  /// Obtiene la lista de rutas escolares activas del colegio
  Future<List<BusRoute>> getRoutes({required String colegioId}) async {
    final list = _routes.where((r) {
      return r.colegioId == colegioId ||
          r.colegioId.startsWith('a0000000') ||
          colegioId == 'col-1';
    }).toList();
    return List<BusRoute>.from(list);
  }

  /// Obtiene una ruta por su ID
  Future<BusRoute?> getRouteById(String id) async {
    final idx = _routes.indexWhere((r) => r.id == id);
    if (idx != -1) return _routes[idx];
    return null;
  }

  /// Crea una nueva ruta de transporte escolar
  Future<BusRoute> createRoute(BusRoute route) async {
    _routes.insert(0, route);
    return route;
  }

  /// Cambia el estado operativo de una ruta ('En Espera', 'En Tránsito', 'Completada')
  Future<BusRoute> updateRouteStatus(String routeId, String newStatus) async {
    final idx = _routes.indexWhere((r) => r.id == routeId);
    if (idx == -1) {
      throw Exception('Ruta no encontrada');
    }
    final updated = _routes[idx].copyWith(estadoRuta: newStatus);
    _routes[idx] = updated;
    return updated;
  }

  /// Actualiza el estado de abordaje de un alumno en una ruta específica
  Future<TransportPassenger> updatePassengerStatus({
    required String routeId,
    required String estudianteId,
    required String nuevoEstado,
    String? horaCheckIn,
  }) async {
    final routeIdx = _routes.indexWhere((r) => r.id == routeId);
    if (routeIdx == -1) throw Exception('Ruta no encontrada');

    final route = _routes[routeIdx];
    final passIdx = route.pasajeros.indexWhere((p) => p.estudianteId == estudianteId);
    if (passIdx == -1) throw Exception('Estudiante no encontrado en la ruta');

    final updatedPassenger = route.pasajeros[passIdx].copyWith(
      estadoAbordaje: nuevoEstado,
      horaCheckIn: horaCheckIn ?? (nuevoEstado == 'Abordó Autobús' ? '07:15 AM' : null),
    );

    final updatedPassengers = List<TransportPassenger>.from(route.pasajeros);
    updatedPassengers[passIdx] = updatedPassenger;

    _routes[routeIdx] = route.copyWith(pasajeros: updatedPassengers);
    return updatedPassenger;
  }

  /// Obtiene la ruta a la que pertenece un estudiante específico
  Future<BusRoute?> getRouteForStudent(String estudianteId) async {
    for (final route in _routes) {
      if (route.pasajeros.any((p) => p.estudianteId == estudianteId)) {
        return route;
      }
    }
    return null;
  }

  /// Asigna un estudiante a una ruta escolar
  Future<BusRoute> assignStudentToRoute({
    required String routeId,
    required TransportPassenger passenger,
  }) async {
    final routeIdx = _routes.indexWhere((r) => r.id == routeId);
    if (routeIdx == -1) throw Exception('Ruta no encontrada');

    final route = _routes[routeIdx];
    if (route.estaLlena) {
      throw Exception('La ruta ha alcanzado su capacidad máxima (${route.capacidadAsientos} asientos)');
    }

    // Si ya estaba en la ruta, se actualiza
    final updatedPassengers = List<TransportPassenger>.from(route.pasajeros);
    final existingIdx = updatedPassengers.indexWhere((p) => p.estudianteId == passenger.estudianteId);
    if (existingIdx != -1) {
      updatedPassengers[existingIdx] = passenger;
    } else {
      updatedPassengers.add(passenger);
    }

    final updatedRoute = route.copyWith(pasajeros: updatedPassengers);
    _routes[routeIdx] = updatedRoute;
    return updatedRoute;
  }

  /// Estadísticas consolidadas de transporte para KPIs institucionales
  Future<Map<String, dynamic>> getTransportStats({required String colegioId}) async {
    final routes = await getRoutes(colegioId: colegioId);
    final totalRutas = routes.length;
    final totalAsientos = routes.fold<int>(0, (sum, r) => sum + r.capacidadAsientos);
    final totalAlumnos = routes.fold<int>(0, (sum, r) => sum + r.totalPasajeros);
    final rutasEnTransito = routes.where((r) => r.enTransito).length;
    final porcentajeOcupacion =
        totalAsientos > 0 ? (totalAlumnos / totalAsientos) * 100 : 0.0;

    return {
      'totalRutas': totalRutas,
      'totalVehiculos': totalRutas,
      'totalAlumnos': totalAlumnos,
      'totalAsientos': totalAsientos,
      'asientosDisponibles': totalAsientos - totalAlumnos,
      'rutasEnTransito': rutasEnTransito,
      'porcentajeOcupacion': porcentajeOcupacion,
    };
  }
}
