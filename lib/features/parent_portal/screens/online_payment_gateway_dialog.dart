import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../families/models/family.dart';
import '../models/payment_receipt.dart';
import '../../families/repositories/family_repository.dart';

/// Modal interactivo de Pasarela de Pagos en Línea (Tarjeta de Crédito / Débito CardNET / Azul)
class OnlinePaymentGatewayDialog extends StatefulWidget {
  final Family family;
  final FamilyRepository familyRepository;
  final VoidCallback onPaymentSuccess;

  const OnlinePaymentGatewayDialog({
    super.key,
    required this.family,
    required this.familyRepository,
    required this.onPaymentSuccess,
  });

  static Future<PaymentReceipt?> show({
    required BuildContext context,
    required Family family,
    required FamilyRepository familyRepository,
    required VoidCallback onPaymentSuccess,
  }) {
    return showDialog<PaymentReceipt?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OnlinePaymentGatewayDialog(
        family: family,
        familyRepository: familyRepository,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<OnlinePaymentGatewayDialog> createState() => _OnlinePaymentGatewayDialogState();
}

class _OnlinePaymentGatewayDialogState extends State<OnlinePaymentGatewayDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _conceptController;
  late TextEditingController _cardNumberController;
  late TextEditingController _holderNameController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;

  bool _isFullBalance = true;
  bool _isProcessing = false;
  bool _saveCard = false;

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.family.balancePendiente > 0 ? widget.family.balancePendiente : 8500.0;
    _amountController = TextEditingController(text: defaultAmount.toStringAsFixed(2));
    _conceptController = TextEditingController(text: 'Colegiatura y Servicios Escolares');

    final defaultHolder = widget.family.tutores.isNotEmpty
        ? widget.family.tutores.first.nombreCompleto
        : widget.family.nombreFamilia;

    _holderNameController = TextEditingController(text: defaultHolder);
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();

    _cardNumberController.addListener(() => setState(() {}));
    _holderNameController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
    _cvvController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _conceptController.dispose();
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _cardBrand {
    final text = _cardNumberController.text.replaceAll(' ', '');
    if (text.startsWith('4')) return 'VISA';
    if (text.startsWith('5')) return 'MASTERCARD';
    if (text.startsWith('3')) return 'AMEX';
    return 'CARD';
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto válido mayor a 0')),
      );
      return;
    }

    final rawCard = _cardNumberController.text.replaceAll(' ', '');
    if (rawCard.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un número de tarjeta válido (16 dígitos)')),
      );
      return;
    }

    if (_expiryController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una fecha de expiración válida (MM/AA)')),
      );
      return;
    }

    if (_cvvController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el código de seguridad CVV (3 dígitos)')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulación de respuesta bancaria y 3D-Secure
    await Future.delayed(const Duration(milliseconds: 700));

    final last4 = rawCard.length >= 4 ? rawCard.substring(rawCard.length - 4) : '9010';
    final authCode = 'AUTH-CARDNET-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    PaymentReceipt receipt;
    try {
      receipt = await widget.familyRepository.recordPayment(
        familiaId: widget.family.id,
        monto: amount,
        concepto: _conceptController.text.trim().isEmpty ? 'Pago de Colegiatura en Línea' : _conceptController.text.trim(),
        metodo: 'Tarjeta de Crédito / $_cardBrand (•••• $last4)',
        referencia: authCode,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar pago: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (mounted) {
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      widget.onPaymentSuccess();
      nav.pop(receipt);

      messenger.showSnackBar(
        SnackBar(
          content: Text('¡Pago autorizado exitosamente por el banco! NCF: ${receipt.ncf}'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 850),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.credit_card_rounded, color: AppColors.navyPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pasarela de Pago Seguro en Línea',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Familia: ${widget.family.nombreFamilia}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Visual Credit Card Preview
              _buildVisualCreditCard(),

              const SizedBox(height: 20),

              // Selección de Monto (Total vs Parcial)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        'Pagar Balance Total (RD\$ ${widget.family.balancePendiente.toStringAsFixed(2)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _isFullBalance ? FontWeight.bold : FontWeight.normal,
                          color: _isFullBalance ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: _isFullBalance,
                      selectedColor: AppColors.navyPrimary,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _isFullBalance = true;
                            _amountController.text = widget.family.balancePendiente.toStringAsFixed(2);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: Text(
                      'Otro Monto',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isFullBalance ? FontWeight.bold : FontWeight.normal,
                        color: !_isFullBalance ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: !_isFullBalance,
                    selectedColor: AppColors.navyPrimary,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _isFullBalance = false);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Campos del formulario
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            readOnly: _isFullBalance,
                            decoration: const InputDecoration(
                              labelText: 'Monto a Pagar (RD\$)',
                              prefixText: 'RD\$ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: _conceptController,
                            decoration: const InputDecoration(
                              labelText: 'Concepto de Pago',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Número de Tarjeta
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Número de Tarjeta de Crédito / Débito',
                        hintText: '4000 1234 5678 9010',
                        prefixIcon: const Icon(Icons.payment_rounded),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildBrandIcon(),
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Titular de la Tarjeta
                    TextFormField(
                      controller: _holderNameController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Titular (como figura en la tarjeta)',
                        prefixIcon: Icon(Icons.person_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Expiración y CVV
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _CardExpiryInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Vencimiento (MM/AA)',
                              hintText: '12/28',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'CVV / CVC',
                              hintText: '123',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Checkbox para guardar tarjeta
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _saveCard,
                      title: const Text(
                        'Guardar tarjeta de forma segura para pagos recurrentes automáticos',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) => setState(() => _saveCard = val ?? false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Badges de Seguridad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded, color: AppColors.accentGreen, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Encriptación Bancaria 256-Bit SSL • Certificación PCI-DSS CardNET',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processPayment,
                      icon: _isProcessing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.lock_rounded, size: 18),
                      label: Text(
                        _isProcessing
                            ? 'Autorizando Pago...'
                            : 'Pagar RD\$ ${_amountController.text}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCreditCard() {
    final rawNumber = _cardNumberController.text;
    final displayCardNumber = rawNumber.isEmpty ? '•••• •••• •••• ••••' : rawNumber;
    final displayHolder = _holderNameController.text.isEmpty ? 'NOMBRE DEL TITULAR' : _holderNameController.text.toUpperCase();
    final displayExpiry = _expiryController.text.isEmpty ? 'MM/AA' : _expiryController.text;

    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2B714),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.memory_rounded, color: Colors.black54, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.contactless_rounded, color: Colors.white70, size: 22),
                ],
              ),
              Text(
                _cardBrand,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          Text(
            displayCardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TITULAR', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                    Text(
                      displayHolder,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRA', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                  Text(
                    displayExpiry,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandIcon() {
    switch (_cardBrand) {
      case 'VISA':
        return const Text('VISA', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1F71), fontSize: 13));
      case 'MASTERCARD':
        return const Text('MC', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEB001B), fontSize: 13));
      case 'AMEX':
        return const Text('AMEX', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF006FCF), fontSize: 13));
      default:
        return const Icon(Icons.credit_card, size: 18, color: Colors.grey);
    }
  }
}

/// Formateador para separar números de tarjeta de crédito cada 4 dígitos
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formateador para fecha de expiración MM/AA
class _CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
