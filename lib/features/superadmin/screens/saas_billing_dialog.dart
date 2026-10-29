import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/school.dart';
import '../models/saas_invoice.dart';
import '../repositories/school_repository.dart';

/// Modal para la gestión de Cobranza SaaS y Facturas con NCF DGII para Colegios
class SaasBillingDialog extends StatefulWidget {
  final School? initialSchool;

  const SaasBillingDialog({super.key, this.initialSchool});

  @override
  State<SaasBillingDialog> createState() => _SaasBillingDialogState();
}

class _SaasBillingDialogState extends State<SaasBillingDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SchoolRepository _repository = SchoolRepository();

  List<SaaSInvoice> _invoices = [];
  List<School> _schools = [];
  bool _isLoading = true;

  // Formulario de nueva factura
  School? _selectedSchoolForNew;
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _periodoController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  String _selectedTipoNCF = 'B01';
  int _diasGracia = 15;
  bool _isEmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _periodoController.text = _getDefaultPeriodo();
    _loadData();
  }

  String _getDefaultPeriodo() {
    final now = DateTime.now();
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[now.month - 1]} ${now.year}';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final schools = await _repository.getSchools();
    final invoices = await _repository.getSaaSInvoices(
      schoolId: widget.initialSchool?.id,
    );

    if (mounted) {
      setState(() {
        _schools = schools;
        _invoices = invoices;
        if (widget.initialSchool != null) {
          _selectedSchoolForNew = schools.firstWhere(
            (s) => s.id == widget.initialSchool!.id,
            orElse: () => widget.initialSchool!,
          );
        } else if (schools.isNotEmpty) {
          _selectedSchoolForNew = schools.first;
        }
        if (_selectedSchoolForNew != null) {
          _montoController.text = _selectedSchoolForNew!.cuotaMensualSaaS.toStringAsFixed(0);
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _montoController.dispose();
    _periodoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _onSchoolChanged(School? school) {
    if (school == null) return;
    setState(() {
      _selectedSchoolForNew = school;
      _montoController.text = school.cuotaMensualSaaS.toStringAsFixed(0);
    });
  }

  Future<void> _emitInvoice() async {
    if (_selectedSchoolForNew == null) {
      AppToast.warning(context, 'Seleccione un colegio destinatario');
      return;
    }
    final monto = double.tryParse(_montoController.text.trim());
    if (monto == null || monto <= 0) {
      AppToast.warning(context, 'Ingrese un monto mensual válido');
      return;
    }
    if (_periodoController.text.trim().isEmpty) {
      AppToast.warning(context, 'Ingrese el período de facturación');
      return;
    }

    setState(() => _isEmitting = true);
    try {
      final invoice = await _repository.generateSaaSInvoice(
        schoolId: _selectedSchoolForNew!.id,
        schoolName: _selectedSchoolForNew!.nombre,
        monto: monto,
        periodo: _periodoController.text.trim(),
        rnc: _selectedSchoolForNew!.rnc,
        tipoNCF: _selectedTipoNCF,
        diasGracia: _diasGracia,
        notas: _notasController.text.trim().isNotEmpty ? _notasController.text.trim() : null,
      );

      if (mounted) {
        AppToast.success(
          context,
          'Factura NCF ${invoice.ncf} emitida exitosamente para ${_selectedSchoolForNew!.nombre}',
        );
        _notasController.clear();
        await _loadData();
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error emitiendo factura: $e');
      }
    } finally {
      if (mounted) setState(() => _isEmitting = false);
    }
  }

  Future<void> _markAsPaid(SaaSInvoice invoice) async {
    final metodoController = TextEditingController(text: 'Transferencia Bancaria BHD');
    final notaPagoController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 24),
            const SizedBox(width: 8),
            const Text('Registrar Cobro SaaS', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmar cobro de RD\$ ${invoice.monto.toStringAsFixed(2)} para ${invoice.colegioNombre} (NCF: ${invoice.ncf ?? "S/N"}).',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Método de Pago', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: metodoController.text,
              dropdownColor: AppColors.cardBackground,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSubtle)),
              ),
              items: const [
                DropdownMenuItem(value: 'Transferencia Bancaria BHD', child: Text('Transferencia Bancaria BHD')),
                DropdownMenuItem(value: 'Transferencia Banreservas', child: Text('Transferencia Banreservas')),
                DropdownMenuItem(value: 'Transferencia Banco Popular', child: Text('Transferencia Banco Popular')),
                DropdownMenuItem(value: 'Tarjeta Corporativa', child: Text('Tarjeta de Crédito Corporativa')),
                DropdownMenuItem(value: 'Cheque Comercial', child: Text('Cheque Comercial')),
              ],
              onChanged: (val) {
                if (val != null) metodoController.text = val;
              },
            ),
            const SizedBox(height: 12),
            const Text('Nota de Pago / Referencia', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: notaPagoController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ej: Ref #992812 - BHD León',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSubtle)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmar Cobro', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.recordInvoicePayment(
        invoiceId: invoice.id,
        metodoPago: metodoController.text,
        notas: notaPagoController.text.trim().isNotEmpty ? notaPagoController.text.trim() : null,
      );
      if (mounted) {
        AppToast.success(
          context,
          'Pago de factura NCF ${invoice.ncf} registrado exitosamente',
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 900,
        height: 650,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInvoicesListTab(),
                        _buildEmitInvoiceTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.electricBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cobranza SaaS & Facturas Fiscales NCF',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.initialSchool != null
                      ? 'Historial y facturación para: ${widget.initialSchool!.nombre}'
                      : 'Control de ciclo de facturación, mora y comprobantes DGII B01/B02',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.electricBlue,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.electricBlue,
        tabs: [
          Tab(
            icon: const Icon(Icons.format_list_bulleted, size: 18),
            text: 'Facturas Emitidas (${_invoices.length})',
          ),
          const Tab(
            icon: Icon(Icons.post_add, size: 18),
            text: 'Emitir Nueva Factura NCF',
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesListTab() {
    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No hay facturas registradas',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilice la pestaña "Emitir Nueva Factura NCF" para generar un cobro.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final isPagada = inv.estado == SaaSInvoiceStatus.pagada;

        Color badgeColor;
        switch (inv.estado) {
          case SaaSInvoiceStatus.pagada:
            badgeColor = AppColors.accentGreen;
            break;
          case SaaSInvoiceStatus.pendiente:
            badgeColor = AppColors.amberAccent;
            break;
          case SaaSInvoiceStatus.enMora:
            badgeColor = Colors.redAccent;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPagada ? Icons.check_circle : Icons.schedule,
                  color: badgeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          inv.colegioNombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (inv.ncf != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NCF: ${inv.ncf}',
                              style: const TextStyle(
                                color: AppColors.electricBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Período: ${inv.periodo}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Vence: ${inv.fechaVencimiento.day}/${inv.fechaVencimiento.month}/${inv.fechaVencimiento.year}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (isPagada && inv.metodoPago != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '• Pagado vía ${inv.metodoPago}',
                            style: const TextStyle(color: AppColors.accentGreen, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    if (inv.notas != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Nota: ${inv.notas}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RD\$ ${inv.monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inv.estado.displayName,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              if (!isPagada)
                ElevatedButton.icon(
                  onPressed: () => _markAsPaid(inv),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Cobrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmitInvoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emisión de Factura Fiscal DGII (NCF)',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Genere comprobantes con valor fiscal válidos ante la Dirección General de Impuestos Internos.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Selección de colegio
          const Text('Institución Educativa Destinataria', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<School>(
            value: _selectedSchoolForNew,
            dropdownColor: AppColors.cardBackground,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            ),
            items: _schools.map((s) {
              return DropdownMenuItem<School>(
                value: s,
                child: Text('${s.nombre} (${s.planName})'),
              );
            }).toList(),
            onChanged: _onSchoolChanged,
          ),
          const SizedBox(height: 16),

          // Fila de Cuota y Período
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monto de la Factura (RD\$)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        prefixText: 'RD\$ ',
                        prefixStyle: const TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Período de Facturación', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _periodoController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ej: Noviembre 2026',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tipo de NCF y Días de gracia
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Comprobante Fiscal', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTipoNCF,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'B01',
                          child: Text('B01 - Factura de Crédito Fiscal (Empresas/RNC)'),
                        ),
                        DropdownMenuItem(
                          value: 'B02',
                          child: Text('B02 - Factura de Consumo Final'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTipoNCF = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Días de Gracia para Pago', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _diasGracia,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 días (Corte estricto)')),
                        DropdownMenuItem(value: 10, child: Text('10 días')),
                        DropdownMenuItem(value: 15, child: Text('15 días (Recomendado)')),
                        DropdownMenuItem(value: 30, child: Text('30 días (Crédito mensual)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _diasGracia = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notas adicionales
          const Text('Concepto o Notas Adicionales', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _notasController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej: Licencia SaaS EDUNEX mensualidad. Incluye sucursal secundaria.',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            ),
          ),
          const SizedBox(height: 24),

          // Botón de emisión
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isEmitting ? null : _emitInvoice,
              icon: _isEmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle),
              label: Text(
                _isEmitting ? 'Emitiendo NCF...' : 'Emitir Factura con NCF',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}