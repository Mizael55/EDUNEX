import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';

/// Modal para dar de alta un nuevo colegio cliente en la plataforma EDUNEX
class CreateSchoolDialog extends StatefulWidget {
  final SchoolRepository schoolRepository;
  final ValueChanged<School>? onSchoolCreated;

  const CreateSchoolDialog({
    super.key,
    required this.schoolRepository,
    this.onSchoolCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required SchoolRepository schoolRepository,
    ValueChanged<School>? onSchoolCreated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateSchoolDialog(
        schoolRepository: schoolRepository,
        onSchoolCreated: onSchoolCreated,
      ),
    );
  }

  @override
  State<CreateSchoolDialog> createState() => _CreateSchoolDialogState();
}

class _CreateSchoolDialogState extends State<CreateSchoolDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _siglasController = TextEditingController();
  final _rncController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();

  int _selectedMaxEstudiantes = 500;
  String _selectedStatus = 'active';
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _siglasController.dispose();
    _rncController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newSchool = await widget.schoolRepository.createSchool(
        nombre: _nombreController.text,
        siglas: _siglasController.text.isNotEmpty ? _siglasController.text : null,
        rnc: _rncController.text.isNotEmpty ? _rncController.text : null,
        telefono: _telefonoController.text.isNotEmpty ? _telefonoController.text : null,
        emailContacto: _emailController.text.isNotEmpty ? _emailController.text : null,
        direccion: _direccionController.text.isNotEmpty ? _direccionController.text : null,
        estadoSuscripcion: _selectedStatus,
        maxEstudiantes: _selectedMaxEstudiantes,
      );

      if (mounted) {
        widget.onSchoolCreated?.call(newSchool);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.navyPrimary,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Colegio "${newSchool.nombre}" registrado exitosamente en el SaaS!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Error al dar de alta el colegio: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del Modal
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
                    child: const Icon(
                      Icons.domain_add_rounded,
                      color: AppColors.surfaceWhite,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar Nuevo Colegio Cliente',
                          style: TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Alta multi-tenant de institución educativa y activación de suscripción SaaS',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
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
                      // Nombre del Colegio
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la Institución *',
                          hintText: 'Ej. Colegio Bilingüe San Judas Tadeo',
                          prefixIcon: const Icon(Icons.school_rounded, color: AppColors.navyPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Siglas y RNC
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _siglasController,
                              decoration: InputDecoration(
                                labelText: 'Siglas / Abreviatura',
                                hintText: 'Ej. SJT',
                                prefixIcon: const Icon(Icons.short_text_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _rncController,
                              decoration: InputDecoration(
                                labelText: 'RNC (Rep. Dominicana)',
                                hintText: 'Ej. 1-31-55443-2',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Teléfono y Email
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telefonoController,
                              decoration: InputDecoration(
                                labelText: 'Teléfono de Contacto',
                                hintText: '809-555-0100',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email de Contacto',
                                hintText: 'direccion@colegio.edu.do',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Dirección física
                      TextFormField(
                        controller: _direccionController,
                        decoration: InputDecoration(
                          labelText: 'Dirección Física',
                          hintText: 'Av. Winston Churchill #105, Santo Domingo, D.N.',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Plan de Suscripción y Estado
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedMaxEstudiantes,
                              decoration: InputDecoration(
                                labelText: 'Capacidad de Estudiantes',
                                prefixIcon: const Icon(Icons.people_alt_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 250, child: Text('Básico (Hasta 250)')),
                                DropdownMenuItem(value: 500, child: Text('Profesional (Hasta 500)')),
                                DropdownMenuItem(value: 1000, child: Text('Enterprise (Hasta 1,000)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedMaxEstudiantes = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: InputDecoration(
                                labelText: 'Estado de Suscripción',
                                prefixIcon: const Icon(Icons.verified_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'active', child: Text('Activa (Pagando)')),
                                DropdownMenuItem(value: 'trial', child: Text('Período de Prueba (Trial)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatus = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con Botones
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
                    label: Text(_isLoading ? 'Guardando...' : 'Dar de Alta Colegio'),
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
}
