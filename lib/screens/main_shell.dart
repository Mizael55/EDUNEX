import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../features/auth/models/user_profile.dart';
import '../features/auth/models/user_role.dart';
import '../features/families/repositories/family_repository.dart';
import '../features/families/screens/family_directory_screen.dart';
import '../features/dashboard/screens/dashboard_overview_screen.dart';
import '../features/parent_portal/screens/parent_portal_screen.dart';
import '../features/parent_portal/screens/parent_payments_screen.dart';
import '../features/parent_portal/screens/parent_services_screen.dart';
import '../features/parent_portal/screens/parent_store_screen.dart';
import '../features/parent_portal/screens/parent_questions_screen.dart';
import '../features/parent_portal/screens/parent_events_screen.dart';
import '../features/events/repositories/event_repository.dart';
import '../features/events/screens/admin_events_screen.dart';
import '../features/attendance/repositories/attendance_repository.dart';
import '../features/attendance/screens/admin_attendance_screen.dart';
import '../features/parent_portal/screens/parent_attendance_screen.dart';
import '../features/transport/repositories/transport_repository.dart';
import '../features/transport/screens/admin_transport_screen.dart';
import '../features/circulars/repositories/circular_repository.dart';
import '../features/circulars/screens/admin_circulars_screen.dart';
import '../features/parent_portal/screens/parent_circulars_screen.dart';
import '../features/academics/repositories/academic_repository.dart';
import '../features/academics/screens/admin_grades_screen.dart';
import '../features/parent_portal/screens/parent_grades_screen.dart';
import '../features/inquiries/screens/admin_inquiries_screen.dart';
import '../features/superadmin/repositories/school_repository.dart';
import '../features/superadmin/screens/superadmin_dashboard_screen.dart';
import '../features/superadmin/models/school.dart';
import '../features/finances/screens/finance_overview_screen.dart';
import '../features/services/screens/services_management_screen.dart';
import 'login_screen.dart';

