import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../../families/screens/family_detail_dialog.dart';
import '../../families/screens/enroll_student_dialog.dart';
import '../../families/screens/create_family_dialog.dart';
import '../../finances/screens/record_payment_dialog.dart';
import '../../services/screens/daycare_attendance_dialog.dart';
import '../../services/screens/transport_routes_dialog.dart';
import '../../superadmin/repositories/school_repository.dart';
import '../../schools/screens/school_payment_method_screen.dart';

/// Pantalla Principal del Dashboard de EDUNEX
class DashboardOverviewScreen extends StatefulWidget {
  final FamilyRepository familyRepository;
  final VoidCallback onNavigateToFamilies;
  final String? schoolName;
  final String? colegioId;
  final VoidCallback? onReturnToSuperAdmin;
  final VoidCallback? onEditSchoolLogo;

  const DashboardOverviewScreen({
    super.key,
    required this.familyRepository,
    required this.onNavigateToFamilies,
    this.schoolName,
    this.colegioId,
    this.onReturnToSuperAdmin,
    this.onEditSchoolLogo,
  });

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  List<Family> _recentFamilies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final list = await widget.familyRepository.getFamilies(colegioId: widget.colegioId);
      if (mounted) {
        setState(() {
          _recentFamilies = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _verifyPaymentMethodBeforeEnroll() async {
    if (widget.colegioId == null) return true;
    try {
      final school = await SchoolRepository().getSchoolById(widget.colegioId!);
      if (school != null && !school.tieneMetodoPagoValido) {
        if (!mounted) return false;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 24),
                SizedBox(width: 10),
                Text('Método de Pago Requerido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Para habilitar el enrolamiento de alumnos y familias en tu centro educativo, debes registrar un método de pago o realizar el pago correspondiente en el menú lateral (Método de Pago & Suscripción).',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Método de Pago & Suscripción'),
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: Colors.white,
                        ),
                        body: SchoolPaymentMethodScreen(
                          colegioId: widget.colegioId,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.credit_card_rounded, size: 16),
                label: const Text('Configurar Método de Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
        return false;
      }
    } catch (_) {}
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.onReturnToSuperAdmin != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, color: AppColors.navyPrimary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'MODO AUDITORÍA SAAS: Inspeccionando la institución "${widget.schoolName ?? "Colegio Cliente"}"',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.onReturnToSuperAdmin,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Volver al Panel Maestro'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navyPrimary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Cabecera Moderna (Saludo dinámico, selector de ciclo escolar, barra de búsqueda y notificaciones)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panel de Control Institucional',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¡Hola, ${widget.schoolName?.split(' ').first ?? "Prof. Carlos"}! • ${widget.schoolName ?? "Colegio Bilingüe EDUNEX Piloto"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Selector de Ciclo Escolar tipo pastilla
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Ciclo Escolar', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              Text('2026-2027', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateDark)),
                            ],
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    // Barra de búsqueda global limpia
                    SizedBox(
                      width: 190,
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar global...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                          suffixText: '⌘K',
                          suffixStyle: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                    if (widget.onEditSchoolLogo != null) ...[
                      OutlinedButton.icon(
                        onPressed: widget.onEditSchoolLogo,
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                        label: const Text('Logo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyPrimary,
                          side: const BorderSide(color: AppColors.navyPrimary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    // Campana de notificaciones con dot rojo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.slateDark),
                          Positioned(
                            top: 9,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF43F5E),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Tarjetas KPI Principales Bento
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final crossAxisCount = isWide ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);
                final totalEstudiantes = _recentFamilies.fold<int>(0, (sum, f) => sum + f.estudiantes.length);
                final totalFamilias = _recentFamilies.length;
                final totalBalance = _recentFamilies.fold<double>(0.0, (sum, f) => sum + f.balancePendiente);
                
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.25 : (constraints.maxWidth >= 550 ? 1.4 : 1.9),
                  children: [
                    _buildKpiCard(
                      title: 'Asistencia General',
                      value: '94%',
                      subtitle: '94% promedio semanal',
                      icon: Icons.person_outline_rounded,
                      color: const Color(0xFF10B981),
                      progress: 0.94,
                    ),
                    _buildKpiCard(
                      title: 'Estudiantes Activos',
                      value: '$totalEstudiantes',
                      subtitle: totalEstudiantes == 0 ? 'Sin alumnos registrados' : '$totalEstudiantes matriculados',
                      icon: Icons.school_rounded,
                      color: AppColors.navyPrimary,
                      progress: (totalEstudiantes / 500).clamp(0.05, 1.0),
                    ),
                    _buildKpiCard(
                      title: 'Cuentas Familiares',
                      value: '$totalFamilias',
                      subtitle: totalFamilias == 0 ? 'Sin familias registradas' : '$totalFamilias cuentas activas',
                      icon: Icons.family_restroom_rounded,
                      color: const Color(0xFFF43F5E),
                    ),
                    _buildKpiCard(
                      title: 'Por Cobrar',
                      value: 'RD\$ ${totalBalance.toStringAsFixed(0)}',
                      subtitle: totalBalance == 0.0 ? 'Sin cuentas pendientes' : 'Balance acumulado',
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Bento Grid de 3 Columnas (Mis Clases, Tareas Recientes, Calendario & Eventos)
            LayoutBuilder(
              builder: (context, innerConstraints) {
                final isWide = innerConstraints.maxWidth >= 980;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna 1: Mis Clases (40%)
                      Expanded(
                        flex: 4,
                        child: _buildClassesCard(),
                      ),
                      const SizedBox(width: 16),
                      // Columna 2: Tareas Recientes (35%)
                      Expanded(
                        flex: 4,
                        child: _buildRecentTasksCard(),
                      ),
                      const SizedBox(width: 16),
                      // Columna 3: Calendario & Eventos (25%)
                      Expanded(
                        flex: 3,
                        child: _buildCalendarEventsCard(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildClassesCard(),
                      const SizedBox(height: 16),
                      _buildRecentTasksCard(),
                      const SizedBox(height: 16),
                      _buildCalendarEventsCard(),
                    ],
                  );
                }
              },
            ),

            if (widget.onReturnToSuperAdmin == null) ...[
              const SizedBox(height: 28),

              // Acciones Rápidas (Exclusivo para la administración del colegio, no para SuperAdmin)
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickAction(
                    key: const Key('btn_quick_enrolar_familia'),
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Enrolar Familia',
                    color: AppColors.electricBlue,
                    onTap: () async {
                      final canEnroll = await _verifyPaymentMethodBeforeEnroll();
                      if (!canEnroll || !mounted) return;
                      CreateFamilyDialog.show(
                        context,
                        repository: widget.familyRepository,
                        colegioId: widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001',
                        onFamilyCreated: (_) => _loadData(),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.school_rounded,
                    label: 'Matricular Alumno',
                    color: AppColors.navyPrimary,
                    onTap: () async {
                      final canEnroll = await _verifyPaymentMethodBeforeEnroll();
                      if (!canEnroll || !mounted) return;
                      EnrollStudentDialog.show(
                        context,
                        repository: widget.familyRepository,
                        colegioId: widget.colegioId,
                        onStudentEnrolled: (_) => _loadData(),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.receipt_long_rounded,
                    label: 'Registrar Pago',
                    color: AppColors.accentGreen,
                    onTap: () {
                      RecordPaymentDialog.show(
                        context,
                        repository: widget.familyRepository,
                        onPaymentRecorded: () => _loadData(),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.child_care_rounded,
                    label: 'Asistencia Cuido',
                    color: AppColors.electricBlue,
                    onTap: () {
                      DaycareAttendanceDialog.show(context);
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.directions_bus_rounded,
                    label: 'Rutas Transporte',
                    color: const Color(0xFFB45309),
                    onTap: () {
                      TransportRoutesDialog.show(context);
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Cuentas Familiares Recientes
            Row(
              children: [
                const Text(
                  'Cuentas Familiares Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onNavigateToFamilies,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Ver Directorio Completo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navyPrimary,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.navyPrimary),
                ),
              )
            else if (_recentFamilies.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.navyPrimary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Portal del Centro Educativo - Sin Familias Registradas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta institución educativa no cuenta aún con comunidad escolar matriculada.\nComo Administrador o Director del centro, puedes enrolar la primera familia o inicializar datos para pruebas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            CreateFamilyDialog.show(
                              context,
                              repository: widget.familyRepository,
                              colegioId: widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001',
                              onFamilyCreated: (_) => _loadData(),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('+ Enrolar Primera Familia'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            EnrollStudentDialog.show(
                              context,
                              repository: widget.familyRepository,
                              colegioId: widget.colegioId,
                              onStudentEnrolled: (_) => _loadData(),
                            );
                          },
                          icon: const Icon(Icons.school_rounded, size: 18),
                          label: const Text('+ Matricular Alumno'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navyPrimary,
                            side: const BorderSide(color: AppColors.navyPrimary),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentFamilies.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final family = _recentFamilies[index];
                  return Material(
                    color: AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () => FamilyDetailDialog.show(context, family),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.family_restroom_rounded,
                          color: AppColors.navyPrimary,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            family.nombreFamilia,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            family.codigoFamilia,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${family.estudiantes.length} ${family.estudiantes.length == 1 ? "estudiante" : "estudiantes"} • Tel: ${family.telefonoPrincipal ?? "N/D"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                family.estaAlDia
                                    ? 'AL DÍA'
                                    : 'RD\$ ${family.balancePendiente.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: family.estaAlDia
                                      ? AppColors.accentGreen
                                      : const Color(0xFFB45309),
                                ),
                              ),
                              Text(
                                family.estaAlDia ? 'Sin deuda' : 'Pendiente',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Clases',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slateDark,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: const [
              _ClassIllustrationTile(
                title: 'Matemáticas 2B',
                tags: ['Álgebra', 'Trigonometría'],
                pupilsCount: 32,
                gradientColors: [Color(0xFF818CF8), Color(0xFFC7D2FE)],
                icon: Icons.calculate_rounded,
              ),
              _ClassIllustrationTile(
                title: 'Ciencias 1A',
                tags: ['Biología', 'Laboratorio'],
                pupilsCount: 28,
                gradientColors: [Color(0xFF34D399), Color(0xFFA7F3D0)],
                icon: Icons.biotech_rounded,
              ),
              _ClassIllustrationTile(
                title: 'Historia 2B',
                tags: ['Universal', 'Épocas'],
                pupilsCount: 30,
                gradientColors: [Color(0xFFFBBF24), Color(0xFFFDE68A)],
                icon: Icons.public_rounded,
              ),
              _ClassIllustrationTile(
                title: 'Literatura 3C',
                tags: ['Lectura', 'Gramática'],
                pupilsCount: 25,
                gradientColors: [Color(0xFFFB7185), Color(0xFFFECDD3)],
                icon: Icons.menu_book_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tareas Recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slateDark,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mini Barra de Progreso Global
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avance de Entregas',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                    ),
                    Text(
                      '94% Completado',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.navyPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.94,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.navyPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filas de Alumnos y Estado
          const _StudentSubmissionTile(
            studentName: 'Carlos Ramírez',
            status: 'Entregado a tiempo',
            avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
            isGraded: false,
          ),
          const _StudentSubmissionTile(
            studentName: 'Ana Sofía Peña',
            status: 'Revisión pendiente',
            avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
            isGraded: false,
          ),
          const _StudentSubmissionTile(
            studentName: 'Marcos Ventura',
            status: 'Calificado: 98/100',
            avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
            isGraded: true,
          ),
          const _StudentSubmissionTile(
            studentName: 'Laura Castillo',
            status: 'Entregado a tiempo',
            avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
            isGraded: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarEventsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendario y Eventos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slateDark,
            ),
          ),
          const SizedBox(height: 16),

          // Mini franja de días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayChip('18', true),
              _buildDayChip('19', false),
              _buildDayChip('20', false),
              _buildDayChip('21', false),
              _buildDayChip('22', false),
              _buildDayChip('23', false),
            ],
          ),
          const SizedBox(height: 20),

          // Próximos eventos (Timeline sutil)
          _buildTimelineEvent(
            dotColor: AppColors.navyPrimary,
            title: 'Upcoming actividades',
            description: 'Donaderos de Matemática',
            time: 'En 3 horas',
          ),
          const SizedBox(height: 14),
          _buildTimelineEvent(
            dotColor: const Color(0xFFF59E0B),
            title: 'Upcoming Aprendizaje',
            description: 'Ambiente colaborativo institucional',
            time: 'Hoy 3:00 PM',
          ),
          const SizedBox(height: 14),
          _buildTimelineEvent(
            dotColor: const Color(0xFF10B981),
            title: 'Publicación de Boletines',
            description: 'Cierre del 1er periodo',
            time: 'Viernes',
          ),

          const SizedBox(height: 20),
          // Gráfico decorativo inferior de ambiente escolar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_rounded, color: AppColors.navyPrimary, size: 22),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Ciclo Lectivo Activo • 180 Días',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(String day, bool isSelected) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.navyPrimary : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        day,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTimelineEvent({
    required Color dotColor,
    required String title,
    required String description,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slateDark),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: color == AppColors.accentGreen ? const Color(0xFF15803D) : AppColors.textPrimary,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    Key? key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassIllustrationTile extends StatefulWidget {
  final String title;
  final List<String> tags;
  final int pupilsCount;
  final List<Color> gradientColors;
  final IconData icon;

  const _ClassIllustrationTile({
    required this.title,
    required this.tags,
    required this.pupilsCount,
    required this.gradientColors,
    required this.icon,
  });

  @override
  State<_ClassIllustrationTile> createState() => _ClassIllustrationTileState();
}

class _ClassIllustrationTileState extends State<_ClassIllustrationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered ? AppColors.navyPrimary.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? AppColors.navyPrimary.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
              blurRadius: _hovered ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner superior ilustrado
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, size: 28, color: Colors.white.withValues(alpha: 0.9)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slateDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${widget.pupilsCount} alumnos',
                                style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _hovered ? AppColors.navyPrimary : AppColors.navyPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _hovered ? Colors.white : AppColors.navyPrimary,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 11,
                              color: _hovered ? Colors.white : AppColors.navyPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _StudentSubmissionTile extends StatefulWidget {
  final String studentName;
  final String status;
  final String avatarUrl;
  final bool isGraded;

  const _StudentSubmissionTile({
    required this.studentName,
    required this.status,
    required this.avatarUrl,
    required this.isGraded,
  });

  @override
  State<_StudentSubmissionTile> createState() => _StudentSubmissionTileState();
}

class _StudentSubmissionTileState extends State<_StudentSubmissionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? AppColors.navyPrimary.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
              child: Text(
                widget.studentName[0],
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.slateDark),
                  ),
                  Text(
                    widget.status,
                    style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isGraded ? const Color(0xFFF1F5F9) : AppColors.navyPrimary,
                foregroundColor: widget.isGraded ? AppColors.textSecondary : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
              child: Text(
                widget.isGraded ? 'Ver' : 'Calificar',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
