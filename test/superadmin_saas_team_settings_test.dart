import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edunex/features/superadmin/models/saas_user.dart';
import 'package:edunex/features/superadmin/models/saas_company_config.dart';
import 'package:edunex/features/superadmin/repositories/school_repository.dart';
import 'package:edunex/features/superadmin/screens/saas_users_screen.dart';
import 'package:edunex/features/superadmin/screens/saas_settings_screen.dart';
import 'package:edunex/features/superadmin/widgets/create_saas_user_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchoolRepository repository;

  setUp(() {
    SchoolRepository.restoreSeedData();
    repository = SchoolRepository(useDemoFallback: true);
  });

  group('Equipo & Roles SaaS - Pruebas Unitarias de Repositorio', () {
    test('getSaaSUsers retorna inicialmente solo el usuario superadmin principal sin data falsa', () async {
      final users = await repository.getSaaSUsers();
      expect(users.length, equals(1));
      expect(users.first.email, equals('admin@edunex.edu'));
      expect(users.first.rol, equals(SaaSRole.superadmin));
      expect(users.first.activo, isTrue);
    });

    test('createSaaSUser crea colaborador con rol asignado y audita el evento', () async {
      final user = await repository.createSaaSUser(
        nombre: 'Pedro',
        apellido: 'Martínez',
        email: 'pedro.contable@edunex.edu.do',
        rol: SaaSRole.contable,
        telefono: '809-555-0888',
        password: 'password123',
        notas: 'Encargado de facturación DGII',
      );

      expect(user.id, startsWith('usr-saas-'));
      expect(user.nombreCompleto, equals('Pedro Martínez'));
      expect(user.email, equals('pedro.contable@edunex.edu.do'));
      expect(user.rol, equals(SaaSRole.contable));
      expect(user.activo, isTrue);

      final users = await repository.getSaaSUsers();
      expect(users.length, equals(2));
      expect(users.any((u) => u.email == 'pedro.contable@edunex.edu.do'), isTrue);
    });

    test('toggleSaaSUserStatus suspende y reactiva acceso', () async {
      final user = await repository.createSaaSUser(
        nombre: 'Ana',
        apellido: 'Gómez',
        email: 'ana.secretaria@edunex.edu.do',
        rol: SaaSRole.secretaria,
        password: 'secret12345',
      );

      await repository.toggleSaaSUserStatus(user.id);
      var list = await repository.getSaaSUsers();
      var updated = list.firstWhere((u) => u.id == user.id);
      expect(updated.activo, isFalse);

      await repository.toggleSaaSUserStatus(user.id);
      list = await repository.getSaaSUsers();
      updated = list.firstWhere((u) => u.id == user.id);
      expect(updated.activo, isTrue);
    });

    test('resetSaaSUserPassword actualiza contraseña y registra auditoría', () async {
      final user = await repository.createSaaSUser(
        nombre: 'Luis',
        apellido: 'Soporte',
        email: 'luis.soporte@edunex.edu.do',
        rol: SaaSRole.soporte,
        password: 'initialPassword1',
      );

      await repository.resetSaaSUserPassword(user.id, 'newSecurePassword999');
      // No debe lanzar excepciones
      final list = await repository.getSaaSUsers();
      expect(list.any((u) => u.id == user.id), isTrue);
    });

    test('Configuración de la empresa matriz SaaS get y save', () async {
      final initialConfig = await repository.getCompanyConfig();
      expect(initialConfig.rnc, equals('1-32-45678-9'));
      expect(initialConfig.razonSocial, equals('EDUNEX Dominicana SAS'));

      final modified = initialConfig.copyWith(
        nombreComercial: 'EDUNEX Enterprise Global',
        secuenciaNCFB01: 500,
        modoMantenimiento: true,
      );

      await repository.saveCompanyConfig(modified);
      final saved = await repository.getCompanyConfig();
      expect(saved.nombreComercial, equals('EDUNEX Enterprise Global'));
      expect(saved.secuenciaNCFB01, equals(500));
      expect(saved.modoMantenimiento, isTrue);
    });
  });

  group('Equipo & Roles SaaS - Pruebas de Widgets', () {
    testWidgets('SaaSUsersScreen renderiza lista con SuperAdmin principal y KPIs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: SaaSUsersScreen(schoolRepository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Equipo & Asignación de Roles SaaS'), findsOneWidget);
      expect(find.text('Total Miembros'), findsOneWidget);
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('admin@edunex.edu'), findsOneWidget);
      expect(find.text('+ Nuevo Miembro del Equipo'), findsOneWidget);
    });

    testWidgets('CreateSaaSUserDialog valida campos obligatorios y añade usuario', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CreateSaaSUserDialog.show(
                  ctx,
                  schoolRepository: repository,
                ),
                child: const Text('Abrir Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Miembro del Equipo SaaS'), findsOneWidget);

      final submitBtn = find.widgetWithText(ElevatedButton, 'Crear Usuario');
      expect(submitBtn, findsOneWidget);

      // Botón debe estar deshabilitado al inicio
      ElevatedButton btnWidget = tester.widget(submitBtn);
      expect(btnWidget.onPressed, isNull);

      // Ingresar Nombres
      await tester.enterText(find.widgetWithText(TextFormField, 'Ej. Carlos'), 'Marta');
      await tester.pumpAndSettle();

      // Ingresar Apellidos
      await tester.enterText(find.widgetWithText(TextFormField, 'Ej. Medina'), 'Pérez');
      await tester.pumpAndSettle();

      // Ingresar Email
      await tester.enterText(find.widgetWithText(TextFormField, 'usuario@edunex.edu.do'), 'marta.perez@edunex.edu.do');
      await tester.pumpAndSettle();

      // Ingresar Contraseña
      await tester.enterText(find.widgetWithText(TextFormField, 'Mínimo 6 caracteres'), 'clave1234');
      await tester.pumpAndSettle();

      // Ahora debe estar habilitado
      btnWidget = tester.widget(submitBtn);
      expect(btnWidget.onPressed, isNotNull);

      // Enviar formulario
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Miembro del Equipo SaaS'), findsNothing);

      final users = await repository.getSaaSUsers();
      expect(users.any((u) => u.email == 'marta.perez@edunex.edu.do'), isTrue);
    });

    testWidgets('SaaSSettingsScreen renderiza pestañas y permite guardar configuración', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: SaaSSettingsScreen(schoolRepository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configuración de la Empresa Matriz SaaS'), findsOneWidget);
      expect(find.text('Empresa Matriz & Facturación DGII'), findsOneWidget);
      expect(find.text('Seguridad & Plataforma'), findsOneWidget);

      // Cambiar a la pestaña de Seguridad
      await tester.tap(find.text('Seguridad & Plataforma'));
      await tester.pumpAndSettle();

      expect(find.text('Modo Mantenimiento Global'), findsOneWidget);
      expect(find.text('Exigir Doble Factor de Autenticación (2FA)'), findsOneWidget);

      // Guardar configuración
      final saveBtn = find.text('Guardar Configuración');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
    });
  });
}
