import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../../events/models/school_event.dart';
import '../../events/models/event_registration.dart';
import '../../events/repositories/event_repository.dart';

/// Pantalla del Tutor para Exploración e Inscripción de Hijos en Eventos y Excursiones Escolares
class ParentEventsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;
  final EventRepository? eventRepository;

  const ParentEventsScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
    this.eventRepository,
  });

  @override
  State<ParentEventsScreen> createState() => _ParentEventsScreenState();
}

class _ParentEventsScreenState extends State<ParentEventsScreen> {
  late final EventRepository _eventRepository;
  Family? _family;
  List<SchoolEvent> _events = [];
  List<EventRegistration> _myRegistrations = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _eventRepository = widget.eventRepository ?? EventRepository(familyRepository: widget.familyRepository);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );

      final events = await _eventRepository.getEvents(colegioId: widget.userProfile.colegioId);
      List<EventRegistration> regs = [];
      if (family != null) {
        regs = await _eventRepository.getRegistrationsForFamily(family.id);
      }

      if (mounted) {
        setState(() {
          _family = family;
          _events = events;
          _myRegistrations = regs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

    final filteredEvents = _selectedFilter == 'Todos'
        ? _events
        : _events.where((e) => e.tipo == _selectedFilter).toList();

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
                        'Eventos, Excursiones & Actividades',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inscribe a tus hijos en actividades curriculares y extracurriculares con cupos oficiales • ${family.nombreFamilia}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_added_rounded, color: AppColors.navyPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_myRegistrations.length} inscripciones activas',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Filtros de Categoría
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Excursión'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Taller STEAM'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Acto Institucional'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Torneo Deportivo'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Listado de Eventos
            if (filteredEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No hay eventos disponibles en esta categoría en este momento.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredEvents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return _buildEventCard(event, family);
                },
              ),

            if (_myRegistrations.isNotEmpty) ...[
              const SizedBox(height: 36),
              Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: AppColors.navyPrimary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Mis Hijos Inscritos Confirmados (${_myRegistrations.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myRegistrations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final reg = _myRegistrations[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reg.eventoTitulo,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Alumno: ${reg.estudianteNombre} • ${reg.metodoPago}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            reg.estadoPago.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
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
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.navyPrimary : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildEventCard(SchoolEvent event, Family family) {
    final isFull = !event.tieneCupoDisponible;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.event_available_rounded, color: AppColors.navyPrimary, size: 28),
              ),
              const SizedBox(width: 16),
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
                            style: const TextStyle(
                              color: AppColors.electricBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
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
                            isFull ? 'CUPO LLENO' : 'CUPOS DISPONIBLES',
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.descripcion,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    event.esGratuito ? 'GRATUITO' : 'RD\$ ${event.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.cuposRestantes} cupos libres de ${event.cupoMaximo}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFull ? const Color(0xFFDC2626) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Fecha: ${event.fechaEvento.day.toString().padLeft(2, '0')}/${event.fechaEvento.month.toString().padLeft(2, '0')}/${event.fechaEvento.year}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.place_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    event.lugar,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: isFull ? null : () => _showRegistrationDialog(context, event, family),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Inscribir a mi hijo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRegistrationDialog(BuildContext context, SchoolEvent event, Family family) {
    if (family.estudiantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay estudiantes registrados en la familia.')),
      );
      return;
    }

    String selectedStudentId = family.estudiantes.first.id;
    String selectedMethod = 'Tarjeta de Crédito / CardNET';
    bool isRegistering = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final student = family.estudiantes.firstWhere((s) => s.id == selectedStudentId);
          final alreadyEnrolled = event.estudiantesInscritos.contains(student.nombreCompleto);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, color: AppColors.navyPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Inscripción: ${event.titulo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
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
                    'Evento: ${event.titulo} (${event.tipo})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary, fontSize: 14),
                  ),
                  Text(
                    'Costo por estudiante: ${event.esGratuito ? "Gratuito" : "RD\$ " + event.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Selecciona el hijo a inscribir:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: family.estudiantes.map((st) {
                      return DropdownMenuItem(
                        value: st.id,
                        child: Text('${st.nombreCompleto} (${st.gradoNombre ?? "Nivel Inicial"})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedStudentId = val);
                    },
                  ),
                  if (alreadyEnrolled) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_rounded, color: Color(0xFFB45309), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este alumno ya se encuentra inscrito en este evento.',
                              style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!event.esGratuito) ...[
                    const SizedBox(height: 16),
                    const Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Tarjeta de Crédito / CardNET', child: Text('Tarjeta de Crédito / CardNET')),
                        DropdownMenuItem(value: 'Cargar a Cuenta Familiar', child: Text('Cargar a Estado de Cuenta Familiar')),
                        DropdownMenuItem(value: 'Transferencia Bancaria BHD', child: Text('Transferencia Bancaria BHD')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMethod = val);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isRegistering ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isRegistering || alreadyEnrolled
                    ? null
                    : () async {
                        setModalState(() => isRegistering = true);
                        try {
                          await _eventRepository.registerStudentToEvent(
                            eventoId: event.id,
                            familiaId: family.id,
                            estudianteId: student.id,
                            estudianteNombre: student.nombreCompleto,
                            metodoPago: selectedMethod,
                          );

                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            await _loadData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡${student.nombres} ha sido inscrito exitosamente en ${event.titulo}!'),
                                  backgroundColor: AppColors.accentGreen,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setModalState(() => isRegistering = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: AppColors.surfaceWhite,
                ),
                child: isRegistering
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar Inscripción'),
              ),
            ],
          );
        },
      ),
    );
  }
}
