import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/models/student.dart';
import '../../families/repositories/family_repository.dart';
import '../../academics/models/grade_report.dart';
import '../../academics/repositories/academic_repository.dart';

class ParentGradesScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;
  final AcademicRepository? academicRepository;

  const ParentGradesScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
    this.academicRepository,
  });

  @override
  State<ParentGradesScreen> createState() => _ParentGradesScreenState();
}

class _ParentGradesScreenState extends State<ParentGradesScreen> {
  late final AcademicRepository _academicRepo;
  Family? _family;
  Student? _selectedStudent;
  StudentGradeReport? _gradeReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _academicRepo = widget.academicRepository ?? AcademicRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fam = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );

      Student? activeStudent = _selectedStudent;
      if (activeStudent == null && fam != null && fam.estudiantes.isNotEmpty) {
        activeStudent = fam.estudiantes.first;
      }

      StudentGradeReport? report;
      if (activeStudent != null) {
        report = await _academicRepo.getReportForStudent(activeStudent.id);
      }

      if (mounted) {
        setState(() {
          _family = fam;
          _selectedStudent = activeStudent;
          _gradeReport = report;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchStudent(Student student) async {
    setState(() {
      _selectedStudent = student;
      _isLoading = true;
    });
    final report = await _academicRepo.getReportForStudent(student.id);
    if (mounted) {
      setState(() {
        _gradeReport = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = _family;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Principal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PORTAL ACADÉMICO FAMILIAR',
                              style: TextStyle(
                                color: AppColors.electricBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Evaluaciones & Récord Oficial', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Boletín de Calificaciones Oficial',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Consulta el progreso bimestral, promedios ponderados y observaciones pedagógicas docentes.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generando Boletín Oficial en formato PDF de alta resolución...'),
                        backgroundColor: AppColors.navyPrimary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Descargar Boletín (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyPrimary,
                    side: const BorderSide(color: AppColors.navyPrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Selector de Estudiante (Si la familia tiene más de un hijo)
            if (family != null && family.estudiantes.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: family.estudiantes.map((st) {
                    final isSelected = _selectedStudent?.id == st.id;
                    return Expanded(
                      child: InkWell(
                        onTap: () => _switchStudent(st),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: isSelected ? AppColors.navyPrimary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${st.nombres} (${st.gradoNombre ?? "General"})',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.navyPrimary : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_gradeReport == null)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 40, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(
                      'No hay calificaciones registradas aún para ${_selectedStudent?.nombres ?? "este estudiante"}.',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text('El equipo docente publicará las notas al cierre del período evaluativo.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              _buildReportCardView(_gradeReport!),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCardView(StudentGradeReport report) {
    final prom = report.promedioGeneral;
    final promColor = prom >= 90
        ? AppColors.accentGreen
        : prom >= 70
            ? AppColors.electricBlue
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Identidad Institucional
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navyPrimary, AppColors.electricBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COLEGIO BILINGÜE NUEVO HORIZONTE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estudiante: ${report.studentName} • Matrícula: ${report.matricula}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${report.grado} • ${report.seccion} • Año Escolar: ${report.anioEscolar}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (report.honorRoll) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech_rounded, color: Color(0xFFB45309), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Cuadro de Honor',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Resumen de Métricas del Alumno
          Row(
            children: [
              Expanded(
                child: _statPill(
                  title: 'Promedio General',
                  value: '${prom.toStringAsFixed(1)} / 100',
                  color: promColor,
                  icon: Icons.grade_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statPill(
                  title: 'Estatus del Curso',
                  value: report.estatusFinal,
                  color: AppColors.accentGreen,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statPill(
                  title: 'Conducta & Disciplina',
                  value: report.calificacionConducta,
                  color: AppColors.electricBlue,
                  icon: Icons.verified_user_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tabla de Asignaturas & Calificaciones
          const Text(
            'Calificaciones Bimestrales por Asignatura:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyPrimary),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // Encabezado de la tabla
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('ASIGNATURA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        SizedBox(width: 45, child: Text('P1', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        SizedBox(width: 45, child: Text('P2', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        SizedBox(width: 45, child: Text('P3', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        SizedBox(width: 45, child: Text('P4', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        SizedBox(width: 65, child: Text('PROM', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        SizedBox(width: 110, child: Text('ESTADO', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Filas de asignaturas
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: report.materias.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final m = report.materias[index];
                      final pCol = m.promedio >= 90
                          ? AppColors.accentGreen
                          : m.promedio >= 70
                              ? AppColors.navyPrimary
                              : const Color(0xFFDC2626);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.materia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                  Text(m.docente, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            _scoreBox(m.periodo1),
                            _scoreBox(m.periodo2),
                            _scoreBox(m.periodo3),
                            _scoreBox(m.periodo4),
                            SizedBox(
                              width: 65,
                              child: Text(
                                m.promedio > 0 ? m.promedio.toStringAsFixed(1) : '--',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: pCol),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pCol.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  m.estado,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: pCol),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Observaciones Pedagógicas Docentes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rate_review_rounded, color: AppColors.navyPrimary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Observaciones del Tutor Docente:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.observacionesDocente,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(int? score) {
    return SizedBox(
      width: 45,
      child: Text(
        score != null ? '$score' : '--',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
