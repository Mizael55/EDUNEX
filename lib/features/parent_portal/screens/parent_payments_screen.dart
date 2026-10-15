import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../models/payment_receipt.dart';
import '../models/payment_agreement_request.dart';
import '../widgets/receipt_details_dialog.dart';
import 'online_payment_gateway_dialog.dart';

/// Pantalla del Tutor para Pagos de Colegiatura, Acuerdos de Pago y Validación de Comprobantes Oficiales (NCF)
class ParentPaymentsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;

  const ParentPaymentsScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
  });

  @override
  State<ParentPaymentsScreen> createState() => _ParentPaymentsScreenState();
}

class _ParentPaymentsScreenState extends State<ParentPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Family? _family;
  List<PaymentReceipt> _receipts = [];
  List<PaymentAgreementRequest> _agreements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );

      List<PaymentReceipt> receipts = [];
      List<PaymentAgreementRequest> agreements = [];

      if (family != null) {
        receipts = await widget.familyRepository.getReceiptsForFamily(family.id);
        agreements = await widget.familyRepository.getAgreementsForFamily(family.id);
      }

      if (mounted) {
        setState(() {
          _family = family;
          _receipts = receipts;
          _agreements = agreements;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.navyPrimary)),
      );
    }

    final family = _family;
    if (family == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: Text('No se encontró expediente familiar.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Principal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pagos, Acuerdos & Comprobantes',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestión financiera para la ${family.nombreFamilia} • NCF & Convenios',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showAgreementRequestDialog(context, family),
                      icon: const Icon(Icons.handshake_rounded, size: 18),
                      label: const Text('Solicitar Acuerdo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyPrimary,
                        side: const BorderSide(color: AppColors.navyPrimary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(context, family),
                      icon: const Icon(Icons.credit_card_rounded, size: 18),
                      label: Text(family.estaAlDia ? 'Abonar a Cuenta' : 'Pagar RD\$ ${family.balancePendiente.toStringAsFixed(2)}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: AppColors.surfaceWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tarjeta de Balance Consolidado
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: family.estaAlDia
                      ? [const Color(0xFF065F46), const Color(0xFF047857)]
                      : [AppColors.navyPrimary, const Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      family.estaAlDia ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                      color: AppColors.surfaceWhite,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.estaAlDia ? 'CUENTA AL DÍA' : 'BALANCE PENDIENTE DE PAGO',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RD\$ ${family.balancePendiente.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          family.estaAlDia
                              ? 'No tienes cuotas ni mensualidades pendientes.'
                              : 'Vencimiento sugerido: Próximo día 10. Puedes pagar en línea o solicitar un acuerdo de pago.',
                          style: TextStyle(
                            color: AppColors.surfaceWhite.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!family.estaAlDia)
                    ElevatedButton(
                      onPressed: () => _showPaymentDialog(context, family),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberAccent,
                        foregroundColor: AppColors.navyPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Pagar en Línea'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Pestañas: 1. Comprobantes Oficiales (NCF) | 2. Acuerdos y Convenios
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.navyPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.navyPrimary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    text: 'Comprobantes Oficiales (${_receipts.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.handshake_rounded, size: 20),
                    text: 'Convenios & Acuerdos de Pago (${_agreements.length})',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contenido de las Pestañas
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña 1: Comprobantes de Pago
                  _buildReceiptsList(),

                  // Pestaña 2: Acuerdos de Pago
                  _buildAgreementsList(family),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsList() {
    if (_receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No hay comprobantes de pago registrados aún.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _receipts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _receipts[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.numeroComprobante,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'NCF: ${r.ncf}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.concepto,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.metodoPago} • ${r.fechaEmision.day.toString().padLeft(2, '0')}/${r.fechaEmision.month.toString().padLeft(2, '0')}/${r.fechaEmision.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RD\$ ${r.monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ElevatedButton.icon(
                    onPressed: () => ReceiptDetailsDialog.show(context, r),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Ver / Imprimir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgreementsList(Family family) {
    if (_agreements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No tienes solicitudes de acuerdos registradas.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAgreementRequestDialog(context, family),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Solicitar Primer Convenio de Pago'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _agreements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _agreements[index];
        final isApproved = a.estado.toLowerCase().contains('aprobado');
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                        color: isApproved ? AppColors.accentGreen : const Color(0xFFB45309),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        a.tipoAcuerdo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a.estado,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isApproved ? const Color(0xFF166534) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Cuota Propuesta por el Tutor: RD\$ ${a.propuestaCuota.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Justificación: "${a.justificacion}"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
              if (a.respuestaCentro != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.school_rounded, size: 16, color: AppColors.navyPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Respuesta de la Institución: ${a.respuestaCentro}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, Family family) async {
    final receipt = await OnlinePaymentGatewayDialog.show(
      context: context,
      family: family,
      familyRepository: widget.familyRepository,
      onPaymentSuccess: _loadData,
    );
    if (receipt != null && context.mounted) {
      ReceiptDetailsDialog.show(context, receipt);
    }
  }

  void _showAgreementRequestDialog(BuildContext context, Family family) {
    final amountController = TextEditingController(text: (family.balancePendiente / 2).toStringAsFixed(2));
    final justificationController = TextEditingController();
    String selectedType = 'Fraccionamiento de Cuota de Colegiatura';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.handshake_rounded, color: AppColors.navyPrimary),
              SizedBox(width: 10),
              Text('Solicitar Acuerdo o Convenio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'El centro revisará tu solicitud de ajuste o facilidad de pago en el Consejo Administrativo.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Acuerdo Deseado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Fraccionamiento de Cuota de Colegiatura',
                      child: Text('Fraccionamiento de Cuota (Quincenal)'),
                    ),
                    DropdownMenuItem(
                      value: 'Extensión de Plazo de Pago',
                      child: Text('Extensión de Plazo de Vencimiento'),
                    ),
                    DropdownMenuItem(
                      value: 'Reestructuración por Caso Especial',
                      child: Text('Reestructuración Financiera Especial'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Propuesta de Cuota Viable (RD\$)',
                    prefixText: 'RD\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: justificationController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo o Justificación',
                    hintText: 'Explica brevemente la situación financiera...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (justificationController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor especifica una justificación.')),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0.0;
                      setModalState(() => isSubmitting = true);

                      await widget.familyRepository.submitAgreementRequest(
                        familiaId: family.id,
                        nombreFamilia: family.nombreFamilia,
                        tipoAcuerdo: selectedType,
                        propuestaCuota: amount,
                        justificacion: justificationController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        await _loadData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Solicitud de acuerdo enviada para evaluación de la Dirección.'),
                              backgroundColor: AppColors.navyPrimary,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: AppColors.surfaceWhite,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar Solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}
