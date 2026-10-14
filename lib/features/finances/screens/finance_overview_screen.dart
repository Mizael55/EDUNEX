import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../families/repositories/family_repository.dart';
import '../../superadmin/repositories/school_repository.dart';
import '../models/billing_models.dart';
import 'record_payment_dialog.dart';
import 'monthly_billing_dialog.dart';

/// Pantalla Integral de Finanzas & Cobranzas de EDUNEX
/// Soporta vista dual:
/// - Modo SuperAdmin (Facturación SaaS de licencias a colegios, MRR, estado de contratos)
/// - Modo Administrador Escolar (Cobranza de colegiatura, cartera por cobrar, emisión de recibos)
class FinanceOverviewScreen extends StatefulWidget {
  final bool isSuperAdmin;
  final FamilyRepository familyRepository;
  final SchoolRepository? schoolRepository;

  const FinanceOverviewScreen({
    super.key,
    required this.isSuperAdmin,
    required this.familyRepository,
    this.schoolRepository,
  });

  @override
  State<FinanceOverviewScreen> createState() => _FinanceOverviewScreenState();
}

class _FinanceOverviewScreenState extends State<FinanceOverviewScreen> {
  bool _isLoading = true;
  final double _totalCobrado = 0.0;
  double _totalPorCobrar = 0.0;
  final List<Map<String, dynamic>> _transacciones = [];
  DebtAgingSummary? _agingSummary;
  int _selectedTab = 0; // 0: Historial de Recibos, 1: Antigüedad de Cartera & Mora

  @override
  void initState() {
    super.initState();
    _loadFinances();
  }

