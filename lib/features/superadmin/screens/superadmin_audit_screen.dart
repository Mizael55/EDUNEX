import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/audit_log.dart';
import '../repositories/audit_repository.dart';

/// Pantalla Completa de Auditoría y Trazabilidad para el SuperAdmin (Feedback QA)
class SuperAdminAuditScreen extends StatefulWidget {
  final AuditRepository repository;
  final String? colegioId;
  final String? schoolName;

  const SuperAdminAuditScreen({
    super.key,
    required this.repository,
    this.colegioId,
    this.schoolName,
  });

  @override
  State<SuperAdminAuditScreen> createState() => _SuperAdminAuditScreenState();
}

class _SuperAdminAuditScreenState extends State<SuperAdminAuditScreen> {
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String _selectedModulo = 'Todos';
  String _selectedNivel = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _modulos = [
    'Todos',
    'SaaS / SuperAdmin',
    'Institucional',
    'Finanzas',
    'Seguridad',
    'Académico',
  ];

  final List<String> _niveles = [
    'Todos',
    'INFO',
    'SUCCESS',
    'WARNING',
    'CRITICAL',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final results = await widget.repository.getAuditLogs(
      colegioId: widget.colegioId,
      modulo: _selectedModulo,
      nivel: _selectedNivel,
      query: _searchController.text,
    );
    if (mounted) {
      setState(() {
        _logs = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.schoolName != null
        ? 'Auditoría Institucional • ${widget.schoolName}'
        : 'Auditoría Global del Sistema & Trazabilidad SaaS';

    final subtitle = widget.schoolName != null
        ? 'Registro histórico y trazabilidad de operaciones para ${widget.schoolName}'
        : 'Supervisión en tiempo real de operaciones, accesos y cambios en la red de colegios EDUNEX';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SUPERVISIÓN & SEGURIDAD',
                              style: TextStyle(
                                color: AppColors.navyPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Text(
                            'Logs de Auditoría Inmutables',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadLogs,
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.navyPrimary),
                  tooltip: 'Actualizar logs de auditoría',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tarjetas de Métricas de Auditoría
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : (constraints.maxWidth >= 550 ? 2 : 1),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.2 : 2.5,
                  children: [
                    _buildMetricCard(
                      title: 'Eventos Registrados',
                      value: '${_logs.length}',
                      subtitle: 'Trazabilidad total activa',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildMetricCard(
                      title: 'Operaciones Exitosas',
                      value: '${_logs.where((l) => l.nivel == "SUCCESS" || l.nivel == "INFO").length}',
                      subtitle: 'Sin errores de sistema',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildMetricCard(
                      title: 'Cambios de Registro',
                      value: '${_logs.where((l) => l.modulo == "Institucional").length}',
                      subtitle: 'Documentos y datos de colegios',
                      icon: Icons.domain_verification_rounded,
                      color: AppColors.electricBlue,
                    ),
                    _buildMetricCard(
                      title: 'Alertas & Seguridad',
                      value: '${_logs.where((l) => l.nivel == "WARNING" || l.nivel == "CRITICAL").length}',
                      subtitle: 'Eventos que requieren atención',
                      icon: Icons.security_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Filtros y Búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Búsqueda
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _loadLogs(),
                      decoration: InputDecoration(
                        hintText: 'Buscar por acción, usuario o colegio...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  // Filtro Módulo
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Módulo: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: _selectedModulo,
                        underline: const SizedBox(),
                        items: _modulos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModulo = val);
                            _loadLogs();
                          }
                        },
                      ),
                    ],
                  ),

                  // Filtro Nivel
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nivel: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: _selectedNivel,
                        underline: const SizedBox(),
                        items: _niveles.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedNivel = val);
                            _loadLogs();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Lista / Tabla de Logs de Auditoría
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
                      const Icon(Icons.history_toggle_off_rounded, color: AppColors.navyPrimary, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Registro Histórico de Auditoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Mostrando ${_logs.length} eventos',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (_logs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text('No se encontraron eventos de auditoría con los filtros aplicados.', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return _buildLogRow(log);
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

  Widget _buildLogRow(AuditLog log) {
    return InkWell(
      onTap: () => _showLogDetail(log),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: log.nivelColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(log.icon, size: 18, color: log.nivelColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: log.nivelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.accion,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: log.nivelColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${log.modulo}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
                      ),
                      if (log.colegioNombre != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${log.colegioNombre})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${log.timestamp.day.toString().padLeft(2, '0')}/${log.timestamp.month.toString().padLeft(2, '0')}/${log.timestamp.year} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.descripcion,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${log.usuario} • Rol: ${log.rol}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (log.ipAddress != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.language_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          log.ipAddress!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetail(AuditLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(log.icon, color: log.nivelColor),
            const SizedBox(width: 10),
            Text(log.accion, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.descripcion, style: const TextStyle(fontSize: 14)),
              const Divider(height: 24),
              _buildDetailItem('ID Evento:', log.id),
              _buildDetailItem('Módulo:', log.modulo),
              _buildDetailItem('Nivel de Severidad:', log.nivel),
              _buildDetailItem('Usuario Ejecutor:', log.usuario),
              _buildDetailItem('Rol:', log.rol),
              if (log.colegioNombre != null) _buildDetailItem('Colegio:', log.colegioNombre!),
              if (log.ipAddress != null) _buildDetailItem('Dirección IP / Origen:', log.ipAddress!),
              _buildDetailItem('Fecha y Hora:', log.timestamp.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
        ],
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
