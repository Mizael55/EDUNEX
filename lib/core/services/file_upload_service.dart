import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../features/families/models/student_document.dart';

/// Representación en memoria de un archivo real seleccionado por el usuario
class RealPickedFile {
  final String name;
  final int size;
  final Uint8List bytes;
  final String extension;
  final String mimeType;
  final String dataUrl;

  const RealPickedFile({
    required this.name,
    required this.size,
    required this.bytes,
    required this.extension,
    required this.mimeType,
    required this.dataUrl,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension.toLowerCase()) ||
      mimeType.startsWith('image/');

  bool get isPdf =>
      extension.toLowerCase() == 'pdf' || mimeType.contains('pdf');
}

/// Servicio integral para seleccionar y subir archivos reales en EDUNEX
class FileUploadService {
  static const String bucketName = 'expedientes';

  /// Determina el MIME Type según la extensión del archivo
  static String resolveMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Abre el explorador de archivos nativo del sistema para seleccionar un documento real
  static Future<RealPickedFile?> pickRealFile({
    List<String>? allowedExtensions,
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf', 'png', 'jpg', 'jpeg', 'docx', 'doc'],
      );

      if (files.isEmpty) {
        return null;
      }

      final file = files.first;
      final bytes = await file.readAsBytes();
      final size = (await file.length()) ?? bytes.length;

      final ext = file.extension ?? (file.name.contains('.') ? file.name.split('.').last : 'pdf');
      final mime = resolveMimeType(ext);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      return RealPickedFile(
        name: file.name,
        size: size,
        bytes: bytes,
        extension: ext,
        mimeType: mime,
        dataUrl: dataUrl,
      );
    } catch (e) {
      debugPrint('Error en pickRealFile: $e');
      return null;
    }
  }

  /// Sube bytes directamente a Supabase Storage y retorna la URL pública
  static Future<({String publicUrl, String path})> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    String folder = 'documentos',
  }) async {
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'pdf';
    final mime = resolveMimeType(ext);

    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;
        await client.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mime,
            upsert: true,
          ),
        );

        final publicUrl = client.storage.from(bucketName).getPublicUrl(path);
        if (publicUrl.isNotEmpty) {
          return (publicUrl: publicUrl, path: path);
        }
      } catch (e) {
        debugPrint('Aviso: Falló subida a Supabase Storage: $e. Usando Data URL');
      }
    }

    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    return (publicUrl: dataUrl, path: path);
  }

  /// Sube los bytes del archivo a Supabase Storage y retorna la URL pública
  /// En caso de error o sin conexión, retorna el Data URL en Base64 para persistencia total
  static Future<String> uploadToStorage({
    required RealPickedFile file,
    String folder = 'documentos',
  }) async {
    final res = await uploadBytes(bytes: file.bytes, fileName: file.name, folder: folder);
    return res.publicUrl;
  }

  /// Flujo completo: selecciona archivo real, sube a almacenamiento y genera StudentDocument
  static Future<StudentDocument?> pickAndUploadStudentDocument({
    required String tipo,
    String? defaultName,
    bool verificado = true,
  }) async {
    final picked = await pickRealFile();
    if (picked == null) return null;

    final url = await uploadToStorage(file: picked, folder: 'estudiantes');

    return StudentDocument(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      tipo: tipo,
      nombre: defaultName ?? tipo,
      nombreArchivo: picked.name,
      urlArchivo: url,
      tamanoBytes: picked.size,
      fechaSubida: DateTime.now(),
      verificado: verificado,
    );
  }
}
