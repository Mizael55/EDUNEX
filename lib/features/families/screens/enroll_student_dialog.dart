import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../repositories/family_repository.dart';

/// Modal para matricular un nuevo alumno bajo una cuenta familiar existente
class EnrollStudentDialog extends StatefulWidget {
  final FamilyRepository repository;
  final Family? initialFamily;
  final ValueChanged<Student>? onStudentEnrolled;

  const EnrollStudentDialog({
    super.key,
    required this.repository,
    this.initialFamily,
    this.onStudentEnrolled,
  });

  static Future<Student?> show(
    BuildContext context, {
    required FamilyRepository repository,
    Family? initialFamily,
    ValueChanged<Student>? onStudentEnrolled,
  }) {
    return showDialog<Student>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EnrollStudentDialog(
        repository: repository,
        initialFamily: initialFamily,
        onStudentEnrolled: onStudentEnrolled,
      ),
    );
  }

  @override
  State<EnrollStudentDialog> createState() => _EnrollStudentDialogState();
}

class _EnrollStudentDialogState extends State<EnrollStudentDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Family> _families = [];
  Family? _selectedFamily;
  bool _isLoadingFamilies = true;
  bool _isSubmitting = false;

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  String _selectedGrado = '1ro de Primaria';
  String _selectedSeccion = 'Sección A';
  String _selectedGenero = 'Masculino';
  bool _incluirCuido = false;
  bool _incluirTransporte = false;

  Student? _enrolledStudent;

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
  void initState() {
    super.initState();
    _loadFamilies();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    try {
      final list = await widget.repository.getFamilies();
      if (mounted) {
        setState(() {
          _families = list;
          _isLoadingFamilies = false;
          if (widget.initialFamily != null) {
            _selectedFamily = list.firstWhere(
              (f) => f.id == widget.initialFamily!.id,
              orElse: () => widget.initialFamily!,
            );
          } else if (list.isNotEmpty) {
            _selectedFamily = list.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFamilies = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta familiar')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final servicios = <String>[];
      if (_incluirCuido) servicios.add('Cuido Vespertino (3:00 - 6:00 PM)');
      if (_incluirTransporte) servicios.add('Ruta Escolar Asignada');

      final student = await widget.repository.enrollStudent(
        familiaId: _selectedFamily!.id,
        colegioId: _selectedFamily!.colegioId,
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        gradoNombre: _selectedGrado,
        seccionNombre: _selectedSeccion,
        genero: _selectedGenero,
        servicios: servicios,
      );

      if (mounted) {
        setState(() {
          _enrolledStudent = student;
          _isSubmitting = false;
        });
        widget.onStudentEnrolled?.call(student);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Error al matricular estudiante: $e'),
          ),
        );
      }
    }
  }

  Widget _buildSuccessContent() {
    final s = _enrolledStudent!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF166534),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Matrícula Asignada con Éxito!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'El expediente escolar digital ha sido generado y vinculado.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(s),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('EXPEDIENTE ESCOLAR DIGITAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF166534))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(s.matricula, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFBBF7D0), height: 16),
                    Text('🎓 Alumno: ${s.nombreCompleto}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('📚 Grado & Sección: ${s.gradoYSeccion}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('👨‍👩‍👧‍👦 Familia: ${_selectedFamily?.nombreFamilia ?? "N/D"}', style: const TextStyle(fontSize: 13)),
                    if (s.serviciosActivos.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('✨ Servicios activos: ${s.serviciosActivos.join(", ")}', style: const TextStyle(fontSize: 12, color: Color(0xFF15803D))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '💡 La matrícula quedó registrada en la base de datos y visible para el director y la familia.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
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
              OutlinedButton.icon(
                onPressed: () {
                  final text = '''
*Matrícula de Estudiante - EDUNEX*
Estudiante: ${s.nombreCompleto}
Matrícula: ${s.matricula}
Grado: ${s.gradoYSeccion}
Familia: ${_selectedFamily?.nombreFamilia ?? ""}
''';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Matrícula copiada al portapapeles.'),
                      backgroundColor: AppColors.navyPrimary,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar Matrícula'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: AppColors.navyPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Entendido y Cerrar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 800),
        child: _enrolledStudent != null
            ? _buildSuccessContent()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asistente de Matrícula Escolar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Inscribe un alumno y asígnale su grado y servicios complementarios.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cuenta Familiar *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                            const SizedBox(height: 6),
                            if (_isLoadingFamilies)
                              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                            else if (_families.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Por favor registra una cuenta familiar primero antes de matricular alumnos.', style: TextStyle(fontSize: 12)),
                              )
                            else
                              DropdownButtonFormField<Family>(
                                initialValue: _selectedFamily,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.family_restroom_rounded, color: AppColors.navyPrimary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _families.map((f) {
                                  return DropdownMenuItem<Family>(
                                    value: f,
                                    child: Text('${f.nombreFamilia} (${f.codigoFamilia})', style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (f) {
                                  if (f != null) setState(() => _selectedFamily = f);
                                },
                              ),

                            const SizedBox(height: 18),

                            // Nombres y Apellidos
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nombresController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombres del Alumno *',
                                      prefixIcon: const Icon(Icons.person_outline_rounded),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _apellidosController,
                                    decoration: InputDecoration(
                                      labelText: 'Apellidos del Alumno *',
                                      prefixIcon: const Icon(Icons.person_outline_rounded),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Grado y Sección
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedGrado,
                                    decoration: InputDecoration(
                                      labelText: 'Grado / Nivel *',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: _grados.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedGrado = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedSeccion,
                                    decoration: InputDecoration(
                                      labelText: 'Sección *',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: ['Sección A', 'Sección B', 'Sección C', 'Sección Única']
                                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedSeccion = v);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Género
                            DropdownButtonFormField<String>(
                              initialValue: _selectedGenero,
                              decoration: InputDecoration(
                                labelText: 'Género',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: ['Masculino', 'Femenino', 'Otro'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedGenero = v);
                              },
                            ),

                            const SizedBox(height: 18),

                            // Servicios Adicionales
                            const Text('Servicios Complementarios Opcionales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                            const SizedBox(height: 6),
                            CheckboxListTile(
                              title: const Text('Inscribir en Cuido Vespertino (3:00 - 6:00 PM)', style: TextStyle(fontSize: 13)),
                              subtitle: const Text('Tarifa adicional RD\$ 3,500/mes', style: TextStyle(fontSize: 11)),
                              value: _incluirCuido,
                              onChanged: (v) => setState(() => _incluirCuido = v ?? false),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: const Text('Asignar Ruta de Transporte Escolar', style: TextStyle(fontSize: 13)),
                              subtitle: const Text('Tarifa adicional RD\$ 4,000/mes', style: TextStyle(fontSize: 11)),
                              value: _incluirTransporte,
                              onChanged: (v) => setState(() => _incluirTransporte = v ?? false),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Acciones
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
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_isSubmitting ? 'Inscribiendo...' : 'Completar Matrícula'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            foregroundColor: Colors.white,
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
