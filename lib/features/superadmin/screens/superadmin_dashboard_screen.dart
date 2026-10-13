import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';
import 'create_school_dialog.dart';

/// Panel Maestro del Dueño del Software (Superadministrador SaaS)
class SuperAdminDashboardScreen extends StatefulWidget {
  final SchoolRepository schoolRepository;
  final ValueChanged<School>? onSelectSchoolToInspect;

  const SuperAdminDashboardScreen({
    super.key,
    required this.schoolRepository,
    this.onSelectSchoolToInspect,
  });

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  List<School> _schools = [];
  Map<String, dynamic> _kpis = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schools = await widget.schoolRepository.getSchools(
        statusFilter: _selectedFilter,
      );
      final kpis = await widget.schoolRepository.getSaaSMasterKpis();
      if (mounted) {
        setState(() {
          _schools = schools;
          _kpis = kpis;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCreateSchoolDialog() {
    CreateSchoolDialog.show(
      context,
      schoolRepository: widget.schoolRepository,
      onSchoolCreated: (newSchool) {
        _loadData();
      },
    );
  }

  void _toggleSubscription(School school) {
    final nextStatus = school.isActive ? 'suspended' : 'active';
    final actionName = school.isActive ? 'Suspender' : 'Reactivar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionName Suscripción'),
        content: Text(
          '¿Estás seguro de que deseas cambiar el estado de "${school.nombre}" a "$nextStatus"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              await widget.schoolRepository.updateSubscriptionStatus(school.id, nextStatus);
              _loadData();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Suscripción actualizada a $nextStatus'),
                    backgroundColor: AppColors.navyPrimary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: school.isActive ? Colors.red.shade700 : AppColors.accentGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(actionName),
          ),
        ],
      ),
    );
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
            // Cabecera del Dueño del Software
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 750;
                final titleSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.amberAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PANEL MAESTRO SAAS',
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Text(
                          'Control Global de la Plataforma EDUNEX',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Directorio de Colegios & Métricas del Negocio',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ],
                );

                final actionButton = ElevatedButton.icon(
                  onPressed: _openCreateSchoolDialog,
                  icon: const Icon(Icons.domain_add_rounded, size: 20),
                  label: const Text('+ Nuevo Colegio Cliente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: AppColors.surfaceWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleSection,
                      const SizedBox(height: 14),
                      actionButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: titleSection),
                    const SizedBox(width: 16),
                    actionButton,
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Master KPIs del SaaS
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
                  childAspectRatio: isWide ? 1.35 : (constraints.maxWidth >= 550 ? 1.5 : 1.9),
                  children: [
                    _buildKpiCard(
                      title: 'Colegios Clientes',
                      value: '${_kpis['totalSchools'] ?? 0}',
                      subtitle: '${_kpis['activeSchools'] ?? 0} con suscripción activa',
                      icon: Icons.domain_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildKpiCard(
                      title: 'Alumnos en la Red',
                      value: '${_kpis['totalStudents'] ?? 0}',
                      subtitle: 'Matriculados en los colegios',
                      icon: Icons.groups_rounded,
                      color: AppColors.electricBlue,
                    ),
                    _buildKpiCard(
                      title: 'Ingresos MRR Est.',
                      value: 'RD\$ ${((_kpis['estimatedMRR'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                      subtitle: 'Mensualidad recurrente SaaS',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildKpiCard(
                      title: 'Infraestructura',
                      value: '100% OK',
                      subtitle: 'Supabase DB • Netlify CDN',
                      icon: Icons.cloud_done_rounded,
                      color: AppColors.amberAccent,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Filtros y Título de Colegios
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;
                const titleText = Text(
                  'Instituciones Educativas Clientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                );

                final filterButtons = SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Todos')),
                    ButtonSegment(value: 'active', label: Text('Activos')),
                    ButtonSegment(value: 'trial', label: Text('En Trial')),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (set) {
                    setState(() => _selectedFilter = set.first);
                    _loadData();
                  },
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleText,
                      const SizedBox(height: 10),
                      filterButtons,
                    ],
                  );
                }

                return Row(
                  children: [
                    const Expanded(child: titleText),
                    const SizedBox(width: 12),
                    filterButtons,
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.navyPrimary),
                ),
              )
            else if (_schools.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      const Icon(Icons.domain_disabled_rounded, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay colegios registrados con este filtro.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _openCreateSchoolDialog,
                        child: const Text('Registrar Primer Colegio'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schools.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final school = _schools[index];
                  return _buildSchoolCard(school);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(School school) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icono / Identificador del Colegio
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.navyPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Información Principal
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (school.siglas != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            school.siglas!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          school.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RNC: ${school.rnc ?? "N/D"} • Tel: ${school.telefono ?? "N/D"} • Email: ${school.emailContacto ?? "N/D"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (school.direccion != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      school.direccion!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            // Plan y Capacidad de Alumnos
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.planName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: school.maxEstudiantes > 0
                        ? (school.totalEstudiantes / school.maxEstudiantes).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: AppColors.electricBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${school.totalEstudiantes} de ${school.maxEstudiantes} cupos usados',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Estado de Suscripción & Botón de Acción
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: school.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: school.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    school.statusDisplayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: school.statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        school.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                        color: school.isActive ? Colors.red.shade700 : AppColors.accentGreen,
                        size: 22,
                      ),
                      tooltip: school.isActive ? 'Suspender Servicio' : 'Activar Servicio',
                      onPressed: () => _toggleSubscription(school),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        widget.onSelectSchoolToInspect?.call(school);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Accediendo al espacio de "${school.nombre}" en modo soporte'),
                            backgroundColor: AppColors.navyPrimary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: AppColors.surfaceWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Inspeccionar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
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
}
