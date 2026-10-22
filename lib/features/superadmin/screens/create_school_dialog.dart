import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../theme/app_colors.dart';
import '../../families/models/student_document.dart';
import '../../families/widgets/document_preview_dialog.dart';
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
  final _directorNombresController = TextEditingController(text: 'Carlos');
  final _directorApellidosController = TextEditingController(text: 'Gómez');
  final _directorCedulaController = TextEditingController(text: '001-1827364-5');
  final _directorEmailController = TextEditingController();
  final _directorPasswordController = TextEditingController(text: '123456');
  bool _obscurePassword = false;

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
  School? _createdSchool;
  String? _createdDirectorEmail;
  String? _createdDirectorPassword;
  String? _createdDirectorName;
  String? _createdDirectorCedula;

  @override
  void dispose() {
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
    }
    _directorNombresController.dispose();
    _directorApellidosController.dispose();
    _directorCedulaController.dispose();
    _directorEmailController.dispose();
    _directorPasswordController.dispose();
    super.dispose();
  }

  void _addBranch() {
    setState(() {
      _branchControllers.add({
        'nombre': TextEditingController(text: 'Sucursal ${_branchControllers.length + 1}'),
        'direccion': TextEditingController(),
      });
    });
  }

  void _removeBranch(int index) {
    setState(() {
      final removed = _branchControllers.removeAt(index);
      removed['nombre']?.dispose();
      removed['direccion']?.dispose();
    });
  }

  void _geolocateAddress() {
    const lat = 18.4861;
    const lng = -69.9312;
    setState(() {
      _gpsCoordinates = '$lat, $lng';
      final current = _direccionController.text.trim();
      if (current.isEmpty) {
        _direccionController.text = 'Av. Winston Churchill, Santo Domingo, D.N. (GPS: $lat, $lng)';
      } else if (!current.contains('GPS:')) {
        _direccionController.text = '$current (GPS: $lat, $lng)';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.navyPrimary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.my_location_rounded, color: AppColors.cyanLight),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '📍 Coordenadas GPS asociadas exitosamente: [18.4861, -69.9312]',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
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
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento "$defaultTipo" cargado exitosamente (${(picked.size / 1024).toStringAsFixed(1)} KB)'),
            backgroundColor: AppColors.navyPrimary,
            duration: const Duration(seconds: 2),
          ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final capacity = int.tryParse(_maxEstudiantesController.text.trim()) ?? _selectedMaxEstudiantes;
      String direccionFinal = _direccionController.text.trim();
      if (_hasBranches && _branchControllers.isNotEmpty) {
        final branchesInfo = _branchControllers
            .map((b) => '${b['nombre']?.text.trim() ?? "Sucursal"}: ${b['direccion']?.text.trim() ?? ""}')
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
      );

      final newSchool = result['school'] as School;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Error al dar de alta el colegio y director: $e'),
          ),
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
                        Text(
                          'Credenciales Generadas para el Director Escolar:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Credenciales copiadas al portapapeles.'),
                      backgroundColor: AppColors.navyPrimary,
                    ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

            // Contenido Scrolleable del Formulario
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
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
                                  ? Image.network(
                                      _logoUrlController.text.trim(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image_rounded,
                                        color: Colors.redAccent,
                                        size: 26,
                                      ),
                                    )
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
                                      labelText: 'Logo o Foto del Colegio (URL)',
                                      hintText: 'https://ejemplo.com/logo-colegio.png',
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
                                    children: [
                                      ActionChip(
                                        avatar: const Icon(Icons.auto_awesome, size: 14, color: AppColors.electricBlue),
                                        label: const Text('Usar Logo Demo 1', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _logoUrlController.text =
                                              'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=200';
                                          setState(() {});
                                        },
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.school, size: 14, color: AppColors.accentOrange),
                                        label: const Text('Usar Logo Demo 2', style: TextStyle(fontSize: 11)),
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
                              decoration: InputDecoration(
                                labelText: 'Teléfono Principal',
                                hintText: '809-555-0100',
                                helperText: 'Central telefónica o WhatsApp',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _emailContactoController,
                              decoration: InputDecoration(
                                labelText: 'Email de Administración',
                                hintText: 'contacto@colegio.edu.do',
                                helperText: 'Para contratos y alertas SaaS',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
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
                              labelText: 'Dirección Física del Plantel',
                              hintText: 'Av. Winston Churchill #105, Santo Domingo, D.N.',
                              helperText: 'Sede principal o campus en República Dominicana',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              suffixIcon: IconButton(
                                tooltip: 'Geolocalizar Dirección (GPS/Coordenadas)',
                                icon: const Icon(Icons.my_location_rounded, color: AppColors.electricBlue),
                                onPressed: _geolocateAddress,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _geolocateAddress,
                                icon: const Icon(Icons.gps_fixed_rounded, size: 15, color: AppColors.electricBlue),
                                label: const Text('Geolocalizar Dirección (GPS/Coordenadas)', style: TextStyle(fontSize: 12)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.electricBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.electricBlue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tarifa Modelo EDUNEX: ${_branchControllers.isEmpty ? "RD\$ 7,000 / mes (1 sucursal base)" : (_branchControllers.length == 1 ? "RD\$ 10,500 / mes (2 sucursales)" : "RD\$ 14,000 / mes (${1 + _branchControllers.length} sucursales)")}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                                      ),
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
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Sucursal / Campus #${idx + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                                          ),
                                          if (_branchControllers.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                              onPressed: () => _removeBranch(idx),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: branch['nombre'],
                                              decoration: InputDecoration(
                                                labelText: 'Nombre de la Sucursal',
                                                hintText: 'Ej. Campus Piantini / Recinto Este',
                                                isDense: true,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: branch['direccion'],
                                              decoration: InputDecoration(
                                                labelText: 'Dirección de la Sucursal',
                                                hintText: 'Ej. Calle Federico Geraldino #45',
                                                isDense: true,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 16),

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

                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 16),

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
                                labelText: 'Apellidos del Director',
                                hintText: 'Ej. Gómez',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
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

                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 16),

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
                                            '${doc.nombreArchivo} • ${doc.tamanoFormateado} • Digital',
                                            style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.navyPrimary),
                                      onPressed: () => _previewSchoolDoc(doc),
                                      tooltip: 'Ver documento',
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _pickRealSchoolDoc(keyName, doc.tipo),
                                      icon: const Icon(Icons.file_open_rounded, size: 13),
                                      label: const Text('Cargar Archivo Real', style: TextStyle(fontSize: 11)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.electricBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
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
                    label: Text(_isLoading ? 'Habilitando Colegio...' : 'Dar de Alta Colegio y Director'),
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
