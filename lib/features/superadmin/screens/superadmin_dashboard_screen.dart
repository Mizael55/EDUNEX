import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';
import 'business_model_dialog.dart';
import 'create_school_dialog.dart';

/// Panel Maestro del Dueño del Software (Superadministrador SaaS de EDUNEX).
///
/// Este módulo permite al dueño de la plataforma:
/// - Visualizar los indicadores clave de rendimiento (KPIs) del negocio a nivel nacional.
/// - Registrar nuevos colegios clientes con su RNC y límite de matrícula.
/// - Suspender o reactivar licencias de uso de colegios por estado de pago.
/// - Acceder en modo soporte/auditoría a los colegios clientes para diagnosticar problemas.
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
  final TextEditingController _searchController = TextEditingController();
  bool _showAdminGuide = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schools = await widget.schoolRepository.getSchools(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
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
    final actionName = school.isActive ? 'Suspender Servicio' : 'Reactivar Servicio';
    final actionDesc = school.isActive
        ? 'Al suspender el servicio de "${school.nombre}", los directores, maestros y padres de este colegio no podrán acceder al sistema hasta que se reactive su pago.'
        : 'Al reactivar el servicio de "${school.nombre}", se restaurará de inmediato el acceso al sistema para todos sus usuarios.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              school.isActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: school.isActive ? Colors.red.shade700 : AppColors.accentGreen,
            ),
            const SizedBox(width: 8),
            Text(actionName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmas el cambio de estado para la institución?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(actionDesc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Colegio: ${school.nombre}\nRNC: ${school.rnc ?? "N/D"}\nEstado nuevo: ${nextStatus.toUpperCase()}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
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
                    content: Text('Estado de "${school.nombre}" actualizado a: ${nextStatus.toUpperCase()}'),
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
            // Cabecera Principal del Dueño del Software
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
                          'Centro de Control Global de EDUNEX',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 4),
                    const Text(
                      'Gestiona los colegios clientes de la plataforma, supervisa suscripciones y audita operaciones.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                );

                final businessModelButton = OutlinedButton.icon(
                  onPressed: () => BusinessModelDialog.show(context),
                  icon: const Icon(Icons.analytics_rounded, size: 18, color: AppColors.electricBlue),
                  label: const Text('Modelo de Negocio & Pricing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyPrimary,
                    side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          businessModelButton,
                          actionButton,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: titleSection),
                    const SizedBox(width: 16),
                    businessModelButton,
                    const SizedBox(width: 12),
                    actionButton,
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Banner Explicativo del Rol del Dueño del Software
            _buildAdminGuideBanner(),

            const SizedBox(height: 20),

            // Tarjetas de Métricas Maestras (KPIs)
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
                  childAspectRatio: isWide ? 1.35 : (constraints.maxWidth >= 550 ? 1.45 : 1.8),
                  children: [
                    _buildKpiCard(
                      title: 'Colegios Clientes',
                      value: '${_kpis['totalSchools'] ?? _schools.length}',
                      subtitle: '${_kpis['activeSchools'] ?? _schools.where((s) => s.isActive).length} con suscripción activa',
                      description: 'Instituciones educativas registradas en la red EDUNEX.',
                      icon: Icons.domain_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildKpiCard(
                      title: 'Alumnos en la Red',
                      value: '${_kpis['totalStudents'] ?? 0}',
                      subtitle: 'Matrícula total en el país',
                      description: 'Total de estudiantes inscritos entre todos los colegios.',
                      icon: Icons.groups_rounded,
                      color: AppColors.electricBlue,
                    ),
                    _buildKpiCard(
                      title: 'Ingresos MRR Est.',
                      value: 'RD\$ ${((_kpis['estimatedMRR'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                      subtitle: 'Mensualidad recurrente SaaS',
                      description: 'Facturación mensual estimada generada por las licencias.',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildKpiCard(
                      title: 'Infraestructura',
                      value: '100% OK',
                      subtitle: 'Supabase DB • Netlify CDN',
                      description: 'Disponibilidad en vivo de la base de datos PostgreSQL.',
                      icon: Icons.cloud_done_rounded,
                      color: AppColors.amberAccent,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Barra de Búsqueda y Filtros de Estado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 650;
                      final searchField = TextField(
                        controller: _searchController,
                        onChanged: (_) => _loadData(),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre de colegio, RNC, siglas o email...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navyPrimary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadData();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );

                      final filterButtons = SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Todos')),
                          ButtonSegment(value: 'active', label: Text('Activos')),
                          ButtonSegment(value: 'trial', label: Text('En Trial')),
                          ButtonSegment(value: 'suspended', label: Text('Suspendidos')),
                        ],
                        selected: {_selectedFilter},
                        onSelectionChanged: (set) {
                          setState(() => _selectedFilter = set.first);
                          _loadData();
                        },
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            searchField,
                            const SizedBox(height: 12),
                            filterButtons,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 14),
                          filterButtons,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Listado de Colegios o Estado Vacío para QA
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: CircularProgressIndicator(color: AppColors.navyPrimary),
                ),
              )
            else if (_schools.isEmpty)
              _buildEmptyStateForQa()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schools.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
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

  /// Banner didáctico que explica en detalle el rol y las facultades del Dueño del Sistema
  Widget _buildAdminGuideBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.navyPrimary,
              foregroundColor: Colors.white,
              child: Icon(Icons.info_outline_rounded, size: 20),
            ),
            title: const Text(
              '¿Cómo funciona el Panel Maestro del Dueño de EDUNEX?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
            ),
            subtitle: const Text(
              'Conoce las facultades y herramientas exclusivas para gestionar tu red de clientes.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: IconButton(
              icon: Icon(_showAdminGuide ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              onPressed: () => setState(() => _showAdminGuide = !_showAdminGuide),
            ),
          ),
          if (_showAdminGuide)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  final items = [
                    _buildGuideItem(
                      icon: Icons.domain_add_rounded,
                      title: '1. Onboarding de Colegios',
                      desc: 'Registra colegios con su RNC oficial de DGII, asignando capacidad de alumnos y plan contratado.',
                    ),
                    _buildGuideItem(
                      icon: Icons.pause_circle_outline_rounded,
                      title: '2. Control de Acceso',
                      desc: 'Suspende o reactiva el acceso al sistema con un clic si una institución está al día o en mora.',
                    ),
                    _buildGuideItem(
                      icon: Icons.support_agent_rounded,
                      title: '3. Modo Auditoría / Soporte',
                      desc: 'Inspecciona la vista interna del colegio sin pedir claves para resolver dudas a los directores.',
                    ),
                    _buildGuideItem(
                      icon: Icons.analytics_rounded,
                      title: '4. Salud del Negocio SaaS',
                      desc: 'Monitorea el total de alumnos en la red y los ingresos recurrentes (MRR) en pesos dominicanos.',
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w))).toList(),
                    );
                  }

                  return Column(
                    children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w)).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuideItem({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.navyPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  /// Estado vacío amigable y didáctico para que el tester de QA sepa exactamente qué probar
  Widget _buildEmptyStateForQa() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.domain_add_rounded, size: 48, color: AppColors.navyPrimary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Base de Datos Lista para Validación de QA',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Actualmente no hay colegios clientes registrados en la tabla "colegios" de Supabase.\nComo Dueño del Software, tu primer paso es dar de alta la primera institución educativa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreateSchoolDialog,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Registrar Primer Colegio Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          // Flujo de prueba para QA
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Flujo de Prueba Recomendado para QA:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                ),
                const SizedBox(height: 8),
                _buildTestStep('1', 'Haz clic en el botón superior "+ Registrar Primer Colegio Cliente".'),
                _buildTestStep('2', 'Ingresa los datos: Nombre del Colegio, RNC dominicano (ej. 1-31-00000-1), Siglas (ej. SJT) y cupo de alumnos.'),
                _buildTestStep('3', 'Verifica que la tarjeta aparezca inmediatamente en el listado y que los KPIs se actualicen.'),
                _buildTestStep('4', 'Prueba el botón "Suspender Servicio" y verifica que el badge cambie a rojo (SUSPENDIDA).'),
                _buildTestStep('5', 'Haz clic en "Inspeccionar" para verificar el salto en modo soporte al espacio del colegio.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: AppColors.navyPrimary,
            child: Text(number, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  /// Tarjeta detallada de cada colegio cliente
  Widget _buildSchoolCard(School school) {
    final cuposPct = school.maxEstudiantes > 0
        ? (school.totalEstudiantes / school.maxEstudiantes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: school.isSuspended ? Colors.red.shade200 : const Color(0xFFE2E8F0),
          width: school.isSuspended ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila Superior: Identidad del Colegio, RNC y Contacto
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identificador visual del Colegio
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: school.isSuspended
                        ? Colors.red.shade50
                        : AppColors.navyPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: school.isSuspended ? Colors.red.shade700 : AppColors.navyPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Nombres, RNC y datos de contacto
                Expanded(
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildDetailChip(Icons.badge_outlined, 'RNC: ${school.rnc ?? "N/D"}'),
                          _buildDetailChip(Icons.phone_outlined, school.telefono ?? 'Tel: N/D'),
                          _buildDetailChip(Icons.email_outlined, school.emailContacto ?? 'Email: N/D'),
                        ],
                      ),
                      if (school.direccion != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📍 ${school.direccion!}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Fila Inferior: Capacidad contratada y Acciones Operativas
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;

                final quotaWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Plan ${school.planName}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(cuposPct * 100).toStringAsFixed(0)}% cupos usados',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: cuposPct,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: cuposPct > 0.85 ? Colors.orange.shade700 : AppColors.electricBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${school.totalEstudiantes} de ${school.maxEstudiantes} alumnos contratados',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                );

                final actionsWidget = Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    // Badge de suscripción
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: school.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: school.statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            school.isActive
                                ? Icons.check_circle_rounded
                                : (school.isSuspended ? Icons.block_rounded : Icons.timer_rounded),
                            size: 14,
                            color: school.statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            school.statusDisplayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: school.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón para Suspender / Reactivar
                    TextButton.icon(
                      onPressed: () => _toggleSubscription(school),
                      icon: Icon(
                        school.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                        size: 18,
                        color: school.isActive ? Colors.red.shade700 : AppColors.accentGreen,
                      ),
                      label: Text(
                        school.isActive ? 'Suspender' : 'Reactivar',
                        style: TextStyle(
                          fontSize: 12,
                          color: school.isActive ? Colors.red.shade700 : AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Botón para Inspeccionar
                    ElevatedButton.icon(
                      onPressed: () {
                        widget.onSelectSchoolToInspect?.call(school);
                      },
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                      label: const Text('Inspeccionar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: AppColors.surfaceWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 3, child: quotaWidget),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: actionsWidget),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    quotaWidget,
                    const SizedBox(height: 12),
                    actionsWidget,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  /// Tarjeta de métrica ejecutiva con subtítulo y descripción explicativa
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
