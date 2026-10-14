import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/school_event.dart';
import '../models/event_registration.dart';
import '../repositories/event_repository.dart';

/// Pantalla Administrativa del Colegio para Gestión de Eventos, Excursiones y Talleres
class AdminEventsScreen extends StatefulWidget {
  final EventRepository repository;
  final String? colegioId;

  const AdminEventsScreen({
    super.key,
    required this.repository,
    this.colegioId,
  });

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  List<SchoolEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.repository.getEvents(colegioId: widget.colegioId);
      if (mounted) {
        setState(() {
          _events = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalParticipants {
    int total = 0;
    for (final e in _events) {
      total += e.cuposOcupados;
    }
    return total;
  }

  double get _totalRevenue {
    double total = 0.0;
    for (final e in _events) {
      total += e.cuposOcupados * e.precio;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
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
                              'Gestión de Eventos & Excursiones',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Planificación de actividades extracurriculares, control de cupos y recaudación',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateEventDialog(context),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        label: const Text('Nuevo Evento Escolar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: AppColors.surfaceWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Métricas del Módulo de Eventos
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final isMedium = constraints.maxWidth >= 600;
                      final count = isWide ? 4 : (isMedium ? 2 : 1);

                      return GridView.count(
                        crossAxisCount: count,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 2.4 : 2.6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildMetricCard(
                            title: 'Eventos Publicados',
                            value: '${_events.length}',
                            subtitle: 'En calendario escolar activo',
                            icon: Icons.event_rounded,
                            color: AppColors.navyPrimary,
                          ),
                          _buildMetricCard(
                            title: 'Alumnos Inscritos',
                            value: '$_totalParticipants',
                            subtitle: 'Participantes confirmados',
                            icon: Icons.people_alt_rounded,
                            color: AppColors.electricBlue,
                          ),
                          _buildMetricCard(
                            title: 'Recaudación Estimada',
                            value: 'RD\$ ${_totalRevenue.toStringAsFixed(2)}',
                            subtitle: 'Generado por actividades',
                            icon: Icons.payments_rounded,
                            color: AppColors.accentGreen,
                          ),
                          _buildMetricCard(
                            title: 'Estado de Cupos',
                            value: '${_events.where((e) => e.tieneCupoDisponible).length} Abiertos',
                            subtitle: '${_events.where((e) => !e.tieneCupoDisponible).length} con cupo lleno',
                            icon: Icons.analytics_rounded,
                            color: const Color(0xFFB45309),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Listado de Eventos
                  const Text(
                    'Eventos Registrados en el Colegio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return _buildAdminEventCard(event);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
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

  Widget _buildAdminEventCard(SchoolEvent event) {
    final percent = (event.cuposOcupados / event.cupoMaximo).clamp(0.0, 1.0);
    final isFull = !event.tieneCupoDisponible;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.confirmation_number_rounded, color: AppColors.navyPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.electricBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.tipo,
                            style: const TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFull ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.estado.toUpperCase(),
                            style: TextStyle(
                              color: isFull ? const Color(0xFF991B1B) : const Color(0xFF166534),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.descripcion} • Lugar: ${event.lugar}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    event.esGratuito ? 'Gratuito' : 'RD\$ ${event.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navyPrimary),
                  ),
                  Text(
                    'Total: RD\$ ${(event.cuposOcupados * event.precio).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de ocupación de cupos
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFull ? const Color(0xFFDC2626) : AppColors.accentGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${event.cuposOcupados} / ${event.cupoMaximo} cupos (${(percent * 100).toInt()}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Fecha: ${event.fechaEvento.day.toString().padLeft(2, '0')}/${event.fechaEvento.month.toString().padLeft(2, '0')}/${event.fechaEvento.year} • Límite Inscripción: ${event.fechaLimiteInscripcion.day.toString().padLeft(2, '0')}/${event.fechaLimiteInscripcion.month.toString().padLeft(2, '0')}/${event.fechaLimiteInscripcion.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              OutlinedButton.icon(
                onPressed: () => _showParticipantsDialog(context, event),
                icon: const Icon(Icons.format_list_bulleted_rounded, size: 16),
                label: Text('Ver Participantes (${event.estudiantesInscritos.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showParticipantsDialog(BuildContext context, SchoolEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: AppColors.navyPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Participantes: ${event.titulo}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: event.estudiantesInscritos.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Aún no hay estudiantes inscritos en este evento.'),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: event.estudiantesInscritos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final studentName = event.estudiantesInscritos[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                        child: Text(
                          studentName.isNotEmpty ? studentName[0] : 'E',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                        ),
                      ),
                      title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Inscripción confirmada • Cupo #${index + 1}', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              foregroundColor: AppColors.surfaceWhite,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController(text: 'Instalaciones del Colegio');
    final priceController = TextEditingController(text: '0.00');
    final capacityController = TextEditingController(text: '50');
    String selectedType = 'Excursión';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 14));
    DateTime deadlineDate = DateTime.now().add(const Duration(days: 10));
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: AppColors.navyPrimary),
              SizedBox(width: 10),
              Text('Crear Evento o Excursión Escolar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título de la Actividad',
                    hintText: 'Ej. Excursión al Acuario Nacional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo de Actividad', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Excursión', child: Text('Excursión / Salida Educativa')),
                    DropdownMenuItem(value: 'Taller STEAM', child: Text('Taller de Ciencias / STEAM')),
                    DropdownMenuItem(value: 'Acto Institucional', child: Text('Acto Cultural / Institucional')),
                    DropdownMenuItem(value: 'Torneo Deportivo', child: Text('Torneo Deportivo Interescolar')),
                    DropdownMenuItem(value: 'Campamento', child: Text('Campamento de Temporada')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción & Objetivos',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lugar / Destino',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio (RD\$)',
                          prefixText: 'RD\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cupo Máximo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor ingresa el título del evento.')),
                        );
                        return;
                      }

                      final price = double.tryParse(priceController.text.replaceAll(',', '')) ?? 0.0;
                      final capacity = int.tryParse(capacityController.text.trim()) ?? 30;

                      setModalState(() => isSaving = true);

                      await widget.repository.createEvent(
                        colegioId: widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001',
                        titulo: titleController.text.trim(),
                        descripcion: descriptionController.text.trim(),
                        tipo: selectedType,
                        fechaEvento: selectedDate,
                        fechaLimiteInscripcion: deadlineDate,
                        lugar: locationController.text.trim(),
                        precio: price,
                        cupoMaximo: capacity,
                      );

                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        await _loadEvents();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Evento creado exitosamente y publicado en el Portal de Padres!'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: AppColors.surfaceWhite,
              ),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Publicar Evento'),
            ),
          ],
        ),
      ),
    );
  }
}
