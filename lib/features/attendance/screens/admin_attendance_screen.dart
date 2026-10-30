import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// Pantalla del Personal Escolar y Dirección para el Registro y Control de Asistencia Diaria
class AdminAttendanceScreen extends StatefulWidget {
  final AttendanceRepository repository;
  final String? colegioId;

  const AdminAttendanceScreen({
    super.key,
    required this.repository,
    this.colegioId,
  });

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedGrade = '1ro de Primaria';
  String _selectedSection = 'Sección A';

  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _availableGrados = [
    'Kinder',
    'Pre-Primario',
    '1ro de Primaria',
    '2do de Primaria',
    '3ro de Primaria',
    '4to de Primaria',
    '5to de Primaria',
    '6to de Primaria',
  ];

  final List<String> _availableSecciones = ['Sección A', 'Sección B'];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.repository.getAttendanceForDateAndSection(
        fecha: _selectedDate,
        colegioId: widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001',
        gradoNombre: _selectedGrade,
        seccionNombre: _selectedSection,
      );
      if (mounted) {
        setState(() {
          _records = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateStudentStatus(int index, String newStatus) {
    setState(() {
      final old = _records[index];
      String? arrivalTime = old.horaLlegada;
      if (newStatus == 'Presente' && arrivalTime == null) {
        arrivalTime = '07:45 AM';
      } else if (newStatus == 'Tardanza') {
        arrivalTime = '08:15 AM';
      } else if (newStatus == 'Ausente') {
        arrivalTime = null;
      }
      _records[index] = old.copyWith(
        estado: newStatus,
        horaLlegada: arrivalTime,
      );
    });
  }

  void _markAllAs(String status) {
    setState(() {
      for (int i = 0; i < _records.length; i++) {
        _records[i] = _records[i].copyWith(
          estado: status,
          horaLlegada: status == 'Presente' ? '07:45 AM' : (status == 'Tardanza' ? '08:15 AM' : null),
        );
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      await widget.repository.saveAttendanceRecords(_records);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Asistencia guardada y notificada a los tutores (${_records.length} alumnos)!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAttendance();
    }
  }

  int get _presentCount => _records.where((r) => r.esPresente).length;
  int get _tardyCount => _records.where((r) => r.esTardanza).length;
  int get _absentCount => _records.where((r) => r.esAusente).length;
  int get _justifiedCount => _records.where((r) => r.esJustificado).length;
  double get _attendancePercentage {
    if (_records.isEmpty) return 100.0;
    return ((_presentCount + _justifiedCount) / _records.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navyPrimary))
          : SingleChildScrollView(
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
                              'Control de Asistencia Escolar',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Consolidado institucional y registro diario de asistencia administrado por profesores (Issue #23)',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_rounded, size: 16, color: AppColors.navyPrimary),
                                SizedBox(width: 8),
                                Text(
                                  'Modo Auditoría Directiva',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveAttendance,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(_isSaving ? 'Guardando...' : 'Guardar y Notificar a Padres'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navyPrimary,
                              foregroundColor: AppColors.surfaceWhite,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Banner didáctico (Issue #23 Caso 3)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Control de Asistencia Institucional: El pase de lista operativo diario es administrado por el docente titular en el aula. Este dashboard permite a la dirección auditar la asistencia por curso y sección sin botones manuales de llegada.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Barra de Filtros (Fecha, Grado, Sección)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        // Selector de Fecha
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: AppColors.navyPrimary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Fecha: $dateFormatted',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Selector de Grado
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Grado: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedGrade,
                              underline: const SizedBox(),
                              items: _availableGrados.map((g) {
                                return DropdownMenuItem(value: g, child: Text(g));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedGrade = val);
                                  _loadAttendance();
                                }
                              },
                            ),
                          ],
                        ),

                        // Selector de Sección
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Sección: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedSection,
                              underline: const SizedBox(),
                              items: _availableSecciones.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSection = val);
                                  _loadAttendance();
                                }
                              },
                            ),
                          ],
                        ),

                        // Botón de acción rápida: Todos Presentes
                        OutlinedButton.icon(
                          onPressed: () => _markAllAs('Presente'),
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('Marcar Todos Presentes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navyPrimary,
                            side: const BorderSide(color: AppColors.navyPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),

                        // Botón para refrescar
                        IconButton(
                          onPressed: _loadAttendance,
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.navyPrimary),
                          tooltip: 'Actualizar asistencia en tiempo real',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tarjetas de Métricas Resumen
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
                            title: 'Tasa de Asistencia',
                            value: '${_attendancePercentage.toStringAsFixed(1)}%',
                            subtitle: '${_records.length} matriculados en sección',
                            icon: Icons.pie_chart_rounded,
                            color: AppColors.accentGreen,
                          ),
                          _buildStatCard(
                            title: 'Presentes',
                            value: '$_presentCount',
                            subtitle: 'En aula al iniciar jornada',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF166534),
                          ),
                          _buildStatCard(
                            title: 'Tardanzas',
                            value: '$_tardyCount',
                            subtitle: 'Llegadas posteriores a la hora',
                            icon: Icons.access_time_rounded,
                            color: const Color(0xFFB45309),
                          ),
                          _buildStatCard(
                            title: 'Ausencias',
                            value: '$_absentCount',
                            subtitle: '$_justifiedCount con justificación previa',
                            icon: Icons.cancel_rounded,
                            color: const Color(0xFFDC2626),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Roster / Lista de Estudiantes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Roster de Asistencia • $_selectedGrade ($_selectedSection)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_records.length} alumnos matriculados',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_records.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No se encontraron estudiantes para la sección seleccionada.'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildStudentRecordTile(index, record);
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
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

  Widget _buildStudentRecordTile(int index, AttendanceRecord record) {
    Color statusColor;
    switch (record.estado) {
      case 'Presente':
        statusColor = const Color(0xFF166534);
        break;
      case 'Tardanza':
        statusColor = const Color(0xFFB45309);
        break;
      case 'Ausente':
        statusColor = const Color(0xFFDC2626);
        break;
      case 'Justificado':
        statusColor = const Color(0xFF1D4ED8);
        break;
      default:
        statusColor = AppColors.navyPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.esAusente
              ? const Color(0xFFFECACA)
              : (record.esTardanza ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          // Inicial / Avatar
          CircleAvatar(
            backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.08),
            child: Text(
              record.estudianteNombre.isNotEmpty ? record.estudianteNombre[0] : 'E',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
            ),
          ),
          const SizedBox(width: 14),

          // Información del estudiante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.estudianteNombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        record.matricula,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (record.horaLlegada != null) ...[
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Llegada: ${record.horaLlegada}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (record.justificacionTutor != null) ...[
                      const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Justificado: ${record.justificacionTutor}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else if (record.observacion != null) ...[
                      Expanded(
                        child: Text(
                          'Nota: ${record.observacion}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Selector de Estado de Asistencia / Auditoría Docente (Issue #23)
          Wrap(
            spacing: 6,
            children: [
              _buildStatusButton(index, 'Presente', record.estado == 'Presente', const Color(0xFF166534)),
              _buildStatusButton(index, 'Tardanza', record.estado == 'Tardanza', const Color(0xFFB45309)),
              _buildStatusButton(index, 'Ausente', record.estado == 'Ausente', const Color(0xFFDC2626)),
              _buildStatusButton(index, 'Justificado', record.estado == 'Justificado', const Color(0xFF1D4ED8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(int index, String status, bool isSelected, Color activeColor) {
    return InkWell(
      onTap: () => _updateStudentStatus(index, status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : activeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : activeColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : activeColor,
          ),
        ),
      ),
    );
  }
}
