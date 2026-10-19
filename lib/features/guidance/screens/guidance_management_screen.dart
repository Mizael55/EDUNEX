import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/guidance_case.dart';
import '../repositories/guidance_repository.dart';

/// Pantalla Administrativa de Psicología, Orientación Escolar y Convivencia
class GuidanceManagementScreen extends StatefulWidget {
  final GuidanceRepository guidanceRepository;
  final String colegioId;

  const GuidanceManagementScreen({
    super.key,
    required this.guidanceRepository,
    required this.colegioId,
  });

  @override
  State<GuidanceManagementScreen> createState() => _GuidanceManagementScreenState();
}

class _GuidanceManagementScreenState extends State<GuidanceManagementScreen> {
  List<GuidanceCase> _cases = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  String _filterEstado = 'Todos';
  String _filterUrgencia = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cases = await widget.guidanceRepository.getCases(
      colegioId: widget.colegioId,
      estado: _filterEstado,
      urgencia: _filterUrgencia,
      searchQuery: _searchController.text,
    );
    final stats = await widget.guidanceRepository.getStats(widget.colegioId);

    if (mounted) {
      setState(() {
        _cases = cases;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDesktop),
                  const SizedBox(height: 20),
                  _buildKpiCards(isDesktop),
                  const SizedBox(height: 24),
                  _buildFilterBar(isDesktop),
                  const SizedBox(height: 16),
                  _buildCasesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.purple, size: 28),
            ),
            const SizedBox(width: 14),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Psicología & Convivencia Escolar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  Text(
                    'Expedientes psicopedagógicos, citaciones a tutores y actas de compromiso',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          key: const Key('btn_nuevo_caso_psicologia'),
          onPressed: _showCreateCaseModal,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('+ Nuevo Caso de Orientación'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCards(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 900
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth > 600 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _kpiCard(
              title: 'Casos Activos',
              value: '${_stats['casosActivos'] ?? 0}',
              subtitle: 'De ${_stats['totalCasos'] ?? 0} expedientes totales',
              icon: Icons.folder_shared_rounded,
              color: AppColors.electricBlue,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Urgencia Alta',
              value: '${_stats['casosUrgenciaAlta'] ?? 0}',
              subtitle: 'Requieren atención prioritaria',
              icon: Icons.warning_amber_rounded,
              color: Colors.redAccent,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Citas a Familias',
              value: '${_stats['citasPendientes'] ?? 0}',
              subtitle: 'Pendientes por realizar',
              icon: Icons.family_restroom_rounded,
              color: Colors.purple,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Cumplimiento Acuerdos',
              value: '${(_stats['tasaCumplimientoAcuerdos'] ?? 100.0).toStringAsFixed(0)}%',
              subtitle: 'De compromisos de convivencia',
              icon: Icons.handshake_rounded,
              color: const Color(0xFF16A34A),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDesktop) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por alumno, matrícula o motivo...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                onChanged: (_) => _loadData(),
              ),
            ),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButton<String>(
                  value: _filterEstado,
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos los Estados')),
                    DropdownMenuItem(value: 'En Evaluación', child: Text('En Evaluación')),
                    DropdownMenuItem(value: 'En Intervención', child: Text('En Intervención')),
                    DropdownMenuItem(value: 'Citación a Tutores', child: Text('Citación a Tutores')),
                    DropdownMenuItem(value: 'Cerrado', child: Text('Cerrado / Resuelto')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _filterEstado = val);
                      _loadData();
                    }
                  },
                ),
                const SizedBox(width: 8),
                const Text('Urgencia:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButton<String>(
                  value: _filterUrgencia,
                  items: const [
                    DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                    DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'Media', child: Text('Media')),
                    DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _filterUrgencia = val);
                      _loadData();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesList() {
    if (_cases.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AppColors.slateGray),
            SizedBox(height: 12),
            Text(
              'No se encontraron expedientes psicopedagógicos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'No hay casos con los filtros seleccionados o la base de datos está limpia.',
              style: TextStyle(fontSize: 13, color: AppColors.slateGray),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _cases[index];
        final isUrgent = c.esUrgente;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isUrgent ? Colors.redAccent.withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
              width: isUrgent ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple.withValues(alpha: 0.15),
                          child: Text(
                            c.studentName.isNotEmpty ? c.studentName[0] : 'E',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Matrícula: ${c.matricula} • ${c.grado} (${c.seccion})',
                              style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Urgencia ${c.nivelUrgencia}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? Colors.red.shade800 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.estado == 'Cerrado'
                                ? const Color(0xFFF1F5F9)
                                : Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c.estado,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: c.estado == 'Cerrado' ? AppColors.slateGray : Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Motivo de Remisión: ${c.motivoRemision}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                if (c.diagnosticoSugerido != null && c.diagnosticoSugerido!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Evaluación Diagnóstica: ${c.diagnosticoSugerido}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.purple),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_edu_rounded, size: 16, color: Colors.purple.shade700),
                        const SizedBox(width: 4),
                        Text('${c.sesiones.length} sesiones', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 14),
                        Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.electricBlue),
                        const SizedBox(width: 4),
                        Text('${c.citasPadres.length} citas familiares', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 14),
                        Icon(Icons.check_circle_outline_rounded, size: 16, color: const Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          '${c.compromisos.where((co) => co.cumplido).length}/${c.compromisos.length} acuerdos',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: Key('btn_ver_expediente_${c.id}'),
                      onPressed: () => _showCaseDetailsDialog(c),
                      icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                      label: const Text('Ver Expediente Psicopedagógico'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== MODALES ====================

  void _showCaseDetailsDialog(GuidanceCase c) {
    showDialog(
      context: context,
      builder: (ctx) => _CaseDetailsDialog(
        guidanceCase: c,
        guidanceRepository: widget.guidanceRepository,
        onCaseUpdated: () {
          _loadData();
        },
      ),
    );
  }

  void _showCreateCaseModal() {
    final nameCtrl = TextEditingController();
    final matriculaCtrl = TextEditingController();
    final gradoCtrl = TextEditingController(text: '1ro de Primaria');
    final seccionCtrl = TextEditingController(text: 'Sección A');
    final motivoCtrl = TextEditingController();
    final remitidoCtrl = TextEditingController(text: 'Coordinación Pedagógica');
    String urgencia = 'Media';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar Nuevo Caso de Orientación'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const Key('input_guidance_student_name'),
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del Estudiante *'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('input_guidance_matricula'),
                          controller: matriculaCtrl,
                          decoration: const InputDecoration(labelText: 'Matrícula *'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: urgencia,
                          decoration: const InputDecoration(labelText: 'Nivel Urgencia'),
                          items: const [
                            DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                            DropdownMenuItem(value: 'Media', child: Text('Media')),
                            DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                          ],
                          onChanged: (v) => setModalState(() => urgencia = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: gradoCtrl,
                          decoration: const InputDecoration(labelText: 'Grado *'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: seccionCtrl,
                          decoration: const InputDecoration(labelText: 'Sección *'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: remitidoCtrl,
                    decoration: const InputDecoration(labelText: 'Remitido por *'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('input_guidance_motivo'),
                    controller: motivoCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de Remisión / Descripción del Caso *',
                      hintText: 'Detalla las conductas observadas o necesidades psicopedagógicas...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('btn_submit_guidance_case'),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || motivoCtrl.text.trim().isEmpty) return;
                await widget.guidanceRepository.createCase(
                  colegioId: widget.colegioId,
                  studentId: 'student-${DateTime.now().millisecondsSinceEpoch}',
                  studentName: nameCtrl.text.trim(),
                  matricula: matriculaCtrl.text.trim().isNotEmpty ? matriculaCtrl.text.trim() : 'EST-NEW',
                  grado: gradoCtrl.text.trim(),
                  seccion: seccionCtrl.text.trim(),
                  remitidoPor: remitidoCtrl.text.trim(),
                  motivoRemision: motivoCtrl.text.trim(),
                  nivelUrgencia: urgencia,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                _loadData();
              },
              child: const Text('Crear Expediente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de Expediente Psicopedagógico con Pestañas Internas
class _CaseDetailsDialog extends StatefulWidget {
  final GuidanceCase guidanceCase;
  final GuidanceRepository guidanceRepository;
  final VoidCallback onCaseUpdated;

  const _CaseDetailsDialog({
    required this.guidanceCase,
    required this.guidanceRepository,
    required this.onCaseUpdated,
  });

  @override
  State<_CaseDetailsDialog> createState() => _CaseDetailsDialogState();
}

class _CaseDetailsDialogState extends State<_CaseDetailsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GuidanceCase _currentCase;

  @override
  void initState() {
    super.initState();
    _currentCase = widget.guidanceCase;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Expediente: ${_currentCase.studentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${_currentCase.matricula} • ${_currentCase.grado} (${_currentCase.seccion})', style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _currentCase.estado,
            items: const [
              DropdownMenuItem(value: 'En Evaluación', child: Text('En Evaluación')),
              DropdownMenuItem(value: 'En Intervención', child: Text('En Intervención')),
              DropdownMenuItem(value: 'Citación a Tutores', child: Text('Citación a Tutores')),
              DropdownMenuItem(value: 'Cerrado', child: Text('Cerrado')),
            ],
            onChanged: (val) async {
              if (val != null) {
                final updated = await widget.guidanceRepository.updateCaseStatus(_currentCase.id, val);
                setState(() => _currentCase = updated);
                widget.onCaseUpdated();
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 480,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.purple,
              unselectedLabelColor: AppColors.slateGray,
              indicatorColor: Colors.purple,
              tabs: const [
                Tab(icon: Icon(Icons.history_edu_rounded), text: 'Sesiones'),
                Tab(icon: Icon(Icons.family_restroom_rounded), text: 'Citaciones Tutores'),
                Tab(icon: Icon(Icons.handshake_rounded), text: 'Acuerdos Convivencia'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSessionsTab(),
                  _buildInterviewsTab(),
                  _buildAgreementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar Expediente'),
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Historial de Sesiones (${_currentCase.sesiones.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                key: const Key('btn_add_guidance_session'),
                onPressed: _showAddSessionModal,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva Sesión'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _currentCase.sesiones.isEmpty
                ? const Center(child: Text('No hay sesiones registradas aún.'))
                : ListView.separated(
                    itemCount: _currentCase.sesiones.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, idx) {
                      final s = _currentCase.sesiones[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${s.tipo} • ${s.fecha.day}/${s.fecha.month}/${s.fecha.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                                Text(s.profesionalACargo, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(s.notasConfidenciales, style: const TextStyle(fontSize: 12)),
                            if (s.acuerdos.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Acuerdo: ${s.acuerdos}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.navyPrimary)),
                            ],
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

  Widget _buildInterviewsTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Citaciones a Padres (${_currentCase.citasPadres.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                key: const Key('btn_schedule_parent_interview'),
                onPressed: _showScheduleInterviewModal,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const Text('Agendar Cita'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _currentCase.citasPadres.isEmpty
                ? const Center(child: Text('No hay citaciones a padres agendadas.'))
                : ListView.separated(
                    itemCount: _currentCase.citasPadres.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final c = _currentCase.citasPadres[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: AppColors.electricBlue, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${c.fecha.day}/${c.fecha.month}/${c.fecha.year} a las ${c.hora} (${c.modalidad})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Motivo: ${c.motivo}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                  if (c.conclusiones != null) Text('Conclusiones: ${c.conclusiones}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF16A34A))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.estado == 'Realizada' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(c.estado, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.estado == 'Realizada' ? const Color(0xFF15803D) : const Color(0xFFB45309))),
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

  Widget _buildAgreementsTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Acuerdos de Convivencia (${_currentCase.compromisos.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                key: const Key('btn_add_convivencia_agreement'),
                onPressed: _showAddAgreementModal,
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text('Nuevo Acuerdo'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _currentCase.compromisos.isEmpty
                ? const Center(child: Text('No hay acuerdos suscritos aún.'))
                : ListView.separated(
                    itemCount: _currentCase.compromisos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final a = _currentCase.compromisos[idx];
                      return CheckboxListTile(
                        value: a.cumplido,
                        onChanged: (val) async {
                          final updated = await widget.guidanceRepository.toggleAgreementStatus(_currentCase.id, a.id);
                          setState(() => _currentCase = updated);
                          widget.onCaseUpdated();
                        },
                        title: Text(a.descripcion, style: TextStyle(fontSize: 13, decoration: a.cumplido ? TextDecoration.lineThrough : null)),
                        subtitle: Text('Responsable: ${a.responsable}', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        tileColor: a.cumplido ? const Color(0xFFF0FDF4) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: a.cumplido ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSessionModal() {
    final notesCtrl = TextEditingController();
    final acuerdosCtrl = TextEditingController();
    String tipo = 'Individual con Alumno';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Registrar Sesión de Orientación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Tipo de Sesión'),
                items: const [
                  DropdownMenuItem(value: 'Individual con Alumno', child: Text('Individual con Alumno')),
                  DropdownMenuItem(value: 'Observación Áulica', child: Text('Observación Áulica')),
                  DropdownMenuItem(value: 'Evaluación Psicopedagógica', child: Text('Evaluación Psicopedagógica')),
                  DropdownMenuItem(value: 'Seguimiento', child: Text('Sesión de Seguimiento')),
                ],
                onChanged: (v) => setModalState(() => tipo = v!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('input_session_notes'),
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas Confidenciales de la Sesión *'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('input_session_acuerdos'),
                controller: acuerdosCtrl,
                decoration: const InputDecoration(labelText: 'Acuerdos Pedagógicos / Tareas'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('btn_submit_session'),
              onPressed: () async {
                if (notesCtrl.text.trim().isEmpty) return;
                final updated = await widget.guidanceRepository.addSession(
                  _currentCase.id,
                  GuidanceSession(
                    id: 'ses-${DateTime.now().millisecondsSinceEpoch}',
                    fecha: DateTime.now(),
                    tipo: tipo,
                    notasConfidenciales: notesCtrl.text.trim(),
                    acuerdos: acuerdosCtrl.text.trim(),
                    profesionalACargo: 'Psicología Escolar',
                  ),
                );
                setState(() => _currentCase = updated);
                widget.onCaseUpdated();
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
              child: const Text('Guardar Sesión'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleInterviewModal() {
    final motivoCtrl = TextEditingController();
    final horaCtrl = TextEditingController(text: '09:00 AM');
    String modalidad = 'Presencial';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Agendar Citación con Padres / Tutores'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('input_interview_motivo'),
                controller: motivoCtrl,
                decoration: const InputDecoration(labelText: 'Motivo de la Cita *', hintText: 'Ej. Firma de acuerdo pedagógico'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: horaCtrl,
                decoration: const InputDecoration(labelText: 'Hora *', hintText: 'Ej. 10:30 AM'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: modalidad,
                decoration: const InputDecoration(labelText: 'Modalidad'),
                items: const [
                  DropdownMenuItem(value: 'Presencial', child: Text('Presencial en Centro')),
                  DropdownMenuItem(value: 'Virtual (Meet/Zoom)', child: Text('Virtual (Google Meet / Zoom)')),
                ],
                onChanged: (v) => setModalState(() => modalidad = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('btn_submit_interview'),
              onPressed: () async {
                if (motivoCtrl.text.trim().isEmpty) return;
                final updated = await widget.guidanceRepository.scheduleParentInterview(
                  _currentCase.id,
                  ParentInterview(
                    id: 'cita-${DateTime.now().millisecondsSinceEpoch}',
                    fecha: DateTime.now().add(const Duration(days: 2)),
                    hora: horaCtrl.text.trim(),
                    modalidad: modalidad,
                    motivo: motivoCtrl.text.trim(),
                    estado: 'Programada',
                  ),
                );
                setState(() => _currentCase = updated);
                widget.onCaseUpdated();
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
              child: const Text('Agendar Cita'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAgreementModal() {
    final descCtrl = TextEditingController();
    String resp = 'Estudiante';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Nuevo Compromiso de Convivencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('input_agreement_desc'),
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción del Compromiso *', hintText: 'Ej. Cumplir con tareas diarias...'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: resp,
                decoration: const InputDecoration(labelText: 'Responsable del Cumplimiento'),
                items: const [
                  DropdownMenuItem(value: 'Estudiante', child: Text('Estudiante')),
                  DropdownMenuItem(value: 'Padres / Tutores', child: Text('Padres / Tutores')),
                  DropdownMenuItem(value: 'Docente', child: Text('Docente de Asignatura')),
                  DropdownMenuItem(value: 'Colegio', child: Text('Colegio / Orientación')),
                ],
                onChanged: (v) => setModalState(() => resp = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('btn_submit_agreement'),
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) return;
                final updated = await widget.guidanceRepository.addAgreement(
                  _currentCase.id,
                  ConvivenciaAgreement(
                    id: 'comp-${DateTime.now().millisecondsSinceEpoch}',
                    fecha: DateTime.now(),
                    descripcion: descCtrl.text.trim(),
                    responsable: resp,
                    cumplido: false,
                  ),
                );
                setState(() => _currentCase = updated);
                widget.onCaseUpdated();
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
              child: const Text('Registrar Acuerdo'),
            ),
          ],
        ),
      ),
    );
  }
}
