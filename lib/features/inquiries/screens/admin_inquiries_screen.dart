import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../families/repositories/family_repository.dart';
import '../../parent_portal/models/parent_question.dart';
import '../../parent_portal/models/payment_agreement_request.dart';

/// Pantalla de Gestión de Atención a Familias, Consultas y Acuerdos de Pago (Admin / Dirección)
class AdminInquiriesScreen extends StatefulWidget {
  final FamilyRepository familyRepository;
  final String? colegioId;

  const AdminInquiriesScreen({
    super.key,
    required this.familyRepository,
    this.colegioId,
  });

  @override
  State<AdminInquiriesScreen> createState() => _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends State<AdminInquiriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ParentQuestion> _questions = [];
  List<PaymentAgreementRequest> _agreements = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedDepartment = 'Todos';
  String _selectedStatus = 'Todos';

  final List<String> _departments = [
    'Todos',
    'Dirección Académica',
    'Caja y Facturación',
    'Psicología y Orientación',
    'Secretaría Escolar',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final questions = await widget.familyRepository.getAllQuestions(colegioId: widget.colegioId);
      final agreements = await widget.familyRepository.getAllAgreements(colegioId: widget.colegioId);
      if (mounted) {
        setState(() {
          _questions = questions;
          _agreements = agreements;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ParentQuestion> get _filteredQuestions {
    return _questions.where((q) {
      final matchesDept = _selectedDepartment == 'Todos' || q.departamento == _selectedDepartment;
      final matchesStatus = _selectedStatus == 'Todos' || q.estado == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          q.asunto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.mensaje.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.tutorNombre.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDept && matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.navyPrimary)),
      );
    }

    final totalQuestions = _questions.length;
    final pendingQuestions = _questions.where((q) => q.estado == 'En trámite').length;
    final answeredQuestions = _questions.where((q) => q.estado == 'Respondida').length;
    final pendingAgreements = _agreements.where((a) => a.estado == 'En revisión por Dirección').length;

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
                        'Atención a Familias & Consultas Escolares',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mesa de ayuda institucional, canal de comunicación con tutores y resolución de convenios',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar bandeja',
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.navyPrimary),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tarjetas KPI
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isWide ? 1.6 : 1.35,
                  children: [
                    _buildKpiCard(
                      title: 'Total de Consultas',
                      value: '$totalQuestions',
                      subtitle: 'Recibidas en el ciclo',
                      icon: Icons.forum_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildKpiCard(
                      title: 'Pendientes de Respuesta',
                      value: '$pendingQuestions',
                      subtitle: 'Requieren atención',
                      icon: Icons.mark_chat_unread_rounded,
                      color: const Color(0xFFD97706),
                    ),
                    _buildKpiCard(
                      title: 'Respondidas & Resueltas',
                      value: '$answeredQuestions',
                      subtitle: 'Tiempo prom. 4.2h',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildKpiCard(
                      title: 'Convenios por Revisar',
                      value: '$pendingAgreements',
                      subtitle: 'Solicitudes financieras',
                      icon: Icons.handshake_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Tab bar selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.navyPrimary,
                labelColor: AppColors.navyPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.question_answer_rounded, size: 20),
                    text: 'Bandeja de Consultas de Tutores ($pendingQuestions pend.)',
                  ),
                  Tab(
                    icon: const Icon(Icons.handshake_rounded, size: 20),
                    text: 'Solicitudes de Acuerdos de Pago ($pendingAgreements)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Contenido de las pestañas
            SizedBox(
              height: 750,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionsTab(),
                  _buildAgreementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    final filtered = _filteredQuestions;

    return Column(
      children: [
        // Filtros y Búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por tutor, asunto o mensaje...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 14),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Estado: Todos')),
                      DropdownMenuItem(value: 'En trámite', child: Text('Estado: En trámite')),
                      DropdownMenuItem(value: 'Respondida', child: Text('Estado: Respondida')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Chips de departamentos
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _departments.map((dept) {
                    final isSelected = _selectedDepartment == dept;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(dept, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selectedColor: AppColors.navyPrimary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.navyPrimary,
                        labelStyle: TextStyle(color: isSelected ? AppColors.navyPrimary : AppColors.textPrimary),
                        onSelected: (_) => setState(() => _selectedDepartment = dept),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Lista de Consultas
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay consultas que coincidan con los filtros.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final question = filtered[index];
                    return _buildQuestionCard(question);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ParentQuestion question) {
    final isPending = question.estado == 'En trámite';

    Color deptColor;
    switch (question.departamento) {
      case 'Dirección Académica':
        deptColor = AppColors.navyPrimary;
        break;
      case 'Caja y Facturación':
        deptColor = AppColors.accentGreen;
        break;
      case 'Psicología y Orientación':
        deptColor = const Color(0xFF7C3AED);
        break;
      case 'Secretaría Escolar':
      default:
        deptColor = const Color(0xFF0284C7);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la tarjeta
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: deptColor.withValues(alpha: 0.15),
                child: Text(
                  question.tutorNombre.isNotEmpty ? question.tutorNombre[0].toUpperCase() : 'T',
                  style: TextStyle(color: deptColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          question.tutorNombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: deptColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            question.departamento,
                            style: TextStyle(color: deptColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Enviado el ${_formatDate(question.fechaEnvio)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPending ? Icons.pending_rounded : Icons.check_circle_rounded,
                      color: isPending ? const Color(0xFFB45309) : const Color(0xFF065F46),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      question.estado,
                      style: TextStyle(
                        color: isPending ? const Color(0xFFB45309) : const Color(0xFF065F46),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Asunto y Mensaje
          Text(
            question.asunto,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            question.mensaje,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
          ),

          // Bloque de respuesta oficial si ya fue respondida
          if (question.respuestaCentro != null && question.respuestaCentro!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, color: AppColors.navyPrimary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Respuesta de ${question.respondidoPor ?? "Dirección del Centro"}:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                      ),
                      const Spacer(),
                      if (question.fechaRespuesta != null)
                        Text(
                          _formatDate(question.fechaRespuesta!),
                          style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.respuestaCentro!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Botón de acción para responder
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showAnswerDialog(context, question),
              icon: Icon(isPending ? Icons.reply_rounded : Icons.edit_note_rounded, size: 16),
              label: Text(isPending ? 'Responder Consulta' : 'Actualizar Respuesta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? AppColors.navyPrimary : Colors.white,
                foregroundColor: isPending ? Colors.white : AppColors.navyPrimary,
                side: isPending ? null : const BorderSide(color: AppColors.navyPrimary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementsTab() {
    if (_agreements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No hay convenios ni acuerdos de pago registrados.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _agreements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final agreement = _agreements[index];
        final isPending = agreement.estado == 'En revisión por Dirección';
        final isApproved = agreement.estado == 'Aprobado';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPending
                  ? const Color(0xFFFCD34D)
                  : (isApproved ? const Color(0xFF86EFAC) : const Color(0xFFFDA4AF)),
              width: 1.2,
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.handshake_rounded, color: Color(0xFF7C3AED), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agreement.nombreFamilia,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyPrimary),
                          ),
                          Text(
                            agreement.tipoAcuerdo,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFFEF3C7)
                          : (isApproved ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      agreement.estado,
                      style: TextStyle(
                        color: isPending
                            ? const Color(0xFFB45309)
                            : (isApproved ? const Color(0xFF065F46) : const Color(0xFF991B1B)),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: AppColors.accentGreen, size: 20),
                    const SizedBox(width: 8),
                    const Text('Propuesta de Cuota Familiar: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(
                      'RD\$ ${agreement.propuestaCuota.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                    ),
                    const Spacer(),
                    Text(
                      'Solicitado: ${_formatDate(agreement.fechaSolicitud)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Justificación de la Familia:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                agreement.justificacion,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),

              if (agreement.respuestaCentro != null && agreement.respuestaCentro!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'Resolución de Dirección: ${agreement.respuestaCentro!}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.navyPrimary),
                  ),
                ),
              ],

              if (isPending) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _reviewAgreement(context, agreement, approve: false),
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                      label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _reviewAgreement(context, agreement, approve: true),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Aprobar Convenio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAnswerDialog(BuildContext context, ParentQuestion question) {
    final responseController = TextEditingController(text: question.respuestaCentro ?? '');
    final responderController = TextEditingController(
      text: question.respondidoPor ?? 'Dirección Académica EDUNEX',
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.reply_rounded, color: AppColors.navyPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Responder Consulta de ${question.tutorNombre}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asunto: ${question.asunto}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.mensaje,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: responderController,
                  decoration: const InputDecoration(
                    labelText: 'Identidad del Funcionario / Departamento',
                    hintText: 'Ej. Licda. Carmen Morales (Coord. Académica)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: responseController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Respuesta Oficial al Tutor',
                    hintText: 'Escriba la orientación o solución oficial...',
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
                      if (responseController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor redacte una respuesta')),
                        );
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      await widget.familyRepository.answerQuestion(
                        questionId: question.id,
                        respuesta: responseController.text.trim(),
                        respondidoPor: responderController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        await _loadData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Respuesta enviada y notificada al tutor con éxito!'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enviar Respuesta Oficial'),
            ),
          ],
        ),
      ),
    );
  }

  void _reviewAgreement(BuildContext context, PaymentAgreementRequest agreement, {required bool approve}) {
    final noteController = TextEditingController(
      text: approve
          ? 'Convenio aprobado por Dirección Financiera. Se aplicará el esquema de cuotas solicitado.'
          : 'Solicitud no procedente en las fechas requeridas. Por favor comunicarse con Caja.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Aprobar Convenio de Pago' : 'Rechazar Convenio de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Familia: ${agreement.nombreFamilia}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Cuota propuesta: RD\$ ${agreement.propuestaCuota.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resolución Oficial',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.familyRepository.reviewAgreement(
                agreementId: agreement.id,
                approve: approve,
                respuestaCentro: noteController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(ctx).pop();
                await _loadData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(approve ? 'Convenio de pago aprobado formalmente' : 'Convenio rechazado'),
                      backgroundColor: approve ? AppColors.accentGreen : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppColors.accentGreen : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Confirmar Aprobación' : 'Confirmar Rechazo'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
  }
}
