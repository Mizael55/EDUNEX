import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/school.dart';
import '../models/saas_invoice.dart';
import '../repositories/school_repository.dart';

/// Pantalla completa de Cobranza SaaS y Facturación con NCF para el Menú Lateral
class SaasBillingScreen extends StatefulWidget {
  final SchoolRepository schoolRepository;

  const SaasBillingScreen({super.key, required this.schoolRepository});

  @override
  State<SaasBillingScreen> createState() => _SaasBillingScreenState();
}

class _SaasBillingScreenState extends State<SaasBillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SaaSInvoice> _invoices = [];
  List<School> _schools = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  // Formulario nueva factura
  School? _selectedSchool;
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
    final schools = await widget.schoolRepository.getSchools();
    final invoices = await widget.schoolRepository.getSaaSInvoices();

    if (mounted) {
      setState(() {
        _schools = schools;
        _invoices = invoices;
        if (schools.isNotEmpty && _selectedSchool == null) {
          _selectedSchool = schools.first;
          _montoController.text = _selectedSchool!.cuotaMensualSaaS.toStringAsFixed(0);
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
      _selectedSchool = school;
      _montoController.text = school.cuotaMensualSaaS.toStringAsFixed(0);
    });
  }

  Future<void> _emitInvoice() async {
    if (_selectedSchool == null) {
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
      final invoice = await widget.schoolRepository.generateSaaSInvoice(
        schoolId: _selectedSchool!.id,
        schoolName: _selectedSchool!.nombre,
        monto: monto,
        periodo: _periodoController.text.trim(),
        rnc: _selectedSchool!.rnc,
        tipoNCF: _selectedTipoNCF,
        diasGracia: _diasGracia,
        notas: _notasController.text.trim().isNotEmpty ? _notasController.text.trim() : null,
      );

      if (mounted) {
        AppToast.success(
          context,
          'Factura NCF ${invoice.ncf} emitida exitosamente para ${_selectedSchool!.nombre}',
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
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 24),
            SizedBox(width: 8),
            Text('Registrar Cobro SaaS', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
      await widget.schoolRepository.recordInvoicePayment(
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
    final filteredInvoices = _invoices.where((i) {
      if (_statusFilter == 'paid') return i.estado == SaaSInvoiceStatus.pagada;
      if (_statusFilter == 'pending') return i.estado == SaaSInvoiceStatus.pendiente;
      if (_statusFilter == 'overdue') return i.estado == SaaSInvoiceStatus.enMora;
      return true;
    }).toList();

    final totalFacturado = _invoices.fold<double>(0.0, (s, i) => s + i.monto);
    final totalCobrado = _invoices.where((i) => i.estado == SaaSInvoiceStatus.pagada).fold<double>(0.0, (s, i) => s + i.monto);
    final totalPendiente = _invoices.where((i) => i.estado != SaaSInvoiceStatus.pagada).fold<double>(0.0, (s, i) => s + i.monto);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Moderna acorde a la Guía Visual
            _buildTopHeader(),
            const SizedBox(height: 20),

            // Fila de 3 KPIs de Facturación SaaS
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final tiles = [
                  _buildBillingKpi(
                    title: 'Total Facturado SaaS',
                    value: 'RD\$ ${totalFacturado.toStringAsFixed(2)}',
                    subtext: '${_invoices.length} facturas emitidas',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF1D4ED8),
                  ),
                  _buildBillingKpi(
                    title: 'Cobros Recaudados',
                    value: 'RD\$ ${totalCobrado.toStringAsFixed(2)}',
                    subtext: 'Ingresos confirmados en banco',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.accentGreen,
                  ),
                  _buildBillingKpi(
                    title: 'Pendiente de Cobro',
                    value: 'RD\$ ${totalPendiente.toStringAsFixed(2)}',
                    subtext: '${_invoices.where((i) => i.estado != SaaSInvoiceStatus.pagada).length} facturas por cobrar',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.amberAccent,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: tiles.map((t) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: t))).toList(),
                  );
                }
                return Column(
                  children: tiles.map((t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: t)).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1D4ED8),
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: const Color(0xFF1D4ED8),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                    text: 'Listado de Facturas (${_invoices.length})',
                  ),
                  const Tab(
                    icon: Icon(Icons.post_add_rounded, size: 18),
                    text: 'Emitir Factura con NCF DGII',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contenedor principal de pestañas
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInvoicesListTab(filteredInvoices),
                          _buildEmitInvoiceTab(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
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
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'MÓDULO DE COBRANZA SAAS',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Text('Facturación Institucional y NCF DGII', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Cobranza SaaS y Facturas Fiscales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Emisión de comprobantes fiscales B01 y B02, registro de pagos mensuales y control de mora para colegios clientes.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _tabController.animateTo(1),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          label: const Text('+ Emitir Nueva Factura'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingKpi({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                const SizedBox(height: 2),
                Text(subtext, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesListTab(List<SaaSInvoice> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text(
              'No hay facturas registradas en este momento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Utiliza la pestaña "Emitir Factura con NCF DGII" para generar el primer comprobante.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtros rápidos
        Row(
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) => setState(() => _statusFilter = 'all'),
                ),
                ChoiceChip(
                  label: const Text('Pendientes'),
                  selected: _statusFilter == 'pending',
                  onSelected: (_) => setState(() => _statusFilter = 'pending'),
                ),
                ChoiceChip(
                  label: const Text('Pagadas'),
                  selected: _statusFilter == 'paid',
                  onSelected: (_) => setState(() => _statusFilter = 'paid'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final inv = list[index];
              final isPaid = inv.estado == SaaSInvoiceStatus.pagada;

              Color statusColor = isPaid ? AppColors.accentGreen : AppColors.amberAccent;
              if (inv.estado == SaaSInvoiceStatus.enMora) statusColor = Colors.redAccent;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                inv.colegioNombre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                              ),
                              const SizedBox(width: 8),
                              if (inv.ncf != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'NCF: ${inv.ncf}',
                                    style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Período: ${inv.periodo} • Vence: ${inv.fechaVencimiento.day}/${inv.fechaVencimiento.month}/${inv.fechaVencimiento.year}${isPaid && inv.metodoPago != null ? " • Pagado vía ${inv.metodoPago}" : ""}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (inv.notas != null) ...[
                            const SizedBox(height: 2),
                            Text('Nota: ${inv.notas}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RD\$ ${inv.monto.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            inv.estado.displayName,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (!isPaid) ...[
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: () => _markAsPaid(inv),
                        icon: const Icon(Icons.payment_rounded, size: 16),
                        label: const Text('Cobrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmitInvoiceTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Formulario de Emisión de Factura Fiscal DGII (NCF)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Emita un comprobante formal con valor fiscal según la normativa de la Dirección General de Impuestos Internos.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Selección de institución
          const Text('Institución Educativa Destinataria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<School>(
            value: _selectedSchool,
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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

          // Fila Cuota y Período
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monto de la Factura (RD\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'RD\$ ',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
                    const Text('Período de Facturación', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _periodoController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Noviembre 2026',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fila Tipo NCF y Días Gracia
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de NCF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTipoNCF,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'B01', child: Text('B01 - Factura de Crédito Fiscal')),
                        DropdownMenuItem(value: 'B02', child: Text('B02 - Factura de Consumo Final')),
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
                    const Text('Días de Gracia para Vencimiento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _diasGracia,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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

          // Notas
          const Text('Concepto o Notas Adicionales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _notasController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ej: Licencia SaaS EDUNEX mensualidad. Incluye sucursal secundaria.',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 24),

          // Botón emitir
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isEmitting ? null : _emitInvoice,
              icon: _isEmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isEmitting ? 'Emitiendo NCF...' : 'Emitir Factura con NCF',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
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