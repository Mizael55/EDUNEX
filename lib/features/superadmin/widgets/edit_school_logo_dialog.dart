import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../repositories/school_repository.dart';

/// Modal interactivo para que el Administrador o Director del centro agregue o cambie
/// el logo oficial del colegio tipo foto de perfil (Issue #15)
class EditSchoolLogoDialog extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final String? currentLogoUrl;
  final SchoolRepository schoolRepository;
  final ValueChanged<String>? onLogoUpdated;

  const EditSchoolLogoDialog({
    super.key,
    required this.schoolId,
    required this.schoolName,
    this.currentLogoUrl,
    required this.schoolRepository,
    this.onLogoUpdated,
  });

  static Future<String?> show(
    BuildContext context, {
    required String schoolId,
    required String schoolName,
    String? currentLogoUrl,
    required SchoolRepository schoolRepository,
    ValueChanged<String>? onLogoUpdated,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditSchoolLogoDialog(
        schoolId: schoolId,
        schoolName: schoolName,
        currentLogoUrl: currentLogoUrl,
        schoolRepository: schoolRepository,
        onLogoUpdated: onLogoUpdated,
      ),
    );
  }

  @override
  State<EditSchoolLogoDialog> createState() => _EditSchoolLogoDialogState();
}

class _EditSchoolLogoDialogState extends State<EditSchoolLogoDialog> {
  late TextEditingController _urlController;
  late String _selectedLogo;
  bool _isSaving = false;

  // Catálogo de logotipos / emblemas escolares institucionales preconfigurados
  static const List<Map<String, String>> _presetLogos = [
    {
      'name': 'Escudo Oficial Azul Oro',
      'url': 'https://images.unsplash.com/photo-1594608661623-aa0bd3a69d98?w=200&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Insignia Académica Clásica',
      'url': 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=200&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Emblema Moderno Escolar',
      'url': 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=200&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Monograma Dorado Institucional',
      'url': 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=200&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedLogo = widget.currentLogoUrl ?? _presetLogos.first['url']!;
    _urlController = TextEditingController(text: _selectedLogo);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveLogo() async {
    final finalUrl = _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : _selectedLogo;
    setState(() => _isSaving = true);

    try {
      await widget.schoolRepository.updateSchoolLogo(
        schoolId: widget.schoolId,
        logoUrl: finalUrl,
      );

      if (mounted) {
        widget.onLogoUpdated?.call(finalUrl);
        Navigator.of(context).pop(finalUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el logo: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 850),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.navyPrimary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logo Oficial del Centro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        Text(
                          widget.schoolName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Previsualización Tipo Perfil Institucional
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.navyPrimary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _selectedLogo.startsWith('http')
                                ? Image.network(
                                    _selectedLogo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                                  )
                                : _buildFallbackAvatar(),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.electricBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vista Previa del Perfil del Centro',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Selector de Catálogo de Emblemas
              const Text(
                'Seleccionar Emblema Institucional Recomendado:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _presetLogos.map((preset) {
                  final isSelected = _selectedLogo == preset['url'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedLogo = preset['url']!;
                        _urlController.text = preset['url']!;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.electricBlue.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.electricBlue : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              preset['url']!,
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 36, color: AppColors.navyPrimary),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset['name']!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.electricBlue : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // O ingresar URL personalizada
              const Text(
                'O pegar URL directa de la imagen/logo del colegio:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://ejemplo.com/logo-colegio.png',
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() => _selectedLogo = val.trim());
                },
              ),
              const SizedBox(height: 24),

              // Botones de Acción
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveLogo,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar Logo de Perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppColors.navyPrimary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.school_rounded, size: 52, color: AppColors.navyPrimary),
      ),
    );
  }
}
