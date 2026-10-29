import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/services/location_service.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../families/models/student_document.dart';
import '../../families/widgets/document_preview_dialog.dart';
import '../../families/repositories/family_repository.dart';
import '../../families/screens/create_family_dialog.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';

/// Modal completo para dar de alta un nuevo colegio cliente en la plataforma EDUNEX.
///
/// Este proceso realiza el onboarding integral:
/// 1. Registra la institución educativa en la tabla `colegios`.
/// 2. Crea el usuario y credenciales del Director con rol `admin_colegio`.
/// 3. Emite un resumen con botón para copiar las credenciales de acceso para el cliente.
class CreateSchoolDialog extends StatefulWidget {
  final SchoolRepository schoolRepository;
  final ValueChanged<School>? onSchoolCreated;
  final int initialStep;

  const CreateSchoolDialog({
    super.key,
    required this.schoolRepository,
    this.onSchoolCreated,
    this.initialStep = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required SchoolRepository schoolRepository,
    ValueChanged<School>? onSchoolCreated,
    int initialStep = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateSchoolDialog(
        schoolRepository: schoolRepository,
        onSchoolCreated: onSchoolCreated,
        initialStep: initialStep,
      ),
    );
  }

  @override
  State<CreateSchoolDialog> createState() => _CreateSchoolDialogState();
}

class _CreateSchoolDialogState extends State<CreateSchoolDialog> {
  final _formKey = GlobalKey<FormState>();

  // Datos Institucionales
  final _nombreController = TextEditingController();
  final _siglasController = TextEditingController();
  final _rncController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailContactoController = TextEditingController();
  final _direccionController = TextEditingController();

  // Caso 1: RNC Persona Física vs Persona Jurídica
  String _rncType = 'juridica'; // 'juridica' (9 dígitos) | 'fisica' (11 dígitos)

  // Caso 2: Capacidad de Estudiantes Libre & Presets
  final _maxEstudiantesController = TextEditingController(text: '500');
  int _selectedMaxEstudiantes = 500;
  final List<int> _presetCapacities = [100, 250, 500, 1000, 2500];
  String _selectedStatus = 'active';

  // Caso 3: Foto/Logo Institucional con Previsualización y Geolocalización GPS
  final _logoUrlController = TextEditingController();
  String? _gpsCoordinates;

  // Caso 4: Multi-sucursales
  bool _hasBranches = false;
  final List<Map<String, TextEditingController>> _branchControllers = [];

  // Caso 2: Tarifario Escolar & Criterio Sujeto a Mejora de Pago
  final _precioInicialController = TextEditingController(text: '6500');
  final _precioPrimariaController = TextEditingController(text: '8000');
  final _precioSecundariaController = TextEditingController(text: '9500');
  final _precioMatriculaController = TextEditingController(text: '12000');
  bool _sujetoAMejoraPago = true;
  double _descuentoAnual = 10.0;
  double _descuentoSemestral = 5.0;
  double _descuentoTrimestral = 3.0;
  double _descuentoHermanos = 10.0;

  // Credenciales del Director / Administrador Escolar (Issue #18: Cédula requerida para enrolar colegio)
  final _directorNombresController = TextEditingController();
  final _directorApellidosController = TextEditingController();
  final _directorCedulaController = TextEditingController();
  final _directorEmailController = TextEditingController();
  final _directorPasswordController = TextEditingController();
  bool _obscurePassword = false;
  bool _isLocating = false;

