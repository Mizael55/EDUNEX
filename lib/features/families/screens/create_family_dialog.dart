import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../models/student_document.dart';
import '../models/tutor.dart';
import '../repositories/family_repository.dart';
import '../../../core/services/file_upload_service.dart';
import '../widgets/document_preview_dialog.dart';

/// Borrador de tutor adicional o persona autorizada para retiro de alumnos (Issue #19)
class TutorDraft {
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String parentesco = 'Madre';
  bool esAutorizadoRetiro = true;
  // Documentos adjuntos del tutor adicional (Issue #19)
  final Map<String, StudentDocument> documentosAdjuntos = {};

  void dispose() {
    nombresController.dispose();
    apellidosController.dispose();
    cedulaController.dispose();
    telefonoController.dispose();
    emailController.dispose();
  }
}

/// Borrador de estudiante para enrolamiento multi-alumno en la misma familia
class StudentDraft {
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  String grado = '1ro de Primaria';
  String genero = 'Masculino';
  DateTime fechaNacimiento = DateTime(2018, 5, 14);

  // Datos médicos (Caso 1)
  String tipoSangre = 'O+';
  final TextEditingController alergiasController = TextEditingController();
  final TextEditingController seguroMedicoController = TextEditingController(text: 'ARS Humano');
  final TextEditingController numeroPolizaController = TextEditingController();
  final TextEditingController pediatraController = TextEditingController();

  // Expediente escolar y documentos físicos (Caso 1 e Issue #19)
  bool fotoAdjunta = true;
  bool actaNacimientoAdjunta = true;
  bool certificadoNotasAdjunto = true;
  bool cartaSaldoConductaAdjunta = true;

  // Documentos adjuntos reales / interactivos en el expediente (Issue #19)
  final Map<String, StudentDocument> documentosAdjuntos = {
    'Foto 2x2': StudentDocument(
      id: 'doc-foto-init',
      tipo: 'Foto 2x2',
      nombreArchivo: 'foto_estudiante.jpg',
      tamanoBytes: 1024 * 320,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Acta de Nacimiento': StudentDocument(
      id: 'doc-acta-init',
      tipo: 'Acta de Nacimiento',
      nombreArchivo: 'acta_nacimiento_legalizada.pdf',
      tamanoBytes: 1024 * 1450,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Certificado de Notas': StudentDocument(
      id: 'doc-notas-init',
      tipo: 'Certificado de Notas',
      nombreArchivo: 'record_notas_oficial.pdf',
      tamanoBytes: 1024 * 890,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Carta de Saldo / Conducta': StudentDocument(
      id: 'doc-conducta-init',
      tipo: 'Carta de Saldo / Conducta',
      nombreArchivo: 'carta_saldo_conducta.pdf',
      tamanoBytes: 1024 * 540,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
  };

  void toggleDocument(String tipo, String defaultFilename, int defaultSize) {
    if (documentosAdjuntos.containsKey(tipo)) {
      documentosAdjuntos.remove(tipo);
    } else {
      documentosAdjuntos[tipo] = StudentDocument(
        id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
        tipo: tipo,
        nombreArchivo: defaultFilename,
        tamanoBytes: defaultSize,
        fechaSubida: DateTime.now(),
        verificado: true,
      );
    }
  }

  // Criterios evaluados del centro (Caso 1)
  String evaluacionAdmision = 'Aprobada';
  String entrevistaPsicologica = 'Aprobada';

  void dispose() {
    nombresController.dispose();
    apellidosController.dispose();
    alergiasController.dispose();
    seguroMedicoController.dispose();
    numeroPolizaController.dispose();
    pediatraController.dispose();
  }
}

/// Modal integral para enrolamiento familiar en EDUNEX.
///
/// Implementa los 3 Casos de Aceptación:
/// - Caso 1: Datos físicos del tutor (cédula, cartas de trabajo, estados financieros),
///   expediente del alumno (médicos, fotos, actas, notas) y criterios adicionales del centro.
/// - Caso 2: Tarifario, mensualidades y condición especial "Sujeto a mejora de pago"
///   con acuerdos por pronto pago (anual, 6 meses, 3 meses).
/// - Caso 3: Multi-estudiante (múltiples alumnos en la misma cuenta) y cotización consolidada.
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

class _CreateFamilyDialogState extends State<CreateFamilyDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  // Paso 1: Datos de la Familia & Tutor
  final _nombreFamiliaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _tutorNombresController = TextEditingController();
  final _tutorApellidosController = TextEditingController();
  final _tutorEmailController = TextEditingController();
  final _tutorTelefonoController = TextEditingController();
  final _tutorCedulaController = TextEditingController();
  String _selectedParentesco = 'Padre';

  // Datos laborales y financieros del tutor (Caso 1)
  final _tutorOcupacionController = TextEditingController();
  final _tutorLugarTrabajoController = TextEditingController();
  final _tutorTelefonoTrabajoController = TextEditingController();
  String _selectedIngresos = 'RD\$ 60,000 – 120,000 / mes';
  bool _cartaTrabajoAdjunta = true;
  bool _estadosFinancierosAdjuntos = true;
  bool _copiaCedulaAdjunta = true;
  final _tutorPasswordController = TextEditingController(text: '123456');

