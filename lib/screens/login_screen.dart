import 'package:flutter/material.dart';
import '../features/auth/models/user_role.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../core/widgets/app_toast.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController(text: 'admin@edunex.edu');
  final _passwordController = TextEditingController(text: '123456');

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  int _selectedRoleIndex = 0;

  // Personalización del Centro Educativo (Logo y Nombre institucional)
  String? _customSchoolName;
  String? _customSchoolLogoUrl;

  final List<Map<String, dynamic>> _roles = [
    {
      'role': UserRole.superadmin,
      'name': 'Dueño SaaS',
      'email': 'admin@edunex.edu',
      'icon': UserRole.superadmin.icon,
      'color': UserRole.superadmin.color,
    },
    {
      'role': UserRole.adminColegio,
      'name': 'Administrador',
      'email': '',
      'icon': UserRole.adminColegio.icon,
      'color': UserRole.adminColegio.color,
    },
    {
      'role': UserRole.docente,
      'name': 'Docente',
      'email': '',
      'icon': UserRole.docente.icon,
      'color': UserRole.docente.color,
    },
    {
      'role': UserRole.tutorFamiliar,
      'name': 'Tutor o Familia',
      'email': '',
      'icon': UserRole.tutorFamiliar.icon,
      'color': UserRole.tutorFamiliar.color,
    },
    {
      'role': UserRole.estudiante,
      'name': 'Estudiante',
      'email': '',
      'icon': UserRole.estudiante.icon,
      'color': UserRole.estudiante.color,
    },
  ];

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    setState(() {
      _selectedRoleIndex = index;
      final selectedRole = _roles[index]['role'] as UserRole;
      if (selectedRole == UserRole.superadmin) {
        _userController.text = 'admin@edunex.edu';
      } else {
        final registered = AuthRepository.getRegisteredUsersByRole(selectedRole);
        if (registered.isNotEmpty) {
          _userController.text = registered.last.email;
        } else {
          _userController.text = '';
        }
      }
    });
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedRole = _roles[_selectedRoleIndex]['role'] as UserRole;
      final profile = await AuthRepository().signInWithPassword(
        email: _userController.text.trim(),
        password: _passwordController.text,
        preferredRole: selectedRole,
      );

      if (!mounted) return;

      AppToast.success(
        context,
        '¡Bienvenido/a ${profile.nombreCompleto}! Acceso concedido como ${profile.rol.displayName}.',
        title: 'Acceso Concedido',
      );

      // Navegar al shell principal del SaaS EDUNEX
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(userProfile: profile),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e.toString().replaceAll('Exception: ', ''),
        title: 'Error de Autenticación',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Fondo decorativo con ondas y formas abstractas inspiradas en el logo
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.electricBlue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGreen.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vista adaptada para Pantallas Grandes / Web Desktop
  Widget _buildDesktopLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1080),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lado izquierdo: Banner institucional con degradado y características
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(44),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera superior izquierda
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: AppColors.cyanLight, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'EDUNEX CRM ESCOLAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Impulsa la excelencia\nde tu institución.',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'La plataforma integral de gestión académica y vinculación que une directivos, docentes, estudiantes y familias.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 3 Pilares del Logo (Conecta, Gestiona, Haz Crecer)
                    Column(
                      children: [
                        _buildValueItem(
                          icon: Icons.hub_rounded,
                          color: AppColors.electricBlue,
                          title: 'CONECTA',
                          desc: 'Comunicación en tiempo real entre directivos, docentes y familias.',
                        ),
                        const SizedBox(height: 14),
                        _buildValueItem(
                          icon: Icons.auto_graph_rounded,
                          color: AppColors.accentOrange,
                          title: 'GESTIONA',
                          desc: 'Calificaciones, matrículas, cobros y asistencia en un solo lugar.',
                        ),
                        const SizedBox(height: 14),
                        _buildValueItem(
                          icon: Icons.trending_up_rounded,
                          color: AppColors.accentGreen,
                          title: 'HAZ CRECER',
                          desc: 'Indicadores estratégicos para el crecimiento de tu centro educativo.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Tarjeta inferior de seguridad y confianza
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: AppColors.navyPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Acceso Institucional Seguro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Datos encriptados y respaldados para tu centro educativo.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lado derecho: Formulario de Login
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: _buildLoginForm(),
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Vista adaptada para Móviles y pantallas compactas
  Widget _buildMobileLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo oficial EDUNEX
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logo.jpg',
                height: 95,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackLogo();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Eslogan con puntos coloreados del logo
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'CONECTA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.slateGray,
                ),
              ),
              _buildColorDot(AppColors.electricBlue),
              const Text(
                'GESTIONA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.slateGray,
                ),
              ),
              _buildColorDot(AppColors.accentOrange),
              const Text(
                'HAZ CRECER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.slateGray,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Personalización con el logo de tu centro educativo
          _buildSchoolBrandingHeader(),

          const SizedBox(height: 16),

          // Selector de perfil/rol
          const Text(
            'Perfil de Acceso',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.slateLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: List.generate(_roles.length, (index) {
                final isSelected = _selectedRoleIndex == index;
                final role = _roles[index];
                return Expanded(
                  child: InkWell(
                    onTap: () => _onRoleChanged(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            role['icon'] as IconData,
                            size: 18,
                            color: isSelected
                                ? (role['color'] as Color)
                                : AppColors.slateGray,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.navyDark : AppColors.slateGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Campo Usuario / Correo
          const Text(
            'Usuario o Correo Institucional',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu usuario o correo';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'ej. usuario@colegio.edu',
              hintStyle: const TextStyle(color: AppColors.slateGray, fontSize: 14),
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.navyPrimary,
              ),
              filled: true,
              fillColor: AppColors.surfaceWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Campo Contraseña
          const Text(
            'Contraseña',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Ingresa tu contraseña',
              hintStyle: const TextStyle(color: AppColors.slateGray, fontSize: 14),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.navyPrimary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.slateGray,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.surfaceWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Recordarme y Olvidé contraseña
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.electricBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _rememberMe = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recordarme',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.slateDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  AppToast.info(
                    context,
                    'Por favor contacta al administrador de tu colegio para restablecer tu clave.',
                    title: 'Restablecer Clave',
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.electricBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botón Iniciar Sesión con degradado corporativo
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.cyanLight,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Pie con soporte y derechos
          Center(
            child: Text(
              '© ${DateTime.now().year} EDUNEX CRM Escolar. Todos los derechos reservados.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slateGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_rounded, color: AppColors.navyPrimary, size: 36),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(
                    text: 'EDU',
                    style: TextStyle(color: AppColors.navyDark),
                  ),
                  TextSpan(
                    text: 'NEX',
                    style: TextStyle(color: AppColors.electricBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Text(
          'CRM ESCOLAR',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            color: AppColors.slateDark,
          ),
        ),
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildValueItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolBrandingHeader() {
    if (_customSchoolName != null || _customSchoolLogoUrl != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.electricBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.electricBlue.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _customSchoolLogoUrl != null && _customSchoolLogoUrl!.isNotEmpty
                  ? Image.network(
                      _customSchoolLogoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        color: AppColors.navyPrimary,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.school_rounded,
                      color: AppColors.navyPrimary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _customSchoolName?.trim().isNotEmpty == true
                        ? _customSchoolName!
                        : 'Centro Educativo Asociado',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Acceso Institucional Personalizado',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.slateGray,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar personalización',
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slateGray),
              onPressed: () {
                setState(() {
                  _customSchoolName = null;
                  _customSchoolLogoUrl = null;
                });
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