  // Issue #18: Documentos de registro del colegio y cédula del director
  final Map<String, StudentDocument> _schoolDocuments = {
    'Cédula del Director': StudentDocument(
      id: 'doc-cedula-dir',
      tipo: 'Copia Cédula del Director',
      nombreArchivo: 'cedula_director_oficial.pdf',
      tamanoBytes: 1024 * 420,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Acreditación MINERD': StudentDocument(
      id: 'doc-minerd-acred',
      tipo: 'Acreditación MINERD / Registro',
      nombreArchivo: 'acreditacion_minerd_resolucion.pdf',
      tamanoBytes: 1024 * 1280,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
    'Registro Mercantil / RNC': StudentDocument(
      id: 'doc-onapi-rm',
      tipo: 'Registro Mercantil / RNC',
      nombreArchivo: 'registro_mercantil_dgii.pdf',
      tamanoBytes: 1024 * 850,
      fechaSubida: DateTime.now(),
      verificado: true,
    ),
  };

  bool _isLoading = false;
  int _currentStep = 0;
  School? _createdSchool;
  String? _createdDirectorEmail;
  String? _createdDirectorPassword;
  String? _createdDirectorName;
  String? _createdDirectorCedula;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.initialStep > 0) {
      if (_nombreController.text.isEmpty) _nombreController.text = 'Colegio San Agustín';
      if (_rncController.text.isEmpty) _rncController.text = '1-30-12345-1';
      if (_telefonoController.text.isEmpty) _telefonoController.text = '809-555-0101';
      if (_emailContactoController.text.isEmpty) _emailContactoController.text = 'contacto@sanagustin.edu.do';
      if (_direccionController.text.isEmpty) _direccionController.text = 'Av. 27 de Febrero #50, D.N.';
      if (_directorNombresController.text.isEmpty) _directorNombresController.text = 'Carlos';
      if (_directorApellidosController.text.isEmpty) _directorApellidosController.text = 'Gómez';
      if (_directorCedulaController.text.isEmpty) _directorCedulaController.text = '001-1827364-5';
      if (_directorEmailController.text.isEmpty) _directorEmailController.text = 'director@sanagustin.edu.do';
      if (_directorPasswordController.text.isEmpty) _directorPasswordController.text = '123456';
    }
    _nombreController.addListener(_onFormFieldChanged);
    _siglasController.addListener(_onFormFieldChanged);
    _rncController.addListener(_onFormFieldChanged);
    _telefonoController.addListener(_onFormFieldChanged);
    _emailContactoController.addListener(_onFormFieldChanged);
    _direccionController.addListener(_onFormFieldChanged);
    _maxEstudiantesController.addListener(_onFormFieldChanged);
    _directorNombresController.addListener(_onFormFieldChanged);
    _directorApellidosController.addListener(_onFormFieldChanged);
    _directorCedulaController.addListener(_onFormFieldChanged);
    _directorEmailController.addListener(_onFormFieldChanged);
    _directorPasswordController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onFormFieldChanged);
    _siglasController.removeListener(_onFormFieldChanged);
    _rncController.removeListener(_onFormFieldChanged);
    _telefonoController.removeListener(_onFormFieldChanged);
    _emailContactoController.removeListener(_onFormFieldChanged);
    _direccionController.removeListener(_onFormFieldChanged);
    _maxEstudiantesController.removeListener(_onFormFieldChanged);
    _directorNombresController.removeListener(_onFormFieldChanged);
    _directorApellidosController.removeListener(_onFormFieldChanged);
    _directorCedulaController.removeListener(_onFormFieldChanged);
    _directorEmailController.removeListener(_onFormFieldChanged);
    _directorPasswordController.removeListener(_onFormFieldChanged);

    _nombreController.dispose();
    _siglasController.dispose();
    _rncController.dispose();
    _telefonoController.dispose();
    _emailContactoController.dispose();
    _direccionController.dispose();
    _maxEstudiantesController.dispose();
    _logoUrlController.dispose();
    _precioInicialController.dispose();
    _precioPrimariaController.dispose();
    _precioSecundariaController.dispose();
    _precioMatriculaController.dispose();
    for (final branch in _branchControllers) {
      branch['nombre']?.dispose();
      branch['direccion']?.dispose();
      branch['estudiantes']?.dispose();
    }
    _directorNombresController.dispose();
    _directorApellidosController.dispose();
    _directorCedulaController.dispose();
    _directorEmailController.dispose();
    _directorPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormReadyToSubmit {
    return _nombreController.text.trim().isNotEmpty &&
           _rncController.text.trim().isNotEmpty &&
           _telefonoController.text.trim().isNotEmpty &&
           _emailContactoController.text.trim().isNotEmpty &&
           _direccionController.text.trim().isNotEmpty &&
           _maxEstudiantesController.text.trim().isNotEmpty &&
           _directorNombresController.text.trim().isNotEmpty &&
           _directorApellidosController.text.trim().isNotEmpty &&
           _directorCedulaController.text.trim().isNotEmpty &&
           _directorEmailController.text.trim().isNotEmpty &&
           _directorPasswordController.text.trim().isNotEmpty;
  }

  void _addBranch() {
    final newIndex = _branchControllers.length + 1;
    final ctrlNombre = TextEditingController(text: 'Sucursal $newIndex');
    final ctrlDireccion = TextEditingController();
    final ctrlEstudiantes = TextEditingController(text: '100');

    ctrlNombre.addListener(_onFormFieldChanged);
    ctrlDireccion.addListener(_onFormFieldChanged);
    ctrlEstudiantes.addListener(_onFormFieldChanged);

    setState(() {
      _branchControllers.add({
        'nombre': ctrlNombre,
        'direccion': ctrlDireccion,
        'estudiantes': ctrlEstudiantes,
      });
    });
  }

  void _removeBranch(int index) {
    setState(() {
      final removed = _branchControllers.removeAt(index);
      removed['nombre']?.removeListener(_onFormFieldChanged);
      removed['direccion']?.removeListener(_onFormFieldChanged);
      removed['estudiantes']?.removeListener(_onFormFieldChanged);
      removed['nombre']?.dispose();
      removed['direccion']?.dispose();
      removed['estudiantes']?.dispose();
    });
  }

  Future<void> _geolocateAddress() async {
    setState(() => _isLocating = true);
    try {
      final res = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _gpsCoordinates = res.formattedCoordinates;
        final current = _direccionController.text.trim();
        if (current.isEmpty) {
          _direccionController.text = res.isLiveGps
              ? 'Ubicación actual del plantel (GPS: ${res.formattedCoordinates})'
              : 'Av. Winston Churchill, Santo Domingo, D.N. (GPS: ${res.formattedCoordinates})';
        } else if (!current.contains('GPS:')) {
          _direccionController.text = '$current (GPS: ${res.formattedCoordinates})';
        }
      });

      if (res.isLiveGps) {
        AppToast.success(
          context,
          '📍 Ubicación GPS obtenida del navegador/dispositivo: [${res.formattedCoordinates}]',
          title: 'Geolocalización Exitosa',
        );
      } else {
        AppToast.info(
          context,
          'Coordenadas de referencia asignadas [${res.formattedCoordinates}] (${res.errorMessage ?? "Santo Domingo, D.N."}).',
          title: 'Ubicación GPS',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      AppToast.warning(
        context,
        'No se pudo consultar el sensor GPS: $e. Se asociaron coordenadas por defecto.',
        title: 'Geolocalización',
      );
    }
  }

  Future<void> _pickRealSchoolDoc(String keyName, String defaultTipo) async {
    final picked = await FileUploadService.pickRealFile();
    if (picked != null) {
      setState(() {
        _schoolDocuments[keyName] = StudentDocument(
          id: 'sdoc-${DateTime.now().millisecondsSinceEpoch}',
          tipo: defaultTipo,
          nombreArchivo: picked.name,
          tamanoBytes: picked.size,
          fechaSubida: DateTime.now(),
          verificado: true,
          urlArchivo: picked.dataUrl,
          rawBytes: picked.bytes,
        );
      });
      if (mounted) {
        AppToast.success(
          context,
          'Documento "$defaultTipo" cargado exitosamente (${(picked.size / 1024).toStringAsFixed(1)} KB)',
          title: 'Documento Cargado',
        );
      }
    }
  }

  void _previewSchoolDoc(StudentDocument doc) {
    DocumentPreviewDialog.show(
      context,
      document: doc,
      studentName: _nombreController.text.trim().isEmpty ? 'Institución Escolar' : _nombreController.text.trim(),
    );
  }

  String? _validateRnc(String? val) {
    if (val == null || val.trim().isEmpty) {
      return _rncType == 'juridica'
          ? 'El RNC es obligatorio para Persona Jurídica'
          : 'La Cédula es obligatoria para Persona Física';
    }
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (_rncType == 'juridica') {
      if (digits.length != 9) {
        return 'El RNC de Persona Jurídica debe contener 9 dígitos (ingresados: ${digits.length})';
      }
    } else {
      if (digits.length != 11) {
        return 'La Cédula de Persona Física debe contener 11 dígitos (ingresados: ${digits.length})';
      }
    }
    return null;
  }

  int get _totalBranchStudents {
    if (!_hasBranches) return 0;
    return _branchControllers.fold<int>(
      0,
      (sum, b) => sum + (int.tryParse(b['estudiantes']?.text.trim() ?? '') ?? 0),
    );
  }

  int get _grandTotalStudents {
    final mainCampus = int.tryParse(_maxEstudiantesController.text.trim()) ?? _selectedMaxEstudiantes;
    return mainCampus + _totalBranchStudents;
  }

  double _calculateSaaSFee() {
    final total = _grandTotalStudents;
    double base;
    if (total <= 250) {
      base = 4000.0;
    } else if (total <= 400) {
      base = 5500.0;
    } else if (total <= 700) {
      base = 7000.0;
    } else {
      base = 8500.0;
    }
    if (_hasBranches && _branchControllers.isNotEmpty) {
      base += base * 0.15 * _branchControllers.length;
    }
    return base;
  }

  bool _validateStep(int stepIndex) {
    if (stepIndex == 0) {
      if (_nombreController.text.trim().isEmpty) {
        _showStepError('Ingresa el Nombre Oficial de la Institución Educativa.');
        return false;
      }
      final rncDigits = _rncController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (rncDigits.isEmpty) {
        _showStepError('Ingresa el RNC Institucional para continuar.');
        return false;
      }
      final requiredLength = _rncType == 'juridica' ? 9 : 11;
      if (rncDigits.length != requiredLength) {
        _showStepError('El RNC para Persona ${_rncType == "juridica" ? "Jurídica debe tener 9" : "Física debe tener 11"} dígitos (actual: ${rncDigits.length}).');
        return false;
      }
      if (_telefonoController.text.trim().isEmpty) {
        _showStepError('Ingresa el Teléfono Principal de contacto del colegio.');
        return false;
      }
      final emailAdmin = _emailContactoController.text.trim();
      if (emailAdmin.isEmpty || !emailAdmin.contains('@') || !emailAdmin.contains('.')) {
        _showStepError('Ingresa un Email de Administración válido para contratos y alertas.');
        return false;
      }
      if (_direccionController.text.trim().isEmpty) {
        _showStepError('Ingresa o geolocaliza la Dirección Física del Plantel.');
        return false;
      }
      return true;
    }

    if (stepIndex == 1) {
      final cap = int.tryParse(_maxEstudiantesController.text.trim());
      if (cap == null || cap <= 0) {
        _showStepError('Ingresa una capacidad de estudiantes válida mayor a 0.');
        return false;
      }
      return true;
    }

    if (stepIndex == 2) {
      if (_directorNombresController.text.trim().isEmpty) {
        _showStepError('Ingresa los nombres del Director(a) General.');
        return false;
      }
      if (_directorApellidosController.text.trim().isEmpty) {
        _showStepError('Ingresa los apellidos del Director(a) General.');
        return false;
      }
      final cedulaDigits = _directorCedulaController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (cedulaDigits.length != 11) {
        _showStepError('La cédula del director debe contener 11 dígitos numéricos dominicanos.');
        return false;
      }
      final email = _directorEmailController.text.trim();
      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        _showStepError('Ingresa un correo electrónico de acceso válido para el Director.');
        return false;
      }
      if (_directorPasswordController.text.trim().length < 6) {
        _showStepError('La contraseña del director debe tener al menos 6 caracteres.');
        return false;
      }
      return true;
    }

    return true;
  }

  void _showStepError(String message) {
    AppToast.warning(
      context,
      message,
      title: 'Campo Obligatorio Pendiente',
    );
  }

  void _tryGoToStep(int targetStep) {
    if (targetStep <= _currentStep) {
      setState(() => _currentStep = targetStep);
      return;
    }
    // Para avanzar, validar el paso actual y pasos intermedios
    for (int s = _currentStep; s < targetStep; s++) {
      if (!_validateStep(s)) {
        setState(() => _currentStep = s);
        return;
      }
    }
    setState(() => _currentStep = targetStep);
  }

  Widget _buildTimelineHeader() {
    final steps = [
      {'title': 'Institución', 'subtitle': 'Datos & RNC'},
      {'title': 'Plan SaaS', 'subtitle': 'Cupo & Tarifas'},
      {'title': 'Director', 'subtitle': 'Acceso & Cédula'},
      {'title': 'Documentos', 'subtitle': 'Expediente & Alta'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: List.generate(steps.length, (stepIdx) {
          final step = steps[stepIdx];
          final isPast = stepIdx < _currentStep;
          final isCurrent = stepIdx == _currentStep;

          Color circleColor;
          Color textColor;
          Widget circleContent;

          if (isPast) {
            circleColor = AppColors.accentGreen;
            textColor = AppColors.accentGreen;
            circleContent = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
          } else if (isCurrent) {
            circleColor = AppColors.navyPrimary;
            textColor = AppColors.navyPrimary;
            circleContent = Text(
              '${stepIdx + 1}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            );
          } else {
            circleColor = const Color(0xFFCBD5E1);
            textColor = const Color(0xFF94A3B8);
            circleContent = Text(
              '${stepIdx + 1}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () => _tryGoToStep(stepIdx),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: circleContent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            step['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            step['subtitle']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: isCurrent ? AppColors.navyPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stepIdx < steps.length - 1)
                      const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      AppToast.warning(
        context,
        'Por favor completa o corrige los campos obligatorios del formulario.',
        title: 'Formulario Incompleto',
      );
      return;
    }

    for (int s = 0; s <= 2; s++) {
      if (!_validateStep(s)) {
        setState(() => _currentStep = s);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final capacity = _grandTotalStudents;
      String direccionFinal = _direccionController.text.trim();
      if (_hasBranches && _branchControllers.isNotEmpty) {
        final branchesInfo = _branchControllers
            .map((b) => '${b['nombre']?.text.trim() ?? "Sucursal"}: ${b['direccion']?.text.trim() ?? ""} (${b['estudiantes']?.text.trim() ?? "0"} alumnos)')
            .join(' | ');
        direccionFinal = direccionFinal.isNotEmpty
            ? '$direccionFinal [Sucursales: $branchesInfo]'
            : '[Sucursales: $branchesInfo]';
      }

      final result = await widget.schoolRepository.createSchoolWithDirector(
        nombre: _nombreController.text,
        siglas: _siglasController.text.isNotEmpty ? _siglasController.text : null,
        rnc: _rncController.text.isNotEmpty ? _rncController.text : null,
        telefono: _telefonoController.text.isNotEmpty ? _telefonoController.text : null,
        emailContacto: _emailContactoController.text.isNotEmpty ? _emailContactoController.text : null,
        direccion: direccionFinal.isNotEmpty ? direccionFinal : null,
        logoUrl: _logoUrlController.text.trim().isNotEmpty ? _logoUrlController.text.trim() : null,
        estadoSuscripcion: _selectedStatus,
        maxEstudiantes: capacity > 0 ? capacity : 500,
        directorEmail: _directorEmailController.text.trim(),
        directorPassword: _directorPasswordController.text.trim(),
        directorNombres: _directorNombresController.text.trim(),
        directorApellidos: _directorApellidosController.text.trim(),
        directorCedula: _directorCedulaController.text.trim(),
        precioInicial: double.tryParse(_precioInicialController.text.trim()) ?? 6500.0,
        precioPrimaria: double.tryParse(_precioPrimariaController.text.trim()) ?? 8000.0,
        precioSecundaria: double.tryParse(_precioSecundariaController.text.trim()) ?? 9500.0,
        precioMatricula: double.tryParse(_precioMatriculaController.text.trim()) ?? 12000.0,
        sujetoAMejoraPago: _sujetoAMejoraPago,
        descuentoProntoPagoAnualPct: _descuentoAnual,
        descuentoProntoPagoSemestralPct: _descuentoSemestral,
        descuentoProntoPagoTrimestralPct: _descuentoTrimestral,
        descuentoHermanosPct: _descuentoHermanos,
        documentos: _schoolDocuments.values.toList(),
      );

      final newSchool = result['school'] as School;

      // Issue #23 Caso 2: Cero familias precargadas.
      // El centro creado desde cero debe estar 100% limpio (0 familias) para que QA sea quien agregue la data.

      if (mounted) {
        setState(() {
          _createdSchool = newSchool;
          _createdDirectorEmail = _directorEmailController.text.trim();
          _createdDirectorPassword = _directorPasswordController.text.trim();
          _createdDirectorName = '${_directorNombresController.text.trim()} ${_directorApellidosController.text.trim()}'.trim();
          _createdDirectorCedula = _directorCedulaController.text.trim();
          _isLoading = false;
        });

        // Notificar callback para actualizar la lista en el dashboard del dueño
        widget.onSchoolCreated?.call(newSchool);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(
          context,
          'Error al dar de alta el colegio y director: $e',
          title: 'Error de Alta',
        );
      }
    }
  }

  Widget _buildSuccessContent(BuildContext context) {
    final school = _createdSchool!;
    final email = _createdDirectorEmail ?? '';
    final password = _createdDirectorPassword ?? '';
    final directorName = _createdDirectorName ?? 'Director';

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
                      '¡Colegio & Director Habilitados!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'La institución ha sido dada de alta y sus credenciales están listas.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.domain_rounded, color: Color(0xFF166534), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF166534)),
                          ),
                          Text(
                            'RNC: ${school.rnc ?? "N/D"} • Plan ${school.planName} (${school.maxEstudiantes} Alumnos) • Estado: ACTIVO',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.navyPrimary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Credenciales Generadas para el Director Escolar:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    Text('👤 Nombre: $directorName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('🪪 Cédula Oficial: ${_createdDirectorCedula ?? school.directorCedula ?? "001-1827364-5"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Text('📧 Correo: $email', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                    const SizedBox(height: 6),
                    Text('🔑 Contraseña: $password', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    const SizedBox(height: 6),
                    const Text('🛡️ Perfil de Acceso: Administrador de Colegio (admin_colegio)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '💡 El director ya puede ingresar al sistema utilizando estas credenciales y tendrá acceso total al colegio.',
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
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final text = '''
*Credenciales de Acceso a EDUNEX*
Colegio: ${school.nombre}
Director: $directorName
URL: https://edunexdev.netlify.app
Correo: $email
Contraseña: $password
''';
                  Clipboard.setData(ClipboardData(text: text));
                  AppToast.success(
                    context,
                    'Credenciales copiadas al portapapeles con éxito.',
                    title: 'Copiado',
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar Credenciales'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: AppColors.navyPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Entendido y Ver en Panel'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: _createdSchool != null
            ? _buildSuccessContent(context)
            : Column(
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
                          'Registrar Nuevo Colegio Cliente & Director',
                          style: TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Da de alta la institución y genera su cuenta de administrador en un solo paso.',
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

            // Línea de Tiempo / Timeline Stepper Header
            _buildTimelineHeader(),

            // Contenido Scrolleable del Formulario (Paso a Paso)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStep == 0) _buildStep1Institucion(),
                      if (_currentStep == 1) _buildStep2PlanSaaS(),
                      if (_currentStep == 2) _buildStep3Director(),
                      if (_currentStep == 3) _buildStep4Documentos(),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con Navegación Paso a Paso de la Línea de Tiempo
            _buildTimelineFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Institucion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECCIÓN 1: DATOS INSTITUCIONALES
        _buildSectionHeader(
          icon: Icons.school_rounded,
          title: '1. Datos de la Institución Educativa',
          subtitle: 'Información oficial del colegio en República Dominicana',
        ),
        const SizedBox(height: 16),

                      // CASO 3: Foto/Logo Institucional con Previsualización en Vivo
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.slateLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _logoUrlController.text.trim().isNotEmpty
                                  ? (_logoUrlController.text.trim().startsWith('data:image')
                                      ? Builder(
                                          builder: (_) {
                                            try {
                                              final commaIdx = _logoUrlController.text.indexOf(',');
                                              final b64 = _logoUrlController.text.substring(commaIdx + 1);
                                              return Image.memory(
                                                base64Decode(b64),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Colors.redAccent,
                                                  size: 26,
                                                ),
                                              );
                                            } catch (_) {
                                              return const Icon(Icons.broken_image_rounded, color: Colors.redAccent, size: 26);
                                            }
                                          },
                                        )
                                      : Image.network(
                                          _logoUrlController.text.trim(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.broken_image_rounded,
                                            color: Colors.redAccent,
                                            size: 26,
                                          ),
                                        ))
                                  : const Icon(
                                      Icons.account_balance_rounded,
                                      color: AppColors.navyPrimary,
                                      size: 30,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _logoUrlController,
                                    decoration: InputDecoration(
                                      labelText: 'Logo o Foto Oficial del Colegio',
                                      hintText: 'https://ejemplo.com/logo-colegio.png o sube un archivo',
                                      prefixIcon: const Icon(Icons.add_photo_alternate_outlined),
                                      suffixIcon: _logoUrlController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded, size: 18),
                                              onPressed: () {
                                                _logoUrlController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      ActionChip(
                                        avatar: const Icon(Icons.upload_file_rounded, size: 14, color: AppColors.navyPrimary),
                                        label: const Text('Subir Logo Real', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          final picked = await FileUploadService.pickRealFile();
                                          if (picked != null) {
                                            setState(() {
                                              _logoUrlController.text = picked.dataUrl;
                                            });
                                          }
                                        },
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.auto_awesome, size: 14, color: AppColors.electricBlue),
                                        label: const Text('Logo Predeterminado 1', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _logoUrlController.text =
                                              'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=200';
                                          setState(() {});
                                        },
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.school, size: 14, color: AppColors.accentOrange),
                                        label: const Text('Logo Predeterminado 2', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _logoUrlController.text =
                                              'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=200';
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre Oficial de la Institución *',
                          hintText: 'Ej. Colegio Bilingüe San Judas Tadeo',
                          helperText: 'Razón social o nombre comercial del colegio cliente',
                          prefixIcon: const Icon(Icons.school_rounded, color: AppColors.navyPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'El nombre del colegio es obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      // CASO 1: Selector Tipo de RNC (Persona Jurídica vs Persona Física)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.badge_outlined, size: 16, color: AppColors.navyPrimary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tipo de Registro Fiscal DGII (República Dominicana):',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: 'juridica',
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Persona Jurídica (9 dígitos)'),
                                  ),
                                  icon: Icon(Icons.business_rounded, size: 16),
                                ),
                                ButtonSegment<String>(
                                  value: 'fisica',
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Persona Física (11 dígitos)'),
                                  ),
                                  icon: Icon(Icons.person_outline_rounded, size: 16),
                                ),
                              ],
                              selected: {_rncType},
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  _rncType = newSelection.first;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _siglasController,
                              decoration: InputDecoration(
                                labelText: 'Siglas Institucionales',
                                hintText: 'Ej. SJT',
                                helperText: 'Código corto para matrículas',
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
                                labelText: _rncType == 'juridica'
                                    ? 'RNC Institucional (9 dígitos) *'
                                    : 'Cédula de Propietario (11 dígitos) *',
                                hintText: _rncType == 'juridica' ? '1-31-55443-2' : '001-1234567-8',
                                helperText: _rncType == 'juridica'
                                    ? '9 dígitos numéricos (DGII Dominicana)'
                                    : '11 dígitos numéricos de cédula',
                                prefixIcon: Icon(
                                  _rncType == 'juridica' ? Icons.business_center_outlined : Icons.perm_identity_rounded,
                                  color: AppColors.navyPrimary,
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: _validateRnc,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Teléfono Principal *',
                                hintText: '809-555-0100',
                                helperText: 'Central telefónica o WhatsApp',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty)
                                  ? 'El teléfono es obligatorio'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _emailContactoController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email de Administración *',
                                hintText: 'contacto@colegio.edu.do',
                                helperText: 'Para contratos y alertas SaaS',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'El email de administración es obligatorio';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Ingresa un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // CASO 3: Dirección Física + Botón Geolocalizar Dirección (GPS)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _direccionController,
                            decoration: InputDecoration(
                              labelText: 'Dirección Física del Plantel *',
                              hintText: 'Av. Winston Churchill #105, Santo Domingo, D.N.',
                              helperText: 'Sede principal o campus en República Dominicana',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: IconButton(
                                tooltip: 'Geolocalizar Dirección (GPS/Coordenadas)',
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.my_location_rounded, color: AppColors.electricBlue),
                                onPressed: _isLocating ? null : _geolocateAddress,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty)
                                ? 'La dirección del plantel es obligatoria'
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isLocating ? null : _geolocateAddress,
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.gps_fixed_rounded, size: 15, color: AppColors.electricBlue),
                                label: Text(
                                  _isLocating ? 'Obteniendo GPS del dispositivo...' : 'Geolocalizar Dirección (GPS/Coordenadas)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.electricBlue,
                                  side: BorderSide(color: AppColors.electricBlue.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (_gpsCoordinates != null)
                                Chip(
                                  avatar: const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accentGreen),
                                  label: Text('GPS: $_gpsCoordinates', style: const TextStyle(fontSize: 11)),
                                  backgroundColor: const Color(0xFFF0FDF4),
                                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // CASO 2: Capacidad de Estudiantes Libre & Presets
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.groups_rounded, size: 18, color: AppColors.navyPrimary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Capacidad de Estudiantes:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.electricBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    () {
                                      final count = int.tryParse(_maxEstudiantesController.text.trim()) ?? _selectedMaxEstudiantes;
                                      if (count <= 250) return 'Plan Básico (≤ 250)';
                                      if (count <= 500) return 'Plan Profesional (≤ 500)';
                                      return 'Plan Enterprise ($count Alumnos)';
                                    }(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.electricBlue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _maxEstudiantesController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: 'Número Exacto de Estudiantes *',
                                      hintText: 'Ej. 137, 345, 500, 1200...',
                                      helperText: 'Capacidad libre sin estar limitado a planes fijos',
                                      prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val);
                                      if (parsed != null && parsed > 0) {
                                        setState(() => _selectedMaxEstudiantes = parsed);
                                      }
                                    },
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Indica la capacidad';
                                      final parsed = int.tryParse(val.trim());
                                      if (parsed == null || parsed <= 0) return 'Ingresa un número mayor a 0';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedStatus,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Estado',
                                      helperText: 'Activa o Trial',
                                      prefixIcon: const Icon(Icons.verified_outlined),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'active', child: Text('Activa')),
                                      DropdownMenuItem(value: 'trial', child: Text('Trial')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedStatus = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('Opciones rápidas:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ..._presetCapacities.map((preset) {
                                  final isCurrent = _maxEstudiantesController.text == preset.toString();
                                  return ChoiceChip(
                                    label: Text('$preset alumnos'),
                                    selected: isCurrent,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedMaxEstudiantes = preset;
                                        _maxEstudiantesController.text = preset.toString();
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tarificación SaaS Escolar en Vivo (Issue #22)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.monetization_on_rounded, size: 20, color: Color(0xFF166534)),
                                SizedBox(width: 8),
                                Text(
                                  'Plan SaaS Calculado (Issue #22)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cuota Mensual (MRR):', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                                    Text(
                                      'RD\$ ${_calculateSaaSFee().toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF166534)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Facturación Anual (ARR):', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                                    Text(
                                      'RD\$ ${(_calculateSaaSFee() * 12).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF166534)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              () {
                                final count = int.tryParse(_maxEstudiantesController.text.trim()) ?? _selectedMaxEstudiantes;
                                String baseLabel;
                                if (count <= 250) {
                                  baseLabel = '100 a 250 alumnos: RD\$ 4,000 / mes';
                                } else if (count <= 400) {
                                  baseLabel = '251 a 400 alumnos: RD\$ 5,500 / mes';
                                } else {
                                  baseLabel = '450+ alumnos: RD\$ 7,000 / mes';
                                }
                                if (_hasBranches && _branchControllers.isNotEmpty) {
                                  return '• Base ($baseLabel) + 15% por cada una de las ${_branchControllers.length} sucursal(es) adicional(es).';
                                }
                                return '• Base: $baseLabel (Sede Única sin recargo).';
                              }(),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CASO 4: Soporte Multi-sucursales
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasBranches ? AppColors.electricBlue : const Color(0xFFCBD5E1),
                            width: _hasBranches ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.hub_rounded, size: 20, color: AppColors.navyPrimary),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '¿Cuenta con sucursales o recintos adicionales?',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _hasBranches,
                                  activeColor: AppColors.electricBlue,
                                  onChanged: (val) {
                                    setState(() {
                                      _hasBranches = val;
                                      if (_hasBranches && _branchControllers.isEmpty) {
                                        _addBranch();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_hasBranches) ...[
                              const Divider(height: 16),
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.electricBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.25)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.monetization_on_rounded, size: 18, color: AppColors.electricBlue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Tarifa Plan SaaS Calculada: RD\$ ${_calculateSaaSFee().toStringAsFixed(2)} / mes (${1 + _branchControllers.length} sedes)',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cálculo preciso: Sede Central (${_maxEstudiantesController.text.trim().isEmpty ? 0 : _maxEstudiantesController.text.trim()} alumnos) + ${_branchControllers.length} sucursales ($_totalBranchStudents alumnos) = $_grandTotalStudents alumnos en total.',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sucursales enroladas: ${_branchControllers.length}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slateDark),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addBranch,
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Agregar Sucursal', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navyPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...List.generate(_branchControllers.length, (idx) {
                                final branch = _branchControllers[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
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
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.apartment_rounded, size: 14, color: AppColors.navyPrimary),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Sucursal / Campus #${idx + 1}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                                              ),
                                            ],
                                          ),
                                          if (_branchControllers.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                              tooltip: 'Eliminar esta sucursal',
                                              onPressed: () => _removeBranch(idx),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: TextFormField(
                                              controller: branch['nombre'],
                                              decoration: InputDecoration(
                                                labelText: 'Nombre de la Sucursal',
                                                hintText: 'Ej. Campus Piantini / Recinto Este',
                                                isDense: true,
                                                prefixIcon: const Icon(Icons.business_rounded, size: 18),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 3,
                                            child: TextFormField(
                                              controller: branch['direccion'],
                                              decoration: InputDecoration(
                                                labelText: 'Dirección de la Sucursal',
                                                hintText: 'Ej. Calle Federico Geraldino #45',
                                                isDense: true,
                                                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: branch['estudiantes'],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Estudiantes',
                                                hintText: '100',
                                                helperText: 'Cupo de sede',
                                                isDense: true,
                                                prefixIcon: const Icon(Icons.groups_outlined, size: 18),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          const Text(
                                            'Cupo rápido:',
                                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                          ),
                                          for (final preset in [50, 100, 150, 200, 300])
                                            InkWell(
                                              onTap: () {
                                                branch['estudiantes']?.text = preset.toString();
                                              },
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: (branch['estudiantes']?.text.trim() == preset.toString())
                                                      ? AppColors.electricBlue.withValues(alpha: 0.15)
                                                      : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: (branch['estudiantes']?.text.trim() == preset.toString())
                                                        ? AppColors.electricBlue
                                                        : const Color(0xFFCBD5E1),
                                                  ),
                                                ),
                                                child: Text(
                                                  '$preset alumnos',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: (branch['estudiantes']?.text.trim() == preset.toString())
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: (branch['estudiantes']?.text.trim() == preset.toString())
                                                        ? AppColors.navyPrimary
                                                        : const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
      ],
    );
  }

  Widget _buildStep2PlanSaaS() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CASO 2: SECCIÓN DE TARIFARIO ESCOLAR & CRITERIO "SUJETO A MEJORA DE PAGO"
        _buildSectionHeader(
          icon: Icons.payments_rounded,
          title: '2. Tarifario Escolar & Criterios de Pago (Caso 2)',
          subtitle: 'Precios base de mensualidades, matrícula y acuerdos flexibles de pronto pago por familia',
        ),
        const SizedBox(height: 16),

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
                            const Text(
                              'Precios y Rangos de Mensualidad por Nivel Educativo:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _precioInicialController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Nivel Inicial (Maternal/Kínder)',
                                      prefixText: 'RD\$ ',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _precioPrimariaController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Nivel Primaria (1ro a 6to)',
                                      prefixText: 'RD\$ ',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                                    controller: _precioSecundariaController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Nivel Secundaria (1ro a 6to)',
                                      prefixText: 'RD\$ ',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _precioMatriculaController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Matrícula Anual / Inscripción',
                                      prefixText: 'RD\$ ',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 10),

                            // Criterio especial: "Sujeto a mejora de pago, por familia"
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _sujetoAMejoraPago ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _sujetoAMejoraPago ? AppColors.electricBlue : const Color(0xFFCBD5E1),
                                  width: _sujetoAMejoraPago ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.handshake_rounded, color: AppColors.navyPrimary, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Criterio Especial: Sujeto a mejora de pago, por familia',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _sujetoAMejoraPago,
                                        activeColor: AppColors.electricBlue,
                                        onChanged: (val) => setState(() => _sujetoAMejoraPago = val),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Permite registrar acuerdos flexibles si la familia paga el año, 6 meses o 3 meses por adelantado, o cuenta con múltiples hermanos en el centro.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                                  ),
                                  if (_sujetoAMejoraPago) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _buildDiscountChip('Año Adelantado: 10% desc.', Colors.green.shade800),
                                        _buildDiscountChip('6 Meses (Semestral): 5% desc.', AppColors.electricBlue),
                                        _buildDiscountChip('3 Meses (Trimestral): 3% desc.', AppColors.navyPrimary),
                                        _buildDiscountChip('2do Hermano: 10% desc.', Colors.deepPurple),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ],
    );
  }

  Widget _buildStep3Director() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECCIÓN 3: CUENTA DEL DIRECTOR
        _buildSectionHeader(
          icon: Icons.person_add_alt_1_rounded,
          title: '3. Cuenta de Acceso del Director / Administrador',
          subtitle: 'Estas serán las credenciales para que el colegio inicie sesión en EDUNEX',
        ),
        const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _directorNombresController,
                              decoration: InputDecoration(
                                labelText: 'Nombre del Director *',
                                hintText: 'Ej. Carlos',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _directorApellidosController,
                              decoration: InputDecoration(
                                labelText: 'Apellidos del Director *',
                                hintText: 'Ej. Gómez',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        key: const Key('input_director_cedula'),
                        controller: _directorCedulaController,
                        decoration: InputDecoration(
                          labelText: 'Cédula de Identidad del Director / Responsable *',
                          hintText: '001-1827364-5',
                          helperText: 'Cédula oficial dominicana del responsable legal del centro',
                          prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.navyPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'La cédula del director es obligatoria';
                          final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length != 11) {
                            return 'La cédula debe contener 11 dígitos (ingresados: ${digits.length})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _directorEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico de Acceso *',
                          hintText: 'director@colegio.edu.do',
                          helperText: 'El director usará este correo para ingresar al sistema',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.navyPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'El correo del director es obligatorio';
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(val.trim())) return 'Ingresa un formato de correo válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _directorPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña Inicial de Acceso *',
                          hintText: 'Mínimo 6 caracteres',
                          helperText: 'Contraseña con la que el director entrará por primera vez',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.navyPrimary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
      ],
    );
  }

  Widget _buildStep4Documentos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECCIÓN 4: DOCUMENTOS DE REGISTRO INSTITUCIONAL (Issue #18)
        _buildSectionHeader(
          icon: Icons.folder_special_rounded,
          title: '4. Documentos de Registro del Colegio (Issue #18)',
          subtitle: 'Carga los documentos oficiales de acreditación, registro comercial y copia de cédula del director',
        ),
        const SizedBox(height: 16),

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
                            const Text(
                              'Expediente Digital de Registro del Centro Educativo:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sube archivos reales en formato PDF o imágenes (JPG, PNG) para validar la institución.',
                              style: TextStyle(fontSize: 11, color: AppColors.slateGray),
                            ),
                            const SizedBox(height: 12),
                            ..._schoolDocuments.entries.map((entry) {
                              final keyName = entry.key;
                              final doc = entry.value;
                              final hasFile = doc.hasUploadedFile;
                              final isBaseReq = ['Cédula del Director', 'Acreditación MINERD', 'Registro Mercantil / RNC'].contains(keyName);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.navyPrimary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        doc.tipo.toLowerCase().contains('cédula') || doc.tipo.toLowerCase().contains('cedula')
                                            ? Icons.badge_rounded
                                            : Icons.description_rounded,
                                        size: 20,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            keyName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                                          ),
                                          Text(
                                            hasFile
                                                ? '${doc.nombreArchivo} • ${doc.tamanoFormateado} • Digital'
                                                : 'Sin archivo adjunto (Pendiente de cargar) • 0 B',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: hasFile ? AppColors.slateGray : Colors.amber.shade900,
                                              fontStyle: hasFile ? FontStyle.normal : FontStyle.italic,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        hasFile ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 18,
                                        color: hasFile ? AppColors.navyPrimary : Colors.black26,
                                      ),
                                      onPressed: hasFile ? () => _previewSchoolDoc(doc) : null,
                                      tooltip: hasFile ? 'Ver documento' : 'Sin archivo para visualizar',
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _pickRealSchoolDoc(keyName, doc.tipo),
                                      icon: const Icon(Icons.file_open_rounded, size: 13),
                                      label: const Text('Cargar Archivo Real', style: TextStyle(fontSize: 11)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasFile ? AppColors.navyPrimary : AppColors.electricBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: hasFile || !isBaseReq ? Colors.redAccent : Colors.black26,
                                      ),
                                      tooltip: hasFile
                                          ? 'Borrar archivo cargado'
                                          : (!isBaseReq ? 'Eliminar requisito' : 'Requisito institucional'),
                                      onPressed: (hasFile || !isBaseReq)
                                          ? () {
                                              if (hasFile) {
                                                // Limpiar el archivo para permitir volver a cargar sin borrar el requisito
                                                setState(() {
                                                  _schoolDocuments[keyName] = StudentDocument(
                                                    id: doc.id,
                                                    tipo: doc.tipo,
                                                    nombreArchivo: 'Sin archivo adjunto',
                                                    tamanoBytes: 0,
                                                    fechaSubida: DateTime.now(),
                                                    verificado: false,
                                                    urlArchivo: null,
                                                    rawBytes: null,
                                                  );
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Archivo de "$keyName" removido. Puedes cargar una nueva imagen o PDF.'),
                                                    backgroundColor: AppColors.navyPrimary,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              } else {
                                                // Documento personalizado sin archivo: remover fila
                                                setState(() {
                                                  _schoolDocuments.remove(keyName);
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Requisito "$keyName" eliminado.'),
                                                    backgroundColor: Colors.redAccent,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (_schoolDocuments.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No hay documentos adjuntos. Puedes cargar archivos usando el botón de abajo.',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final newDocType = 'Documento Institucional ${_schoolDocuments.length + 1}';
                                await _pickRealSchoolDoc(newDocType, newDocType);
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                              label: const Text('+ Agregar Documento Institucional', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navyPrimary,
                                side: const BorderSide(color: AppColors.navyPrimary),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
      ],
    );
  }

  Widget _buildTimelineFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          return Row(
            children: [
              if (_currentStep > 0)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => setState(() => _currentStep--),
                  icon: const Icon(Icons.arrow_back_rounded, size: 14),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar'),
                ),
              const Spacer(),
              if (!isNarrow) ...[
                Text(
                  'Paso ${_currentStep + 1} de 4',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentStep < 3)
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _tryGoToStep(_currentStep + 1),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('Continuar al Paso Siguiente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      if (_currentStep >= 2) ...[
                        if (_currentStep < 3) const SizedBox(width: 8),
                        Tooltip(
                          message: _isFormReadyToSubmit
                              ? 'Dar de alta institución y director'
                              : 'Completa todos los campos obligatorios del colegio y director para habilitar el alta',
                          child: ElevatedButton.icon(
                            onPressed: (_isLoading || !_isFormReadyToSubmit) ? null : _submit,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              _isLoading ? 'Habilitando...' : 'Dar de Alta Colegio y Director',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormReadyToSubmit ? AppColors.navyPrimary : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              disabledForegroundColor: const Color(0xFF94A3B8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
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

  Widget _buildDiscountChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
