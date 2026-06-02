/*import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/agente_model.dart';

class AdminService {
  final AuthService auth;
  AdminService(this.auth);

  String get base => auth.baseUrl;

  // ── AGENTES ────────────────────────────────────────────
  Future<List<AgenteModel>> listarAgentes() async {
    final res = await http.get(
      Uri.parse('$base/agentes/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).map((j) => AgenteModel.fromJson(j)).toList();
    }
    throw Exception('Error al listar agentes');
  }

  Future<AgenteModel> crearAgente(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$base/agentes/'),
      headers: auth.authHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 201) return AgenteModel.fromJson(jsonDecode(res.body));
    final err = jsonDecode(res.body);
    throw Exception(err.toString());
  }

  Future<void> toggleAgenteActivo(int id, bool activo) async {
    await http.patch(
      Uri.parse('$base/agentes/$id/'),
      headers: auth.authHeaders,
      body: jsonEncode({'is_active': activo}),
    );
  }

  Future<void> eliminarAgente(int id) async {
    await http.delete(
      Uri.parse('$base/agentes/$id/'),
      headers: auth.authHeaders,
    );
  }

  // ── CLIENTES ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listarClientes() async {
    final res = await http.get(
      Uri.parse('$base/clientes/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Error al listar clientes');
  }

  Future<void> toggleClienteActivo(int id, bool activo) async {
    await http.patch(
      Uri.parse('$base/clientes/$id/'),
      headers: auth.authHeaders,
      body: jsonEncode({'is_active': activo}),
    );
  }

  // ── COTIZACIONES ───────────────────────────────────────
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

  Future<void> aceptarCotizacion(int id) async {
    final res = await http.post(
      Uri.parse('$base/cotizaciones/$id/aceptar/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode != 200) throw Exception('Error al aceptar cotización');
  }

  // ── RENOVACIONES ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> listarRenovaciones() async {
    final res = await http.get(
      Uri.parse('$base/renovaciones/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Error al listar renovaciones');
  }

  Future<void> aprobarRenovacion(int id, {String obs = '', double ajuste = 0}) async {
    final res = await http.post(
      Uri.parse('$base/renovaciones/$id/aprobar/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'observaciones_analista': obs,
        'porcentaje_ajuste_prima': ajuste,
      }),
    );
    if (res.statusCode != 200) throw Exception('Error al aprobar');
  }

  Future<void> rechazarRenovacion(int id, String motivo) async {
    final res = await http.post(
      Uri.parse('$base/renovaciones/$id/rechazar/'),
      headers: auth.authHeaders,
      body: jsonEncode({'observaciones_analista': motivo}),
    );
    if (res.statusCode != 200) throw Exception('Error al rechazar');
  }

  // ── REPORTES ───────────────────────────────────────────
  Future<Map<String, dynamic>> obtenerReporte({
    required String modelo,
    String export = 'json',
    Map<String, String> filtros = const {},
  }) async {
    final params = {'modelo': modelo, 'export': export, ...filtros};
    final uri = Uri.parse('$base/reportes/').replace(queryParameters: params);
    final res = await http.get(uri, headers: auth.authHeaders);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener reporte');
  }

  Future<Map<String, dynamic>> reportePorVoz(String texto) async {
    final res = await http.post(
      Uri.parse('$base/reportes/voice-intent/'),
      headers: auth.authHeaders,
      body: jsonEncode({'text': texto}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error en reporte por voz');
  }

  // ── BITÁCORA ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listarBitacora() async {
    final res = await http.get(
      Uri.parse('$base/mi-agencia/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Error al listar bitácora');
  }
}*/
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/agente_model.dart';
import '../models/reporte_model.dart';

class AdminService {
  final AuthService auth;
  AdminService(this.auth);

  String get base => auth.baseUrl;

  // ══════════════════════════════════════════════════════════════════════
  // AGENTES
  // ══════════════════════════════════════════════════════════════════════

  Future<List<AgenteModel>> listarAgentes() async {
    final res = await http.get(
      Uri.parse('$base/agentes/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).map((j) => AgenteModel.fromJson(j)).toList();
    }
    throw Exception('Error al listar agentes');
  }

  Future<AgenteModel> crearAgente(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$base/agentes/'),
      headers: auth.authHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 201) {
      return AgenteModel.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err.toString());
  }

  Future<void> toggleAgenteActivo(int id, bool activo) async {
    await http.patch(
      Uri.parse('$base/agentes/$id/'),
      headers: auth.authHeaders,
      body: jsonEncode({'is_active': activo}),
    );
  }

