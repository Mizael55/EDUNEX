import 'package:flutter/foundation.dart';
import '../models/circular.dart';
import '../../families/repositories/family_repository.dart';

/// Repositorio para la Gestión de Circulares Oficiales, Avisos y Autorizaciones Digitales
class CircularRepository {
  final FamilyRepository? _familyRepository;
  final bool useDemoFallback;
  final List<CircularItem> _circulars;

  CircularRepository({
    FamilyRepository? familyRepository,
    this.useDemoFallback = false,
  })  : _familyRepository = familyRepository,
        _circulars = useDemoFallback ? List<CircularItem>.from(_defaultCirculars) : [];

  void clearAllData() {
    _circulars.clear();
  }

  static final List<CircularItem> _defaultCirculars = [
    CircularItem(
      id: 'circ-001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      titulo: 'Circular No. 05: Salida Pedagógica al Acuario Nacional y Taller de Vida Marina',
      contenido:
          'Estimados tutores: En el marco de nuestra unidad de Ciencias de la Naturaleza, los alumnos de 1ro de Primaria realizarán una visita guiada al Acuario Nacional. La actividad incluye transporte escolar privado supervisado, refrigerio balanceado y guías pedagógicos especializados. Es obligatorio contar con la autorización firmada por el tutor legal para garantizar la participación del estudiante.',
      categoria: 'Autorización Requerida',
      fechaPublicacion: DateTime(2026, 3, 10),
      fechaLimite: DateTime(2026, 3, 28),
      segmentacion: '1ro de Primaria',
      requiereFirma: true,
      remitenteCargo: 'Coordinación de Ciencias & Nivel Primario',
      leidoPorTutores: ['tutor-1'],
      firmas: [],
    ),
    CircularItem(
      id: 'circ-002',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      titulo: 'Circular No. 04: Cronograma de Evaluaciones Bimestrales y Asueto Patrio',
      contenido:
          'Estimada Comunidad Educativa: Les compartimos el calendario oficial correspondiente a las evaluaciones del segundo bimestre para todos los grados académicos. Asimismo, les recordamos que con motivo a la conmemoración de la Independencia Nacional, no habrá docencia presencial los días feriados correspondientes. Les invitamos a revisar los temas de estudio en los cuadernos de trabajo.',
      categoria: 'Feriado / Calendario',
      fechaPublicacion: DateTime(2026, 2, 20),
      fechaLimite: null,
      segmentacion: 'Todo el Colegio',
      requiereFirma: false,
      remitenteCargo: 'Dirección Académica Central',
      leidoPorTutores: ['tutor-1', 'familia@edunex.edu', 'tutor-3'],
      firmas: [],
    ),
    CircularItem(
      id: 'circ-003',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      titulo: 'Circular No. 03: Protocolo Oficial de Seguridad y Retiro de Alumnos en Puerta',
      contenido:
          'Apreciadas familias: Con el propósito de reforzar la integridad física y protección de nuestros alumnos a la hora de salida, recordamos que es indispensable presentar el carnet digital de tutor o estar formalmente autorizado en la ficha escolar de EDUNEX. Ningún alumno será despachado a personas no autorizadas sin consentimiento previo por escrito.',
      categoria: 'Institucional',
      fechaPublicacion: DateTime(2026, 2, 1),
      fechaLimite: DateTime(2026, 3, 30),
      segmentacion: 'Todo el Colegio',
      requiereFirma: true,
      remitenteCargo: 'Dirección General & Departamento de Seguridad',
      leidoPorTutores: ['tutor-3'],
      firmas: [
        CircularSignature(
          id: 'sig-001',
          tutorId: 'tutor-3',
          tutorNombre: 'Laura Méndez',
          tutorCedula: '001-3456789-0',
          estudianteId: 'f0000000-0000-0000-0000-000000000003',
          estudianteNombre: 'Diego Ramírez Méndez',
          fechaFirma: DateTime(2026, 2, 5, 10, 30),
          autorizado: true,
          comentario: 'Consentimiento otorgado para el nuevo protocolo de salida.',
        ),
      ],
    ),
  ];

