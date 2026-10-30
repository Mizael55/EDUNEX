import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/bus_route.dart';
import '../repositories/transport_repository.dart';

/// Pantalla del Administrador y Coordinador de Transporte para Gestión de Rutas y Abordaje
class AdminTransportScreen extends StatefulWidget {
  final TransportRepository repository;
  final String? colegioId;

  const AdminTransportScreen({
    super.key,
    required this.repository,
    this.colegioId,
  });

  @override
  State<AdminTransportScreen> createState() => _AdminTransportScreenState();
}

class _AdminTransportScreenState extends State<AdminTransportScreen> {
  List<BusRoute> _routes = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedFilter = 'Todas'; // 'Todas', 'En Tránsito', 'En Espera', 'Completadas'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schoolId = widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001';
      final list = await widget.repository.getRoutes(colegioId: schoolId);
      final stats = await widget.repository.getTransportStats(colegioId: schoolId);

      if (mounted) {
        setState(() {
          _routes = list;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewRouteDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final zoneCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '24');
    final driverCtrl = TextEditingController();
    final driverPhoneCtrl = TextEditingController();
    final monitorCtrl = TextEditingController();
    final monitorPhoneCtrl = TextEditingController();
    String turno = 'Completo';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.directions_bus_rounded, color: AppColors.navyPrimary),
                SizedBox(width: 10),
                Text('Nueva Ruta de Transporte Escolar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Ruta *',
                          hintText: 'Ej. Ruta 4 - Los Prados / San Gerónimo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: zoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Zona Geográfica *',
                                hintText: 'Ej. Santo Domingo Oeste',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: turno,
                              decoration: const InputDecoration(labelText: 'Turno', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Completo', child: Text('Completo (AM/PM)')),
                                DropdownMenuItem(value: 'Matutino', child: Text('Solo Matutino')),
                                DropdownMenuItem(value: 'Vespertino', child: Text('Solo Vespertino')),
                              ],
                              onChanged: (v) => setModalState(() => turno = v ?? 'Completo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Datos del Vehículo / Unidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: plateCtrl,
                              decoration: const InputDecoration(labelText: 'Placa *', hintText: 'I-099123', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: modelCtrl,
                              decoration: const InputDecoration(labelText: 'Modelo / Año *', hintText: 'Toyota Coaster 2024', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: capacityCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Capacidad *', border: OutlineInputBorder()),
                              validator: (v) => v == null || int.tryParse(v) == null ? 'Inválido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Personal a Bordo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: driverCtrl,
                              decoration: const InputDecoration(labelText: 'Nombre del Chofer *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: driverPhoneCtrl,
                              decoration: const InputDecoration(labelText: 'Teléfono Chofer *', hintText: '809-555-0000', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: monitorCtrl,
                              decoration: const InputDecoration(labelText: 'Monitora de Ruta *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: monitorPhoneCtrl,
                              decoration: const InputDecoration(labelText: 'Teléfono Monitora *', hintText: '809-555-0000', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final newRoute = BusRoute(
                      id: 'route-${DateTime.now().millisecondsSinceEpoch}',
                      colegioId: widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001',
                      codigo: 'RUTA-0${_routes.length + 1}',
                      nombre: nameCtrl.text.trim(),
                      turno: turno,
                      vehiculoPlaca: plateCtrl.text.trim().toUpperCase(),
                      vehiculoModelo: modelCtrl.text.trim(),
                      capacidadAsientos: int.parse(capacityCtrl.text.trim()),
                      choferNombre: driverCtrl.text.trim(),
                      choferTelefono: driverPhoneCtrl.text.trim(),
                      choferLicencia: '001-0000000-0',
                      monitoraNombre: monitorCtrl.text.trim(),
                      monitoraTelefono: monitorPhoneCtrl.text.trim(),
                      zonaGeografica: zoneCtrl.text.trim(),
                      estadoRuta: 'En Espera',
                    );

                    await widget.repository.createRoute(newRoute);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      await _loadData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡Ruta "${newRoute.nombre}" creada y lista para operar!'),
                            backgroundColor: AppColors.accentGreen,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary, foregroundColor: Colors.white),
                child: const Text('Crear Ruta Escolar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPassengerSheet(BusRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final passengers = route.pasajeros;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Cabecera del modal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.navyPrimary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoja de Pasajeros & Abordaje: ${route.codigo}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${route.nombre} • ${passengers.length} alumnos asignados (${route.asientosDisponibles} asientos libres)',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Lista de pasajeros
                Expanded(
                  child: passengers.isEmpty
                      ? const Center(
                          child: Text('No hay estudiantes asignados a esta ruta aún.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: passengers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final p = passengers[idx];

                            Color statusColor;
                            switch (p.estadoAbordaje) {
                              case 'Abordó Autobús':
                                statusColor = AppColors.accentGreen;
                                break;
                              case 'Entregado en Destino':
                                statusColor = AppColors.electricBlue;
                                break;
                              case 'No Viaja Hoy':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = const Color(0xFFB45309);
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person_rounded, color: AppColors.navyPrimary),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.estudianteNombre,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${p.gradoNombre} (${p.seccionNombre}) • Parada: ${p.paradaNombre}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          'Tutor: ${p.tutorContacto} (${p.tutorTelefono})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        if (p.horaCheckIn != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Hora de abordaje: ${p.horaCheckIn}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Selector rápido de estado
                                  PopupMenuButton<String>(
                                    tooltip: 'Cambiar Estado de Abordaje',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            p.estadoAbordaje,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_drop_down, size: 18, color: statusColor),
                                        ],
                                      ),
                                    ),
                                    onSelected: (newStatus) async {
                                      await widget.repository.updatePassengerStatus(
                                        routeId: route.id,
                                        estudianteId: p.estudianteId,
                                        nuevoEstado: newStatus,
                                      );
                                      final updated = await widget.repository.getRouteById(route.id);
                                      if (updated != null && mounted) {
                                        setSheetState(() => route = updated);
                                        await _loadData();
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'En Espera en Parada', child: Text('En Espera en Parada')),
                                      PopupMenuItem(value: 'Abordó Autobús', child: Text('Abordó Autobús')),
                                      PopupMenuItem(value: 'Entregado en Destino', child: Text('Entregado en Destino')),
                                      PopupMenuItem(value: 'No Viaja Hoy', child: Text('No Viaja Hoy')),
                                    ],
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredRoutes = _selectedFilter == 'Todas'
        ? _routes
        : _routes.where((r) => r.estadoRuta == _selectedFilter).toList();

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
                      const Text(
                        'Transporte Escolar & Monitoreo de Rutas',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control operativo de unidades, choferes certificados, paradas autorizadas y lista de pasajeros.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showNewRouteDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nueva Ruta Escolar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tarjetas KPI Responsivas
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isMedium = constraints.maxWidth >= 600;
                final count = isWide ? 4 : (isMedium ? 2 : 1);

                return GridView.count(
                  crossAxisCount: count,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 2.6 : 2.3,
                  children: [
                    _buildKpiCard(
                      title: 'Rutas Operativas',
                      value: '${_stats['totalRutas'] ?? 0}',
                      subtitle: '${_stats['totalVehiculos'] ?? 0} unidades vehiculares',
                      icon: Icons.directions_bus_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildKpiCard(
                      title: 'Alumnos en Ruta',
                      value: '${_stats['totalAlumnos'] ?? 0}',
                      subtitle: 'De ${_stats['totalAsientos'] ?? 0} asientos totales',
                      icon: Icons.groups_rounded,
                      color: AppColors.electricBlue,
                    ),
                    _buildKpiCard(
                      title: 'En Tránsito Ahora',
                      value: '${_stats['rutasEnTransito'] ?? 0}',
                      subtitle: 'Monitoreo en vivo',
                      icon: Icons.near_me_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildKpiCard(
                      title: 'Ocupación de Flota',
                      value: '${((_stats['porcentajeOcupacion'] as num?) ?? 0).toStringAsFixed(1)}%',
                      subtitle: '${_stats['asientosDisponibles'] ?? 0} asientos disponibles',
                      icon: Icons.pie_chart_rounded,
                      color: const Color(0xFFB45309),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Filtros de Estado
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Filtrar Rutas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 4),
                ...['Todas', 'En Tránsito', 'En Espera', 'Completada'].map((f) {
                  final isSelected = _selectedFilter == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    selectedColor: AppColors.navyPrimary,
                    backgroundColor: AppColors.surfaceWhite,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.surfaceWhite : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 18),

            // Catálogo de Rutas
            if (filteredRoutes.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No hay rutas registradas con este criterio de filtro.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRoutes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildRouteCard(filteredRoutes[index]);
                },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
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

  Widget _buildRouteCard(BusRoute route) {
    Color statusColor;
    IconData statusIcon;
    switch (route.estadoRuta) {
      case 'En Tránsito':
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.near_me_rounded;
        break;
      case 'Completada':
        statusColor = AppColors.electricBlue;
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = const Color(0xFFB45309);
        statusIcon = Icons.access_time_filled_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: route.enTransito ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: route.enTransito ? 1.5 : 1.0,
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
          // Fila 1: Código, Nombre y Estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  route.codigo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  route.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      route.estadoRuta,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Fila 2: Información del vehículo y personal
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Unidad: ${route.vehiculoModelo} (Placa ${route.vehiculoPlaca})',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chofer: ${route.choferNombre} • Tel: ${route.choferTelefono}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Monitora: ${route.monitoraNombre} • Tel: ${route.monitoraTelefono}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Ocupación de Asientos
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${route.totalPasajeros} / ${route.capacidadAsientos} Asientos',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      value: route.porcentajeOcupacion / 100,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: route.estaLlena ? Colors.red : AppColors.accentGreen,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${route.asientosDisponibles} asientos disponibles',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Fila 3: Botones de Acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cambiar Estado Operativo de la Ruta
              Row(
                children: [
                  const Text('Estado Operativo: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      String nextStatus = 'En Tránsito';
                      if (route.estadoRuta == 'En Tránsito') {
                        nextStatus = 'Completada';
                      } else if (route.estadoRuta == 'Completada') {
                        nextStatus = 'En Espera';
                      }
                      await widget.repository.updateRouteStatus(route.id, nextStatus);
                      await _loadData();
                    },
                    icon: Icon(
                      route.enTransito ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                      size: 16,
                      color: AppColors.navyPrimary,
                    ),
                    label: Text(
                      route.enTransito ? 'Finalizar Recorrido' : (route.completada ? 'Reiniciar Recorrido' : 'Iniciar Recorrido'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),

              // Ver Hoja de Abordaje
              ElevatedButton.icon(
                onPressed: () => _showPassengerSheet(route),
                icon: const Icon(Icons.people_alt_rounded, size: 16),
                label: Text('Hoja de Pasajeros (${route.totalPasajeros})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