  Future<void> eliminarAgente(int id) async {
    await http.delete(
      Uri.parse('$base/agentes/$id/'),
      headers: auth.authHeaders,
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // CLIENTES
  // ══════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> listarClientes() async {
    final res = await http.get(
      Uri.parse('$base/clientes/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Error al listar clientes');
  }

  Future<void> toggleClienteActivo(int id, bool activo) async {
    await http.patch(
      Uri.parse('$base/clientes/$id/'),
      headers: auth.authHeaders,
      body: jsonEncode({'is_active': activo}),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // COTIZACIONES
  // ══════════════════════════════════════════════════════════════════════

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

  Future<void> aceptarCotizacion(int id) async {
    final res = await http.post(
      Uri.parse('$base/cotizaciones/$id/aceptar/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode != 200) throw Exception('Error al aceptar cotización');
  }

  // ══════════════════════════════════════════════════════════════════════
  // RENOVACIONES
  // ══════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> listarRenovaciones() async {
    final res = await http.get(
      Uri.parse('$base/renovaciones/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Error al listar renovaciones');
  }

  Future<void> aprobarRenovacion(
    int id, {
    String obs = '',
    double ajuste = 0,
  }) async {
    final res = await http.post(
      Uri.parse('$base/renovaciones/$id/aprobar/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'observaciones_analista': obs,
        'porcentaje_ajuste_prima': ajuste,
      }),
    );
    if (res.statusCode != 200) throw Exception('Error al aprobar');
  }

  Future<void> rechazarRenovacion(int id, String motivo) async {
    final res = await http.post(
      Uri.parse('$base/renovaciones/$id/rechazar/'),
      headers: auth.authHeaders,
      body: jsonEncode({'observaciones_analista': motivo}),
    );
    if (res.statusCode != 200) throw Exception('Error al rechazar');
  }

  // ══════════════════════════════════════════════════════════════════════
  // REPORTES — Nuevos métodos
  // ══════════════════════════════════════════════════════════════════════

  /// Obtiene los metadatos de todos los modelos permitidos.
  /// Devuelve un mapa: "app.modelo" → ModeloMetadata
  Future<Map<String, ModeloMetadata>> obtenerMetadata() async {
    final res = await http.get(
      Uri.parse('$base/reportes/metadata/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      return raw.map(
        (key, value) => MapEntry(key, ModeloMetadata.fromJson(key, value)),
      );
    }
    throw Exception('Error al obtener metadatos: ${res.statusCode}');
  }

  /// Obtiene datos en JSON con columnas y filtros personalizados.
  Future<Map<String, dynamic>> obtenerReporteJson({
    required String modelo,
    List<String>? campos, // columnas seleccionadas
    Map<String, String> filtros = const {},
    String? ordering,
    int? limit,
  }) async {
    final params = <String, String>{'modelo': modelo, 'export': 'json'};
    if (campos != null && campos.isNotEmpty) {
      params['campos'] = campos.join(',');
    }
    if (ordering != null) params['ordering'] = ordering;
    if (limit != null) params['limit'] = limit.toString();
    params.addAll(filtros);

    final uri = Uri.parse('$base/reportes/').replace(queryParameters: params);
    final res = await http.get(uri, headers: auth.authHeaders);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error en reporte JSON: ${res.statusCode}');
  }

  /// Descarga el reporte en Excel y devuelve los bytes.
  Future<Uint8List> descargarExcel({
    required String modelo,
    List<String>? campos,
    Map<String, String> filtros = const {},
    String? ordering,
  }) async {
    final params = <String, String>{'modelo': modelo, 'export': 'excel'};
    if (campos != null && campos.isNotEmpty) {
      params['campos'] = campos.join(',');
    }
    if (ordering != null) params['ordering'] = ordering;
    params.addAll(filtros);

    final uri = Uri.parse('$base/reportes/').replace(queryParameters: params);

    // Para archivos binarios no podemos usar auth.authHeaders directamente
    // porque incluye 'Content-Type: application/json'
    final headers = Map<String, String>.from(auth.authHeaders)
      ..remove('Content-Type');

    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception('Error al exportar Excel: ${res.statusCode}');
  }

  /// Descarga el reporte en PDF y devuelve los bytes.
  Future<Uint8List> descargarPdf({
    required String modelo,
    List<String>? campos,
    Map<String, String> filtros = const {},
    String? ordering,
  }) async {
    final params = <String, String>{'modelo': modelo, 'export': 'pdf'};
    if (campos != null && campos.isNotEmpty) {
      params['campos'] = campos.join(',');
    }
    if (ordering != null) params['ordering'] = ordering;
    params.addAll(filtros);

    final uri = Uri.parse('$base/reportes/').replace(queryParameters: params);

    final headers = Map<String, String>.from(auth.authHeaders)
      ..remove('Content-Type');

    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception('Error al exportar PDF: ${res.statusCode}');
  }

  /// Envía el reporte por email al destinatario indicado.
  Future<String> enviarReportePorEmail({
    required String modelo,
    required String emailTo,
    List<String>? campos,
    Map<String, String> filtros = const {},
  }) async {
    final params = <String, String>{
      'modelo': modelo,
      'export': 'email',
      'email_to': emailTo,
    };
    if (campos != null && campos.isNotEmpty) {
      params['campos'] = campos.join(',');
    }
    params.addAll(filtros);

    final uri = Uri.parse('$base/reportes/').replace(queryParameters: params);
    final headers = Map<String, String>.from(auth.authHeaders)
      ..remove('Content-Type');

    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['mensaje'] ?? 'Enviado correctamente';
    }
    throw Exception('Error al enviar email: ${res.statusCode}');
  }

  /// Reporte por comando de voz/texto usando IA (Gemini).
  Future<Map<String, dynamic>> reportePorVoz(String texto) async {
    final res = await http.post(
      Uri.parse('$base/reportes/voice-intent/'),
      headers: auth.authHeaders,
      body: jsonEncode({'text': texto}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error en reporte por voz');
  }

  // ══════════════════════════════════════════════════════════════════════
  // BITÁCORA
  // ══════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> listarBitacora() async {
    final res = await http.get(
      Uri.parse('$base/mi-agencia/'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception('Error al listar bitácora');
  }

  Future<Map<String, dynamic>> obtenerReporte({
  required String modelo,
  String export = 'json',
  Map<String, String> filtros = const {},
}) async {
  final params = {'modelo': modelo, 'export': export, ...filtros};
  final uri = Uri.parse('$base/reportes/').replace(queryParameters: params);
  final headers = Map<String, String>.from(auth.authHeaders)
    ..remove('Content-Type');
  final res = await http.get(uri, headers: headers);
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception('Error al obtener reporte: ${res.statusCode}');
}
}