  // Issue #19: Documentos digitales interactivos del tutor / padre
  final Map<String, StudentDocument> _tutorDocuments = {
    'Copia Física de Cédula de Identidad': StudentDocument(
      id: 'doc-tutor-cedula',
      tipo: 'Copia Física de Cédula de Identidad',
      nombre: 'Copia Física de Cédula de Identidad',
      nombreArchivo: 'cedula_padre_tutor.pdf',
      tamanoBytes: 1024 * 450,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Carta de Trabajo / Certificación Laboral': StudentDocument(
      id: 'doc-tutor-laboral',
      tipo: 'Carta de Trabajo / Certificación Laboral',
      nombre: 'Carta de Trabajo / Certificación Laboral',
      nombreArchivo: 'certificacion_laboral.pdf',
      tamanoBytes: 1024 * 380,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Estados Financieros / Comprobante de Ingresos': StudentDocument(
      id: 'doc-tutor-ingresos',
      tipo: 'Estados Financieros / Comprobante de Ingresos',
      nombre: 'Estados Financieros / Comprobante de Ingresos',
      nombreArchivo: 'comprobante_ingresos.pdf',
      tamanoBytes: 1024 * 512,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
  };

  // Paso 1: Tutores Adicionales y Personas Autorizadas a Retirar (Issue #19)
  final List<TutorDraft> _additionalTutors = [];

  // Paso 2: Multi-Estudiante (Caso 3)
  final List<StudentDraft> _students = [];

  // Paso 3: Criterios adicionales del centro (Caso 1)
  final List<String> _criteriosPersonalizados = [
    'Entrevista con Orientación y Psicología Escolar',
    'Récord de conducta y saldo de colegio anterior',
  ];
  final _nuevoCriterioController = TextEditingController();

  // Paso 4: Precios, Sujeto a Mejora de Pago & Cotización (Casos 2 & 3)
  String _modalidadPago = 'mensual'; // 'mensual', 'trimestral', 'semestral', 'anual', 'acuerdo_especial'
  double _descuentoAcordadoPct = 0.0;
  final _notaAcuerdoPagoController = TextEditingController(
    text: 'Sujeto a mejora de pago acordada por pronto pago y hermanos en el centro.',
  );

  bool _isLoading = false;

  final List<String> _parentescos = ['Padre', 'Madre', 'Tutor Legal', 'Abuelo / Abuela', 'Tío / Tía', 'Chofer / Transporte', 'Hermano Mayor / Familiar'];
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

  final List<String> _rangosIngresos = [
    'Menos de RD\$ 40,000 / mes',
    'RD\$ 40,000 – 60,000 / mes',
    'RD\$ 60,000 – 120,000 / mes',
    'RD\$ 120,000 – 250,000 / mes',
    'Más de RD\$ 250,000 / mes',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Inicializar con 1 alumno inicial (Caso 3 permite agregar más)
    final initialStudent = StudentDraft();
    initialStudent.nombresController.text = 'Mateo';
    initialStudent.apellidosController.text = 'Pérez';
    _students.add(initialStudent);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreFamiliaController.dispose();
    _direccionController.dispose();
    _tutorNombresController.dispose();
    _tutorApellidosController.dispose();
    _tutorEmailController.dispose();
    _tutorTelefonoController.dispose();
    _tutorCedulaController.dispose();
    _tutorOcupacionController.dispose();
    _tutorLugarTrabajoController.dispose();
    _tutorTelefonoTrabajoController.dispose();
    _tutorPasswordController.dispose();
    _nuevoCriterioController.dispose();
    _notaAcuerdoPagoController.dispose();
    for (final t in _additionalTutors) {
      t.dispose();
    }
    for (final s in _students) {
      s.dispose();
    }
    super.dispose();
  }

  void _addAdditionalTutor() {
    setState(() {
      final draft = TutorDraft();
      draft.apellidosController.text = _tutorApellidosController.text.trim();
      _additionalTutors.add(draft);
    });
  }

  void _removeAdditionalTutor(int index) {
    setState(() {
      _additionalTutors[index].dispose();
      _additionalTutors.removeAt(index);
    });
  }

  void _addStudent() {
    setState(() {
      final newStudent = StudentDraft();
      newStudent.apellidosController.text = _tutorApellidosController.text.trim();
      newStudent.grado = 'Kínder (4-5 años)';
      _students.add(newStudent);
    });
  }

  void _removeStudent(int index) {
    if (_students.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La familia debe tener al menos un alumno a enrolar.')),
      );
      return;
    }
    setState(() {
      _students[index].dispose();
      _students.removeAt(index);
    });
  }

  // Cálculos de Cotización Escolar (Casos 2 & 3)
  double _getMonthlyTuitionForGrade(String grado) {
    if (grado.contains('Maternal') || grado.contains('Kínder') || grado.contains('Párvulos') || grado.contains('Pre-')) {
      return 6500.0;
    } else if (grado.contains('Primaria')) {
      return 8000.0;
    } else {
      return 9500.0;
    }
  }

  double get _subtotalMatricula => _students.length * 12000.0;

  double get _subtotalMensualidad {
    double total = 0;
    for (final s in _students) {
      total += _getMonthlyTuitionForGrade(s.grado);
    }
    return total;
  }

  double get _descuentoHermanos {
    if (_students.length < 2) return 0.0;
    double desc = 0;
    // 10% en el segundo hijo en adelante
    for (int i = 1; i < _students.length; i++) {
      desc += _getMonthlyTuitionForGrade(_students[i].grado) * 0.10;
    }
    return desc;
  }

  double get _descuentoModalidad {
    switch (_modalidadPago) {
      case 'anual':
        return (_subtotalMensualidad - _descuentoHermanos) * 0.10;
      case 'semestral':
        return (_subtotalMensualidad - _descuentoHermanos) * 0.05;
      case 'trimestral':
        return (_subtotalMensualidad - _descuentoHermanos) * 0.03;
      case 'acuerdo_especial':
        return (_subtotalMensualidad - _descuentoHermanos) * (_descuentoAcordadoPct / 100.0);
      default:
        return 0.0;
    }
  }

  double get _totalMensualNeto => (_subtotalMensualidad - _descuentoHermanos - _descuentoModalidad);

