import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/siniestro_model.dart';

class SiniestroService {
  final AuthService auth;
  SiniestroService(this.auth);

  String get base => auth.baseUrl;

  Future<List<SiniestroModel>> listarSiniestros() async {
    final res = await http.get(
      Uri.parse('$base/siniestros/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List)
          .map((j) => SiniestroModel.fromJson(j))
          .toList();
    }
    throw Exception('Error al listar siniestros (${res.statusCode})');
  }

  Future<SiniestroModel> reportarSiniestro({
    required int polizaId,
    required String tipoSiniestro,
    required String fechaEvento,
    required String descripcion,
    String? documentoSoporteUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$base/siniestros/reportar/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'poliza_id': polizaId,
        'tipo_siniestro': tipoSiniestro,
        'fecha_evento': fechaEvento,
        'descripcion': descripcion,
        if (documentoSoporteUrl != null)
          'documento_soporte_url': documentoSoporteUrl,
      }),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      // El backend devuelve { mensaje, siniestro_id, ... } no el objeto completo
      // Hacemos un GET para obtener el objeto completo
      return await _obtenerSiniestro(data['siniestro_id']);
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Error al reportar siniestro');
  }

  Future<SiniestroModel> _obtenerSiniestro(int id) async {
    final res = await http.get(
      Uri.parse('$base/siniestros/$id/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      return SiniestroModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Error al obtener siniestro');
  }

  Future<void> revisarSiniestro({
    required int siniestroId,
    required String estado, // EN_REVISION | APROBADO | RECHAZADO
    String observaciones = '',
  }) async {
    final res = await http.post(
      Uri.parse('$base/siniestros/$siniestroId/revisar/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'estado': estado,
        'observaciones_agente': observaciones,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Error al revisar siniestro');
    }
  }

  // ── Indemnizaciones ──────────────────────────────────────────────────────

  Future<List<IndemnizacionModel>> listarIndemnizaciones() async {
    final res = await http.get(
      Uri.parse('$base/indemnizaciones/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List)
          .map((j) => IndemnizacionModel.fromJson(j))
          .toList();
    }
    throw Exception(
        'Error al listar indemnizaciones (${res.statusCode})');
  }

  Future<void> iniciarIndemnizacion({
    required int siniestroId,
    String observaciones = '',
  }) async {
    final res = await http.post(
      Uri.parse('$base/indemnizaciones/iniciar/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'siniestro_id': siniestroId,
        'observaciones': observaciones,
      }),
    );
    if (res.statusCode != 201) {
      final err = jsonDecode(res.body);
      throw Exception(
          err['error'] ?? 'Error al iniciar indemnización');
    }
  }

  Future<void> aprobarIndemnizacion({
    required int indemnizacionId,
    required double monto,
    String observaciones = '',
  }) async {
    final res = await http.post(
      Uri.parse('$base/indemnizaciones/$indemnizacionId/aprobar/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'monto_aprobado': monto,
        'observaciones': observaciones,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(
          err['error'] ?? 'Error al aprobar indemnización');
    }
  }

  Future<void> rechazarIndemnizacion({
    required int indemnizacionId,
    required String observaciones,
  }) async {
    final res = await http.post(
      Uri.parse(
          '$base/indemnizaciones/$indemnizacionId/rechazar/'),
      headers: auth.authHeaders,
      body: jsonEncode({'observaciones': observaciones}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(
          err['error'] ?? 'Error al rechazar indemnización');
    }
  }
}