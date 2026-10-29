import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/modern_dialog.dart';
import '../models/saas_user.dart';
import '../repositories/school_repository.dart';
import '../widgets/create_saas_user_dialog.dart';

class SaaSUsersScreen extends StatefulWidget {
  final SchoolRepository schoolRepository;

  const SaaSUsersScreen({
    super.key,
    required this.schoolRepository,
  });

  @override
  State<SaaSUsersScreen> createState() => _SaaSUsersScreenState();
}

class _SaaSUsersScreenState extends State<SaaSUsersScreen> {
  List<SaaSUser> _users = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  SaaSRole? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.schoolRepository.getSaaSUsers(
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        rolFilter: _selectedRoleFilter,
      );
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCreateUserDialog() {
    CreateSaaSUserDialog.show(
      context,
      schoolRepository: widget.schoolRepository,
      onUserCreated: (_) => _loadUsers(),
    );
  }

  Future<void> _toggleStatus(SaaSUser user) async {
    if (user.rol == SaaSRole.superadmin && user.email == 'admin@edunex.edu') {
      AppToast.warning(
        context,
        'No es posible suspender la cuenta maestra del Superadmin principal.',
        title: 'Acción Restringida',
      );
      return;
    }

    final action = user.activo ? 'Suspender' : 'Reactivar';
    final confirmed = await ModernConfirmDialog.show(
      context: context,
      title: '$action Acceso',
      message: '¿Estás seguro de que deseas $action a "${user.nombreCompleto}" (${user.email})?',
      confirmText: action,
      isDestructive: user.activo,
      icon: user.activo ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
    );

    if (confirmed == true && mounted) {
      await widget.schoolRepository.toggleSaaSUserStatus(user.id);
      AppToast.success(
        context,
        'El usuario ${user.nombreCompleto} ha sido ${user.activo ? "suspendido" : "reactivado"}.',
      );
      _loadUsers();
    }
  }

  Future<void> _resetPassword(SaaSUser user) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFFB45309)),
            const SizedBox(width: 8),
            const Text('Nueva Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa la nueva contraseña provisional para ${user.nombreCompleto}:',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: 'Mínimo 6 caracteres',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Actualizar Clave'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.trim().length >= 6 && mounted) {
      await widget.schoolRepository.resetSaaSUserPassword(user.id, passwordController.text.trim());
      if (mounted) {
        AppToast.success(
          context,
          'Contraseña restablecida exitosamente para ${user.email}.',
          title: 'Clave Actualizada',
        );
      }
    } else if (confirmed == true && mounted) {
      AppToast.warning(
        context,
        'La contraseña debe contener al menos 6 caracteres.',
        title: 'Contraseña Muy Corta',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1050;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(constraints),
                const SizedBox(height: 20),
                _buildKpis(constraints),
                const SizedBox(height: 24),
                _buildSearchAndFilters(),
                const SizedBox(height: 18),
                _buildUsersGridOrEmpty(isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 900;

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
                color: AppColors.navyPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EMPRESA MATRIZ SAAS',
                style: TextStyle(
                  color: AppColors.navyPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Text(
              'Equipo Corporativo EDUNEX',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Equipo & Asignación de Roles SaaS',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Administra el personal interno de tu empresa (Superadmin, Admins, Contables, Secretaría y Soporte Técnico).',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );

    final actionButton = ElevatedButton.icon(
      onPressed: _openCreateUserDialog,
      icon: const Icon(Icons.person_add_rounded, size: 18),
      label: const Text('+ Nuevo Miembro del Equipo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.surfaceWhite,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 14),
        actionButton,
      ],
    );
  }

  Widget _buildKpis(BoxConstraints constraints) {
    final total = _users.length;
    final admins = _users.where((u) => u.rol == SaaSRole.superadmin || u.rol == SaaSRole.admin).length;
    final contables = _users.where((u) => u.rol == SaaSRole.contable).length;
    final activos = _users.where((u) => u.activo).length;

    final isDesktop = constraints.maxWidth >= 950;
    final crossAxisCount = isDesktop ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isDesktop ? 1.6 : (constraints.maxWidth >= 550 ? 1.8 : 2.2),
      children: [
        _buildKpiCard('Total Miembros', '$total', 'Personal interno registrado', Icons.people_alt_rounded, AppColors.navyPrimary),
        _buildKpiCard('Administración', '$admins', 'Superadmins y Operaciones', Icons.admin_panel_settings_rounded, AppColors.electricBlue),
        _buildKpiCard('Finanzas & DGII', '$contables', 'Cobranza y Facturación', Icons.receipt_long_rounded, const Color(0xFF0284C7)),
        _buildKpiCard('Cuentas Activas', '$activos', 'Con acceso vigente', Icons.verified_user_rounded, AppColors.accentGreen),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadUsers(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o correo corporativo...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navyPrimary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleFilterChip(null, 'Todos'),
                ...SaaSRole.values.map((r) => _buildRoleFilterChip(r, r.displayName)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(SaaSRole? role, String label) {
    final isSelected = _selectedRoleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.navyPrimary.withValues(alpha: 0.12),
        checkmarkColor: AppColors.navyPrimary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.navyPrimary : AppColors.textSecondary,
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppColors.navyPrimary : const Color(0xFFE2E8F0)),
        ),
        onSelected: (_) {
          setState(() => _selectedRoleFilter = role);
          _loadUsers();
        },
      ),
    );
  }

  Widget _buildUsersGridOrEmpty(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(color: AppColors.navyPrimary),
        ),
      );
    }

    if (_users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.group_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'No se encontraron usuarios en el equipo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Añade colaboradores a tu empresa SaaS para delegar administración, finanzas y soporte.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openCreateUserDialog,
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('+ Nuevo Miembro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = isDesktop ? 3 : 1;

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 220,
        ),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(SaaSUser user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.activo ? const Color(0xFFE2E8F0) : Colors.red.shade200,
        ),
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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: user.rol.color.withValues(alpha: 0.15),
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: user.rol.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.nombreCompleto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: user.activo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.activo ? 'ACTIVO' : 'SUSPENDIDO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: user.activo ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (user.telefono != null && user.telefono!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📞 ${user.telefono!}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.rol.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: user.rol.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(user.rol.icon, size: 13, color: user.rol.color),
                  const SizedBox(width: 5),
                  Text(
                    user.rol.displayName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: user.rol.color),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _resetPassword(user),
                  icon: const Icon(Icons.lock_reset_rounded, size: 14, color: Color(0xFFB45309)),
                  label: const Text('Reset Clave', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    backgroundColor: const Color(0xFFFEF3C7),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: user.activo ? 'Suspender Acceso' : 'Reactivar Acceso',
                  icon: Icon(
                    user.activo ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                    size: 18,
                    color: user.activo ? Colors.red.shade700 : AppColors.accentGreen,
                  ),
                  onPressed: () => _toggleStatus(user),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
