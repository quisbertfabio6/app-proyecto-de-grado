import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/database_helper.dart';

class ApiService {
  static const String baseUrl = 'sdasdasdadsdas/api';

  // AUTENTICACIÓN Y SESIÓN

  // 1. Iniciar Sesión
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');
    print("INTENTANDO CONECTAR A: $url");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': 'mobile_app',
        }),
      );

      print('Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _guardarDatosSesion(data['token'], data['rol']);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              'Error ${response.statusCode}: Credenciales incorrectas o falla en servidor.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'No se pudo conectar. Revisa que tu PC y el Túnel estén encendidos. ($e)',
      };
    }
  }

  // Guardar token y rol localmente
  static Future<void> _guardarDatosSesion(String token, String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_rol', rol);
  }

  // Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Obtener rol guardado
  static Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_rol');
  }

  // MÓDULO ESTUDIANTE

  // Catalogo y cupo del semestre, ambos consultados desde Laravel.
  static Future<Map<String, dynamic>> getCategoriasLicencia() {
    return _getDatosLicencia('estudiante/categorias-licencia');
  }

  static Future<Map<String, dynamic>> getCupoLicencias() {
    return _getDatosLicencia('estudiante/licencias/cupo');
  }

  static Future<Map<String, dynamic>> _getDatosLicencia(String ruta) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Inicia sesión nuevamente.'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$ruta'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      ).timeout(const Duration(seconds: 15));

      final dynamic body = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          body is Map<String, dynamic> &&
          body['success'] == true) {
        return body;
      }

      return {
        'success': false,
        'message': response.statusCode == 401
            ? 'Tu sesión ha expirado. Vuelve a iniciar sesión.'
            : (body is Map<String, dynamic>
                ? (body['message'] ?? 'No se pudieron cargar los datos.')
                : 'No se pudieron cargar los datos.'),
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'No se pudieron cargar los datos. Comprueba la conexión con el servidor.',
      };
    }
  }


  static Future<Map<String, dynamic>> enviarLicencia({
    required String motivo,
    required String fechaInicio,
    required String fechaFin,
    File? archivo,
    int? categoriaId,
    int? subcategoriaId,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/estudiante/licencias');

    try {
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Bypass-Tunnel-Reminder': 'true',
      });

      request.fields['motivo'] = motivo;
      request.fields['fecha_inicio'] = fechaInicio;
      request.fields['fecha_fin'] = fechaFin;
      if (categoriaId != null) {
        request.fields['categoria_id'] = categoriaId.toString();
      }
      if (subcategoriaId != null) {
        request.fields['subcategoria_id'] = subcategoriaId.toString();
      }

      if (archivo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('archivo', archivo.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Respuesta Servidor Licencia: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Licencia enviada correctamente'};
      }

      Map<String, dynamic> data = {};
      try {
        final dynamic body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          data = body;
        }
      } catch (_) {
        // Algunas respuestas de error del servidor no son JSON.
      }
      return {
        'success': false,
        'status': response.statusCode,
        'codigo': data['codigo'],
        'message': data['message'] ?? 'Error ${response.statusCode} al enviar la solicitud.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 3. Obtener Dashboard Estudiante
  static Future<Map<String, dynamic>> getEstudianteDashboard() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/estudiante/dashboard');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  // 4. Obtener materias del estudiante (Con porcentajes)
  static Future<List<dynamic>> getMateriasEstudiante() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/estudiante/materias');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 5. Obtener historial de licencias
  static Future<List<dynamic>> getMisLicencias() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/estudiante/mis-licencias');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      }
      return [];
    } catch (e) {
      print("Error obteniendo licencias: $e");
      return [];
    }
  }

  // 6. Anular licencia
  static Future<Map<String, dynamic>> anularLicencia(int id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/estudiante/licencias/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Error al anular',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // --------------------------------------------------------
  // MÓDULO DOCENTE
  // --------------------------------------------------------

  // 7. Obtener materias asignadas
  static Future<List<dynamic>> getMateriasDocente() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/docente/materias');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      } else {
        print('Error al cargar materias: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de conexión: $e');
      return [];
    }
  }

  // 8. Registrar Asistencia por QR
  static Future<Map<String, dynamic>> registrarAsistencia({
    required String codigoQr,
    required int materiaId,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/docente/registrar-qr');

    final now = DateTime.now();
    final fecha =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final hora =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'Bypass-Tunnel-Reminder': 'true',
            },
            body: jsonEncode({
              'codigo_qr': codigoQr,
              'materia_id': materiaId,
              'fecha': fecha,
              'hora': hora,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'alumno': data['alumno']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al registrar',
        };
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }

  // 9. Obtener lista de fechas registradas (Para el carrusel)
  static Future<List<String>> getFechasClases(int materiaId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/docente/fechas-clases');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'materia_id': materiaId}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<String>.from(body['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 10. Obtener lista de control manual (Con fecha opcional)
  static Future<List<dynamic>> getListaControl(
    int materiaId, {
    String? fecha,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/docente/lista-control');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
        // Enviamos la fecha si existe
        body: jsonEncode({'materia_id': materiaId, 'fecha': fecha}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      } else {
        return [];
      }
    } catch (e) {
      print("Error obteniendo lista: $e");
      return [];
    }
  }

  // 11. Registrar Manual (Falta/Atraso)
  static Future<Map<String, dynamic>> registrarManual({
    required int estudianteId,
    required int materiaId,
    required String estado,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/docente/registrar-manual');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({
          'estudiante_id': estudianteId,
          'materia_id': materiaId,
          'estado': estado,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // --------------------------------------------------------
  // MÓDULO OFFLINE
  // --------------------------------------------------------

  // 12. Sincronizar Pendientes
  static Future<int> sincronizarPendientes() async {
    final dbHelper = DatabaseHelper();
    final pendientes = await dbHelper.getPendientes();

    if (pendientes.isEmpty) return 0;

    int sincronizados = 0;
    final token = await getToken();
    final url = Uri.parse('$baseUrl/docente/registrar-qr');

    for (var asistencia in pendientes) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Bypass-Tunnel-Reminder': 'true',
          },
          body: jsonEncode({
            'codigo_qr': asistencia['codigo_qr'],
            'materia_id': asistencia['materia_id'],
            'fecha': asistencia['fecha'],
            'hora': asistencia['hora'],
          }),
        );

        if (response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 409) {
          await dbHelper.borrarAsistencia(asistencia['id']);
          sincronizados++;
        }
      } catch (e) {
        print("Error al sincronizar uno: $e");
      }
    }
    return sincronizados;
  }
}
