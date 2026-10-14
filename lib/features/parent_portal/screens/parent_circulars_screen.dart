import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/models/student.dart';
import '../../families/repositories/family_repository.dart';
import '../../circulars/models/circular.dart';
import '../../circulars/repositories/circular_repository.dart';

/// Pantalla del Portal de Padres para Lectura de Circulares y Firma Digital de Autorizaciones
class ParentCircularsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;
  final CircularRepository? circularRepository;

  const ParentCircularsScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
    this.circularRepository,
  });

  @override
  State<ParentCircularsScreen> createState() => _ParentCircularsScreenState();
}

class _ParentCircularsScreenState extends State<ParentCircularsScreen> {
  late final CircularRepository _circularRepository;
  Family? _family;
  List<CircularItem> _circulars = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todas'; // 'Todas', 'Pendientes de Firma', 'Firmadas / Leídas'

  @override
  void initState() {
    super.initState();
    _circularRepository = widget.circularRepository ?? CircularRepository(familyRepository: widget.familyRepository);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );

      List<CircularItem> list = [];
      if (family != null) {
        final grados = family.estudiantes.map((s) => s.gradoNombre ?? '').toList();
        list = await _circularRepository.getCircularsForParent(
          colegioId: family.colegioId,
          tutorEmail: widget.userProfile.email,
          gradosHijos: grados,
        );
      }

      if (mounted) {
        setState(() {
          _family = family;
          _circulars = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSignatureDialog(CircularItem circular, Student student) {
    final cedulaCtrl = TextEditingController(text: '001-1234567-8');
    final commentCtrl = TextEditingController();
    bool consentGranted = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.draw_rounded, color: AppColors.navyPrimary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Firma Digital & Consentimiento Legal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      circular.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estudiante: ${student.nombreCompleto} (${student.gradoNombre ?? "Nivel Inicial"})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                          const SizedBox(height: 2),
                          Text('Tutor Firmante: ${widget.userProfile.nombreCompleto}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: cedulaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cédula o Documento de Identidad del Tutor *',
                        hintText: '001-0000000-0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: commentCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Comentario o aclaración médica (Opcional)',
                        hintText: 'Ej. No alérgico a picaduras, llevará su propia merienda...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: consentGranted,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.navyPrimary,
                      title: const Text(
                        'Declaro formalmente que he leído las normativas de esta circular y autorizo la actividad.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (val) => setModalState(() => consentGranted = val ?? true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: (isSubmitting || !consentGranted)
                    ? null
                    : () async {
                        setModalState(() => isSubmitting = true);
                        try {
                          final sig = CircularSignature(
                            id: 'sig-${DateTime.now().millisecondsSinceEpoch}',
                            tutorId: widget.userProfile.id,
                            tutorNombre: widget.userProfile.nombreCompleto,
                            tutorCedula: cedulaCtrl.text.trim(),
                            estudianteId: student.id,
                            estudianteNombre: student.nombreCompleto,
                            fechaFirma: DateTime.now(),
                            autorizado: true,
                            comentario: commentCtrl.text.trim().isNotEmpty ? commentCtrl.text.trim() : null,
                          );

                          await _circularRepository.signCircular(
                            circularId: circular.id,
                            signature: sig,
                          );

                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                            await _loadData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡Consentimiento formal registrado exitosamente para ${student.nombreCompleto}!'),
                                  backgroundColor: AppColors.accentGreen,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar Firma Digital'),
              ),
            ],
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

    final family = _family;
    if (family == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: Text('No se encontró expediente familiar.')),
      );
    }

    final filtered = _circulars.where((c) {
      if (_selectedFilter == 'Pendientes de Firma') {
        if (!c.requiereFirma) return false;
        // Si algún estudiante de la familia no ha firmado
        return family.estudiantes.any((st) => !c.haFirmado(st.id, widget.userProfile.id));
      } else if (_selectedFilter == 'Firmadas / Leídas') {
        return c.haLeido(widget.userProfile.email) ||
            family.estudiantes.any((st) => c.haFirmado(st.id, widget.userProfile.id));
      }
      return true;
    }).toList();

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
                        'Circulares Oficiales & Autorizaciones',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comunicados oficiales del colegio y autorizaciones pedagógicas con firma digital legal • ${family.nombreFamilia}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Filtros de navegación
            Row(
              children: [
                const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: ['Todas', 'Pendientes de Firma', 'Firmadas / Leídas'].map((f) {
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
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Lista de Circulares para la Familia
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No hay comunicados disponibles con este filtro.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildCircularCard(filtered[index], family);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularCard(CircularItem circular, Family family) {
    final dateStr =
        '${circular.fechaPublicacion.day.toString().padLeft(2, '0')}/${circular.fechaPublicacion.month.toString().padLeft(2, '0')}/${circular.fechaPublicacion.year}';

    // Determinar si hay alumnos pendientes de firma
    final pendingStudents = family.estudiantes.where((st) => !circular.haFirmado(st.id, widget.userProfile.id)).toList();
    final isPendingSignature = circular.requiereFirma && pendingStudents.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPendingSignature ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: isPendingSignature ? 1.5 : 1.0,
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
          // Banner de alerta de firma si aplica
          if (isPendingSignature) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Acción Requerida: Pendiente de autorización para ${pendingStudents.map((s) => s.nombres).join(", ")}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB45309)),
                    ),
                  ),
                  if (circular.fechaLimite != null)
                    Text(
                      'Límite: ${circular.fechaLimite!.day}/${circular.fechaLimite!.month}/${circular.fechaLimite!.year}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Cabecera: Categoría, Segmentación y Fecha
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  circular.categoria,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.navyPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Dirigido a: ${circular.segmentacion}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E40AF)),
                ),
              ),
              const Spacer(),
              Text('Fecha: $dateStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),

          const SizedBox(height: 12),
          Text(circular.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyPrimary)),
          const SizedBox(height: 4),
          Text('Remitente Oficial: ${circular.remitenteCargo}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text(circular.contenido, style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.9), height: 1.4)),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Acciones y firmas por estudiante
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Estado de firmas de los hijos
              if (circular.requiereFirma)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: family.estudiantes.map((st) {
                    final hasSigned = circular.haFirmado(st.id, widget.userProfile.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasSigned ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 14,
                            color: hasSigned ? AppColors.accentGreen : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${st.nombreCompleto}: ${hasSigned ? "Autorizado" : "Pendiente"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasSigned ? FontWeight.bold : FontWeight.normal,
                              color: hasSigned ? const Color(0xFF166534) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.accentGreen),
                    const SizedBox(width: 6),
                    const Text('Comunicado de carácter informativo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),

              // Botón de firma para alumnos pendientes
              if (isPendingSignature)
                ElevatedButton.icon(
                  onPressed: () => _showSignatureDialog(circular, pendingStudents.first),
                  icon: const Icon(Icons.draw_rounded, size: 16),
                  label: Text('Firmar para ${pendingStudents.first.nombres}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else if (circular.requiereFirma)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 16, color: Color(0xFF166534)),
                      SizedBox(width: 6),
                      Text('Autorizado Formalmente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
