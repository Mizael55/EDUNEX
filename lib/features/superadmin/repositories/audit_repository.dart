import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/audit_log.dart';

/// Repositorio de Auditoría y Trazabilidad para el SuperAdmin SaaS
class AuditRepository {
  final SupabaseClient? _supabaseClient;
  final List<AuditLog> _inMemoryLogs = [];

  AuditRepository({SupabaseClient? client})
      : _supabaseClient = client ?? (SupabaseConfig.isConfigured ? SupabaseConfig.adminClient : null) {
    _initDefaultLogs();
  }

  void _initDefaultLogs() {
    final now = DateTime.now();
    _inMemoryLogs.addAll([
      AuditLog(
        id: 'aud-001',
        timestamp: now.subtract(const Duration(minutes: 12)),
        accion: 'INSPECCION_INSTITUCIONAL',
        descripcion: 'SuperAdmin inició sesión de auditoría e inspección técnica para Centro Educativo Nuevo Orden (CENO).',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        colegioNombre: 'Centro Educativo Nuevo Orden',
        modulo: 'SaaS / SuperAdmin',
        nivel: 'INFO',
        ipAddress: '179.52.14.88 (Santo Domingo, DO)',
      ),
      AuditLog(
        id: 'aud-002',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 25)),
        accion: 'ACTUALIZACION_REGISTRO',
        descripcion: 'Verificación de documentación mercantil y cédula de director en Centro Educativo Nuevo Orden.',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        colegioNombre: 'Centro Educativo Nuevo Orden',
        modulo: 'Institucional',
        nivel: 'SUCCESS',
        ipAddress: '179.52.14.88 (Santo Domingo, DO)',
      ),
      AuditLog(
        id: 'aud-003',
        timestamp: now.subtract(const Duration(hours: 3)),
        accion: 'TARIFICACION_SAAS',
        descripcion: 'Cálculo de plan SaaS escalonado RD\$ 7,000/mes asignado según rango de capacidad (>450 alumnos).',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        colegioNombre: 'Centro Educativo Nuevo Orden',
        modulo: 'Finanzas',
        nivel: 'INFO',
        ipAddress: '179.52.14.88 (Santo Domingo, DO)',
      ),
      AuditLog(
        id: 'aud-004',
        timestamp: now.subtract(const Duration(hours: 5)),
        accion: 'VALIDACION_METODO_PAGO',
        descripcion: 'Validación de política de suscripción activa requerida previo a enrolamiento de alumnos.',
        usuario: 'admin@ceno.edu.do',
        rol: 'AdminColegio',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        colegioNombre: 'Centro Educativo Nuevo Orden',
        modulo: 'Seguridad',
        nivel: 'INFO',
        ipAddress: '190.166.42.11 (Santo Domingo, DO)',
      ),
      AuditLog(
        id: 'aud-005',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        accion: 'ENROLAMIENTO_COLEGIO',
        descripcion: 'Alta institucional del colegio cliente "Centro Educativo Nuevo Orden" con RNC 1-32-45678-9.',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: 'a0000000-0000-0000-0000-000000000001',
        colegioNombre: 'Centro Educativo Nuevo Orden',
        modulo: 'Institucional',
        nivel: 'SUCCESS',
        ipAddress: '179.52.14.88 (Santo Domingo, DO)',
      ),
      AuditLog(
        id: 'aud-006',
        timestamp: now.subtract(const Duration(days: 2)),
        accion: 'ACTIVACION_LICENCIA',
        descripcion: 'Activación de licencia comercial para Colegio Bilingüe EDUNEX Piloto.',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        colegioId: 'a0000000-0000-0000-0000-000000000002',
        colegioNombre: 'Colegio Bilingüe EDUNEX Piloto',
        modulo: 'SaaS / SuperAdmin',
        nivel: 'SUCCESS',
        ipAddress: '179.52.14.88 (Santo Domingo, DO)',
      ),
      AuditLog(
        id: 'aud-007',
        timestamp: now.subtract(const Duration(days: 3)),
        accion: 'CONTROL_ACCESO',
        descripcion: 'Autenticación exitosa de SuperAdministrador SaaS en consola central.',
        usuario: 'superadmin@edunex.edu',
        rol: 'SuperAdmin',
        modulo: 'Seguridad',
        nivel: 'INFO',
        ipAddress: '179.52.14.88 (Santo Domingo, DO)',
      ),
    ]);
  }

  /// Consulta los eventos de auditoría con soporte de filtros
  Future<List<AuditLog>> getAuditLogs({
    String? colegioId,
    String? modulo,
    String? nivel,
    String? query,
  }) async {
    List<AuditLog> results = List.from(_inMemoryLogs);

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        var queryBuilder = _supabaseClient.from('logs_auditoria').select();
        if (colegioId != null) {
          queryBuilder = queryBuilder.eq('colegio_id', colegioId);
        }
        final data = await queryBuilder.order('timestamp', ascending: false).limit(100);
        if (data is List && data.isNotEmpty) {
          final remoteLogs = data.map((json) => AuditLog.fromJson(json as Map<String, dynamic>)).toList();
          return remoteLogs;
        }
      } catch (e) {
        debugPrint('Aviso consultando auditoría en Supabase (usando eventos del sistema): $e');
      }
    }

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

  /// Registra un nuevo evento de auditoría
  Future<void> recordAuditLog(AuditLog log) async {
    _inMemoryLogs.insert(0, log);

    if (_supabaseClient != null && SupabaseConfig.isConfigured) {
      try {
        await _supabaseClient.from('logs_auditoria').insert(log.toJson());
      } catch (e) {
        debugPrint('Aviso persistiendo auditoría en Supabase: $e');
      }
    }
  }
}
