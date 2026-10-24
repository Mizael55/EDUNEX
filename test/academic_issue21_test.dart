import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edunex/features/academics/models/academic_models.dart';
import 'package:edunex/features/academics/repositories/academic_repository.dart';
import 'package:edunex/features/academics/screens/admin_grades_screen.dart';
import 'package:edunex/features/families/repositories/family_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Issue #21: Gestión Académica Avanzada - Verificación de Casos 1 al 6', () {
    late AcademicRepository academicRepo;
    late FamilyRepository familyRepo;

    setUp(() {
      academicRepo = AcademicRepository(useDemoFallback: true);
      familyRepo = FamilyRepository(useDemoFallback: true);
    });

    test('Caso 1: Cursos, secciones, asignación horaria, disponibilidad docente y prevención de colisiones', () async {
      // 1. Asignación horaria inicial exitosa (Lunes 08:00 - 09:30)
      final asg1 = await academicRepo.assignTeacherToSubjectAndSection(
        colegioId: 'col-qa',
        profesorId: 'tch-001',
        materiaId: 'mat-001',
        cursoId: 'cur-001',
        seccionId: 'sec-001',
        anioEscolar: '2025-2026',
        diaSemana: 'Lunes',
        bloqueHorario: '08:00 - 09:30 AM',
        aula: 'Aula 101',
      );

      expect(asg1.diaSemana, 'Lunes');
      expect(asg1.bloqueHorario, '08:00 - 09:30 AM');
      expect(asg1.aula, 'Aula 101');

      // 2. Colisión del mismo profesor en otra sección en el mismo bloque horario
      final collision1 = academicRepo.checkScheduleCollision(
        profesorId: 'tch-001',
        seccionId: 'sec-002',
        diaSemana: 'Lunes',
        bloqueHorario: '08:00 - 09:30 AM',
        anioEscolar: '2025-2026',
      );
      expect(collision1, isNotNull);
      expect(collision1, contains('Conflicto de Horario'));

      // 3. Intento de asignación debe lanzar excepción
      expect(
        () => academicRepo.assignTeacherToSubjectAndSection(
          colegioId: 'col-qa',
          profesorId: 'tch-001',
          materiaId: 'mat-002',
          cursoId: 'cur-001',
          seccionId: 'sec-002',
          anioEscolar: '2025-2026',
          diaSemana: 'Lunes',
          bloqueHorario: '08:00 - 09:30 AM',
        ),
        throwsA(isA<Exception>()),
      );

      // 4. Colisión de la misma sección con otro profesor en el mismo horario
      final collision2 = academicRepo.checkScheduleCollision(
        profesorId: 'tch-002',
        seccionId: 'sec-001',
        diaSemana: 'Lunes',
        bloqueHorario: '08:00 - 09:30 AM',
        anioEscolar: '2025-2026',
      );
      expect(collision2, isNotNull);
      expect(collision2, contains('ya tiene asignada'));
    });

    test('Caso 2 & 3: Búsqueda de estudiantes en centro, matrícula oficial y datos de aula/capacidad', () async {
      // 1. Obtener estudiantes registrados del centro escolar
      final registered = await familyRepo.getAllRegisteredStudents(colegioId: 'col-qa');
      expect(registered, isNotEmpty);
      final sampleStudent = registered.first;
      expect(sampleStudent.nombreCompleto, isNotEmpty);
      expect(sampleStudent.matricula, isNotEmpty);

      // 2. Matricular estudiante oficial en sección
      final enrollment = await academicRepo.enrollStudent(
        colegioId: 'col-qa',
        estudianteId: sampleStudent.id,
        estudianteNombre: sampleStudent.nombreCompleto,
        matricula: sampleStudent.matricula,
        cursoId: 'cur-001',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-001',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        aula: 'Aula 101',
      );

      expect(enrollment.estudianteNombre, sampleStudent.nombreCompleto);
      expect(enrollment.matricula, sampleStudent.matricula);
      expect(enrollment.aula, 'Aula 101');
      expect(enrollment.usuarioAcceso, isNotNull);
      expect(enrollment.claveTemporal, isNotNull);
    });

    test('Caso 4: Explorador de aulas, materias con horarios y eventos/exámenes programados', () async {
      // 1. Eventos precargados para el aula sec-002
      final events = await academicRepo.getClassroomEvents(seccionId: 'sec-002');
      expect(events, isNotEmpty);
      expect(events.first.tipo, isIn(['Examen', 'Proyecto', 'Tarea', 'Reunión']));

      // 2. Programar nuevo examen/evento en aula
      final newEvent = ClassroomEvent(
        id: 'ev-test-101',
        colegioId: 'col-qa',
        cursoId: 'cur-001',
        seccionId: 'sec-001',
        titulo: 'Examen Diagnóstico de Matemáticas',
        tipo: 'Examen',
        fecha: DateTime.now().add(const Duration(days: 5)),
        profesorNombre: 'Lic. Rosaura Peña',
        materiaNombre: 'Matemáticas',
        descripcion: 'Evaluación de operaciones básicas y resolución de problemas.',
      );

      await academicRepo.addClassroomEvent(newEvent);
      final updatedEvents = await academicRepo.getClassroomEvents(seccionId: 'sec-001');
      expect(updatedEvents.any((ev) => ev.id == 'ev-test-101'), isTrue);
    });

    test('Caso 5: Gestión docente, expediente completo, buena conducta y evaluaciones de director', () async {
      // 1. Crear profesor con expediente académico completo
      final teacher = await academicRepo.createTeacher(
        colegioId: 'col-qa',
        nombreCompleto: 'Prof. Marcos Valerio',
        cedula: '001-9988776-5',
        email: 'marcos.valerio@edunex.edu.do',
        telefono: '(809) 555-4321',
        especialidad: 'Lengua Española & Literatura',
        estudios: 'Licenciatura en Educación mención Letras',
        maestria: 'Maestría en Lingüística Aplicada',
        experiencia: '10 años en bachillerato',
        referencias: 'Colegio Loyola - Dirección Académica',
        tieneCartaBuenaConducta: true,
      );

      expect(teacher.estudios, contains('Licenciatura'));
      expect(teacher.maestria, contains('Maestría'));
      expect(teacher.tieneCartaBuenaConducta, isTrue);
      expect(teacher.usuarioAcceso, isNotNull);
      expect(teacher.claveTemporal, isNotNull);
      expect(teacher.debeCambiarClave, isTrue);

      // 2. Evaluar desempeño docente por parte de la dirección
      await academicRepo.evaluateTeacher(
        teacherId: teacher.id,
        puntaje: 4.8,
        criterio: 'Pedagogía y Trato con Alumnos',
        comentario: 'Excelente manejo didáctico y motivación en el aula.',
        directorNombre: 'Lic. Rafael Santos',
      );

      final teachers = await academicRepo.getTeachers(colegioId: 'col-qa');
      final evaluatedTeacher = teachers.firstWhere((t) => t.id == teacher.id);
      expect(evaluatedTeacher.evaluacionesDirector, isNotEmpty);
      expect(evaluatedTeacher.evaluacionesDirector.first.criterio, 'Pedagogía y Trato con Alumnos');
      expect(evaluatedTeacher.calificacionDesempeno, greaterThanOrEqualTo(4.8));
    });

    test('Caso 6: Credenciales de acceso automáticas y comprobante digital', () async {
      // Docente
      final teacher = await academicRepo.createTeacher(
        colegioId: 'col-qa',
        nombreCompleto: 'Lic. Andrea Gómez',
        cedula: '402-1234567-8',
        email: 'andrea.gomez@edunex.edu.do',
        telefono: '(809) 555-7890',
        especialidad: 'Ciencias Naturales',
      );
      expect(teacher.usuarioAcceso, startsWith('prof.'));
      expect(teacher.claveTemporal, isNotNull);

      // Estudiante
      final enrollment = await academicRepo.enrollStudent(
        colegioId: 'col-qa',
        estudianteId: 'est-temp-01',
        estudianteNombre: 'Lucas David Gómez',
        matricula: 'RNE-2026-999',
        cursoId: 'cur-001',
        cursoNombre: '1ro Primaria',
        seccionId: 'sec-001',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
      );
      expect(enrollment.usuarioAcceso, 'est.rne2026999');
      expect(enrollment.claveTemporal, isNotNull);
    });

    testWidgets('UI Test: Explorador de aula y botones con estilo legible en AdminGradesScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminGradesScreen(
              colegioId: 'col-1',
              academicRepository: academicRepo,
              familyRepository: familyRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navegar a Tab 2: Panel Académico & Aulas
      final tabDashboard = find.widgetWithIcon(Tab, Icons.analytics_rounded);
      expect(tabDashboard, findsOneWidget);
      await tester.tap(tabDashboard);
      await tester.pumpAndSettle();

      // Verificar que el Explorador de Aula está visible
      expect(find.text('Explorador de Aula & Gestión de Sección en Vivo'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_classroom_event')), findsOneWidget);

      // Navegar a Tab 3: Cursos & Secciones
      final tabCursos = find.widgetWithIcon(Tab, Icons.school_rounded);
      expect(tabCursos, findsOneWidget);
      await tester.tap(tabCursos);
      await tester.pumpAndSettle();

      // Verificar botón "Nueva Sección"
      expect(find.byKey(const Key('btn_add_section_header')), findsOneWidget);
      expect(find.text('Nueva Sección'), findsOneWidget);
    });
  });
}
