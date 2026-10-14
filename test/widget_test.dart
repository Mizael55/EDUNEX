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
import 'package:edunex/features/parent_portal/widgets/receipt_details_dialog.dart';
import 'package:edunex/screens/login_screen.dart';
import 'package:edunex/screens/main_shell.dart';

void main() {
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
}

