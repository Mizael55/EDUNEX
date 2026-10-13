import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../models/student.dart';
import '../models/tutor.dart';

/// Modal para visualizar en detalle el expediente de una Cuenta Familiar Única
class FamilyDetailDialog extends StatelessWidget {
  final Family family;

  const FamilyDetailDialog({
    super.key,
    required this.family,
  });

  static Future<void> show(BuildContext context, Family family) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FamilyDetailDialog(family: family),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          children: [
            // Cabecera Institucional del Modal
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.navySecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: AppColors.surfaceWhite,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              family.codigoFamilia,
                              style: const TextStyle(
                                color: AppColors.amberAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: family.estaAlDia
                                    ? AppColors.accentGreen.withValues(alpha: 0.2)
                                    : AppColors.amberAccent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                family.estaAlDia ? 'AL DÍA' : 'PENDIENTE DE PAGO',
                                style: TextStyle(
                                  color: family.estaAlDia
                                      ? AppColors.accentGreen
                                      : AppColors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          family.nombreFamilia,
                          style: const TextStyle(
                            color: AppColors.surfaceWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (family.telefonoPrincipal != null ||
                            family.emailPrincipal != null) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              if (family.telefonoPrincipal != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone_rounded,
                                      size: 14,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      family.telefonoPrincipal!,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              if (family.emailPrincipal != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      family.emailPrincipal!,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Contenido con Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de Balance Consolidado de la Cuenta Familiar
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: family.estaAlDia
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: family.estaAlDia
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            family.estaAlDia
                                ? Icons.account_balance_wallet_rounded
                                : Icons.warning_amber_rounded,
                            color: family.estaAlDia
                                ? AppColors.accentGreen
                                : const Color(0xFFB45309),
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  family.estaAlDia
                                      ? 'Cuenta Familiar al Día'
                                      : 'Balance Pendiente Acumulado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: family.estaAlDia
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                                Text(
                                  family.estaAlDia
                                      ? 'RD\$ 0.00'
                                      : 'RD\$ ${family.balancePendiente.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: family.estaAlDia
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Abriendo pasarela de pago para ${family.nombreFamilia}',
                                  ),
                                  backgroundColor: AppColors.navyPrimary,
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              family.estaAlDia ? 'Historial Pagos' : 'Registrar Pago',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navyPrimary,
                              foregroundColor: AppColors.surfaceWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sección: Estudiantes matriculados (Hermanos agrupados)
                    Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: AppColors.navyPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hijos Matriculados (${family.estudiantes.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (family.estudiantes.isEmpty)
                      const Text(
                        'No hay estudiantes registrados en esta cuenta familiar.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: family.estudiantes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final student = family.estudiantes[index];
                          return _buildStudentCard(student, isDesktop);
                        },
                      ),

                    const SizedBox(height: 28),

                    // Sección: Tutores y Contactos Autorizados
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_rounded,
                          color: AppColors.navyPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tutores y Personas Autorizadas (${family.tutores.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (family.tutores.isEmpty)
                      const Text(
                        'No hay tutores registrados para esta familia.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: family.tutores.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tutor = family.tutores[index];
                          return _buildTutorCard(tutor);
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Footer con Botones de Acción
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Editando expediente de ${family.nombreFamilia}',
                          ),
                          backgroundColor: AppColors.navyPrimary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Editar Familia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.electricBlue.withValues(alpha: 0.12),
                child: Text(
                  student.nombres.isNotEmpty ? student.nombres[0] : 'E',
                  style: const TextStyle(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Matrícula: ${student.matricula} • ${student.gradoNombre ?? "Nivel Inicial"} (${student.seccionNombre ?? "Sección A"}) • ${student.edad} años',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (student.serviciosActivos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: student.serviciosActivos.map((service) {
                final isCuido = service.toLowerCase().contains('cuido');
                final isTransport = service.toLowerCase().contains('ruta');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCuido
                        ? AppColors.electricBlue.withValues(alpha: 0.1)
                        : (isTransport
                            ? AppColors.amberAccent.withValues(alpha: 0.15)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCuido
                          ? AppColors.electricBlue.withValues(alpha: 0.3)
                          : (isTransport
                              ? AppColors.amberAccent.withValues(alpha: 0.4)
                              : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCuido
                            ? Icons.child_care_rounded
                            : (isTransport
                                ? Icons.directions_bus_rounded
                                : Icons.check_circle_outline),
                        size: 13,
                        color: isCuido
                            ? AppColors.navyPrimary
                            : (isTransport
                                ? const Color(0xFFB45309)
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        service,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCuido
                              ? AppColors.navyPrimary
                              : (isTransport
                                  ? const Color(0xFFB45309)
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTutorCard(Tutor tutor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tutor.esContactoPrincipal
                ? AppColors.navyPrimary
                : const Color(0xFFCBD5E1),
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: tutor.esContactoPrincipal
                  ? AppColors.surfaceWhite
                  : const Color(0xFF475569),
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
                      tutor.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tutor.parentesco,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (tutor.esContactoPrincipal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRINCIPAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cédula: ${tutor.cedulaOPasaporte ?? "N/D"} • Tel: ${tutor.telefono ?? "N/D"}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (tutor.autorizadoRecoger)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 14,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Autorizado a retirar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
