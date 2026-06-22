import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/documento_model.dart';

class DocumentoService {
  final AuthService auth;
  DocumentoService(this.auth);

  String get base => auth.baseUrl;

  Future<ExpedienteModel> crearExpediente(ExpedienteModel expediente) async {
    final res = await http.post(
      Uri.parse('$base/expedientes/'),
      headers: auth.authHeaders,
      body: jsonEncode(expediente.toJson()),
    );
    if (res.statusCode == 201) {
      return ExpedienteModel.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err.toString());
  }

  Future<ExpedienteModel> actualizarExpediente(int id, Map<String, dynamic> campos) async {
    final res = await http.patch(
      Uri.parse('$base/expedientes/$id/'),
      headers: auth.authHeaders,
      body: jsonEncode(campos),
    );
    if (res.statusCode == 200) {
      return ExpedienteModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Error al actualizar expediente');
  }

  /*Future<ExpedienteModel?> obtenerExpedientePorCotizacion(int cotizacionId) async {
    final res = await http.get(
      Uri.parse('$base/expedientes/?cotizacion=$cotizacionId'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      if ((list as List).isEmpty) return null;
      return ExpedienteModel.fromJson(list.first);
    }
    return null;
  }*/
   Future<ExpedienteModel?> obtenerExpedientePorCotizacion(int cotizacionId) async {
    final res = await http.get(
      Uri.parse('$base/expedientes/?cotizacion=$cotizacionId'),
      headers: auth.authHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      // Defensa: validar explícitamente que el expediente devuelto
      // corresponde a ESTA cotización (evita arrastrar datos viejos).
      final filtrado = (list as List).where((e) {
        final cot = e['cotizacion'];
        return cot != null && cot.toString() == cotizacionId.toString();
      }).toList();
      if (filtrado.isEmpty) return null;
      return ExpedienteModel.fromJson(filtrado.first);
    }
    return null;
  }
  
  /*-------------------------------------------------------------*/
  Future<void> validarExpediente(int expedienteId, {String observaciones = ''}) async {
    final res = await http.post(
      Uri.parse('$base/expedientes/$expedienteId/validar/'),
      headers: auth.authHeaders,
      body: jsonEncode({'observaciones': observaciones}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al validar expediente (${res.statusCode})');
    }
  }

  Future<void> rechazarExpediente(int expedienteId, String motivo) async {
    final res = await http.post(
      Uri.parse('$base/expedientes/$expedienteId/rechazar/'),
      headers: auth.authHeaders,
      body: jsonEncode({'motivo': motivo}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al rechazar expediente (${res.statusCode})');
    }
  }
  /*-----------------------------------------------------*/
}