import 'package:flutter/foundation.dart';
import '../models/attendance_record.dart';
import '../../families/repositories/family_repository.dart';
import '../../families/models/student.dart';

/// Repositorio para la Gestión de Asistencia Escolar Diaria y Seguimiento Familiar
class AttendanceRepository {
  final FamilyRepository? _familyRepository;
  final List<AttendanceRecord> _records;

  AttendanceRepository({
    FamilyRepository? familyRepository,
  })  : _familyRepository = familyRepository,
        _records = List<AttendanceRecord>.from(_defaultRecords);

  static final List<AttendanceRecord> _defaultRecords = [
    // Registros para Mateo Pérez (1ro de Primaria - Sección A)
    AttendanceRecord(
      id: 'att-001',
      estudianteId: 'f0000000-0000-0000-0000-000000000001',
      estudianteNombre: 'Mateo Pérez González',
      matricula: 'EST-2026-01',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: '1ro de Primaria',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 16),
      estado: 'Presente',
      horaLlegada: '07:48 AM',
      observacion: 'Uniforme completo y puntual',
      notificadoATutor: true,
    ),
    AttendanceRecord(
      id: 'att-002',
      estudianteId: 'f0000000-0000-0000-0000-000000000001',
      estudianteNombre: 'Mateo Pérez González',
      matricula: 'EST-2026-01',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: '1ro de Primaria',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 17),
      estado: 'Tardanza',
      horaLlegada: '08:22 AM',
      observacion: 'Demora reportada por congestión en ruta familiar',
      notificadoATutor: true,
    ),
    AttendanceRecord(
      id: 'att-003',
      estudianteId: 'f0000000-0000-0000-0000-000000000001',
      estudianteNombre: 'Mateo Pérez González',
      matricula: 'EST-2026-01',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: '1ro de Primaria',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 18),
      estado: 'Ausente',
      horaLlegada: null,
      observacion: 'Inasistencia sin notificación matutina',
      notificadoATutor: true,
    ),
    AttendanceRecord(
      id: 'att-004',
      estudianteId: 'f0000000-0000-0000-0000-000000000001',
      estudianteNombre: 'Mateo Pérez González',
      matricula: 'EST-2026-01',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: '1ro de Primaria',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 19),
      estado: 'Presente',
      horaLlegada: '07:50 AM',
      observacion: 'Presente en salón de clases',
      notificadoATutor: true,
    ),
    // Registros para Sofía Pérez (Kinder - Sección A)
    AttendanceRecord(
      id: 'att-005',
      estudianteId: 'f0000000-0000-0000-0000-000000000002',
      estudianteNombre: 'Sofía Pérez González',
      matricula: 'EST-2026-02',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: 'Kinder',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 16),
      estado: 'Presente',
      horaLlegada: '07:55 AM',
      observacion: 'Excelente ánimo matutino',
      notificadoATutor: true,
    ),
    AttendanceRecord(
      id: 'att-006',
      estudianteId: 'f0000000-0000-0000-0000-000000000002',
      estudianteNombre: 'Sofía Pérez González',
      matricula: 'EST-2026-02',
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: 'Kinder',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 17),
      estado: 'Justificado',
      horaLlegada: null,
      observacion: 'Cita con pediatra programada',
      justificacionTutor: 'Cita médica pediátrica de control anual',
      notificadoATutor: true,
    ),
    // Registros para Lucas Fernández (1ro de Primaria - Sección A)
    AttendanceRecord(
      id: 'att-007',
      estudianteId: 'f0000000-0000-0000-0000-000000000003',
      estudianteNombre: 'Lucas Fernández',
      matricula: 'EST-2026-03',
      familiaId: 'e0000000-0000-0000-0000-000000000002',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: '1ro de Primaria',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 18),
      estado: 'Presente',
      horaLlegada: '07:40 AM',
      observacion: null,
      notificadoATutor: true,
    ),
    // Registros para Camila Castillo (1ro de Primaria - Sección A)
    AttendanceRecord(
      id: 'att-008',
      estudianteId: 'f0000000-0000-0000-0000-000000000004',
      estudianteNombre: 'Camila Castillo',
      matricula: 'EST-2026-04',
      familiaId: 'e0000000-0000-0000-0000-000000000003',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: '1ro de Primaria',
      seccionNombre: 'Sección A',
      fecha: DateTime(2026, 3, 18),
      estado: 'Presente',
      horaLlegada: '07:45 AM',
      observacion: null,
      notificadoATutor: true,
    ),
  ];

  /// Obtiene los registros de asistencia para una fecha y sección específica.
  /// Si no existen registros aún para esa fecha, genera borradores a partir del roster de estudiantes.
  Future<List<AttendanceRecord>> getAttendanceForDateAndSection({
    required DateTime fecha,
    required String colegioId,
    String gradoNombre = '1ro de Primaria',
    String seccionNombre = 'Sección A',
  }) async {
    final targetDate = DateTime(fecha.year, fecha.month, fecha.day);

    final existing = _records.where((r) {
      final rDate = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
      final matchSchool = r.colegioId == colegioId || r.colegioId.startsWith('a0000000');
      return rDate == targetDate &&
          r.gradoNombre.toLowerCase() == gradoNombre.toLowerCase() &&
          r.seccionNombre.toLowerCase() == seccionNombre.toLowerCase() &&
          matchSchool;
    }).toList();

    if (existing.isNotEmpty) {
      return List<AttendanceRecord>.from(existing);
    }

    // Si no hay registros aún para esta fecha, creamos una lista base con los estudiantes matriculados
    final students = await _getStudentsForSection(colegioId, gradoNombre, seccionNombre);
    final drafts = students.map((s) {
      return AttendanceRecord(
        id: 'draft-${s.id}-${targetDate.millisecondsSinceEpoch}',
        estudianteId: s.id,
        estudianteNombre: s.nombreCompleto,
        matricula: s.matricula,
        familiaId: s.familiaId,
        colegioId: colegioId,
        gradoNombre: gradoNombre,
        seccionNombre: seccionNombre,
        fecha: targetDate,
        estado: 'Presente',
        horaLlegada: '07:45 AM',
        notificadoATutor: false,
      );
    }).toList();

    return drafts;
  }

  /// Guarda o actualiza los registros de asistencia y dispara la notificación a los tutores
  Future<void> saveAttendanceRecords(List<AttendanceRecord> records) async {
    for (final record in records) {
      final idx = _records.indexWhere((r) =>
          r.id == record.id ||
          (r.estudianteId == record.estudianteId &&
              r.fecha.year == record.fecha.year &&
              r.fecha.month == record.fecha.month &&
              r.fecha.day == record.fecha.day));

      final confirmedRecord = record.copyWith(notificadoATutor: true);

      if (idx != -1) {
        _records[idx] = confirmedRecord;
      } else {
        _records.insert(0, confirmedRecord);
      }
    }
  }

  /// Retorna el historial de asistencia completo de un estudiante
  Future<List<AttendanceRecord>> getAttendanceForStudent(String estudianteId) async {
    final list = _records.where((r) => r.estudianteId == estudianteId).toList();
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  /// Retorna el historial de asistencia de todos los estudiantes de una familia
  Future<List<AttendanceRecord>> getAttendanceForFamily(String familiaId) async {
    final list = _records.where((r) => r.familiaId == familiaId).toList();
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  /// Permite a un tutor justificar una inasistencia o tardanza
  Future<AttendanceRecord> submitJustification({
    required String recordId,
    required String motivo,
    String? comentario,
  }) async {
    final idx = _records.indexWhere((r) => r.id == recordId);
    if (idx == -1) {
      throw Exception('Registro de asistencia no encontrado');
    }

    final old = _records[idx];
    final justificationText = comentario != null && comentario.trim().isNotEmpty
        ? '$motivo: ${comentario.trim()}'
        : motivo;

    final updated = old.copyWith(
      estado: 'Justificado',
      justificacionTutor: justificationText,
    );

    _records[idx] = updated;
    return updated;
  }

  /// Estadísticas consolidadas de asistencia escolar
  Future<Map<String, dynamic>> getAttendanceStats({
    required String colegioId,
    DateTime? fecha,
  }) async {
    final target = fecha != null ? DateTime(fecha.year, fecha.month, fecha.day) : null;

    final filtered = _records.where((r) {
      final matchSchool = r.colegioId == colegioId || r.colegioId.startsWith('a0000000');
      if (!matchSchool) return false;
      if (target != null) {
        final rDate = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
        return rDate == target;
      }
      return true;
    }).toList();

    final presentes = filtered.where((r) => r.esPresente).length;
    final tardanzas = filtered.where((r) => r.esTardanza).length;
    final ausentes = filtered.where((r) => r.esAusente).length;
    final justificados = filtered.where((r) => r.esJustificado).length;
    final total = filtered.length;

    final porcentaje = total > 0 ? ((presentes + justificados) / total) * 100 : 100.0;

    return {
      'totalRegistros': total,
      'presentes': presentes,
      'tardanzas': tardanzas,
      'ausentes': ausentes,
      'justificados': justificados,
      'porcentajeAsistencia': porcentaje,
    };
  }

  /// Asistente privado para resolver la lista de estudiantes por sección
  Future<List<Student>> _getStudentsForSection(
    String colegioId,
    String gradoNombre,
    String seccionNombre,
  ) async {
    if (_familyRepository != null) {
      final families = await _familyRepository!.getFamilies();
      final allStudents = <Student>[];
      for (final f in families) {
        allStudents.addAll(f.estudiantes);
      }
      final filtered = allStudents.where((s) =>
          (s.gradoNombre?.toLowerCase() == gradoNombre.toLowerCase() || s.gradoNombre == null) &&
          (s.seccionNombre?.toLowerCase() == seccionNombre.toLowerCase() || s.seccionNombre == null)).toList();
      if (filtered.isNotEmpty) return filtered;
    }

    // Default roster si no hay estudiantes disponibles
    return [
      Student(
        id: 'f0000000-0000-0000-0000-000000000001',
        colegioId: colegioId,
        familiaId: 'e0000000-0000-0000-0000-000000000001',
        matricula: 'EST-2026-01',
        nombres: 'Mateo',
        apellidos: 'Pérez González',
        fechaNacimiento: DateTime(2019, 5, 14),
        gradoNombre: gradoNombre,
        seccionNombre: seccionNombre,
      ),
      Student(
        id: 'f0000000-0000-0000-0000-000000000002',
        colegioId: colegioId,
        familiaId: 'e0000000-0000-0000-0000-000000000001',
        matricula: 'EST-2026-02',
        nombres: 'Sofía',
        apellidos: 'Pérez González',
        fechaNacimiento: DateTime(2021, 8, 20),
        gradoNombre: gradoNombre,
        seccionNombre: seccionNombre,
      ),
    ];
  }
}
