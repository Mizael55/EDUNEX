import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para obtener la dirección IP pública del cliente o una ubicación dominicana
class IpService {
  static String? _cachedIp;

  /// Retorna la dirección IP del cliente (con fallback a IP dominicana)
  static Future<String> getClientIp() async {
    if (_cachedIp != null && _cachedIp!.isNotEmpty) {
      return _cachedIp!;
    }

    try {
      final res = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['ip'] != null) {
          _cachedIp = '${data['ip']} (Santo Domingo, DO)';
          return _cachedIp!;
        }
      }
    } catch (_) {}

    _cachedIp = '179.52.14.88 (Santo Domingo, DO)';
    return _cachedIp!;
  }

  /// Limpia la IP en caché para pruebas
  static void clearCache() {
    _cachedIp = null;
  }
}
