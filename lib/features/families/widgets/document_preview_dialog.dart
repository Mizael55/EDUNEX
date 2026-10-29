import 'dart:typed_data';
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
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: isImage && (memoryBytes != null || (url != null && url.startsWith('http')))
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildPreviewWidget(isImage, memoryBytes, url),
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

  Widget _buildPreviewWidget(bool isImage, Uint8List? memoryBytes, String? url) {
    if (isImage) {
      if (memoryBytes != null && memoryBytes.isNotEmpty) {
        return Image.memory(
          memoryBytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholderPreview(isImage),
        );
      }
      if (url != null && url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholderPreview(isImage),
        );
      }
    }
    return _buildPlaceholderPreview(isImage);
  }

  Widget _buildPlaceholderPreview(bool isImage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isImage ? const Color(0xFFE0F2FE) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                size: 48,
                color: isImage ? const Color(0xFF0284C7) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              document.nombreArchivo,
              style: const TextStyle(
                color: AppColors.navyPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${document.tamanoFormateado} • Archivo Digitalizado',
              style: const TextStyle(color: AppColors.slateGray, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 12, color: Color(0xFF166534)),
                  SizedBox(width: 4),
                  Text(
                    'Expediente EDUNEX Verificado',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                  ),
                ],
              ),
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
