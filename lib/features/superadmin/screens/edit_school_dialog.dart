import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.school;
    _nombreController = TextEditingController(text: s.nombre);
    _siglasController = TextEditingController(text: s.siglas ?? '');
    _rncController = TextEditingController(text: s.rnc ?? '');
    _telefonoController = TextEditingController(text: s.telefono ?? '');
    _emailController = TextEditingController(text: s.emailContacto ?? '');
    _direccionController = TextEditingController(text: s.direccion ?? '');
    _maxEstudiantesController = TextEditingController(text: s.maxEstudiantes.toString());
    _directorNombreController = TextEditingController(text: s.directorNombre ?? '');
    _directorCedulaController = TextEditingController(text: s.directorCedula ?? '');
    _directorTelefonoController = TextEditingController(text: s.directorTelefono ?? '');
    _directorEmailController = TextEditingController(text: s.directorEmail ?? '');
  }

  @override
  void dispose() {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = await widget.repository.updateSchoolRegistration(
        schoolId: widget.school.id,
        nombre: _nombreController.text.trim(),
        siglas: _siglasController.text.trim().isEmpty ? null : _siglasController.text.trim(),
        rnc: _rncController.text.trim().isEmpty ? null : _rncController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        emailContacto: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        maxEstudiantes: int.tryParse(_maxEstudiantesController.text.trim()) ?? widget.school.maxEstudiantes,
        directorNombre: _directorNombreController.text.trim().isEmpty ? null : _directorNombreController.text.trim(),
        directorCedula: _directorCedulaController.text.trim().isEmpty ? null : _directorCedulaController.text.trim(),
        directorTelefono: _directorTelefonoController.text.trim().isEmpty ? null : _directorTelefonoController.text.trim(),
        directorEmail: _directorEmailController.text.trim().isEmpty ? null : _directorEmailController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop(updated);
        AppToast.success(
          context,
          '¡Información de registro de "${updated.nombre}" actualizada con éxito!',
          title: 'Colegio Actualizado',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(
          context,
          'Error guardando cambios: $e',
          title: 'Error al Guardar',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.navyPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar Información de Registro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        Text(
                          'Modifica los datos oficiales del colegio en la base de datos central.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Form body
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            prefixIcon: Icon(Icons.domain_rounded, size: 20),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _siglasController,
                                decoration: const InputDecoration(
                                  labelText: 'Siglas / Acrónimo',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.short_text_rounded, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _rncController,
                                decoration: const InputDecoration(
                                  labelText: 'RNC Institucional',
                                  hintText: '1-32-45678-9',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
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
                                controller: _telefonoController,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono Institucional',
                                  hintText: '(809) 555-0100',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_rounded, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Correo Electrónico Oficial',
                                  hintText: 'contacto@colegio.edu.do',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección Física',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _maxEstudiantesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Capacidad de Estudiantes (MINERD)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.groups_rounded, size: 20),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cuota SaaS Calculada:', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                    Text(
                                      'RD\$ ${_calculateSaaSFee().toStringAsFixed(2)} / mes',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534)),
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
                            labelText: 'Nombre del Director(a) / Representante',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _directorCedulaController,
                                decoration: const InputDecoration(
                                  labelText: 'Cédula de Identidad',
                                  hintText: '001-1234567-8',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.fingerprint_rounded, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _directorTelefonoController,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono Personal del Director',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _directorEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo Personal / Notificaciones Directivas',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                          ),
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
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
