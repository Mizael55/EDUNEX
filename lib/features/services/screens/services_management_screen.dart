import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../families/repositories/family_repository.dart';
import 'daycare_attendance_dialog.dart';
import 'transport_routes_dialog.dart';

/// Tipo de módulo de servicio operativo
enum ServiceModuleType { cuido, transporte, tienda }

/// Pantalla operativa para Cuido, Transporte y Tienda Escolar
class ServicesManagementScreen extends StatelessWidget {
  final ServiceModuleType moduleType;
  final String? colegioId;
  final FamilyRepository? familyRepository;

  const ServicesManagementScreen({
    super.key,
    required this.moduleType,
    this.colegioId,
    this.familyRepository,
  });

  @override
  Widget build(BuildContext context) {
    switch (moduleType) {
      case ServiceModuleType.cuido:
        return _buildCuidoView(context);
      case ServiceModuleType.transporte:
        return _buildTransporteView(context);
      case ServiceModuleType.tienda:
        return _buildTiendaView(context);
    }
  }

  Widget _buildCuidoView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servicios de Cuido Extracurricular',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Horario extendido de 3:00 PM a 6:00 PM con talleres, merienda y asistencia monitoreada.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => DaycareAttendanceDialog.show(context),
                  icon: const Icon(Icons.checklist_rounded, size: 18),
                  label: const Text('Abrir Control de Asistencia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Alumnos Inscritos',
                    value: '0',
                    subtitle: 'Capacidad de sala: 30',
                    icon: Icons.groups_rounded,
                    color: AppColors.electricBlue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'En Sala Ahora',
                    value: '0',
                    subtitle: 'Asistencia en tiempo real',
                    icon: Icons.child_care_rounded,
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Tarifa Mensual',
                    value: 'RD\$ 0.00',
                    subtitle: 'Facturado con colegiatura',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Programación Diaria del Cuido',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary),
                  ),
                  const SizedBox(height: 14),
                  _buildScheduleItem('03:00 PM - 03:30 PM', 'Recepción de Alumnos & Merienda Saludable', Icons.restaurant_rounded),
                  _buildScheduleItem('03:30 PM - 04:30 PM', 'Acompañamiento en Tareas & Refuerzo Pedagógico', Icons.menu_book_rounded),
                  _buildScheduleItem('04:30 PM - 05:30 PM', 'Actividades Lúdicas, Arte & Psicomotricidad', Icons.palette_rounded),
                  _buildScheduleItem('05:30 PM - 06:00 PM', 'Entrega a Tutores Autorizados con Verificación', Icons.verified_user_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransporteView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transporte Escolar & Monitoreo de Rutas',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rutas de autobuses, choferes certificados, unidades de transporte y paradas autorizadas.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => TransportRoutesDialog.show(context),
                  icon: const Icon(Icons.directions_bus_rounded, size: 18),
                  label: const Text('Monitoreo en Vivo de Rutas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Rutas Activas',
                    value: '0',
                    subtitle: 'Zonas escolares',
                    icon: Icons.map_rounded,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Alumnos Transportados',
                    value: '0',
                    subtitle: 'Capacidad vehicular',
                    icon: Icons.groups_rounded,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Seguridad en Ruta',
                    value: 'Sin rutas',
                    subtitle: 'Monitoreo activo',
                    icon: Icons.shield_rounded,
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Protocolo de Seguridad en Transporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary)),
                  const SizedBox(height: 14),
                  _buildScheduleItem('Asistente de Ruta', 'Cada autobús cuenta con una monitora que asiste en el abordaje y desembarque.', Icons.supervised_user_circle_rounded),
                  _buildScheduleItem('Notificación de Parada', 'Los tutores reciben confirmación cuando el estudiante aborda y arriba al colegio.', Icons.notifications_active_rounded),
                  _buildScheduleItem('Inspección Mecánica', 'Mantenimiento preventivo quincenal y revisión obligatoria de cinturones.', Icons.build_circle_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiendaView(BuildContext context) {
    final productos = <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tienda Escolar & Uniformes Oficiales',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inventario de prendas oficiales, libros de texto y pedidos realizados por las familias.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Catálogo de uniformes actualizado y sincronizado.'),
                        backgroundColor: AppColors.navyPrimary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Inventario Sincronizado'),
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
            if (productos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 36,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No hay productos registrados en inventario',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cuando se registren uniformes, textos o útiles escolares aparecerán listados aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = productos[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: AppColors.navyPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                            Text('Categoría: ${p["cat"]} • Tallas disponibles: ${p["tallas"]}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('RD\$ ${(p["precio"] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF166534))),
                          Text('${p["stock"]} unidades en inventario', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navyPrimary, size: 20),
          const SizedBox(width: 12),
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
