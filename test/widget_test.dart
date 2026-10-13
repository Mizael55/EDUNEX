import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edunex/main.dart';
import 'package:edunex/features/auth/models/user_profile.dart';
import 'package:edunex/features/auth/models/user_role.dart';
import 'package:edunex/features/families/repositories/family_repository.dart';
import 'package:edunex/features/superadmin/repositories/school_repository.dart';
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

    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(userProfile: parentProfile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Roberto Pérez!'), findsOneWidget);
    expect(find.text('PORTAL DE PADRES'), findsOneWidget);
    expect(find.textContaining('Mis Hijos Matriculados'), findsOneWidget);
  });

  test('FamilyRepository loads pilot families correctly', () async {
    final repo = FamilyRepository();
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
}
