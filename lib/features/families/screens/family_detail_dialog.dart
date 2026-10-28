import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../models/student_document.dart';
import '../models/tutor.dart';
import '../repositories/family_repository.dart';
import '../../../core/services/file_upload_service.dart';
import '../widgets/document_preview_dialog.dart';

/// Modal para visualizar en detalle el expediente de una Cuenta Familiar Única
class FamilyDetailDialog extends StatefulWidget {
  final Family family;
  final FamilyRepository? repository;

  const FamilyDetailDialog({
    super.key,
    required this.family,
    this.repository,
  });

  static Future<void> show(
    BuildContext context,
    Family family, {
    FamilyRepository? repository,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FamilyDetailDialog(
        family: family,
        repository: repository,
      ),
    );
  }

  @override
  State<FamilyDetailDialog> createState() => _FamilyDetailDialogState();
}

class _FamilyDetailDialogState extends State<FamilyDetailDialog> {
  late Family _family;
  late final FamilyRepository _repository;

  @override
  void initState() {
    super.initState();
    _family = widget.family;
    _repository = widget.repository ?? FamilyRepository();
  }

  void _showAddTutorModal() {
    final formKey = GlobalKey<FormState>();
    final nombresController = TextEditingController();
    final apellidosController = TextEditingController();
    final cedulaController = TextEditingController();
    final telefonoController = TextEditingController();
    final emailController = TextEditingController();
    String selectedParentesco = 'Madre';
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
                Text('Agregar Tutor o Autorizado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        controller: nombresController,
                        decoration: const InputDecoration(
                          labelText: 'Nombres *',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: apellidosController,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos *',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: cedulaController,
                        decoration: const InputDecoration(
                          labelText: 'Cédula / Documento Identidad',
                          hintText: '001-1234567-8',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono Móvil',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico (opcional)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedParentesco,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Parentesco / Vínculo',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          'Madre',
                          'Padre',
                          'Abuelo / Abuela',
                          'Tío / Tía',
                          'Chofer / Transporte',
                          'Hermano Mayor / Familiar',
                          'Otro Autorizado',
                        ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setModalState(() => selectedParentesco = v!),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: autorizadoRecoger,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Autorizado para retirar estudiantes', style: TextStyle(fontSize: 12)),
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
                key: const Key('btn_submit_add_tutor'),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newTutor = Tutor(
                      id: 'tutor-${DateTime.now().millisecondsSinceEpoch}',
                      familiaId: _family.id,
                      nombres: nombresController.text.trim(),
                      apellidos: apellidosController.text.trim(),
                      parentesco: selectedParentesco,
                      cedulaOPasaporte: cedulaController.text.trim().isNotEmpty ? cedulaController.text.trim() : null,
                      telefono: telefonoController.text.trim().isNotEmpty ? telefonoController.text.trim() : null,
                      email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                      esContactoPrincipal: false,
                      autorizadoRecoger: autorizadoRecoger,
                    );

                    await _repository.addTutorToFamily(_family.id, newTutor);
                    setState(() {
                      _family = _family.copyWith(tutores: [..._family.tutores, newTutor]);
                    });

                    if (mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tutor ${newTutor.nombreCompleto} agregado a la familia.'),
                          backgroundColor: AppColors.accentGreen,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
                child: const Text('Guardar Tutor / Autorizado', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAttachDocumentDialog(Student student) {
    final docTypes = [
      'Foto 2x2',
      'Acta de Nacimiento',
      'Certificado de Notas',
      'Carta de Saldo / Conducta',
      'Certificado Médico Actualizado',
      'Comprobante de Vacunas',
      'Evaluación Psicométrica',
      'Cédula / Pasaporte Tutor',
      'Otro Documento Personalizado',
    ];

    Uint8List? pickedBytes;
    String? pickedDataUrl;
    int pickedSize = 1024 * 512;
    String selectedTipo = docTypes[0];
    final customTipoCtrl = TextEditingController();
    final filenameCtrl = TextEditingController(text: 'foto_${student.nombres.toLowerCase().replaceAll(' ', '_')}.jpg');
    bool verificado = true;
    bool isFileSelected = true;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isCustom = selectedTipo == 'Otro Documento Personalizado';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.upload_file_rounded, color: AppColors.navyPrimary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Adjuntar Documento Digital', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Expediente: ${student.nombreCompleto}', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Documento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedTipo,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedTipo = val;
                            if (pickedBytes == null) {
                              if (val == 'Foto 2x2') {
                                filenameCtrl.text = 'foto_${student.nombres.toLowerCase().replaceAll(' ', '_')}.jpg';
                              } else if (val != 'Otro Documento Personalizado') {
                                filenameCtrl.text = '${val.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}.pdf';
                              }
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: customTipoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Especifique Tipo de Documento *',
                          hintText: 'Ej. Sentencia Judicial, Permiso Especial',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Nombre del Archivo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: filenameCtrl,
                      decoration: InputDecoration(
                        hintText: 'nombre_del_documento.pdf',
                        isDense: true,
                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pickedBytes != null ? Icons.check_circle_rounded : Icons.cloud_done_rounded,
                            color: pickedBytes != null ? AppColors.accentGreen : AppColors.electricBlue,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFileSelected ? filenameCtrl.text : 'Ningún archivo adjunto',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tamaño: ${(pickedSize / 1024).toStringAsFixed(1)} KB • ${pickedBytes != null ? "Archivo real cargado" : "Formato: PDF/Digital"}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await FileUploadService.pickRealFile();
                              if (picked != null) {
                                setModalState(() {
                                  pickedBytes = picked.bytes;
                                  pickedDataUrl = picked.dataUrl;
                                  pickedSize = picked.size;
                                  filenameCtrl.text = picked.name;
                                  isFileSelected = true;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Archivo real seleccionado: ${picked.name} (${(picked.size / 1024).toStringAsFixed(1)} KB)'),
                                      duration: const Duration(milliseconds: 1500),
                                      backgroundColor: AppColors.navyPrimary,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.file_open_rounded, size: 14),
                            label: const Text('Explorar Archivo', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: verificado,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Marcar como documento oficial verificado', style: TextStyle(fontSize: 12)),
                      onChanged: (v) => setModalState(() => verificado = v ?? true),
                    ),
                    if (isUploading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text('Subiendo archivo al almacenamiento seguro...', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                key: const Key('btn_confirm_attach_doc_detail'),
                onPressed: isUploading ? null : () async {
                  setModalState(() => isUploading = true);

                  final finalTipo = isCustom && customTipoCtrl.text.trim().isNotEmpty
                      ? customTipoCtrl.text.trim()
                      : selectedTipo;
                  final finalFilename = filenameCtrl.text.trim().isNotEmpty
                      ? filenameCtrl.text.trim()
                      : '${finalTipo.toLowerCase().replaceAll(' ', '_')}.pdf';

                  String? fileUrl = pickedDataUrl;
                  if (pickedBytes != null) {
                    final uploadRes = await FileUploadService.uploadBytes(
                      bytes: pickedBytes!,
                      fileName: finalFilename,
                      folder: 'students/${student.id}',
                    );
                    fileUrl = uploadRes.publicUrl;
                  }

                  final newDoc = StudentDocument(
                    id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                    tipo: finalTipo,
                    nombreArchivo: finalFilename,
                    tamanoBytes: pickedSize,
                    fechaSubida: DateTime.now(),
                    verificado: verificado,
                    urlArchivo: fileUrl,
                  );

                  await _repository.addDocumentToStudent(
                    studentId: student.id,
                    document: newDoc,
                  );

                  final updatedStudents = _family.estudiantes.map((s) {
                    if (s.id == student.id) {
                      return s.copyWith(documentosExpediente: [...s.documentosExpediente, newDoc]);
                    }
                    return s;
                  }).toList();

                  setState(() {
                    _family = _family.copyWith(estudiantes: updatedStudents);
                  });

                  if (mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Documento "$finalTipo" guardado y vinculado al expediente de ${student.nombres}.'),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Guardar y Vincular'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPreviewDocModal(StudentDocument doc, String studentName) {
    DocumentPreviewDialog.show(context, document: doc, studentName: studentName);
  }

  void _toggleStudentStatus(Student student) {
    if (student.activo) {
      final motivoController = TextEditingController(text: 'Traslado escolar voluntario');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              const Text('Dar de Baja a Estudiante', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Confirmas que deseas dar de baja a ${student.nombreCompleto} de la institución educativa?'),
              const SizedBox(height: 12),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la baja o retiro',
                  border: OutlineInputBorder(),
                  hintText: 'Ej. Traslado, retiro familiar...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _repository.deactivateStudent(studentId: student.id, motivo: motivoController.text.trim());
                setState(() {
                  final updatedStudents = _family.estudiantes.map((s) {
                    if (s.id == student.id) return s.copyWith(activo: false);
                    return s;
                  }).toList();
                  _family = _family.copyWith(estudiantes: updatedStudents);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Estudiante ${student.nombreCompleto} ha sido dado de baja.'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              },
              child: const Text('Confirmar Baja'),
            ),
          ],
        ),
      );
    } else {
      // Reactivar estudiante
      _repository.reactivateStudent(studentId: student.id);
      setState(() {
        final updatedStudents = _family.estudiantes.map((s) {
          if (s.id == student.id) return s.copyWith(activo: true);
          return s;
        }).toList();
        _family = _family.copyWith(estudiantes: updatedStudents);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estudiante ${student.nombreCompleto} ha sido reactivado exitosamente.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  void _showAttachTutorDocumentDialog(Tutor tutor) {
    final docTypes = [
      'Copia Física de Cédula de Identidad',
      'Carta de Trabajo / Certificación Laboral',
      'Estados Financieros / Comprobante de Ingresos',
      'Poder Notarial de Custodia',
      'Acta de Matrimonio / Unión Libre',
      'Copia de Pasaporte',
      'Otro Documento Personalizado',
    ];

    Uint8List? pickedBytes;
    String? pickedDataUrl;
    int pickedSize = 1024 * 450;
    String selectedTipo = docTypes[0];
    final customTipoCtrl = TextEditingController();
    final filenameCtrl = TextEditingController(text: 'cedula_${tutor.nombres.toLowerCase().replaceAll(' ', '_')}.pdf');
    bool verificado = true;
    bool isFileSelected = true;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isCustom = selectedTipo == 'Otro Documento Personalizado';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.upload_file_rounded, color: AppColors.navyPrimary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Adjuntar Documento del Tutor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Tutor: ${tutor.nombreCompleto}', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Documento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedTipo,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedTipo = val;
                            if (pickedBytes == null) {
                              if (val == 'Copia Física de Cédula de Identidad') {
                                filenameCtrl.text = 'cedula_${tutor.nombres.toLowerCase().replaceAll(' ', '_')}.pdf';
                              } else if (val == 'Carta de Trabajo / Certificación Laboral') {
                                filenameCtrl.text = 'carta_trabajo_${tutor.nombres.toLowerCase().replaceAll(' ', '_')}.pdf';
                              } else if (val == 'Estados Financieros / Comprobante de Ingresos') {
                                filenameCtrl.text = 'comprobante_ingresos_${tutor.nombres.toLowerCase().replaceAll(' ', '_')}.pdf';
                              } else if (val != 'Otro Documento Personalizado') {
                                filenameCtrl.text = '${val.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}.pdf';
                              }
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: customTipoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Especifique Tipo de Documento *',
                          hintText: 'Ej. Poder Notarial, Certificación Bancaria',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Nombre del Archivo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: filenameCtrl,
                      decoration: InputDecoration(
                        hintText: 'nombre_del_documento.pdf',
                        isDense: true,
                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pickedBytes != null ? Icons.check_circle_rounded : Icons.cloud_done_rounded,
                            color: pickedBytes != null ? AppColors.accentGreen : AppColors.electricBlue,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFileSelected ? filenameCtrl.text : 'Ningún archivo seleccionado',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tamaño: ${(pickedSize / 1024).toStringAsFixed(1)} KB • ${pickedBytes != null ? "Archivo real cargado" : "Formato: PDF/Digital"}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await FileUploadService.pickRealFile();
                              if (picked != null) {
                                setModalState(() {
                                  pickedBytes = picked.bytes;
                                  pickedDataUrl = picked.dataUrl;
                                  pickedSize = picked.size;
                                  filenameCtrl.text = picked.name;
                                  isFileSelected = true;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Archivo real seleccionado: ${picked.name} (${(picked.size / 1024).toStringAsFixed(1)} KB)'),
                                      duration: const Duration(milliseconds: 1500),
                                      backgroundColor: AppColors.navyPrimary,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.file_open_rounded, size: 14),
                            label: const Text('Explorar Archivo', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: verificado,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Marcar como documento oficial verificado', style: TextStyle(fontSize: 12)),
                      onChanged: (v) => setModalState(() => verificado = v ?? true),
                    ),
                    if (isUploading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text('Subiendo archivo al almacenamiento seguro...', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                key: const Key('btn_confirm_attach_tutor_doc'),
                onPressed: isUploading ? null : () async {
                  setModalState(() => isUploading = true);

                  final finalTipo = isCustom && customTipoCtrl.text.trim().isNotEmpty
                      ? customTipoCtrl.text.trim()
                      : selectedTipo;
                  final finalFilename = filenameCtrl.text.trim().isNotEmpty
                      ? filenameCtrl.text.trim()
                      : '${finalTipo.toLowerCase().replaceAll(' ', '_')}.pdf';

                  String? fileUrl = pickedDataUrl;
                  if (pickedBytes != null) {
                    final uploadRes = await FileUploadService.uploadBytes(
                      bytes: pickedBytes!,
                      fileName: finalFilename,
                      folder: 'tutores/${tutor.id}',
                    );
                    fileUrl = uploadRes.publicUrl;
                  }

                  final newDoc = StudentDocument(
                    id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                    tipo: finalTipo,
                    nombreArchivo: finalFilename,
                    tamanoBytes: pickedSize,
                    urlArchivo: fileUrl,
                    fechaSubida: DateTime.now(),
                    verificado: verificado,
                  );

                  await _repository.addDocumentToTutor(
                    familyId: _family.id,
                    tutorId: tutor.id,
                    document: newDoc,
                  );

                  final updatedTutores = _family.tutores.map((t) {
                    if (t.id == tutor.id) {
                      return t.copyWith(
                        documentosExpediente: [...t.documentosExpediente, newDoc],
                        copiaCedulaAdjunta: t.copiaCedulaAdjunta || finalTipo.toLowerCase().contains('cedula') || finalTipo.toLowerCase().contains('cédula'),
                        cartaTrabajoAdjunta: t.cartaTrabajoAdjunta || finalTipo.toLowerCase().contains('trabajo') || finalTipo.toLowerCase().contains('laboral'),
                        estadosFinancierosAdjuntos: t.estadosFinancierosAdjuntos || finalTipo.toLowerCase().contains('financiero') || finalTipo.toLowerCase().contains('ingreso'),
                      );
                    }
                    return t;
                  }).toList();

                  setState(() {
                    _family = _family.copyWith(tutores: updatedTutores);
                  });

                  if (mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Documento "$finalTipo" vinculado al expediente de ${tutor.nombreCompleto}.'),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Guardar y Vincular'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final family = _family;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          children: [
            // Cabecera Institucional del Modal
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.navySecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: AppColors.surfaceWhite,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              family.codigoFamilia,
                              style: const TextStyle(
                                color: AppColors.amberAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: family.estaAlDia
                                    ? AppColors.accentGreen.withValues(alpha: 0.2)
                                    : AppColors.amberAccent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                family.estaAlDia ? 'AL DÍA' : 'PENDIENTE DE PAGO',
                                style: TextStyle(
                                  color: family.estaAlDia
                                      ? AppColors.accentGreen
                                      : AppColors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          family.nombreFamilia,
                          style: const TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (family.telefonoPrincipal != null ||
                            family.emailPrincipal != null) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              if (family.telefonoPrincipal != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone_rounded,
                                      size: 14,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      family.telefonoPrincipal!,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              if (family.emailPrincipal != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      family.emailPrincipal!,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.surfaceWhite,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenido con Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen Financiero
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: family.estaAlDia
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: family.estaAlDia
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            family.estaAlDia
                                ? Icons.account_balance_wallet_rounded
                                : Icons.warning_amber_rounded,
                            color: family.estaAlDia
                                ? AppColors.accentGreen
                                : const Color(0xFFB45309),
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  family.estaAlDia
                                      ? 'Cuenta Familiar al Día'
                                      : 'Balance Pendiente Acumulado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: family.estaAlDia
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                                Text(
                                  family.estaAlDia
                                      ? 'RD\$ 0.00'
                                      : 'RD\$ ${family.balancePendiente.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: family.estaAlDia
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Abriendo pasarela de pago para ${family.nombreFamilia}',
                                  ),
                                  backgroundColor: AppColors.navyPrimary,
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              family.estaAlDia ? 'Historial Pagos' : 'Registrar Pago',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navyPrimary,
                              foregroundColor: AppColors.surfaceWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sección: Estudiantes matriculados (Hermanos agrupados)
                    Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: AppColors.navyPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hijos Matriculados (${family.estudiantes.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (family.estudiantes.isEmpty)
                      const Text(
                        'No hay estudiantes registrados en esta cuenta familiar.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: family.estudiantes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final student = family.estudiantes[index];
                          return _buildStudentCard(student, isDesktop);
                        },
                      ),

                    const SizedBox(height: 28),

                    // Sección: Tutores y Contactos Autorizados (Issue #19)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_rounded,
                              color: AppColors.navyPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tutores y Personas Autorizadas (${family.tutores.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          key: const Key('btn_add_tutor_detail'),
                          onPressed: _showAddTutorModal,
                          icon: const Icon(Icons.person_add_rounded, size: 14),
                          label: const Text('+ Agregar Tutor / Autorizado', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (family.tutores.isEmpty)
                      const Text(
                        'No hay tutores registrados para esta familia.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: family.tutores.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tutor = family.tutores[index];
                          return _buildTutorCard(tutor);
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Footer con Botones de Acción
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
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Editando expediente de ${family.nombreFamilia}',
                          ),
                          backgroundColor: AppColors.navyPrimary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Editar Familia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _buildStudentCard(Student student, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.electricBlue.withValues(alpha: 0.12),
                child: Text(
                  student.nombres.isNotEmpty ? student.nombres[0] : 'E',
                  style: const TextStyle(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.nombreCompleto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: student.activo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: student.activo ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                            ),
                          ),
                          child: Text(
                            student.activo ? 'Activo' : 'Dado de baja',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: student.activo ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Matrícula: ${student.matricula} • ${student.gradoNombre ?? "Nivel Inicial"} (${student.seccionNombre ?? "Sección A"}) • ${student.edad} años',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                key: Key('btn_baja_estudiante_${student.id}'),
                onPressed: () => _toggleStudentStatus(student),
                icon: Icon(
                  student.activo ? Icons.person_remove_rounded : Icons.person_add_alt_1_rounded,
                  size: 13,
                  color: student.activo ? Colors.red.shade700 : AppColors.accentGreen,
                ),
                label: Text(
                  student.activo ? 'Dar de Baja' : 'Reactivar Alumno',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: student.activo ? Colors.red.shade700 : AppColors.accentGreen,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: student.activo ? Colors.red.shade200 : AppColors.accentGreen.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (student.serviciosActivos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: student.serviciosActivos.map((service) {
                final isCuido = service.toLowerCase().contains('cuido');
                final isTransport = service.toLowerCase().contains('ruta');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCuido
                        ? AppColors.electricBlue.withValues(alpha: 0.1)
                        : (isTransport
                            ? AppColors.amberAccent.withValues(alpha: 0.15)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCuido
                          ? AppColors.electricBlue.withValues(alpha: 0.3)
                          : (isTransport
                              ? AppColors.amberAccent.withValues(alpha: 0.4)
                              : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCuido
                            ? Icons.child_care_rounded
                            : (isTransport
                                ? Icons.directions_bus_rounded
                                : Icons.check_circle_outline),
                        size: 13,
                        color: isCuido
                            ? AppColors.navyPrimary
                            : (isTransport
                                ? const Color(0xFFB45309)
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        service,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCuido
                              ? AppColors.navyPrimary
                              : (isTransport
                                  ? const Color(0xFFB45309)
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Expediente Escolar y Documentos Adjuntos (Issue #19)
          const SizedBox(height: 12),
          const Divider(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_shared_rounded, size: 16, color: AppColors.navyPrimary),
                  SizedBox(width: 6),
                  Text(
                    'Expediente Escolar & Documentos (Issue #19):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                  ),
                ],
              ),
              TextButton.icon(
                key: Key('btn_adjuntar_doc_${student.id}'),
                onPressed: () => _showAttachDocumentDialog(student),
                icon: const Icon(Icons.upload_file_rounded, size: 14),
                label: const Text('Adjuntar Documento', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final docs = List<StudentDocument>.from(student.documentosExpediente);
              if (docs.isEmpty) {
                if (student.fotoAdjunta) {
                  docs.add(StudentDocument(
                    id: 'doc-foto',
                    tipo: 'Foto 2x2',
                    nombreArchivo: 'foto_${student.nombres.toLowerCase().replaceAll(' ', '_')}.jpg',
                    tamanoBytes: 1024 * 320,
                    fechaSubida: DateTime.now(),
                    verificado: true,
                  ));
                }
                if (student.actaNacimientoAdjunta) {
                  docs.add(StudentDocument(
                    id: 'doc-acta',
                    tipo: 'Acta de Nacimiento',
                    nombreArchivo: 'acta_legalizada.pdf',
                    tamanoBytes: 1024 * 1450,
                    fechaSubida: DateTime.now(),
                    verificado: true,
                  ));
                }
                if (student.certificadoNotasAdjunto) {
                  docs.add(StudentDocument(
                    id: 'doc-notas',
                    tipo: 'Certificado de Notas',
                    nombreArchivo: 'record_academico.pdf',
                    tamanoBytes: 1024 * 890,
                    fechaSubida: DateTime.now(),
                    verificado: true,
                  ));
                }
              }

              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFB45309)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sin documentos en expediente aún. Pulsa "Adjuntar Documento" para cargar foto, acta o notas.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: docs.map((doc) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        '${doc.tipo}: ${doc.nombreArchivo} (${doc.tamanoFormateado})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showPreviewDocModal(doc, student.nombreCompleto),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(Icons.visibility_outlined, size: 15, color: AppColors.navyPrimary),
                        ),
                      ),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: () async {
                          await _repository.removeDocumentFromStudent(studentId: student.id, documentId: doc.id);
                          final updatedStudents = _family.estudiantes.map((s) {
                            if (s.id == student.id) {
                              return s.copyWith(
                                documentosExpediente: s.documentosExpediente.where((d) => d.id != doc.id).toList(),
                              );
                            }
                            return s;
                          }).toList();
                          setState(() {
                            _family = _family.copyWith(estudiantes: updatedStudents);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Documento "${doc.tipo}" retirado del expediente de ${student.nombres}.'),
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(Icons.close_rounded, size: 15, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTutorCard(Tutor tutor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: tutor.esContactoPrincipal
                    ? AppColors.navyPrimary
                    : const Color(0xFFCBD5E1),
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: tutor.esContactoPrincipal
                      ? AppColors.surfaceWhite
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tutor.nombreCompleto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tutor.parentesco,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        if (tutor.esContactoPrincipal) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRINCIPAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cédula: ${tutor.cedulaOPasaporte ?? "N/D"} • Tel: ${tutor.telefono ?? "N/D"}${tutor.email != null ? " • Email: ${tutor.email}" : ""}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (tutor.autorizadoRecoger)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Autorizado a retirar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Documentos de Identidad / Tutor (Issue #19)
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Documentos / Cédula (${tutor.documentos.length}):',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyPrimary,
                ),
              ),
              OutlinedButton.icon(
                key: Key('btn_upload_tutor_doc_${tutor.id}'),
                onPressed: () => _showAttachTutorDocumentDialog(tutor),
                icon: const Icon(Icons.upload_file_rounded, size: 14),
                label: const Text('Adjuntar Documento / Cédula', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: AppColors.navyPrimary),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
          if (tutor.documentos.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...tutor.documentos.map((doc) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${doc.tipo}: ${doc.nombreArchivo} (${doc.tamanoFormateado})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                    ),
                  ),
                  TextButton.icon(
                    key: Key('btn_ver_tutor_doc_${doc.id}'),
                    onPressed: () => _showPreviewDocModal(doc, tutor.nombreCompleto),
                    icon: const Icon(Icons.visibility_outlined, size: 12, color: AppColors.navyPrimary),
                    label: const Text('Ver', style: TextStyle(fontSize: 10, color: AppColors.navyPrimary)),
                  ),
                  IconButton(
                    key: Key('btn_del_tutor_doc_${doc.id}'),
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                    onPressed: () async {
                      await _repository.removeDocumentFromTutor(
                        familyId: _family.id,
                        tutorId: tutor.id,
                        documentId: doc.id,
                      );
                      final updatedTutores = _family.tutores.map((t) {
                        if (t.id == tutor.id) {
                          return t.copyWith(
                            documentosExpediente: t.documentosExpediente.where((d) => d.id != doc.id).toList(),
                          );
                        }
                        return t;
                      }).toList();
                      setState(() {
                        _family = _family.copyWith(tutores: updatedTutores);
                      });
                    },
                  ),
                ],
              ),
            )),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              'No hay documentos de identidad o laborales cargados para este tutor aún.',
              style: TextStyle(fontSize: 11, color: AppColors.slateGray),
            ),
          ],
        ],
      ),
    );
  }
}
