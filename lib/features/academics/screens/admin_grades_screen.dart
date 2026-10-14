import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/grade_report.dart';
import '../repositories/academic_repository.dart';

class AdminGradesScreen extends StatefulWidget {
  final AcademicRepository academicRepository;

  const AdminGradesScreen({
    super.key,
    required this.academicRepository,
  });

  @override
  State<AdminGradesScreen> createState() => _AdminGradesScreenState();
}

class _AdminGradesScreenState extends State<AdminGradesScreen> {
  String _selectedGrado = 'Todos los Grados';
  List<StudentGradeReport> _reports = [];
  bool _isLoading = true;

  final List<String> _grados = [
    'Todos los Grados',
    '1ro de Primaria',
    'Kinder',
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final gradoFilter = _selectedGrado == 'Todos los Grados' ? null : _selectedGrado;
    final list = await widget.academicRepository.getReports(grado: gradoFilter);
    if (mounted) {
      setState(() {
        _reports = list;
        _isLoading = false;
      });
    }
  }

  void _openGradeEntry(StudentGradeReport report) {
    showDialog(
      context: context,
      builder: (_) => _GradeEntryDialog(
        report: report,
        repository: widget.academicRepository,
        onSaved: _loadReports,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.academicRepository.getAcademicMetrics();

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
                              'REGISTRO & EVALUACIÓN ACADÉMICA',
                              style: TextStyle(
                                color: AppColors.electricBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Currículo & Calificaciones MINERD', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Control Académico & Boletín de Notas',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Administra las calificaciones por período, promedios ponderados y emisión de récords de notas por estudiante.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4 Tarjetas de Métricas Académicas
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final crossAxisCount = isWide ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isWide ? 2.0 : 2.2,
                  children: [
                    _buildMetricCard(
                      title: 'Promedio General',
                      amount: '${(metrics['promedioGeneral'] as double).toStringAsFixed(1)} / 100',
                      subtitle: 'Rendimiento global del centro',
                      icon: Icons.grade_rounded,
                      color: AppColors.electricBlue,
                    ),
                    _buildMetricCard(
                      title: 'Tasa de Aprobación',
                      amount: '${(metrics['tasaAprobacion'] as double).toStringAsFixed(1)}%',
                      subtitle: '${metrics['totalEvaluados']} estudiantes evaluados',
                      icon: Icons.verified_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildMetricCard(
                      title: 'Cuadro de Honor',
                      amount: '${metrics['cuadroHonorCount']} Alumnos',
                      subtitle: 'Promedio superior a 90 pts',
                      icon: Icons.military_tech_rounded,
                      color: const Color(0xFFD97706),
                    ),
                    _buildMetricCard(
                      title: 'En Reforzamiento',
                      amount: '${metrics['reforzamientoCount']} Alumnos',
                      subtitle: 'Materias con promedio < 70',
                      icon: Icons.psychology_rounded,
                      color: const Color(0xFFDC2626),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Filtros y Tabla de Estudiantes
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.navyPrimary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Récord de Calificaciones por Estudiante',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                      ),
                      const Spacer(),
                      // Filtro de Grado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGrado,
                            style: const TextStyle(fontSize: 13, color: AppColors.navyPrimary, fontWeight: FontWeight.w600),
                            items: _grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGrado = val);
                                _loadReports();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (_reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No hay estudiantes en el grado seleccionado.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reports.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final r = _reports[index];
                        final prom = r.promedioGeneral;
                        final promColor = prom >= 90
                            ? AppColors.accentGreen
                            : prom >= 70
                                ? AppColors.electricBlue
                                : const Color(0xFFDC2626);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                                child: Text(
                                  r.studentName.isNotEmpty ? r.studentName[0] : 'E',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          r.studentName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                        ),
                                        if (r.honorRoll) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star_rounded, size: 12, color: Color(0xFFB45309)),
                                                SizedBox(width: 2),
                                                Text('Honor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${r.grado} • ${r.seccion} • Matrícula: ${r.matricula}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Conducta: ${r.calificacionConducta}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('${r.materias.length} materias evaluadas', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${prom.toStringAsFixed(1)} pts',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: promColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: promColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r.estatusFinal,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: promColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _openGradeEntry(r),
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Ver / Calificar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navyPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _GradeEntryDialog extends StatefulWidget {
  final StudentGradeReport report;
  final AcademicRepository repository;
  final VoidCallback onSaved;

  const _GradeEntryDialog({
    required this.report,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<_GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends State<_GradeEntryDialog> {
  late StudentGradeReport _currentReport;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  void _editGrade(SubjectGrade m, int periodo, int? currentVal) {
    final controller = TextEditingController(text: currentVal?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Calificar P$periodo - ${m.materia}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa una calificación entre 0 y 100:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 0 && val <= 100) {
                await widget.repository.updateSubjectGrade(
                  reportId: _currentReport.id,
                  materia: m.materia,
                  periodo: periodo,
                  nota: val,
                );
                final updated = await widget.repository.getReportForStudent(_currentReport.studentId);
                if (mounted && updated != null) {
                  setState(() => _currentReport = updated);
                }
                widget.onSaved();
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                    child: const Icon(Icons.school_rounded, color: AppColors.navyPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentReport.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyPrimary),
                        ),
                        Text(
                          '${_currentReport.grado} • ${_currentReport.seccion} • Año: ${_currentReport.anioEscolar} • Matrícula: ${_currentReport.matricula}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Promedio: ${_currentReport.promedioGeneral.toStringAsFixed(1)} / 100',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              const Text(
                'Desglose por Asignaturas & Períodos Bimestrales:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _currentReport.materias.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = _currentReport.materias[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.materia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(m.docente, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          _periodBadge(context, 'P1', m.periodo1, () => _editGrade(m, 1, m.periodo1)),
                          const SizedBox(width: 6),
                          _periodBadge(context, 'P2', m.periodo2, () => _editGrade(m, 2, m.periodo2)),
                          const SizedBox(width: 6),
                          _periodBadge(context, 'P3', m.periodo3, () => _editGrade(m, 3, m.periodo3)),
                          const SizedBox(width: 6),
                          _periodBadge(context, 'P4', m.periodo4, () => _editGrade(m, 4, m.periodo4)),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.promedio > 0 ? '${m.promedio.toStringAsFixed(1)}' : '--',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: m.promedio >= 70 ? AppColors.navyPrimary : const Color(0xFFDC2626),
                                  ),
                                ),
                                Text(m.estado, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.navyPrimary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Observaciones: ${_currentReport.observacionesDocente}',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary, foregroundColor: Colors.white),
                  child: const Text('Listo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodBadge(BuildContext context, String label, int? score, VoidCallback onTap) {
    final hasScore = score != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: hasScore ? AppColors.electricBlue.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: hasScore ? AppColors.electricBlue.withValues(alpha: 0.3) : const Color(0xFFCBD5E1)),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(
              hasScore ? '$score' : '--',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasScore ? AppColors.navyPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
