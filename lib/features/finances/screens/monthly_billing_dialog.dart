import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../families/repositories/family_repository.dart';
import '../models/billing_models.dart';

class MonthlyBillingDialog extends StatefulWidget {
  final FamilyRepository repository;
  final VoidCallback onBillingCompleted;

  const MonthlyBillingDialog({
    super.key,
    required this.repository,
    required this.onBillingCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required FamilyRepository repository,
    required VoidCallback onBillingCompleted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MonthlyBillingDialog(
        repository: repository,
        onBillingCompleted: onBillingCompleted,
      ),
    );
  }

  @override
  State<MonthlyBillingDialog> createState() => _MonthlyBillingDialogState();
}

class _MonthlyBillingDialogState extends State<MonthlyBillingDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMonth = 'Octubre 2026';
  final _cuotaController = TextEditingController(text: '8500.00');
  bool _incluirServicios = true;
  bool _isProcessing = false;

  final List<String> _meses = [
    'Septiembre 2026',
    'Octubre 2026',
    'Noviembre 2026',
    'Diciembre 2026',
    'Enero 2027',
    'Febrero 2027',
  ];

  @override
  void dispose() {
    _cuotaController.dispose();
    super.dispose();
  }

  Future<void> _executeBilling() async {
    if (!_formKey.currentState!.validate()) return;

    final cuota = double.tryParse(_cuotaController.text.trim()) ?? 8500.0;

    setState(() => _isProcessing = true);
    try {
      final result = await widget.repository.executeMonthlyBillingRun(
        mesConcepto: _selectedMonth,
        cuotaColegiaturaBase: cuota,
        incluirServicios: _incluirServicios,
      );

      if (!mounted) return;
      widget.onBillingCompleted();
      Navigator.of(context).pop();

      _showSummarySheet(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al ejecutar el corte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSummarySheet(BuildContext context, BillingRunResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Corte Mensual Ejecutado Exitosamente',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyPrimary),
                      ),
                      Text(
                        'Concepto: ${result.mesConcepto} • Ref: ${result.id}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryMetric('Familias', '${result.familiasProcesadas}'),
                  _summaryMetric('Estudiantes', '${result.estudiantesFacturados}'),
                  _summaryMetric('Colegiaturas', 'RD\$ ${result.montoColegiaturas.toStringAsFixed(0)}'),
                  _summaryMetric('Servicios', 'RD\$ ${result.montoServiciosAdicionales.toStringAsFixed(0)}'),
                  _summaryMetric('Total Cargado', 'RD\$ ${result.montoTotalFacturado.toStringAsFixed(2)}', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Desglose por Cuentas Familiares:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: result.detalles.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final d = result.detalles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.nombreFamilia, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('${d.codigoFamilia} • ${d.cantidadEstudiantes} alumno(s)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+ RD\$ ${d.totalCargo.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                            ),
                            Text('Nuevo balance: RD\$ ${d.nuevoBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entendido y Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _summaryMetric(String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 14 : 13,
            color: isBold ? AppColors.navyPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.electricBlue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corte Mensual de Facturación',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                          ),
                          Text(
                            'Generación de colegiaturas y servicios recurrentes a todas las familias',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Selección de Mes
                const Text('Período / Mes a Facturar *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _meses.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMonth = val);
                  },
                ),
                const SizedBox(height: 16),

                // Cuota Colegiatura Base
                const Text('Cuota Colegiatura Base por Alumno (RD\$) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cuotaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.textSecondary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Indica la cuota base';
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Switch de Servicios Complementarios
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_shopping_cart_rounded, color: AppColors.navyPrimary, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Incluir Servicios Complementarios', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Cargará cuido vespertino y rutas de transporte activas', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _incluirServicios,
                        activeThumbColor: AppColors.electricBlue,
                        onChanged: (val) => setState(() => _incluirServicios = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _executeBilling,
                      icon: _isProcessing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(_isProcessing ? 'Procesando...' : 'Ejecutar Corte Masivo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
