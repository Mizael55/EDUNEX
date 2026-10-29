import 'package:flutter/material.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/school_logo_avatar.dart';
import '../../../theme/app_colors.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';

/// Diálogo interactivo para que el SuperAdmin edite la información de registro de un colegio cliente
class EditSchoolDialog extends StatefulWidget {
  final School school;
  final SchoolRepository repository;

  const EditSchoolDialog({
    super.key,
    required this.school,
    required this.repository,
  });

  static Future<School?> show(
    BuildContext context, {
    required School school,
    required SchoolRepository repository,
  }) {
    return showDialog<School>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditSchoolDialog(
        school: school,
        repository: repository,
      ),
    );
  }

  @override
  State<EditSchoolDialog> createState() => _EditSchoolDialogState();
}

class _EditSchoolDialogState extends State<EditSchoolDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _siglasController;
  late TextEditingController _rncController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _direccionController;
  late TextEditingController _maxEstudiantesController;
  late TextEditingController _directorNombreController;
  late TextEditingController _directorCedulaController;
  late TextEditingController _directorTelefonoController;
  late TextEditingController _directorEmailController;

  String? _logoUrl;
  bool _isSaving = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final s = widget.school;
    _logoUrl = s.logoUrl;
    _nombreController = TextEditingController(text: s.nombre);
    _siglasController = TextEditingController(text: s.siglas ?? '');
    _rncController = TextEditingController(text: s.rnc ?? '');
    _telefonoController = TextEditingController(text: s.telefono ?? '');
    _emailController = TextEditingController(text: s.emailContacto ?? '');
    _direccionController = TextEditingController(text: s.direccion ?? '');
    _maxEstudiantesController = TextEditingController(text: s.maxEstudiantes.toString());
    _directorNombreController = TextEditingController(text: s.directorNombre ?? '');
    _directorCedulaController = TextEditingController(text: s.directorCedula ?? '');
    _directorTelefonoController = TextEditingController(text: s.directorTelefono ?? s.telefono ?? '');
    _directorEmailController = TextEditingController(text: s.directorEmail ?? '');

    _nombreController.addListener(_onFieldChanged);
    _siglasController.addListener(_onFieldChanged);
    _rncController.addListener(_onFieldChanged);
    _telefonoController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _direccionController.addListener(_onFieldChanged);
    _maxEstudiantesController.addListener(_onFieldChanged);
    _directorNombreController.addListener(_onFieldChanged);
    _directorCedulaController.addListener(_onFieldChanged);
    _directorTelefonoController.addListener(_onFieldChanged);
    _directorEmailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onFieldChanged);
    _siglasController.removeListener(_onFieldChanged);
    _rncController.removeListener(_onFieldChanged);
    _telefonoController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _direccionController.removeListener(_onFieldChanged);
    _maxEstudiantesController.removeListener(_onFieldChanged);
    _directorNombreController.removeListener(_onFieldChanged);
    _directorCedulaController.removeListener(_onFieldChanged);
    _directorTelefonoController.removeListener(_onFieldChanged);
    _directorEmailController.removeListener(_onFieldChanged);

    _nombreController.dispose();
    _siglasController.dispose();
    _rncController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _maxEstudiantesController.dispose();
    _directorNombreController.dispose();
    _directorCedulaController.dispose();
    _directorTelefonoController.dispose();
    _directorEmailController.dispose();
    super.dispose();
  }

  /// Verifica si todos los campos requeridos están llenos para habilitar el guardado
  bool get _isFormReady {
    return _nombreController.text.trim().isNotEmpty &&
        _siglasController.text.trim().isNotEmpty &&
        _rncController.text.trim().isNotEmpty &&
        _telefonoController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _direccionController.text.trim().isNotEmpty &&
        _maxEstudiantesController.text.trim().isNotEmpty &&
        _directorNombreController.text.trim().isNotEmpty &&
        _directorCedulaController.text.trim().isNotEmpty &&
        _directorTelefonoController.text.trim().isNotEmpty &&
        _directorEmailController.text.trim().isNotEmpty;
  }

  double _calculateSaaSFee() {
    final count = int.tryParse(_maxEstudiantesController.text.trim()) ?? widget.school.maxEstudiantes;
    double base;
    if (count <= 250) {
      base = 4000.0;
    } else if (count <= 400) {
      base = 5500.0;
    } else {
      base = 7000.0;
    }
    if (widget.school.sucursalesCount > 0) {
      base += base * 0.15 * widget.school.sucursalesCount;
    }
    return base;
  }

  Future<void> _pickLogo() async {
    setState(() => _isUploadingLogo = true);
    try {
      final picked = await FileUploadService.pickRealFile();
      if (picked != null) {
        setState(() {
          _logoUrl = picked.dataUrl;
        });
        if (mounted) {
          AppToast.success(
            context,
            'Imagen de logotipo seleccionada correctamente (${picked.sizeFormatted})',
            title: 'Logotipo Actualizado',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error al cargar imagen: $e', title: 'Error');
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(
        context,
        'Por favor completa todos los campos obligatorios con formatos válidos.',
        title: 'Formulario Incompleto',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await widget.repository.updateSchoolRegistration(
        schoolId: widget.school.id,
        nombre: _nombreController.text.trim(),
        siglas: _siglasController.text.trim(),
        rnc: _rncController.text.trim(),
        telefono: _telefonoController.text.trim(),
        emailContacto: _emailController.text.trim(),
        direccion: _direccionController.text.trim(),
        maxEstudiantes: int.tryParse(_maxEstudiantesController.text.trim()) ?? widget.school.maxEstudiantes,
        directorNombre: _directorNombreController.text.trim(),
        directorCedula: _directorCedulaController.text.trim(),
        directorTelefono: _directorTelefonoController.text.trim(),
        directorEmail: _directorEmailController.text.trim(),
        logoUrl: _logoUrl?.trim(),
      );

      if (mounted) {
        AppToast.success(
          context,
          'La información del colegio y su director fue actualizada exitosamente.',
          title: 'Colegio Actualizado',
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          'No se pudieron guardar los cambios: $e',
          title: 'Error de Actualización',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saasFee = _calculateSaaSFee();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.navyPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Información de Registro',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Modifica los datos oficiales del colegio en la base de datos central.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Formulario desplazable
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECCIÓN: Identidad Visual y Logotipo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              SchoolLogoAvatar(
                                logoUrl: _logoUrl,
                                fallbackText: _siglasController.text.isNotEmpty
                                    ? _siglasController.text
                                    : _nombreController.text,
                                radius: 34,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Logotipo / Emblema Oficial del Colegio',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _logoUrl != null && _logoUrl!.isNotEmpty
                                          ? 'Imagen institucional activa. Puedes reemplazarla seleccionando un nuevo archivo.'
                                          : 'No tiene imagen asignada. Se muestran las siglas iniciales por defecto.',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: (_isSaving || _isUploadingLogo) ? null : _pickLogo,
                                icon: _isUploadingLogo
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.photo_camera_rounded, size: 16),
                                label: Text(
                                  _logoUrl != null && _logoUrl!.isNotEmpty ? 'Cambiar Foto' : 'Subir Imagen',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navyPrimary,
                                  side: const BorderSide(color: AppColors.navyPrimary),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (_logoUrl != null && _logoUrl!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Quitar imagen',
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  onPressed: _isSaving ? null : () => setState(() => _logoUrl = null),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sección: Datos Institucionales
                        const Row(
                          children: [
                            Icon(Icons.business_rounded, size: 18, color: AppColors.navyPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Datos Institucionales & Legales',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Oficial del Centro *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'El nombre oficial es obligatorio' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _siglasController,
                                decoration: const InputDecoration(
                                  labelText: 'Siglas / Acrónimo *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.short_text_rounded, size: 20),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Las siglas son obligatorias' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _rncController,
                                decoration: const InputDecoration(
                                  labelText: 'RNC Institucional (9 u 11 dígitos) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'El RNC es obligatorio';
                                  final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (digits.length != 9 && digits.length != 11) {
                                    return 'El RNC debe contener 9 u 11 dígitos (actual: ${digits.length})';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _telefonoController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono Institucional *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'El teléfono es obligatorio' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo Electrónico Oficial *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'El correo es obligatorio';
                                  if (!val.contains('@') || !val.contains('.')) return 'Ingresa un email válido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección Física *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'La dirección es obligatoria' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _maxEstudiantesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Capacidad de Estudiantes (MINERD) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.groups_rounded, size: 20),
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val?.trim() ?? '');
                                  if (num == null || num <= 0) return 'Capacidad debe ser mayor a 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cuota SaaS Calculada:',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'RD\$ ${saasFee.toStringAsFixed(2)} / mes',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Sección: Datos del Director
                        const Row(
                          children: [
                            Icon(Icons.person_pin_rounded, size: 18, color: AppColors.navyPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Dirección & Representación Legal',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _directorNombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Director(a) / Representante *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'El nombre del director es obligatorio' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _directorCedulaController,
                                decoration: const InputDecoration(
                                  labelText: 'Cédula de Identidad (11 dígitos) *',
                                  hintText: '001-1234567-8',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.fingerprint_rounded, size: 20),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'La cédula es obligatoria';
                                  final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (digits.length != 11) {
                                    return 'La cédula debe tener 11 dígitos (actual: ${digits.length})';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _directorTelefonoController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono Personal del Director *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'El teléfono del director es obligatorio' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _directorEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo Personal / Notificaciones Directivas *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'El correo del director es obligatorio';
                            if (!val.contains('@') || !val.contains('.')) return 'Ingresa un correo electrónico válido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: _isFormReady
                        ? 'Guardar modificaciones en la base de datos'
                        : 'Completa todos los campos obligatorios (*) para habilitar el guardado',
                    child: ElevatedButton.icon(
                      onPressed: (_isSaving || !_isFormReady) ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormReady ? AppColors.navyPrimary : const Color(0xFFCBD5E1),
                        foregroundColor: _isFormReady ? Colors.white : const Color(0xFF94A3B8),
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
}
