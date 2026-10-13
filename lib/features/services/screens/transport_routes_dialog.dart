import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Modelo de Ruta de Transporte Escolar
class BusRouteItem {
  final String id;
  final String name;
  final String driverName;
  final String driverPhone;
  final String vehicleInfo;
  final int assignedStudents;
  final int capacity;
  String status; // 'En Ruta', 'En Espera', 'Completada'

  BusRouteItem({
    required this.id,
    required this.name,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleInfo,
    required this.assignedStudents,
    required this.capacity,
    required this.status,
  });
}

/// Modal interactivo de Monitoreo de Rutas de Transporte Escolar
class TransportRoutesDialog extends StatefulWidget {
  const TransportRoutesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const TransportRoutesDialog(),
    );
  }

  @override
  State<TransportRoutesDialog> createState() => _TransportRoutesDialogState();
}

class _TransportRoutesDialogState extends State<TransportRoutesDialog> {
  final List<BusRouteItem> _routes = [
    BusRouteItem(
      id: 'ruta-1',
      name: 'Ruta 1 - Naco / Piantini / Serrallés',
      driverName: 'Ramón Bautista',
      driverPhone: '809-555-7711',
      vehicleInfo: 'Autobús Escolar Toyota Coaster (Ficha #04)',
      assignedStudents: 16,
      capacity: 22,
      status: 'En Ruta',
    ),
    BusRouteItem(
      id: 'ruta-2',
      name: 'Ruta 2 - Bella Vista / Mirador Sur',
      driverName: 'José Almonte',
      driverPhone: '809-555-8822',
      vehicleInfo: 'Minibús Hyundai County (Ficha #07)',
      assignedStudents: 14,
      capacity: 18,
      status: 'En Espera',
    ),
    BusRouteItem(
      id: 'ruta-3',
      name: 'Ruta 3 - Arroyo Hondo / Los Ríos',
      driverName: 'Héctor Rosario',
      driverPhone: '809-555-9933',
      vehicleInfo: 'Autobús Escolar Mercedes-Benz (Ficha #02)',
      assignedStudents: 20,
      capacity: 25,
      status: 'Completada',
    ),
  ];

  void _toggleStatus(BusRouteItem route) {
    setState(() {
      if (route.status == 'En Espera') {
        route.status = 'En Ruta';
      } else if (route.status == 'En Ruta') {
        route.status = 'Completada';
      } else {
        route.status = 'En Espera';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado de "${route.name}" cambiado a: ${route.status}'),
        backgroundColor: AppColors.navyPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 750),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB45309), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoreo de Rutas de Transporte Escolar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Control de choferes, unidades móviles, paradas y alumnos asignados.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: _routes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = _routes[index];
                  final statusColor = r.status == 'En Ruta'
                      ? AppColors.accentGreen
                      : (r.status == 'En Espera' ? Colors.orange.shade700 : AppColors.textSecondary);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                r.status,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('🚌 ${r.vehicleInfo}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('👤 Chofer: ${r.driverName} • 📞 ${r.driverPhone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Capacidad: ${r.assignedStudents} / ${r.capacity} cupos ocupados',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () => _toggleStatus(r),
                              icon: const Icon(Icons.sync_rounded, size: 14),
                              label: const Text('Cambiar Estado', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navyPrimary,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary, foregroundColor: Colors.white),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
