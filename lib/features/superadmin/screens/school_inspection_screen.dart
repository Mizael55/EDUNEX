import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/school.dart';
import '../repositories/school_repository.dart';
import '../repositories/audit_repository.dart';
import '../models/audit_log.dart';
import 'edit_school_dialog.dart';
import 'reset_password_dialog.dart';
import '../../families/widgets/document_preview_dialog.dart';
import '../../families/models/student_document.dart';

/// Pantalla de Inspección Exclusiva para el SuperAdmin SaaS (Issue #23 & Feedback QA)
/// - Muestra exclusivamente la información institucional, legal, directiva y SaaS del colegio cliente.
/// - CERO opciones para agregar familias, matricular alumnos o crear datos operativos escolares.
/// - Botón para editar la información de registro del colegio.
class SchoolInspectionScreen extends StatefulWidget {
  final School school;
  final SchoolRepository schoolRepository;
  final AuditRepository? auditRepository;
  final VoidCallback onReturnToMaster;
  final ValueChanged<School>? onSchoolUpdated;

  const SchoolInspectionScreen({
    super.key,
    required this.school,
    required this.schoolRepository,
    this.auditRepository,
    required this.onReturnToMaster,
    this.onSchoolUpdated,
  });

  @override
  State<SchoolInspectionScreen> createState() => _SchoolInspectionScreenState();
}

class _SchoolInspectionScreenState extends State<SchoolInspectionScreen> {
  late School _school;
  List<AuditLog> _schoolAuditLogs = [];
  bool _isLoadingAudit = true;

  @override
  void initState() {
    super.initState();
    _school = widget.school;
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    final repo = widget.auditRepository ?? AuditRepository();
    final logs = await repo.getAuditLogs(colegioId: _school.id);
    if (mounted) {
      setState(() {
        _schoolAuditLogs = logs;
        _isLoadingAudit = false;
      });
    }
  }

