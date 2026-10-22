import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../models/student_document.dart';
import '../models/tutor.dart';
import '../repositories/family_repository.dart';
import '../widgets/document_preview_dialog.dart';
import 'family_detail_dialog.dart';

/// Modal para matricular un nuevo alumno bajo una cuenta familiar existente
class EnrollStudentDialog extends StatefulWidget {
  final FamilyRepository repository;
  final Family? initialFamily;
  final String? colegioId;
  final ValueChanged<Student>? onStudentEnrolled;

  const EnrollStudentDialog({
    super.key,
    required this.repository,
    this.initialFamily,
    this.colegioId,
    this.onStudentEnrolled,
  });

  static Future<Student?> show(
    BuildContext context, {
    required FamilyRepository repository,
    Family? initialFamily,
    String? colegioId,
    ValueChanged<Student>? onStudentEnrolled,
  }) {
    return showDialog<Student>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EnrollStudentDialog(
        repository: repository,
        initialFamily: initialFamily,
        colegioId: colegioId,
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

  // Documentos adjuntos interactivos en el expediente (Issue #19)
  final Map<String, StudentDocument> _documentosAdjuntos = {
    'Foto 2x2': StudentDocument(
      id: 'doc-foto-enr',
      tipo: 'Foto 2x2',
      nombreArchivo: 'foto_estudiante.jpg',
      tamanoBytes: 1024 * 320,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Acta de Nacimiento': StudentDocument(
      id: 'doc-acta-enr',
      tipo: 'Acta de Nacimiento',
      nombreArchivo: 'acta_nacimiento_oficial.pdf',
      tamanoBytes: 1024 * 1450,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Certificado de Notas': StudentDocument(
      id: 'doc-notas-enr',
      tipo: 'Certificado de Notas',
      nombreArchivo: 'record_notas_legalizado.pdf',
      tamanoBytes: 1024 * 890,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Carta de Conducta': StudentDocument(
      id: 'doc-conducta-enr',
      tipo: 'Carta de Conducta',
      nombreArchivo: 'carta_saldo_conducta.pdf',
      tamanoBytes: 1024 * 540,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
  };

  void _toggleDocument(String tipo, String defaultFilename, int defaultSize) {
    setState(() {
      if (_documentosAdjuntos.containsKey(tipo)) {
        _documentosAdjuntos.remove(tipo);
      } else {
        _documentosAdjuntos[tipo] = StudentDocument(
          id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
          tipo: tipo,
          nombreArchivo: defaultFilename,
          tamanoBytes: defaultSize,
          fechaSubida: DateTime.now(),
          verificado: true,
        );
      }
    });
  }

  Future<void> _pickRealDocumentForSlot(String tipo) async {
    final picked = await FileUploadService.pickRealFile();
    if (picked != null) {
      setState(() {
        _documentosAdjuntos[tipo] = StudentDocument(
          id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
          tipo: tipo,
          nombreArchivo: picked.name,
          tamanoBytes: picked.size,
          fechaSubida: DateTime.now(),
          verificado: true,
          urlArchivo: picked.dataUrl,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento real "$tipo" cargado (${(picked.size / 1024).toStringAsFixed(1)} KB)'),
            backgroundColor: AppColors.navyPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _previewDocument(StudentDocument doc) {
    final studentName = '${_nombresController.text} ${_apellidosController.text}'.trim();
    DocumentPreviewDialog.show(
      context,
      document: doc,
      studentName: studentName.isEmpty ? 'Estudiante en Proceso de Matrícula' : studentName,
    );
  }

  // Tutores adicionales o personas autorizadas a retirar (Issue #19)
  final List<Tutor> _additionalTutors = [];

  void _showAddTutorModal() {
    final formKey = GlobalKey<FormState>();
    final nombresCtrl = TextEditingController();
    final apellidosCtrl = TextEditingController();
    final cedulaCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String parentesco = 'Madre';
    bool autorizadoRecoger = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: AppColors.navyPrimary, size: 24),
                SizedBox(width: 10),
                Text('Agregar Tutor o Persona Autorizada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const Key('input_tutor_names'),
                        controller: nombresCtrl,
                        decoration: const InputDecoration(labelText: 'Nombres *', isDense: true, border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('input_tutor_lastnames'),
                        controller: apellidosCtrl,
                        decoration: const InputDecoration(labelText: 'Apellidos *', isDense: true, border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: parentesco,
                        decoration: const InputDecoration(labelText: 'Parentesco / Relación *', isDense: true, border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Madre', child: Text('Madre')),
                          DropdownMenuItem(value: 'Padre', child: Text('Padre')),
                          DropdownMenuItem(value: 'Tutor Legal', child: Text('Tutor Legal')),
                          DropdownMenuItem(value: 'Abuelo/a', child: Text('Abuelo/a')),
                          DropdownMenuItem(value: 'Tío/a', child: Text('Tío/a')),
                          DropdownMenuItem(value: 'Chofer / Transporte', child: Text('Chofer / Transporte')),
                          DropdownMenuItem(value: 'Persona Autorizada', child: Text('Persona Autorizada para Retiro')),
                        ],
                        onChanged: (v) => setModalState(() => parentesco = v ?? 'Madre'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('input_tutor_cedula'),
                        controller: cedulaCtrl,
                        decoration: const InputDecoration(labelText: 'Cédula o Pasaporte', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('input_tutor_phone'),
                        controller: telefonoCtrl,
                        decoration: const InputDecoration(labelText: 'Teléfono Móvil', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('input_tutor_email'),
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico (Opcional)', isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: autorizadoRecoger,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Autorizado para retirar al alumno del centro escolar', style: TextStyle(fontSize: 12)),
                        onChanged: (v) => setModalState(() => autorizadoRecoger = v ?? true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                key: const Key('btn_submit_enroll_tutor'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final newTutor = Tutor(
                      id: 'tutor-${DateTime.now().millisecondsSinceEpoch}',
                      familiaId: _selectedFamily?.id ?? 'temp',
                      nombres: nombresCtrl.text.trim(),
                      apellidos: apellidosCtrl.text.trim(),
                      parentesco: parentesco,
                      cedulaOPasaporte: cedulaCtrl.text.trim().isNotEmpty ? cedulaCtrl.text.trim() : null,
                      telefono: telefonoCtrl.text.trim().isNotEmpty ? telefonoCtrl.text.trim() : null,
                      email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                      esContactoPrincipal: false,
                      autorizadoRecoger: autorizadoRecoger,
                    );
                    setState(() {
                      _additionalTutors.add(newTutor);
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tutor/autorizado "${newTutor.nombreCompleto}" agregado a la matrícula.'),
                        backgroundColor: AppColors.navyPrimary,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
                child: const Text('Agregar Tutor', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

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
    _selectedFamily = widget.initialFamily;
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
      final list = await widget.repository.getFamilies(colegioId: widget.colegioId);
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
        documentos: _documentosAdjuntos.values.toList(),
        additionalTutors: _additionalTutors,
      );

      if (mounted) {
        setState(() {
          _enrolledStudent = student;
          _isSubmitting = false;
        });
        widget.onStudentEnrolled?.call(student);
      }
    } catch (e, stack) {
      debugPrint('Error al matricular estudiante: $e\n$stack');
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
                    if (s.documentosExpediente.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('📁 Expediente: ${s.documentosExpediente.length} documentos oficiales vinculados (${s.documentosExpediente.map((d) => d.tipo).join(", ")})', style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
                    ],
                    if (_additionalTutors.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('👥 Tutores/Autorizados adicionales: ${_additionalTutors.map((t) => "${t.nombreCompleto} (${t.parentesco})").join(", ")}', style: const TextStyle(fontSize: 12, color: AppColors.navyPrimary)),
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
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedFamily != null) ...[
                OutlinedButton.icon(
                  key: const Key('btn_success_ver_expediente_completo'),
                  onPressed: () {
                    Navigator.of(context).pop(s);
                    FamilyDetailDialog.show(
                      context,
                      _selectedFamily!,
                      repository: widget.repository,
                    );
                  },
                  icon: const Icon(Icons.folder_shared_rounded, size: 16),
                  label: const Text('Ver Expediente en Detalle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.electricBlue,
                    side: const BorderSide(color: AppColors.electricBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  final text = '''
*Matrícula de Estudiante - EDUNEX*
Estudiante: ${s.nombreCompleto}
Matrícula: ${s.matricula}
Grado: ${s.gradoYSeccion}
Familia: ${_selectedFamily?.nombreFamilia ?? ""}
Documentos en expediente: ${s.documentosExpediente.length}
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
                                value: _selectedFamily,
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
                                    key: const Key('input_enroll_student_names'),
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
                                    key: const Key('input_enroll_student_apellidos'),
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

                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 10),

                            // Sección: Documentos del Expediente Escolar (Issue #19)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.folder_shared_rounded, color: AppColors.navyPrimary, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Documentos para el Expediente Escolar (Issue #19)',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Adjunta o verifica los documentos oficiales para el expediente digital del alumno.',
                                        style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  key: const Key('btn_enroll_add_custom_doc'),
                                  onPressed: () {
                                    _toggleDocument(
                                      'Certificado Médico Actualizado',
                                      'certificado_medico_${_nombresController.text.trim().toLowerCase().replaceAll(' ', '_')}.pdf',
                                      1024 * 410,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Documento actualizado en el expediente.'), duration: Duration(seconds: 1)),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file_rounded, size: 14),
                                  label: const Text('Adjuntar / Alternar', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navyPrimary,
                                    side: const BorderSide(color: AppColors.navyPrimary),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            ...[
                              ('Foto 2x2', 'Foto 2x2 del Estudiante', 'foto_estudiante.jpg', 1024 * 320),
                              ('Acta de Nacimiento', 'Acta de Nacimiento Legalizada', 'acta_nacimiento_oficial.pdf', 1024 * 1450),
                              ('Certificado de Notas', 'Certificado / Récord de Notas', 'record_notas_legalizado.pdf', 1024 * 890),
                              ('Carta de Conducta', 'Carta de Conducta Escolar', 'carta_conducta.pdf', 1024 * 540),
                              ('Certificado Médico Actualizado', 'Certificado Médico & Vacunas', 'certificado_medico.pdf', 1024 * 410),
                            ].map((docDef) {
                              final tipoKey = docDef.$1;
                              final label = docDef.$2;
                              final defaultFilename = docDef.$3;
                              final defaultSize = docDef.$4;
                              final isAttached = _documentosAdjuntos.containsKey(tipoKey);
                              final doc = _documentosAdjuntos[tipoKey];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isAttached ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isAttached ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      key: Key('checkbox_doc_$tipoKey'),
                                      value: isAttached,
                                      onChanged: (_) => _toggleDocument(tipoKey, defaultFilename, defaultSize),
                                      activeColor: const Color(0xFF16A34A),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isAttached ? const Color(0xFF14532D) : AppColors.slateDark,
                                            ),
                                          ),
                                          if (isAttached && doc != null)
                                            Text(
                                              '${doc.nombreArchivo} • ${doc.tamanoFormateado} • Adjunto al expediente',
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A)),
                                            )
                                          else
                                            const Text(
                                              'Pendiente de entrega o subida digital',
                                              style: TextStyle(fontSize: 10, color: AppColors.slateGray),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isAttached && doc != null) ...[
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.navyPrimary),
                                        onPressed: () => _previewDocument(doc),
                                        tooltip: 'Ver documento',
                                      ),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.file_open_rounded, size: 18, color: AppColors.electricBlue),
                                      onPressed: () => _pickRealDocumentForSlot(tipoKey),
                                      tooltip: 'Cargar archivo real desde el dispositivo',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isAttached ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                                        size: 18,
                                        color: isAttached ? const Color(0xFF16A34A) : AppColors.slateGray,
                                      ),
                                      onPressed: () => _toggleDocument(tipoKey, defaultFilename, defaultSize),
                                      tooltip: isAttached ? 'Quitar documento' : 'Adjuntar documento',
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 10),

                            // Sección: Tutores Adicionales y Personas Autorizadas a Retirar (Issue #19)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.badge_rounded, color: AppColors.navyPrimary, size: 18),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Tutores y Personas Autorizadas (Issue #19)',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Agrega a la madre, familiares o chofer autorizados para el retiro del alumno.',
                                        style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  key: const Key('btn_enroll_add_tutor'),
                                  onPressed: _showAddTutorModal,
                                  icon: const Icon(Icons.person_add_rounded, size: 14),
                                  label: const Text('+ Agregar Tutor', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.electricBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (_additionalTutors.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Text(
                                  'El alumno quedará vinculado al tutor principal de la cuenta familiar. Presiona "+ Agregar Tutor" para registrar personas autorizadas adicionales para retiro o contacto.',
                                  style: TextStyle(fontSize: 11, color: AppColors.slateDark),
                                ),
                              )
                            else
                              ..._additionalTutors.map((t) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, color: AppColors.navyPrimary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${t.nombreCompleto} (${t.parentesco})',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          Text(
                                            'Tel: ${t.telefono ?? "N/D"} • ${t.autorizadoRecoger ? "Autorizado para retiro" : "No autorizado"}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Autorizado', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                    ),
                                  ],
                                ),
                              )),
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
                          key: const Key('btn_enroll_submit_student'),
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
