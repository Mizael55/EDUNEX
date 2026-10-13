import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';

/// Modal para registrar pagos, abonos y emisión de recibos escolares
class RecordPaymentDialog extends StatefulWidget {
  final FamilyRepository repository;
  final Family? initialFamily;
  final VoidCallback? onPaymentRecorded;

  const RecordPaymentDialog({
    super.key,
    required this.repository,
    this.initialFamily,
    this.onPaymentRecorded,
  });

  static Future<void> show(
    BuildContext context, {
    required FamilyRepository repository,
    Family? initialFamily,
    VoidCallback? onPaymentRecorded,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordPaymentDialog(
        repository: repository,
        initialFamily: initialFamily,
        onPaymentRecorded: onPaymentRecorded,
      ),
    );
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Family> _families = [];
  Family? _selectedFamily;
  bool _isLoadingFamilies = true;
  bool _isSubmitting = false;

  final _montoController = TextEditingController(text: '5000.00');
  final _referenciaController = TextEditingController();
  final _notasController = TextEditingController();

  String _selectedConcepto = 'Colegiatura Mensual';
  String _selectedMetodo = 'Transferencia';

  // Éxito
  Map<String, dynamic>? _receiptData;

  final List<String> _conceptos = [
    'Colegiatura Mensual',
    'Matrícula Anual',
    'Servicio Cuido Vespertino',
    'Ruta de Transporte Escolar',
    'Uniforme Escolar',
    'Materiales y Libros',
    'Abono a Saldo Pendiente',
  ];

  final List<String> _metodos = [
    'Transferencia',
    'Tarjeta',
    'Efectivo',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    _referenciaController.text = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _loadFamilies();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    try {
      final list = await widget.repository.getFamilies();
      if (mounted) {
        setState(() {
          _families = list;
          _isLoadingFamilies = false;
          if (widget.initialFamily != null) {
            _selectedFamily = list.firstWhere(
              (f) => f.id == widget.initialFamily!.id,
              orElse: () => widget.initialFamily!,
            );
          } else if (list.isNotEmpty) {
            _selectedFamily = list.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFamilies = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una familia')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;
      await widget.repository.recordPayment(
        familiaId: _selectedFamily!.id,
        monto: monto,
        concepto: _selectedConcepto,
        metodo: _selectedMetodo,
        referencia: _referenciaController.text.trim(),
      );

      final receipt = {
        'numeroRecibo': _referenciaController.text.trim(),
        'familia': _selectedFamily!.nombreFamilia,
        'codigoFamilia': _selectedFamily!.codigoFamilia,
        'monto': monto,
        'concepto': _selectedConcepto,
        'metodo': _selectedMetodo,
        'fecha': DateTime.now(),
      };

      if (mounted) {
        setState(() {
          _receiptData = receipt;
          _isSubmitting = false;
        });
        widget.onPaymentRecorded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Error al registrar el pago: $e'),
          ),
        );
      }
    }
  }

  Widget _buildReceiptSuccess() {
    final r = _receiptData!;
    final montoStr = (r['monto'] as double).toStringAsFixed(2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF166534),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Pago Registrado Exitosamente!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'El cobro fue asentado en la contabilidad y se emitió el recibo.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RECIBO OFICIAL EDUNEX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF166534))),
                        Text('No: ${r['numeroRecibo']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                      ],
                    ),
                    const Divider(color: Color(0xFFBBF7D0), height: 16),
                    Text('👤 Cuenta Familiar: ${r['familia']} (${r['codigoFamilia']})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('📋 Concepto: ${r['concepto']}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('💳 Método de Pago: ${r['metodo']}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Monto Pagado: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('RD\$ $montoStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '💡 El balance pendiente de la cuenta familiar ha sido actualizado automáticamente.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final text = '''
*Comprobante de Pago - EDUNEX*
Recibo No: ${r['numeroRecibo']}
Familia: ${r['familia']}
Concepto: ${r['concepto']}
Monto: RD\$ $montoStr
Método: ${r['metodo']}
Estado: APROBADO & ASENTADO
''';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comprobante copiado al portapapeles.'),
                      backgroundColor: AppColors.navyPrimary,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar Recibo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: AppColors.navyPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Entendido y Cerrar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 750),
        child: _receiptData != null
            ? _buildReceiptSuccess()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentGreen, Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar Cobro & Emitir Recibo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Asienta pagos de colegiatura, cuido, transporte o uniformes.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Formulario
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selector de Familia
                            const Text('Cuenta Familiar Destino *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                            const SizedBox(height: 6),
                            if (_isLoadingFamilies)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_families.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: const Text(
                                  'Aún no hay familias registradas. Por favor da de alta una familia primero.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                                ),
                              )
                            else
                              DropdownButtonFormField<Family>(
                                initialValue: _selectedFamily,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.family_restroom_rounded, color: AppColors.navyPrimary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _families.map((f) {
                                  return DropdownMenuItem<Family>(
                                    value: f,
                                    child: Text(
                                      '${f.nombreFamilia} (${f.codigoFamilia}) - Saldo: RD\$ ${f.balancePendiente.toStringAsFixed(2)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (f) {
                                  if (f != null) setState(() => _selectedFamily = f);
                                },
                              ),

                            const SizedBox(height: 18),

                            // Concepto y Monto
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Concepto de Cobro *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedConcepto,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        items: _conceptos.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                                        onChanged: (v) {
                                          if (v != null) setState(() => _selectedConcepto = v);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Monto (RD\$) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _montoController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          prefixText: 'RD\$ ',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Requerido';
                                          final n = double.tryParse(v.trim());
                                          if (n == null || n <= 0) return 'Monto inválido';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Método de pago y No. Recibo
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Método de Pago *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedMetodo,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        items: _metodos.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                                        onChanged: (v) {
                                          if (v != null) setState(() => _selectedMetodo = v);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('No. Recibo / Referencia *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _referenciaController,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Notas u observaciones
                            const Text('Notas u Observaciones (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _notasController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Ej: Transferencia del Banco Popular, pagada por tutor...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Acciones
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(_isSubmitting ? 'Registrando...' : 'Registrar Pago & Emitir Recibo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
