import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../repositories/family_repository.dart';

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

  // Expediente escolar y documentos físicos (Caso 1)
  bool fotoAdjunta = true;
  bool actaNacimientoAdjunta = true;
  bool certificadoNotasAdjunto = true;
  bool cartaSaldoConductaAdjunta = true;

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

  final List<String> _parentescos = ['Padre', 'Madre', 'Tutor Legal', 'Abuelo / Abuela', 'Tío / Tía'];
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
    for (final s in _students) {
      s.dispose();
    }
    super.dispose();
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
            criteriosEvaluados: {
              'Evaluación Admisión': draft.evaluacionAdmision,
              'Entrevista Psicología': draft.entrevistaPsicologica,
            },
            activo: true,
          ),
        );
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
        balanceInicial: _subtotalMatricula, // Saldo inicial correspondiente a matrícula
        multipleStudents: studentsList,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
                const SizedBox(height: 12),
                const Text('Documentos Físicos del Tutor Entregados:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildDocCheckbox('Carta de Trabajo / Certificación Laboral', _cartaTrabajoAdjunta, (v) => setState(() => _cartaTrabajoAdjunta = v)),
                const SizedBox(height: 4),
                _buildDocCheckbox('Estados Financieros / Comprobante de Ingresos', _estadosFinancierosAdjuntos, (v) => setState(() => _estadosFinancierosAdjuntos = v)),
                const SizedBox(height: 4),
                _buildDocCheckbox('Copia Física de Cédula de Identidad', _copiaCedulaAdjunta, (v) => setState(() => _copiaCedulaAdjunta = v)),
              ],
            ),
          ),
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
                        const SizedBox(height: 10),
                        const Text('Documentos del Expediente Escolar Entregados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 16,
                          children: [
                            _buildDocCheckbox('Foto del Alumno', student.fotoAdjunta, (v) => setState(() => student.fotoAdjunta = v)),
                            _buildDocCheckbox('Acta de Nacimiento', student.actaNacimientoAdjunta, (v) => setState(() => student.actaNacimientoAdjunta = v)),
                            _buildDocCheckbox('Certificado de Notas', student.certificadoNotasAdjunto, (v) => setState(() => student.certificadoNotasAdjunto = v)),
                            _buildDocCheckbox('Carta de Saldo / Conducta', student.cartaSaldoConductaAdjunta, (v) => setState(() => student.cartaSaldoConductaAdjunta = v)),
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
