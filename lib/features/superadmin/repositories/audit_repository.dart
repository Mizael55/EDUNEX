import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/audit_log.dart';

/// Repositorio de Auditoría y Trazabilidad para el SuperAdmin SaaS
/// Persistencia y lectura 100% directa desde la base de datos PostgreSQL en Supabase.
class AuditRepository {
  final SupabaseClient? _supabaseClient;
  final List<AuditLog> _inMemoryLogs = [];

  AuditRepository({SupabaseClient? client})
      : _supabaseClient = client ?? (SupabaseConfig.isConfigured ? SupabaseConfig.adminClient : null);

  /// Consulta los eventos de auditoría directamente desde la tabla `logs_auditoria` en Supabase
  Future<List<AuditLog>> getAuditLogs({
    String? colegioId,
    String? modulo,
    String? nivel,
    String? query,
  }) async {
    // 1. Consulta directa a la base de datos Supabase
    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        var queryBuilder = _supabaseClient.from('logs_auditoria').select();

        if (colegioId != null && colegioId.isNotEmpty) {
          queryBuilder = queryBuilder.eq('colegio_id', colegioId);
        }

        if (modulo != null && modulo != 'Todos') {
          queryBuilder = queryBuilder.eq('modulo', modulo);
        }

        if (nivel != null && nivel != 'Todos') {
          queryBuilder = queryBuilder.eq('nivel', nivel.toUpperCase());
        }

        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim();
          queryBuilder = queryBuilder.or('descripcion.ilike.%$q%,accion.ilike.%$q%,usuario.ilike.%$q%,colegio_nombre.ilike.%$q%');
        }

        final data = await queryBuilder.order('timestamp', ascending: false).limit(200);
        if (data is List) {
          final remoteLogs = data.map((json) => AuditLog.fromJson(json as Map<String, dynamic>)).toList();
          return remoteLogs;
        }
      } catch (e) {
        debugPrint('Aviso consultando logs_auditoria en Supabase: $e');
      }
    }

    // 2. Fallback exclusivo para modo pruebas sin conexión
    List<AuditLog> results = List.from(_inMemoryLogs);

    if (colegioId != null && colegioId.isNotEmpty) {
      results = results.where((l) => l.colegioId == colegioId).toList();
    }

    if (modulo != null && modulo != 'Todos') {
      results = results.where((l) => l.modulo.toLowerCase() == modulo.toLowerCase()).toList();
    }

    if (nivel != null && nivel != 'Todos') {
      results = results.where((l) => l.nivel.toUpperCase() == nivel.toUpperCase()).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((l) {
        return l.descripcion.toLowerCase().contains(q) ||
            l.accion.toLowerCase().contains(q) ||
            l.usuario.toLowerCase().contains(q) ||
            (l.colegioNombre?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  /// Registra un nuevo evento de auditoría en la base de datos Supabase
  Future<void> recordAuditLog(AuditLog log) async {
    _inMemoryLogs.insert(0, log);

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        final payload = <String, dynamic>{
          'accion': log.accion,
          'descripcion': log.descripcion,
          'usuario': log.usuario,
          'rol': log.rol,
          'modulo': log.modulo,
          'nivel': log.nivel,
        };
        if (log.colegioId != null && log.colegioId!.isNotEmpty) {
          payload['colegio_id'] = log.colegioId;
        }
        if (log.colegioNombre != null && log.colegioNombre!.isNotEmpty) {
          payload['colegio_nombre'] = log.colegioNombre;
        }
        if (log.ipAddress != null && log.ipAddress!.isNotEmpty) {
          payload['ip_address'] = log.ipAddress;
        }

        await _supabaseClient.from('logs_auditoria').insert(payload);
      } catch (e) {
        debugPrint('Aviso persistiendo auditoría en Supabase: $e');
      }
    }
  }

  /// Limpia los logs de auditoría en memoria (para pruebas)
  void clearLocalLogs() {
    _inMemoryLogs.clear();
  }
}
