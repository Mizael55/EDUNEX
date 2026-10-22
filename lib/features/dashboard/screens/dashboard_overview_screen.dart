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

            // Cabecera de bienvenida
            Row(
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
                        '${widget.schoolName ?? "Colegio Bilingüe EDUNEX Piloto"} • Período Escolar 2026',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onEditSchoolLogo != null) ...[
                      OutlinedButton.icon(
                        onPressed: widget.onEditSchoolLogo,
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                        label: const Text('Personalizar Logo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyPrimary,
                          side: const BorderSide(color: AppColors.navyPrimary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Sistema Operativo & Sincronizado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tarjetas KPI Principales
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
                  childAspectRatio: isWide ? 1.2 : (constraints.maxWidth >= 550 ? 1.4 : 1.9),
                  children: [
                    _buildKpiCard(
                      title: 'Estudiantes Activos',
                      value: '$totalEstudiantes',
                      subtitle: totalEstudiantes == 0 ? 'Sin alumnos registrados' : '$totalEstudiantes matriculados',
                      icon: Icons.school_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildKpiCard(
                      title: 'Cuentas Familiares',
                      value: '$totalFamilias',
                      subtitle: totalFamilias == 0 ? 'Sin familias registradas' : '$totalFamilias cuentas activas',
                      icon: Icons.family_restroom_rounded,
                      color: AppColors.electricBlue,
                    ),
                    _buildKpiCard(
                      title: 'Por Cobrar',
                      value: 'RD\$ ${totalBalance.toStringAsFixed(2)}',
                      subtitle: totalBalance == 0.0 ? 'Sin cuentas pendientes' : 'Balance acumulado',
                      icon: Icons.monetization_on_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildKpiCard(
                      title: 'Servicios Activos',
                      value: '0',
                      subtitle: 'Cuido y Transporte escolar',
                      icon: Icons.alt_route_rounded,
                      color: AppColors.amberAccent,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Acciones Rápidas
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
                  onTap: () {
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
                  onTap: () {
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
                        TextButton.icon(
                          onPressed: () async {
                            final schoolId = widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001';
                            final schoolName = widget.schoolName ?? 'Colegio Cliente';
                            await FamilyRepository.seedInitialFamiliesForSchool(
                              schoolId: schoolId,
                              schoolName: schoolName,
                            );
                            _loadData();
                          },
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text('Cargar Comunidad de Prueba'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color == AppColors.accentGreen ? const Color(0xFF15803D) : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