/// Shell principal responsivo de EDUNEX con navegación adaptativa
class MainShell extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository? familyRepository;
  final SchoolRepository? schoolRepository;
  final AcademicRepository? academicRepository;

  const MainShell({
    super.key,
    required this.userProfile,
    this.familyRepository,
    this.schoolRepository,
    this.academicRepository,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final FamilyRepository _familyRepository;
  late final SchoolRepository _schoolRepository;
  late final EventRepository _eventRepository;
  late final AttendanceRepository _attendanceRepository;
  late final TransportRepository _transportRepository;
  late final CircularRepository _circularRepository;
  late final AcademicRepository _academicRepository;
  String _schoolName = 'Colegio Cliente EDUNEX';
  School? _inspectedSchool;

  @override
  void initState() {
    super.initState();
    _familyRepository = widget.familyRepository ?? FamilyRepository();
    _schoolRepository = widget.schoolRepository ?? SchoolRepository();
    _eventRepository = EventRepository(familyRepository: _familyRepository);
    _attendanceRepository = AttendanceRepository(familyRepository: _familyRepository);
    _transportRepository = TransportRepository(familyRepository: _familyRepository);
    _circularRepository = CircularRepository(familyRepository: _familyRepository);
    _academicRepository = widget.academicRepository ?? AcademicRepository();
    _loadSchoolName();
  }

  Future<void> _loadSchoolName() async {
    if (widget.userProfile.colegioId != null) {
      final name = await _schoolRepository.getSchoolNameById(widget.userProfile.colegioId!);
      if (name != null && mounted) {
        setState(() => _schoolName = name);
      }
    }
  }

  bool get _isSuperAdmin => widget.userProfile.rol == UserRole.superadmin;
  bool get _isParent => widget.userProfile.rol == UserRole.tutorFamiliar;
  bool get _isStudent => widget.userProfile.rol == UserRole.estudiante;

  List<NavigationItem> get _navItems {
    if (_isSuperAdmin) {
      return [
        const NavigationItem(
          title: 'Panel Maestro SaaS',
          icon: Icons.hub_rounded,
        ),
        const NavigationItem(
          title: 'Colegios Clientes',
          icon: Icons.domain_rounded,
        ),
        const NavigationItem(
          title: 'Panel Escolar Piloto',
          icon: Icons.dashboard_rounded,
        ),
        const NavigationItem(
          title: 'Cuentas Familiares',
          icon: Icons.people_alt_rounded,
        ),
        const NavigationItem(
          title: 'Finanzas & Cobranzas',
          icon: Icons.account_balance_wallet_rounded,
        ),
      ];
    }

    if (_isParent) {
      return [
        const NavigationItem(
          title: 'Mi Familia & Hijos',
          icon: Icons.family_restroom_rounded,
        ),
        const NavigationItem(
          title: 'Pagos, Acuerdos & NCF',
          icon: Icons.receipt_long_rounded,
        ),
        const NavigationItem(
          title: 'Servicios Escolares',
          icon: Icons.room_service_rounded,
        ),
        const NavigationItem(
          title: 'Tienda Escolar',
          icon: Icons.shopping_bag_rounded,
        ),
        const NavigationItem(
          title: 'Eventos & Excursiones',
          icon: Icons.event_available_rounded,
        ),
        const NavigationItem(
          title: 'Asistencia & Seguimiento',
          icon: Icons.fact_check_rounded,
        ),
        const NavigationItem(
          title: 'Circulares & Autorizaciones',
          icon: Icons.campaign_rounded,
        ),
        const NavigationItem(
          title: 'Consultas & Preguntas',
          icon: Icons.question_answer_rounded,
        ),
        const NavigationItem(
          title: 'Calificaciones & Boletín',
          icon: Icons.grade_rounded,
        ),
      ];
    }

    if (_isStudent) {
      return [
        const NavigationItem(
          title: 'Mi Portal Escolar',
          icon: Icons.backpack_rounded,
        ),
        const NavigationItem(
          title: 'Servicios de Cuido',
          icon: Icons.child_care_rounded,
        ),
        const NavigationItem(
          title: 'Tienda & Uniformes',
          icon: Icons.shopping_bag_rounded,
        ),
      ];
    }

    return [
      const NavigationItem(
        title: 'Panel de Control',
        icon: Icons.dashboard_rounded,
      ),
      const NavigationItem(
        title: 'Cuentas Familiares',
        icon: Icons.people_alt_rounded,
      ),
      const NavigationItem(
        title: 'Finanzas & Cobranzas',
        icon: Icons.account_balance_wallet_rounded,
      ),
      const NavigationItem(
        title: 'Control de Asistencia',
        icon: Icons.fact_check_rounded,
      ),
      const NavigationItem(
        title: 'Circulares & Avisos',
        icon: Icons.campaign_rounded,
      ),
      const NavigationItem(
        title: 'Servicios de Cuido',
        icon: Icons.child_care_rounded,
      ),
      const NavigationItem(
        title: 'Eventos & Excursiones',
        icon: Icons.event_available_rounded,
      ),
      const NavigationItem(
        title: 'Transporte Escolar',
        icon: Icons.directions_bus_rounded,
      ),
      const NavigationItem(
        title: 'Gestión Académica & Notas',
        icon: Icons.school_rounded,
      ),
      const NavigationItem(
        title: 'Atención a Familias',
        icon: Icons.support_agent_rounded,
      ),
      const NavigationItem(
        title: 'Tienda & Uniformes',
        icon: Icons.shopping_bag_rounded,
      ),
    ];
  }

  Widget _buildBody() {
    if (_isSuperAdmin) {
      switch (_selectedIndex) {
        case 0:
        case 1:
          return SuperAdminDashboardScreen(
            schoolRepository: _schoolRepository,
            onSelectSchoolToInspect: (school) {
              setState(() {
                _inspectedSchool = school;
                _selectedIndex = 2;
              });
            },
          );
        case 2:
          return DashboardOverviewScreen(
            familyRepository: _familyRepository,
            schoolName: _inspectedSchool?.nombre,
            onReturnToSuperAdmin: _inspectedSchool != null
                ? () => setState(() {
                      _inspectedSchool = null;
                      _selectedIndex = 0;
                    })
                : null,
            onNavigateToFamilies: () => setState(() => _selectedIndex = 3),
          );
        case 3:
          return FamilyDirectoryScreen(
            repository: _familyRepository,
            colegioId: _inspectedSchool?.id,
          );
        case 4:
          return FinanceOverviewScreen(
            isSuperAdmin: true,
            familyRepository: _familyRepository,
            schoolRepository: _schoolRepository,
          );
        default:
          return _buildPlaceholderScreen(_navItems[_selectedIndex].title);
      }
    }

    if (_isParent) {
      switch (_selectedIndex) {
        case 0:
          return ParentPortalScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
            eventRepository: _eventRepository,
            attendanceRepository: _attendanceRepository,
            circularRepository: _circularRepository,
            academicRepository: _academicRepository,
            onNavigateTab: (index) => setState(() => _selectedIndex = index),
          );
        case 1:
          return ParentPaymentsScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
          );
        case 2:
          return ParentServicesScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
          );
        case 3:
          return ParentStoreScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
          );
        case 4:
          return ParentEventsScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
            eventRepository: _eventRepository,
          );
        case 5:
          return ParentAttendanceScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
            attendanceRepository: _attendanceRepository,
          );
        case 6:
          return ParentCircularsScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
            circularRepository: _circularRepository,
          );
        case 7:
          return ParentQuestionsScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
          );
        case 8:
          return ParentGradesScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
            academicRepository: _academicRepository,
          );
        default:
          return _buildPlaceholderScreen(_navItems[_selectedIndex].title);
      }
    }

    if (_isStudent) {
      switch (_selectedIndex) {
        case 0:
          return ParentPortalScreen(
            userProfile: widget.userProfile,
            familyRepository: _familyRepository,
          );
        case 1:
          return const ServicesManagementScreen(moduleType: ServiceModuleType.cuido);
        case 2:
          return const ServicesManagementScreen(moduleType: ServiceModuleType.tienda);
        default:
          return _buildPlaceholderScreen(_navItems[_selectedIndex].title);
      }
    }

    // Administrador de Colegio (Director / Personal Escolar)
    switch (_selectedIndex) {
      case 0:
        return DashboardOverviewScreen(
          familyRepository: _familyRepository,
          schoolName: _schoolName,
          onNavigateToFamilies: () => setState(() => _selectedIndex = 1),
        );
      case 1:
        return FamilyDirectoryScreen(
          repository: _familyRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 2:
        return FinanceOverviewScreen(
          isSuperAdmin: false,
          familyRepository: _familyRepository,
        );
      case 3:
        return AdminAttendanceScreen(
          repository: _attendanceRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 4:
        return AdminCircularsScreen(
          repository: _circularRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 5:
        return const ServicesManagementScreen(moduleType: ServiceModuleType.cuido);
      case 6:
        return AdminEventsScreen(
          repository: _eventRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 7:
        return AdminTransportScreen(
          repository: _transportRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 8:
        return AdminGradesScreen(
          academicRepository: _academicRepository,
        );
      case 9:
        return AdminInquiriesScreen(
          familyRepository: _familyRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 10:
        return const ServicesManagementScreen(moduleType: ServiceModuleType.tienda);
      default:
        return _buildPlaceholderScreen(_navItems[_selectedIndex].title);
    }
  }

  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 48,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Módulo conectado al esquema central de base de datos de Supabase.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedIndex = 0),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Volver al Inicio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de EDUNEX?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navyPrimary,
          foregroundColor: AppColors.surfaceWhite,
          elevation: 0,
          title: Row(
            children: [
              Image.asset('assets/logo.jpg', height: 28, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
              const SizedBox(width: 8),
              const Text('EDUNEX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar Sesión',
              onPressed: _logout,
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppColors.navyPrimary),
                accountName: Text(
                  widget.userProfile.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(widget.userProfile.email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppColors.surfaceWhite,
                  child: Text(
                    widget.userProfile.nombres.isNotEmpty ? widget.userProfile.nombres[0] : 'U',
                    style: const TextStyle(color: AppColors.navyPrimary, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: _selectedIndex == index ? AppColors.navyPrimary : AppColors.textSecondary,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: _selectedIndex == index ? AppColors.navyPrimary : AppColors.textPrimary,
                          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: _selectedIndex == index,
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex < 4 ? _selectedIndex : 0,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: AppColors.navyPrimary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: _navItems.take(4).map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.title.split(' ').first,
            );
          }).toList(),
        ),
      );
    }

    // Layout de Escritorio con Sidebar elegante
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar Fija
          Container(
            width: 270,
            decoration: const BoxDecoration(
              color: AppColors.navyPrimary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cabecera del Sidebar con Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.school_rounded,
                            color: AppColors.navyPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EDUNEX',
                            style: TextStyle(
                              color: AppColors.surfaceWhite,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'CRM ESCOLAR',
                            style: TextStyle(
                              color: AppColors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge de Institución
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceWhite.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuperAdmin ? Icons.hub_rounded : Icons.location_city_rounded,
                          color: _isSuperAdmin ? AppColors.amberAccent : AppColors.surfaceWhite,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSuperAdmin ? 'Red Central EDUNEX (SaaS)' : _schoolName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.surfaceWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),

                // Items de Navegación
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: isSelected ? AppColors.electricBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedIndex = index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected ? AppColors.surfaceWhite : Colors.white70,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.surfaceWhite : Colors.white70,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Perfil de Usuario y Logout
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceWhite.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: widget.userProfile.rol.color,
                        child: Text(
                          widget.userProfile.nombres.isNotEmpty ? widget.userProfile.nombres[0] : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userProfile.nombreCompleto,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              widget.userProfile.rol.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.userProfile.rol.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Cerrar Sesión',
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Área de Contenido Principal
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;

  const NavigationItem({
    required this.title,
    required this.icon,
  });
}