  /// Obtiene la lista completa de circulares oficiales del centro educativo
  Future<List<CircularItem>> getCirculars({required String colegioId}) async {
    final list = _circulars.where((c) {
      return c.colegioId == colegioId ||
          c.colegioId.startsWith('a0000000') ||
          colegioId == 'col-1';
    }).toList();
    list.sort((a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion));
    return List<CircularItem>.from(list);
  }

  /// Obtiene las circulares aplicables a los hijos de un tutor específico
  Future<List<CircularItem>> getCircularsForParent({
    required String colegioId,
    String? tutorEmail,
    List<String>? gradosHijos,
  }) async {
    final all = await getCirculars(colegioId: colegioId);

    if (gradosHijos == null || gradosHijos.isEmpty) {
      return all;
    }

    final filtered = all.where((c) {
      if (c.segmentacion.toLowerCase() == 'todo el colegio') return true;
      return gradosHijos.any((g) =>
          c.segmentacion.toLowerCase().contains(g.toLowerCase()) ||
          g.toLowerCase().contains(c.segmentacion.toLowerCase()));
    }).toList();

    return filtered;
  }

  /// Crea una nueva circular oficial
  Future<CircularItem> createCircular(CircularItem circular) async {
    _circulars.insert(0, circular);
    return circular;
  }

  /// Registra la firma y consentimiento formal de un tutor
  Future<CircularSignature> signCircular({
    required String circularId,
    required CircularSignature signature,
  }) async {
    final idx = _circulars.indexWhere((c) => c.id == circularId);
    if (idx == -1) throw Exception('Circular no encontrada');

    final circ = _circulars[idx];
    final updatedSignatures = List<CircularSignature>.from(circ.firmas);

    // Evitar firmas duplicadas para el mismo estudiante
    final existingIdx = updatedSignatures.indexWhere((s) => s.estudianteId == signature.estudianteId);
    if (existingIdx != -1) {
      updatedSignatures[existingIdx] = signature;
    } else {
      updatedSignatures.add(signature);
    }

    final updatedReaders = List<String>.from(circ.leidoPorTutores);
    if (!updatedReaders.contains(signature.tutorId)) {
      updatedReaders.add(signature.tutorId);
    }

    _circulars[idx] = circ.copyWith(
      firmas: updatedSignatures,
      leidoPorTutores: updatedReaders,
    );

    return signature;
  }

  /// Marca una circular como leída por el tutor
  Future<void> markAsRead({
    required String circularId,
    required String tutorIdentifier,
  }) async {
    final idx = _circulars.indexWhere((c) => c.id == circularId);
    if (idx != -1) {
      final circ = _circulars[idx];
      if (!circ.leidoPorTutores.contains(tutorIdentifier)) {
        final updated = List<String>.from(circ.leidoPorTutores)..add(tutorIdentifier);
        _circulars[idx] = circ.copyWith(leidoPorTutores: updated);
      }
    }
  }

  /// Estadísticas consolidadas para panel directivo
  Future<Map<String, dynamic>> getCircularStats({required String colegioId}) async {
    final list = await getCirculars(colegioId: colegioId);
    final totalPublicadas = list.length;
    final requierenFirma = list.where((c) => c.requiereFirma).length;
    final totalFirmasRecibidas = list.fold<int>(0, (sum, c) => sum + c.totalFirmas);
    final totalLecturas = list.fold<int>(0, (sum, c) => sum + c.totalLecturas);

    return {
      'totalPublicadas': totalPublicadas,
      'requierenFirma': requierenFirma,
      'totalFirmasRecibidas': totalFirmasRecibidas,
      'totalLecturas': totalLecturas,
    };
  }
}
