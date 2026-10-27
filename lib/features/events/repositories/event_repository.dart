import 'package:flutter/foundation.dart';
import '../models/school_event.dart';
import '../models/event_registration.dart';
import '../../families/repositories/family_repository.dart';

/// Repositorio de Eventos, Actividades Extracurriculares y Excursiones en EDUNEX
class EventRepository {
  final FamilyRepository? _familyRepository;
  final bool useDemoFallback;
  final List<SchoolEvent> _events;
  final List<EventRegistration> _registrations;

  EventRepository({
    FamilyRepository? familyRepository,
    this.useDemoFallback = false,
  })  : _familyRepository = familyRepository,
        _events = useDemoFallback ? List<SchoolEvent>.from(_defaultEvents) : [],
        _registrations = useDemoFallback ? List<EventRegistration>.from(_defaultRegistrations) : [];

  void clearAllData() {
    _events.clear();
    _registrations.clear();
  }

  static final List<SchoolEvent> _defaultEvents = [
    SchoolEvent(
      id: 'evt-001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      titulo: 'Gran Excursión al Jardín Botánico Nacional',
      descripcion: 'Safari ecológico guiado, taller de botánica tropical, merienda incluida y transporte escolar ida y vuelta.',
      tipo: 'Excursión',
      fechaEvento: DateTime(2026, 3, 20, 8, 30),
      fechaLimiteInscripcion: DateTime(2026, 3, 15, 18, 0),
      lugar: 'Jardín Botánico Nacional Dr. Rafael M. Moscoso, Santo Domingo',
      precio: 1200.0,
      cupoMaximo: 45,
      cuposOcupados: 28,
      estado: 'Abierto',
      estudiantesInscritos: const ['Lucas Fernández', 'Camila Castillo'],
    ),
    SchoolEvent(
      id: 'evt-002',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      titulo: 'Taller de Robótica & Ciencias STEAM',
      descripcion: 'Construcción y programación de robots con Lego Education y circuitos electrónicos para primaria.',
      tipo: 'Taller STEAM',
      fechaEvento: DateTime(2026, 3, 28, 14, 0),
      fechaLimiteInscripcion: DateTime(2026, 3, 25, 12, 0),
      lugar: 'Laboratorio de Innovación EDUNEX (Pabellón B)',
      precio: 850.0,
      cupoMaximo: 30,
      cuposOcupados: 18,
      estado: 'Abierto',
      estudiantesInscritos: const ['Sofía Pérez', 'Alejandro Morales'],
    ),
    SchoolEvent(
      id: 'evt-003',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      titulo: 'Feria de la Dominicanidad & Folklore Familiar',
      descripcion: 'Acto cultural con bailes típicos, gastronomía criolla y presentaciones artísticas de los estudiantes.',
      tipo: 'Acto Institucional',
      fechaEvento: DateTime(2026, 4, 12, 9, 0),
      fechaLimiteInscripcion: DateTime(2026, 4, 8, 18, 0),
      lugar: 'Auditorio Central del Colegio',
      precio: 0.0,
      cupoMaximo: 150,
      cuposOcupados: 94,
      estado: 'Abierto',
      estudiantesInscritos: const ['Mateo Pérez', 'Sofía Pérez', 'Camila Castillo'],
    ),
    SchoolEvent(
      id: 'evt-004',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      titulo: 'Torneo Deportivo Interescolar de Primavera',
      descripcion: 'Competencias de fútbol sala, voleibol y atletismo con entrega de medallas y diplomas.',
      tipo: 'Torneo Deportivo',
      fechaEvento: DateTime(2026, 4, 25, 8, 0),
      fechaLimiteInscripcion: DateTime(2026, 4, 20, 18, 0),
      lugar: 'Canchas Polideportivas del Colegio',
      precio: 600.0,
      cupoMaximo: 60,
      cuposOcupados: 60,
      estado: 'Cupo Lleno',
      estudiantesInscritos: const ['Mateo Pérez'],
    ),
  ];

