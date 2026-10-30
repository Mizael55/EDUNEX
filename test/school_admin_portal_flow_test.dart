import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edunex/screens/main_shell.dart';
import 'package:edunex/features/superadmin/models/school.dart';
import 'package:edunex/features/superadmin/repositories/school_repository.dart';
import 'package:edunex/features/families/repositories/family_repository.dart';
import 'package:edunex/features/families/screens/create_family_dialog.dart';
import 'package:edunex/features/circulars/repositories/circular_repository.dart';
import 'package:edunex/features/events/repositories/event_repository.dart';
import 'package:edunex/features/transport/repositories/transport_repository.dart';
import 'package:edunex/features/store/repositories/store_repository.dart';
import 'package:edunex/features/guidance/repositories/guidance_repository.dart';
import 'package:edunex/features/attendance/repositories/attendance_repository.dart';
import 'package:edunex/features/academics/repositories/academic_repository.dart';
import 'package:edunex/features/auth/models/user_profile.dart';
import 'package:edunex/features/auth/models/user_role.dart';

void main() {
  setUp(() {
    GuidanceRepository.clearAllData();
  });

  group('School Administrator Portal Flow - Zero Mock Leaks & Full Functionality', () {
    testWidgets('Newly created school logs in, sees isolated clean state and operates all modules', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Create a brand new client school with director
      final schoolRepo = SchoolRepository(useDemoFallback: false);
      final schoolCreation = await schoolRepo.createSchoolWithDirector(
        nombre: 'Colegio Experimental del Caribe',
        rnc: '131998877',
        telefono: '809-555-9000',
        emailContacto: 'contacto@caribe.edu.do',
        direccion: 'Av. Winston Churchill #105, Santo Domingo',
        directorNombres: 'Carmen',
        directorApellidos: 'Santana',
        directorEmail: 'directora@caribe.edu.do',
        directorPassword: 'password123',
        directorCedula: '001-9876543-2',
        estadoSuscripcion: 'active',
        maxEstudiantes: 300,
      );
      final newSchool = schoolCreation['school'] as School;
      final newSchoolId = newSchool.id;

      // Repositories in non-demo clean mode for this school
      final familyRepo = FamilyRepository(useDemoFallback: false);
      final attendanceRepo = AttendanceRepository(familyRepository: familyRepo, useDemoFallback: false);
      final circularRepo = CircularRepository(familyRepository: familyRepo, useDemoFallback: false);
      final eventRepo = EventRepository(familyRepository: familyRepo, useDemoFallback: false);
      final transportRepo = TransportRepository(familyRepository: familyRepo, useDemoFallback: false);
      final storeRepo = StoreRepository(useDemoFallback: false);
      final guidanceRepo = GuidanceRepository(useDemoFallback: false);
      final academicRepo = AcademicRepository();

      // Director user profile for the new school
      final directorProfile = UserProfile(
        id: 'user-dir-caribe',
        colegioId: newSchoolId,
        colegioNombre: newSchool.nombre,
        rol: UserRole.adminColegio,
        email: 'directora@caribe.edu.do',
        nombres: 'Carmen',
        apellidos: 'Santana',
      );

      // 2. Mount MainShell as School Administrator
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            userProfile: directorProfile,
            familyRepository: familyRepo,
            schoolRepository: schoolRepo,
            circularRepository: circularRepo,
            eventRepository: eventRepo,
            transportRepository: transportRepo,
            storeRepository: storeRepo,
            guidanceRepository: guidanceRepo,
            attendanceRepository: attendanceRepo,
            academicRepository: academicRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify Dashboard Overview
      expect(find.text('Panel de Control Institucional'), findsOneWidget);
      expect(find.textContaining('Colegio Experimental del Caribe'), findsWidgets);
      // Zero mock leak: 0 students and 0 families in KPIs
      expect(find.text('Estudiantes Activos'), findsOneWidget);
      expect(find.text('Sin alumnos registrados'), findsWidgets);
      expect(find.text('Sin familias registradas'), findsOneWidget);
      expect(find.text('Sin eventos programados'), findsOneWidget);
      expect(find.text('Sin cursos configurados'), findsOneWidget);

      // 4. Verify Quick Action opens enrollment dialog and create first family
      final btnEnrolar = find.byKey(const Key('btn_quick_enrolar_familia'));
      expect(btnEnrolar, findsOneWidget);
      await tester.tap(btnEnrolar);
      await tester.pumpAndSettle();

      expect(find.text('Alta de Cuenta Familiar Única'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      await familyRepo.createFamily(
        colegioId: newSchoolId,
        nombreFamilia: 'Familia Almonte Peña',
        tutorNombres: 'Marcos',
        tutorApellidos: 'Almonte',
        tutorEmail: 'marcos.almonte@gmail.com',
        tutorTelefono: '809-555-7722',
        cedula: '001-1234567-8',
        estudianteNombres: 'Lucas',
        estudianteApellidos: 'Almonte Peña',
        gradoNombre: '1ro de Primaria',
      );

      // 6. Navigate to Cuentas Familiares (Tab 1)
      await tester.tap(find.byKey(const Key('nav_item_1')));
      await tester.pumpAndSettle();
      expect(find.text('Directorio de Cuentas Familiares'), findsOneWidget);
      expect(find.text('Familia Almonte Peña'), findsOneWidget);
      // No demo family leaked
      expect(find.text('Familia Pérez González'), findsNothing);

      // 7. Navigate to Finanzas & Cobranzas (Tab 2)
      await tester.tap(find.byKey(const Key('nav_item_2')));
      await tester.pumpAndSettle();
      expect(find.text('Gestión de Cobranzas & Ingresos Institucionales'), findsOneWidget);
      expect(find.text('Historial de Cobros & Recibos'), findsOneWidget);

      // 8. Navigate to Control de Asistencia (Tab 3)
      await tester.tap(find.byKey(const Key('nav_item_3')));
      await tester.pumpAndSettle();
      expect(find.text('Control de Asistencia Escolar'), findsOneWidget);
      expect(find.text('Guardar y Notificar a Padres'), findsOneWidget);

      // 9. Navigate to Circulares & Avisos (Tab 4)
      await tester.tap(find.byKey(const Key('nav_item_4')));
      await tester.pumpAndSettle();
      expect(find.text('Circulares Oficiales & Comunicados'), findsOneWidget);
      expect(find.text('Redactar Circular'), findsOneWidget);
      // Zero demo circulars
      expect(find.textContaining('Salida Pedagógica al Acuario'), findsNothing);

      // 10. Navigate to Servicios de Cuido (Tab 5)
      await tester.tap(find.byKey(const Key('nav_item_5')));
      await tester.pumpAndSettle();
      expect(find.text('Servicios de Cuido Extracurricular'), findsOneWidget);
      expect(find.text('Abrir Control de Asistencia'), findsOneWidget);

      // 11. Navigate to Eventos & Excursiones (Tab 6)
      await tester.tap(find.byKey(const Key('nav_item_6')));
      await tester.pumpAndSettle();
      expect(find.text('Gestión de Eventos & Excursiones'), findsOneWidget);
      expect(find.text('Nuevo Evento Escolar'), findsOneWidget);
      // Zero demo events
      expect(find.textContaining('Jardín Botánico'), findsNothing);

      // 12. Navigate to Transporte Escolar (Tab 7)
      await tester.tap(find.byKey(const Key('nav_item_7')));
      await tester.pumpAndSettle();
      expect(find.text('Transporte Escolar & Monitoreo de Rutas'), findsOneWidget);
      expect(find.text('Nueva Ruta Escolar'), findsOneWidget);
      // Zero demo routes
      expect(find.textContaining('Ruta 1 - Naco'), findsNothing);

      // 13. Navigate to Gestión Académica & Notas (Tab 8)
      await tester.tap(find.byKey(const Key('nav_item_8')));
      await tester.pumpAndSettle();
      expect(find.text('REGISTRO & EVALUACIÓN ACADÉMICA'), findsOneWidget);

      // 14. Navigate to Atención a Familias (Tab 9)
      await tester.tap(find.byKey(const Key('nav_item_9')));
      await tester.pumpAndSettle();
      expect(find.text('Atención a Familias & Consultas Escolares'), findsOneWidget);
      // Zero mock questions
      expect(find.text('No hay consultas que coincidan con los filtros.'), findsOneWidget);

      // 15. Navigate to Tienda & Uniformes (Tab 10)
      await tester.tap(find.byKey(const Key('nav_item_10')));
      await tester.pumpAndSettle();
      expect(find.text('Tienda & Uniformes Oficiales'), findsOneWidget);
      expect(find.text('Nuevo Producto'), findsOneWidget);

      // 16. Navigate to Psicología & Convivencia (Tab 11)
      await tester.tap(find.byKey(const Key('nav_item_11')));
      await tester.pumpAndSettle();
      expect(find.text('Psicología & Convivencia Escolar'), findsOneWidget);
      expect(find.text('+ Nuevo Caso de Orientación'), findsOneWidget);
      // Zero mock cases
      expect(find.text('No se encontraron expedientes psicopedagógicos'), findsOneWidget);

      // 17. Navigate to Método de Pago & Suscripción (Tab 12)
      final navItem12 = find.byKey(const Key('nav_item_12'));
      await tester.scrollUntilVisible(
        navItem12,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(navItem12);
      await tester.pumpAndSettle();
      expect(find.text('Método de Pago & Suscripción Escolar'), findsOneWidget);
      expect(find.textContaining('Guardar Método de Pago'), findsOneWidget);
    });
  });
}
