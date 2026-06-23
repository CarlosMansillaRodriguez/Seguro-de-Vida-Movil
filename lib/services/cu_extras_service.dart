import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CuExtrasService {
  final AuthService auth;
  CuExtrasService(this.auth);
  String get base => auth.baseUrl;

  // HU-28
  Future<Map<String, dynamic>> proyectarRescate(int polizaId) async {
    final res = await http.get(
      Uri.parse('$base/polizas/$polizaId/proyectar_rescate/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al proyectar rescate');
  }

  // HU-30
  Future<Map<String, dynamic>> recomendacionIA(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$base/cotizaciones/recomendacion-ia/'),
      headers: auth.authHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al obtener recomendación IA');
  }

  // HU-31
  Future<Map<String, dynamic>> validarOcr(int expedienteId) async {
    final res = await http.post(
      Uri.parse('$base/expedientes/$expedienteId/validar_ocr/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al ejecutar OCR');
  }

  // HU-32
  Future<Map<String, dynamic>> validarCarencia(int siniestroId) async {
    final res = await http.post(
      Uri.parse('$base/siniestros/$siniestroId/validar_carencia/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al validar carencia');
  }
}