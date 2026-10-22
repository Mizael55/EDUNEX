import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edunex/features/academics/models/academic_models.dart';
import 'package:edunex/features/academics/repositories/academic_repository.dart';
import 'package:edunex/features/academics/screens/admin_grades_screen.dart';

void main() {
  group('Issue #20: Gestión Académica, Cursos, Secciones, Estudiantes y Profesores', () {
    late AcademicRepository repository;

    setUp(() {
      repository = AcademicRepository(useDemoFallback: true);
    });

    test('1. Gestión de cursos y secciones: creación, cupos y múltiples secciones por curso', () async {
      // Crear curso
      final course = await repository.createCourse(
        colegioId: 'col-qa',
        nombre: '4to de Primaria',
        nivel: 'Primaria',
        anioEscolar: '2025-2026',
      );
      expect(course.id, startsWith('cur-'));
      expect(course.nombre, '4to de Primaria');

      // Crear sección A
      final secA = await repository.createSection(
        colegioId: 'col-qa',
        cursoId: course.id,
        cursoNombre: course.nombre,
        nombre: 'Sección A',
        anioEscolar: '2025-2026',
        capacidadEstudiantes: 28,
        aula: 'Aula 401',
        profesorTitularNombre: 'Lic. Rosaura Peña',
      );
      expect(secA.capacidadEstudiantes, 28);
      expect(secA.aula, 'Aula 401');

      // Crear sección B (múltiples secciones por curso)
      final secB = await repository.createSection(
        colegioId: 'col-qa',
        cursoId: course.id,
        cursoNombre: course.nombre,
        nombre: 'Sección B',
        anioEscolar: '2025-2026',
        capacidadEstudiantes: 30,
        aula: 'Aula 402',
      );
      expect(secB.nombre, 'Sección B');

      final secciones = await repository.getSections(colegioId: 'col-qa', cursoId: course.id);
      expect(secciones.length, 2);
      expect(secciones.any((s) => s.nombre == 'Sección A'), isTrue);
      expect(secciones.any((s) => s.nombre == 'Sección B'), isTrue);
    });

    test('2. Gestión de profesores: crear perfil docente y materias de especialidad', () async {
      final teacher = await repository.createTeacher(
        colegioId: 'col-qa',
        nombreCompleto: 'Prof. Carlos Santana',
        cedula: '001-5544332-1',
        email: 'carlos.santana@edunex.edu.do',
        telefono: '(809) 555-8899',
        especialidad: 'Física y Química Avanzada',
        materiasQuePuedeImpartir: ['Física', 'Química'],
      );

      expect(teacher.nombreCompleto, 'Prof. Carlos Santana');
      expect(teacher.estado, 'Activo');

      final teachers = await repository.getTeachers(colegioId: 'col-qa');
      expect(teachers.any((t) => t.id == teacher.id), isTrue);
    });

    test('3. Gestión de materias curriculares: registro y asociación a cursos', () async {
      final subject = await repository.createSubject(
        colegioId: 'col-qa',
        nombre: 'Robótica Educativa',
        codigo: 'ROB-101',
        horasSemanales: 3,
        descripcion: 'Programación visual y diseño de prototipos robóticos.',
      );

      expect(subject.nombre, 'Robótica Educativa');
      expect(subject.codigo, 'ROB-101');
      expect(subject.horasSemanales, 3);

      final subjects = await repository.getSubjects(colegioId: 'col-qa');
      expect(subjects.any((m) => m.id == subject.id), isTrue);
    });

    test('4. Asignación académica de profesores: mapeo flexible y prevención de duplicados', () async {
      final asg = await repository.assignTeacherToSubjectAndSection(
        colegioId: 'col-qa',
        profesorId: 'tch-001',
        materiaId: 'mat-001',
        cursoId: 'cur-002',
        seccionId: 'sec-002',
        anioEscolar: '2025-2026',
        horarioSemanal: 'Lunes 8:00 AM',
      );
      expect(asg.id, startsWith('asg-'));

      // Intentar duplicar la misma asignación debe lanzar excepción
      expect(
        () => repository.assignTeacherToSubjectAndSection(
          colegioId: 'col-qa',
          profesorId: 'tch-001',
          materiaId: 'mat-001',
          cursoId: 'cur-002',
          seccionId: 'sec-002',
          anioEscolar: '2025-2026',
        ),
        throwsA(isA<Exception>()),
      );

      // Un profesor puede impartir otra materia o en otra sección
      final asg2 = await repository.assignTeacherToSubjectAndSection(
        colegioId: 'col-qa',
        profesorId: 'tch-001',
        materiaId: 'mat-001',
        cursoId: 'cur-002',
        seccionId: 'sec-003', // Sección B
        anioEscolar: '2025-2026',
      );
      expect(asg2.seccionId, 'sec-003');

      // Seguridad docente: verificar acceso
      expect(
        repository.canTeacherAccessAssignment(teacherId: 'tch-001', seccionId: 'sec-002', materiaId: 'mat-001'),
        isTrue,
      );
      expect(
        repository.canTeacherAccessAssignment(teacherId: 'tch-001', seccionId: 'sec-005', materiaId: 'mat-001'),
        isFalse,
      );
    });

    test('5. Asignación y traslado de estudiantes con registro en el historial', () async {
      // Matricular
      final enrollment = await repository.enrollStudent(
        colegioId: 'col-qa',
        estudianteId: 'est-qa-1',
        estudianteNombre: 'Camila Morales',
        matricula: 'EST-2026-99',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
      );
      expect(enrollment.seccionNombre, 'Sección A');
      expect(enrollment.historialTraslados, isEmpty);

      // Trasladar a Sección B
      final transferred = await repository.transferStudentSection(
        enrollmentId: enrollment.id,
        nuevaSeccionId: 'sec-003',
        nuevaSeccionNombre: 'Sección B',
        motivo: 'Ajuste de cupo y horario vespertino solicitado por los padres',
        usuarioResponsable: 'Director Académico',
      );

      expect(transferred.seccionId, 'sec-003');
      expect(transferred.seccionNombre, 'Sección B');
      expect(transferred.historialTraslados.length, 1);
      expect(transferred.historialTraslados.first.seccionAnterior, 'Sección A');
      expect(transferred.historialTraslados.first.seccionNueva, 'Sección B');
      expect(transferred.historialTraslados.first.motivo, contains('Ajuste de cupo'));
    });

    test('6. Panel de control académico: KPIs, promedio por aula y capacidad', () {
      final metrics = repository.getAcademicDashboardMetrics(colegioId: 'col-1');
      expect(metrics.totalCursos, greaterThan(0));
      expect(metrics.totalSecciones, greaterThan(0));
      expect(metrics.totalEstudiantesMatriculados, greaterThan(0));
      expect(metrics.totalProfesores, greaterThan(0));
      expect(metrics.totalMaterias, greaterThan(0));
      expect(metrics.promedioEstudiantesPorAula, greaterThan(0.0));
    });

    testWidgets('7. AdminGradesScreen UI: navega por las 6 pestañas y realiza acciones académicas', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminGradesScreen(
              academicRepository: repository,
              colegioId: 'col-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar 6 pestañas
      expect(find.text('1. Boletines & Calificaciones'), findsOneWidget);
      expect(find.text('2. Panel Académico & Aulas'), findsOneWidget);
      expect(find.textContaining('3. Cursos & Secciones'), findsOneWidget);
      expect(find.textContaining('4. Estudiantes & Matrícula'), findsOneWidget);
      expect(find.textContaining('5. Profesores & Asignaciones'), findsOneWidget);
      expect(find.textContaining('6. Materias Curriculares'), findsOneWidget);

      // Ir a Tab 2: Panel Académico
      await tester.tap(find.text('2. Panel Académico & Aulas'));
      await tester.pumpAndSettle();
      expect(find.text('Cursos Habilitados'), findsOneWidget);
      expect(find.text('Matrícula Activa'), findsOneWidget);
      expect(find.textContaining('Distribución de Estudiantes por Curso'), findsOneWidget);

      // Ir a Tab 3: Cursos & Secciones
      await tester.tap(find.textContaining('3. Cursos & Secciones'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo de Cursos & Secciones Activas'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_section_header')), findsOneWidget);

      // Ir a Tab 4: Estudiantes & Matrícula
      await tester.tap(find.textContaining('4. Estudiantes & Matrícula'));
      await tester.pumpAndSettle();
      expect(find.text('Listado de Estudiantes Matriculados & Secciones'), findsOneWidget);
      expect(find.text('Mateo Pérez González'), findsOneWidget);
      expect(find.byKey(const Key('btn_enroll_student_header')), findsOneWidget);

      // Abrir modal de traslado para el primer estudiante
      final transferButtons = find.byTooltip('Ver Historial de Traslados');
      expect(transferButtons, findsWidgets);

      // Ir a Tab 5: Profesores & Asignaciones
      await tester.tap(find.textContaining('5. Profesores & Asignaciones'));
      await tester.pumpAndSettle();
      expect(find.text('Cuerpo Docente & Asignaciones Académicas'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_teacher')), findsOneWidget);
      expect(find.byKey(const Key('btn_add_academic_assignment')), findsOneWidget);
      expect(find.text('Lic. Rosaura Peña'), findsOneWidget);

      // Ir a Tab 6: Materias Curriculares
      await tester.tap(find.textContaining('6. Materias Curriculares'));
      await tester.pumpAndSettle();
      expect(find.text('Malla Curricular & Catálogo de Materias'), findsOneWidget);
      expect(find.text('Matemáticas'), findsWidgets);
      expect(find.text('Lengua Española'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_subject')), findsOneWidget);
    });
  });
}
