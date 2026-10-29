import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../repositories/school_repository.dart';

/// Diálogo para que el SuperAdmin resetee contraseñas de directores y personal escolar
class ResetPasswordDialog extends StatefulWidget {
  final String? schoolId;
  final String? schoolName;
  final String? userEmail;
  final String? userName;
  final SchoolRepository schoolRepository;

  const ResetPasswordDialog({
    super.key,
    this.schoolId,
    this.schoolName,
    this.userEmail,
    this.userName,
    required this.schoolRepository,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? schoolId,
    String? schoolName,
    String? userEmail,
    String? userName,
    required SchoolRepository schoolRepository,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResetPasswordDialog(
        schoolId: schoolId,
        schoolName: schoolName,
        userEmail: userEmail,
        userName: userName,
        schoolRepository: schoolRepository,
      ),
    );
  }

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  bool _obscureText = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: _generateRandomPassword());
    _emailController = TextEditingController(text: widget.userEmail ?? '');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!#%*';
    final random = Random();
    final nameToClean = widget.schoolName ?? 'Edunex';
    final cleanSchool = nameToClean.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    final prefix = cleanSchool.length >= 4 ? cleanSchool.substring(0, 4) : 'Edunex';
    final suffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return '${prefix}2026!$suffix';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final targetEmail = widget.userEmail?.isNotEmpty == true
        ? widget.userEmail!
        : _emailController.text.trim();
    final newPassword = _passwordController.text.trim();
    final resolvedSchoolName = widget.schoolName ?? 'Red Central EDUNEX (SaaS)';

    try {
      await widget.schoolRepository.resetDirectorPassword(
        schoolId: widget.schoolId ?? '',
        directorEmail: targetEmail,
        newPassword: newPassword,
        schoolName: resolvedSchoolName,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop(true);
        _showSuccessDialog(targetEmail, newPassword);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(
          context,
          'Error al resetear contraseña: $e',
          title: 'Error de Seguridad',
        );
      }
    }
  }

  void _showSuccessDialog(String targetEmail, String newPassword) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 26),
            SizedBox(width: 10),
            Text('Contraseña Reseteada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se ha actualizado la contraseña para ${widget.userEmail} en la base de datos.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, color: AppColors.navyPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      newPassword,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.navyPrimary),
                    tooltip: 'Copiar al portapapeles',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: newPassword));
                      AppToast.success(
                        ctx,
                        '¡Contraseña copiada al portapapeles!',
                        title: 'Copiado',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Entrega esta clave temporal al usuario y recomiéndale cambiarla en su primer inicio.',
              style: TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFB45309), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resetear Contraseña de Acceso',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        Text(
                          widget.schoolName ?? 'Red Central EDUNEX (SaaS)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Info usuario o campo para escribir email
              if (widget.userEmail != null && widget.userEmail!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, color: AppColors.navyPrimary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName ?? 'Director(a) / Administrador',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              widget.userEmail!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Formulario de contraseña
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.userEmail == null || widget.userEmail!.isEmpty) ...[
                      const Text(
                        'Correo Electrónico a Resetear:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'ej. director@colegio.edu.do',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa el correo electrónico del usuario';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Ingresa un correo válido (ej. usuario@dominio.com)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Nueva Contraseña:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _passwordController.text = _generateRandomPassword();
                            });
                          },
                          icon: const Icon(Icons.casino_outlined, size: 16),
                          label: const Text('Generar Automática', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.electricBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                        helperText: 'Mínimo 6 caracteres. Se actualizará en la base de datos central.',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.lock_reset_rounded, size: 18),
                    label: Text(_isSaving ? 'Guardando...' : 'Confirmar Reseteo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
