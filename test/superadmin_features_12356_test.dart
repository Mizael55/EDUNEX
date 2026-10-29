import 'package:flutter_test/flutter_test.dart';
import 'package:edunex/features/superadmin/models/school.dart';
import 'package:edunex/features/superadmin/models/saas_invoice.dart';
import 'package:edunex/features/superadmin/models/system_announcement.dart';
import 'package:edunex/features/superadmin/repositories/school_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchoolRepository repository;

  setUp(() {
    SchoolRepository.restoreSeedData();
    repository = SchoolRepository(useDemoFallback: true);
  });

  group('Item 1: Cobranza SaaS y Facturas a Colegios con NCF', () {
    test('generateSaaSInvoice genera factura con NCF B01/B02 y estado pendiente', () async {
      final invoice = await repository.generateSaaSInvoice(
        schoolId: 'a0000000-0000-0000-0000-000000000001',
        schoolName: 'Colegio Bilingüe EDUNEX Piloto',
        monto: 7000.0,
        periodo: 'Noviembre 2026',
        rnc: '1-31-00000-1',
        tipoNCF: 'B01',
        diasGracia: 15,
      );

      expect(invoice.id, startsWith('inv-saas-'));
      expect(invoice.monto, equals(7000.0));
      expect(invoice.periodo, equals('Noviembre 2026'));
      expect(invoice.tipoNCF, equals('B01'));
      expect(invoice.ncf, startsWith('B01'));
      expect(invoice.estado, equals(SaaSInvoiceStatus.pendiente));
      expect(invoice.isPaid, isFalse);
    });

    test('recordInvoicePayment registra cobro y cambia estado a pagada', () async {
      final invoice = await repository.generateSaaSInvoice(
        schoolId: 'a0000000-0000-0000-0000-000000000001',
        schoolName: 'Colegio Bilingüe EDUNEX Piloto',
        monto: 7000.0,
        periodo: 'Noviembre 2026',
      );

      await repository.recordInvoicePayment(
        invoiceId: invoice.id,
        metodoPago: 'Transferencia Bancaria BHD',
        notas: 'Referencia #449210',
      );

      final invoices = await repository.getSaaSInvoices(schoolId: 'a0000000-0000-0000-0000-000000000001');
      final updated = invoices.firstWhere((i) => i.id == invoice.id);

      expect(updated.estado, equals(SaaSInvoiceStatus.pagada));
      expect(updated.isPaid, isTrue);
      expect(updated.metodoPago, equals('Transferencia Bancaria BHD'));
      expect(updated.fechaPago, isNotNull);
    });
  });

  group('Item 2: Gestión de Periodos de Prueba (Trials) & Conversión', () {
    test('School calcula trialDiasRestantes y isTrial correctamente', () {
      final trialSchool = School(
        id: 'trial-1',
        nombre: 'Colegio en Prueba',
        estadoSuscripcion: 'trial',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(trialSchool.isTrial, isTrue);
      expect(trialSchool.trialDiasRestantes, greaterThanOrEqualTo(9));
      expect(trialSchool.trialDiasRestantes, lessThanOrEqualTo(10));
    });

    test('extendSchoolTrial amplía los días de prueba del colegio', () async {
      final schoolId = 'a0000000-0000-0000-0000-000000000003'; // St. Patrick (trial)
      final before = await repository.getSchoolById(schoolId);
      final beforeDias = before!.trialDiasRestantes;

      await repository.extendSchoolTrial(schoolId, 15);

      final after = await repository.getSchoolById(schoolId);
      expect(after!.trialDiasRestantes, greaterThanOrEqualTo(beforeDias + 14));
    });

    test('convertSchoolToActive convierte colegio trial a suscripción activa de pago', () async {
      final schoolId = 'a0000000-0000-0000-0000-000000000003';
      await repository.convertSchoolToActive(schoolId, diaCorte: 5);

      final school = await repository.getSchoolById(schoolId);
      expect(school!.estadoSuscripcion, equals('active'));
      expect(school.isActive, isTrue);
      expect(school.isTrial, isFalse);
      expect(school.diaCorte, equals(5));
      expect(school.metodoPagoRegistrado, isTrue);
    });
  });

  group('Item 3: Módulo de Anuncios y Banners Globales del Sistema', () {
    test('createSystemAnnouncement crea anuncio activo y se lista correctamente', () async {
      final ann = await repository.createSystemAnnouncement(
        titulo: 'Mantenimiento Preventivo',
        mensaje: 'Actualización de clusters en la nube',
        tipo: AnnouncementType.mantenimiento,
      );

      expect(ann.id, startsWith('ann-'));
      expect(ann.activo, isTrue);
      expect(ann.tipo, equals(AnnouncementType.mantenimiento));

      final active = await repository.getSystemAnnouncements(onlyActive: true);
      expect(active.any((a) => a.id == ann.id), isTrue);
    });

    test('toggleAnnouncementStatus y deleteSystemAnnouncement modifican estado', () async {
      final ann = await repository.createSystemAnnouncement(
        titulo: 'Aviso Temporal',
        mensaje: 'Texto de prueba',
      );

      await repository.toggleAnnouncementStatus(ann.id, false);
      var list = await repository.getSystemAnnouncements(onlyActive: true);
      expect(list.any((a) => a.id == ann.id), isFalse);

      await repository.deleteSystemAnnouncement(ann.id);
      list = await repository.getSystemAnnouncements(onlyActive: false);
      expect(list.any((a) => a.id == ann.id), isFalse);
    });
  });

  group('Item 5: Métricas de Consumo y Almacenamiento en la Nube', () {
    test('getSchoolStorageMetrics retorna desglose de almacenamiento y cuota', () async {
      final metrics = await repository.getSchoolStorageMetrics('a0000000-0000-0000-0000-000000000001');

      expect(metrics['totalGB'], isNotNull);
      expect(metrics['maxQuotaGB'], equals(10.0));
      expect(metrics['porcentajeUso'], greaterThan(0.0));
      expect(metrics['documentosMB'], greaterThan(0.0));
      expect(metrics['expedientesMB'], greaterThan(0.0));
      expect(metrics['fotosMB'], greaterThan(0.0));
      expect(metrics['baseDatosMB'], greaterThan(0.0));
      expect(metrics['estadoSalud'], equals('Saludable'));
    });
  });

  group('Item 6: Exportación de Datos e Informes Financieros CSV', () {
    test('exportSchoolsCsv genera archivo compatible con Excel con todos los campos clave', () async {
      final csv = await repository.exportSchoolsCsv();

      expect(csv, contains('ID,Nombre Institución,RNC,Siglas'));
      expect(csv, contains('Colegio Bilingüe EDUNEX Piloto'));
      expect(csv, contains('Instituto Educativo San Judas Tadeo'));
      expect(csv, contains('1-31-00000-1'));
      expect(csv, contains('RD\$'));
    });
  });
}