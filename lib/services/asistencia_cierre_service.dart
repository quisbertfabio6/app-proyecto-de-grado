import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Cierre online de la asistencia. El servidor decide los estados faltantes.
class AsistenciaCierreService {
  static Future<Map<String, dynamic>> finalizar({
    required int materiaId,
    required String fecha,
  }) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Inicia sesión nuevamente.'};
    }
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/docente/finalizar-asistencia'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'materia_id': materiaId, 'fecha': fecha}),
      ).timeout(const Duration(seconds: 20));
      final dynamic data = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> && data['success'] == true) {
        return data;
      }
      return {
        'success': false,
        'message': data is Map<String, dynamic>
            ? (data['message'] ?? 'No se pudo finalizar la asistencia.')
            : 'No se pudo finalizar la asistencia.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'No se confirmó el cierre. Revisa la conexión y vuelve a intentar.',
      };
    }
  }
}
