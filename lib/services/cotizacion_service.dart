import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/cotizacion_model.dart';

class CotizacionService {
  final AuthService auth;
  CotizacionService(this.auth);

  String get base => auth.baseUrl;

  Future<List<PlanModel>> listarPlanes() async {
    final res = await http.get(
      Uri.parse('$base/planes/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).map((j) => PlanModel.fromJson(j)).toList();
    }
    throw Exception('Error al cargar planes: ${res.statusCode}');
  }

  Future<CotizacionResultado> calcularCotizacion(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$base/cotizaciones/calcular/'),
      headers: auth.authHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return CotizacionResultado.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err.toString());
  }

  Future<Map<String, dynamic>> aceptarCotizacion(int cotizacionId) async {
    final res = await http.post(
      Uri.parse('$base/cotizaciones/$cotizacionId/aceptar/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al aceptar cotización');
  }

  Future<List<Map<String, dynamic>>> listarCotizaciones() async {
    final res = await http.get(
      Uri.parse('$base/cotizaciones/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Error al listar cotizaciones');
  }
}