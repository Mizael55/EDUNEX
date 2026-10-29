import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/saas_user.dart';
import '../repositories/school_repository.dart';

class CreateSaaSUserDialog extends StatefulWidget {
  final SchoolRepository schoolRepository;
  final ValueChanged<SaaSUser>? onUserCreated;

  const CreateSaaSUserDialog({
    super.key,
    required this.schoolRepository,
    this.onUserCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required SchoolRepository schoolRepository,
    ValueChanged<SaaSUser>? onUserCreated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateSaaSUserDialog(
        schoolRepository: schoolRepository,
        onUserCreated: onUserCreated,
      ),
    );
  }

  @override
  State<CreateSaaSUserDialog> createState() => _CreateSaaSUserDialogState();
}

class _CreateSaaSUserDialogState extends State<CreateSaaSUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  SaaSRole _selectedRole = SaaSRole.admin;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(_onFieldChanged);
    _apellidoController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onFieldChanged);
    _apellidoController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);

    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _isValid {
    final nombreValid = _nombreController.text.trim().length >= 2;
    final apellidoValid = _apellidoController.text.trim().length >= 2;
    final emailText = _emailController.text.trim();
    final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailText);
    final passwordValid = _passwordController.text.trim().length >= 6;

    return nombreValid && apellidoValid && emailValid && passwordValid;
  }

  Future<void> _submit() async {
    if (!_isValid || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newUser = await widget.schoolRepository.createSaaSUser(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        rol: _selectedRole,
        telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        password: _passwordController.text.trim(),
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        AppToast.success(
          context,
          'Se ha creado la cuenta para ${newUser.nombreCompleto} con rol ${newUser.rol.displayName}.',
          title: 'Usuario Añadido al Equipo',
        );
        widget.onUserCreated?.call(newUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(
          context,
          'No se pudo registrar el usuario: $e',
          title: 'Error de Creación',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera del Diálogo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.navyPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nuevo Miembro del Equipo SaaS',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Asigna accesos y facultades operativas para tu empresa matriz.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
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
                      // Nombres y Apellidos
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Nombres *'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nombreController,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. Carlos',
                                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
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
                                _buildLabel('Apellidos *'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _apellidoController,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. Medina',
                                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Correo Electrónico
                      _buildLabel('Correo Electrónico Corporativo *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'usuario@edunex.edu.do',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Teléfono
                      _buildLabel('Teléfono de Contacto (Opcional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '809-555-0123',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Selección de Rol
                      _buildLabel('Rol en la Empresa SaaS *'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SaaSRole>(
                            value: _selectedRole,
                            isExpanded: true,
                            items: SaaSRole.values.map((rol) {
                              return DropdownMenuItem<SaaSRole>(
                                value: rol,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: rol.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(rol.icon, size: 16, color: rol.color),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            rol.displayName,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                                          ),
                                          Text(
                                            rol.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRole = val);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contraseña Inicial
                      _buildLabel('Contraseña Inicial Provisoria *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Mínimo 6 caracteres',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notas
                      _buildLabel('Notas u Observaciones (Opcional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notasController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ej. Coordinador de cobranzas zona Norte',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botones de Acción
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isValid && !_isLoading ? _submit : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(_isLoading ? 'Guardando...' : 'Crear Usuario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      disabledBackgroundColor: AppColors.navyPrimary.withValues(alpha: 0.35),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navyPrimary,
      ),
    );
  }
}
