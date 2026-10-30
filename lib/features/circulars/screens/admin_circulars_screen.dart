import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/circular.dart';
import '../repositories/circular_repository.dart';

/// Pantalla del Administrador y Dirección para Emisión de Circulares y Control de Firmas
class AdminCircularsScreen extends StatefulWidget {
  final CircularRepository repository;
  final String? colegioId;

  const AdminCircularsScreen({
    super.key,
    required this.repository,
    this.colegioId,
  });

  @override
  State<AdminCircularsScreen> createState() => _AdminCircularsScreenState();
}

class _AdminCircularsScreenState extends State<AdminCircularsScreen> {
  List<CircularItem> _circulars = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedFilter = 'Todas'; // 'Todas', 'Requieren Firma', 'Institucional', 'Académica', 'Feriado / Calendario'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schoolId = widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001';
      final list = await widget.repository.getCirculars(colegioId: schoolId);
      final stats = await widget.repository.getCircularStats(colegioId: schoolId);

      if (mounted) {
        setState(() {
          _circulars = list;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewCircularDialog() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final senderCtrl = TextEditingController(text: 'Dirección Académica Central');
    String categoria = 'Institucional';
    String segmentacion = 'Todo el Colegio';
    bool requiereFirma = false;
    DateTime? fechaLimite;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.campaign_rounded, color: AppColors.navyPrimary),
                SizedBox(width: 10),
                Text('Redactar Nueva Circular Oficial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: SizedBox(
                  width: 550,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Título de la Circular *',
                          hintText: 'Ej. Circular No. 06: Normativa de Talleres Extracurriculares',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: categoria,
                              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Institucional', child: Text('Institucional')),
                                DropdownMenuItem(value: 'Académica', child: Text('Académica')),
                                DropdownMenuItem(value: 'Feriado / Calendario', child: Text('Feriado / Calendario')),
                                DropdownMenuItem(value: 'Autorización Requerida', child: Text('Autorización Requerida')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setModalState(() {
                                    categoria = v;
                                    if (v == 'Autorización Requerida') requiereFirma = true;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: segmentacion,
                              decoration: const InputDecoration(labelText: 'Dirigido a', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Todo el Colegio', child: Text('Todo el Colegio')),
                                DropdownMenuItem(value: 'Kinder', child: Text('Kinder')),
                                DropdownMenuItem(value: 'Pre-Primario', child: Text('Pre-Primario')),
                                DropdownMenuItem(value: '1ro de Primaria', child: Text('1ro de Primaria')),
                                DropdownMenuItem(value: '2do de Primaria', child: Text('2do de Primaria')),
                                DropdownMenuItem(value: '3ro de Primaria', child: Text('3ro de Primaria')),
                              ],
                              onChanged: (v) {
                                if (v != null) setModalState(() => segmentacion = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: senderCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Departamento o Remitente *',
                          hintText: 'Ej. Dirección General',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: requiereFirma,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Requiere Autorización / Firma Digital del Tutor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('El tutor deberá firmar digitalmente con su cédula para confirmar su consentimiento.', style: TextStyle(fontSize: 11)),
                        onChanged: (v) => setModalState(() => requiereFirma = v ?? false),
                      ),
                      if (requiereFirma) ...[
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 120)),
                            );
                            if (picked != null) setModalState(() => fechaLimite = picked);
                          },
                          icon: const Icon(Icons.event_rounded, size: 16),
                          label: Text(fechaLimite == null
                              ? 'Fijar Fecha Límite de Firma (Opcional)'
                              : 'Fecha Límite: ${fechaLimite!.day}/${fechaLimite!.month}/${fechaLimite!.year}'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bodyCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Cuerpo del Comunicado *',
                          hintText: 'Redacte el comunicado oficial para las familias...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final newCirc = CircularItem(
                      id: 'circ-${DateTime.now().millisecondsSinceEpoch}',
                      colegioId: widget.colegioId ?? 'a0000000-0000-0000-0000-000000000001',
                      titulo: titleCtrl.text.trim(),
                      contenido: bodyCtrl.text.trim(),
                      categoria: categoria,
                      fechaPublicacion: DateTime.now(),
                      fechaLimite: fechaLimite,
                      segmentacion: segmentacion,
                      requiereFirma: requiereFirma,
                      remitenteCargo: senderCtrl.text.trim(),
                    );

                    await widget.repository.createCircular(newCirc);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      await _loadData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Circular oficial publicada y distribuida a las familias!'),
                            backgroundColor: AppColors.accentGreen,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary, foregroundColor: Colors.white),
                child: const Text('Publicar Circular'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSignaturesSheet(CircularItem circular) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
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
                    child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registro Oficial de Firmas Digitales',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          circular.titulo,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
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
            Expanded(
              child: circular.firmas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('No se han registrado firmas para esta circular todavía.'),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: circular.firmas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final sig = circular.firmas[idx];
                        final dateStr =
                            '${sig.fechaFirma.day.toString().padLeft(2, '0')}/${sig.fechaFirma.month.toString().padLeft(2, '0')}/${sig.fechaFirma.year} ${sig.fechaFirma.hour.toString().padLeft(2, '0')}:${sig.fechaFirma.minute.toString().padLeft(2, '0')}';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.verified_rounded, color: Color(0xFF166534), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tutor: ${sig.tutorNombre} (Cédula: ${sig.tutorCedula})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Consentimiento para: ${sig.estudianteNombre}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                    ),
                                    if (sig.comentario != null) ...[
                                      const SizedBox(height: 2),
                                      Text('Nota: "${sig.comentario}"', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                                    ],
                                    const SizedBox(height: 2),
                                    Text('Fecha y Hora de Firma: $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
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

    final filtered = _selectedFilter == 'Todas'
        ? _circulars
        : (_selectedFilter == 'Requieren Firma'
            ? _circulars.where((c) => c.requiereFirma).toList()
            : _circulars.where((c) => c.categoria == _selectedFilter).toList());

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
                        'Circulares Oficiales & Comunicados',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Emisión de avisos institucionales, normativas pedagógicas y recolección de firmas digitales con valor formal.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showNewCircularDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Redactar Circular'),
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

            // Tarjetas KPI
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
                      title: 'Circulares Publicadas',
                      value: '${_stats['totalPublicadas'] ?? 0}',
                      subtitle: 'Canal oficial activo',
                      icon: Icons.campaign_rounded,
                      color: AppColors.navyPrimary,
                    ),
                    _buildKpiCard(
                      title: 'Con Autorización',
                      value: '${_stats['requierenFirma'] ?? 0}',
                      subtitle: 'Requieren consentimiento legal',
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFFB45309),
                    ),
                    _buildKpiCard(
                      title: 'Firmas Recibidas',
                      value: '${_stats['totalFirmasRecibidas'] ?? 0}',
                      subtitle: 'Tutores que han firmado',
                      icon: Icons.history_edu_rounded,
                      color: AppColors.accentGreen,
                    ),
                    _buildKpiCard(
                      title: 'Lecturas Registradas',
                      value: '${_stats['totalLecturas'] ?? 0}',
                      subtitle: 'Confirmaciones de apertura',
                      icon: Icons.mark_email_read_rounded,
                      color: AppColors.electricBlue,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Filtros de Categoría
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 4),
                ...['Todas', 'Requieren Firma', 'Institucional', 'Académica', 'Feriado / Calendario'].map((f) {
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

            // Lista de Circulares
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No hay circulares publicadas con este filtro.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildCircularCard(filtered[index]);
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

  Widget _buildCircularCard(CircularItem circular) {
    Color badgeColor;
    Color badgeTextColor;
    switch (circular.categoria) {
      case 'Autorización Requerida':
        badgeColor = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFFB45309);
        break;
      case 'Académica':
        badgeColor = const Color(0xFFDBEAFE);
        badgeTextColor = const Color(0xFF1D4ED8);
        break;
      case 'Feriado / Calendario':
        badgeColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        break;
      default:
        badgeColor = const Color(0xFFF1F5F9);
        badgeTextColor = const Color(0xFF334155);
    }

    final dateStr =
        '${circular.fechaPublicacion.day.toString().padLeft(2, '0')}/${circular.fechaPublicacion.month.toString().padLeft(2, '0')}/${circular.fechaPublicacion.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: circular.requiereFirma ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: circular.requiereFirma ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                child: Text(circular.categoria, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: badgeTextColor)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: Text('Para: ${circular.segmentacion}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E40AF))),
              ),
              const Spacer(),
              Text('Publicado: $dateStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(circular.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary)),
          const SizedBox(height: 4),
          Text('Remitente: ${circular.remitenteCargo}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text(circular.contenido, style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.9), height: 1.4)),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('${circular.totalLecturas} tutores han leído este comunicado', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              if (circular.requiereFirma)
                ElevatedButton.icon(
                  onPressed: () => _showSignaturesSheet(circular),
                  icon: const Icon(Icons.history_edu_rounded, size: 16),
                  label: Text('Ver Firmas Recibidas (${circular.totalFirmas})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
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
