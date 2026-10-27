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
import '../features/store/repositories/store_repository.dart';
import '../features/store/screens/admin_store_screen.dart';
import '../features/superadmin/repositories/school_repository.dart';
import '../features/superadmin/screens/superadmin_dashboard_screen.dart';
import '../features/superadmin/widgets/edit_school_logo_dialog.dart';
import '../features/superadmin/models/school.dart';
import '../features/finances/screens/finance_overview_screen.dart';
import '../features/services/screens/services_management_screen.dart';
import '../features/teacher_portal/repositories/teacher_repository.dart';
import '../features/teacher_portal/screens/teacher_portal_screen.dart';
import '../features/guidance/repositories/guidance_repository.dart';
import '../features/guidance/screens/guidance_management_screen.dart';
import 'login_screen.dart';

/// Shell principal responsivo de EDUNEX con navegación adaptativa
class MainShell extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository? familyRepository;
  final SchoolRepository? schoolRepository;
  final AcademicRepository? academicRepository;
  final StoreRepository? storeRepository;
  final TeacherRepository? teacherRepository;
  final GuidanceRepository? guidanceRepository;

  const MainShell({
    super.key,
    required this.userProfile,
    this.familyRepository,
    this.schoolRepository,
    this.academicRepository,
    this.storeRepository,
    this.teacherRepository,
    this.guidanceRepository,
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
  late final StoreRepository _storeRepository;
  late final TeacherRepository _teacherRepository;
  late final GuidanceRepository _guidanceRepository;
  String _schoolName = 'Colegio Cliente EDUNEX';
  String? _schoolLogoUrl;
  School? _inspectedSchool;

  @override
  void initState() {
    super.initState();
    _familyRepository = widget.familyRepository ?? FamilyRepository(useDemoFallback: false);
    _schoolRepository = widget.schoolRepository ?? SchoolRepository(useDemoFallback: false);
    _eventRepository = EventRepository(familyRepository: _familyRepository, useDemoFallback: false);
    _attendanceRepository = AttendanceRepository(familyRepository: _familyRepository, useDemoFallback: false);
    _transportRepository = TransportRepository(familyRepository: _familyRepository, useDemoFallback: false);
    _circularRepository = CircularRepository(familyRepository: _familyRepository, useDemoFallback: false);
    _academicRepository = widget.academicRepository ?? AcademicRepository(useDemoFallback: false);
    _storeRepository = widget.storeRepository ?? StoreRepository(useDemoFallback: false);
    _teacherRepository = widget.teacherRepository ?? TeacherRepository(useDemoFallback: false);
    _guidanceRepository = widget.guidanceRepository ?? GuidanceRepository(useDemoFallback: false);
    _loadSchoolName();
  }

  Future<void> _loadSchoolName() async {
    if (widget.userProfile.colegioId != null) {
      final school = await _schoolRepository.getSchoolById(widget.userProfile.colegioId!);
      if (school != null && mounted) {
        setState(() {
          _schoolName = school.nombre;
          _schoolLogoUrl = school.logoUrl;
        });
      } else {
        final name = await _schoolRepository.getSchoolNameById(widget.userProfile.colegioId!);
        if (name != null && mounted) {
          setState(() => _schoolName = name);
        }
      }
    }
  }

  void _openEditSchoolLogoDialog() async {
    final schoolId = widget.userProfile.colegioId ?? 'a0000000-0000-0000-0000-000000000001';
    final updatedLogo = await EditSchoolLogoDialog.show(
      context,
      schoolId: schoolId,
      schoolName: _schoolName,
      currentLogoUrl: _schoolLogoUrl,
      schoolRepository: _schoolRepository,
      onLogoUpdated: (newLogo) {
        if (mounted) {
          setState(() => _schoolLogoUrl = newLogo);
        }
      },
    );
    if (updatedLogo != null && mounted) {
      setState(() => _schoolLogoUrl = updatedLogo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Logo del centro educativo actualizado con éxito!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  bool get _isSuperAdmin => widget.userProfile.rol == UserRole.superadmin;
  bool get _isParent => widget.userProfile.rol == UserRole.tutorFamiliar;
  bool get _isStudent => widget.userProfile.rol == UserRole.estudiante;
  bool get _isTeacher => widget.userProfile.rol == UserRole.docente;

  List<NavigationItem> get _navItems {
    if (_isTeacher) {
      return [
        const NavigationItem(
          title: 'Libro de Clases',
          icon: Icons.auto_stories_rounded,
        ),
        const NavigationItem(
          title: 'Calificador de Aula',
          icon: Icons.grading_rounded,
        ),
        const NavigationItem(
          title: 'Pase de Lista',
          icon: Icons.fact_check_rounded,
        ),
        const NavigationItem(
          title: 'Observador & Convivencia',
          icon: Icons.psychology_rounded,
        ),
      ];
    }

    if (_isSuperAdmin) {
      if (_inspectedSchool != null) {
        return [
          const NavigationItem(
            title: 'Panel del Colegio Auditado',
            icon: Icons.dashboard_rounded,
          ),
          const NavigationItem(
            title: 'Cuentas Familiares',
            icon: Icons.people_alt_rounded,
          ),
          const NavigationItem(
            title: 'Finanzas del Colegio',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ];
      }

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
          title: 'Finanzas & Facturación SaaS',
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
      const NavigationItem(
        title: 'Psicología & Convivencia',
        icon: Icons.psychology_rounded,
      ),
    ];
  }

  Widget _buildBody() {
    if (_isTeacher) {
      return TeacherPortalScreen(
        userProfile: widget.userProfile,
        teacherRepository: _teacherRepository,
        academicRepository: _academicRepository,
        attendanceRepository: _attendanceRepository,
        initialTabIndex: _selectedIndex.clamp(0, 3),
        onTabChanged: (idx) {
          if (_selectedIndex != idx) setState(() => _selectedIndex = idx);
        },
      );
    }

    if (_isSuperAdmin) {
      if (_inspectedSchool != null) {
        switch (_selectedIndex) {
          case 0:
            return DashboardOverviewScreen(
              familyRepository: _familyRepository,
              schoolName: _inspectedSchool?.nombre,
              colegioId: _inspectedSchool?.id,
              onReturnToSuperAdmin: () => setState(() {
                _inspectedSchool = null;
                _selectedIndex = 0;
              }),
              onNavigateToFamilies: () => setState(() => _selectedIndex = 1),
            );
          case 1:
            return FamilyDirectoryScreen(
              repository: _familyRepository,
              colegioId: _inspectedSchool?.id,
            );
          case 2:
            return FinanceOverviewScreen(
              isSuperAdmin: false,
              familyRepository: _familyRepository,
              schoolRepository: _schoolRepository,
            );
          default:
            return _buildPlaceholderScreen(_navItems[_selectedIndex].title);
        }
      }

      switch (_selectedIndex) {
        case 0:
        case 1:
          return SuperAdminDashboardScreen(
            schoolRepository: _schoolRepository,
            onSelectSchoolToInspect: (school) {
              setState(() {
                _inspectedSchool = school;
                _selectedIndex = 0;
              });
            },
          );
        case 2:
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
            storeRepository: _storeRepository,
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
            storeRepository: _storeRepository,
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
          colegioId: widget.userProfile.colegioId,
          onEditSchoolLogo: _openEditSchoolLogoDialog,
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
          familyRepository: _familyRepository,
          colegioId: widget.userProfile.colegioId ?? 'col-1',
        );
      case 9:
        return AdminInquiriesScreen(
          familyRepository: _familyRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 10:
        return AdminStoreScreen(
          storeRepository: _storeRepository,
          colegioId: widget.userProfile.colegioId,
        );
      case 11:
        return GuidanceManagementScreen(
          guidanceRepository: _guidanceRepository,
          colegioId: widget.userProfile.colegioId ?? 'a0000000-0000-0000-0000-000000000001',
        );
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
      final role = widget.userProfile.rol;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: role.color,
          foregroundColor: AppColors.surfaceWhite,
          elevation: 2,
          title: Row(
            children: [
              Image.asset('assets/logo.jpg', height: 26, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
              const SizedBox(width: 8),
              const Text('EDUNEX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white38),
                ),
                child: Text(
                  role.tagLabel.split('•').first.trim(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
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
                decoration: BoxDecoration(gradient: role.layoutGradient),
                accountName: Text(
                  widget.userProfile.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text('${widget.userProfile.email} • ${role.displayName}'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: role.activeItemColor,
                  child: Text(
                    widget.userProfile.nombres.isNotEmpty ? widget.userProfile.nombres[0] : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
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
                        color: _selectedIndex == index ? role.color : AppColors.textSecondary,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: _selectedIndex == index ? role.color : AppColors.textPrimary,
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
        body: Column(
          children: [
            Container(height: 3, color: role.activeItemColor),
            Expanded(child: _buildBody()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex < 4 ? _selectedIndex : 0,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: role.color,
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

    final role = widget.userProfile.rol;

    // Layout de Escritorio con Sidebar elegante adaptado al Rol
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar Fija con Color y Gradiente Específico del Rol
          Container(
            width: 270,
            decoration: BoxDecoration(
              gradient: role.layoutGradient,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cabecera del Sidebar con Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

                // Badge Destacado de Identidad de Rol (Permite distinguir al instante el rol activo)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: role.activeItemColor.withValues(alpha: 0.7), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Icon(role.icon, color: role.activeItemColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ROL ACTIVO',
                                style: TextStyle(
                                  color: role.activeItemColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                role.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Badge de Institución con Logo de Perfil (Issue #15)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceWhite.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        if (!_isSuperAdmin && _schoolLogoUrl != null && _schoolLogoUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _schoolLogoUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.school_rounded,
                                color: AppColors.surfaceWhite,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          Icon(
                            _isSuperAdmin ? Icons.hub_rounded : Icons.school_rounded,
                            color: _isSuperAdmin ? AppColors.amberAccent : AppColors.surfaceWhite,
                            size: 22,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSuperAdmin ? 'Red Central EDUNEX (SaaS)' : _schoolName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.surfaceWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isSuperAdmin)
                                const Text(
                                  'Logo Institucional',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!_isSuperAdmin)
                          IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.amberAccent, size: 18),
                            tooltip: 'Cambiar Logo del Centro',
                            onPressed: _openEditSchoolLogoDialog,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

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
                          color: isSelected ? role.color : Colors.transparent,
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
                        backgroundColor: role.activeItemColor,
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
                              role.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: role.activeItemColor,
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

          // Área de Contenido Principal con Barra Superior de Rol
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [role.color, role.activeItemColor],
                    ),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
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
