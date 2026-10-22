import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/academic_models.dart';
import '../models/grade_report.dart';
import '../repositories/academic_repository.dart';

/// Pantalla Integral de Gestión Académica EDUNEX (Issue #20)
/// Administra Boletines, Cursos, Secciones, Estudiantes, Profesores, Asignaciones y Materias
class AdminGradesScreen extends StatefulWidget {
  final AcademicRepository academicRepository;
  final String colegioId;

  const AdminGradesScreen({
    super.key,
    required this.academicRepository,
    this.colegioId = 'col-1',
  });

  @override
  State<AdminGradesScreen> createState() => _AdminGradesScreenState();
}

class _AdminGradesScreenState extends State<AdminGradesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Datos en memoria
  List<AcademicCourse> _courses = [];
  List<AcademicSection> _sections = [];
  List<AcademicSubject> _subjects = [];
  List<AcademicTeacher> _teachers = [];
  List<TeacherAcademicAssignment> _assignments = [];
  List<StudentEnrollment> _enrollments = [];
  List<StudentGradeReport> _reports = [];

  // Filtros
  String _selectedGrado = 'Todos los Grados';
  String _searchEstudiante = '';

  final List<String> _grados = [
    'Todos los Grados',
    '1ro de Primaria',
    'Kinder',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final gradoFilter = _selectedGrado == 'Todos los Grados' ? null : _selectedGrado;
    final reports = await widget.academicRepository.getReports(grado: gradoFilter);
    final courses = await widget.academicRepository.getCourses(colegioId: widget.colegioId);
    final sections = await widget.academicRepository.getSections(colegioId: widget.colegioId);
    final subjects = await widget.academicRepository.getSubjects(colegioId: widget.colegioId);
    final teachers = await widget.academicRepository.getTeachers(colegioId: widget.colegioId);
    final assignments = await widget.academicRepository.getTeacherAssignments(colegioId: widget.colegioId);
    final enrollments = await widget.academicRepository.getEnrollments(colegioId: widget.colegioId);

    if (mounted) {
      setState(() {
        _reports = reports;
        _courses = courses;
        _sections = sections;
        _subjects = subjects;
        _teachers = teachers;
        _assignments = assignments;
        _enrollments = enrollments;
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // MODALES: CURSOS Y SECCIONES (Issue #20)
  // =========================================================
  void _showCreateCourseDialog() {
    final nombreCtrl = TextEditingController();
    String nivel = 'Primaria';
    final anioCtrl = TextEditingController(text: '2025-2026');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.school_rounded, color: AppColors.navyPrimary),
              SizedBox(width: 8),
              Text('Crear Nuevo Curso / Grado'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('input_course_name'),
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Curso *',
                    hintText: 'Ej. 3ro de Primaria',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: nivel,
                  decoration: const InputDecoration(
                    labelText: 'Nivel Académico',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Inicial', child: Text('Inicial / Parvularia')),
                    DropdownMenuItem(value: 'Primaria', child: Text('Primaria')),
                    DropdownMenuItem(value: 'Secundaria', child: Text('Secundaria')),
                  ],
                  onChanged: (v) => setDialogState(() => nivel = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: anioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Año Escolar',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              key: const Key('btn_save_course'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty) return;
                await widget.academicRepository.createCourse(
                  colegioId: widget.colegioId,
                  nombre: nombreCtrl.text.trim(),
                  nivel: nivel,
                  anioEscolar: anioCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadAllData();
              },
              child: const Text('Guardar Curso', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSectionDialog({AcademicCourse? preselectedCourse}) {
    String selectedCursoId = preselectedCourse?.id ?? (_courses.isNotEmpty ? _courses.first.id : '');
    final nombreCtrl = TextEditingController(text: 'Sección ');
    final capacidadCtrl = TextEditingController(text: '30');
    final aulaCtrl = TextEditingController(text: 'Aula ');
    String? selectedProfesorId = _teachers.isNotEmpty ? _teachers.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cur = _courses.firstWhere(
            (c) => c.id == selectedCursoId,
            orElse: () => _courses.isNotEmpty
                ? _courses.first
                : const AcademicCourse(id: '', colegioId: '', nombre: '', nivel: '', anioEscolar: ''),
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.meeting_room_rounded, color: AppColors.navyPrimary),
                SizedBox(width: 8),
                Text('Crear Nueva Sección'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('select_course_for_section'),
                    value: selectedCursoId.isNotEmpty ? selectedCursoId : null,
                    decoration: const InputDecoration(
                      labelText: 'Curso / Grado Académico *',
                      border: OutlineInputBorder(),
                    ),
                    items: _courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                    onChanged: (v) => setDialogState(() => selectedCursoId = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input_section_name'),
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Sección *',
                      hintText: 'Ej. Sección C',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('input_section_capacity'),
                          controller: capacidadCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capacidad de Alumnos *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: aulaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Aula / Ubicación',
                            hintText: 'Ej. Aula 103',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedProfesorId,
                    decoration: const InputDecoration(
                      labelText: 'Profesor Titular / Guía',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                      ..._teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombreCompleto))),
                    ],
                    onChanged: (v) => setDialogState(() => selectedProfesorId = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                key: const Key('btn_save_section'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  final cap = int.tryParse(capacidadCtrl.text.trim()) ?? 30;
                  final prof = _teachers.where((t) => t.id == selectedProfesorId).firstOrNull;

                  await widget.academicRepository.createSection(
                    colegioId: widget.colegioId,
                    cursoId: cur.id,
                    cursoNombre: cur.nombre,
                    nombre: nombreCtrl.text.trim(),
                    anioEscolar: cur.anioEscolar,
                    capacidadEstudiantes: cap,
                    aula: aulaCtrl.text.trim(),
                    profesorTitularId: prof?.id,
                    profesorTitularNombre: prof?.nombreCompleto,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _loadAllData();
                },
                child: const Text('Guardar Sección', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // MODALES: ESTUDIANTES Y TRASLADOS (Issue #20)
  // =========================================================
  void _showEnrollStudentDialog() {
    final nombreCtrl = TextEditingController();
    final matriculaCtrl = TextEditingController(text: 'EST-2026-${_enrollments.length + 1}');
    String? selectedCursoId = _courses.isNotEmpty ? _courses.first.id : null;
    String? selectedSeccionId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final seccionesDelCurso = _sections.where((s) => s.cursoId == selectedCursoId).toList();
          if (selectedSeccionId == null && seccionesDelCurso.isNotEmpty) {
            selectedSeccionId = seccionesDelCurso.first.id;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: AppColors.navyPrimary),
                SizedBox(width: 8),
                Text('Matricular & Asignar Estudiante'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('input_enroll_student_name'),
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y Apellidos del Estudiante *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: matriculaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número de Matrícula / RNE *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('select_enroll_course'),
                    value: selectedCursoId,
                    decoration: const InputDecoration(
                      labelText: 'Curso Asignado *',
                      border: OutlineInputBorder(),
                    ),
                    items: _courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedCursoId = v;
                        final newSecs = _sections.where((s) => s.cursoId == v).toList();
                        selectedSeccionId = newSecs.isNotEmpty ? newSecs.first.id : null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('select_enroll_section'),
                    value: selectedSeccionId,
                    decoration: const InputDecoration(
                      labelText: 'Sección Asignada *',
                      border: OutlineInputBorder(),
                    ),
                    items: seccionesDelCurso
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.nombre} (${s.aula ?? "Sin aula"})'),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedSeccionId = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                key: const Key('btn_confirm_enroll'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty || selectedCursoId == null || selectedSeccionId == null) {
                    return;
                  }
                  final cur = _courses.firstWhere((c) => c.id == selectedCursoId);
                  final sec = _sections.firstWhere((s) => s.id == selectedSeccionId);

                  await widget.academicRepository.enrollStudent(
                    colegioId: widget.colegioId,
                    estudianteId: 'est-${DateTime.now().millisecondsSinceEpoch}',
                    estudianteNombre: nombreCtrl.text.trim(),
                    matricula: matriculaCtrl.text.trim(),
                    cursoId: cur.id,
                    cursoNombre: cur.nombre,
                    seccionId: sec.id,
                    seccionNombre: sec.nombre,
                    anioEscolar: cur.anioEscolar,
                  );

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _loadAllData();
                },
                child: const Text('Completar Matrícula', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTransferDialog(StudentEnrollment enrollment) {
    final otrasSecciones = _sections.where((s) => s.id != enrollment.seccionId).toList();
    String? selectedNuevaSeccionId = otrasSecciones.isNotEmpty ? otrasSecciones.first.id : null;
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: AppColors.electricBlue),
              SizedBox(width: 8),
              Text('Trasladar Estudiante de Sección'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estudiante: ${enrollment.estudianteNombre}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Ubicación actual: ${enrollment.cursoNombre} - ${enrollment.seccionNombre}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('select_new_section_transfer'),
                  value: selectedNuevaSeccionId,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Sección de Destino *',
                    border: OutlineInputBorder(),
                  ),
                  items: otrasSecciones
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.cursoNombre} - ${s.nombre} (Cupo: ${s.capacidadEstudiantes})'),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedNuevaSeccionId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('input_transfer_reason'),
                  controller: motivoCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del Traslado *',
                    hintText: 'Ej. Rebalanceo de cupo escolar / Solicitud familiar',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_transfer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
              onPressed: () async {
                if (selectedNuevaSeccionId == null || motivoCtrl.text.trim().isEmpty) return;
                final secDestino = _sections.firstWhere((s) => s.id == selectedNuevaSeccionId);

                await widget.academicRepository.transferStudentSection(
                  enrollmentId: enrollment.id,
                  nuevaSeccionId: secDestino.id,
                  nuevaSeccionNombre: secDestino.nombre,
                  motivo: motivoCtrl.text.trim(),
                  usuarioResponsable: 'Director Académico',
                );

                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadAllData();
              },
              child: const Text('Confirmar Traslado', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferHistoryDialog(StudentEnrollment enrollment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.navyPrimary),
            const SizedBox(width: 8),
            Text('Historial de Traslados: ${enrollment.estudianteNombre}'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: enrollment.historialTraslados.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Este estudiante no registra traslados previos. Permanece en su sección original de matrícula.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: enrollment.historialTraslados.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, idx) {
                    final t = enrollment.historialTraslados[idx];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.change_circle_outlined, color: AppColors.electricBlue),
                      title: Text(
                        'De ${t.seccionAnterior} ➔ ${t.seccionNueva}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Motivo: ${t.motivo}\nFecha: ${t.fecha.day}/${t.fecha.month}/${t.fecha.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MODALES: PROFESORES Y ASIGNACIONES (Issue #20)
  // =========================================================
  void _showCreateTeacherDialog() {
    final nombreCtrl = TextEditingController();
    final cedulaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final espCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.badge_rounded, color: AppColors.navyPrimary),
            SizedBox(width: 8),
            Text('Crear Perfil de Profesor'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('input_teacher_name'),
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Completo *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('input_teacher_cedula'),
                controller: cedulaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Cédula de Identidad *', hintText: '001-0000000-0', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: telCtrl,
                      decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('input_teacher_specialty'),
                controller: espCtrl,
                decoration: const InputDecoration(
                  labelText: 'Especialidad Docente / Área *',
                  hintText: 'Ej. Matemáticas & Física',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            key: const Key('btn_save_teacher'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty || cedulaCtrl.text.trim().isEmpty) return;
              await widget.academicRepository.createTeacher(
                colegioId: widget.colegioId,
                nombreCompleto: nombreCtrl.text.trim(),
                cedula: cedulaCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                telefono: telCtrl.text.trim(),
                especialidad: espCtrl.text.trim().isEmpty ? 'General' : espCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
              _loadAllData();
            },
            child: const Text('Guardar Profesor', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    String? selectedProfesorId = _teachers.isNotEmpty ? _teachers.first.id : null;
    String? selectedMateriaId = _subjects.isNotEmpty ? _subjects.first.id : null;
    String? selectedSeccionId = _sections.isNotEmpty ? _sections.first.id : null;
    final horarioCtrl = TextEditingController(text: 'Lunes a Viernes 8:00 - 9:00 AM');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.assignment_ind_rounded, color: AppColors.navyPrimary),
              SizedBox(width: 8),
              Text('Nueva Asignación Académica Docente'),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('select_assignment_teacher'),
                  value: selectedProfesorId,
                  decoration: const InputDecoration(labelText: 'Profesor *', border: OutlineInputBorder()),
                  items: _teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombreCompleto))).toList(),
                  onChanged: (v) => setDialogState(() => selectedProfesorId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('select_assignment_subject'),
                  value: selectedMateriaId,
                  decoration: const InputDecoration(labelText: 'Materia *', border: OutlineInputBorder()),
                  items: _subjects.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
                  onChanged: (v) => setDialogState(() => selectedMateriaId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('select_assignment_section'),
                  value: selectedSeccionId,
                  decoration: const InputDecoration(labelText: 'Curso & Sección *', border: OutlineInputBorder()),
                  items: _sections
                      .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.cursoNombre} - ${s.nombre}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedSeccionId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: horarioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Horario Semanal',
                    hintText: 'Ej. Lunes y Miércoles 8:00 - 9:30 AM',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('btn_confirm_assignment'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
              onPressed: () async {
                if (selectedProfesorId == null || selectedMateriaId == null || selectedSeccionId == null) {
                  return;
                }
                final sec = _sections.firstWhere((s) => s.id == selectedSeccionId);

                try {
                  await widget.academicRepository.assignTeacherToSubjectAndSection(
                    colegioId: widget.colegioId,
                    profesorId: selectedProfesorId!,
                    materiaId: selectedMateriaId!,
                    cursoId: sec.cursoId,
                    seccionId: sec.id,
                    anioEscolar: sec.anioEscolar,
                    horarioSemanal: horarioCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _loadAllData();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Asignar Materia', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MODALES: MATERIAS (Issue #20)
  // =========================================================
  void _showCreateSubjectDialog() {
    final nombreCtrl = TextEditingController();
    final codigoCtrl = TextEditingController(text: 'MAT-10${_subjects.length + 1}');
    final horasCtrl = TextEditingController(text: '4');
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.navyPrimary),
            SizedBox(width: 8),
            Text('Registrar Nueva Materia'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('input_subject_name'),
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la Asignatura *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codigoCtrl,
                      decoration: const InputDecoration(labelText: 'Código MINERD', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: horasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Horas / Semana', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción Curricular', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            key: const Key('btn_save_subject'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;
              await widget.academicRepository.createSubject(
                colegioId: widget.colegioId,
                nombre: nombreCtrl.text.trim(),
                codigo: codigoCtrl.text.trim(),
                horasSemanales: int.tryParse(horasCtrl.text.trim()) ?? 4,
                descripcion: descCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
              _loadAllData();
            },
            child: const Text('Guardar Materia', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openGradeEntry(StudentGradeReport report) {
    showDialog(
      context: context,
      builder: (_) => _GradeEntryDialog(
        report: report,
        repository: widget.academicRepository,
        onSaved: _loadAllData,
      ),
    );
  }

  // =========================================================
  // BUILD PRINCIPAL
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header Principal con Título Oficial y Acciones Rápidas
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isWide ? 650 : constraints.maxWidth),
                          child: Column(
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
                                  const Text(
                                    'Currículo & Calificaciones MINERD',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
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
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              key: const Key('btn_quick_create_course'),
                              onPressed: _showCreateCourseDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Nuevo Curso'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyPrimary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key('btn_quick_enroll_student'),
                              onPressed: _showEnrollStudentDialog,
                              icon: const Icon(Icons.person_add_rounded, size: 16),
                              label: const Text('Matricular Alumno'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // TabBar de Navegación del Módulo Integral
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.navyPrimary,
                  unselectedLabelColor: AppColors.slateGray,
                  indicatorColor: AppColors.electricBlue,
                  indicatorWeight: 3,
                  tabs: [
                    const Tab(
                      icon: Icon(Icons.grade_rounded, size: 18),
                      text: '1. Boletines & Calificaciones',
                    ),
                    const Tab(
                      icon: Icon(Icons.analytics_rounded, size: 18),
                      text: '2. Panel Académico & Aulas',
                    ),
                    Tab(
                      icon: const Icon(Icons.school_rounded, size: 18),
                      text: '3. Cursos & Secciones (${_courses.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.people_alt_rounded, size: 18),
                      text: '4. Estudiantes & Matrícula (${_enrollments.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.badge_rounded, size: 18),
                      text: '5. Profesores & Asignaciones (${_teachers.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      text: '6. Materias Curriculares (${_subjects.length})',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido de las pestañas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGradeReportsAndKpisTab(),
                      _buildDashboardTab(),
                      _buildCoursesTab(),
                      _buildStudentsTab(),
                      _buildTeachersTab(),
                      _buildSubjectsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 1: BOLETINES & CALIFICACIONES (MINERD)
  // Preserva 100% de los elementos de widget_test.dart
  // =========================================================
  Widget _buildGradeReportsAndKpisTab() {
    final metrics = widget.academicRepository.getAcademicMetrics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Tarjetas de Métricas Académicas Oficiales
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
                              _loadAllData();
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
                if (_reports.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay estudiantes en este grado.')))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reports.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final r = _reports[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                              child: Text(
                                r.studentName.isNotEmpty ? r.studentName[0] : 'E',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                                  ),
                                  Text(
                                    '${r.grado} • ${r.seccion} • Mat: ${r.matricula}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: r.promedioGeneral >= 70
                                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                                    : const Color(0xFFDC2626).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Promedio: ${r.promedioGeneral.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: r.promedioGeneral >= 70 ? const Color(0xFF166534) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _openGradeEntry(r),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Ver / Calificar'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 2: PANEL DE CONTROL ACADÉMICO & AULAS (Issue #20)
  // =========================================================
  Widget _buildDashboardTab() {
    final metrics = widget.academicRepository.getAcademicDashboardMetrics(colegioId: widget.colegioId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              _buildKpiCard('Cursos Habilitados', metrics.totalCursos.toString(), Icons.school_rounded, const Color(0xFF2563EB)),
              _buildKpiCard('Secciones / Aulas', metrics.totalSecciones.toString(), Icons.meeting_room_rounded, const Color(0xFF0D9488)),
              _buildKpiCard('Matrícula Activa', metrics.totalEstudiantesMatriculados.toString(), Icons.people_rounded, const Color(0xFF10B981)),
              _buildKpiCard('Planta Docente', metrics.totalProfesores.toString(), Icons.badge_rounded, const Color(0xFF8B5CF6)),
              _buildKpiCard('Materias Curriculares', metrics.totalMaterias.toString(), Icons.menu_book_rounded, const Color(0xFFF59E0B)),
              _buildKpiCard('Promedio Alumnos/Aula', '${metrics.promedioEstudiantesPorAula}', Icons.groups_rounded, const Color(0xFFEC4899)),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribución de Estudiantes por Curso & Capacidad de Aulas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Control en tiempo real de ocupación de aulas según la normativa MINERD.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ...metrics.estudiantesPorCurso.entries.map((entry) {
                    final cursoNombre = entry.key;
                    final inscritos = entry.value;
                    final cap = metrics.capacidadPorCurso[cursoNombre] ?? 30;
                    final pct = cap > 0 ? (inscritos / cap).clamp(0.0, 1.0) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cursoNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(
                                '$inscritos / $cap estudiantes (${(pct * 100).toStringAsFixed(0)}% cupo)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct >= 0.9 ? Colors.orange : AppColors.accentGreen,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 3: CURSOS & SECCIONES (Issue #20)
  // =========================================================
  Widget _buildCoursesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catálogo de Cursos & Secciones Activas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
              ),
              ElevatedButton.icon(
                key: const Key('btn_add_section_header'),
                onPressed: () => _showCreateSectionDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva Sección'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, idx) {
              final c = _courses[idx];
              final secciones = _sections.where((s) => s.cursoId == c.id).toList();

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.navyPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.school_rounded, color: AppColors.navyPrimary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Nivel ${c.nivel}', style: const TextStyle(fontSize: 11, color: AppColors.slateDark)),
                              ),
                              const SizedBox(width: 6),
                              Text('• Año: ${c.anioEscolar}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          OutlinedButton.icon(
                            key: Key('btn_add_section_to_${c.id}'),
                            onPressed: () => _showCreateSectionDialog(preselectedCourse: c),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('+ Agregar Sección', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (secciones.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No hay secciones creadas para este curso aún.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: secciones.map((sec) {
                            final matriculados = _enrollments.where((e) => e.seccionId == sec.id).length;

                            return Container(
                              width: 280,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sec.nombre,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$matriculados / ${sec.capacidadEstudiantes} est.',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Aula: ${sec.aula ?? "No asignada"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(
                                    'Docente Guía: ${sec.profesorTitularNombre ?? "Por asignar"}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.navyPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 4: ESTUDIANTES & MATRÍCULA (Issue #20)
  // =========================================================
  Widget _buildStudentsTab() {
    final filtered = _enrollments.where((e) {
      if (_searchEstudiante.isNotEmpty &&
          !e.estudianteNombre.toLowerCase().contains(_searchEstudiante.toLowerCase()) &&
          !e.matricula.toLowerCase().contains(_searchEstudiante.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Listado de Estudiantes Matriculados & Secciones',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
              ),
              ElevatedButton.icon(
                key: const Key('btn_enroll_student_header'),
                onPressed: _showEnrollStudentDialog,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Matricular Alumno'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar por nombre o número de matrícula...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchEstudiante = v),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, idx) {
                final enr = filtered[idx];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.electricBlue.withValues(alpha: 0.15),
                    child: Text(enr.estudianteNombre[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.electricBlue)),
                  ),
                  title: Text(enr.estudianteNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Matrícula: ${enr.matricula} • Curso: ${enr.cursoNombre} • ${enr.seccionNombre}\nAño Escolar: ${enr.anioEscolar} • Estado: ${enr.estado}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      OutlinedButton.icon(
                        key: Key('btn_transfer_student_${enr.id}'),
                        onPressed: () => _showTransferDialog(enr),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                        label: const Text('Trasladar', style: TextStyle(fontSize: 11)),
                      ),
                      IconButton(
                        key: Key('btn_history_student_${enr.id}'),
                        icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.slateGray),
                        tooltip: 'Ver Historial de Traslados',
                        onPressed: () => _showTransferHistoryDialog(enr),
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

  // =========================================================
  // TAB 5: PROFESORES & ASIGNACIONES (Issue #20)
  // =========================================================
  Widget _buildTeachersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              const Text(
                'Cuerpo Docente & Asignaciones Académicas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    key: const Key('btn_add_teacher'),
                    onPressed: _showCreateTeacherDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('+ Nuevo Profesor'),
                  ),
                  ElevatedButton.icon(
                    key: const Key('btn_add_academic_assignment'),
                    onPressed: _showCreateAssignmentDialog,
                    icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                    label: const Text('Asignar Materia a Docente'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, idx) {
              final t = _teachers[idx];
              final asignacionesDelProfesor = _assignments.where((a) => a.profesorId == t.id).toList();

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                                child: const Icon(Icons.person, color: AppColors.navyPrimary),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('Cédula: ${t.cedula} • Tel: ${t.telefono} • ${t.email}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(t.estado, style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Especialidad: ${t.especialidad}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text(
                        'Materias y Secciones Impartidas:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slateGray),
                      ),
                      const SizedBox(height: 6),
                      if (asignacionesDelProfesor.isEmpty)
                        const Text('Sin materias asignadas actualmente.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: asignacionesDelProfesor.map((asg) {
                            return Chip(
                              backgroundColor: const Color(0xFFEFF6FF),
                              label: Text('${asg.materiaNombre} (${asg.cursoNombre} - ${asg.seccionNombre})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.navyPrimary)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () async {
                                await widget.academicRepository.removeTeacherAssignment(asg.id);
                                _loadAllData();
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 6: MATERIAS CURRICULARES (Issue #20)
  // =========================================================
  Widget _buildSubjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Malla Curricular & Catálogo de Materias',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
              ),
              ElevatedButton.icon(
                key: const Key('btn_add_subject'),
                onPressed: _showCreateSubjectDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva Materia'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
            ),
            itemCount: _subjects.length,
            itemBuilder: (_, idx) {
              final m = _subjects[idx];

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(m.nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyPrimary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.codigo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${m.horasSemanales} horas académicas semanales', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        m.descripcion ?? 'Sin descripción',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.slateDark),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Diálogo oficial de Calificaciones MINERD con desglose de períodos y botón Listo
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

  void _editGrade(SubjectGrade materia, int periodo, int? currentGrade) {
    final controller = TextEditingController(text: currentGrade?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar P$periodo - ${materia.materia}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Calificación (0 - 100)',
            hintText: 'Ej. 95',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0 && val <= 100) {
                await widget.repository.updateSubjectGrade(
                  reportId: _currentReport.id,
                  materia: materia.materia,
                  periodo: periodo,
                  nota: val,
                );
                final updated = await widget.repository.getReportForStudent(_currentReport.studentId);
                if (updated != null && mounted) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
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
                                  m.promedio > 0 ? m.promedio.toStringAsFixed(1) : '--',
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
