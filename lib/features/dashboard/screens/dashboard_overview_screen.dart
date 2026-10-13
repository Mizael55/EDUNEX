import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../../families/screens/family_detail_dialog.dart';

/// Pantalla Principal del Dashboard de EDUNEX
class DashboardOverviewScreen extends StatefulWidget {
  final FamilyRepository familyRepository;
  final VoidCallback onNavigateToFamilies;

  const DashboardOverviewScreen({
    super.key,
    required this.familyRepository,
    required this.onNavigateToFamilies,
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
      final list = await widget.familyRepository.getFamilies();
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
                        'Colegio Bilingüe EDUNEX Piloto • Período Escolar 2026',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
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

            const SizedBox(height: 24),

            // Tarjetas KPI Principales
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final crossAxisCount = isWide ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);
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
                      value: '342',
                      subtitle: '+14 nuevos este ciclo',
                      icon: Icons.school_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildKpiCard(
                      title: 'Cuentas Familiares',
                      value: '186',
                      subtitle: '98% con tutor principal verificado',
                      icon: Icons.family_restroom_rounded,
                      color: AppColors.electricBlue,
                    ),
                    _buildKpiCard(
                      title: 'Cobranza del Mes',
                      value: 'RD\$ 1.28M',
                      subtitle: '91.4% de recaudación al día',
                      icon: Icons.monetization_on_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildKpiCard(
                      title: 'Servicios Activos',
                      value: '52',
                      subtitle: '38 en Cuido • 14 en Transporte',
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
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Matricular Alumno',
                  color: AppColors.navyPrimary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abriendo asistente de matrícula escolar'),
                        backgroundColor: AppColors.navyPrimary,
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'Registrar Pago',
                  color: AppColors.accentGreen,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abriendo caja para registro de cobros'),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.child_care_rounded,
                  label: 'Asistencia Cuido',
                  color: AppColors.electricBlue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abriendo control de asistencia en cuido vespertino'),
                        backgroundColor: AppColors.electricBlue,
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.directions_bus_rounded,
                  label: 'Rutas Transporte',
                  color: const Color(0xFFB45309),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abriendo monitoreo de rutas de transporte escolar'),
                        backgroundColor: Color(0xFFB45309),
                      ),
                    );
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
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
