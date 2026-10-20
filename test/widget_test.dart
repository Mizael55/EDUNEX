import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edunex/main.dart';
import 'package:edunex/features/auth/models/user_profile.dart';
import 'package:edunex/features/auth/models/user_role.dart';
import 'package:edunex/features/families/repositories/family_repository.dart';
import 'package:edunex/features/families/models/student.dart';
import 'package:edunex/features/families/screens/create_family_dialog.dart';
import 'package:edunex/features/auth/repositories/auth_repository.dart';
import 'package:edunex/features/superadmin/repositories/school_repository.dart';
import 'package:edunex/features/superadmin/screens/business_model_dialog.dart';
import 'package:edunex/features/superadmin/screens/create_school_dialog.dart';
import 'package:edunex/features/parent_portal/screens/parent_payments_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_services_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_store_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_questions_screen.dart';
import 'package:edunex/features/events/models/school_event.dart';
import 'package:edunex/features/events/models/event_registration.dart';
import 'package:edunex/features/events/repositories/event_repository.dart';
import 'package:edunex/features/events/screens/admin_events_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_events_screen.dart';
import 'package:edunex/features/attendance/models/attendance_record.dart';
import 'package:edunex/features/attendance/repositories/attendance_repository.dart';
import 'package:edunex/features/attendance/screens/admin_attendance_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_attendance_screen.dart';
import 'package:edunex/features/transport/models/bus_route.dart';
import 'package:edunex/features/transport/repositories/transport_repository.dart';
import 'package:edunex/features/transport/screens/admin_transport_screen.dart';
import 'package:edunex/features/circulars/models/circular.dart';
import 'package:edunex/features/circulars/repositories/circular_repository.dart';
import 'package:edunex/features/circulars/screens/admin_circulars_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_circulars_screen.dart';
import 'package:edunex/features/finances/models/billing_models.dart';
import 'package:edunex/features/finances/screens/finance_overview_screen.dart';
import 'package:edunex/features/finances/screens/monthly_billing_dialog.dart';
import 'package:edunex/features/academics/models/grade_report.dart';
import 'package:edunex/features/academics/repositories/academic_repository.dart';
import 'package:edunex/features/academics/screens/admin_grades_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_grades_screen.dart';
import 'package:edunex/features/inquiries/screens/admin_inquiries_screen.dart';
import 'package:edunex/features/parent_portal/screens/online_payment_gateway_dialog.dart';
import 'package:edunex/features/parent_portal/widgets/receipt_details_dialog.dart';
import 'package:edunex/features/store/models/store_item.dart';
import 'package:edunex/features/store/repositories/store_repository.dart';
import 'package:edunex/features/store/screens/admin_store_screen.dart';
import 'package:edunex/features/finances/models/payment_approval_request.dart';
import 'package:edunex/features/finances/screens/record_payment_dialog.dart';
import 'package:edunex/features/superadmin/widgets/edit_school_logo_dialog.dart';
import 'package:edunex/features/families/screens/family_detail_dialog.dart';
import 'package:edunex/features/families/screens/enroll_student_dialog.dart';
import 'package:edunex/features/families/screens/family_directory_screen.dart';
import 'package:edunex/features/dashboard/screens/dashboard_overview_screen.dart';
import 'package:edunex/features/parent_portal/screens/parent_portal_screen.dart';
import 'package:edunex/features/families/models/student_document.dart';
import 'package:edunex/features/families/models/tutor.dart';
import 'package:edunex/screens/login_screen.dart';
import 'package:edunex/screens/main_shell.dart';
import 'package:edunex/features/teacher_portal/models/teacher_class.dart';
import 'package:edunex/features/teacher_portal/models/teacher_evaluation.dart';
import 'package:edunex/features/teacher_portal/models/student_behavior_log.dart';
import 'package:edunex/features/teacher_portal/repositories/teacher_repository.dart';
import 'package:edunex/features/teacher_portal/screens/teacher_portal_screen.dart';
import 'package:edunex/features/guidance/models/guidance_case.dart';
import 'package:edunex/features/guidance/repositories/guidance_repository.dart';
import 'package:edunex/features/guidance/screens/guidance_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('EdunexApp desktop smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const EdunexApp());
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('EdunexApp mobile smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const EdunexApp());
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('MainShell renders admin portal and KPIs on desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final adminProfile = UserProfile(
      id: 'admin-1',
      colegioId: 'col-1',
      rol: UserRole.adminColegio,
      email: 'director@edunex.edu',
      nombres: 'Carlos',
      apellidos: 'Gómez',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(userProfile: adminProfile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Panel de Control Institucional'), findsOneWidget);
    expect(find.text('Cuentas Familiares'), findsWidgets);
    expect(find.text('Estudiantes Activos'), findsOneWidget);
  });

  testWidgets('MainShell renders parent portal for tutorFamiliar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final parentProfile = UserProfile(
      id: 'parent-1',
      colegioId: 'col-1',
      rol: UserRole.tutorFamiliar,
      email: 'familia@edunex.edu',
      nombres: 'Roberto',
      apellidos: 'Pérez',
    );

    final demoFamilyRepo = FamilyRepository(useDemoFallback: true);
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          userProfile: parentProfile,
          familyRepository: demoFamilyRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Roberto Pérez!'), findsOneWidget);
    expect(find.text('PORTAL DE PADRES'), findsOneWidget);
    expect(find.textContaining('Mis Hijos Matriculados'), findsOneWidget);
  });

  test('FamilyRepository loads pilot families correctly', () async {
    final repo = FamilyRepository(useDemoFallback: true);
    final families = await repo.getFamilies();

    expect(families.isNotEmpty, isTrue);
    final perezFamily = families.firstWhere((f) => f.codigoFamilia == 'FAM-2026-001');
    expect(perezFamily.nombreFamilia, 'Familia Pérez González');
    expect(perezFamily.estudiantes.length, 2);
    expect(perezFamily.tutores.length, 2);
    expect(perezFamily.balancePendiente, 7500.00);
    expect(perezFamily.estaAlDia, isFalse);
  });

  testWidgets('MainShell renders SaaS Master Panel for superadmin', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final superadminProfile = UserProfile(
      id: 'superadmin-1',
      colegioId: null,
      rol: UserRole.superadmin,
      email: 'admin@edunex.edu',
      nombres: 'Administrador',
      apellidos: 'SaaS EDUNEX',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(userProfile: superadminProfile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Panel Maestro SaaS'), findsWidgets);
    expect(find.text('Colegios Clientes'), findsWidgets);
    expect(find.text('Red Central EDUNEX (SaaS)'), findsOneWidget);
  });

  test('SchoolRepository createSchoolWithDirector creates school and director data', () async {
    final repo = SchoolRepository();
    final result = await repo.createSchoolWithDirector(
      nombre: 'Colegio Experimental EDUNEX',
      rnc: '1-30-11223-4',
      siglas: 'CEED',
      estadoSuscripcion: 'active',
      maxEstudiantes: 500,
      directorEmail: 'director.exp@edunex.edu',
      directorPassword: 'password123',
      directorNombres: 'Marcos',
      directorApellidos: 'Díaz',
    );

    final school = result['school'];
    final director = result['director'] as Map<String, dynamic>;

    expect(school.nombre, 'Colegio Experimental EDUNEX');
    expect(school.siglas, 'CEED');
    expect(director['email'], 'director.exp@edunex.edu');
    expect(director['rol'], 'admin_colegio');
  });

  test('FamilyRepository createFamily, recordPayment and enrollStudent work end-to-end', () async {
    final repo = FamilyRepository();
    final newFamily = await repo.createFamily(
      colegioId: 'col-test',
      nombreFamilia: 'Familia Méndez Peña',
      tutorNombres: 'Julio',
      tutorApellidos: 'Méndez',
      tutorEmail: 'julio.mendez@test.com',
      tutorTelefono: '809-555-9000',
      balanceInicial: 10000.0,
      estudianteNombres: 'Camila',
      gradoNombre: '2do de Primaria',
    );

    expect(newFamily.nombreFamilia, 'Familia Méndez Peña');
    expect(newFamily.balancePendiente, 10000.0);
    expect(newFamily.estudiantes.length, 1);
    expect(newFamily.estudiantes.first.nombres, 'Camila');

    // Registrar pago / abono
    await repo.recordPayment(
      familiaId: newFamily.id,
      monto: 4000.0,
      concepto: 'Abono Colegiatura',
      metodo: 'Transferencia',
    );

    final updated = await repo.getFamilyById(newFamily.id);
    expect(updated, isNotNull);
    expect(updated!.balancePendiente, 6000.0);

    // Matricular segundo hijo
    final newStudent = await repo.enrollStudent(
      familiaId: newFamily.id,
      colegioId: 'col-test',
      nombres: 'Diego',
      apellidos: 'Méndez',
      gradoNombre: 'Kinder',
    );

    expect(newStudent.nombreCompleto, 'Diego Méndez');
    final familyWithTwo = await repo.getFamilyById(newFamily.id);
    expect(familyWithTwo!.estudiantes.length, 2);
  });

  testWidgets('LoginScreen displays 4 role profiles including Estudiante and School Branding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Administrador'), findsWidgets);
    expect(find.text('Docente'), findsOneWidget);
    expect(find.text('Tutor o Familia'), findsOneWidget);
    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.text('Personalizar Logo / Centro Educativo'), findsOneWidget);
  });

  testWidgets('MainShell renders student portal for estudiante role', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final studentProfile = UserProfile(
      id: 'student-1',
      colegioId: 'col-1',
      rol: UserRole.estudiante,
      email: 'estudiante@edunex.edu',
      nombres: 'Alejandro',
      apellidos: 'Gómez',
    );

    final demoFamilyRepo = FamilyRepository(useDemoFallback: true);
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          userProfile: studentProfile,
          familyRepository: demoFamilyRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi Portal Escolar'), findsWidgets);
    expect(find.text('Servicios de Cuido'), findsWidgets);
    expect(find.text('Tienda & Uniformes'), findsWidgets);
  });

  testWidgets('CreateSchoolDialog renders Casos 1, 2, 3, 4 properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = SchoolRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateSchoolDialog(schoolRepository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Caso 1: RNC Persona Jurídica / Física
    expect(find.textContaining('Persona Jurídica'), findsWidgets);
    expect(find.textContaining('Persona Física'), findsWidgets);

    // Caso 2: Capacidad exacta y presets
    expect(find.text('Número Exacto de Estudiantes *'), findsOneWidget);
    expect(find.text('100 alumnos'), findsOneWidget);
    expect(find.text('250 alumnos'), findsOneWidget);
    expect(find.text('500 alumnos'), findsOneWidget);

    // Caso 3: Geolocalizar GPS
    expect(find.text('Geolocalizar Dirección (GPS/Coordenadas)'), findsOneWidget);

    // Caso 4: Multi-sucursales
    expect(find.text('¿Cuenta con sucursales o recintos adicionales?'), findsOneWidget);
  });

  testWidgets('BusinessModelDialog renders pricing table, simulation and MINERD targets', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BusinessModelDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modelo de Negocio & Arquitectura Comercial EDUNEX'), findsOneWidget);
    expect(find.text('RD\$ 7,000'), findsOneWidget);
    expect(find.text('1 Sucursal'), findsOneWidget);
    expect(find.text('2 Sucursales'), findsOneWidget);
    expect(find.text('3+ Sucursales'), findsOneWidget);
    expect(find.textContaining('MRR Proyectado'), findsOneWidget);
  });

  test('FamilyRepository creates family with multi-student, physical tutor dossier and prevents disappearance on login', () async {
    final familyRepo = FamilyRepository(useDemoFallback: true);
    final authRepo = AuthRepository();

    final created = await familyRepo.createFamily(
      colegioId: 'col-1',
      nombreFamilia: 'Familia Pérez Gómez',
      tutorNombres: 'Marcos',
      tutorApellidos: 'Pérez',
      tutorEmail: 'marcos.perez@test.edu',
      tutorTelefono: '809-555-0199',
      cedula: '001-9988776-5',
      ocupacion: 'Ingeniero de Software',
      lugarTrabajo: 'Tech Corp',
      telefonoTrabajo: '809-222-1111',
      ingresosAproximados: '120000',
      cartaTrabajoAdjunta: true,
      estadosFinancierosAdjuntos: true,
      copiaCedulaAdjunta: true,
      modalidadPago: 'Semestral',
      descuentoAcordadoPct: 5.0,
      multipleStudents: [
        Student(
          id: 'est-1',
          colegioId: 'col-1',
          familiaId: 'fam-test',
          matricula: 'MAT-001',
          nombres: 'Mateo',
          apellidos: 'Pérez',
          fechaNacimiento: DateTime(2018, 5, 12),
          gradoNombre: '1er Grado Primaria',
          tipoSangre: 'O+',
          alergias: 'Ninguna',
          seguroMedico: 'Humano Seguros',
          numeroPoliza: 'POL-9988',
          pediatraContacto: 'Dra. Castillo (809-555-4321)',
          fotoAdjunta: true,
          actaNacimientoAdjunta: true,
          certificadoNotasAdjunto: true,
          cartaSaldoConductaAdjunta: true,
        ),
        Student(
          id: 'est-2',
          colegioId: 'col-1',
          familiaId: 'fam-test',
          matricula: 'MAT-002',
          nombres: 'Lucía',
          apellidos: 'Pérez',
          fechaNacimiento: DateTime(2021, 2, 8),
          gradoNombre: 'Kínder',
          tipoSangre: 'O+',
          alergias: 'Polvo',
          seguroMedico: 'Humano Seguros',
          numeroPoliza: 'POL-9988',
          pediatraContacto: 'Dra. Castillo (809-555-4321)',
          fotoAdjunta: true,
          actaNacimientoAdjunta: true,
          certificadoNotasAdjunto: false,
          cartaSaldoConductaAdjunta: false,
        ),
      ],
    );

    expect(created.id, isNotEmpty);
    expect(created.estudiantes.length, 2);
    expect(created.tutores.first.ocupacion, 'Ingeniero de Software');
    expect(created.tutores.first.ingresosAproximados, '120000');
    expect(created.tutores.first.cartaTrabajoAdjunta, isTrue);

    // Verify student medical data & dossier
    expect(created.estudiantes[0].tipoSangre, 'O+');
    expect(created.estudiantes[0].seguroMedico, 'Humano Seguros');
    expect(created.estudiantes[0].cartaSaldoConductaAdjunta, isTrue);
    expect(created.estudiantes[1].nombreCompleto, 'Lucía Pérez');

    // Verify auth login works seamlessly for this tutor
    final authUser = await authRepo.signInWithPassword(
      email: 'marcos.perez@test.edu',
      password: 'Password123!',
    );
    expect(authUser.rol, UserRole.tutorFamiliar);
    expect(authUser.colegioId, 'col-1');

    // Verify family does NOT disappear upon access
    final retrieved = await familyRepo.getFamilyForCurrentUser(
      email: authUser.email,
      colegioId: authUser.colegioId,
    );
    expect(retrieved, isNotNull);
    expect(retrieved!.id, created.id);
    expect(retrieved.nombreFamilia, 'Familia Pérez Gómez');
    expect(retrieved.estudiantes.length, 2);
  });

  testWidgets('CreateFamilyDialog renders 4 tabs, supports adding second student and displays quotation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateFamilyDialog(
            repository: familyRepo,
            colegioId: 'col-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 4 tabs
    expect(find.text('1. Tutor & Familia'), findsOneWidget);
    expect(find.textContaining('2. Alumnos'), findsOneWidget);
    expect(find.text('3. Criterios del Centro'), findsOneWidget);
    expect(find.text('4. Cotización & Pagos'), findsOneWidget);

    // Verify tutor fields
    expect(find.textContaining('Cédula'), findsWidgets);
    expect(find.textContaining('Ocupación / Profesión'), findsOneWidget);
    expect(find.textContaining('Lugar de Trabajo'), findsOneWidget);
    expect(find.textContaining('Documentos Físicos del Tutor'), findsOneWidget);

    // Switch to Tab 2: Alumnos
    await tester.tap(find.textContaining('2. Alumnos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Expediente Médico & Clínico'), findsOneWidget);
    expect(find.textContaining('Documentos del Expediente Escolar'), findsOneWidget);
    expect(find.text('+ Agregar Otro Alumno / Hermano'), findsOneWidget);

    // Add second student
    await tester.tap(find.text('+ Agregar Otro Alumno / Hermano'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ALUMNO #2'), findsOneWidget);

    // Switch to Tab 4: Cotización & Pagos
    await tester.tap(find.text('4. Cotización & Pagos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sujeto a Mejora de Pago'), findsOneWidget);
    expect(find.textContaining('Resumen Consolidado'), findsOneWidget);
    expect(find.text('COTIZADOR EN VIVO'), findsOneWidget);
    expect(find.text('Generar y Emitir Cotización Oficial'), findsOneWidget);
  });

  testWidgets('Issue #13: Tutor cannot create families or matriculate students, and has full access to the 6 allowed features', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final parentProfile = UserProfile(
      id: 'parent-roberto',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      rol: UserRole.tutorFamiliar,
      email: 'familia@edunex.edu',
      nombres: 'Roberto',
      apellidos: 'Pérez',
    );

    final familyRepo = FamilyRepository(useDemoFallback: true);

    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          userProfile: parentProfile,
          familyRepository: familyRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Caso 1: Verificar que NO existen los botones "Nueva Familia" ni "Matricular Alumno"
    expect(find.text('Nueva Familia'), findsNothing);
    expect(find.text('Matricular Alumno'), findsNothing);

    // 2. Verificar banner institucional oficial
    expect(find.textContaining('Estudiantes Matriculados Oficialmente'), findsOneWidget);

    // 3. Verificar que los 6 módulos / acciones permitidas están presentes en pantalla o navegación
    expect(find.textContaining('1. Comprar en la Tienda'), findsOneWidget);
    expect(find.textContaining('2. Pagar Colegiatura'), findsOneWidget);
    expect(find.textContaining('3. Realizar Acuerdos de Pago'), findsOneWidget);
    expect(find.textContaining('4. Hacer Preguntas al Centro'), findsOneWidget);
    expect(find.textContaining('5. Gestionar Servicios'), findsOneWidget);
    expect(find.textContaining('6. Validar Comprobantes (NCF)'), findsOneWidget);

    // 4. Navegar a Tienda Escolar
    await tester.tap(find.text('Tienda Escolar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tienda Escolar EDUNEX'), findsOneWidget);
    expect(find.textContaining('Polo Oficial Institucional'), findsOneWidget);

    // 5. Navegar a Pagos, Acuerdos & NCF
    await tester.tap(find.text('Pagos, Acuerdos & NCF'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pagos, Acuerdos & Comprobantes'), findsOneWidget);
    expect(find.textContaining('Comprobantes Oficiales'), findsOneWidget);
    expect(find.textContaining('Convenios & Acuerdos de Pago'), findsOneWidget);

    // 6. Navegar a Servicios Escolares
    await tester.tap(find.text('Servicios Escolares'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gestión de Servicios Escolares'), findsOneWidget);
    expect(find.textContaining('Cuido Vespertino'), findsWidgets);

    // 7. Navegar a Consultas & Preguntas
    await tester.tap(find.text('Consultas & Preguntas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Canal de Consultas & Preguntas'), findsOneWidget);
    expect(find.text('Nueva Consulta'), findsOneWidget);
  });

  test('Issue #13: FamilyRepository operations for receipts, agreements, questions, and services work end-to-end', () async {
    final familyRepo = FamilyRepository(useDemoFallback: true);
    const famId = 'e0000000-0000-0000-0000-000000000001';

    // 1. Test Payment & Receipt creation with NCF
    final receipt = await familyRepo.recordPayment(
      familiaId: famId,
      monto: 3500.0,
      concepto: 'Mensualidad Febrero Parcial',
      metodo: 'Tarjeta de Crédito / CardNET',
    );
    expect(receipt.id.isNotEmpty, isTrue);
    expect(receipt.ncf.startsWith('B02'), isTrue);
    expect(receipt.monto, 3500.0);

    final receipts = await familyRepo.getReceiptsForFamily(famId);
    expect(receipts.any((r) => r.id == receipt.id), isTrue);

    // 2. Test Agreement Request
    final agreement = await familyRepo.submitAgreementRequest(
      familiaId: famId,
      nombreFamilia: 'Familia Pérez González',
      tipoAcuerdo: 'Extensión de Plazo de Pago',
      propuestaCuota: 2000.0,
      justificacion: 'Solicitud de extensión de plazo por retraso en nómina',
    );
    expect(agreement.estado, 'En revisión por Dirección');
    final agreements = await familyRepo.getAgreementsForFamily(famId);
    expect(agreements.any((a) => a.id == agreement.id), isTrue);

    // 3. Test Question Submission
    final question = await familyRepo.submitQuestion(
      familiaId: famId,
      tutorNombre: 'Roberto Pérez',
      departamento: 'Caja y Facturación',
      asunto: 'Consulta sobre factura de transporte',
      mensaje: '¿El servicio incluye ruta de regreso los viernes?',
    );
    expect(question.estado, 'En trámite');
    final questions = await familyRepo.getQuestionsForFamily(famId);
    expect(questions.any((q) => q.id == question.id), isTrue);

    // 4. Test Student Service Toggle
    await familyRepo.toggleStudentService(
      familiaId: famId,
      studentId: 'f0000000-0000-0000-0000-000000000001',
      servicio: 'Transporte Escolar',
      activar: true,
    );
    final fam = await familyRepo.getFamilyById(famId);
    expect(fam, isNotNull);
    final student = fam!.estudiantes.firstWhere((s) => s.id == 'f0000000-0000-0000-0000-000000000001');
    expect(student.serviciosActivos.contains('Transporte Escolar'), isTrue);
  });

  test('EventRepository manages school events and registrations correctly', () async {
    final familyRepo = FamilyRepository(useDemoFallback: true);
    final eventRepo = EventRepository(familyRepository: familyRepo);

    final events = await eventRepo.getEvents();
    expect(events.isNotEmpty, isTrue);

    // 1. Create a new event
    final newEvent = await eventRepo.createEvent(
      colegioId: 'col-1',
      titulo: 'Visita Botánica y Herbario Nacional',
      descripcion: 'Recorrido educativo de ciencias naturales',
      tipo: 'Excursión',
      lugar: 'Jardín Botánico Nacional',
      fechaEvento: DateTime.now().add(const Duration(days: 10)),
      fechaLimiteInscripcion: DateTime.now().add(const Duration(days: 8)),
      precio: 850.0,
      cupoMaximo: 30,
    );
    expect(newEvent.id.isNotEmpty, isTrue);
    expect(newEvent.cuposRestantes, 30);

    // 2. Register student to the event
    final registration = await eventRepo.registerStudentToEvent(
      eventoId: newEvent.id,
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      estudianteId: 'f0000000-0000-0000-0000-000000000001',
      estudianteNombre: 'Mateo Pérez',
      metodoPago: 'Tarjeta de Crédito / CardNET',
    );
    expect(registration.id.isNotEmpty, isTrue);
    expect(registration.estadoPago, 'Pagado');
    expect(registration.montoPagado, 850.0);

    // 3. Verify event capacity decreased
    final updatedEvent = await eventRepo.getEventById(newEvent.id);
    expect(updatedEvent!.cuposOcupados, 1);
    expect(updatedEvent.cuposRestantes, 29);

    // 4. Verify family registrations query
    final familyRegs = await eventRepo.getRegistrationsForFamily('e0000000-0000-0000-0000-000000000001');
    expect(familyRegs.any((r) => r.id == registration.id), isTrue);

    // 5. Verify event participants query
    final eventRegs = await eventRepo.getRegistrationsForEvent(newEvent.id);
    expect(eventRegs.length, 1);
    expect(eventRegs.first.estudianteNombre, 'Mateo Pérez');
  });

  testWidgets('AdminEventsScreen displays school events, metrics and creates event', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final eventRepo = EventRepository(familyRepository: familyRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminEventsScreen(
            repository: eventRepo,
            colegioId: 'col-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Metrics
    expect(find.text('Gestión de Eventos & Excursiones'), findsOneWidget);
    expect(find.text('Eventos Publicados'), findsOneWidget);
    expect(find.text('Alumnos Inscritos'), findsOneWidget);
    expect(find.text('Recaudación Estimada'), findsOneWidget);
    expect(find.text('Estado de Cupos'), findsOneWidget);
    expect(find.text('Nuevo Evento Escolar'), findsOneWidget);

    // Verify event cards exist
    expect(find.textContaining('Gran Excursión al Jardín Botánico Nacional'), findsOneWidget);
  });

  testWidgets('ParentEventsScreen renders catalog and allows child registration', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final parentProfile = UserProfile(
      id: 'parent-1',
      colegioId: 'col-1',
      rol: UserRole.tutorFamiliar,
      email: 'familia@edunex.edu',
      nombres: 'Roberto',
      apellidos: 'Pérez',
    );

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final eventRepo = EventRepository(familyRepository: familyRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentEventsScreen(
            userProfile: parentProfile,
            familyRepository: familyRepo,
            eventRepository: eventRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Catalog UI elements
    expect(find.text('Eventos, Excursiones & Actividades'), findsOneWidget);
    expect(find.textContaining('Gran Excursión al Jardín Botánico Nacional'), findsOneWidget);

    // Tap on Inscribir a mi hijo
    final enrollButtons = find.text('Inscribir a mi hijo');
    expect(enrollButtons, findsWidgets);
    await tester.tap(enrollButtons.first);
    await tester.pumpAndSettle();

    // Registration Dialog appears
    expect(find.textContaining('Inscripción:'), findsOneWidget);
    expect(find.text('Confirmar Inscripción'), findsOneWidget);

    // Confirm registration
    await tester.tap(find.text('Confirmar Inscripción'));
    await tester.pumpAndSettle();

    // Dialog closed and active registrations updated
    expect(find.text('Confirmar Inscripción'), findsNothing);
    expect(find.textContaining('inscripciones activas'), findsOneWidget);
  });

  test('AttendanceRepository loads, updates and justifies records correctly', () async {
    final familyRepo = FamilyRepository(useDemoFallback: true);
    final attendanceRepo = AttendanceRepository(familyRepository: familyRepo);

    // 1. Fetch records for date and section
    final records = await attendanceRepo.getAttendanceForDateAndSection(
      fecha: DateTime(2026, 3, 16),
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradoNombre: '1ro de Primaria',
      seccionNombre: 'Sección A',
    );
    expect(records.isNotEmpty, true);
    expect(records.first.estudianteNombre, contains('Mateo Pérez'));

    // 2. Compute attendance stats
    final stats = await attendanceRepo.getAttendanceStats(
      colegioId: 'a0000000-0000-0000-0000-000000000001',
    );
    expect(stats['totalRegistros'], greaterThan(0));

    // 3. Justify an absence
    final justifiedRecord = await attendanceRepo.submitJustification(
      recordId: 'att-003',
      motivo: 'Cita Médica Pediátrica',
      comentario: 'Consulta de control anual',
    );
    expect(justifiedRecord.estado, 'Justificado');
    expect(justifiedRecord.esJustificado, true);
    expect(justifiedRecord.justificacionTutor, contains('Cita Médica'));
  });

  testWidgets('AdminAttendanceScreen renders student roster and updates attendance', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final attendanceRepo = AttendanceRepository(familyRepository: familyRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminAttendanceScreen(
            repository: attendanceRepo,
            colegioId: 'a0000000-0000-0000-0000-000000000001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify key titles and buttons
    expect(find.text('Control de Asistencia Escolar'), findsOneWidget);
    expect(find.text('Marcar Todos Presentes'), findsOneWidget);
    expect(find.text('Guardar y Notificar a Padres'), findsOneWidget);

    // Verify student name is listed
    expect(find.textContaining('Mateo Pérez González'), findsOneWidget);

    // Mark all as present
    await tester.tap(find.text('Marcar Todos Presentes'));
    await tester.pumpAndSettle();

    // Save attendance
    await tester.tap(find.text('Guardar y Notificar a Padres'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify confirmation snackbar
    expect(find.textContaining('¡Asistencia guardada y notificada'), findsOneWidget);
  });

  testWidgets('ParentAttendanceScreen renders attendance history and submits justification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final parentProfile = UserProfile(
      id: 'parent-1',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      rol: UserRole.tutorFamiliar,
      email: 'familia@edunex.edu',
      nombres: 'Roberto',
      apellidos: 'Pérez',
    );

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final attendanceRepo = AttendanceRepository(familyRepository: familyRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentAttendanceScreen(
            userProfile: parentProfile,
            familyRepository: familyRepo,
            attendanceRepository: attendanceRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and child chips
    expect(find.text('Asistencia & Seguimiento Escolar'), findsOneWidget);
    expect(find.textContaining('Mateo Pérez González'), findsWidgets);

    // Check justification button for absence/tardiness
    final justifyButtons = find.text('Justificar Inasistencia');
    expect(justifyButtons, findsWidgets);

    // Tap first Justificar button
    await tester.tap(justifyButtons.first);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Justificar Inasistencia / Tardanza'), findsOneWidget);
    expect(find.text('Enviar Justificación'), findsOneWidget);

    // Submit justification
    await tester.tap(find.text('Enviar Justificación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify dialog dismissed and success message shown
    expect(find.text('Justificar Inasistencia / Tardanza'), findsNothing);
    expect(find.textContaining('Justificación enviada'), findsOneWidget);
  });

  test('TransportRepository loads routes, updates status and manages passenger boarding', () async {
    final familyRepo = FamilyRepository(useDemoFallback: true);
    final transportRepo = TransportRepository(familyRepository: familyRepo);

    // 1. Fetch routes
    final routes = await transportRepo.getRoutes(colegioId: 'a0000000-0000-0000-0000-000000000001');
    expect(routes.length, 3);
    expect(routes.first.codigo, 'RUTA-01');
    expect(routes.first.choferNombre, 'Manuel Rosario');

    // 2. Update route status
    final updatedRoute = await transportRepo.updateRouteStatus('route-001', 'Completada');
    expect(updatedRoute.estadoRuta, 'Completada');
    expect(updatedRoute.completada, true);

    // 3. Update passenger boarding status
    final passenger = await transportRepo.updatePassengerStatus(
      routeId: 'route-001',
      estudianteId: 'f0000000-0000-0000-0000-000000000001',
      nuevoEstado: 'Entregado en Destino',
    );
    expect(passenger.estadoAbordaje, 'Entregado en Destino');

    // 4. Check transport stats
    final stats = await transportRepo.getTransportStats(colegioId: 'a0000000-0000-0000-0000-000000000001');
    expect(stats['totalRutas'], 3);
    expect(stats['totalAsientos'], greaterThan(60));
  });

  testWidgets('AdminTransportScreen renders routes, metrics and allows passenger check-in', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final transportRepo = TransportRepository(familyRepository: familyRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminTransportScreen(
            repository: transportRepo,
            colegioId: 'a0000000-0000-0000-0000-000000000001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and KPI metrics
    expect(find.text('Transporte Escolar & Monitoreo de Rutas'), findsOneWidget);
    expect(find.text('Rutas Operativas'), findsOneWidget);
    expect(find.text('Alumnos en Ruta'), findsOneWidget);
    expect(find.text('Nueva Ruta Escolar'), findsOneWidget);

    // Verify route cards exist
    expect(find.textContaining('Ruta 1 - Naco'), findsOneWidget);
    expect(find.textContaining('Manuel Rosario'), findsOneWidget);

    // Open passenger manifest sheet
    final passengerButtons = find.textContaining('Hoja de Pasajeros');
    expect(passengerButtons, findsWidgets);
    await tester.tap(passengerButtons.first);
    await tester.pumpAndSettle();

    // Verify modal sheet appears with assigned student
    expect(find.textContaining('Hoja de Pasajeros & Abordaje: RUTA-01'), findsOneWidget);
    expect(find.textContaining('Mateo Pérez González'), findsOneWidget);
  });

  test('CircularRepository loads circulars, filters by grade and signs digital consent', () async {
    final familyRepo = FamilyRepository(useDemoFallback: true);
    final circularRepo = CircularRepository(familyRepository: familyRepo);

    // 1. Fetch circulars
    final circulars = await circularRepo.getCirculars(colegioId: 'a0000000-0000-0000-0000-000000000001');
    expect(circulars.length, 3);
    expect(circulars.first.titulo, contains('Circular No. 05'));

    // 2. Fetch for parent with 1ro de Primaria
    final parentCirculars = await circularRepo.getCircularsForParent(
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      gradosHijos: ['1ro de Primaria'],
    );
    expect(parentCirculars.isNotEmpty, true);

    // 3. Sign circular
    final sig = await circularRepo.signCircular(
      circularId: 'circ-001',
      signature: CircularSignature(
        id: 'sig-test-01',
        tutorId: 'parent-1',
        tutorNombre: 'Roberto Pérez',
        tutorCedula: '001-1234567-8',
        estudianteId: 'f0000000-0000-0000-0000-000000000001',
        estudianteNombre: 'Mateo Pérez González',
        fechaFirma: DateTime.now(),
        autorizado: true,
      ),
    );
    expect(sig.autorizado, true);
    expect(sig.tutorNombre, 'Roberto Pérez');

    // 4. Check stats
    final stats = await circularRepo.getCircularStats(colegioId: 'a0000000-0000-0000-0000-000000000001');
    expect(stats['totalPublicadas'], 3);
    expect(stats['requierenFirma'], 2);
  });

  testWidgets('AdminCircularsScreen renders circulars, KPIs and allows inspecting signatures', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final circularRepo = CircularRepository(familyRepository: familyRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminCircularsScreen(
            repository: circularRepo,
            colegioId: 'a0000000-0000-0000-0000-000000000001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify headers and metrics
    expect(find.text('Circulares Oficiales & Comunicados'), findsOneWidget);
    expect(find.text('Circulares Publicadas'), findsOneWidget);
    expect(find.text('Redactar Circular'), findsOneWidget);

    // Verify circular cards exist
    expect(find.textContaining('Circular No. 05'), findsOneWidget);

    // Open signatures sheet
    final sigButtons = find.textContaining('Ver Firmas Recibidas');
    expect(sigButtons, findsWidgets);
    await tester.tap(sigButtons.first);
    await tester.pumpAndSettle();

    // Verify modal sheet appears
    expect(find.text('Registro Oficial de Firmas Digitales'), findsOneWidget);
  });

  testWidgets('ParentCircularsScreen renders circulars and allows digital signing for student', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final parentProfile = UserProfile(
      id: 'parent-1',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      rol: UserRole.tutorFamiliar,
      email: 'familia@edunex.edu',
      nombres: 'Roberto',
      apellidos: 'Pérez',
    );

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final circularRepo = CircularRepository(familyRepository: familyRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentCircularsScreen(
            userProfile: parentProfile,
            familyRepository: familyRepo,
            circularRepository: circularRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and pending action banner
    expect(find.text('Circulares Oficiales & Autorizaciones'), findsOneWidget);
    expect(find.textContaining('Acción Requerida: Pendiente de autorización'), findsWidgets);

    // Tap signature button
    final signButtons = find.textContaining('Firmar para');
    expect(signButtons, findsWidgets);
    await tester.tap(signButtons.first);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Firma Digital & Consentimiento Legal'), findsOneWidget);
    expect(find.text('Confirmar Firma Digital'), findsOneWidget);

    // Submit signature
    await tester.tap(find.text('Confirmar Firma Digital'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Dialog dismissed and success confirmation shown
    expect(find.text('Firma Digital & Consentimiento Legal'), findsNothing);
    expect(find.textContaining('Consentimiento formal registrado'), findsOneWidget);
  });

  test('FamilyRepository: executeMonthlyBillingRun and getDebtAgingReport manage recurring charges and aging', () async {
    final repo = FamilyRepository(useDemoFallback: true);

    // Initial aging report
    final initialAging = await repo.getDebtAgingReport();
    expect(initialAging.familiasEnMora.isNotEmpty, isTrue);
    expect(initialAging.totalCarteraVencida, greaterThan(0));

    // Execute monthly billing run
    final billingResult = await repo.executeMonthlyBillingRun(
      mesConcepto: 'Octubre 2026',
      cuotaColegiaturaBase: 8500.0,
      incluirServicios: true,
    );

    expect(billingResult.familiasProcesadas, greaterThan(0));
    expect(billingResult.estudiantesFacturados, greaterThan(0));
    expect(billingResult.montoTotalFacturado, greaterThan(0));
    expect(billingResult.mesConcepto, 'Octubre 2026');

    // History contains the run
    final runs = await repo.getBillingRuns();
    expect(runs.length, greaterThanOrEqualTo(1));
    expect(runs.first.id, billingResult.id);

    // Delinquency reminders
    final remindersSent = await repo.sendDelinquencyReminders();
    expect(remindersSent, greaterThan(0));
  });

  testWidgets('FinanceOverviewScreen renders recurring billing, aging tab, and bulk reminders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinanceOverviewScreen(
            isSuperAdmin: false,
            familyRepository: familyRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header buttons
    expect(find.text('Corte Mensual Recurrente'), findsOneWidget);
    expect(find.text('Registrar Cobro en Caja'), findsOneWidget);

    // Verify tabs
    expect(find.text('Historial de Cobros & Recibos'), findsOneWidget);
    expect(find.textContaining('Reporte de Antigüedad de Cartera'), findsOneWidget);

    // Switch to aging tab
    await tester.tap(find.textContaining('Reporte de Antigüedad de Cartera'));
    await tester.pumpAndSettle();

    // Verify aging buckets and bulk reminder button
    expect(find.text('Corriente (0-30 días)'), findsOneWidget);
    expect(find.text('Vencido (31-60 días)'), findsOneWidget);
    expect(find.text('Mora Crítica (>90 días)'), findsOneWidget);
    expect(find.text('Enviar Recordatorio Masivo a Todos'), findsOneWidget);

    // Tap send reminders
    await tester.tap(find.text('Enviar Recordatorio Masivo a Todos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recordatorios de cobro enviados'), findsOneWidget);
  });

  test('AcademicRepository: manages student grade reports, honors, and grade updates', () async {
    final repo = AcademicRepository();

    // Get all reports
    final reports = await repo.getReports();
    expect(reports.length, greaterThanOrEqualTo(2));

    // Get Mateo's report
    final mateoReport = await repo.getReportForStudent('f0000000-0000-0000-0000-000000000001');
    expect(mateoReport, isNotNull);
    expect(mateoReport!.studentName, 'Mateo Pérez González');
    expect(mateoReport.promedioGeneral, greaterThanOrEqualTo(85.0));
    expect(mateoReport.materias.isNotEmpty, isTrue);

    // Update grade for Mateo
    await repo.updateSubjectGrade(
      reportId: mateoReport.id,
      materia: 'Matemáticas',
      periodo: 1,
      nota: 98,
    );

    final updatedMateo = await repo.getReportForStudent('f0000000-0000-0000-0000-000000000001');
    final math = updatedMateo!.materias.firstWhere((m) => m.materia == 'Matemáticas');
    expect(math.periodo1, 98);

    // Metrics
    final metrics = repo.getAcademicMetrics();
    expect(metrics['promedioGeneral'], greaterThan(80.0));
    expect(metrics['tasaAprobacion'], greaterThanOrEqualTo(90.0));
  });

  testWidgets('AdminGradesScreen renders academic metrics and allows entering period grades', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final academicRepo = AcademicRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminGradesScreen(academicRepository: academicRepo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and KPI metrics
    expect(find.text('Control Académico & Boletín de Notas'), findsOneWidget);
    expect(find.text('Promedio General'), findsOneWidget);
    expect(find.text('Tasa de Aprobación'), findsOneWidget);
    expect(find.text('Cuadro de Honor'), findsOneWidget);

    // Verify students listed
    expect(find.text('Mateo Pérez González'), findsOneWidget);
    expect(find.text('Sofía Pérez González'), findsOneWidget);

    // Open grade entry dialog for Mateo
    final editButtons = find.text('Ver / Calificar');
    expect(editButtons, findsWidgets);
    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();

    // Dialog appears with subjects
    expect(find.text('Desglose por Asignaturas & Períodos Bimestrales:'), findsOneWidget);
    expect(find.text('Matemáticas'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(find.text('Desglose por Asignaturas & Períodos Bimestrales:'), findsNothing);
  });

  testWidgets('ParentGradesScreen renders official report card, GPA, and subject breakdown', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final parentProfile = UserProfile(
      id: 'parent-1',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      rol: UserRole.tutorFamiliar,
      email: 'familia@edunex.edu',
      nombres: 'Roberto',
      apellidos: 'Pérez',
    );

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final academicRepo = AcademicRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentGradesScreen(
            userProfile: parentProfile,
            familyRepository: familyRepo,
            academicRepository: academicRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and report card view
    expect(find.text('Boletín de Calificaciones Oficial'), findsOneWidget);
    expect(find.text('COLEGIO BILINGÜE NUEVO HORIZONTE'), findsOneWidget);
    expect(find.text('Descargar Boletín (PDF)'), findsOneWidget);

    // Verify student selector pills (Mateo and Sofía)
    expect(find.textContaining('Mateo'), findsWidgets);
    expect(find.textContaining('Sofía'), findsWidgets);

    // Verify subjects table
    expect(find.text('Calificaciones Bimestrales por Asignatura:'), findsOneWidget);
    expect(find.text('Matemáticas'), findsOneWidget);
    expect(find.text('Observaciones del Tutor Docente:'), findsOneWidget);

    // Tap Download PDF
    await tester.tap(find.text('Descargar Boletín (PDF)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Generando Boletín Oficial en formato PDF'), findsOneWidget);
  });

  test('FamilyRepository manages questions, answers, and agreement reviews end-to-end', () async {
    final repo = FamilyRepository(useDemoFallback: true);

    // Get all questions
    final allQuestions = await repo.getAllQuestions();
    expect(allQuestions.length, greaterThanOrEqualTo(3));

    // Submit a new question
    final newQ = await repo.submitQuestion(
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      tutorNombre: 'Roberto Pérez',
      departamento: 'Psicología y Orientación',
      asunto: 'Consulta sobre taller para padres',
      mensaje: '¿Cuándo se impartirá el próximo taller de orientación vocacional?',
    );
    expect(newQ.id, startsWith('qst-'));
    expect(newQ.estado, 'En trámite');

    // Answer the question
    final answered = await repo.answerQuestion(
      questionId: newQ.id,
      respuesta: 'El taller será el próximo jueves a las 6:00 PM vía Zoom.',
      respondidoPor: 'Dra. Altagracia Peña (Orientación)',
    );
    expect(answered.estado, 'Respondida');
    expect(answered.respuestaCentro, contains('próximo jueves'));
    expect(answered.respondidoPor, 'Dra. Altagracia Peña (Orientación)');

    // Agreements
    final agreements = await repo.getAllAgreements();
    expect(agreements.isNotEmpty, isTrue);

    // Review agreement
    final pendingAgr = agreements.firstWhere((a) => a.estado == 'En revisión por Dirección');
    final reviewed = await repo.reviewAgreement(
      agreementId: pendingAgr.id,
      approve: true,
      respuestaCentro: 'Aprobado formalmente por Consejo Financiero.',
    );
    expect(reviewed.estado, 'Aprobado');
    expect(reviewed.respuestaCentro, contains('Aprobado formalmente'));
  });

  testWidgets('AdminInquiriesScreen displays inquiries, filters by department, and answers parent question', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminInquiriesScreen(familyRepository: familyRepo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and KPI metrics
    expect(find.text('Atención a Familias & Consultas Escolares'), findsOneWidget);
    expect(find.text('Total de Consultas'), findsOneWidget);
    expect(find.text('Pendientes de Respuesta'), findsOneWidget);
    expect(find.text('Respondidas & Resueltas'), findsOneWidget);
    expect(find.text('Convenios por Revisar'), findsOneWidget);

    // Verify tabs
    expect(find.textContaining('Bandeja de Consultas de Tutores'), findsOneWidget);
    expect(find.textContaining('Solicitudes de Acuerdos de Pago'), findsOneWidget);

    // Verify departments filter chips
    expect(find.text('Todos'), findsWidgets);
    expect(find.text('Dirección Académica'), findsWidgets);
    expect(find.text('Caja y Facturación'), findsWidgets);

    // Open answer dialog
    final replyButtons = find.text('Responder Consulta');
    expect(replyButtons, findsWidgets);
    await tester.ensureVisible(replyButtons.first);
    await tester.tap(replyButtons.first);
    await tester.pumpAndSettle();

    // Dialog appears
    expect(find.text('Enviar Respuesta Oficial'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar Respuesta Oficial'), findsNothing);

    // Switch to Agreements tab
    final agreementsTab = find.textContaining('Solicitudes de Acuerdos de Pago');
    await tester.ensureVisible(agreementsTab);
    await tester.tap(agreementsTab);
    await tester.pumpAndSettle();

    expect(find.textContaining('Propuesta de Cuota Familiar:'), findsWidgets);
  });

  testWidgets('OnlinePaymentGatewayDialog validates card inputs, simulates banking authorization, and records receipt', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final families = await familyRepo.getFamilies();
    final family = families.first;

    bool paymentSucceeded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final receipt = await OnlinePaymentGatewayDialog.show(
                  context: context,
                  family: family,
                  familyRepository: familyRepo,
                  onPaymentSuccess: () => paymentSucceeded = true,
                );
                if (receipt != null && context.mounted) {
                  ReceiptDetailsDialog.show(context, receipt);
                }
              },
              child: const Text('Abrir Pasarela'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open gateway
    await tester.tap(find.text('Abrir Pasarela'));
    await tester.pumpAndSettle();

    // Verify gateway interface
    expect(find.text('Pasarela de Pago Seguro en Línea'), findsOneWidget);
    expect(find.text('TITULAR'), findsOneWidget);
    expect(find.text('EXPIRA'), findsOneWidget);
    expect(find.textContaining('Pagar Balance Total'), findsOneWidget);
    expect(find.textContaining('Encriptación Bancaria 256-Bit SSL'), findsOneWidget);

    // Enter valid card details
    await tester.enterText(find.byType(TextFormField).at(2), '4000123456789010'); // Card Number (Visa)
    await tester.enterText(find.byType(TextFormField).at(3), 'ROBERTO PEREZ'); // Cardholder
    await tester.enterText(find.byType(TextFormField).at(4), '1228'); // Expiry MM/YY
    await tester.enterText(find.byType(TextFormField).at(5), '888'); // CVV
    await tester.pumpAndSettle();

    // Verify card brand updated to VISA
    expect(find.text('VISA'), findsWidgets);

    // Tap Pay button
    final payButton = find.textContaining('Pagar RD\$');
    expect(payButton, findsWidgets);
    await tester.tap(payButton.last);

    // Pump during banking simulation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Verify payment callback and receipt dialog
    expect(paymentSucceeded, isTrue);
    expect(find.textContaining('Comprobante Oficial de Pago'), findsOneWidget);
  });

  test('StoreRepository manages catalog, stock adjustments, orders, and fulfillment end-to-end', () async {
    final repo = StoreRepository();

    // 1. Catalog loading
    final products = await repo.getProducts();
    expect(products.length, greaterThanOrEqualTo(9));
    final polo = products.firstWhere((p) => p.id == 'prod-001');
    expect(polo.name, 'Polo Oficial Institucional EDUNEX');
    final initialStock = polo.stock;

    // 2. Adjust stock
    await repo.adjustStock(productId: 'prod-001', delta: 5);
    final updatedProducts = await repo.getProducts();
    expect(updatedProducts.firstWhere((p) => p.id == 'prod-001').stock, initialStock + 5);

    // 3. Add product
    const newProduct = StoreProduct(
      id: 'prod-test-01',
      colegioId: 'school-001',
      name: 'Gorra Institucional Escolar',
      category: 'Uniformes',
      price: 450.0,
      description: 'Gorra azul marino con logo bordado.',
      sizes: ['Única'],
      stock: 30,
      icon: Icons.dry_cleaning_rounded,
    );
    await repo.addProduct(newProduct);
    final withNewProd = await repo.getProducts();
    expect(withNewProd.any((p) => p.id == 'prod-test-01'), isTrue);

    // 4. Create Order and verify stock decrease
    final initialStockPolo = withNewProd.firstWhere((p) => p.id == 'prod-001').stock;
    final order = await repo.createOrder(
      colegioId: 'school-001',
      familiaId: 'fam-001',
      familiaNombre: 'Familia Pérez Gómez',
      estudianteNombre: 'Mateo Pérez',
      items: const [
        StoreOrderItem(
          productId: 'prod-001',
          productName: 'Polo Oficial Institucional EDUNEX',
          size: 'Talla 8',
          quantity: 2,
          unitPrice: 850.0,
        ),
      ],
      metodoPago: 'Tarjeta de Crédito / CardNET',
      ncf: 'B0200000025',
    );
    expect(order.total, 1700.0);
    expect(order.status, StoreOrderStatus.pendiente);

    final afterOrderProds = await repo.getProducts();
    expect(afterOrderProds.firstWhere((p) => p.id == 'prod-001').stock, initialStockPolo - 2);

    // 5. Update order status to listo and entregado
    await repo.updateOrderStatus(orderId: order.id, newStatus: StoreOrderStatus.listo);
    var currentOrders = await repo.getOrders(familiaId: 'fam-001');
    expect(currentOrders.firstWhere((o) => o.id == order.id).status, StoreOrderStatus.listo);

    await repo.updateOrderStatus(orderId: order.id, newStatus: StoreOrderStatus.entregado);
    currentOrders = await repo.getOrders(familiaId: 'fam-001');
    expect(currentOrders.firstWhere((o) => o.id == order.id).status, StoreOrderStatus.entregado);
    expect(currentOrders.firstWhere((o) => o.id == order.id).fechaEntrega, isNotNull);
  });

  testWidgets('AdminStoreScreen renders catalog metrics, filters categories, adjusts stock, and dispatches orders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storeRepo = StoreRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminStoreScreen(
            storeRepository: storeRepo,
            colegioId: 'school-001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & KPIs
    expect(find.text('Tienda & Uniformes Oficiales'), findsOneWidget);
    expect(find.text('Artículos Catálogo'), findsOneWidget);
    expect(find.text('Stock Físico'), findsOneWidget);
    expect(find.text('Por Despachar'), findsOneWidget);
    expect(find.text('Ventas Tienda'), findsOneWidget);

    // Verify Catalog items rendered
    expect(find.text('Polo Oficial Institucional EDUNEX'), findsOneWidget);
    expect(find.text('Pantalón Escolar Caqui Reforzado'), findsOneWidget);

    // Tap +5 stock on first product
    final plusFiveBtn = find.text('+5');
    expect(plusFiveBtn, findsWidgets);
    await tester.tap(plusFiveBtn.first);
    await tester.pumpAndSettle();

    // Switch to Orders Tab
    await tester.tap(find.textContaining('Pedidos & Despacho a Familias'));
    await tester.pumpAndSettle();

    // Verify orders are displayed
    expect(find.textContaining('Pedido #ord-001'), findsOneWidget);
    expect(find.textContaining('Familia Pérez Gómez'), findsOneWidget);

    // Tap "Confirmar Entrega" on ord-001 (which is in status listo)
    final confirmEntregaBtn = find.text('Confirmar Entrega');
    expect(confirmEntregaBtn, findsWidgets);
    await tester.tap(confirmEntregaBtn.first);
    await tester.pumpAndSettle();

    // Check snackbar
    expect(find.textContaining('¡Pedido formalmente entregado al tutor/alumno!'), findsOneWidget);
  });

  testWidgets('ParentStoreScreen loads catalog from StoreRepository, adds items to cart, and completes checkout creating order', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final storeRepo = StoreRepository();
    final parentUser = UserProfile(
      id: 'usr-parent-01',
      email: 'familia@edunex.edu',
      nombres: 'Roberto',
      apellidos: 'Pérez',
      rol: UserRole.tutorFamiliar,
      colegioId: 'a0000000-0000-0000-0000-000000000001',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentStoreScreen(
            userProfile: parentUser,
            familyRepository: familyRepo,
            storeRepository: storeRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Store Title & Products
    expect(find.text('Tienda Escolar EDUNEX'), findsOneWidget);
    expect(find.text('Mis Pedidos (1)'), findsOneWidget);

    // Add item to cart
    final addButtons = find.text('Agregar');
    expect(addButtons, findsWidgets);
    await tester.tap(addButtons.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Cart button should have updated
    expect(find.textContaining('Carrito (RD\$ 850.00)'), findsOneWidget);

    // Open Cart Modal
    await tester.tap(find.textContaining('Carrito (RD\$ 850.00)'));
    await tester.pumpAndSettle();

    // Complete Checkout
    await tester.tap(find.text('Completar Pedido & Pagar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify Receipt Dialog was triggered
    expect(find.textContaining('Comprobante Oficial de Pago'), findsOneWidget);

    // Verify order was registered in store repository
    final orders = await storeRepo.getOrders(familiaId: 'e0000000-0000-0000-0000-000000000001');
    expect(orders.length, greaterThanOrEqualTo(2));
    expect(orders.first.items.first.productName, 'Polo Oficial Institucional EDUNEX');
  });

  testWidgets('Issue #15: EditSchoolLogoDialog renders presets and updates school logo', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final schoolRepo = SchoolRepository();
    String? selectedLogo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditSchoolLogoDialog(
            schoolId: 'a0000000-0000-0000-0000-000000000001',
            schoolName: 'Colegio Bilingüe San Juan',
            currentLogoUrl: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=150',
            schoolRepository: schoolRepo,
            onLogoUpdated: (newLogo) {
              selectedLogo = newLogo;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dialog header
    expect(find.text('Logo Oficial del Centro'), findsOneWidget);
    expect(find.textContaining('Colegio Bilingüe San Juan'), findsOneWidget);

    // Verify preset emblems
    expect(find.text('Seleccionar Emblema Institucional Recomendado:'), findsOneWidget);

    // Save and verify callback
    await tester.tap(find.text('Guardar Logo de Perfil'));
    await tester.pumpAndSettle();

    expect(selectedLogo, isNotNull);
  });

  test('Issue #17: FamilyRepository manages abono approval requests lifecycle', () async {
    final repo = FamilyRepository();

    // 1. Initial requests count
    final initial = await repo.getAbonoApprovalRequests();
    final initialCount = initial.length;

    // 2. Create approval request
    final req = await repo.createAbonoApprovalRequest(
      familiaId: 'e0000000-0000-0000-0000-000000000001',
      montoAbono: 2500.0,
      motivo: 'Compromiso de pago en dos cuotas quincenales',
      solicitadoPor: 'Cajero de Turno',
    );
    expect(req.id, startsWith('req-abono-'));
    expect(req.estado, PaymentApprovalStatus.pendiente);

    // 3. Verify in pending list
    final pending = await repo.getAbonoApprovalRequests(status: PaymentApprovalStatus.pendiente);
    expect(pending.length, initialCount + 1);

    // 4. Resolve approval (approve)
    final ok = await repo.resolveAbonoApprovalRequest(
      requestId: req.id,
      approve: true,
      revisorNombre: 'Director Financiero',
      notas: 'Autorizado abono parcial por acuerdo previo',
    );
    expect(ok, isTrue);

    // 5. Verify approved abono for family
    final approved = await repo.getApprovedAbonoForFamily('e0000000-0000-0000-0000-000000000001');
    expect(approved, isNotNull);
    expect(approved!.montoAbonoPropuesto, 2500.0);
    expect(approved.estado, PaymentApprovalStatus.aprobado);
  });

  testWidgets('Issue #17: RecordPaymentDialog auto-fills debt, locks input, and enforces abono approval workflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository();
    final family = (await familyRepo.getFamilies()).first;
    final debtStr = family.balancePendiente.toStringAsFixed(2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordPaymentDialog(
            repository: familyRepo,
            initialFamily: family,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify automatic full debt display
    expect(find.text('Deuda Total Pendiente:'), findsOneWidget);
    expect(find.text('Abono familia'), findsOneWidget);
    expect(find.textContaining('RD\$ $debtStr'), findsWidgets);

    // 2. Default button is "Cobrar Deuda Total"
    expect(find.textContaining('Cobrar Deuda Total'), findsOneWidget);

    // 3. Toggle "Abono familia" checkbox
    await tester.tap(find.byKey(const Key('checkbox_abono_familia')));
    await tester.pumpAndSettle();

    // 4. Mode active: motive field is now shown
    expect(find.byKey(const Key('input_motivo_abono')), findsOneWidget);
    expect(find.text('Solicitar Permiso de Abono'), findsOneWidget);

    // 5. Enter motive
    await tester.enterText(find.byKey(const Key('input_motivo_abono')), 'Acuerdo firmado en dirección para pago en 2 partes');
    await tester.pumpAndSettle();

    // 6. Submit abono permission request
    await tester.tap(find.byKey(const Key('btn_submit_pago_abono')));
    await tester.pumpAndSettle();

    // 7. Verify permission sent confirmation dialog
    expect(find.text('Solicitud de Permiso Enviada'), findsOneWidget);
    expect(find.textContaining('Por directriz del centro, no se puede cobrar abonos sin previa autorización'), findsOneWidget);
  });

  testWidgets('Issue #17: FinanceOverviewScreen allows administrator to approve abono request', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinanceOverviewScreen(
            isSuperAdmin: false,
            familyRepository: familyRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Switch to Autorizaciones Abonos tab
    expect(find.byKey(const Key('tab_autorizaciones_abonos')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab_autorizaciones_abonos')));
    await tester.pumpAndSettle();

    // 2. Verify bandeja header
    expect(find.text('Bandeja de Autorizaciones de Abonos'), findsOneWidget);
    expect(find.text('Aprobar Abono'), findsWidgets);

    // 3. Scroll to approve button and approve first pending request
    final approveButtons = find.text('Aprobar Abono');
    await tester.ensureVisible(approveButtons.first);
    await tester.pumpAndSettle();

    await tester.tap(approveButtons.first);
    await tester.pumpAndSettle();

    // 4. Verify snackbar confirmation
    expect(find.text('Abono autorizado correctamente.'), findsOneWidget);
  });

  testWidgets('Issue #18: CreateSchoolDialog enforces Director Cedula field and validates Dominican format', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final schoolRepo = SchoolRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateSchoolDialog(schoolRepository: schoolRepo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Dialog Title
    expect(find.textContaining('Nuevo Colegio Cliente'), findsOneWidget);

    // 2. Locate Director Cédula field
    final cedulaField = find.byKey(const Key('input_director_cedula'));
    expect(cedulaField, findsOneWidget);
    expect(find.textContaining('Cédula de Identidad del Director'), findsOneWidget);

    // 3. Fill required fields with invalid cédula first
    await tester.ensureVisible(cedulaField);
    await tester.enterText(cedulaField, '12345');

    final submitBtn = find.text('Dar de Alta Colegio y Director');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // 4. Expect validation error for invalid cédula
    expect(find.textContaining('La cédula debe contener 11 dígitos'), findsOneWidget);

    // 5. Enter valid cédula
    await tester.enterText(cedulaField, '001-1234567-8');
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(find.textContaining('La cédula debe contener 11 dígitos'), findsNothing);
  });

  testWidgets('Issue #19: CreateFamilyDialog manages multi-tutors, pickup authorizations, and student documents', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateFamilyDialog(repository: familyRepo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Tab 1: Verify "+ Agregar Tutor / Autorizado" button exists (Issue #19)
    final addTutorBtn = find.byKey(const Key('btn_add_another_tutor'));
    expect(addTutorBtn, findsOneWidget);
    await tester.ensureVisible(addTutorBtn);
    await tester.tap(addTutorBtn);
    await tester.pumpAndSettle();

    // 2. Verify additional tutor card appears
    expect(find.text('Tutor / Autorizado #1'), findsOneWidget);
    expect(find.text('Persona autorizada formalmente para retirar alumnos del colegio'), findsOneWidget);

    // 3. Switch to Tab 2: Alumnos
    await tester.tap(find.textContaining('2. Alumnos'));
    await tester.pumpAndSettle();

    // 4. Verify interactive document dossier manager button exists (Issue #19)
    final docUploadBtn = find.byKey(const Key('btn_cargar_expediente_demo_0'));
    expect(docUploadBtn, findsOneWidget);
    expect(find.textContaining('Documentos del Expediente Escolar & Carga Digital'), findsOneWidget);

    // 5. Click to upload/manage document
    await tester.ensureVisible(docUploadBtn);
    await tester.tap(docUploadBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 6. Verify notification and attached document badge
    expect(find.text('Documento actualizado en el expediente del estudiante.'), findsOneWidget);
  });

  testWidgets('Issue #19: FamilyDetailDialog allows adding dynamic tutors and uploading student documents', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    final family = (await familyRepo.getFamilies()).first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FamilyDetailDialog(family: family, repository: familyRepo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify detail dialog rendered
    expect(find.text(family.nombreFamilia), findsWidgets);

    // 2. Verify "+ Agregar Tutor / Autorizado" button in detail dialog (Issue #19)
    final addTutorBtn = find.byKey(const Key('btn_add_tutor_detail'));
    expect(addTutorBtn, findsOneWidget);
    await tester.ensureVisible(addTutorBtn);
    await tester.tap(addTutorBtn);
    await tester.pumpAndSettle();

    // 3. Verify Add Tutor dialog opened
    expect(find.text('Agregar Tutor o Autorizado'), findsOneWidget);
    expect(find.byKey(const Key('btn_submit_add_tutor')), findsOneWidget);

    // 4. Close modal
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // 5. Verify student document attachment button
    final firstStudent = family.estudiantes.first;
    expect(find.byKey(Key('btn_adjuntar_doc_${firstStudent.id}')), findsOneWidget);
  });

  testWidgets('Issue #16: DashboardOverviewScreen renders quick action Enrolar Familia', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardOverviewScreen(
          familyRepository: familyRepo,
          onNavigateToFamilies: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify quick action button for enrolling family exists
    expect(find.byKey(const Key('btn_quick_enrolar_familia')), findsOneWidget);
    expect(find.text('Enrolar Familia'), findsOneWidget);
  });

  testWidgets('Issue #16: ParentPortalScreen shows isolated empty state without leaking other families', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final familyRepo = FamilyRepository(useDemoFallback: true);
    // Non-existent or new tutor
    final unlinkedTutor = UserProfile(
      id: 'tutor-nonexistent',
      colegioId: 'a0000000-0000-0000-0000-000000000001',
      rol: UserRole.tutorFamiliar,
      email: 'tutor.nuevo.sin.familia@gmail.com',
      nombres: 'Tutor',
      apellidos: 'Prueba',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParentPortalScreen(
          userProfile: unlinkedTutor,
          familyRepository: familyRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify it does NOT leak other families
    expect(find.text('Familia Pérez González'), findsNothing);
    expect(find.byKey(const Key('card_tutor_no_family_found')), findsOneWidget);
    expect(find.text('No se encontró cuenta familiar asociada'), findsOneWidget);
  });

  test('QA Clean Slate: clearAllData clears repository state completely', () async {
    // 1. Verify clearAllData on SchoolRepository
    final schoolRepo = SchoolRepository(useDemoFallback: true);
    expect((await schoolRepo.getSchools()).isNotEmpty, isTrue);
    SchoolRepository.clearAllData();
    expect((await schoolRepo.getSchools()).isEmpty, isTrue);

    // 2. Verify clearAllData on FamilyRepository
    final familyRepo = FamilyRepository(useDemoFallback: true);
    expect((await familyRepo.getFamilies()).isNotEmpty, isTrue);
    FamilyRepository.clearAllData();
    expect((await familyRepo.getFamilies()).isEmpty, isTrue);

    // 3. Verify clearAllData and restore on TeacherRepository
    TeacherRepository.restoreSeedData();
    final teacherRepo = TeacherRepository(useDemoFallback: true);
    expect((await teacherRepo.getClasses(docenteId: 'docente-001')).isNotEmpty, isTrue);
    TeacherRepository.clearAllData();
    expect((await teacherRepo.getClasses(docenteId: 'docente-001')).isEmpty, isTrue);
    TeacherRepository.restoreSeedData();
    expect((await teacherRepo.getClasses(docenteId: 'docente-001')).isNotEmpty, isTrue);

    // 4. Verify clearAllData and restore on GuidanceRepository
    GuidanceRepository.restoreSeedData();
    final guidanceRepo = GuidanceRepository(useDemoFallback: true);
    expect((await guidanceRepo.getCases()).isNotEmpty, isTrue);
    GuidanceRepository.clearAllData();
    expect((await guidanceRepo.getCases()).isEmpty, isTrue);
    GuidanceRepository.restoreSeedData();
    expect((await guidanceRepo.getCases()).isNotEmpty, isTrue);

    // Restore seed data for subsequent tests
    SchoolRepository.restoreSeedData();
    FamilyRepository.restoreSeedData();
  });

  group('Teacher Portal - Unit Tests', () {
    test('TeacherRepository calculates weighted period averages and publishes to AcademicRepository', () async {
      TeacherRepository.restoreSeedData();
      final teacherRepo = TeacherRepository(useDemoFallback: true);
      final academicRepo = AcademicRepository();

      final classes = await teacherRepo.getClasses(docenteId: 'docente-001');
      expect(classes.isNotEmpty, isTrue);
      final testClass = classes.first;

      // Create a 20% Quiz evaluation
      final newEval = await teacherRepo.createEvaluation(
        classId: testClass.id,
        periodo: 'P1',
        titulo: 'Examen Diagnóstico',
        tipo: 'Quiz',
        porcentaje: 20.0,
        fecha: DateTime.now(),
      );
      expect(newEval.id.isNotEmpty, isTrue);

      // Score the first student
      final studentId = testClass.estudiantes.first.id;
      await teacherRepo.saveStudentScores(newEval.id, {studentId: 95.0});

      // Calculate period averages
      final averages = await teacherRepo.calculatePeriodAverages(testClass.id, 'P1');
      expect(averages.containsKey(studentId), isTrue);
      expect(averages[studentId]! > 0, isTrue);

      // Publish grades to AcademicRepository
      await teacherRepo.publishPeriodGradesToAcademic(
        classId: testClass.id,
        periodo: 'P1',
        academicRepo: academicRepo,
      );

      final report = await academicRepo.getReportForStudent(studentId);
      if (report != null) {
        final sub = report.materias.firstWhere((a) => a.materia.toLowerCase().contains('mat'));
        expect(sub.periodo1, isNotNull);
      }
    });

    test('TeacherRepository records class attendance and behavior logs correctly', () async {
      TeacherRepository.restoreSeedData();
      final teacherRepo = TeacherRepository(useDemoFallback: true);
      final attendanceRepo = AttendanceRepository();

      final classes = await teacherRepo.getClasses(docenteId: 'docente-001');
      final testClass = classes.first;
      final student = testClass.estudiantes.first;

      // Record attendance
      await teacherRepo.recordClassAttendance(
        classId: testClass.id,
        fecha: DateTime(2026, 3, 20),
        statuses: {student.id: 'Tardanza'},
        attendanceRepo: attendanceRepo,
      );

      final studentAttendance = await attendanceRepo.getAttendanceForStudent(student.id);
      expect(studentAttendance.any((r) => r.estado == 'Tardanza'), isTrue);

      // Add behavior observation log
      final log = await teacherRepo.addBehaviorLog(
        classId: testClass.id,
        studentId: student.id,
        studentName: student.nombreCompleto,
        grado: testClass.grado,
        docenteId: 'docente-001',
        docenteNombre: 'Prof. María González',
        tipo: 'Mérito / Felicitación',
        categoria: 'Académico',
        descripcion: 'Excelente desempeño en resolución de problemas matemáticos',
        notificadoTutor: true,
        notificadoPsicologia: false,
      );
      expect(log.id.isNotEmpty, isTrue);

      final logs = await teacherRepo.getBehaviorLogs(classId: testClass.id);
      expect(logs.any((l) => l.studentId == student.id), isTrue);
    });
  });

  group('Teacher Portal - Widget Tests', () {
    testWidgets('MainShell renders TeacherPortalScreen for UserRole.docente with 4 tabs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      TeacherRepository.restoreSeedData();
      final teacherRepo = TeacherRepository(useDemoFallback: true);
      final academicRepo = AcademicRepository();
      final attendanceRepo = AttendanceRepository();

      final teacherUser = UserProfile(
        id: 'docente-001',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        rol: UserRole.docente,
        email: 'docente@edunex.edu.do',
        nombres: 'María',
        apellidos: 'González',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            userProfile: teacherUser,
            teacherRepository: teacherRepo,
            academicRepository: academicRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Teacher Nav Items
      expect(find.text('Libro de Clases'), findsWidgets);
      expect(find.text('Calificador de Aula'), findsWidgets);
      expect(find.text('Pase de Lista'), findsWidgets);
      expect(find.text('Observador & Convivencia'), findsWidgets);

      // Verify default tab (Libro de Clases) content
      expect(find.textContaining('Horario Pedagógico'), findsOneWidget);
      expect(find.text('Matemáticas'), findsWidgets);

      // Switch to Calificador de Aula
      await tester.tap(find.text('Calificador de Aula').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Período Académico'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_evaluacion')), findsOneWidget);

      // Open Add Evaluation Modal
      await tester.tap(find.byKey(const Key('btn_add_evaluacion')));
      await tester.pumpAndSettle();
      expect(find.text('Nueva Evaluación Pedagógica'), findsOneWidget);

      // Fill and submit evaluation
      await tester.enterText(find.byKey(const Key('input_eval_title')), 'Práctica Semana 4');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_submit_eval')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Práctica Semana 4'), findsWidgets);

      // Switch to Pase de Lista
      await tester.tap(find.text('Pase de Lista').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Fecha de Clase'), findsOneWidget);
      expect(find.byKey(const Key('btn_guardar_asistencia_docente')), findsOneWidget);

      // Switch to Observador & Convivencia
      await tester.tap(find.text('Observador & Convivencia').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Filtro:'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_observacion_docente')), findsOneWidget);
    });
  });

  group('Psychology & Guidance - Unit Tests', () {
    test('GuidanceRepository manages cases, sessions, parent interviews and agreements', () async {
      GuidanceRepository.restoreSeedData();
      final repo = GuidanceRepository(useDemoFallback: true);

      // Create new case
      final newCase = await repo.createCase(
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        studentId: 'stud-test-01',
        studentName: 'Gabriel Santos',
        matricula: 'EST-2026-99',
        grado: '3ro de Primaria',
        seccion: 'Sección A',
        remitidoPor: 'Prof. Carlos Ramírez',
        motivoRemision: 'Aislamiento social y dificultades de integración en el recreo',
        nivelUrgencia: 'Alta',
      );
      expect(newCase.id.isNotEmpty, isTrue);

      // Add session
      final withSession = await repo.addSession(
        newCase.id,
        GuidanceSession(
          id: 'ses-test',
          fecha: DateTime.now(),
          tipo: 'Individual con Alumno',
          notasConfidenciales: 'Estudiante expresa timidez y ansiedad al interactuar.',
          acuerdos: 'Participación en dinámicas grupales guiadas.',
          profesionalACargo: 'Lic. Laura Medina',
        ),
      );
      expect(withSession.sesiones.length, 1);
      expect(withSession.estado, 'En Intervención');

      // Schedule interview
      final withInterview = await repo.scheduleParentInterview(
        newCase.id,
        ParentInterview(
          id: 'cita-test',
          fecha: DateTime.now().add(const Duration(days: 3)),
          hora: '10:00 AM',
          modalidad: 'Presencial',
          motivo: 'Entrevista de seguimiento con tutores',
          estado: 'Programada',
        ),
      );
      expect(withInterview.citasPadres.length, 1);
      expect(withInterview.estado, 'Citación a Tutores');

      // Add agreement and toggle status
      final withAgreement = await repo.addAgreement(
        newCase.id,
        ConvivenciaAgreement(
          id: 'agr-test',
          fecha: DateTime.now(),
          descripcion: 'Fomentar actividades extracurriculares artísticas',
          responsable: 'Padres / Tutores',
          cumplido: false,
        ),
      );
      expect(withAgreement.compromisos.length, 1);

      final toggled = await repo.toggleAgreementStatus(newCase.id, 'agr-test');
      expect(toggled.compromisos.first.cumplido, isTrue);

      // Verify stats
      final stats = await repo.getStats('a0000000-0000-0000-0000-000000000001');
      expect(stats['totalCasos']! >= 3, isTrue);
      expect(stats['casosActivos']! >= 3, isTrue);
    });

    test('GuidanceRepository creates case seamlessly from teacher behavior log referral', () async {
      GuidanceRepository.restoreSeedData();
      final repo = GuidanceRepository(useDemoFallback: true);

      final behaviorLog = StudentBehaviorLog(
        id: 'log-099',
        classId: 'class-cie-2b',
        studentId: 'stud-ref-001',
        studentName: 'Camila Peña',
        grado: '2do de Primaria',
        docenteId: 'docente-001',
        docenteNombre: 'Prof. Carlos Ramírez',
        tipo: 'Remisión a Psicología',
        categoria: 'Conducta',
        descripcion: 'Crisis de llanto recurrente ante evaluaciones escritas.',
        fecha: DateTime.now(),
        notificadoTutor: true,
        notificadoPsicologia: true,
      );

      final createdCase = await repo.createCaseFromTeacherLog(
        log: behaviorLog,
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        matricula: 'EST-2026-88',
        seccion: 'Sección B',
      );

      expect(createdCase.studentName, 'Camila Peña');
      expect(createdCase.motivoRemision, contains('Crisis de llanto'));
      expect(createdCase.esActivo, isTrue);
    });
  });

  group('Psychology & Guidance - Widget Tests', () {
    testWidgets('MainShell renders GuidanceManagementScreen with KPIs, cases list and modals', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      GuidanceRepository.restoreSeedData();
      final guidanceRepo = GuidanceRepository(useDemoFallback: true);

      final adminUser = UserProfile(
        id: 'dir-001',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        rol: UserRole.adminColegio,
        email: 'director@colegio.edu.do',
        nombres: 'Roberto',
        apellidos: 'Santos',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            userProfile: adminUser,
            guidanceRepository: guidanceRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Psicología & Convivencia (Nav item)
      final guidanceNavItem = find.text('Psicología & Convivencia');
      await tester.scrollUntilVisible(guidanceNavItem, 100.0, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(guidanceNavItem, findsOneWidget);
      await tester.tap(guidanceNavItem);
      await tester.pumpAndSettle();

      // Verify Screen Header and KPIs
      expect(find.text('Psicología & Convivencia Escolar'), findsOneWidget);
      expect(find.text('Casos Activos'), findsOneWidget);
      expect(find.text('Urgencia Alta'), findsWidgets);
      expect(find.text('Citas a Familias'), findsOneWidget);

      // Verify Cases List
      expect(find.text('Mateo Pérez González'), findsOneWidget);
      expect(find.text('Lucas Gómez'), findsOneWidget);

      // Open new case modal
      await tester.tap(find.byKey(const Key('btn_nuevo_caso_psicologia')));
      await tester.pumpAndSettle();
      expect(find.text('Registrar Nuevo Caso de Orientación'), findsOneWidget);

      // Enter student details
      await tester.enterText(find.byKey(const Key('input_guidance_student_name')), 'Ana Sofía Rivas');
      await tester.enterText(find.byKey(const Key('input_guidance_matricula')), 'EST-2026-77');
      await tester.enterText(find.byKey(const Key('input_guidance_motivo')), 'Dificultad de aprendizaje en lectoescritura.');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_submit_guidance_case')));
      await tester.pumpAndSettle();

      // Verify case added
      expect(find.text('Ana Sofía Rivas'), findsOneWidget);

      // Open expediente for Mateo Pérez (case-001)
      final btnExpediente = find.byKey(const Key('btn_ver_expediente_case-001'));
      expect(btnExpediente, findsOneWidget);
      await tester.ensureVisible(btnExpediente);
      await tester.pumpAndSettle();
      await tester.tap(btnExpediente);
      await tester.pumpAndSettle();

      // Verify dialog header
      expect(find.textContaining('Expediente: Mateo Pérez González'), findsOneWidget);
      expect(find.text('Sesiones'), findsOneWidget);
      expect(find.text('Citaciones Tutores'), findsOneWidget);
      expect(find.text('Acuerdos Convivencia'), findsOneWidget);

      // Switch to Acuerdos Convivencia
      await tester.tap(find.text('Acuerdos Convivencia'));
      await tester.pumpAndSettle();
      expect(find.text('Ubicación preferencial en primera fila cerca de la pizarra'), findsOneWidget);

      // Close Dialog
      await tester.tap(find.text('Cerrar Expediente'));
      await tester.pumpAndSettle();
    });
  });

  group('Issue #19 - Expediente escolar y tutores autorizados en matrícula y directorio', () {
    setUp(() {
      FamilyRepository.restoreSeedData();
    });

    testWidgets('EnrollStudentDialog allows uploading documents and adding extra tutors', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final familyRepo = FamilyRepository(useDemoFallback: true);
      final families = await familyRepo.getFamilies();
      final family = families.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnrollStudentDialog(
              repository: familyRepo,
              initialFamily: family,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section header for expediente documents
      expect(find.text('Documentos para el Expediente Escolar (Issue #19)'), findsOneWidget);
      expect(find.text('Tutores y Personas Autorizadas (Issue #19)'), findsOneWidget);

      // Toggle document checkboxes
      final checkActa = find.byKey(const Key('checkbox_doc_Acta de Nacimiento'));
      await tester.ensureVisible(checkActa);
      await tester.pumpAndSettle();
      await tester.tap(checkActa);
      await tester.pumpAndSettle();

      final checkFoto = find.byKey(const Key('checkbox_doc_Foto 2x2'));
      await tester.ensureVisible(checkFoto);
      await tester.pumpAndSettle();
      await tester.tap(checkFoto);
      await tester.pumpAndSettle();

      // Open Add Tutor modal
      final btnAddTutor = find.byKey(const Key('btn_enroll_add_tutor'));
      await tester.ensureVisible(btnAddTutor);
      await tester.pumpAndSettle();
      await tester.tap(btnAddTutor);
      await tester.pumpAndSettle();

      expect(find.text('Agregar Tutor o Persona Autorizada'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('input_tutor_names')), 'Carmen');
      await tester.enterText(find.byKey(const Key('input_tutor_lastnames')), 'González');
      await tester.enterText(find.byKey(const Key('input_tutor_phone')), '809-555-8888');
      await tester.enterText(find.byKey(const Key('input_tutor_email')), 'carmen@ejemplo.com');
      await tester.tap(find.byKey(const Key('btn_submit_enroll_tutor')));
      await tester.pumpAndSettle();

      // Verify tutor added in preview list
      expect(find.text('Carmen González (Madre)'), findsOneWidget);

      // Enter student names
      final inputNames = find.byKey(const Key('input_enroll_student_names'));
      await tester.ensureVisible(inputNames);
      await tester.pumpAndSettle();
      await tester.enterText(inputNames, 'Diego');
      await tester.enterText(find.byKey(const Key('input_enroll_student_apellidos')), 'Pérez González');
      await tester.pumpAndSettle();

      // Submit enrollment
      final btnSubmit = find.byKey(const Key('btn_enroll_submit_student'));
      await tester.ensureVisible(btnSubmit);
      await tester.pumpAndSettle();
      await tester.tap(btnSubmit);
      await tester.pumpAndSettle();

      // Verify success screen shows documents and tutors
      expect(find.text('¡Matrícula Asignada con Éxito!'), findsOneWidget);
      expect(find.textContaining('documentos oficiales vinculados'), findsOneWidget);
      expect(find.textContaining('Tutores/Autorizados adicionales: Carmen González (Madre)'), findsOneWidget);
      expect(find.byKey(const Key('btn_success_ver_expediente_completo')), findsOneWidget);

      // Verify student and tutor persisted in repository
      final updatedFamily = await familyRepo.getFamilyById(family.id);
      expect(updatedFamily, isNotNull);
      final enrolledStudent = updatedFamily!.estudiantes.firstWhere((s) => s.nombres == 'Diego');
      expect(enrolledStudent.documentos.length, 2);
      expect(updatedFamily.tutores.any((t) => t.nombres == 'Carmen'), isTrue);
    });

    testWidgets('FamilyDirectoryScreen displays Expediente button and FamilyDetailDialog persists attached docs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final familyRepo = FamilyRepository(useDemoFallback: true);
      final families = await familyRepo.getFamilies();
      final family = families.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyDirectoryScreen(repository: familyRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Expediente & Tutores button on card
      final btnExpediente = find.byKey(Key('btn_ver_expediente_${family.id}'));
      expect(btnExpediente, findsOneWidget);
      await tester.tap(btnExpediente);
      await tester.pumpAndSettle();

      // FamilyDetailDialog is opened
      expect(find.textContaining(family.nombreFamilia), findsWidgets);
      expect(find.textContaining('Expediente Escolar'), findsWidgets);

      // Verify student docs can be attached and saved
      final student = family.estudiantes.first;
      final newDoc = StudentDocument(
        id: 'doc-test-1',
        tipo: 'certificado_medico',
        nombreArchivo: 'Certificado_Medico_Test.pdf',
        tamanoBytes: 1024 * 1024,
        fechaSubida: DateTime.now(),
      );
      await familyRepo.addDocumentToStudent(studentId: student.id, document: newDoc);
      final refreshedFamily = await familyRepo.getFamilyById(family.id);
      final refreshedStudent = refreshedFamily!.estudiantes.firstWhere((s) => s.id == student.id);
      expect(refreshedStudent.documentos.any((d) => d.id == 'doc-test-1'), isTrue);
    });
  });
}