  Future<void> _loadFinances() async {
    setState(() => _isLoading = true);
    try {
      final families = await widget.familyRepository.getFamilies();
      double pending = 0;
      for (final f in families) {
        pending += f.balancePendiente;
      }
      final aging = await widget.familyRepository.getDebtAgingReport();
      if (mounted) {
        setState(() {
          _totalPorCobrar = pending;
          _agingSummary = aging;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRecordPayment() {
    RecordPaymentDialog.show(
      context,
      repository: widget.familyRepository,
      onPaymentRecorded: () {
        _loadFinances();
      },
    );
  }

  void _openMonthlyBilling() {
    MonthlyBillingDialog.show(
      context,
      repository: widget.familyRepository,
      onBillingCompleted: () {
        _loadFinances();
      },
    );
  }

  Future<void> _sendMassiveReminders() async {
    final count = await widget.familyRepository.sendDelinquencyReminders();
    if (!mounted) return;
    _loadFinances();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recordatorios de cobro enviados a $count familia(s) con cuotas pendientes.'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Principal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.isSuperAdmin ? 'FACTURACIÓN SAAS' : 'MÓDULO DE CAJA & COBRANZAS',
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Text('Control Financiero y Recibos', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isSuperAdmin
                            ? 'Finanzas Globales & Suscripciones de Colegios'
                            : 'Gestión de Cobranzas & Ingresos Institucionales',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isSuperAdmin
                            ? 'Monitorea ingresos recurrentes mensuales (MRR), estado de pagos de licencias y cobros pendientes.'
                            : 'Administra la facturación de colegiaturas, servicios extracurriculares y emisión de recibos oficiales.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!widget.isSuperAdmin) ...[
                  OutlinedButton.icon(
                    onPressed: _openMonthlyBilling,
                    icon: const Icon(Icons.autorenew_rounded, size: 18),
                    label: const Text('Corte Mensual Recurrente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyPrimary,
                      side: const BorderSide(color: AppColors.navyPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openRecordPayment,
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Registrar Cobro en Caja'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Tarjetas KPI Financieras
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final crossAxisCount = isWide ? 3 : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.1 : 2.6,
                  children: [
                    _buildFinanceCard(
                      title: widget.isSuperAdmin ? 'MRR Mensual Estimado' : 'Total Recaudado (Mes)',
                      amount: widget.isSuperAdmin ? 'RD\$ 85,000.00' : 'RD\$ ${_totalCobrado.toStringAsFixed(2)}',
                      subtitle: widget.isSuperAdmin ? 'Ingreso recurrente por licencias' : '88 transacciones aprobadas',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildFinanceCard(
                      title: widget.isSuperAdmin ? 'Facturación Pendiente' : 'Cuentas por Cobrar (Mora)',
                      amount: 'RD\$ ${_totalPorCobrar.toStringAsFixed(2)}',
                      subtitle: widget.isSuperAdmin ? '2 colegios con vencimiento próximo' : 'Familias con cuotas vencidas',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFFB45309),
                    ),
                    _buildFinanceCard(
                      title: widget.isSuperAdmin ? 'Tasa de Cobro SaaS' : 'Eficiencia de Cobro',
                      amount: '94.2%',
                      subtitle: 'Meta mensual: >90%',
                      icon: Icons.pie_chart_outline_rounded,
                      color: AppColors.electricBlue,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Selector de Pestañas (Solo Admin Escolar)
            if (!widget.isSuperAdmin) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 0),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? AppColors.surfaceWhite : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 0
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Historial de Cobros & Recibos',
                            style: TextStyle(
                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                              color: _selectedTab == 0 ? AppColors.navyPrimary : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 1),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? AppColors.surfaceWhite : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 1
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Reporte de Antigüedad de Cartera (Aging & Mora)',
                                  style: TextStyle(
                                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedTab == 1 ? AppColors.navyPrimary : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_agingSummary != null && _agingSummary!.familiasEnMora.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_agingSummary!.familiasEnMora.length}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedTab == 1 && !widget.isSuperAdmin) ...[
              _buildAgingSection(),
            ] else ...[
              // Tabla de Movimientos / Recibos
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, color: AppColors.navyPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.isSuperAdmin
                              ? 'Registro de Pagos de Licencias por Colegios'
                              : 'Historial Reciente de Cobros & Recibos Emitidos',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Generando reporte consolidado en PDF...'),
                                backgroundColor: AppColors.navyPrimary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Exportar Reporte'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navyPrimary,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                  else if (_transacciones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded, size: 32, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No hay transacciones registradas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Los cobros, matrículas y mensualidades registrados aparecerán aquí.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transacciones.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final t = _transacciones[index];
                        final monto = (t['monto'] as double).toStringAsFixed(2);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_rounded, color: Color(0xFF166534), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['entidad'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${t["concepto"]} • ${t["id"]}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['metodo'], style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                    Text(t['fecha'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RD\$ $monto',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF166534)),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t['estado'],
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                                tooltip: 'Copiar Comprobante',
                                onPressed: () {
                                  final text = '''
*Comprobante de Pago - EDUNEX*
Recibo No: ${t['id']}
Entidad: ${t['entidad']}
Concepto: ${t['concepto']}
Monto: RD\$ $monto
Fecha: ${t['fecha']}
Método: ${t['metodo']}
''';
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Comprobante ${t["id"]} copiado al portapapeles.'),
                                      backgroundColor: AppColors.navyPrimary,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildAgingSection() {
  final aging = _agingSummary;
  if (aging == null) {
    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 4 Tarjetas de Cubetas de Antigüedad
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final crossAxisCount = isWide ? 4 : 2;
          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 1.7 : 1.4,
            children: [
              _buildFinanceCard(
                title: 'Corriente (0-30 días)',
                amount: 'RD\$ ${aging.totalCorriente.toStringAsFixed(2)}',
                subtitle: 'Vencimiento dentro del mes',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.accentGreen,
              ),
              _buildFinanceCard(
                title: 'Vencido (31-60 días)',
                amount: 'RD\$ ${aging.total30a60.toStringAsFixed(2)}',
                subtitle: 'Mora temprana / 1 cuota',
                icon: Icons.access_time_rounded,
                color: const Color(0xFFD97706),
              ),
              _buildFinanceCard(
                title: 'Vencido (61-90 días)',
                amount: 'RD\$ ${aging.total60a90.toStringAsFixed(2)}',
                subtitle: 'Mora media / 2 cuotas',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEA580C),
              ),
              _buildFinanceCard(
                title: 'Mora Crítica (>90 días)',
                amount: 'RD\$ ${aging.totalMas90.toStringAsFixed(2)}',
                subtitle: 'Alto riesgo de incobrabilidad',
                icon: Icons.error_outline_rounded,
                color: const Color(0xFFDC2626),
              ),
            ],
          );
        },
      ),

      const SizedBox(height: 20),

      // Tabla de Cartera Vencida & Acciones de Cobranza
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.report_problem_rounded, color: Color(0xFFB45309), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Detalle de Cartera Vencida & Gestión de Cobro',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Cartera Vencida (>30 días): RD\$ ${aging.totalCarteraVencida.toStringAsFixed(2)} • ${aging.familiasEnMora.length} familias registradas',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: aging.familiasEnMora.isEmpty ? null : _sendMassiveReminders,
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: const Text('Enviar Recordatorio Masivo a Todos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            if (aging.familiasEnMora.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    '¡Excelente! No hay familias con balances vencidos en este momento.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: aging.familiasEnMora.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final f = aging.familiasEnMora[index];
                  final riskColor = switch (f.riesgo) {
                    DelinquencyRisk.bajo => AppColors.accentGreen,
                    DelinquencyRisk.medio => const Color(0xFFD97706),
                    DelinquencyRisk.alto => const Color(0xFFEA580C),
                    DelinquencyRisk.critico => const Color(0xFFDC2626),
                  };

                  final riskLabel = switch (f.riesgo) {
                    DelinquencyRisk.bajo => 'Riesgo Bajo',
                    DelinquencyRisk.medio => 'Riesgo Medio',
                    DelinquencyRisk.alto => 'Riesgo Alto',
                    DelinquencyRisk.critico => 'Mora Crítica',
                  };

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: riskColor.withValues(alpha: 0.15),
                          child: Icon(Icons.person_pin_rounded, color: riskColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.nombreFamilia,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text('${f.codigoFamilia} • ${f.telefonoPrincipal} • ${f.emailPrincipal}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${f.diasMora} días (${f.bucketAntiguedad})',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskColor),
                                ),
                              ),
                              if (f.ultimoRecordatorio != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Recordatorio: Hoy ${f.ultimoRecordatorio!.hour.toString().padLeft(2, "0")}:${f.ultimoRecordatorio!.minute.toString().padLeft(2, "0")}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'RD\$ ${f.balancePendiente.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: riskColor),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                riskLabel,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF059669)),
                          tooltip: 'Recordatorio WhatsApp / SMS',
                          onPressed: () {
                            final msg = '''
*AVISO DE COBRANZA ESCOLAR - EDUNEX*
Estimada ${f.nombreFamilia} (${f.codigoFamilia}):
Le recordamos amablemente que presenta un balance vencido de *RD\$ ${f.balancePendiente.toStringAsFixed(2)}* con ${f.diasMora} días de antigüedad.
Le agradecemos regularizar su cuenta a través del Portal de Padres o contactando el departamento financiero del centro.
''';
                            Clipboard.setData(ClipboardData(text: msg));
                            widget.familyRepository.sendDelinquencyReminders(familyIds: [f.familiaId]);
                            _loadFinances();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Mensaje de cobranza copiado para ${f.nombreFamilia}. Notificación registrada.'),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.point_of_sale_rounded, size: 20, color: AppColors.navyPrimary),
                          tooltip: 'Cobrar en Caja',
                          onPressed: _openRecordPayment,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildFinanceCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color == const Color(0xFFB45309) ? color : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
