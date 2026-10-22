import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/student_document.dart';

/// Modal interactivo para previsualizar e inspeccionar documentos digitales reales del expediente
class DocumentPreviewDialog extends StatelessWidget {
  final StudentDocument document;
  final String studentName;

  const DocumentPreviewDialog({
    super.key,
    required this.document,
    required this.studentName,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentDocument document,
    required String studentName,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DocumentPreviewDialog(
        document: document,
        studentName: studentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImage = document.isImage;
    final memoryBytes = document.memoryBytes;
    final url = document.urlArchivo;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isImage
                  ? const Color(0xFFE0F2FE)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              color: isImage ? const Color(0xFF0284C7) : const Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  document.tipo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Expediente Escolar: $studentName',
                  style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenedor de Previsualización Real
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                clipBehavior: Clip.antiAlias,
                child: isImage
                    ? (memoryBytes != null
                        ? Image.memory(
                            memoryBytes,
                            fit: BoxFit.contain,
                          )
                        : (url != null && url.startsWith('http')
                            ? Image.network(
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _buildPlaceholderPreview(isImage),
                              )
                            : _buildPlaceholderPreview(isImage)))
                    : _buildPlaceholderPreview(isImage),
              ),

              const SizedBox(height: 16),

              // Metadatos Oficiales del Archivo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildMetaRow(Icons.description_outlined, 'Nombre Archivo', document.nombreArchivo),
                    const Divider(height: 12),
                    _buildMetaRow(Icons.data_usage_rounded, 'Tamaño', document.tamanoFormateado),
                    const Divider(height: 12),
                    _buildMetaRow(
                      Icons.calendar_today_rounded,
                      'Fecha de Subida',
                      '${document.fechaSubida.day}/${document.fechaSubida.month}/${document.fechaSubida.year} ${document.fechaSubida.hour.toString().padLeft(2, '0')}:${document.fechaSubida.minute.toString().padLeft(2, '0')}',
                    ),
                    const Divider(height: 12),
                    _buildMetaRow(
                      Icons.verified_rounded,
                      'Estado de Validación',
                      document.verificado ? 'Oficial • Verificado en Sistema' : 'Pendiente de Validación',
                      valueColor: document.verificado ? const Color(0xFF15803D) : const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildPlaceholderPreview(bool isImage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
              size: 56,
              color: Colors.white70,
            ),
            const SizedBox(height: 10),
            Text(
              document.nombreArchivo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${document.tamanoFormateado} • Archivo Real Digitalizado',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.slateGray),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.slateDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
