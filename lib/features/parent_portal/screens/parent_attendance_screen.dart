import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/models/student.dart';
import '../../families/repositories/family_repository.dart';
import '../../attendance/models/attendance_record.dart';
import '../../attendance/repositories/attendance_repository.dart';

/// Pantalla del Portal de Padres para Seguimiento de Asistencia Escolar y Justificaciones
class ParentAttendanceScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;
  final AttendanceRepository? attendanceRepository;

  const ParentAttendanceScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
    this.attendanceRepository,
  });

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  late final AttendanceRepository _attendanceRepository;
  Family? _family;
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;

  String? _selectedStudentId;
  String _selectedFilter = 'Todos'; // 'Todos', 'Inasistencias & Tardanzas', 'Justificados'

  @override
  void initState() {
    super.initState();
    _attendanceRepository = widget.attendanceRepository ?? AttendanceRepository(familyRepository: widget.familyRepository);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );

      List<AttendanceRecord> records = [];
      if (family != null) {
        records = await _attendanceRepository.getAttendanceForFamily(family.id);
        if (_selectedStudentId == null && family.estudiantes.isNotEmpty) {
          _selectedStudentId = family.estudiantes.first.id;
        }
      }

      if (mounted) {
        setState(() {
          _family = family;
          _records = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJustificationDialog(BuildContext context, AttendanceRecord record) {
    String selectedReason = 'Cita Médica / Salud';
    final commentController = TextEditingController();
    bool isSubmitting = false;

    final reasons = [
      'Cita Médica / Salud',
      'Asunto Familiar de Fuerza Mayor',
      'Dificultad de Transporte',
      'Enfermedad Común',
      'Duelo / Luto Familiar',
      'Otro Motivo Justificado',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.navyPrimary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Justificar Inasistencia / Tardanza',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estudiante: ${record.estudianteNombre}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                  ),
                  Text(
                    'Fecha: ${record.fecha.day.toString().padLeft(2, '0')}/${record.fecha.month.toString().padLeft(2, '0')}/${record.fecha.year} (${record.estado})',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Motivo Oficial de la Justificación:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Observaciones o detalles adicionales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Presentó malestar gripal o cita en el Centro Médico...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setModalState(() => isSubmitting = true);
                        try {
                          await _attendanceRepository.submitJustification(
                            recordId: record.id,
                            motivo: selectedReason,
                            comentario: commentController.text,
                          );

                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            await _loadData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Justificación enviada y registrada formalmente ante el colegio!'),
                                  backgroundColor: AppColors.accentGreen,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: AppColors.surfaceWhite,
                ),
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar Justificación'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.navyPrimary)),
      );
    }

    final family = _family;
    if (family == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: Text('No se encontró información familiar.')),
      );
    }

    // Filtrar por estudiante seleccionado
    var studentRecords = _selectedStudentId == null
        ? _records
        : _records.where((r) => r.estudianteId == _selectedStudentId).toList();

    // Filtrar por estado
    if (_selectedFilter == 'Inasistencias & Tardanzas') {
      studentRecords = studentRecords.where((r) => r.esAusente || r.esTardanza).toList();
    } else if (_selectedFilter == 'Justificados') {
      studentRecords = studentRecords.where((r) => r.esJustificado).toList();
    }

    final totalDays = studentRecords.length;
    final presentDays = studentRecords.where((r) => r.esPresente).length;
    final tardyDays = studentRecords.where((r) => r.esTardanza).length;
    final absentDays = studentRecords.where((r) => r.esAusente).length;
    final justifiedDays = studentRecords.where((r) => r.esJustificado).length;
    final attendancePct = totalDays > 0 ? ((presentDays + justifiedDays) / totalDays) * 100 : 100.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Principal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asistencia & Seguimiento Escolar',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Historial de puntualidad, asistencia diaria y justificación de inasistencias • ${family.nombreFamilia}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selector de Estudiante (Hijos matriculados)
            if (family.estudiantes.isNotEmpty) ...[
              const Text('Seleccionar Hijo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: family.estudiantes.map((st) {
                  final isSelected = _selectedStudentId == st.id;
                  return ChoiceChip(
                    label: Text('${st.nombreCompleto} (${st.gradoNombre ?? "Nivel Inicial"})'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStudentId = st.id),
                    selectedColor: AppColors.navyPrimary,
                    backgroundColor: AppColors.surfaceWhite,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.surfaceWhite : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Tarjetas de Resumen
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isMedium = constraints.maxWidth >= 600;
                final count = isWide ? 4 : (isMedium ? 2 : 1);

                return GridView.count(
                  crossAxisCount: count,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.5 : 2.7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      title: 'Asistencia Regular',
                      value: '${attendancePct.toStringAsFixed(1)}%',
                      subtitle: '$totalDays jornadas computadas',
                      icon: Icons.pie_chart_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildStatCard(
                      title: 'Días Presente',
                      value: '$presentDays',
                      subtitle: 'Puntual en salón',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF166534),
                    ),
                    _buildStatCard(
                      title: 'Tardanzas',
                      value: '$tardyDays',
                      subtitle: 'Llegadas posteriores a la hora',
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFFB45309),
                    ),
                    _buildStatCard(
                      title: 'Ausencias Registradas',
                      value: '$absentDays',
                      subtitle: '$justifiedDays justificadas por tutor',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFDC2626),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Filtros de Historial
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial Diario de Asistencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('Todos'),
                    _buildFilterChip('Inasistencias & Tardanzas'),
                    _buildFilterChip('Justificados'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Lista de Registros
            if (studentRecords.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No hay registros de asistencia bajo los criterios seleccionados.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: studentRecords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final record = studentRecords[index];
                  return _buildAttendanceItemCard(context, record);
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppColors.navyPrimary,
      backgroundColor: AppColors.surfaceWhite,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.surfaceWhite : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItemCard(BuildContext context, AttendanceRecord record) {
    Color badgeColor;
    Color badgeTextColor;
    IconData badgeIcon;
    String statusTitle;

    switch (record.estado) {
      case 'Presente':
        badgeColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        badgeIcon = Icons.check_circle_rounded;
        statusTitle = 'Presente';
        break;
      case 'Tardanza':
        badgeColor = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFFB45309);
        badgeIcon = Icons.access_time_filled_rounded;
        statusTitle = 'Llegada Tarde';
        break;
      case 'Ausente':
        badgeColor = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFFDC2626);
        badgeIcon = Icons.cancel_rounded;
        statusTitle = 'Inasistencia';
        break;
      case 'Justificado':
        badgeColor = const Color(0xFFDBEAFE);
        badgeTextColor = const Color(0xFF1D4ED8);
        badgeIcon = Icons.verified_user_rounded;
        statusTitle = 'Inasistencia Justificada';
        break;
      default:
        badgeColor = Colors.grey.shade100;
        badgeTextColor = Colors.black87;
        badgeIcon = Icons.info_rounded;
        statusTitle = record.estado;
    }

    final dateStr =
        '${record.fecha.day.toString().padLeft(2, '0')}/${record.fecha.month.toString().padLeft(2, '0')}/${record.fecha.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: record.esAusente ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Badge visual de estado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(badgeIcon, color: badgeTextColor, size: 26),
          ),
          const SizedBox(width: 14),

          // Información del registro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: badgeTextColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $dateStr',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Alumno: ${record.estudianteNombre} • ${record.gradoNombre} (${record.seccionNombre})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (record.horaLlegada != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Hora de entrada al aula: ${record.horaLlegada}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
                if (record.justificacionTutor != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Justificación: ${record.justificacionTutor}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else if (record.observacion != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Nota del docente: ${record.observacion}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),

          // Botón de justificar inasistencia o tardanza
          if ((record.esAusente || record.esTardanza) && record.justificacionTutor == null)
            ElevatedButton.icon(
              onPressed: () => _showJustificationDialog(context, record),
              icon: const Icon(Icons.note_alt_rounded, size: 16),
              label: const Text('Justificar Inasistencia'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: AppColors.surfaceWhite,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
