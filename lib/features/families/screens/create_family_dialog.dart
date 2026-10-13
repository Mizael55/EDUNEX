import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../repositories/family_repository.dart';

/// Modal para dar de alta una nueva Cuenta Familiar Única en EDUNEX
class CreateFamilyDialog extends StatefulWidget {
  final FamilyRepository repository;
  final String colegioId;
  final ValueChanged<Family>? onFamilyCreated;

  const CreateFamilyDialog({
    super.key,
    required this.repository,
    this.colegioId = 'a0000000-0000-0000-0000-000000000001',
    this.onFamilyCreated,
  });

  static Future<Family?> show(
    BuildContext context, {
    required FamilyRepository repository,
    String colegioId = 'a0000000-0000-0000-0000-000000000001',
    ValueChanged<Family>? onFamilyCreated,
  }) {
    return showDialog<Family>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateFamilyDialog(
        repository: repository,
        colegioId: colegioId,
        onFamilyCreated: onFamilyCreated,
      ),
    );
  }

  @override
  State<CreateFamilyDialog> createState() => _CreateFamilyDialogState();
}

class _CreateFamilyDialogState extends State<CreateFamilyDialog> {
  final _formKey = GlobalKey<FormState>();

  // Datos de la Familia
  final _nombreFamiliaController = TextEditingController();
  final _direccionController = TextEditingController();

  // Tutor Principal
  final _tutorNombresController = TextEditingController();
  final _tutorApellidosController = TextEditingController();
  final _tutorEmailController = TextEditingController();
  final _tutorTelefonoController = TextEditingController();
  final _tutorCedulaController = TextEditingController();
  String _selectedParentesco = 'Padre';

  // Alumno Inicial
  final _estudianteNombresController = TextEditingController();
  final _estudianteApellidosController = TextEditingController();
  String _selectedGrado = '1ro de Primaria';

  // Financiero
  final _balanceInicialController = TextEditingController(text: '0.00');

  bool _isLoading = false;

  final List<String> _parentescos = ['Padre', 'Madre', 'Tutor Legal', 'Abuelo / Abuela', 'Tío / Tía'];
  final List<String> _grados = [
    'Maternal (1-2 años)',
    'Párvulos (2-3 años)',
    'Pre-Kínder (3-4 años)',
    'Kínder (4-5 años)',
    'Pre-Primario (5-6 años)',
    '1ro de Primaria',
    '2do de Primaria',
    '3ro de Primaria',
    '4to de Primaria',
    '5to de Primaria',
    '6to de Primaria',
    '1ro de Secundaria',
    '2do de Secundaria',
    '3ro de Secundaria',
    '4to de Secundaria',
  ];

