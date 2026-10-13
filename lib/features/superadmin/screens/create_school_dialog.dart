import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
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
  int _selectedMaxEstudiantes = 500;
  String _selectedStatus = 'active';

  // Credenciales del Director / Administrador Escolar
  final _directorNombresController = TextEditingController(text: 'Carlos');
  final _directorApellidosController = TextEditingController(text: 'Gómez');
  final _directorEmailController = TextEditingController();
  final _directorPasswordController = TextEditingController(text: '123456');
  bool _obscurePassword = false;

  bool _isLoading = false;
  School? _createdSchool;
  String? _createdDirectorEmail;
  String? _createdDirectorPassword;
  String? _createdDirectorName;

  @override
  void dispose() {
    _nombreController.dispose();
    _siglasController.dispose();
    _rncController.dispose();
    _telefonoController.dispose();
    _emailContactoController.dispose();
    _direccionController.dispose();
    _directorNombresController.dispose();
    _directorApellidosController.dispose();
    _directorEmailController.dispose();
    _directorPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.schoolRepository.createSchoolWithDirector(
        nombre: _nombreController.text,
        siglas: _siglasController.text.isNotEmpty ? _siglasController.text : null,
        rnc: _rncController.text.isNotEmpty ? _rncController.text : null,
        telefono: _telefonoController.text.isNotEmpty ? _telefonoController.text : null,
        emailContacto: _emailContactoController.text.isNotEmpty ? _emailContactoController.text : null,
        direccion: _direccionController.text.isNotEmpty ? _direccionController.text : null,
        estadoSuscripcion: _selectedStatus,
        maxEstudiantes: _selectedMaxEstudiantes,
        directorEmail: _directorEmailController.text.trim(),
        directorPassword: _directorPasswordController.text.trim(),
        directorNombres: _directorNombresController.text.trim(),
        directorApellidos: _directorApellidosController.text.trim(),
      );

      final newSchool = result['school'] as School;

      if (mounted) {
        setState(() {
          _createdSchool = newSchool;
          _createdDirectorEmail = _directorEmailController.text.trim();
          _createdDirectorPassword = _directorPasswordController.text.trim();
          _createdDirectorName = '${_directorNombresController.text.trim()} ${_directorApellidosController.text.trim()}'.trim();
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
                                labelText: 'RNC (DGII Dominicana)',
                                hintText: 'Ej. 1-31-55443-2',
                                helperText: 'Registro fiscal de 9 u 11 dígitos',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
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

                      TextFormField(
                        controller: _direccionController,
                        decoration: InputDecoration(
                          labelText: 'Dirección Física del Plantel',
                          hintText: 'Av. Winston Churchill #105, Santo Domingo, D.N.',
                          helperText: 'Sede principal o campus en República Dominicana',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedMaxEstudiantes,
                              decoration: InputDecoration(
                                labelText: 'Capacidad de Estudiantes',
                                helperText: 'Límite según el plan SaaS contratado',
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
                                labelText: 'Estado Inicial',
                                helperText: 'Activa (pagado) o Trial (prueba)',
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

                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 16),

                      // SECCIÓN 2: CUENTA DEL DIRECTOR
                      _buildSectionHeader(
                        icon: Icons.person_add_alt_1_rounded,
                        title: '2. Cuenta de Acceso del Director / Administrador',
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
}
