import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/models/student.dart';
import '../../families/repositories/family_repository.dart';
import 'parent_payments_screen.dart';
import 'parent_services_screen.dart';
import 'parent_store_screen.dart';
import 'parent_questions_screen.dart';
import 'parent_events_screen.dart';
import 'parent_attendance_screen.dart';
import 'parent_circulars_screen.dart';
import '../../events/repositories/event_repository.dart';
import '../../attendance/repositories/attendance_repository.dart';
import '../../circulars/repositories/circular_repository.dart';
import '../../academics/repositories/academic_repository.dart';
import '../../store/repositories/store_repository.dart';
import 'parent_grades_screen.dart';

/// Portal de Padres y Tutores en EDUNEX
class ParentPortalScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;
  final EventRepository? eventRepository;
  final AttendanceRepository? attendanceRepository;
  final CircularRepository? circularRepository;
  final AcademicRepository? academicRepository;
  final StoreRepository? storeRepository;
  final void Function(int tabIndex)? onNavigateTab;

  const ParentPortalScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
    this.eventRepository,
    this.attendanceRepository,
    this.circularRepository,
    this.academicRepository,
    this.storeRepository,
    this.onNavigateTab,
  });

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  Family? _family;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );
      if (mounted) {
        setState(() {
          _family = family;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToSection(int tabIndex, Widget fallbackWidget) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(tabIndex);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => fallbackWidget),
      ).then((_) => _loadFamily());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.navyPrimary),
        ),
      );
    }

    final family = _family;
    if (family == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: Text('No se encontró información familiar.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Familiar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.electricBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyPrimary.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceWhite.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: AppColors.surfaceWhite,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.amberAccent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                family.codigoFamilia,
                                style: const TextStyle(
                                  color: AppColors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'PORTAL DE PADRES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '¡Hola, ${widget.userProfile.nombreCompleto}!',
                          style: const TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${family.nombreFamilia} • Colegio Bilingüe EDUNEX Piloto',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Banner Institucional de Matrícula Oficial Exclusiva de Secretaría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.electricBlue, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Estudiantes Matriculados Oficialmente — Las admisiones, creaciones de familias y matrículas son tramitadas exclusivamente por la secretaría del centro.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Estado de Cuenta Consolidado
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: family.estaAlDia ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                ),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: family.estaAlDia
                          ? AppColors.accentGreen.withValues(alpha: 0.12)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      family.estaAlDia
                          ? Icons.check_circle_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: family.estaAlDia ? AppColors.accentGreen : const Color(0xFFB45309),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.estaAlDia
                              ? 'Tu cuenta familiar está al día'
                              : 'Balance Pendiente Acumulado',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: family.estaAlDia
                                ? const Color(0xFF166534)
                                : const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'RD\$ ${family.balancePendiente.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: family.estaAlDia
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                        Text(
                          'Incluye colegiatura consolidada y servicios adicionales contratados.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _navigateToSection(
                        1,
                        ParentPaymentsScreen(
                          userProfile: widget.userProfile,
                          familyRepository: widget.familyRepository,
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: Text(family.estaAlDia ? 'Ver Recibos & NCF' : 'Pagar RD\$ ${family.balancePendiente.toStringAsFixed(2)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Accesos Rápidos del Tutor (6 Acciones Permitidas de QA)
            const Text(
              'Acciones & Servicios Disponibles para el Tutor',
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
                _buildActionCard(
                  title: '1. Comprar en la Tienda',
                  subtitle: 'Uniformes, libros de texto y útiles',
                  icon: Icons.shopping_bag_rounded,
                  color: AppColors.navyPrimary,
                  onTap: () {
                    _navigateToSection(
                      3,
                      ParentStoreScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                        storeRepository: widget.storeRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '2. Pagar Colegiatura',
                  subtitle: 'Pasarela en línea y abono a cuenta',
                  icon: Icons.credit_card_rounded,
                  color: AppColors.accentGreen,
                  onTap: () {
                    _navigateToSection(
                      1,
                      ParentPaymentsScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '3. Realizar Acuerdos de Pago',
                  subtitle: 'Fraccionamiento y convenios ("Sujeto a mejora")',
                  icon: Icons.handshake_rounded,
                  color: const Color(0xFFB45309),
                  onTap: () {
                    _navigateToSection(
                      1,
                      ParentPaymentsScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '4. Hacer Preguntas al Centro',
                  subtitle: 'Canal de comunicación con dirección y profesores',
                  icon: Icons.question_answer_rounded,
                  color: AppColors.electricBlue,
                  onTap: () {
                    _navigateToSection(
                      6,
                      ParentQuestionsScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '5. Gestionar Servicios',
                  subtitle: 'Cuido vespertino, rutas y comedor por hijo',
                  icon: Icons.child_care_rounded,
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    _navigateToSection(
                      2,
                      ParentServicesScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '6. Validar Comprobantes (NCF)',
                  subtitle: 'Descarga e impresión de facturas oficiales',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () {
                    _navigateToSection(
                      1,
                      ParentPaymentsScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '7. Eventos & Excursiones',
                  subtitle: 'Inscripción a campamentos, talleres y paseos',
                  icon: Icons.event_available_rounded,
                  color: const Color(0xFF0D9488),
                  onTap: () {
                    _navigateToSection(
                      4,
                      ParentEventsScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                        eventRepository: widget.eventRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '8. Asistencia & Justificaciones',
                  subtitle: 'Puntualidad en tiempo real y justificar inasistencias',
                  icon: Icons.fact_check_rounded,
                  color: const Color(0xFF059669),
                  onTap: () {
                    _navigateToSection(
                      5,
                      ParentAttendanceScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                        attendanceRepository: widget.attendanceRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '9. Circulares & Autorizaciones',
                  subtitle: 'Comunicados oficiales y firma digital de consentimientos',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFFC026D3),
                  onTap: () {
                    _navigateToSection(
                      7,
                      ParentCircularsScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                        circularRepository: widget.circularRepository,
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: '10. Boletín de Calificaciones',
                  subtitle: 'Récord oficial de notas, promedios y observaciones docentes',
                  icon: Icons.grade_rounded,
                  color: const Color(0xFFEAB308),
                  onTap: () {
                    _navigateToSection(
                      8,
                      ParentGradesScreen(
                        userProfile: widget.userProfile,
                        familyRepository: widget.familyRepository,
                        academicRepository: widget.academicRepository,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Mis Hijos Matriculados
            Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.navyPrimary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Mis Hijos Matriculados (${family.estudiantes.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isWide ? 1.22 : 1.3,
                  ),
                  itemCount: family.estudiantes.length,
                  itemBuilder: (context, index) {
                    final student = family.estudiantes[index];
                    return _buildChildCard(student);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(Student student) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                child: Text(
                  student.nombres.isNotEmpty ? student.nombres[0] : 'E',
                  style: const TextStyle(
                    color: AppColors.navyPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.gradoNombre ?? "Nivel Inicial"} • ${student.seccionNombre ?? "Sección A"} • Matrícula: ${student.matricula}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Servicios Contratados:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: student.serviciosActivos.isEmpty
                ? [
                    const Text(
                      'Sin servicios adicionales contratados.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    )
                  ]
                : student.serviciosActivos.map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    );
                  }).toList(),
          ),
          const Spacer(),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () {
                  _navigateToSection(
                    2,
                    ParentServicesScreen(
                      userProfile: widget.userProfile,
                      familyRepository: widget.familyRepository,
                    ),
                  );
                },
                icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                label: const Text('Gestionar Servicios'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _navigateToSection(
                    8,
                    ParentGradesScreen(
                      userProfile: widget.userProfile,
                      familyRepository: widget.familyRepository,
                      academicRepository: widget.academicRepository,
                    ),
                  );
                },
                icon: const Icon(Icons.grade_rounded, size: 16),
                label: const Text('Boletín de Notas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFEF3C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Generando carnet digital con código QR para ${student.nombres}'),
                      backgroundColor: AppColors.navyPrimary,
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_rounded, size: 16),
                label: const Text('Carnet Digital QR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