  static final List<EventRegistration> _defaultRegistrations = [
    EventRegistration(
      id: 'reg-001',
      eventoId: 'evt-002',
      eventoTitulo: 'Taller de Robótica & Ciencias STEAM',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      estudianteId: 'f0000000-0000-0000-0000-000000000002',
      estudianteNombre: 'Sofía Pérez González',
      fechaInscripcion: DateTime(2026, 2, 8, 10, 15),
      montoPagado: 850.0,
      metodoPago: 'Tarjeta de Crédito / CardNET',
      estadoPago: 'Pagado',
    ),
    EventRegistration(
      id: 'reg-002',
      eventoId: 'evt-003',
      eventoTitulo: 'Feria de la Dominicanidad & Folklore Familiar',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      estudianteId: 'f0000000-0000-0000-0000-000000000002',
      estudianteNombre: 'Sofía Pérez González',
      fechaInscripcion: DateTime(2026, 2, 9, 11, 30),
      montoPagado: 0.0,
      metodoPago: 'Gratuito',
      estadoPago: 'Gratuito',
    ),
  ];

  /// Obtiene los eventos escolares activos
  Future<List<SchoolEvent>> getEvents({String? colegioId}) async {
    if (colegioId != null) {
      return _events.where((e) => e.colegioId == colegioId || e.colegioId.startsWith('a0000000')).toList();
    }
    return List<SchoolEvent>.from(_events);
  }

  /// Retorna un evento por su ID
  Future<SchoolEvent?> getEventById(String id) async {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Crea un nuevo evento escolar desde el panel administrativo
  Future<SchoolEvent> createEvent({
    required String colegioId,
    required String titulo,
    required String descripcion,
    required String tipo,
    required DateTime fechaEvento,
    required DateTime fechaLimiteInscripcion,
    required String lugar,
    required double precio,
    required int cupoMaximo,
  }) async {
    final newEvent = SchoolEvent(
      id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      titulo: titulo,
      descripcion: descripcion,
      tipo: tipo,
      fechaEvento: fechaEvento,
      fechaLimiteInscripcion: fechaLimiteInscripcion,
      lugar: lugar,
      precio: precio,
      cupoMaximo: cupoMaximo,
      cuposOcupados: 0,
      estado: 'Abierto',
      estudiantesInscritos: const [],
    );

    _events.insert(0, newEvent);
    return newEvent;
  }

  /// Inscribe un estudiante en un evento escolar con cupo y pago integrado
  Future<EventRegistration> registerStudentToEvent({
    required String eventoId,
    required String familiaId,
    required String estudianteId,
    required String estudianteNombre,
    required String metodoPago,
  }) async {
    final eventIndex = _events.indexWhere((e) => e.id == eventoId);
    if (eventIndex == -1) {
      throw Exception('Evento no encontrado');
    }

    final event = _events[eventIndex];
    if (!event.tieneCupoDisponible) {
      throw Exception('El evento ya no tiene cupos disponibles.');
    }

    if (event.estudiantesInscritos.contains(estudianteNombre)) {
      throw Exception('El estudiante ya está inscrito en este evento.');
    }

    final newCupos = event.cuposOcupados + 1;
    final updatedEvent = event.copyWith(
      cuposOcupados: newCupos,
      estado: newCupos >= event.cupoMaximo ? 'Cupo Lleno' : 'Abierto',
      estudiantesInscritos: [...event.estudiantesInscritos, estudianteNombre],
    );
    _events[eventIndex] = updatedEvent;

    // Si tiene costo, registrar pago en la cuenta familiar si se dispone de repositorio
    if (!event.esGratuito && _familyRepository != null) {
      await _familyRepository!.recordPayment(
        familiaId: familiaId,
        monto: event.precio,
        concepto: 'Inscripción Evento: ${event.titulo} ($estudianteNombre)',
        metodo: metodoPago,
      );
    }

    final registration = EventRegistration(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      eventoId: eventoId,
      eventoTitulo: event.titulo,
      familiaId: familiaId,
      estudianteId: estudianteId,
      estudianteNombre: estudianteNombre,
      fechaInscripcion: DateTime.now(),
      montoPagado: event.precio,
      metodoPago: event.esGratuito ? 'Gratuito' : metodoPago,
      estadoPago: event.esGratuito ? 'Gratuito' : 'Pagado',
    );

    _registrations.insert(0, registration);
    return registration;
  }

  /// Retorna las inscripciones realizadas por una familia
  Future<List<EventRegistration>> getRegistrationsForFamily(String familiaId) async {
    return _registrations.where((r) => r.familiaId == familiaId).toList();
  }

  /// Retorna las inscripciones para un evento específico
  Future<List<EventRegistration>> getRegistrationsForEvent(String eventoId) async {
    return _registrations.where((r) => r.eventoId == eventoId).toList();
  }
}
