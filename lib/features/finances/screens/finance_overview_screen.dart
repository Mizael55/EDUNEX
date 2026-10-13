import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../families/repositories/family_repository.dart';
import '../../superadmin/repositories/school_repository.dart';
import 'record_payment_dialog.dart';

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
  final double _totalCobrado = 145000.0;
  double _totalPorCobrar = 42500.0;
  final List<Map<String, dynamic>> _transacciones = [
    {
      'id': 'REC-2026-0089',
      'entidad': 'Familia Pérez González',
      'concepto': 'Colegiatura Mensual (Febrero 2026)',
      'monto': 12500.00,
      'metodo': 'Transferencia Banco Popular',
      'fecha': '12 Feb 2026',
      'estado': 'Aprobado',
    },
    {
      'id': 'REC-2026-0088',
      'entidad': 'Familia Ramírez Méndez',
      'concepto': 'Servicio Cuido Vespertino (3:00 - 6:00 PM)',
      'monto': 3500.00,
      'metodo': 'Tarjeta de Crédito VISA',
      'fecha': '11 Feb 2026',
      'estado': 'Aprobado',
    },
    {
      'id': 'REC-2026-0087',
      'entidad': 'Familia Gómez Marte',
      'concepto': 'Matrícula Anual & Seguro Escolar',
      'monto': 25000.00,
      'metodo': 'Transferencia Banreservas',
      'fecha': '10 Feb 2026',
      'estado': 'Aprobado',
    },
    {
      'id': 'REC-2026-0086',
      'entidad': 'Familia Castillo Rosario',
      'concepto': 'Ruta de Transporte Escolar Naco',
      'monto': 4000.00,
      'metodo': 'Efectivo en Caja',
      'fecha': '09 Feb 2026',
      'estado': 'Aprobado',
    },
  ];

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
      if (mounted) {
        setState(() {
          _totalPorCobrar = pending;
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
                      Row(
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
                          const SizedBox(width: 8),
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

            const SizedBox(height: 28),

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
        ),
      ),
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
      padding: const EdgeInsets.all(18),
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