  void _showUploadDocModal(
    StudentDraft student,
    int studentIdx, {
    String? defaultTipo,
    String? defaultLabel,
    String? defaultFilename,
    int? defaultSize,
  }) {
    final tipoController = TextEditingController(text: defaultTipo ?? 'Foto 2x2');
    final filenameController = TextEditingController(
      text: defaultFilename ?? '${(defaultTipo ?? "documento").toLowerCase().replaceAll(' ', '_')}.pdf',
    );
    bool isCustom = defaultTipo == null || defaultTipo == 'Otro Documento';
    bool verificado = true;
    bool isFileSelected = true;
    RealPickedFile? pickedRealFile;
    int currentSize = defaultSize ?? (1024 * 512);

    final docTypes = [
      'Foto 2x2',
      'Acta de Nacimiento',
      'Certificado de Notas',
      'Carta de Saldo / Conducta',
      'Certificado Médico Escolar',
      'Tarjeta de Vacunación',
      'Cédula / Pasaporte Tutor',
      'Otro Documento',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final studentName = student.nombresController.text.trim().isNotEmpty
              ? student.nombresController.text.trim()
              : 'Estudiante #${studentIdx + 1}';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.cloud_upload_rounded, color: AppColors.navyPrimary, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Carga de Documento Digital', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Expediente: $studentName', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
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
                      value: docTypes.contains(tipoController.text) ? tipoController.text : 'Otro Documento',
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            tipoController.text = val;
                            isCustom = val == 'Otro Documento';
                            if (!isCustom && pickedRealFile == null) {
                              filenameController.text = '${val.toLowerCase().replaceAll(' ', '_')}.pdf';
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Especifique Tipo de Documento *',
                          hintText: 'Ej. Sentencia de Custodia, Informe Psicológico',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) => tipoController.text = v.trim(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Nombre del Archivo Digital:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: filenameController,
                      decoration: InputDecoration(
                        hintText: 'archivo_expediente.pdf',
                        isDense: true,
                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pickedRealFile != null ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: pickedRealFile != null ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pickedRealFile != null ? Icons.check_circle_rounded : Icons.insert_drive_file_rounded,
                            color: pickedRealFile != null ? const Color(0xFF16A34A) : AppColors.electricBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFileSelected ? filenameController.text : 'Ningún archivo seleccionado',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  pickedRealFile != null
                                      ? 'Archivo Real: ${pickedRealFile!.sizeFormatted} • Formato ${pickedRealFile!.extension.toUpperCase()} cargado'
                                      : 'Tamaño: ${(currentSize / 1024).toStringAsFixed(0)} KB • Formato: PDF/Digital',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: pickedRealFile != null ? const Color(0xFF15803D) : AppColors.slateGray,
                                    fontWeight: pickedRealFile != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final real = await FileUploadService.pickRealFile();
                              if (real != null) {
                                setModalState(() {
                                  pickedRealFile = real;
                                  isFileSelected = true;
                                  filenameController.text = real.name;
                                  currentSize = real.size;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Archivo real seleccionado: ${real.name} (${real.sizeFormatted})'),
                                      backgroundColor: AppColors.accentGreen,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                setModalState(() => isFileSelected = true);
                              }
                            },
                            icon: const Icon(Icons.file_open_rounded, size: 14),
                            label: const Text('Explorar', style: TextStyle(fontSize: 11)),
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
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                key: const Key('btn_confirm_upload_doc'),
                onPressed: () async {
                  final tipo = tipoController.text.trim().isNotEmpty ? tipoController.text.trim() : 'Documento';
                  final filename = filenameController.text.trim().isNotEmpty ? filenameController.text.trim() : '$tipo.pdf';
                  final size = pickedRealFile?.size ?? currentSize;

                  String? url;
                  if (pickedRealFile != null) {
                    url = await FileUploadService.uploadToStorage(file: pickedRealFile!, folder: 'estudiantes');
                  }

                  setState(() {
                    student.documentosAdjuntos[tipo] = StudentDocument(
                      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                      tipo: tipo,
                      nombreArchivo: filename,
                      urlArchivo: url,
                      tamanoBytes: size,
                      fechaSubida: DateTime.now(),
                      verificado: verificado,
                    );
                    if (tipo.contains('Foto')) student.fotoAdjunta = true;
                    if (tipo.contains('Acta')) student.actaNacimientoAdjunta = true;
                    if (tipo.contains('Nota') || tipo.contains('Récord')) student.certificadoNotasAdjunto = true;
                    if (tipo.contains('Conducta') || tipo.contains('Saldo')) student.cartaSaldoConductaAdjunta = true;
                  });

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Documento "$tipo" cargado y vinculado al expediente.'),
                        backgroundColor: AppColors.accentGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Subir y Adjuntar'),
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
    DocumentPreviewDialog.show(
      context,
      document: doc,
      studentName: studentName,
    );
  }

  void _showUploadTutorDocModal({
    required String defaultTipo,
    required String defaultLabel,
    required String defaultFilename,
    int defaultSize = 1024 * 450,
    TutorDraft? additionalTutor,
  }) {
    final tipoController = TextEditingController(text: defaultTipo);
    final filenameController = TextEditingController(text: defaultFilename);
    bool verificado = true;
    bool isFileSelected = true;
    int currentSize = defaultSize;
    RealPickedFile? pickedRealFile;

    final docTypes = [
      'Copia Física de Cédula de Identidad',
      'Carta de Trabajo / Certificación Laboral',
      'Estados Financieros / Comprobante de Ingresos',
      'Poder Notarial de Custodia',
      'Acta de Matrimonio / Unión Libre',
      'Otro Documento Personalizado',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isCustom = tipoController.text == 'Otro Documento Personalizado' ||
              (!docTypes.contains(tipoController.text) && tipoController.text.isNotEmpty);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.upload_file_rounded, color: AppColors.navyPrimary, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cargar Documento de Identidad / Tutor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutor: ${additionalTutor != null ? additionalTutor.nombresController.text.trim() : (_tutorNombresController.text.isNotEmpty ? "${_tutorNombresController.text} ${_tutorApellidosController.text}" : "Tutor Principal")}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: docTypes.contains(tipoController.text) ? tipoController.text : 'Otro Documento Personalizado',
                      decoration: InputDecoration(
                        labelText: 'Tipo de Documento',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            tipoController.text = val;
                            if (val == 'Copia Física de Cédula de Identidad') {
                              filenameController.text = 'cedula_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : "padre"}.pdf';
                            } else if (val == 'Carta de Trabajo / Certificación Laboral') {
                              filenameController.text = 'carta_trabajo_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : "tutor"}.pdf';
                            } else if (val == 'Estados Financieros / Comprobante de Ingresos') {
                              filenameController.text = 'comprobante_ingresos_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : "tutor"}.pdf';
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Especifique Tipo de Documento *',
                          hintText: 'Ej. Poder Notarial, Certificación Bancaria',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) => tipoController.text = v.trim(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Nombre del Archivo Digital:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: filenameController,
                      decoration: InputDecoration(
                        hintText: 'archivo_expediente.pdf',
                        isDense: true,
                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pickedRealFile != null ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: pickedRealFile != null ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pickedRealFile != null ? Icons.check_circle_rounded : Icons.insert_drive_file_rounded,
                            color: pickedRealFile != null ? const Color(0xFF16A34A) : AppColors.electricBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFileSelected ? filenameController.text : 'Ningún archivo seleccionado',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  pickedRealFile != null
                                      ? 'Archivo Real: ${pickedRealFile!.sizeFormatted} • Formato ${pickedRealFile!.extension.toUpperCase()} cargado'
                                      : 'Tamaño: ${(currentSize / 1024).toStringAsFixed(0)} KB • Formato: PDF/Digital',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: pickedRealFile != null ? const Color(0xFF15803D) : AppColors.slateGray,
                                    fontWeight: pickedRealFile != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final real = await FileUploadService.pickRealFile();
                              if (real != null) {
                                setModalState(() {
                                  pickedRealFile = real;
                                  isFileSelected = true;
                                  filenameController.text = real.name;
                                  currentSize = real.size;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Archivo real seleccionado: ${real.name} (${real.sizeFormatted})'),
                                      backgroundColor: AppColors.accentGreen,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                setModalState(() => isFileSelected = true);
                              }
                            },
                            icon: const Icon(Icons.file_open_rounded, size: 14),
                            label: const Text('Explorar', style: TextStyle(fontSize: 11)),
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
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                key: const Key('btn_confirm_upload_tutor_doc'),
                onPressed: () async {
                  final tipo = tipoController.text.trim().isNotEmpty ? tipoController.text.trim() : 'Documento';
                  final filename = filenameController.text.trim().isNotEmpty ? filenameController.text.trim() : '$tipo.pdf';
                  final size = pickedRealFile?.size ?? currentSize;

                  String? url;
                  if (pickedRealFile != null) {
                    url = await FileUploadService.uploadToStorage(file: pickedRealFile!, folder: 'tutores');
                  }

                  final newDoc = StudentDocument(
                    id: 'doc-tut-${DateTime.now().millisecondsSinceEpoch}',
                    tipo: tipo,
                    nombreArchivo: filename,
                    urlArchivo: url,
                    tamanoBytes: size,
                    fechaSubida: DateTime.now(),
                    verificado: verificado,
                  );

                  setState(() {
                    if (additionalTutor != null) {
                      additionalTutor.documentosAdjuntos[tipo] = newDoc;
                    } else {
                      _tutorDocuments[tipo] = newDoc;
                      if (tipo.contains('Cédula') || tipo.contains('Cedula')) _copiaCedulaAdjunta = true;
                      if (tipo.contains('Trabajo') || tipo.contains('Laboral')) _cartaTrabajoAdjunta = true;
                      if (tipo.contains('Financiero') || tipo.contains('Ingreso')) _estadosFinancierosAdjuntos = true;
                    }
                  });

                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Documento "$filename" cargado con éxito.'),
                        backgroundColor: AppColors.accentGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Confirmar y Adjuntar'),
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

  Widget _buildTutorDocRow({
    required String tipoKey,
    required String label,
    required bool isAttached,
    required StudentDocument? doc,
    required String defaultFilename,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAttached ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAttached ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isAttached,
            onChanged: (v) {
              if (v == true) {
                onUpload();
              } else {
                onRemove();
              }
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Icon(
            isAttached ? Icons.check_circle_rounded : Icons.insert_drive_file_outlined,
            size: 18,
            color: isAttached ? const Color(0xFF16A34A) : AppColors.slateGray,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAttached ? const Color(0xFF14532D) : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isAttached && doc != null
                      ? '${doc.nombreArchivo} • ${doc.tamanoFormateado} • ✅ Verificado'
                      : 'Pendiente de adjuntar archivo digital',
                  style: TextStyle(
                    fontSize: 10,
                    color: isAttached ? const Color(0xFF15803D) : AppColors.slateGray,
                  ),
                ),
              ],
            ),
          ),
          if (isAttached && doc != null) ...[
            TextButton.icon(
              key: Key('btn_ver_doc_tutor_${tipoKey.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}'),
              onPressed: () => _showPreviewDocModal(
                doc,
                _tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.trim() : 'Tutor Principal',
              ),
              icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.navyPrimary),
              label: const Text('Ver', style: TextStyle(fontSize: 11, color: AppColors.navyPrimary)),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              key: Key('btn_quitar_doc_tutor_${tipoKey.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}'),
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
              label: const Text('Quitar', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            ElevatedButton.icon(
              key: Key('btn_cargar_doc_tutor_${tipoKey.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}'),
              onPressed: onUpload,
              icon: const Icon(Icons.file_upload_outlined, size: 14),
              label: const Text('Cargar Archivo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final uniqueSuffix = now.millisecondsSinceEpoch.toString().substring(8);

      final List<Student> studentsList = [];
      for (int i = 0; i < _students.length; i++) {
        final draft = _students[i];
        final studentId = 'est-${now.millisecondsSinceEpoch}-$i';
        studentsList.add(
          Student(
            id: studentId,
            colegioId: widget.colegioId,
            familiaId: 'temp',
            matricula: 'EST-${now.year}-$uniqueSuffix-${i + 1}',
            nombres: draft.nombresController.text.trim().isNotEmpty
                ? draft.nombresController.text.trim()
                : 'Alumno ${i + 1}',
            apellidos: draft.apellidosController.text.trim().isNotEmpty
                ? draft.apellidosController.text.trim()
                : _tutorApellidosController.text.trim(),
            fechaNacimiento: draft.fechaNacimiento,
            genero: draft.genero,
            gradoNombre: draft.grado,
            seccionNombre: 'Sección A',
            tipoSangre: draft.tipoSangre,
            alergias: draft.alergiasController.text.trim().isNotEmpty
                ? draft.alergiasController.text.trim()
                : 'Ninguna conocida',
            seguroMedico: draft.seguroMedicoController.text.trim(),
            numeroPoliza: draft.numeroPolizaController.text.trim(),
            pediatraContacto: draft.pediatraController.text.trim(),
            fotoAdjunta: draft.fotoAdjunta,
            actaNacimientoAdjunta: draft.actaNacimientoAdjunta,
            certificadoNotasAdjunto: draft.certificadoNotasAdjunto,
            cartaSaldoConductaAdjunta: draft.cartaSaldoConductaAdjunta,
            documentosExpediente: draft.documentosAdjuntos.values.toList(),
            criteriosEvaluados: {
              'Evaluación Admisión': draft.evaluacionAdmision,
              'Entrevista Psicología': draft.entrevistaPsicologica,
            },
            activo: true,
          ),
        );
      }

      // Convertir tutores adicionales y autorizados a retirar (Issue #19)
      final List<Tutor> additionalTutorsList = [];
      for (int i = 0; i < _additionalTutors.length; i++) {
        final tDraft = _additionalTutors[i];
        if (tDraft.nombresController.text.trim().isNotEmpty) {
          additionalTutorsList.add(
            Tutor(
              id: 'tutor-add-${now.millisecondsSinceEpoch}-$i',
              familiaId: 'temp',
              nombres: tDraft.nombresController.text.trim(),
              apellidos: tDraft.apellidosController.text.trim(),
              parentesco: tDraft.parentesco,
              cedulaOPasaporte: tDraft.cedulaController.text.trim().isNotEmpty
                  ? tDraft.cedulaController.text.trim()
                  : null,
              telefono: tDraft.telefonoController.text.trim().isNotEmpty
                  ? tDraft.telefonoController.text.trim()
                  : null,
              email: tDraft.emailController.text.trim().isNotEmpty
                  ? tDraft.emailController.text.trim()
                  : null,
              esContactoPrincipal: false,
              autorizadoRecoger: tDraft.esAutorizadoRetiro,
              documentosExpediente: tDraft.documentosAdjuntos.values.toList(),
            ),
          );
        }
      }

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
        ocupacion: _tutorOcupacionController.text.trim().isNotEmpty ? _tutorOcupacionController.text.trim() : null,
        lugarTrabajo: _tutorLugarTrabajoController.text.trim().isNotEmpty ? _tutorLugarTrabajoController.text.trim() : null,
        telefonoTrabajo: _tutorTelefonoTrabajoController.text.trim().isNotEmpty ? _tutorTelefonoTrabajoController.text.trim() : null,
        ingresosAproximados: _selectedIngresos,
        cartaTrabajoAdjunta: _cartaTrabajoAdjunta,
        estadosFinancierosAdjuntos: _estadosFinancierosAdjuntos,
        copiaCedulaAdjunta: _copiaCedulaAdjunta,
        tutorDocumentos: _tutorDocuments.values.toList(),
        balanceInicial: _subtotalMatricula, // Saldo inicial correspondiente a matrícula
        multipleStudents: studentsList,
        additionalTutors: additionalTutorsList.isNotEmpty ? additionalTutorsList : null,
        modalidadPago: _modalidadPago,
        descuentoAcordadoPct: (_descuentoHermanos + _descuentoModalidad) > 0
            ? ((_descuentoHermanos + _descuentoModalidad) / _subtotalMensualidad) * 100.0
            : 0.0,
        notaAcuerdoPago: _notaAcuerdoPagoController.text.trim(),
        criteriosCentroAdicionales: _criteriosPersonalizados,
      );

      if (mounted) {
        widget.onFamilyCreated?.call(family);
        Navigator.of(context).pop(family);

        // Mostrar confirmación detallada con datos del tutor
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 28),
                const SizedBox(width: 10),
                const Text('Familia Enrolada con Éxito'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta Familiar: ${family.nombreFamilia}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Código Oficial: ${family.codigoFamilia}', style: const TextStyle(color: AppColors.slateGray)),
                const SizedBox(height: 12),
                Text('• Estudiantes matriculados: ${family.estudiantes.length} alumnos'),
                Text('• Tutor Principal: ${family.tutorPrincipal?.nombreCompleto}'),
                Text('• Correo de acceso: ${family.emailPrincipal}'),
                Text('• Cuota mensual neta: RD\$ ${_totalMensualNeto.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Credenciales de acceso listas. El tutor ya puede ingresar al Portal de Padres con este correo y su contraseña.',
                    style: TextStyle(fontSize: 12, color: AppColors.slateDark),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
                child: const Text('Aceptar y Continuar', style: TextStyle(color: Colors.white)),
              ),
            ],
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

  void _showQuoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.navyPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cotización Escolar Consolidada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('EDUNEX Core - Cuenta Familiar Única', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Familia: ${_nombreFamiliaController.text.isNotEmpty ? _nombreFamiliaController.text : "Familia Prospecto"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text('Tutor: ${_tutorNombresController.text} ${_tutorApellidosController.text} (Cédula: ${_tutorCedulaController.text})'),
                      Text('Modalidad de Pago: ${_modalidadPago.toUpperCase()} (Sujeto a Mejora de Pago)'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Desglose por Alumnos Enrolados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ..._students.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final tuition = _getMonthlyTuitionForGrade(s.grado);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hijo #${idx + 1}: ${s.nombresController.text.isNotEmpty ? s.nombresController.text : "Sin nombre"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text('Grado: ${s.grado}', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Matrícula: RD\$ 12,000.00', style: const TextStyle(fontSize: 11)),
                            Text('Mensualidad: RD\$ ${tuition.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                const SizedBox(height: 6),
                _buildSummaryRow('Subtotal Matrículas (${_students.length} alumnos):', 'RD\$ ${_subtotalMatricula.toStringAsFixed(2)}'),
                _buildSummaryRow('Subtotal Mensualidades:', 'RD\$ ${_subtotalMensualidad.toStringAsFixed(2)}'),
                if (_descuentoHermanos > 0)
                  _buildSummaryRow('Descuento por Múltiples Hermanos (10% en 2do+):', '- RD\$ ${_descuentoHermanos.toStringAsFixed(2)}', isDiscount: true),
                if (_descuentoModalidad > 0)
                  _buildSummaryRow('Descuento Modalidad Pronto Pago ($_modalidadPago):', '- RD\$ ${_descuentoModalidad.toStringAsFixed(2)}', isDiscount: true),
                const Divider(),
                _buildSummaryRow('CUOTA MENSUAL FINAL CONSOLIDADA:', 'RD\$ ${_totalMensualNeto.toStringAsFixed(2)}', isTotal: true),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cotización exportada a PDF / Impresión lista.')),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Imprimir Cotización'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
            child: const Text('Cerrar y Continuar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 13 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isDiscount ? Colors.green.shade800 : AppColors.slateDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15 : 12,
              fontWeight: (isTotal || isDiscount) ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? AppColors.navyPrimary
                  : isDiscount
                      ? Colors.green.shade800
                      : AppColors.slateDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 880),
        child: Column(
          children: [
            // Header del Modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.electricBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      Icons.person_add_alt_1_rounded,
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
                          'Alta de Cuenta Familiar Única',
                          style: TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enrolamiento integral: tutores, multi-estudiantes, expediente, criterios y cotización',
                          style: TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.surfaceWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Pestañas de Navegación del Proceso
            Container(
              color: const Color(0xFFF8FAFC),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.navyPrimary,
                unselectedLabelColor: AppColors.slateGray,
                indicatorColor: AppColors.electricBlue,
                indicatorWeight: 3,
                isScrollable: false,
                tabs: [
                  const Tab(icon: Icon(Icons.badge_rounded, size: 18), text: '1. Tutor & Familia'),
                  Tab(
                    icon: const Icon(Icons.family_restroom_rounded, size: 18),
                    text: '2. Alumnos (${_students.length})',
                  ),
                  const Tab(icon: Icon(Icons.fact_check_rounded, size: 18), text: '3. Criterios del Centro'),
                  const Tab(icon: Icon(Icons.calculate_rounded, size: 18), text: '4. Cotización & Pagos'),
                ],
              ),
            ),

            // Contenido con Scroll
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTutorTab(),
                    _buildStudentsTab(),
                    _buildCriteriaTab(),
                    _buildPricingAndQuoteTab(),
                  ],
                ),
              ),
            ),

            // Footer con Botones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showQuoteDialog,
                        icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                        label: const Text('Previsualizar Cotización'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyPrimary,
                          side: const BorderSide(color: AppColors.navyPrimary),
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navyPrimary,
                              foregroundColor: AppColors.surfaceWhite,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Completar Enrolamiento Familiar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Tutor y Datos Físicos (Caso 1)
  Widget _buildTutorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos Generales de la Cuenta Familiar:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _nombreFamiliaController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la Familia *',
                    hintText: 'Ej. Familia Pérez González',
                    prefixIcon: const Icon(Icons.people_alt_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedParentesco,
                  decoration: InputDecoration(
                    labelText: 'Parentesco del Tutor',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _parentescos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _selectedParentesco = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _direccionController,
            decoration: InputDecoration(
              labelText: 'Dirección Residencial Física *',
              hintText: 'Ej. Calle Los Prados #12, Ensanche Naco, Santo Domingo',
              prefixIcon: const Icon(Icons.home_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          const Text(
            'Datos Físicos del Tutor Legal (Caso 1):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tutorNombresController,
                  decoration: InputDecoration(
                    labelText: 'Nombres del Tutor *',
                    hintText: 'Ej. Roberto',
                    prefixIcon: const Icon(Icons.person_rounded),
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
                    labelText: 'Apellidos del Tutor *',
                    hintText: 'Ej. Pérez',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tutorCedulaController,
                  decoration: InputDecoration(
                    labelText: 'Cédula de Identidad o Pasaporte *',
                    hintText: '001-1234567-8',
                    prefixIcon: const Icon(Icons.badge_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Cédula requerida' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tutorTelefonoController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono Móvil / WhatsApp *',
                    hintText: '809-555-0150',
                    prefixIcon: const Icon(Icons.phone_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Teléfono requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tutorEmailController,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico del Tutor (Usuario de Acceso) *',
                    hintText: 'tutor@ejemplo.com',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Correo requerido' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tutorPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña para Portal de Padres *',
                    hintText: '123456',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Datos laborales y estados financieros (Caso 1)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.work_outline_rounded, size: 18, color: AppColors.navyPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Información Laboral & Documentos Financieros (Caso 1):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tutorOcupacionController,
                        decoration: InputDecoration(
                          labelText: 'Ocupación / Profesión',
                          hintText: 'Ej. Ingeniero Civil',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _tutorLugarTrabajoController,
                        decoration: InputDecoration(
                          labelText: 'Empresa / Lugar de Trabajo',
                          hintText: 'Ej. Constructora del Caribe',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedIngresos,
                  decoration: InputDecoration(
                    labelText: 'Rango de Ingresos Familiares Aproximados',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _rangosIngresos.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedIngresos = v!),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documentos Físicos del Tutor / Cédula del Padre (Issue #19):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                          ),
                          Text(
                            'Carga los documentos oficiales de identidad e ingresos del tutor.',
                            style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: const Key('btn_add_custom_tutor_doc'),
                      onPressed: () => _showUploadTutorDocModal(
                        defaultTipo: 'Otro Documento Personalizado',
                        defaultLabel: 'Documento Adicional',
                        defaultFilename: 'documento_adicional_tutor.pdf',
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                      label: const Text('+ Cargar Otro Documento', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyPrimary,
                        side: const BorderSide(color: AppColors.navyPrimary),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 1. Copia Física de Cédula de Identidad
                _buildTutorDocRow(
                  tipoKey: 'Copia Física de Cédula de Identidad',
                  label: 'Copia Física de Cédula de Identidad (Padre / Tutor)',
                  isAttached: _copiaCedulaAdjunta && _tutorDocuments.containsKey('Copia Física de Cédula de Identidad'),
                  doc: _tutorDocuments['Copia Física de Cédula de Identidad'],
                  defaultFilename: 'cedula_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : 'padre'}.pdf',
                  onUpload: () => _showUploadTutorDocModal(
                    defaultTipo: 'Copia Física de Cédula de Identidad',
                    defaultLabel: 'Cédula de Identidad',
                    defaultFilename: 'cedula_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : 'padre'}.pdf',
                  ),
                  onRemove: () {
                    setState(() {
                      _tutorDocuments.remove('Copia Física de Cédula de Identidad');
                      _copiaCedulaAdjunta = false;
                    });
                  },
                ),

                // 2. Carta de Trabajo / Certificación Laboral
                _buildTutorDocRow(
                  tipoKey: 'Carta de Trabajo / Certificación Laboral',
                  label: 'Carta de Trabajo / Certificación Laboral',
                  isAttached: _cartaTrabajoAdjunta && _tutorDocuments.containsKey('Carta de Trabajo / Certificación Laboral'),
                  doc: _tutorDocuments['Carta de Trabajo / Certificación Laboral'],
                  defaultFilename: 'carta_trabajo_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : 'tutor'}.pdf',
                  onUpload: () => _showUploadTutorDocModal(
                    defaultTipo: 'Carta de Trabajo / Certificación Laboral',
                    defaultLabel: 'Carta de Trabajo',
                    defaultFilename: 'carta_trabajo_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : 'tutor'}.pdf',
                  ),
                  onRemove: () {
                    setState(() {
                      _tutorDocuments.remove('Carta de Trabajo / Certificación Laboral');
                      _cartaTrabajoAdjunta = false;
                    });
                  },
                ),

                // 3. Estados Financieros / Comprobante de Ingresos
                _buildTutorDocRow(
                  tipoKey: 'Estados Financieros / Comprobante de Ingresos',
                  label: 'Estados Financieros / Comprobante de Ingresos',
                  isAttached: _estadosFinancierosAdjuntos && _tutorDocuments.containsKey('Estados Financieros / Comprobante de Ingresos'),
                  doc: _tutorDocuments['Estados Financieros / Comprobante de Ingresos'],
                  defaultFilename: 'comprobante_ingresos_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : 'tutor'}.pdf',
                  onUpload: () => _showUploadTutorDocModal(
                    defaultTipo: 'Estados Financieros / Comprobante de Ingresos',
                    defaultLabel: 'Estados Financieros',
                    defaultFilename: 'comprobante_ingresos_${_tutorNombresController.text.isNotEmpty ? _tutorNombresController.text.toLowerCase().replaceAll(' ', '_') : 'tutor'}.pdf',
                  ),
                  onRemove: () {
                    setState(() {
                      _tutorDocuments.remove('Estados Financieros / Comprobante de Ingresos');
                      _estadosFinancierosAdjuntos = false;
                    });
                  },
                ),

                // Documentos adicionales personalizados del tutor
                ..._tutorDocuments.entries.where((e) => ![
                  'Copia Física de Cédula de Identidad',
                  'Carta de Trabajo / Certificación Laboral',
                  'Estados Financieros / Comprobante de Ingresos',
                ].contains(e.key)).map((entry) {
                  final doc = entry.value;
                  return _buildTutorDocRow(
                    tipoKey: entry.key,
                    label: doc.tipo,
                    isAttached: true,
                    doc: doc,
                    defaultFilename: doc.nombreArchivo,
                    onUpload: () {},
                    onRemove: () {
                      setState(() => _tutorDocuments.remove(entry.key));
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          // Tutores Adicionales y Personas Autorizadas a Retirar (Issue #19)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutores Adicionales y Personas Autorizadas (Issue #19):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                    ),
                    Text(
                      'Agrega a la madre, abuelos, chofer o familiares facultados para retirar al alumno.',
                      style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                key: const Key('btn_add_another_tutor'),
                onPressed: _addAdditionalTutor,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('+ Agregar Tutor / Autorizado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: AppColors.navyPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_additionalTutors.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.slateGray),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No hay tutores adicionales agregados. El tutor principal registrado arriba será el único contacto inicial.',
                      style: TextStyle(fontSize: 12, color: AppColors.slateDark),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._additionalTutors.asMap().entries.map((entry) {
              final idx = entry.key;
              final tDraft = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tutor / Autorizado #${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          tooltip: 'Quitar Tutor',
                          onPressed: () => _removeAdditionalTutor(idx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: tDraft.nombresController,
                            decoration: InputDecoration(
                              labelText: 'Nombres *',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: tDraft.apellidosController,
                            decoration: InputDecoration(
                              labelText: 'Apellidos *',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: tDraft.cedulaController,
                            decoration: InputDecoration(
                              labelText: 'Cédula / Documento',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: tDraft.telefonoController,
                            decoration: InputDecoration(
                              labelText: 'Teléfono Móvil',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: tDraft.parentesco,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Parentesco / Vínculo',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _parentescos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (v) => setState(() => tDraft.parentesco = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: tDraft.emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo Electrónico (opcional)',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: tDraft.esAutorizadoRetiro,
                          onChanged: (v) => setState(() => tDraft.esAutorizadoRetiro = v ?? true),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Expanded(
                          child: Text(
                            'Persona autorizada formalmente para retirar alumnos del colegio',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                          ),
                        ),
                      ],
                    ),

                    // Documentos del Tutor Adicional (Issue #19)
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Documentos / Cédula del Tutor Adicional:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          key: Key('btn_cargar_doc_tutor_extra_$idx'),
                          onPressed: () => _showUploadTutorDocModal(
                            defaultTipo: 'Copia Física de Cédula de Identidad',
                            defaultLabel: 'Cédula de Identidad',
                            defaultFilename: 'cedula_${tDraft.nombresController.text.isNotEmpty ? tDraft.nombresController.text.toLowerCase().replaceAll(' ', '_') : "tutor_$idx"}.pdf',
                            additionalTutor: tDraft,
                          ),
                          icon: const Icon(Icons.upload_file_rounded, size: 14),
                          label: const Text('Cargar Cédula / Doc', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navyPrimary,
                            side: const BorderSide(color: AppColors.navyPrimary),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    if (tDraft.documentosAdjuntos.isNotEmpty)
                      ...tDraft.documentosAdjuntos.entries.map((dEntry) {
                        final d = dEntry.value;
                        return Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${d.tipo}: ${d.nombreArchivo} (${d.tamanoFormateado})',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF14532D)),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showPreviewDocModal(d, tDraft.nombresController.text.trim()),
                                icon: const Icon(Icons.visibility_outlined, size: 12, color: AppColors.navyPrimary),
                                label: const Text('Ver', style: TextStyle(fontSize: 10, color: AppColors.navyPrimary)),
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => tDraft.documentosAdjuntos.remove(dEntry.key)),
                                icon: const Icon(Icons.delete_outline_rounded, size: 12, color: Colors.redAccent),
                                label: const Text('Quitar', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // TAB 2: Alumnos Inscritos (Caso 3 Multi-Estudiante & Caso 1 Expediente)
  Widget _buildStudentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alumnos y Hermanos Matriculados (Caso 3):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                    ),
                    Text(
                      'Enrola a todos los hijos de la familia en la misma cuenta consolidada.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addStudent,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('+ Agregar Otro Alumno / Hermano'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._students.asMap().entries.map((entry) {
            final idx = entry.key;
            final student = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ALUMNO #${idx + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.navyPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            student.nombresController.text.isNotEmpty
                                ? '${student.nombresController.text} ${student.apellidosController.text}'
                                : 'Nuevo Estudiante',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      if (_students.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Eliminar Alumno',
                          onPressed: () => _removeStudent(idx),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: student.nombresController,
                          decoration: InputDecoration(
                            labelText: 'Nombres del Alumno *',
                            hintText: 'Ej. Mateo',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: student.apellidosController,
                          decoration: InputDecoration(
                            labelText: 'Apellidos del Alumno *',
                            hintText: 'Ej. Pérez González',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: student.grado,
                          decoration: InputDecoration(
                            labelText: 'Grado Escolar *',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: _grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => student.grado = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: student.genero,
                          decoration: InputDecoration(
                            labelText: 'Género',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                            DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                          ],
                          onChanged: (v) => setState(() => student.genero = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sección Médica y Expediente Escolar (Caso 1)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expediente Médico & Clínico (Caso 1):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: student.tipoSangre,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de Sangre',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                items: const ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (v) => setState(() => student.tipoSangre = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: student.alergiasController,
                                decoration: InputDecoration(
                                  labelText: 'Alergias / Restricciones',
                                  hintText: 'Ej. Penicilina, maní',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: student.seguroMedicoController,
                                decoration: InputDecoration(
                                  labelText: 'Seguro Médico / ARS',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Documentos del Expediente Escolar & Carga Digital (Issue #19):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                                ),
                                Text(
                                  'Sube los documentos oficiales obligatorios para la admisión del estudiante.',
                                  style: TextStyle(fontSize: 10, color: AppColors.slateGray),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              key: Key('btn_cargar_expediente_demo_$idx'),
                              onPressed: () {
                                setState(() {
                                  // Alternar o cargar documento adicional interactivo
                                  student.toggleDocument(
                                    'Certificado Médico Escolar',
                                    'certificado_medico_${student.nombresController.text.toLowerCase().trim().replaceAll(' ', '_')}.pdf',
                                    1024 * 410,
                                  );
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Documento actualizado en el expediente del estudiante.'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.upload_file_rounded, size: 14),
                              label: const Text('Adjuntar / Gestionar', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navyPrimary,
                                side: const BorderSide(color: AppColors.navyPrimary),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Lista visual de documentos requeridos y adjuntos
                        ...[
                          ('Foto 2x2', 'Foto 2x2 del Estudiante', 'foto_${idx + 1}.jpg', 1024 * 320),
                          ('Acta de Nacimiento', 'Acta de Nacimiento Legalizada', 'acta_nacimiento_oficial.pdf', 1024 * 1450),
                          ('Certificado de Notas', 'Certificado / Récord de Notas', 'record_calificaciones.pdf', 1024 * 890),
                          ('Carta de Saldo / Conducta', 'Carta de Saldo y Buena Conducta', 'carta_conducta.pdf', 1024 * 540),
                          ('Certificado Médico Escolar', 'Certificado Médico & Vacunación', 'certificado_medico.pdf', 1024 * 410),
                        ].map((docDef) {
                          final tipoKey = docDef.$1;
                          final label = docDef.$2;
                          final defaultFilename = docDef.$3;
                          final defaultSize = docDef.$4;
                          final isAttached = student.documentosAdjuntos.containsKey(tipoKey);
                          final doc = student.documentosAdjuntos[tipoKey];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAttached ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAttached ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isAttached ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                  size: 18,
                                  color: isAttached ? const Color(0xFF16A34A) : AppColors.slateGray,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isAttached ? const Color(0xFF14532D) : AppColors.slateDark,
                                        ),
                                      ),
                                      if (isAttached && doc != null)
                                        Text(
                                          '${doc.nombreArchivo} • ${doc.tamanoFormateado} • ✅ Verificado',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                                        )
                                      else
                                        const Text(
                                          'Pendiente de digitalización • Formatos: PDF, JPG, PNG',
                                          style: TextStyle(fontSize: 10, color: AppColors.slateGray),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isAttached && doc != null) ...[
                                  TextButton.icon(
                                    onPressed: () => _showPreviewDocModal(doc, student.nombresController.text.trim()),
                                    icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.navyPrimary),
                                    label: const Text('Ver', style: TextStyle(fontSize: 11, color: AppColors.navyPrimary)),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        student.documentosAdjuntos.remove(tipoKey);
                                        if (tipoKey == 'Foto 2x2') student.fotoAdjunta = false;
                                        if (tipoKey == 'Acta de Nacimiento') student.actaNacimientoAdjunta = false;
                                        if (tipoKey == 'Certificado de Notas') student.certificadoNotasAdjunto = false;
                                        if (tipoKey == 'Carta de Saldo / Conducta') student.cartaSaldoConductaAdjunta = false;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                    label: const Text('Quitar', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    key: Key('btn_cargar_doc_${tipoKey}_$idx'),
                                    onPressed: () => _showUploadDocModal(
                                      student,
                                      idx,
                                      defaultTipo: tipoKey,
                                      defaultLabel: label,
                                      defaultFilename: defaultFilename,
                                      defaultSize: defaultSize,
                                    ),
                                    icon: const Icon(Icons.file_upload_outlined, size: 14),
                                    label: const Text('Cargar Archivo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navyPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),

                        // Mostrar documentos adicionales personalizados cargados
                        ...student.documentosAdjuntos.entries.where((e) => ![
                          'Foto 2x2',
                          'Acta de Nacimiento',
                          'Certificado de Notas',
                          'Carta de Saldo / Conducta',
                          'Certificado Médico Escolar',
                        ].contains(e.key)).map((entry) {
                          final doc = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.tipo,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                                      ),
                                      Text(
                                        '${doc.nombreArchivo} • ${doc.tamanoFormateado} • ✅ Personalizado',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF15803D)),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showPreviewDocModal(doc, student.nombresController.text.trim()),
                                  icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.navyPrimary),
                                  label: const Text('Ver', style: TextStyle(fontSize: 11, color: AppColors.navyPrimary)),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() => student.documentosAdjuntos.remove(entry.key));
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                  label: const Text('Quitar', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              key: Key('btn_add_custom_doc_$idx'),
                              onPressed: () => _showUploadDocModal(student, idx, defaultTipo: 'Otro Documento'),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                              label: const Text('+ Cargar Otro Documento Personalizado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navyPrimary,
                                side: const BorderSide(color: AppColors.navyPrimary),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocCheckbox(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(title, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // TAB 3: Criterios Adicionales del Centro (Caso 1)
  Widget _buildCriteriaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Criterios de Admisión y Validación del Centro (Caso 1):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
          ),
          Text(
            'El centro educativo puede evaluar y crear criterios adicionales para la admisión.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 16),

          // Criterios predeterminados evaluados
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Evaluaciones Oficiales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                const Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.verified_outlined, color: AppColors.accentGreen),
                    title: Text('Prueba de Admisión Académica', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('Evaluación de competencias básicas según el grado MINERD'),
                    trailing: Chip(label: Text('Aprobada', style: TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: AppColors.accentGreen),
                  ),
                ),
                const Divider(),
                const Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.psychology_outlined, color: AppColors.electricBlue),
                    title: Text('Entrevista Psicopedagógica Familiar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('Alineación con el proyecto educativo institucional'),
                    trailing: Chip(label: Text('Aprobada', style: TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: AppColors.electricBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Criterios adicionales personalizados
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Criterios Adicionales Definidos por el Centro:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ..._criteriosPersonalizados.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.navyPrimary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nuevoCriterioController,
                        decoration: InputDecoration(
                          hintText: 'Agregar nuevo criterio personalizado (ej. Carta pastoral, egresados)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_nuevoCriterioController.text.trim().isNotEmpty) {
                          setState(() {
                            _criteriosPersonalizados.add(_nuevoCriterioController.text.trim());
                            _nuevoCriterioController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
                      child: const Text('Agregar Criterio', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: Precios, Sujeto a Mejora de Pago & Cotización (Casos 2 & 3)
  Widget _buildPricingAndQuoteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acuerdos de Pago & Cotización Final Consolidada (Casos 2 & 3):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
          ),
          Text(
            'Establece la modalidad de pago pactada con la familia y genera su cotización oficial.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 16),

          // Selector de modalidad "Sujeto a mejora de pago"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.electricBlue, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.handshake_rounded, color: AppColors.navyPrimary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Condición: Sujeto a Mejora de Pago (Caso 2)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _modalidadPago,
                  decoration: InputDecoration(
                    labelText: 'Modalidad de Pago Acordada con la Familia',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mensual', child: Text('Mensual Regular (10 cuotas estándar)')),
                    DropdownMenuItem(value: 'trimestral', child: Text('Trimestral Anticipado (3% descuento)')),
                    DropdownMenuItem(value: 'semestral', child: Text('Semestral Anticipado - 6 Meses (5% descuento)')),
                    DropdownMenuItem(value: 'anual', child: Text('Año Completo Anticipado (10% descuento)')),
                    DropdownMenuItem(value: 'acuerdo_especial', child: Text('Acuerdo Especial Personalizado por Familia')),
                  ],
                  onChanged: (v) => setState(() => _modalidadPago = v!),
                ),
                if (_modalidadPago == 'acuerdo_especial') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _descuentoAcordadoPct.toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Porcentaje de Descuento Acordado (%)',
                            suffixText: '%',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _descuentoAcordadoPct = double.tryParse(v) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _notaAcuerdoPagoController,
                          decoration: InputDecoration(
                            labelText: 'Nota del Acuerdo (Justificación)',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resumen consolidado en tiempo real
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text('Resumen Consolidado de la Cuenta Familiar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Chip(
                      label: Text('COTIZADOR EN VIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      backgroundColor: AppColors.navyPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSummaryRow('Alumnos enrolados:', '${_students.length} estudiantes'),
                _buildSummaryRow('Matrícula total requerida:', 'RD\$ ${_subtotalMatricula.toStringAsFixed(2)}'),
                _buildSummaryRow('Colegiatura mensual regular:', 'RD\$ ${_subtotalMensualidad.toStringAsFixed(2)}'),
                if (_descuentoHermanos > 0)
                  _buildSummaryRow('Descuento por múltiples hermanos (10% en 2do+):', '- RD\$ ${_descuentoHermanos.toStringAsFixed(2)}', isDiscount: true),
                if (_descuentoModalidad > 0)
                  _buildSummaryRow('Descuento por pronto pago / mejora de pago:', '- RD\$ ${_descuentoModalidad.toStringAsFixed(2)}', isDiscount: true),
                const Divider(),
                _buildSummaryRow('CUOTA MENSUAL FINAL CONSOLIDADA:', 'RD\$ ${_totalMensualNeto.toStringAsFixed(2)}', isTotal: true),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _showQuoteDialog,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Generar y Emitir Cotización Oficial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
