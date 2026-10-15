import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../models/payment_approval_request.dart';

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

  // Issue #17: Control de Abono y Autorización
  bool _isAbonoFamilia = false;
  PaymentApprovalRequest? _approvedAbono;
  bool _isLoadingApproval = false;
  final _motivoAbonoController = TextEditingController();

  final _montoController = TextEditingController(text: '0.00');
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
    _motivoAbonoController.dispose();
    super.dispose();
  }

  Future<void> _checkApprovedAbono(String familiaId) async {
    setState(() => _isLoadingApproval = true);
    try {
      final approved = await widget.repository.getApprovedAbonoForFamily(familiaId);
      if (mounted) {
        setState(() {
          _approvedAbono = approved;
          _isLoadingApproval = false;
          if (_isAbonoFamilia && approved != null) {
            _montoController.text = approved.montoAbonoPropuesto.toStringAsFixed(2);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingApproval = false);
    }
  }

  Future<void> _loadFamilies() async {
    try {
      final list = await widget.repository.getFamilies();
      if (mounted) {
        Family? initial;
        if (widget.initialFamily != null) {
          initial = list.firstWhere(
            (f) => f.id == widget.initialFamily!.id,
            orElse: () => widget.initialFamily!,
          );
        } else if (list.isNotEmpty) {
          initial = list.first;
        }

        setState(() {
          _families = list;
          _isLoadingFamilies = false;
          _selectedFamily = initial;
          if (initial != null) {
            _montoController.text = initial.balancePendiente.toStringAsFixed(2);
          }
        });

        if (initial != null) {
          _checkApprovedAbono(initial.id);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFamilies = false);
    }
  }

  void _onToggleAbono(bool value) {
    setState(() {
      _isAbonoFamilia = value;
      if (value) {
        _selectedConcepto = 'Abono a Saldo Pendiente';
        if (_approvedAbono != null) {
          _montoController.text = _approvedAbono!.montoAbonoPropuesto.toStringAsFixed(2);
        } else {
          final currentDebt = _selectedFamily?.balancePendiente ?? 0.0;
          final half = (currentDebt / 2).roundToDouble();
          _montoController.text = half > 0 ? half.toStringAsFixed(2) : '1000.00';
        }
      } else {
        _montoController.text = (_selectedFamily?.balancePendiente ?? 0.0).toStringAsFixed(2);
        _selectedConcepto = 'Colegiatura Mensual';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una familia')),
      );
      return;
    }

    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;

    // Issue #17: Si es abono y NO cuenta con autorización de administración/contabilidad:
    if (_isAbonoFamilia && _approvedAbono == null) {
      if (_motivoAbonoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFD97706),
            content: Text('Debe especificar el motivo del abono para enviar la solicitud de autorización.'),
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        await widget.repository.createAbonoApprovalRequest(
          familiaId: _selectedFamily!.id,
          montoAbono: monto,
          motivo: _motivoAbonoController.text.trim(),
          concepto: _selectedConcepto,
          solicitadoPor: 'Cajero / Recepción',
        );

        if (mounted) {
          setState(() => _isSubmitting = false);
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: Color(0xFFD97706), size: 28),
                  SizedBox(width: 10),
                  Text('Solicitud de Permiso Enviada'),
                ],
              ),
              content: Text(
                'Se ha enviado la solicitud de autorización a Administración y Contabilidad por RD\$ ${monto.toStringAsFixed(2)} para ${_selectedFamily!.nombreFamilia}.\n\nPor directriz del centro, no se puede cobrar abonos sin previa autorización.',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade800,
              content: Text('Error al enviar la solicitud: $e'),
            ),
          );
        }
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
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
                                      '${f.nombreFamilia} (${f.codigoFamilia}) - Deuda: RD\$ ${f.balancePendiente.toStringAsFixed(2)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (f) {
                                  if (f != null) {
                                    setState(() {
                                      _selectedFamily = f;
                                      if (!_isAbonoFamilia) {
                                        _montoController.text = f.balancePendiente.toStringAsFixed(2);
                                      }
                                    });
                                    _checkApprovedAbono(f.id);
                                  }
                                },
                              ),

                            const SizedBox(height: 12),

                            // Resumen de Deuda Total Automática
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.navyPrimary),
                                      SizedBox(width: 8),
                                      Text('Deuda Total Pendiente:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyPrimary)),
                                    ],
                                  ),
                                  Text(
                                    'RD\$ ${(_selectedFamily?.balancePendiente ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626)),
                                  ),
                                ],
                              ),
                            ),

                            // Checkbox Abono Familia (Issue #17)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isAbonoFamilia ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _isAbonoFamilia ? AppColors.electricBlue : const Color(0xFFE2E8F0)),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: CheckboxListTile(
                                  key: const Key('checkbox_abono_familia'),
                                  value: _isAbonoFamilia,
                                  onChanged: (val) => _onToggleAbono(val ?? false),
                                  activeColor: AppColors.navyPrimary,
                                  title: const Text(
                                    'Abono familia',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                                  ),
                                  subtitle: Text(
                                    _isAbonoFamilia
                                        ? 'Modo abono activo: Permite ingresar monto parcial y requiere permiso previo.'
                                        : 'Desmarcado: Solo se permite cobrar el total adeudado de forma automática.',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                ),
                              ),
                            ),

                            // Si es abono: banner de estado y motivo
                            if (_isAbonoFamilia) ...[
                              if (_isLoadingApproval)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_approvedAbono != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, color: Color(0xFF166534), size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Abono Autorizado por Administración', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 13)),
                                            Text(
                                              'Aprobado por ${_approvedAbono!.aprobadoPor ?? "Administración"} por hasta RD\$ ${_approvedAbono!.montoAbonoPropuesto.toStringAsFixed(2)}. Puede proceder con el cobro.',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF14532D)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 22),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Abono Requiere Autorización', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13)),
                                            Text(
                                              'No se puede cobrar sin autorización. Al hacer clic abajo, se enviará la solicitud al administrador o contable para su aprobación.',
                                              style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const Text('Motivo o Justificación del Abono *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                              const SizedBox(height: 6),
                              TextFormField(
                                key: const Key('input_motivo_abono'),
                                controller: _motivoAbonoController,
                                decoration: InputDecoration(
                                  hintText: 'Ej: Dificultad económica temporal, pago parcial de mensualidad...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (v) {
                                  if (_isAbonoFamilia && (v == null || v.trim().isEmpty)) {
                                    return 'Indique el motivo del abono para la solicitud de permiso';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],

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
                                        key: const Key('input_monto_pago'),
                                        controller: _montoController,
                                        readOnly: !_isAbonoFamilia,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          prefixText: 'RD\$ ',
                                          filled: !_isAbonoFamilia,
                                          fillColor: !_isAbonoFamilia ? const Color(0xFFF1F5F9) : Colors.white,
                                          helperText: !_isAbonoFamilia ? 'Total adeudado automático' : null,
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
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
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
                        ElevatedButton.icon(
                          key: const Key('btn_submit_pago_abono'),
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(
                                  _isAbonoFamilia
                                      ? (_approvedAbono != null ? Icons.verified_rounded : Icons.send_rounded)
                                      : Icons.check_circle_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _isSubmitting
                                ? 'Procesando...'
                                : _isAbonoFamilia
                                    ? (_approvedAbono != null
                                        ? 'Cobrar Abono Autorizado (RD\$ ${_montoController.text})'
                                        : 'Solicitar Permiso de Abono')
                                    : 'Cobrar Deuda Total (RD\$ ${_montoController.text})',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAbonoFamilia && _approvedAbono == null
                                ? const Color(0xFFD97706)
                                : AppColors.accentGreen,
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