  @override
  void dispose() {
    _nombreFamiliaController.dispose();
    _direccionController.dispose();
    _tutorNombresController.dispose();
    _tutorApellidosController.dispose();
    _tutorEmailController.dispose();
    _tutorTelefonoController.dispose();
    _tutorCedulaController.dispose();
    _estudianteNombresController.dispose();
    _estudianteApellidosController.dispose();
    _balanceInicialController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final balance = double.tryParse(_balanceInicialController.text.trim()) ?? 0.0;
      final family = await widget.repository.createFamily(
        colegioId: widget.colegioId,
        nombreFamilia: _nombreFamiliaController.text.trim(),
        tutorNombres: _tutorNombresController.text.trim(),
        tutorApellidos: _tutorApellidosController.text.trim(),
        tutorEmail: _tutorEmailController.text.trim(),
        tutorTelefono: _tutorTelefonoController.text.trim(),
        parentesco: _selectedParentesco,
        cedula: _tutorCedulaController.text.trim().isNotEmpty ? _tutorCedulaController.text.trim() : null,
        direccion: _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
        balanceInicial: balance,
        estudianteNombres: _estudianteNombresController.text.trim().isNotEmpty ? _estudianteNombresController.text.trim() : null,
        estudianteApellidos: _estudianteApellidosController.text.trim().isNotEmpty ? _estudianteApellidosController.text.trim() : null,
        gradoNombre: _selectedGrado,
      );

      if (mounted) {
        widget.onFamilyCreated?.call(family);
        Navigator.of(context).pop(family);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta "${family.nombreFamilia}" creada exitosamente con código ${family.codigoFamilia}'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la cuenta familiar: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del diálogo
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.electricBlue],
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
                      color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_add_rounded, color: AppColors.surfaceWhite, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar Nueva Cuenta Familiar',
                          style: TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Centraliza a los tutores legales, estudiantes y balance en una sola ficha.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.surfaceWhite),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                      // SECCIÓN 1: Identidad Familiar
                      _buildSectionHeader(
                        icon: Icons.family_restroom_rounded,
                        title: '1. Identidad de la Cuenta Familiar',
                        subtitle: 'Nombre descriptivo de la familia para recibos y comunicaciones',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombreFamiliaController,
                        decoration: InputDecoration(
                          labelText: 'Nombre Familiar (Ej: Familia Pérez González) *',
                          prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.navyPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre de la familia' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _direccionController,
                        decoration: InputDecoration(
                          labelText: 'Dirección Residencial (Sector / Calle / Edificio)',
                          prefixIcon: const Icon(Icons.home_rounded, color: AppColors.navyPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      // SECCIÓN 2: Tutor Legal Principal
                      _buildSectionHeader(
                        icon: Icons.person_rounded,
                        title: '2. Tutor Legal / Contacto Principal',
                        subtitle: 'Responsable financiero y representante ante el colegio',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tutorNombresController,
                              decoration: InputDecoration(
                                labelText: 'Nombres *',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tutorApellidosController,
                              decoration: InputDecoration(
                                labelText: 'Apellidos *',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedParentesco,
                              decoration: InputDecoration(
                                labelText: 'Parentesco *',
                                prefixIcon: const Icon(Icons.people_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: _parentescos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedParentesco = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tutorCedulaController,
                              decoration: InputDecoration(
                                labelText: 'Cédula o Pasaporte',
                                hintText: '001-XXXXXXX-X',
                                prefixIcon: const Icon(Icons.credit_card_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tutorTelefonoController,
                              decoration: InputDecoration(
                                labelText: 'Teléfono / Móvil *',
                                hintText: '809-555-0000',
                                prefixIcon: const Icon(Icons.phone_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el teléfono' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tutorEmailController,
                              decoration: InputDecoration(
                                labelText: 'Correo Electrónico *',
                                hintText: 'tutor@ejemplo.com',
                                prefixIcon: const Icon(Icons.email_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa el correo';
                                if (!v.contains('@')) return 'Correo no válido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      // SECCIÓN 3: Alumno Inicial (Hijo/Hija)
                      _buildSectionHeader(
                        icon: Icons.school_rounded,
                        title: '3. Primer Estudiante de la Familia (Opcional)',
                        subtitle: 'Puedes matricular el primer alumno ahora o añadirlo después',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _estudianteNombresController,
                              decoration: InputDecoration(
                                labelText: 'Nombres del Estudiante',
                                prefixIcon: const Icon(Icons.child_care_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _estudianteApellidosController,
                              decoration: InputDecoration(
                                labelText: 'Apellidos del Estudiante',
                                prefixIcon: const Icon(Icons.child_care_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGrado,
                        decoration: InputDecoration(
                          labelText: 'Nivel / Grado Escolar',
                          prefixIcon: const Icon(Icons.grade_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedGrado = v);
                        },
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      // SECCIÓN 4: Balance Inicial
                      _buildSectionHeader(
                        icon: Icons.account_balance_wallet_rounded,
                        title: '4. Balance Contable Inicial',
                        subtitle: 'Saldo pendiente por inscripción o colegiatura (RD\$)',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _balanceInicialController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Balance Inicial Pendiente (RD\$)',
                          prefixText: 'RD\$ ',
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Acciones Inferiores
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
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isLoading ? 'Guardando...' : 'Crear Cuenta Familiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
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

  Widget _buildSectionHeader({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.navyPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.navyPrimary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
