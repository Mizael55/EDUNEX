import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../../families/models/family.dart';
import '../../families/repositories/family_repository.dart';
import '../models/parent_question.dart';

/// Pantalla del Tutor para Canal Directo de Consultas y Preguntas con el Centro Escolar
class ParentQuestionsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final FamilyRepository familyRepository;

  const ParentQuestionsScreen({
    super.key,
    required this.userProfile,
    required this.familyRepository,
  });

  @override
  State<ParentQuestionsScreen> createState() => _ParentQuestionsScreenState();
}

class _ParentQuestionsScreenState extends State<ParentQuestionsScreen> {
  Family? _family;
  List<ParentQuestion> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final family = await widget.familyRepository.getFamilyForCurrentUser(
        email: widget.userProfile.email,
        colegioId: widget.userProfile.colegioId,
      );

      List<ParentQuestion> questions = [];
      if (family != null) {
        questions = await widget.familyRepository.getQuestionsForFamily(family.id);
      }

      if (mounted) {
        setState(() {
          _family = family;
          _questions = questions;
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
        body: Center(child: Text('No se encontró expediente familiar.')),
      );
    }

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
                        'Canal de Consultas & Preguntas',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comunicación directa con la dirección, docentes y secretaría • ${family.nombreFamilia}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNewQuestionDialog(context, family),
                  icon: const Icon(Icons.add_comment_rounded, size: 18),
                  label: const Text('Nueva Consulta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: AppColors.surfaceWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Banner informativo
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.electricBlue, size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Tus consultas son atendidas por el personal administrativo y docente en un plazo máximo de 24 horas laborables.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Lista de Consultas
            if (_questions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'No tienes consultas o preguntas enviadas.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => _showNewQuestionDialog(context, family),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: AppColors.surfaceWhite,
                        ),
                        child: const Text('Enviar mi primera pregunta'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final isAnswered = q.estado.toLowerCase().contains('respondida');

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAnswered ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.navyPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                q.departamento,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAnswered ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                q.estado,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isAnswered ? const Color(0xFF166534) : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q.asunto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${q.fechaEnvio.day.toString().padLeft(2, '0')}/${q.fechaEnvio.month.toString().padLeft(2, '0')}/${q.fechaEnvio.year} • Por: ${q.tutorNombre}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          q.mensaje,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        if (q.respuestaCentro != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.school_rounded, size: 16, color: AppColors.accentGreen),
                                    const SizedBox(width: 8),
                                    Text(
                                      q.respondidoPor ?? 'Respuesta Oficial del Colegio',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  q.respuestaCentro!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  void _showNewQuestionDialog(BuildContext context, Family family) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String selectedDept = 'Dirección Académica';
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.question_answer_rounded, color: AppColors.navyPrimary),
              SizedBox(width: 10),
              Text('Hacer una Pregunta al Centro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el departamento adecuado para que tu consulta sea canalizada con prontitud.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDept,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Departamento Destinatario',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Dirección Académica', child: Text('Dirección Académica & Docencia')),
                    DropdownMenuItem(value: 'Caja y Facturación', child: Text('Caja, Facturación & Cobranzas')),
                    DropdownMenuItem(value: 'Psicología y Orientación', child: Text('Psicología & Orientación Escolar')),
                    DropdownMenuItem(value: 'Secretaría Escolar', child: Text('Secretaría & Admisiones')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedDept = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Asunto de la Consulta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detalla tu pregunta o consulta...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (subjectController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor completa el asunto y el mensaje.')),
                        );
                        return;
                      }

                      setModalState(() => isSending = true);

                      await widget.familyRepository.submitQuestion(
                        familiaId: family.id,
                        tutorNombre: widget.userProfile.nombreCompleto,
                        departamento: selectedDept,
                        asunto: subjectController.text.trim(),
                        mensaje: messageController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        await _loadData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pregunta enviada correctamente. El centro te responderá a la brevedad.'),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: AppColors.surfaceWhite,
              ),
              child: isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar Pregunta'),
            ),
          ],
        ),
      ),
    );
  }
}
