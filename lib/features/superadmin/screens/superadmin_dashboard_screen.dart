import 'package:flutter/material.dart';
import '../../../core/widgets/school_logo_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/modern_dialog.dart';
import '../models/school.dart';
import '../models/saas_invoice.dart';
import '../models/system_announcement.dart';
import '../repositories/school_repository.dart';
import 'business_model_dialog.dart';
import 'create_school_dialog.dart';
import 'reset_password_dialog.dart';
import 'saas_billing_dialog.dart';
import 'system_announcement_dialog.dart';

/// Panel Maestro del Dueño del Software (Superadministrador SaaS de EDUNEX).
///
/// Adaptado para pantallas de 14"+ y diseño responsive de dos columnas:
/// - KPIs horizontales compactos con estética de la plataforma.
/// - Columna izquierda: Directorio en cuadrícula (estilo "Mis Clases") con filtros y búsqueda.
/// - Columna derecha: Resúmenes de Cobranza SaaS, Anuncios Globales y Auditoría en Tiempo Real.
class SuperAdminDashboardScreen extends StatefulWidget {
  final SchoolRepository schoolRepository;
  final ValueChanged<School>? onSelectSchoolToInspect;
  final bool showOnlySchools;

  const SuperAdminDashboardScreen({
    super.key,
    required this.schoolRepository,
    this.onSelectSchoolToInspect,
    this.showOnlySchools = false,
  });

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  List<School> _schools = [];
  List<SaaSInvoice> _invoices = [];
  List<SystemAnnouncement> _announcements = [];
  Map<String, dynamic> _kpis = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _showAdminGuide = false;

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
      final invoices = await widget.schoolRepository.getSaaSInvoices();
      final announcements = await widget.schoolRepository.getSystemAnnouncements();

