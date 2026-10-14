import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/models/student.dart';
import '../../families/repositories/family_repository.dart';

/// Pantalla del Tutor para Gestión de Servicios Escolares por Hijo (Cuido, Transporte, Comedor, Tutorías)
class ParentServicesScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;

  const ParentServicesScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
  });

  @override
  State<ParentServicesScreen> createState() => _ParentServicesScreenState();
}

class _ParentServicesScreenState extends State<ParentServicesScreen> {
  Family? _family;
  bool _isLoading = true;

  final Map<String, _ServiceInfo> _availableServices = {
    'Cuido Vespertino': const _ServiceInfo(
      title: 'Cuido Vespertino (3:00 – 6:00 PM)',
      description: 'Supervisión profesional, apoyo en tareas dirigidas y merienda balanceada.',
      price: 2500.0,
      icon: Icons.child_care_rounded,
      color: AppColors.electricBlue,
    ),
    'Transporte Escolar': const _ServiceInfo(
      title: 'Transporte Escolar (Puerta a Puerta)',
      description: 'Rutas seguras con monitoreo GPS en vivo y acompañante escolar.',
      price: 3200.0,
      icon: Icons.directions_bus_rounded,
      color: Color(0xFFB45309),
    ),
    'Comedor Escolar': const _ServiceInfo(
      title: 'Comedor Escolar Nutricional',
      description: 'Almuerzos diarios balanceados supervisados por nutricionista pediátrica.',
      price: 2800.0,
      icon: Icons.restaurant_rounded,
      color: AppColors.accentGreen,
    ),
    'Tutorías Académicas': const _ServiceInfo(
      title: 'Tutorías Académicas Reforzadas',
      description: 'Refuerzo vespertino personalizado en Matemáticas y Lectoescritura.',
      price: 1800.0,
      icon: Icons.menu_book_rounded,
      color: AppColors.navyPrimary,
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    setState(() => _isLoading = true);
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );
      if (mounted) {
        setState(() {
          _family = family;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateTotalServicesCost(List<Student> students) {
    double total = 0.0;
    for (final s in students) {
      for (final activeS in s.serviciosActivos) {
        for (final entry in _availableServices.entries) {
          if (activeS.toLowerCase().contains(entry.key.toLowerCase())) {
            total += entry.value.price;
            break;
          }
        }
      }
    }
    return total;
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
        body: Center(child: Text('No se encontró expediente familiar.')),
      );
    }

    final totalCost = _calculateTotalServicesCost(family.estudiantes);

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
                        'Gestión de Servicios Escolares',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Activa o pausa servicios adicionales para cada hijo matriculado • ${family.nombreFamilia}',
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

            // Resumen de Inversión Mensual en Servicios
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.electricBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyPrimary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.room_service_rounded, color: AppColors.surfaceWhite, size: 32),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INVERSIÓN MENSUAL EN SERVICIOS ADICIONALES',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RD\$ ${totalCost.toStringAsFixed(2)} / mes',
                          style: const TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Los servicios activos se consolidan automáticamente en tu factura mensual.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Lista de Hijos con sus Servicios
            ...family.estudiantes.map((student) => _buildStudentServicesCard(family, student)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentServicesCard(Family family, Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
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
          // Cabecera del Estudiante
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                child: Text(
                  student.nombres.isNotEmpty ? student.nombres[0] : 'E',
                  style: const TextStyle(
                    color: AppColors.navyPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${student.gradoNombre ?? "Nivel Inicial"} • ${student.seccionNombre ?? "Sección A"} • Matrícula: ${student.matricula}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${student.serviciosActivos.length} activos',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Lista de Opciones de Servicios Disponibles
          ..._availableServices.entries.map((entry) {
            final key = entry.key;
            final info = entry.value;
            final isActive = student.serviciosActivos.any(
              (s) => s.toLowerCase().contains(key.toLowerCase()),
            );

            return Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? info.color.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? info.color.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(info.icon, color: info.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                info.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'RD\$ ${info.price.toStringAsFixed(2)}/mes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: info.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeColor: info.color,
                      onChanged: (bool newVal) async {
                        await widget.familyRepository.toggleStudentService(
                          familiaId: family.id,
                          studentId: student.id,
                          servicio: key,
                          activar: newVal,
                        );
                        await _loadFamily();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newVal
                                    ? 'Servicio "${info.title}" contratado para ${student.nombres}'
                                    : 'Servicio "${info.title}" pausado para ${student.nombres}',
                              ),
                              backgroundColor: newVal ? AppColors.accentGreen : AppColors.navyPrimary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ServiceInfo {
  final String title;
  final String description;
  final double price;
  final IconData icon;
  final Color color;

  const _ServiceInfo({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}