  Future<void> _openEditSchoolDialog() async {
    final updated = await EditSchoolDialog.show(
      context,
      school: _school,
      repository: widget.schoolRepository,
    );
    if (updated != null && mounted) {
      setState(() => _school = updated);
      widget.onSchoolUpdated?.call(updated);
      _loadAuditLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Auditoría SaaS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_rounded, color: Color(0xFF1D4ED8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MODO AUDITORÍA SAAS: Inspeccionando la institución "${_school.nombre}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onReturnToMaster,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Volver al Panel Maestro'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.navyPrimary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cabecera Principal con Identidad y Botón de Editar Registro
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 750;
                  final infoSection = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.navyPrimary.withValues(alpha: 0.1),
                        child: Text(
                          _school.siglas ?? _school.nombre.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                Text(
                                  _school.nombre,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navyPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _school.isActive
                                        ? AppColors.accentGreen.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _school.isActive ? 'SUSCRIPCIÓN ACTIVA' : 'SUSCRIPCIÓN SUSPENDIDA',
                                    style: TextStyle(
                                      color: _school.isActive ? AppColors.accentGreen : Colors.red.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                if (_school.rnc != null)
                                  Text('RNC: ${_school.rnc}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                if (_school.telefono != null)
                                  Text('Tel: ${_school.telefono}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                if (_school.emailContacto != null)
                                  Text('Email: ${_school.emailContacto}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final editButton = ElevatedButton.icon(
                    onPressed: _openEditSchoolDialog,
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Editar Información de Registro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoSection,
                        const SizedBox(height: 16),
                        editButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: infoSection),
                      const SizedBox(width: 16),
                      editButton,
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Ficha Técnica y Legal
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.7 : 2.0,
                  children: [
                    // Tarjeta 1: Ficha Institucional & Capacidad MINERD
                    _buildInfoCard(
                      title: 'Ficha Institucional & Capacidad',
                      icon: Icons.account_balance_rounded,
                      headerAction: OutlinedButton.icon(
                        onPressed: () async {
                          final colegioEmail = _school.emailContacto ?? 'contacto@${_school.siglas?.toLowerCase() ?? "colegio"}.edu.do';
                          final reset = await ResetPasswordDialog.show(
                            context,
                            schoolId: _school.id,
                            schoolName: _school.nombre,
                            userEmail: colegioEmail,
                            userName: 'Cuenta Institucional (${_school.nombre})',
                            schoolRepository: widget.schoolRepository,
                          );
                          if (reset == true && mounted) {
                            _loadAuditLogs();
                          }
                        },
                        icon: const Icon(Icons.lock_reset_rounded, size: 14),
                        label: const Text('Resetear Contraseña Institucional', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB45309),
                          side: const BorderSide(color: Color(0xFFB45309)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      rows: [
                        _buildInfoRow('Nombre Oficial:', _school.nombre),
                        _buildInfoRow('Siglas / Acrónimo:', _school.siglas ?? 'No registradas'),
                        _buildInfoRow('RNC:', _school.rnc ?? 'Pendiente'),
                        _buildInfoRow('Dirección Física:', _school.direccion ?? 'República Dominicana'),
                        _buildInfoRow('Capacidad Autorizada:', '${_school.maxEstudiantes} estudiantes (MINERD)'),
                        _buildInfoRow('Matrícula Registrada:', '${_school.totalEstudiantes} estudiantes activos'),
                      ],
                    ),

                    // Tarjeta 2: Dirección & Representación Legal
                    _buildInfoCard(
                      title: 'Representación Legal & Dirección',
                      icon: Icons.badge_outlined,
                      headerAction: OutlinedButton.icon(
                        onPressed: () async {
                          final directorEmail = _school.directorEmail ?? _school.emailContacto ?? 'admin@ceno.edu.do';
                          final directorName = _school.directorNombre ?? 'Director(a) General';
                          final reset = await ResetPasswordDialog.show(
                            context,
                            schoolId: _school.id,
                            schoolName: _school.nombre,
                            userEmail: directorEmail,
                            userName: directorName,
                            schoolRepository: widget.schoolRepository,
                          );
                          if (reset == true && mounted) {
                            _loadAuditLogs();
                          }
                        },
                        icon: const Icon(Icons.lock_reset_rounded, size: 14),
                        label: const Text('Resetear Contraseña', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB45309),
                          side: const BorderSide(color: Color(0xFFB45309)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      rows: [
                        _buildInfoRow('Director(a) General:', _school.directorNombre ?? 'Dirección Académica CENO'),
                        _buildInfoRow('Cédula de Identidad:', _school.directorCedula ?? '001-0897654-3 (Validada)'),
                        _buildInfoRow('Teléfono Directivo:', _school.directorTelefono ?? _school.telefono ?? 'No especificado'),
                        _buildInfoRow('Email de Notificación:', _school.directorEmail ?? _school.emailContacto ?? 'admin@colegio.edu.do'),
                        _buildInfoRow('Sucursales Operativas:', '${_school.sucursalesCount} sedes asociadas'),
                        _buildInfoRow('Fecha de Enrolamiento:', 'Enero 2026 (Red EDUNEX SaaS)'),
                      ],
                    ),

                    // Tarjeta 3: Plan SaaS & Cobranza
                    _buildInfoCard(
                      title: 'Plan SaaS & Tarificación',
                      icon: Icons.monetization_on_rounded,
                      rows: [
                        _buildInfoRow('Rango de Matrícula:', _school.maxEstudiantes <= 250 ? '100 a 250 alumnos' : (_school.maxEstudiantes <= 400 ? '251 a 400 alumnos' : '450+ alumnos')),
                        _buildInfoRow('Cuota Mensual (MRR):', 'RD\$ ${_school.cuotaMensualSaaS.toStringAsFixed(2)}'),
                        _buildInfoRow('Facturación Anual (ARR):', 'RD\$ ${(_school.cuotaMensualSaaS * 12).toStringAsFixed(2)}'),
                        _buildInfoRow('Método de Pago:', _school.metodoPago ?? 'Tarjeta o Transferencia Bancaria configurada'),
                        _buildInfoRow('Estado del Contrato:', _school.isActive ? 'Al día (Servicio Activo)' : 'Suspendido por falta de pago'),
                      ],
                    ),

                    // Tarjeta 4: Documentos de Registro Institucional
                    _buildDocumentsCard(),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Tarjeta de Auditoría Institucional del Colegio
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
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: AppColors.navyPrimary, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Registro de Auditoría de la Institución',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_schoolAuditLogs.length} eventos registrados',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingAudit)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_schoolAuditLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text('No hay eventos de auditoría específicos para esta institución.'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _schoolAuditLogs.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final log = _schoolAuditLogs[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: log.nivelColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(log.icon, size: 16, color: log.nivelColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        log.accion,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: log.nivelColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${log.modulo}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.descripcion,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ejecutado por: ${log.usuario} (${log.rol})',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    Widget? headerAction,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Icon(icon, color: AppColors.navyPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard() {
    final registeredDocs = widget.schoolRepository.getSchoolDocuments(_school.id);
    final docs = registeredDocs.isNotEmpty
        ? registeredDocs
        : [
            StudentDocument(
              id: 'doc-inst-1',
              tipo: 'Registro Mercantil (Cámara de Comercio)',
              nombreArchivo: 'registro_mercantil_${_school.nombre.toLowerCase().replaceAll(' ', '_')}.pdf',
              fechaSubida: DateTime.now().subtract(const Duration(days: 30)),
              tamanoBytes: 1048576,
            ),
            StudentDocument(
              id: 'doc-inst-2',
              tipo: 'Estatutos Constitutivos de la Institución',
              nombreArchivo: 'estatutos_legales_colegio.pdf',
              fechaSubida: DateTime.now().subtract(const Duration(days: 30)),
              tamanoBytes: 2097152,
            ),
            StudentDocument(
              id: 'doc-inst-3',
              tipo: 'Cédula de Identidad del Director(a)',
              nombreArchivo: 'cedula_director_${_school.directorCedula ?? "identidad"}.jpg',
              fechaSubida: DateTime.now().subtract(const Duration(days: 28)),
              tamanoBytes: 524288,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
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
          const Row(
            children: [
              Icon(Icons.folder_shared_rounded, color: AppColors.navyPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'Documentos de Registro Oficial',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final isImg = doc.isImage;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isImg ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                        color: isImg ? const Color(0xFF0284C7) : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.tipo,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              doc.nombreArchivo,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.navyPrimary),
                        tooltip: 'Ver documento',
                        onPressed: () => DocumentPreviewDialog.show(
                          context,
                          document: doc,
                          studentName: _school.nombre,
                        ),
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
}
