import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../superadmin/models/school.dart';
import '../../superadmin/repositories/school_repository.dart';

/// Pantalla para que el Administrador del Centro Educativo configure su Método de Pago y Suscripción SaaS (Issue #23 Caso 2)
class SchoolPaymentMethodScreen extends StatefulWidget {
  final String? colegioId;
  final SchoolRepository? schoolRepository;
  final VoidCallback? onPaymentMethodConfigured;

  const SchoolPaymentMethodScreen({
    super.key,
    this.colegioId,
    this.schoolRepository,
    this.onPaymentMethodConfigured,
  });

  @override
  State<SchoolPaymentMethodScreen> createState() => _SchoolPaymentMethodScreenState();
}

class _SchoolPaymentMethodScreenState extends State<SchoolPaymentMethodScreen> {
  late final SchoolRepository _schoolRepository;
  School? _school;
  bool _isLoading = true;
  bool _isSaving = false;

  int _selectedPaymentType = 0; // 0: Tarjeta de Crédito/Débito, 1: Transferencia Bancaria

  // Formulario Tarjeta
  final _cardHolderController = TextEditingController(text: 'Director del Centro');
  final _cardNumberController = TextEditingController(text: '4242 •••• •••• 4242');
  final _cardExpiryController = TextEditingController(text: '12/28');
  final _cardCvcController = TextEditingController(text: '888');

  // Formulario Transferencia
  final _bankTransferReferenceController = TextEditingController(text: 'TRANS-2026-');
  String _selectedBank = 'Banco Popular Dominicano';

  @override
  void initState() {
    super.initState();
    _schoolRepository = widget.schoolRepository ?? SchoolRepository(useDemoFallback: false);
    _loadSchool();
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _bankTransferReferenceController.dispose();
    super.dispose();
  }

