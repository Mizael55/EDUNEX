import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../models/teacher_class.dart';
import '../models/teacher_evaluation.dart';
import '../models/student_behavior_log.dart';
import '../repositories/teacher_repository.dart';
import '../../academics/repositories/academic_repository.dart';
import '../../attendance/repositories/attendance_repository.dart';

/// Portal Exclusivo del Docente en EDUNEX
/// Integra: Libro de Clases, Calificador por Componentes, Asistencia y Observador Escolar
class TeacherPortalScreen extends StatefulWidget {
  final UserProfile userProfile;
  final TeacherRepository teacherRepository;
  final AcademicRepository academicRepository;
  final AttendanceRepository attendanceRepository;
  final int initialTabIndex;
  final Function(int)? onTabChanged;

  const TeacherPortalScreen({
    super.key,
    required this.userProfile,
    required this.teacherRepository,
    required this.academicRepository,
    required this.attendanceRepository,
    this.initialTabIndex = 0,
    this.onTabChanged,
  });

  @override
  State<TeacherPortalScreen> createState() => _TeacherPortalScreenState();
}

class _TeacherPortalScreenState extends State<TeacherPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TeacherClass> _classes = [];
  TeacherClass? _selectedClass;
  String _selectedPeriodo = 'P1';
  List<TeacherEvaluationItem> _evaluations = [];
  List<StudentBehaviorLog> _behaviorLogs = [];
  Map<String, double> _periodAverages = {};
  Map<String, String> _attendanceMap = {};
  DateTime _attendanceDate = DateTime.now();
  String _behaviorFilter = 'Todos';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onTabChanged?.call(_tabController.index);
        setState(() {});
      }
    });
    _loadTeacherData();
  }

  @override
  void didUpdateWidget(covariant TeacherPortalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex != _tabController.index) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 3));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    final classes = await widget.teacherRepository.getClasses(docenteId: widget.userProfile.id);
    _classes = classes.isNotEmpty ? classes : await widget.teacherRepository.getClasses();

    if (_classes.isNotEmpty) {
      _selectedClass = _classes.first;
      await _loadEvaluations();
      await _loadBehaviorLogs();
      _initAttendanceMap();
    }
    setState(() => _isLoading = false);
  }

  void _initAttendanceMap() {
    if (_selectedClass == null) return;
    _attendanceMap = {
      for (final s in _selectedClass!.estudiantes) s.id: 'Presente',
    };
  }

  Future<void> _loadEvaluations() async {
    if (_selectedClass == null) return;
    _evaluations = await widget.teacherRepository.getEvaluations(
      _selectedClass!.id,
      periodo: _selectedPeriodo,
    );
    _periodAverages = await widget.teacherRepository.calculatePeriodAverages(
      _selectedClass!.id,
      _selectedPeriodo,
    );
    setState(() {});
  }

  Future<void> _loadBehaviorLogs() async {
    if (_selectedClass == null) return;
    _behaviorLogs = await widget.teacherRepository.getBehaviorLogs(
      classId: _selectedClass!.id,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.navyPrimary),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Header Oficial del Portal Docente
          _buildHeader(isDesktop),

          // Pestañas Principales
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.navyPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.electricBlue,
              indicatorWeight: 3,
              isScrollable: !isDesktop,
              tabs: const [
                Tab(icon: Icon(Icons.auto_stories_rounded, size: 18), text: '1. Libro de Clases'),
                Tab(icon: Icon(Icons.grading_rounded, size: 18), text: '2. Calificador de Aula'),
                Tab(icon: Icon(Icons.fact_check_rounded, size: 18), text: '3. Pase de Lista'),
                Tab(icon: Icon(Icons.psychology_rounded, size: 18), text: '4. Observador & Convivencia'),
              ],
            ),
          ),

          // Contenido Dinámico por Pestaña
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClassesTab(isDesktop),
                _buildEvaluationsTab(isDesktop),
                _buildAttendanceTab(isDesktop),
                _buildBehaviorTab(isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header con Identidad del Docente y KPIs Resumen
  Widget _buildHeader(bool isDesktop) {
    final totalAlumnos = _classes.fold<int>(0, (prev, c) => prev + c.totalEstudiantes);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.navyPrimary,
        border: Border(bottom: BorderSide(color: AppColors.electricBlue, width: 2)),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Portal del Docente • ${widget.userProfile.nombreCompleto}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gestión pedagógica de aula, registro de notas MINERD y convivencia escolar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Selector de Asignatura Activa
              if (_classes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const Key('dropdown_selected_class'),
                      value: _selectedClass?.id,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.navyPrimary),
                      items: _classes.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.materia} • ${c.grado} (${c.seccion})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedClass = _classes.firstWhere((c) => c.id == val);
                            _initAttendanceMap();
                          });
                          _loadEvaluations();
                          _loadBehaviorLogs();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // KPIs Rápidos
          Row(
            children: [
              _buildMiniKpi(Icons.auto_stories_rounded, '${_classes.length}', 'Asignaturas'),
              const SizedBox(width: 10),
              _buildMiniKpi(Icons.people_alt_rounded, '$totalAlumnos', 'Alumnos en Aula'),
              const SizedBox(width: 10),
              _buildMiniKpi(Icons.assignment_turned_in_rounded, '${_evaluations.length}', 'Evaluaciones $_selectedPeriodo'),
              const SizedBox(width: 10),
              _buildMiniKpi(Icons.flag_rounded, '${_behaviorLogs.length}', 'Observaciones'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpi(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.electricBlue, size: 16),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PESTAÑA 1: LIBRO DE CLASES ====================
  Widget _buildClassesTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis Clases Asignadas & Horario Pedagógico',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                  ),
                  Text(
                    'Selecciona cualquier aula para consultar su nómina de estudiantes y datos de contacto.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('btn_ver_nomina_completa'),
                onPressed: _selectedClass != null ? () => _showRosterDialog(_selectedClass!) : null,
                icon: const Icon(Icons.people_rounded, size: 16),
                label: const Text('Ver Nómina de la Clase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grilla de Asignaturas Asignadas
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _classes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 180,
                ),
                itemBuilder: (context, index) {
                  final c = _classes[index];
                  final isSelected = _selectedClass?.id == c.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedClass = c;
                        _initAttendanceMap();
                      });
                      _loadEvaluations();
                      _loadBehaviorLogs();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.electricBlue : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(color: AppColors.electricBlue.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.navyPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.grado,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${c.totalEstudiantes} Alumnos',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            c.materia,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.slateGray),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${c.aula} • ${c.seccion}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.electricBlue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(c.horario, style: const TextStyle(fontSize: 11, color: AppColors.electricBlue, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== PESTAÑA 2: CALIFICADOR DE AULA ====================
  Widget _buildEvaluationsTab(bool isDesktop) {
    if (_selectedClass == null) {
      return const Center(child: Text('No hay asignaturas seleccionadas.'));
    }

    final totalWeight = _evaluations.fold<double>(0.0, (prev, e) => prev + e.porcentaje);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de Período y Acciones
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Período Académico:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'P1', label: Text('P1')),
                      ButtonSegment(value: 'P2', label: Text('P2')),
                      ButtonSegment(value: 'P3', label: Text('P3')),
                      ButtonSegment(value: 'P4', label: Text('P4')),
                    ],
                    selected: {_selectedPeriodo},
                    onSelectionChanged: (val) {
                      setState(() => _selectedPeriodo = val.first);
                      _loadEvaluations();
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                children: [
                  OutlinedButton.icon(
                    key: const Key('btn_add_evaluacion'),
                    onPressed: _showAddEvaluationModal,
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: const Text('Nueva Evaluación'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyPrimary,
                      side: const BorderSide(color: AppColors.navyPrimary),
                    ),
                  ),
                  ElevatedButton.icon(
                    key: const Key('btn_publicar_boletin'),
                    onPressed: _publishGradesToBoletin,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: const Text('Publicar al Boletín Oficial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ponderación Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: totalWeight == 100.0 ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: totalWeight == 100.0 ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Icon(
                  totalWeight == 100.0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: totalWeight == 100.0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ponderación Total en $_selectedPeriodo: ${totalWeight.toStringAsFixed(0)}% / 100% '
                    '(${_evaluations.length} componentes evaluativos registrados para ${_selectedClass!.materia})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: totalWeight == 100.0 ? const Color(0xFF14532D) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tabla de Calificaciones por Estudiante
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planilla de Calificaciones y Promedios:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: [
                        const DataColumn(label: Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(label: Text('Alumno', style: TextStyle(fontWeight: FontWeight.bold))),
                        ..._evaluations.map((e) => DataColumn(
                              label: Text('${e.titulo}\n(${e.porcentaje.toStringAsFixed(0)}%)',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            )),
                        DataColumn(label: Text('Promedio $_selectedPeriodo', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary))),
                        const DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _selectedClass!.estudiantes.map((s) {
                        final average = _periodAverages[s.id] ?? 0.0;
                        final isPassing = average >= 70.0;

                        return DataRow(
                          cells: [
                            DataCell(Text(s.matricula, style: const TextStyle(fontSize: 12, color: AppColors.slateGray))),
                            DataCell(Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600))),
                            ..._evaluations.map((e) {
                              final score = e.calificaciones[s.id] ?? 0.0;
                              return DataCell(
                                InkWell(
                                  onTap: () => _showEditScoreModal(e, s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: score >= 70 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: score >= 70 ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                                    ),
                                    child: Text(
                                      score.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: score >= 70 ? const Color(0xFF15803D) : Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPassing ? AppColors.navyPrimary.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  average.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPassing ? AppColors.navyPrimary : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                isPassing ? 'Aprobado' : 'En Riesgo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPassing ? const Color(0xFF16A34A) : Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PESTAÑA 3: PASE DE LISTA ====================
  Widget _buildAttendanceTab(bool isDesktop) {
    if (_selectedClass == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.navyPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Fecha de Clase: ${_attendanceDate.day}/${_attendanceDate.month}/${_attendanceDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('btn_guardar_asistencia_docente'),
                onPressed: _saveClassAttendance,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Registrar Asistencia de la Clase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedClass!.estudiantes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = _selectedClass!.estudiantes[index];
                final status = _attendanceMap[s.id] ?? 'Presente';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                        child: Text(s.nombres[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Matrícula: ${s.matricula} • Tutor: ${s.tutorNombre}',
                                style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                          ],
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Presente', label: Text('P', style: TextStyle(fontWeight: FontWeight.bold))),
                          ButtonSegment(value: 'Tardanza', label: Text('T', style: TextStyle(fontWeight: FontWeight.bold))),
                          ButtonSegment(value: 'Ausente', label: Text('A', style: TextStyle(fontWeight: FontWeight.bold))),
                          ButtonSegment(value: 'Excusa', label: Text('E', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        selected: {status},
                        onSelectionChanged: (val) {
                          setState(() {
                            _attendanceMap[s.id] = val.first;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PESTAÑA 4: OBSERVADOR Y CONVIVENCIA ====================
  Widget _buildBehaviorTab(bool isDesktop) {
    final filteredLogs = _behaviorLogs.where((l) {
      if (_behaviorFilter == 'Todos') return true;
      if (_behaviorFilter == 'Méritos' && l.esPositivo) return true;
      if (_behaviorFilter == 'Llamados' && !l.esPositivo && !l.esPsicologia) return true;
      if (_behaviorFilter == 'Psicología' && l.esPsicologia) return true;
      return false;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Filtro:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _behaviorFilter,
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos los Registros')),
                      DropdownMenuItem(value: 'Méritos', child: Text('Méritos & Felicitaciones')),
                      DropdownMenuItem(value: 'Llamados', child: Text('Llamados de Atención')),
                      DropdownMenuItem(value: 'Psicología', child: Text('Remisiones a Psicología')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _behaviorFilter = val);
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('btn_add_observacion_docente'),
                onPressed: _showAddBehaviorModal,
                icon: const Icon(Icons.add_comment_rounded, size: 16),
                label: const Text('+ Registrar Observación / Reporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (filteredLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No hay observaciones registradas con los filtros seleccionados.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                final isPositive = log.esPositivo;
                final isPsico = log.esPsicologia;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPositive
                          ? const Color(0xFF86EFAC)
                          : (isPsico ? const Color(0xFFC084FC) : const Color(0xFFFECACA)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.stars_rounded
                                    : (isPsico ? Icons.psychology_rounded : Icons.warning_amber_rounded),
                                color: isPositive
                                    ? const Color(0xFF16A34A)
                                    : (isPsico ? Colors.purple : Colors.redAccent),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Text('(${log.tipo})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isPositive
                                        ? const Color(0xFF16A34A)
                                        : (isPsico ? Colors.purple : Colors.redAccent),
                                  )),
                            ],
                          ),
                          Text(
                            '${log.fecha.day}/${log.fecha.month}/${log.fecha.year}',
                            style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(log.descripcion, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (log.notificadoTutor)
                            const Chip(
                              label: Text('Notificado a Familia', style: TextStyle(fontSize: 10)),
                              backgroundColor: Color(0xFFF1F5F9),
                              visualDensity: VisualDensity.compact,
                            ),
                          const SizedBox(width: 8),
                          if (log.notificadoPsicologia)
                            const Chip(
                              label: Text('Derivado a Psicología Escolar', style: TextStyle(fontSize: 10, color: Colors.purple)),
                              backgroundColor: Color(0xFFF3E8FF),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==================== MODALES Y ACCIONES ====================

  void _showRosterDialog(TeacherClass c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nómina de Estudiantes • ${c.identificadorCompleto}'),
        content: SizedBox(
          width: 500,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: c.estudiantes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = c.estudiantes[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Matrícula: ${s.matricula} • Tutor: ${s.tutorNombre} (${s.tutorTelefono})'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showAddEvaluationModal() {
    final titleCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '25');
    String type = 'Tarea';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nueva Evaluación Pedagógica'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('input_eval_title'),
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título de la Evaluación *', hintText: 'Ej. Quiz #2: Fracciones'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo de Componente'),
                  items: const [
                    DropdownMenuItem(value: 'Tarea', child: Text('Tarea / Práctica')),
                    DropdownMenuItem(value: 'Quiz', child: Text('Quiz / Prueba Corta')),
                    DropdownMenuItem(value: 'Proyecto', child: Text('Proyecto / Exposición')),
                    DropdownMenuItem(value: 'Examen', child: Text('Examen de Período')),
                    DropdownMenuItem(value: 'Participación', child: Text('Participación en Clase')),
                  ],
                  onChanged: (v) => setModalState(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('input_eval_weight'),
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ponderación (%) *', suffixText: '%'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('btn_submit_eval'),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final weight = double.tryParse(weightCtrl.text) ?? 20.0;
                await widget.teacherRepository.createEvaluation(
                  classId: _selectedClass!.id,
                  periodo: _selectedPeriodo,
                  titulo: titleCtrl.text.trim(),
                  tipo: type,
                  porcentaje: weight,
                  fecha: DateTime.now(),
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                await _loadEvaluations();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evaluación creada exitosamente.')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditScoreModal(TeacherEvaluationItem eval, ClassStudent student) {
    final currentScore = eval.calificaciones[student.id] ?? 0.0;
    final scoreCtrl = TextEditingController(text: currentScore.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Calificar: ${eval.titulo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alumno: ${student.nombreCompleto}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calificación (0 - 100) *', suffixText: 'pts'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final newScore = double.tryParse(scoreCtrl.text) ?? 0.0;
              await widget.teacherRepository.saveStudentScores(eval.id, {student.id: newScore});
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              await _loadEvaluations();
            },
            child: const Text('Actualizar Nota'),
          ),
        ],
      ),
    );
  }

  void _publishGradesToBoletin() async {
    if (_selectedClass == null) return;
    await widget.teacherRepository.publishPeriodGradesToAcademic(
      classId: _selectedClass!.id,
      periodo: _selectedPeriodo,
      academicRepo: widget.academicRepository,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Calificaciones de ${_selectedClass!.materia} publicadas oficialmente al Boletín del período $_selectedPeriodo!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void _saveClassAttendance() async {
    if (_selectedClass == null) return;
    await widget.teacherRepository.recordClassAttendance(
      classId: _selectedClass!.id,
      fecha: _attendanceDate,
      statuses: _attendanceMap,
      attendanceRepo: widget.attendanceRepository,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Asistencia de ${_selectedClass!.materia} registrada con éxito!'),
        backgroundColor: AppColors.navyPrimary,
      ),
    );
  }

  void _showAddBehaviorModal() {
    if (_selectedClass == null) return;
    ClassStudent selectedStudent = _selectedClass!.estudiantes.first;
    String tipo = 'Mérito / Felicitación';
    String categoria = 'Académico';
    final descCtrl = TextEditingController();
    bool notifTutor = true;
    bool notifPsico = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar en Observador del Alumno'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedStudent.id,
                    decoration: const InputDecoration(labelText: 'Estudiante *'),
                    items: _selectedClass!.estudiantes.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.nombreCompleto));
                    }).toList(),
                    onChanged: (v) {
                      setModalState(() {
                        selectedStudent = _selectedClass!.estudiantes.firstWhere((s) => s.id == v);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo de Incidencia / Nota'),
                    items: const [
                      DropdownMenuItem(value: 'Mérito / Felicitación', child: Text('Mérito / Felicitación')),
                      DropdownMenuItem(value: 'Llamado de Atención Leve', child: Text('Llamado de Atención Leve')),
                      DropdownMenuItem(value: 'Falta Grave de Convivencia', child: Text('Falta Grave de Convivencia')),
                      DropdownMenuItem(value: 'Remisión a Psicología', child: Text('Remisión a Psicología Escolar')),
                    ],
                    onChanged: (v) {
                      setModalState(() {
                        tipo = v!;
                        if (tipo.contains('Psicología')) notifPsico = true;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('input_behavior_desc'),
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de los Hechos *',
                      hintText: 'Detalla lo ocurrido de manera objetiva...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: notifTutor,
                    title: const Text('Notificar a los padres / tutor familiar', style: TextStyle(fontSize: 12)),
                    onChanged: (v) => setModalState(() => notifTutor = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: notifPsico,
                    title: const Text('Remitir copia a Orientación / Psicología', style: TextStyle(fontSize: 12)),
                    onChanged: (v) => setModalState(() => notifPsico = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('btn_submit_behavior'),
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) return;
                await widget.teacherRepository.addBehaviorLog(
                  classId: _selectedClass!.id,
                  studentId: selectedStudent.id,
                  studentName: selectedStudent.nombreCompleto,
                  grado: _selectedClass!.grado,
                  docenteId: widget.userProfile.id,
                  docenteNombre: widget.userProfile.nombreCompleto,
                  tipo: tipo,
                  categoria: categoria,
                  descripcion: descCtrl.text.trim(),
                  notificadoTutor: notifTutor,
                  notificadoPsicologia: notifPsico,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                await _loadBehaviorLogs();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Observación guardada y notificada.')),
                );
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