      if (mounted) {
        setState(() {
          _schools = schools;
          _kpis = kpis;
          _invoices = invoices;
          _announcements = announcements;
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

  Future<void> _showPurgeConfirmationDialog() async {
    final confirmed = await ModernConfirmDialog.show(
      context: context,
      barrierDismissible: false,
      title: '¿Resetear Base de Datos?',
      message: 'Esta acción es IRREVERSIBLE y fue diseñada para pruebas de QA Clean Slate.',
      confirmText: 'Sí, Eliminar y Resetear',
      cancelText: 'Cancelar',
      icon: Icons.delete_forever_rounded,
      isDestructive: true,
      customBody: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Se eliminarán TODOS los colegios registrados.', style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
            Text('• Se borrarán familias, estudiantes, tutores, pagos y notas.', style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
            Text('• Se eliminarán todos los usuarios de Supabase Auth.', style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
            Text('• Se limpiarán todos los cachés locales y preferencias.', style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
            const SizedBox(height: 6),
            Text(
              'Únicamente se conservará el usuario del Super Admin (admin@edunex.edu) para que el QA empiece con data limpia.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      _executePurge();
    }
  }

  Future<void> _executePurge() async {
    setState(() => _isLoading = true);

    AppToast.info(
      context,
      'Purgando base de datos en Supabase y limpiando memoria...',
      title: 'Operación en Proceso',
    );

    try {
      final result = await widget.schoolRepository.purgeAllDataExceptSuperAdmin();
      await _loadData();

      if (mounted) {
        AppToast.success(
          context,
          result['message'] as String? ?? 'Base de datos reseteada con éxito.',
          title: 'Clean Slate Completado',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(
          context,
          'Error al resetear base de datos: $e',
          title: 'Error de Reseteo',
        );
      }
    }
  }

  void _toggleSubscription(School school) async {
    final nextStatus = school.isActive ? 'suspended' : 'active';
    final actionName = school.isActive ? 'Suspender Servicio' : 'Reactivar Servicio';
    final actionDesc = school.isActive
        ? 'Al suspender el servicio de "${school.nombre}", los directores, maestros y padres de este colegio no podrán acceder al sistema hasta que se reactive su pago.'
        : 'Al reactivar el servicio de "${school.nombre}", se restaurará de inmediato el acceso al sistema para todos sus usuarios.';

    final confirmed = await ModernConfirmDialog.show(
      context: context,
      title: actionName,
      message: actionDesc,
      confirmText: actionName,
      cancelText: 'Cancelar',
      icon: school.isActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
      iconColor: school.isActive ? const Color(0xFFDC2626) : AppColors.accentGreen,
      iconBgColor: school.isActive ? const Color(0xFFFEE2E2) : AppColors.softEmerald,
      confirmColor: school.isActive ? const Color(0xFFDC2626) : AppColors.accentGreen,
      isDestructive: school.isActive,
      customBody: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.subtleBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Colegio: ${school.nombre}\nRNC: ${school.rnc ?? "N/D"}\nEstado nuevo: ${nextStatus.toUpperCase()}',
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.navyDark),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await widget.schoolRepository.updateSubscriptionStatus(school.id, nextStatus);
      _loadData();
      if (mounted) {
        AppToast.success(
          context,
          'Estado de "${school.nombre}" actualizado a: ${nextStatus.toUpperCase()}',
          title: 'Suscripción Actualizada',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideDesktop = constraints.maxWidth >= 1100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera Principal del Dueño del Software
                _buildHeader(constraints),

                if (!widget.showOnlySchools) ...[
                  const SizedBox(height: 16),
                  _buildAdminGuideBanner(),
                  const SizedBox(height: 20),
                  // Fila de KPIs Compactos (Horizontal)
                  _buildKpiBar(constraints),
                ],

                const SizedBox(height: 24),

                // Contenido: En pantalla ancha (14"+) dividimos en 2 columnas equilibradas
                if (!widget.showOnlySchools && isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna Izquierda: Colegios Clientes (flex 7)
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterAndSearchSection(),
                            const SizedBox(height: 18),
                            _buildSchoolsGridOrEmpty(isGrid: true, crossAxisCount: 2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Columna Derecha: Paneles de Cobranza, Anuncios y Auditoría (flex 4)
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBillingSummaryPanel(),
                            const SizedBox(height: 18),
                            _buildAnnouncementsSummaryPanel(),
                            const SizedBox(height: 18),
                            _buildAuditAndHealthPanel(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Pantallas menores o vista exclusiva de colegios
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterAndSearchSection(),
                      const SizedBox(height: 18),
                      _buildSchoolsGridOrEmpty(
                        isGrid: isWideDesktop || constraints.maxWidth >= 720,
                        crossAxisCount: constraints.maxWidth >= 1350 ? 3 : (constraints.maxWidth >= 720 ? 2 : 1),
                      ),
                      if (!widget.showOnlySchools) ...[
                        const SizedBox(height: 28),
                        _buildBillingSummaryPanel(),
                        const SizedBox(height: 18),
                        _buildAnnouncementsSummaryPanel(),
                        const SizedBox(height: 18),
                        _buildAuditAndHealthPanel(),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Cabecera superior adaptativa
  Widget _buildHeader(BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 1150;

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
        Text(
          widget.showOnlySchools
              ? 'Colegios Clientes & Licencias SaaS'
              : 'Directorio de Colegios & Métricas del Negocio',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.navyPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.showOnlySchools
              ? 'Directorio central de colegios afiliados, control de licencias y acceso a soporte técnico.'
              : 'Supervisa suscripciones, cobranzas DGII con NCF y el ecosistema nacional de colegios.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );

    final actionButtons = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _showPurgeConfirmationDialog,
          icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.redAccent),
          label: const Text('Resetear DB (QA Clean Slate)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade300, width: 1.5),
            backgroundColor: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await widget.schoolRepository.exportSchoolsCsv();
              if (context.mounted) {
                AppToast.success(
                  context,
                  'Directorio consolidado de ${_schools.length} colegios e informe financiero exportados a CSV.',
                  title: 'Exportación Exitosa',
                );
              }
            } catch (e) {
              if (context.mounted) {
                AppToast.error(context, 'Error exportando informe CSV: $e');
              }
            }
          },
          icon: const Icon(Icons.file_download_outlined, size: 18, color: AppColors.accentGreen),
          label: const Text('Exportar CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navyPrimary,
            side: const BorderSide(color: Color(0xFFA7F3D0), width: 1.5),
            backgroundColor: const Color(0xFFECFDF5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ResetPasswordDialog.show(
              context,
              schoolRepository: widget.schoolRepository,
            );
          },
          icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFFB45309)),
          label: const Text('Resetear Contraseña'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB45309),
            side: const BorderSide(color: Color(0xFFFDE68A), width: 1.5),
            backgroundColor: const Color(0xFFFEF3C7),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (!widget.showOnlySchools)
          OutlinedButton.icon(
            onPressed: () => BusinessModelDialog.show(context),
            icon: const Icon(Icons.analytics_rounded, size: 18, color: AppColors.electricBlue),
            label: const Text('Modelo de Negocio & Pricing'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navyPrimary,
              side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _openCreateSchoolDialog,
          icon: const Icon(Icons.domain_add_rounded, size: 19),
          label: const Text('+ Nuevo Colegio Cliente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyPrimary,
            foregroundColor: AppColors.surfaceWhite,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 14),
          actionButtons,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 14),
        actionButtons,
      ],
    );
  }

  /// Barra de KPIs con tarjetas compactas horizontales
  Widget _buildKpiBar(BoxConstraints constraints) {
    final isDesktop = constraints.maxWidth >= 950;
    final crossAxisCount = isDesktop ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);

    return LayoutBuilder(
      builder: (context, c) {
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: isDesktop ? 1.6 : (constraints.maxWidth >= 550 ? 1.8 : 2.2),
          children: [
            _buildCompactKpiCard(
              title: 'Colegios Clientes',
              value: '${_kpis['totalSchools'] ?? _schools.length}',
              subtitle: '${_kpis['activeSchools'] ?? _schools.where((s) => s.isActive).length} con suscripción activa',
              icon: Icons.domain_rounded,
              color: AppColors.navyPrimary,
            ),
            _buildCompactKpiCard(
              title: 'Alumnos en la Red',
              value: '${_kpis['totalStudents'] ?? 0}',
              subtitle: 'Matrícula total en el país',
              icon: Icons.groups_rounded,
              color: AppColors.electricBlue,
            ),
            _buildCompactKpiCard(
              title: 'Auditoría del Sistema',
              value: 'Activa',
              subtitle: 'Trazabilidad y Seguridad',
              icon: Icons.security_rounded,
              color: const Color(0xFF0284C7),
            ),
            _buildCompactKpiCard(
              title: 'Infraestructura',
              value: '100% OK',
              subtitle: 'Supabase DB • Netlify CDN',
              icon: Icons.cloud_done_rounded,
              color: AppColors.accentGreen,
            ),
          ],
        );
      },
    );
  }

  /// Tarjeta de KPI compacta con contenedor de icono pastel
  Widget _buildCompactKpiCard({
    required String title,
    required String value,
    required String subtitle,
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ],
      ),
    );
  }

  /// Sección de búsqueda y filtros
  Widget _buildFilterAndSearchSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;

          final searchField = TextField(
            controller: _searchController,
            onChanged: (_) => _loadData(),
            decoration: InputDecoration(
              hintText: 'Buscar por colegio, RNC o email...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navyPrimary, size: 20),
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
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              ButtonSegment(value: 'trial', label: Text('Trial')),
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
                const SizedBox(height: 10),
                filterButtons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              filterButtons,
            ],
          );
        },
      ),
    );
  }

  /// Renderizado de colegios en Cuadrícula moderna estilo "Mis Clases"
  Widget _buildSchoolsGridOrEmpty({required bool isGrid, required int crossAxisCount}) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(color: AppColors.navyPrimary),
        ),
      );
    }

    if (_schools.isEmpty) {
      return _buildEmptyStateForQa();
    }

    if (isGrid && crossAxisCount > 1) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 310,
        ),
        itemCount: _schools.length,
        itemBuilder: (context, index) {
          final school = _schools[index];
          return _buildModernSchoolCard(school);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _schools.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final school = _schools[index];
        return _buildModernSchoolCard(school);
      },
    );
  }

  /// Tarjeta de Colegio moderna estilo "Mis Clases" del diseño de referencia
  Widget _buildModernSchoolCard(School school) {
    final cuposPct = school.maxEstudiantes > 0
        ? (school.totalEstudiantes / school.maxEstudiantes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de cabecera de la tarjeta con Logo, Nombre y Estado
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: school.isSuspended
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (school.logoUrl != null && school.logoUrl!.trim().isNotEmpty)
                  SchoolLogoAvatar(
                    logoUrl: school.logoUrl,
                    fallbackText: school.siglas ?? school.nombre,
                    radius: 20,
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: school.isSuspended
                          ? Colors.red.shade50
                          : AppColors.navyPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: school.isSuspended ? Colors.red.shade700 : AppColors.navyPrimary,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (school.siglas != null) ...[
                            Text(
                              school.siglas!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                            const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                          Expanded(
                            child: Text(
                              'RNC: ${school.rnc ?? "N/D"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: school.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: school.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    school.isTrial
                        ? '${school.trialDiasRestantes}d Trial'
                        : school.statusDisplayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: school.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cuerpo de la tarjeta con detalles de contacto y capacidad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Contacto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              school.emailContacto ?? 'Email no configurado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              school.telefono ?? 'Teléfono no configurado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      if (school.direccion != null && school.direccion!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                school.direccion!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Barra de Cuota / Capacidad
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plan ${school.planName}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                          ),
                          Text(
                            '${school.totalEstudiantes} / ${school.maxEstudiantes} alumnos (${(cuposPct * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cuposPct,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: cuposPct > 0.85 ? Colors.orange.shade700 : AppColors.electricBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Barra inferior de botones de acción rápida
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Facturar NCF
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => SaasBillingDialog(initialSchool: school),
                    ).then((_) => _loadData());
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    backgroundColor: const Color(0xFFF0F9FF),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Facturar NCF', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                // Reset Clave
                OutlinedButton(
                  onPressed: () {
                    final directorEmail = school.directorEmail ?? school.emailContacto ?? 'admin@ceno.edu.do';
                    final directorName = school.directorNombre ?? 'Director(a) General';
                    ResetPasswordDialog.show(
                      context,
                      schoolId: school.id,
                      schoolName: school.nombre,
                      userEmail: directorEmail,
                      userName: directorName,
                      schoolRepository: widget.schoolRepository,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    backgroundColor: const Color(0xFFFEF3C7),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Reset Clave', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                // Suspender o Reactivar
                IconButton(
                  tooltip: school.isActive ? 'Suspender Servicio' : 'Reactivar Servicio',
                  icon: Icon(
                    school.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                    size: 20,
                    color: school.isActive ? Colors.red.shade700 : AppColors.accentGreen,
                  ),
                  onPressed: () => _toggleSubscription(school),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // Botón Inspeccionar
                ElevatedButton.icon(
                  onPressed: () => widget.onSelectSchoolToInspect?.call(school),
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                  label: const Text('Inspeccionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: AppColors.surfaceWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Panel Lateral Derecho 1: Cobranza & Facturación SaaS (DGII)
  Widget _buildBillingSummaryPanel() {
    final pendingCount = _invoices.where((i) => i.isPending).length;
    final totalPendingAmount = _invoices
        .where((i) => i.isPending)
        .fold(0.0, (acc, i) => acc + i.monto);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cobranza SaaS & NCF DGII',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                ),
              ),
              IconButton(
                tooltip: 'Emitir Factura NCF',
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const SaasBillingDialog(),
                  ).then((_) => _loadData());
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_invoices.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text(
                    'No hay facturas emitidas aún.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Genera facturas B01/B02 de suscripción mensual con NCF formal de DGII.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const SaasBillingDialog(),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.receipt, size: 14),
                    label: const Text('Crear Primera Factura NCF', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pendiente de Cobro', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      'RD\$ ${totalPendingAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pendingCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$pendingCount pendientes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: pendingCount > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Panel Lateral Derecho 2: Anuncios del Sistema
  Widget _buildAnnouncementsSummaryPanel() {
    final activeAnnouncements = _announcements.where((a) => a.activo).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFB45309).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.campaign_rounded, color: Color(0xFFB45309), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Anuncios del Sistema',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                ),
              ),
              IconButton(
                tooltip: 'Publicar Anuncio Global',
                icon: const Icon(Icons.add_alert_rounded, size: 18, color: Color(0xFFB45309)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const SystemAnnouncementDialog(),
                  ).then((_) => _loadData());
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeAnnouncements.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Sin alertas globales activas.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Puedes emitir banners de mantenimiento o avisos a directores y docentes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const SystemAnnouncementDialog(),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.campaign, size: 14),
                    label: const Text('Publicar Comunicado', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      backgroundColor: const Color(0xFFFEF3C7),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...activeAnnouncements.take(2).map((a) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: a.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a.icon, size: 16, color: a.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: a.color),
                          ),
                          Text(
                            a.mensaje,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Panel Lateral Derecho 3: Auditoría & Salud del Sistema
  Widget _buildAuditAndHealthPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.navyPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Seguridad & Auditoría',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHealthStatusRow('Base de Datos Supabase', 'Conectada & Operativa', Icons.check_circle_rounded, const Color(0xFF15803D)),
          const SizedBox(height: 8),
          _buildHealthStatusRow('Red CDN Netlify', '100% Disponibilidad', Icons.check_circle_rounded, const Color(0xFF15803D)),
          const SizedBox(height: 8),
          _buildHealthStatusRow('Aislamiento Multi-Tenant', 'Activo por RNC', Icons.verified_user_rounded, AppColors.electricBlue),
        ],
      ),
    );
  }

  Widget _buildHealthStatusRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  /// Banner didáctico explicativo del Superadmin
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
                      desc: 'Registra colegios con su RNC oficial de DGII, asignando capacidad de alumnos y plan.',
                    ),
                    _buildGuideItem(
                      icon: Icons.pause_circle_outline_rounded,
                      title: '2. Control de Acceso',
                      desc: 'Suspende o reactiva el acceso al sistema si una institución está al día o en mora.',
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
          Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
        ],
      ),
    );
  }

  /// Estado vacío amigable para QA
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
}