  Future<void> _loadSchool() async {
    setState(() => _isLoading = true);
    try {
      if (widget.colegioId != null) {
        final sc = await _schoolRepository.getSchoolById(widget.colegioId!);
        if (mounted) {
          setState(() {
            _school = sc;
            _isLoading = false;
          });
          return;
        }
      }
      final list = await _schoolRepository.getSchools();
      if (mounted) {
        setState(() {
          _school = list.isNotEmpty ? list.first : null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePaymentMethod() async {
    if (_school == null) return;
    setState(() => _isSaving = true);

    try {
      final methodDesc = _selectedPaymentType == 0
          ? 'Tarjeta Visa/MasterCard terminada en ${_cardNumberController.text.trim().replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0').substring(0)} (Titular: ${_cardHolderController.text.trim()})'
          : 'Transferencia Bancaria $_selectedBank (Ref: ${_bankTransferReferenceController.text.trim()})';

      // Actualizar colegio con método de pago registrado y suscripción activa
      await _schoolRepository.updateSchoolSubscription(
        schoolId: _school!.id,
        newStatus: 'active',
        metodoPago: methodDesc,
      );

      final updated = _school!.copyWith(
        metodoPago: methodDesc,
        metodoPagoRegistrado: true,
        estadoSuscripcion: 'active',
      );

      if (mounted) {
        setState(() {
          _school = updated;
          _isSaving = false;
        });

        widget.onPaymentMethodConfigured?.call();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 28),
                SizedBox(width: 10),
                Text('Método de Pago Registrado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Tu centro educativo (${_school!.nombre}) ahora cuenta con método de pago activo!',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Método configurado: $methodDesc\n• Cuota mensual: RD\$ ${_school!.cuotaMensualSaaS.toStringAsFixed(2)}\n• Estado: Enrolamiento de alumnos desbloqueado al 100%.',
                  style: const TextStyle(fontSize: 13, color: AppColors.navyPrimary),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, 'Error registrando método de pago: $e', title: 'Error');
      }
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

    final school = _school;
    final cuotaMensual = school?.cuotaMensualSaaS ?? 7000.0;
    final cuotaAnual = school?.cuotaAnualSaaS ?? 84000.0;
    final hasPayment = school?.tieneMetodoPagoValido ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.credit_card_rounded, color: AppColors.navyPrimary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Método de Pago & Suscripción Escolar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestiona la vía de pago de tu centro educativo para habilitar y mantener activo el enrolamiento de alumnos.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Banner de Estado de Suscripción y Enrolamiento
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasPayment ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasPayment ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasPayment ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
                    color: hasPayment ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPayment
                              ? 'Suscripción Activa — Enrolamiento de Alumnos Habilitado'
                              : 'Método de Pago Requerido — Enrolamiento Bloqueado (Issue #23)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: hasPayment ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPayment
                            ? 'Tu centro tiene configurado un método de cobro recurrente (${school?.metodoPago ?? "Tarjeta / Transferencia activa"}).'
                            : 'Para activar el botón de enrolar alumnos en el sistema, debes vincular una tarjeta o adjuntar tu transferencia bancaria.',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasPayment ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tarjeta de Detalle del Plan SaaS según rango de alumnos
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: AppColors.navyPrimary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        school?.nombre ?? 'Centro Educativo Cliente',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${school?.maxEstudiantes ?? 500} Estudiantes',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.electricBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tarifa Mensual Recurrente:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              'RD\$ ${cuotaMensual.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.navyPrimary),
                            ),
                            Text(
                              (school?.maxEstudiantes ?? 500) <= 250
                                  ? 'Escala: 100 - 250 alumnos (RD\$ 4,000)'
                                  : (school?.maxEstudiantes ?? 500) <= 400
                                      ? 'Escala: 251 - 400 alumnos (RD\$ 5,500)'
                                      : 'Escala: 450+ alumnos (RD\$ 7,000)',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Facturación Anualizada:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              'RD\$ ${cuotaAnual.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.accentGreen),
                            ),
                            const Text('Pagos mensuales x 12 meses', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Selector de Método de Pago: Tarjeta vs Transferencia
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Vía de Pago',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.credit_card_rounded, size: 18),
                          label: const Text('Tarjeta de Crédito / Débito'),
                          selected: _selectedPaymentType == 0,
                          onSelected: (val) {
                            if (val) setState(() => _selectedPaymentType = 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.account_balance_rounded, size: 18),
                          label: const Text('Transferencia Bancaria'),
                          selected: _selectedPaymentType == 1,
                          onSelected: (val) {
                            if (val) setState(() => _selectedPaymentType = 1);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_selectedPaymentType == 0) ...[
                    // Formulario Tarjeta
                    TextFormField(
                      controller: _cardHolderController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Titular de la Tarjeta *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número de Tarjeta *',
                        prefixIcon: Icon(Icons.credit_card_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cardExpiryController,
                            decoration: const InputDecoration(
                              labelText: 'Vencimiento (MM/AA) *',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cardCvcController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'CVC / CVV *',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Formulario Transferencia Bancaria
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cuentas Bancarias de EDUNEX Dominicana SRL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                          SizedBox(height: 6),
                          Text('• Banco Popular Dominicano — Cuenta Corriente: 801-928374-1'),
                          Text('• Banco de Reservas (Banreservas) — Cuenta Corriente: 240-019283-4'),
                          Text('• RNC Institucional EDUNEX: 1-31-89234-5'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: const InputDecoration(
                        labelText: 'Banco Emisor *',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Banco Popular Dominicano', child: Text('Banco Popular Dominicano')),
                        DropdownMenuItem(value: 'Banco de Reservas (Banreservas)', child: Text('Banco de Reservas (Banreservas)')),
                        DropdownMenuItem(value: 'Banco BHD', child: Text('Banco BHD')),
                        DropdownMenuItem(value: 'Scotiabank República Dominicana', child: Text('Scotiabank')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBank = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bankTransferReferenceController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Comprobante / Referencia de Transferencia *',
                        prefixIcon: Icon(Icons.receipt_long_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePaymentMethod,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.verified_user_rounded, size: 20),
                    label: Text(
                      _isSaving ? 'Guardando...' : 'Guardar Método de Pago y Habilitar Enrolamiento',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
